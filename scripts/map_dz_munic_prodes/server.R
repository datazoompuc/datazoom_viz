# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis
pallete_discrete <- rev(pallete_discrete)
pallete_continuous <- rev(pallete_continuous)

# addLegend() usa leaflet::labelFormat() por padrão, que formata os cortes de
# colorBin() sem tratar Inf de forma especial — o bin superior aberto (usado
# nos bins de desmatado/incremento absolutos, ex.: c(...,1600,Inf)) aparecia
# literalmente como "1.600 – Inf" na legenda. Não é dado inválido (prodes.rds
# não tem nenhum Inf — conferido linha a linha); é só o rótulo padrão do
# corte aberto, que devia ler "≥ 1.600". Intercepta só o tipo "bin" pra isso;
# qualquer outro tipo (numeric/quantile/factor) cai no labelFormat() padrão.
labFormat_bin_inf <- function(type, ...) {
  if (!identical(type, "bin")) {
    return(leaflet::labelFormat(big.mark = ".")(type = type, ...))
  }
  cuts <- list(...)[[1]] # addLegend() passa cuts posicionalmente, não nomeado
  fmt <- function(x) trimws(format(x, big.mark = ".", scientific = FALSE))
  n <- length(cuts)
  vapply(seq_len(n - 1), function(i) {
    lo <- cuts[i]
    hi <- cuts[i + 1]
    if (is.infinite(hi)) {
      paste0("&ge; ", fmt(lo))
    } else {
      paste0(fmt(lo), " &ndash; ", fmt(hi))
    }
  }, character(1))
}

# Fontes

