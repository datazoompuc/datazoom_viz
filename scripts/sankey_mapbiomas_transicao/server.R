# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# hex -> rgba, para deixar os links translúcidos sem perder a cor da classe de origem
hex_rgba <- function(hex, alpha = 0.45) {
  rgb <- grDevices::col2rgb(hex)
  paste0("rgba(", rgb[1], ",", rgb[2], ",", rgb[3], ",", alpha, ")")
}

# Funcão para retornar objeto server
get_server <- function(files, param) {

  # Carrega as duas bases (o toggle geográfico decide qual está ativa).
  # Schema (igual nas duas): time, group, from, to, value -- from/to em inglês.
  df_est   <- readRDS(files$db_file_est)   %>% dplyr::ungroup()
  df_munic <- readRDS(files$db_file_munic) %>% dplyr::ungroup()

  # Legenda oficial do MapBiomas: traduz as chaves em inglês para PT e define a
  # ordem das classes (usada para fixar a cor de cada classe entre seleções)
  legenda  <- data.table::fread(files$legenda, encoding = "UTF-8")
  lab_pt   <- setNames(legenda$nome_pt, legenda$nome_en)
  classes  <- sort(unique(c(df_est$from, df_est$to, df_munic$from, df_munic$to)))
  cor_classe <- setNames(
    pallete_discrete[(seq_along(classes) - 1) %% length(pallete_discrete) + 1],
    classes
  )

  # 1º ano da série (rótulo do acumulado) -- igual ao ts_mapbiomas_transicao
  yr_first <- sub(" .*", "", sort(unique(c(df_est$time, df_munic$time)))[1])

  server <- function(input, output, session) {

    # ---------------------------- Idioma ----------------------------
    lang <- reactiveVal({
      query <- parseQueryString(isolate(session$clientData$url_search))
      if (identical(query[["lang"]], "en")) "en" else "pt"
    })
    observeEvent(input$toggle_lang, {
      new_lang <- ifelse(lang() == "pt", "en", "pt")
      lang(new_lang)
      updateActionButton(session, "toggle_lang",
                         label = param$i18n[[new_lang]]$btn_lang)
    })
    i18n <- reactive({ param$i18n[[lang()]] })

    # Rótulo de uma classe no idioma corrente (EN é a própria chave)
    rotulo <- function(x, lg) {
      if (lg != "pt") return(x)
      out <- unname(lab_pt[x])
      ifelse(is.na(out), x, out)
    }

    # ---------------------------- Nível geográfico ----------------------------
    # Estado/Município via dois actionButton (não mais materialSwitch) -- mesmo
    # padrão de scripts/ts_mapbiomas_cobertura/server.R.
    geo <- reactiveVal({
      query <- parseQueryString(isolate(session$clientData$url_search))
      if (identical(query[["geo"]], "munic")) "munic" else "est"
    })
    observeEvent(input$geo_est,   { geo("est") })
    observeEvent(input$geo_munic, { geo("munic") })
    observeEvent(geo(), {
      session$sendCustomMessage("setGeo", geo())
    }, ignoreInit = FALSE)

    df <- reactive({ if (geo() == "munic") df_munic else df_est })

    output$label_agg       <- renderText({ i18n()$label_agg })
    output$label_geo_est   <- renderText({ i18n()$label_geo_name$est })
    output$label_geo_munic <- renderText({ i18n()$label_geo_name$munic })
    output$plot_desc       <- renderText({ i18n()$plot_desc })
    output$label_var_name  <- renderText({ i18n()$label_var_name })

    # Switch renderizado aqui para que o label acompanhe o idioma
    output$switches <- renderUI({
      i <- param$i18n[[lang()]]
      materialSwitch("accumulate",
        tags$span(sprintf(i$label_accum, yr_first), class = "switch-label"),
        value = isTRUE(isolate(input$accumulate)), status = "info")
    })

    # ---------------------------- Escolhas reativas ----------------------------
    # O intervalo NÃO é input: vira o slider de animação do plotly (um frame por
    # janela), mesmo padrão de scripts/sankey/server.R (COMEX).
    filter_choices <- reactive({
      fc <- sort(unique(df()$group))
      fc[fc != " - " & !is.na(fc)]
    })

    # ---------------------------- Preenchimento inicial / aleatório ----------------------------
    random_inputs <- function() {
      fc <- filter_choices()
      updateSelectizeInput(session, "filter1",
                           label = i18n()$label_geo_name[[geo()]],
                           choices = fc,
                           selected = sample(fc, 1))
    }

    # ---------------------------- URL <-> inputs ----------------------------
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "lang=", lang(),
        "&", "geo=", geo(),
        "&", "top_n=", input$top_n,
        "&", "accumulate=", isTRUE(input$accumulate),
        "&", "filter=", input$filter1
      )
      updateQueryString(q_string, mode = "replace")
    }

    update_my_inputs <- function() {
      query <- parseQueryString(session$clientData$url_search)
      fc <- filter_choices()

      if (!is.null(query[["top_n"]])) {
        updateSelectInput(session, "top_n", selected = query[["top_n"]])
      }
      if (!is.null(query[["accumulate"]])) {
        updateMaterialSwitch(session, "accumulate",
                             value = (query[["accumulate"]] == "TRUE"))
      }
      if (!is.null(query[["filter"]]) && query[["filter"]] %in% fc) {
        updateSelectizeInput(session, "filter1",
                             label = i18n()$label_geo_name[[geo()]],
                             choices = fc, selected = query[["filter"]])
      }
      # Se query está vazia, preenche aleatório
      if (is.null(query[["filter"]])) {
        random_inputs()
      }
    }

    # Retraduz os labels ao trocar idioma (mantém a seleção: group é a mesma chave
    # nos dois idiomas)
    observeEvent(lang(), {
      updateSelectizeInput(session, "filter1",
                           label = i18n()$label_geo_name[[geo()]],
                           selected = isolate(input$filter1))
      updateSelectInput(session, "top_n",
                        label = i18n()$label_topn_name,
                        selected = isolate(input$top_n))
      updateActionButton(session, "ab1", label = i18n()$btn_fullscreen)
    }, ignoreInit = TRUE)

    # Ao trocar de nível geográfico os recortes mudam (9 estados x 772 municípios)
    observeEvent(geo(), {
      fc <- filter_choices()
      updateSelectizeInput(session, "filter1",
                           label = i18n()$label_geo_name[[geo()]],
                           choices = fc, selected = sample(fc, 1))
    }, ignoreInit = TRUE)

    # ---------------------------- Dados do gráfico ----------------------------
    # Fluxos de UMA unidade geográfica na i-ésima janela. O filtro de
    # persistência (from == to) já foi aplicado no data-raw; fica aqui só como
    # rede de segurança caso a base seja regerada sem ele.
    #
    # Com `acumular`, soma as janelas da 1ª até a i-ésima. As duas grades são
    # anuais consecutivas, portanto NÃO sobrepostas, e a soma não dupla-conta
    # (o data-raw checa isso). O resultado é a área BRUTA que foi
    # de A para B no período -- NÃO é a matriz de transição entre o 1º e o último
    # ano, que não pode ser obtida somando janelas (transição não é aditiva).
    fluxos_janela <- function(d_grp, janelas, i, acumular, n) {
      d <- if (acumular) {
        d_grp[d_grp$time %in% janelas[seq_len(i)], ]
      } else {
        d_grp[d_grp$time == janelas[i], ]
      }
      d <- d[d$from != d$to & !is.na(d$value) & d$value > 0, ]

      # No acumulado o mesmo par de/para aparece em várias janelas: consolida
      if (acumular && nrow(d) > 0) {
        d <- d %>%
          dplyr::group_by(from, to) %>%
          dplyr::summarise(value = sum(value), .groups = "drop") %>%
          as.data.frame()
      }

      d <- d[order(-d$value), ]
      if (nrow(d) > n) d <- d[seq_len(n), ]
      d
    }

    # Nós e links de um frame. Origens à esquerda, destinos à direita: uma mesma
    # classe aparece dos dois lados como nós distintos (é o que dá a leitura
    # de/para). O empilhamento vertical é proporcional ao total de cada nó.
    build_nodes_links <- function(d, lg, janela_txt) {
      srcs <- unique(d$from)
      tgts <- unique(d$to)
      ns   <- length(srcs)
      nt   <- length(tgts)

      centro <- function(vals) {
        frac <- vals / sum(vals)
        tops <- cumsum(c(0, head(frac, -1)))
        pmin(pmax(tops + frac / 2, 1e-3), 1 - 1e-3)
      }
      tot_src <- vapply(srcs, function(s) sum(d$value[d$from == s]), numeric(1))
      tot_tgt <- vapply(tgts, function(t) sum(d$value[d$to == t]), numeric(1))

      list(
        node = list(
          label     = c(rotulo(srcs, lg), rotulo(tgts, lg)),
          color     = unname(c(cor_classe[srcs], cor_classe[tgts])),
          pad       = 15,
          thickness = 14,
          line      = list(color = "black", width = 0.5),
          x         = c(rep(0.01, ns), rep(0.99, nt)),
          y         = c(centro(tot_src), centro(tot_tgt)),
          hovertemplate = "<b>%{label}</b><extra></extra>"
        ),
        link = list(
          source = match(d$from, srcs) - 1L,
          target = ns + match(d$to, tgts) - 1L,
          value  = d$value,
          color  = vapply(unname(cor_classe[d$from]), hex_rgba, character(1)),
          # o intervalo vai no hover: o rótulo do slider é curto por espaço, então
          # é aqui que a janela completa fica sempre disponível
          hovertemplate = paste0(
            "<b>%{source.label}</b> ", i18n()$to_connector, " <b>%{target.label}</b>",
            "<br>", janela_txt,
            "<br>%{value}<extra></extra>"
          )
        )
      )
    }

    # Período do i-ésimo passo: no acumulado vai do 1º ano até o fim da janela,
    # no normal é a própria janela. Usado no hover, nos frames e no subtítulo.
    periodo_txt <- function(janelas, i, acum) {
      if (acum) paste0(yr_first, " - ", sub(".* - ", "", janelas[i])) else janelas[i]
    }

    # ---------------------------- Passo ativo do slider ----------------------------
    # O slider é do plotly e roda no navegador. O `event_data()` do R NÃO cobre
    # os eventos de slider (`plotly_sliderchange`/`plotly_animatingframe`), e
    # `plotly_relayout` não dispara com eles -- por isso o listener JS abaixo
    # (em onRender) devolve o nome do frame ativo para o Shiny.
    #   sliderchange   -> arrasto/clique manual no slider
    #   animatingframe -> cada frame durante o play
    # O nome do frame é a própria janela ("1996 - 1997"), então serve direto.
    passo_frame <- reactiveVal(NULL)
    observeEvent(input$slider_frame, { passo_frame(input$slider_frame) })
    # Qualquer coisa que redesenhe o gráfico volta ao último frame: zera o passo
    observeEvent(list(geo(), input$filter1, input$accumulate, input$top_n), {
      passo_frame(NULL)
    }, ignoreInit = TRUE)

    # ---------------------------- Títulos ----------------------------
    output$plot_title <- renderText({
      if (is.null(input$filter1) || input$filter1 == "") return(" ")
      input$filter1
    })

    output$plot_subtitle <- renderText({
      if (is.null(input$filter1) || input$filter1 == "") return(" ")
      janelas <- sort(unique(df()$time))
      if (!length(janelas)) return(" ")

      # Frame ativo. O JS manda o nome do frame (= a janela) ou, se o payload do
      # plotly não trouxer o nome, o índice no formato "#n" (base 0).
      atual <- passo_frame()
      i <- NA_integer_
      if (!is.null(atual) && nzchar(atual)) {
        i <- if (startsWith(atual, "#")) {
          suppressWarnings(as.integer(sub("^#", "", atual))) + 1L
        } else {
          match(atual, janelas)
        }
      }
      # sem evento ainda (ou valor de outra grade): mostra o último
      if (is.na(i) || i < 1L || i > length(janelas)) i <- length(janelas)
      acum <- isTRUE(input$accumulate)

      metrica <- if (acum) sprintf(i18n()$subtitle_accum, yr_first) else i18n()$subtitle_init
      paste0(periodo_txt(janelas, i, acum), " · ", metrica)
    })

    # ---------------------------- Gráfico ----------------------------
    output$plot <- renderPlotly({
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco
      tryCatch(
        {
          req(input$filter1, input$top_n)
          lg      <- lang()
          acum    <- isTRUE(input$accumulate)
          n       <- as.integer(input$top_n)
          d_grp   <- df()[df()$group == input$filter1, ]
          janelas <- sort(unique(df()$time))
          if (!length(janelas) || nrow(d_grp) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Frame inicial = última janela (a mais recente)
          d0 <- fluxos_janela(d_grp, janelas, length(janelas), acum, n)
          if (nrow(d0) < 1) {
            fig <- plotly_empty()
            stop()
          }
          nl0 <- build_nodes_links(d0, lg, periodo_txt(janelas, length(janelas), acum))

          fig_p <- plot_ly(
            type        = "sankey",
            orientation = "h",
            arrangement = "fixed", # respeita as posições y calculadas acima
            valueformat = ",.0f",
            valuesuffix = paste0(" ", i18n()$unit),
            hoverlabel  = list(namelength = -1),
            node = nl0$node,
            link = nl0$link
          )

          # Um frame por janela (o plotly redesenha o sankey a cada frame, o que
          # é necessário aqui: o conjunto de classes muda de uma janela para outra)
          fig_p$x$frames <- lapply(seq_along(janelas), function(i) {
            nl <- build_nodes_links(fluxos_janela(d_grp, janelas, i, acum, n),
                                    lg, periodo_txt(janelas, i, acum))
            list(
              name = as.character(janelas[i]),
              data = list(list(node = nl$node, link = nl$link))
            )
          })

          # Rótulo dos passos do slider. No acumulado o início é sempre o mesmo
          # (o 1º ano), então só o ano final informa e cabe folgado. No modo
          # normal a janela exata é que informa, e vai inteira.
          rot_passo <- if (acum) sub(".* - ", "", janelas) else janelas
          steps <- lapply(seq_along(janelas), function(i) {
            list(
              method = "animate",
              label  = rot_passo[i],
              args = list(
                list(as.character(janelas[i])),
                list(mode = "immediate",
                     frame = list(duration = 10, redraw = TRUE),
                     transition = list(duration = 0))
              )
            )
          })

          prefixo <- if (acum) i18n()$slider_prefix_accum else i18n()$slider_prefix_window

          # Layout + slider + botões de play/pause nativos do plotly
          fig_p <- fig_p %>%
            layout(
              font   = f1,
              margin = list(l = 10, r = 10, t = 10, b = 80),
              sliders = list(list(
                active = length(janelas) - 1,
                x = 0.05, len = 0.9, pad = list(t = 30),
                currentvalue = list(prefix = paste0(prefixo, ": "), font = f1),
                steps = steps
              )),
              updatemenus = list(list(
                type = "buttons", direction = "left", showactive = FALSE,
                x = 0.05, y = -0.02, xanchor = "right", yanchor = "top",
                pad = list(t = 30, r = 10),
                buttons = list(
                  list(method = "animate", label = "▶",
                       args = list(NA, list(mode = "immediate", fromcurrent = FALSE,
                                            frame = list(duration = 1500, redraw = TRUE),
                                            transition = list(duration = 0)))),
                  list(method = "animate", label = "⏸",
                       args = list(list(), list(mode = "immediate",
                                            frame = list(duration = 0, redraw = FALSE),
                                            transition = list(duration = 0))))
                )
              ))
            ) %>%
            config(
              displaylogo = FALSE,
              modeBarButtonsToRemove = c(
                "lasso2d",
                "select2d",
                "hoverCompareCartesian"
              )
            ) %>%
            # Devolve ao Shiny o frame ativo para o subtítulo acompanhar o
            # slider. Os dois eventos são necessários: sliderchange cobre o
            # arrasto manual, animatingframe cobre o play. Nenhum dos dois é
            # exposto pelo event_data() do plotly em R.
            htmlwidgets::onRender(
              "function(el) {
                 var envia = function(v) {
                   if (v === undefined || v === null || v === '') return;
                   Shiny.setInputValue('slider_frame', String(v), {priority: 'event'});
                 };
                 // O formato do payload varia entre evento e versao do plotly,
                 // entao tenta na ordem: nome do frame -> args do passo ->
                 // indice ativo (enviado como '#n', que o server sabe ler).
                 var trata = function(d) {
                   if (!d) return;
                   if (d.frame && d.frame.name) { envia(d.frame.name); return; }
                   if (d.step && d.step.args && d.step.args[0] && d.step.args[0][0]) {
                     envia(d.step.args[0][0]); return;
                   }
                   if (d.slider && d.slider.active !== undefined) {
                     envia('#' + d.slider.active); return;
                   }
                   if (d.step && d.step.label) { envia(d.step.label); return; }
                 };
                 el.on('plotly_animatingframe', trata);
                 el.on('plotly_sliderchange', trata);
                 // ultimo recurso: le o indice direto do proprio grafico
                 el.on('plotly_animated', function() {
                   try {
                     var s = el.layout.sliders[0];
                     if (s && s.active !== undefined) envia('#' + s.active);
                   } catch (e) {}
                 });
               }"
            )

          fig <- fig_p # retorna a figura do gráfico
        },
        error = function(cond) {
          # se encontrar erro retorna fig em branco
          print("plot error")
          fig <- plotly_empty()
        }
      )
      fig
    })

    # Observa eventos
    observe({
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)
      update_my_inputs()
    })
  }

  # Retorna objeto server
  server
}
