# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis
pallete_discrete <- rev(pallete_discrete)
pallete_continuous <- rev(pallete_continuous)

# Fontes

# Funcão para retornar objeto server
get_server <- function(files, param) {

  # Carrega dados
  library(sf)
  df <- arrow::open_dataset(files$db_file)

  # Recupera Polygon salvo em outro arquivo
  shapefile <- readr::read_rds(files$shapefile)

  # Monta as opções (agrupadas) do seletor de variável para o idioma informado
  x_choices_lang <- function(l) {
    tbl <- param$tables[[l]]
    choices <- append("", grouped_list(tbl[which(tbl$x)]))
    choices[[1]] <- NULL
    choices
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
    output$label_toggle   <- renderText({ i18n()$label_toggle })

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

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      selected <- param$x_def
      updateSelectInput(session,
        "x",
        choices = x_choices_lang(isolate(lang())),
        selected = selected
      )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "lang=", lang(),
        "&", "x=", input$x,
        "&", "prop=", input$yprop,
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
        text <- paste0(i18n()$label_selected_variable, x_col$label)
      }

      text
    })

    # Output gráfico
    output$map <- renderLeaflet({

        # Define df_reactived aqui, carregando só as colunas necessárias
        df_reactived <- df %>%
            filter(year == input$filter1) %>%
            select(all_of(c(input$x, "area_km2", param$text_def, param$state, "municipality_code"))) %>%
            collect() # acaba o lazy loading

        if (input$yprop) {
            df_reactived <- df_reactived %>%
                mutate(!!input$x := .data[[input$x]] / area_km2)
        }

        df_reactived <- inner_join(
            shapefile, df_reactived,
            by = "municipality_code"
        )

      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- leaflet() %>%
        addProviderTiles(provider = "Esri.WorldShadedRelief") %>%
        setView(-58, -7, zoom = 5) # inicia figura com gráfico em branco

      # Define paleta de cores
      pal1 <- pallete_continuous
      if (!is.numeric(df_reactived[[input$x]])) {
        pal1 <- pallete_discrete
      }

      # Determina a paleta para as legendas
      pal <- colorBin(palette = pal1, 9, domain = df_reactived[[input$x]])

      tryCatch(
        {

          # Monta mapa

          # Monta html do tooltip
            x_col <- tbl()[which(tbl()$var == input$x), ]
            if (input$yprop) {
                   x_col$unidade <- "%"
                 }


          title_legend <- paste0(x_col[["label"]], " (", x_col$unidade, ")")
          labels <- paste0(
            i18n()$label_munic_name, df_reactived[[param$text_def]], "</b> <br>",
            i18n()$label_state_name, df_reactived[[param$state]], "</b> <br>",
            x_col[["label"]], ": <b>", trimws(format(round(df_reactived[[input$x]], 2),
                                         scientific = FALSE,
                                         decimal.mark = ",",
                                         big.mark = ".")), "</b> <br>",
            i18n()$label_measurement_unit, x_col[["unidade"]], "</b>"
          ) %>%
            lapply(htmltools::HTML)

          fig_p <- df_reactived %>%
            leaflet() %>%
            addProviderTiles(provider = "Esri.WorldShadedRelief") %>%
            setView(-58, -7, zoom = 5) %>%
            addPolygons(
              label = labels,
              stroke = FALSE,
              smoothFactor = .5,
              fillOpacity = 1,
              fillColor = ~ pal(df_reactived[[input$x]]),
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
              values = ~ df_reactived[[input$x]],
              title = title_legend,
              opacity = 1
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
          # cada camada (mexer nisso quebrou o hover numa tentativa
          # anterior).
          #
          # Limitação conhecida e aceita: se o usuário sai da janela do
          # navegador sem que o mouseout dispare (ex: clica em outro
          # monitor), o último tooltip pode ficar visível até o próximo
          # hover. Edge case raro, não vale o risco de regressão no hover
          # normal para cobri-lo.
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
        bindCache(input$x, input$yprop, input$filter1, lang())

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