# Funcão para retornar objeto server
get_server <- function(files, param) {

  # Carrega dados: atributos (PRODES) e geometria são fontes separadas,
  # unidas aqui em memória — mesmo padrão de map_mapbiomas_cover. Evita
  # depender de data/dz_munic_simplified.rds (arquivo combinado de 14 fontes,
  # com geometria desatualizada; ver troubleshooting.md).
  munic_geo <- readr::read_rds(files$shapefile) %>%
    filter(legal_amazon == 1) %>%
    st_make_valid() %>%
    transmute(cod_ibge = as.character(municipality_code), geometry = geom)

  # data/prodes.rds já traz nome/estado (municipio/estado), mas só cobre os
  # municípios que o PRODES de fato monitora — não os 772 inteiros da
  # Amazônia Legal (faltam, entre outros, Mojuí dos Campos/PA e um grupo de
  # municípios de borda no Maranhão como Codó; ver troubleshooting.md).
  # Nome/estado vêm do dado de pacote em vez disso, pra ficarem consistentes
  # e completos pros 772 — inclusive os que o PRODES não cobre.
  munic_meta <- datazoom.amazonia::municipalities %>%
    transmute(
      cod_ibge = as.character(code_muni),
      nm_municip = municipality_mapbiomas,
      estado = abbrev_state
    )

  prodes_raw <- readRDS(files$db_file) %>% janitor::clean_names()

  df_attrs <- prodes_raw %>%
    mutate(
      cod_ibge = as.character(cod_munic_ibge),
      # A unidade dessas colunas é "%" (ver dicionário); multiplicar por 100
      # é obrigatório — sem isso o valor fica em fração 0-1 (bug já
      # encontrado: range real chegava a só 1,004 em vez de 100,4), o que
      # também desalinha os bins especiais de is_prop (c(0,1,2,3,5,10,20,
      # 40,80,100)), pensados pra escala 0-100.
      prop_desmatado    = 100 * desmatado / area_km2,
      prop_incremento   = 100 * incremento / area_km2,
      prop_floresta     = 100 * floresta / area_km2,
      prop_nao_floresta = 100 * nao_floresta / area_km2,
      prop_hidrografia  = 100 * hidrografia / area_km2
    ) %>%
    select(
      cod_ibge, ano,
      desmatado, incremento, floresta, nao_floresta, hidrografia,
      prop_desmatado, prop_incremento, prop_floresta, prop_nao_floresta, prop_hidrografia
    )

  # O PRODES só mede desmatamento dentro da floresta amazônica original: a
  # franja de cerrado da Amazônia Legal (quase todo o TO, sul do MA, leste do
  # MT) é classificada como "não floresta" e por isso aparece com
  # desmatado == 0 em todos os anos — 0 correto por definição (não há
  # floresta pra desmatar), mas visualmente idêntico, nos bins de
  # desmatamento, a um município florestado que desmatou pouco. Marcamos os
  # municípios com menos de 1% da área histórica dentro da máscara de
  # floresta do PRODES pra pintar à parte (99 municípios, dos quais 93 com
  # <1% — ver troubleshooting.md/plano da rodada).
  fora_mascara <- prodes_raw %>%
    group_by(cod_ibge = as.character(cod_munic_ibge)) %>%
    summarise(fora_mascara = max((floresta + desmatado) / area_km2, na.rm = TRUE) < 0.01)

  # Grade completa: todos os municípios legal_amazon == 1 × todos os anos do
  # intervalo do app. Sem isso, um município sem linha no PRODES pra um ano
  # específico simplesmente some do mapa — foi o caso de Codó (MA), Mojuí
  # dos Campos (PA) e outros 10 municípios que o PRODES não monitora (ver
  # troubleshooting.md). Com a grade completa eles aparecem cinza ("sem
  # dado") em vez de sumir — não tem como inventar um número de
  # desmatamento que o INPE não mediu. munic_geo (sf) precisa ser o lado
  # esquerdo dos joins pra preservar a classe sf; munic_meta entra por
  # último, contra a grade completa (não contra df_attrs), pra nome/estado
  # aparecerem mesmo nos município-ano sem dado do PRODES.
  all_years <- param$year_inicio:param$year_final
  complete_grid <- tidyr::expand_grid(cod_ibge = munic_geo$cod_ibge, ano = all_years)

  df <- munic_geo %>%
    inner_join(complete_grid, by = "cod_ibge") %>%
    left_join(df_attrs, by = c("cod_ibge", "ano")) %>%
    left_join(munic_meta, by = "cod_ibge") %>%
    left_join(fora_mascara, by = "cod_ibge") %>%
    st_transform(crs = "+init=epsg:4326")

  # Monta as opções (agrupadas, restritas ao grupo do app) do seletor de
  # variável para o idioma informado
  x_choices_lang <- function(l) {
    tbl <- param$tables[[l]]
    choices <- append("", grouped_list(tbl[which(tbl$x)]))
    choices[param$app][[1]][1:5] # gambiarra p tirar opcoes de prop
  }

  server <- function(input, output, session) {

    # --- LANG TOGGLE ---

    lang <- reactiveVal("pt")

    observeEvent(input$toggle_lang, {
      lang(ifelse(lang() == "pt", "en", "pt"))
    })

    i18n <- reactive({ param$i18n[[lang()]] })
    tbl  <- reactive({ param$tables[[lang()]] })

    # Renderiza textos dinâmicos da sidebar
    output$plot_name_ui    <- renderUI({ h2(class = "plot_name", i18n()$plot_name) })
    output$plot_desc_ui    <- renderUI({ p(class = "plot_desc", i18n()$plot_desc) })
    output$label_var_name  <- renderText({ i18n()$label_var_name })
    output$label_prop_name <- renderText({ i18n()$label_prop_name })

    # Atualiza inputs e botões quando o idioma muda
    observeEvent(lang(), {
      updateSelectInput(session, "x",
        label    = i18n()$label_x_name,
        choices  = x_choices_lang(lang()),
        selected = isolate(input$x)
      )
      updateSliderInput(session, "filter1", label = i18n()$label_year)
      updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
      updateActionButton(session, "ab1", label = i18n()$btn_fullscreen)
    }, ignoreInit = FALSE)

    df_reactived <- reactive({
      w <- df %>%
        filter(ano == input$filter1)

      return(w)
    })

    x_var <- reactive({
        if (isTRUE(input$x_prop)) {
            nm <- paste0("prop_", input$x)
            # se por algum motivo a coluna não existir, cai para a base
            if (nm %in% names(df)) nm else input$x
        } else {
            input$x
        }
    })

    # Cria opções para seleção de datas
    param$filter_choices <- sort(unique(df$ano))

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      choices <- x_choices_lang(isolate(lang()))
      selected <- sample(sample(choices, 1)[[1]], 1)
      updateSelectInput(session,
        "x",
        choices = choices,
        selected = selected
      )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "lang=", lang(),
        "&", "x=", input$x,
        "&", "prop=", input$x_prop,
        "&", "filter=", input$filter1
      )

      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      # Idioma via deep-link (ex: ?lang=en)
      if (!is.null(query[["lang"]]) && query[["lang"]] %in% c("pt", "en")) {
        lang(query[["lang"]])
      }

      # Preenche filtro vazio
      if (!is.null(query[["x"]])) {
        # se tem x na url atribui valor ao selecinput x
        updateSelectInput(session, "x",
          choices = x_choices_lang(isolate(lang())),
          selected = query[["x"]]
        )
      }

      if (!is.null(query[["filter"]])) {
        updateSliderInput(session, "filter1", value = as.numeric(query[["filter"]]))
      }

      # Se query está vazia, preenche aleatório
      if (is.null(query[["filter"]]) && is.null(query[["x"]])) {
        random_inputs() # preenche inputs se estiverem vazios
      }
    }

    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$x) || input$x == "") {
        text <- " "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        text <- i18n()$label_title
      }

      text
    })
    output$plot_subtitle <- renderText({
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$x) || input$x == "") {
        text <- i18n()$subtitle_empty
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- tbl()[which(tbl()$var == x_var()), ]
        text <- paste0(i18n()$label_var_name, x_col$label)
      }

      text
    })

    # Função para atualizar url do app com parâmetros dos inputs sempre que
    # eles mudarem (fora do renderLeaflet: com bindCache, um cache hit não
    # re-executa o corpo do render, e a URL deixaria de refletir a seleção)
    observe({
      update_my_queryString()
    })

    # Output gráfico
    output$map <- renderLeaflet({

      fig <- leaflet() %>%
        addProviderTiles(provider = "CartoDB.PositronNoLabels") %>%
        setView(-58, -7, zoom = 5) # inicia figura com gráfico em branco

      # Define paleta de cores
      pal1 <- pallete_continuous
      if (!is.numeric(df_reactived()[[x_var()]])) {
        pal1 <- pallete_discrete
      }

      # Paleta com bins condicionais para desmatamento ---
      xv <- x_var()
      x_col <- tbl()[which(tbl()$var == xv), ]

      is_numeric <- is.numeric(df[[xv]])
      is_desmat  <- grepl("desmat", tolower(xv)) || grepl("desmat", tolower(x_col$label))
      is_prop    <- startsWith(xv, "prop_") || grepl("propor", tolower(x_col$label))

      # bins especiais para desmatamento
      bins <- NULL
      if (is_numeric && is_desmat && !is_prop) {
          # incremento absoluto (hectares)
          bins <- c(0, 10, 25, 50, 100, 200, 400, 800, 1600, Inf)
      } else if (is_numeric && is_desmat && is_prop) {
          # proporção do município (percentual)
          bins <- c(0, 1, 2, 3, 5, 10, 20, 40, 80, 100)
      }

      if (is_numeric) {
          if (!is.null(bins)) {
              pal <- colorBin(palette = pal1, bins = bins, domain = df[[xv]], right = FALSE)
          } else {
              # fallback padrão (9 classes)
              pal <- colorBin(palette = pal1, bins = 9, domain = df[[xv]])
          }
      } else {
          # categóricas continuam indo pela paleta discreta (mantendo compatibilidade)
          pal <- colorFactor(palette = pal1, domain = df[[xv]])
      }

      tryCatch(
        {

          # Monta mapa

          # Monta html do tooltip
          x_col <- tbl()[which(tbl()$var == x_var()), ]
          title_legend <- paste0(x_col$label, " (", x_col$unidade, ")")

          dfr <- df_reactived()

          # Municípios "fora da máscara" (sem floresta amazônica original pra
          # desmatar — ver comentário na montagem de fora_mascara) só ganham
          # tratamento visual separado quando a variável exibida é de
          # desmatamento; pra floresta/não-floresta/hidrografia o valor alto
          # de "não floresta" nesses municípios é legítimo e vai pela escala
          # normal. NA (municípios sem nenhuma linha no PRODES) vira FALSE
          # aqui — eles já ficam cinza por outro motivo (sem dado).
          fora <- is_desmat & !is.na(dfr$fora_mascara) & dfr$fora_mascara

          valor_fmt <- trimws(format(round(dfr[[xv]], 2), scientific = FALSE, decimal.mark = ",", big.mark = "."))
          labels <- paste0(
            i18n()$label_munic_name, dfr$nm_municip, "</b> <br>",
            i18n()$label_state_name, dfr$estado, "</b> <br>",
            x_col$label, ": <b>", valor_fmt, "</b> <br>",
            i18n()$label_measurement_unit, x_col$unidade, "</b>",
            ifelse(fora, paste0("<br> <i>", i18n()$tooltip_off_mask, "</i>"), "")
          ) %>%
            lapply(htmltools::HTML)

          fig_p <- leaflet(data = dfr) %>%
            addProviderTiles(provider = "CartoDB.PositronNoLabels") %>%
            setView(-58, -7, zoom = 5) %>%
            addPolygons(
              data = dfr[!fora, ],
              label = labels[!fora],
              stroke = FALSE,
              smoothFactor = .5,
              fillOpacity = 0.8,
              fillColor = ~ pal(dfr[[xv]][!fora]),
              highlightOptions = highlightOptions(
                weight = 5,
                fillOpacity = 1,
                color = "black",
                opacity = 1,
                bringToFront = TRUE
              )
            ) %>%
            addLegend("bottomright",
              pal = pal,
              values = ~ dfr[[xv]],
              title = title_legend,
              opacity = 0.8,
              labFormat = labFormat_bin_inf
            )

          # Camada à parte pros municípios fora da máscara de floresta do
          # PRODES: cor fixa fora da escala (bege), pra não ser confundida
          # nem com o bin de desmatamento baixo nem com o cinza de sem dado.
          if (any(fora)) {
            fig_p <- fig_p %>%
              addPolygons(
                data = dfr[fora, ],
                label = labels[fora],
                stroke = FALSE,
                smoothFactor = .5,
                fillOpacity = 0.9,
                fillColor = "#e8ded0",
                highlightOptions = highlightOptions(
                  weight = 5,
                  fillOpacity = 1,
                  color = "black",
                  opacity = 1,
                  bringToFront = TRUE
                )
              ) %>%
              addLegend("bottomright",
                colors = "#e8ded0",
                labels = i18n()$label_off_mask,
                opacity = 0.9
              )
          }

          legal_amazon_boundary <- readr::read_rds(files$legal_amazon)
          states_boundary <- readr::read_rds(files$states_boundary)

          fig_p <- fig_p %>%
            addPolylines(data = states_boundary, color = "grey", weight = 1) %>%
            addPolylines(data = legal_amazon_boundary, color = "black", weight = 2)

          # Corrige tooltips "presos" abertos: como os municípios são
          # poligonos adjacentes sem espaçamento, mover o mouse rápido pode
          # disparar mouseover no próximo polígono antes do mouseout do
          # anterior terminar, deixando vários tooltips abertos ao mesmo
          # tempo. Fechamos o tooltip anterior sempre que um novo abre, e
          # deixamos o Leaflet cuidar do fechamento nativo no mouseout de
          # cada camada.
          fig_p <- fig_p %>%
            htmlwidgets::onRender("
              function(el, x) {
                var map = this;
                var openLayer = null;
                map.eachLayer(function(layer) {
                  if (layer.getTooltip && layer.getTooltip()) {
                    layer.on('mouseover', function(e) {
                      if (openLayer && openLayer !== layer) {
                        openLayer.closeTooltip();
                      }
                      openLayer = layer;
                    });
                    layer.on('mouseout', function(e) {
                      if (openLayer === layer) {
                        openLayer = null;
                      }
                    });
                  }
                });
              }
            ")

          fig <- fig_p # retorna a figura do gráfico
        },
        error = function(cond) {
          # se encontrar erro retorna fig em branco
          print("Plot error in tryCatch environment")
        }
      )
      fig
    }) %>%
      bindCache(input$x, input$x_prop, input$filter1, lang())

    # Observa eventos
    observe({
      update_my_inputs()
    })
  }

  # Retorna objeto server
  server
}
