# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis
pallete_discrete <- rev(pallete_discrete)
pallete_continuous <- rev(pallete_continuous)

# Fontes

# Funcão para retornar objeto server
get_server <- function(files, param) {

  # Carrega dados: atributos (PPM) e geometria são fontes separadas, unidas
  # aqui em memória — mesmo padrão de map_mapbiomas_cover/map_dz_munic_prodes.
  # Evita depender de data/dz_munic_simplified.rds (arquivo combinado de 14
  # fontes, com geometria desatualizada; ver troubleshooting.md).
  munic_geo <- readr::read_rds(files$shapefile) %>%
    filter(legal_amazon == 1) %>%
    st_make_valid() %>%
    transmute(cod_ibge = as.character(municipality_code), geometry = geom)

  # data/ppm_municipality_livestock_inventory.rds não traz nome de
  # município nem estado — vêm do dado de pacote (mesma fonte que o
  # próprio data-raw/dz_munic.R usava).
  munic_meta <- datazoom.amazonia::municipalities %>%
    transmute(
      cod_ibge = as.character(code_muni),
      nm_municip = municipality_mapbiomas,
      estado = abbrev_state
    )

  # dplyr:: explícito: o rename() sem qualificar quebra se algum pacote
  # carregado depois de tidyverse (ex: plyr) mascarar dplyr::rename() com
  # uma assinatura diferente — já aconteceu nesta sessão.
  df_attrs <- readRDS(files$db_file) %>%
    dplyr::rename(cod_ibge = geo_id, ano = time) %>%
    mutate(cod_ibge = as.character(cod_ibge)) %>%
    select(cod_ibge, ano, num_v2670, num_v32794, num_v32796)

  # Grade completa: todos os municípios legal_amazon == 1 × todos os anos do
  # intervalo do app. Sem isso, um município sem linha na fonte pra um ano
  # específico simplesmente some do mapa naquele ano — foi o caso de vários
  # municípios em anos antigos, quando a pesquisa do PPM ainda não cobria
  # todo mundo (cobertura cresce de verdade ao longo do tempo, não é bug).
  # Com a grade completa, o município aparece cinza ("sem dado") em vez de
  # sumir. munic_geo (sf) precisa ser o lado esquerdo dos joins pra
  # preservar a classe sf; munic_meta entra por último, contra a grade
  # completa (não contra df_attrs), pra nome/estado aparecerem mesmo nos
  # município-ano sem dado do PPM.
  all_years <- param$year_inicio:param$year_final
  complete_grid <- tidyr::expand_grid(cod_ibge = munic_geo$cod_ibge, ano = all_years)

  df <- munic_geo %>%
    inner_join(complete_grid, by = "cod_ibge") %>%
    left_join(df_attrs, by = c("cod_ibge", "ano")) %>%
    left_join(munic_meta, by = "cod_ibge") %>%
    st_transform(crs = "+init=epsg:4326")

  # Monta as opções (agrupadas, restritas ao grupo do app) do seletor de
  # variável para o idioma informado
  x_choices_lang <- function(l) {
    tbl <- param$tables[[l]]
    choices <- append("", grouped_list(tbl[which(tbl$x)]))
    choices[param$app][[1]] # só as 3 variáveis do grupo IBGE - PPM
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
    output$plot_name_ui   <- renderUI({ h2(class = "plot_name", i18n()$plot_name) })
    output$plot_desc_ui   <- renderUI({ p(class = "plot_desc", i18n()$plot_desc) })
    output$label_var_name <- renderText({ i18n()$label_var_name })

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

    # Função para atualizar url do app com parâmetros dos inputs sempre que
    # eles mudarem (fora do renderLeaflet: com bindCache, um cache hit não
    # re-executa o corpo do render, e a URL deixaria de refletir a seleção)
    observe({
      q_string <- paste0(
        "?", "lang=", lang(),
        "&", "x=", input$x,
        "&", "filter=", input$filter1
      )

      updateQueryString(q_string, mode = "replace")
    })

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
        x_col <- tbl()[which(tbl()$var == input$x), ]
        text <- paste0(i18n()$label_var_name, x_col$label)
      }

      text
    })

    # Output gráfico
    output$map <- renderLeaflet({

      fig <- leaflet() %>%
        addProviderTiles(provider = "CartoDB.PositronNoLabels") %>%
        setView(-58, -7, zoom = 5) # inicia figura com gráfico em branco

      # Define paleta de cores
      pal1 <- pallete_continuous
      if (!is.numeric(df_reactived()[[input$x]])) {
        pal1 <- pallete_discrete
      }

      # Determina a paleta para as legendas
      pal <- colorBin(palette = pal1, bins = 9, domain = df[[input$x]])

      tryCatch(
        {

          # Monta mapa

          # Monta html do tooltip
          x_col <- tbl()[which(tbl()$var == input$x), ]
          title_legend <- paste0(x_col$label, " (", x_col$unidade, ")")
          valor_fmt <- trimws(format(round(df_reactived()[[input$x]], 2), scientific = FALSE, decimal.mark = ",", big.mark = "."))
          labels <- paste0(
            i18n()$label_munic_name, df_reactived()$nm_municip, "</b> <br>",
            i18n()$label_state_name, df_reactived()$estado, "</b> <br>",
            x_col$label, ": <b>", valor_fmt, "</b> <br>",
            i18n()$label_measurement_unit, x_col$unidade, "</b>"
          ) %>%
            lapply(htmltools::HTML)

          fig_p <- df_reactived() %>%
            leaflet() %>%
            addProviderTiles(provider = "CartoDB.PositronNoLabels") %>%
            setView(-58, -7, zoom = 5) %>%
            addPolygons(
              label = labels,
              stroke = FALSE,
              smoothFactor = .5,
              fillOpacity = 0.8,
              fillColor = ~ pal(df_reactived()[[input$x]]),
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
              values = ~ df_reactived()[[input$x]],
              title = title_legend,
              opacity = 0.8
            )

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
      bindCache(input$x, input$filter1, lang())

    # Observa eventos
    observe({
      update_my_inputs()
    })
  }

  # Retorna objeto server
  server
}
