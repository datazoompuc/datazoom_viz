# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis
pallete_discrete <- rev(pallete_discrete)
pallete_continuous <- rev(pallete_continuous)

# Funcão para retornar objeto server
get_server <- function(files, param) {

  # Carrega dados
  df <- readRDS(files$db_file) %>% st_transform(crs = "+init=epsg:4326")

  # Monta as opções (agrupadas) do seletor de variável para o idioma informado
  x_choices_lang <- function(l) {
    tbl <- param$tables[[l]]
    choices <- append("", grouped_list(tbl[which(tbl$x), ]))
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

    # Atualiza inputs e botões quando o idioma muda
    observeEvent(lang(), {
      updateSelectInput(session, "x",
        label    = i18n()$label_x_name,
        choices  = x_choices_lang(lang()),
        selected = isolate(input$x)
      )
      updateSliderInput(session, "filter1", label = i18n()$label_year)
      updateActionButton(session, "toggle_lang", label = i18n()$btn_lang, icon = icon("globe"))
      updateActionButton(session, "ab1", label = i18n()$btn_fullscreen, icon = icon("expand"))
    }, ignoreInit = FALSE)

    df_reactived <- reactive({
      req(input$filter1)
      df %>% filter(ano == input$filter1)
    })

    # Cria opções para seleção de datas
    param$filter_choices <- sort(unique(df$ano))

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
        "&", "filter=", input$filter1
      )

      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      query <- parseQueryString(session$clientData$url_search)

      # Idioma via deep-link (ex: ?lang=en)
      if (!is.null(query[["lang"]]) && query[["lang"]] %in% c("pt", "en")) {
        lang(query[["lang"]])
      }

      # Preenche filtro vazio
      if (!is.null(query[["x"]])) {
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
        random_inputs()
      }
    }

    # Output título do gráfico
    output$plot_title <- renderText({
      if (is.null(input$x) || input$x == "") {
        return(" ")
      }
      i18n()$label_title
    })

    output$plot_subtitle <- renderText({
      if (is.null(input$x) || input$x == "") {
        return(i18n()$subtitle_empty)
      }
      x_col <- tbl()[which(tbl()$var == input$x), ]
      paste0(i18n()$label_selected_variable, x_col$label)
    })

    # Inicialização do Mapa Leaflet
    output$map <- renderLeaflet({
      leaflet() %>%
        addProviderTiles(provider = "Esri.WorldGrayCanvas") %>%
        setView(-58, -7, zoom = 5) %>%
        # Painel customizado para que os contornos fiquem permanentemente fixados no topo sem piscar ao mudar de ano
        addMapPane("boundaries_pane", zIndex = 450) %>%
        addPolylines(
          data = readr::read_rds(files$states_boundary),
          color = "grey",
          weight = 1,
          options = pathOptions(pane = "boundaries_pane")
        ) %>%
        addPolylines(
          data = readr::read_rds(files$legal_amazon),
          color = "black",
          weight = 2,
          options = pathOptions(pane = "boundaries_pane")
        )
    })

    # Observer para atualizar o mapa de forma incremental e ultra-rápida via leafletProxy
    observe({
      req(input$x, input$filter1, lang())
      
      df_sub <- df_reactived()
      var_name <- input$x
      
      # Define paleta de cores
      pal1 <- pallete_continuous
      if (!is.numeric(df_sub[[var_name]])) {
        pal1 <- pallete_discrete
      }

      # Determina a paleta para as legendas
      pal <- colorBin(palette = pal1, 9, domain = df[[var_name]])

      tryCatch(
        {
          # Monta html do tooltip
          x_col <- tbl()[which(tbl()$var == var_name), ]
          title_legend <- ifelse(is.na(x_col$unidade) | x_col$unidade == "", x_col$label, paste0(x_col$label, " (", x_col$unidade, ")"))
          labels <- paste0(
            i18n()$label_munic_name, df_sub$nm_municip, "</b> <br>",
            i18n()$label_state_name, df_sub$uf, "</b> <br>",
            x_col$label, ": <b>", trimws(format(round(df_sub[[var_name]], 2), 
                                         scientific = FALSE,
                                         decimal.mark = ",", 
                                         big.mark = ".")), "</b>",
            ifelse(is.na(x_col$unidade) | x_col$unidade == "", "", paste0(" <br>", i18n()$label_measurement_unit, x_col$unidade, "</b>"))
          ) %>%
            lapply(htmltools::HTML)

          # Atualiza a URL (efeito colateral)
          update_my_queryString()

          # Atualiza o mapa incrementalmente
          leafletProxy("map", data = df_sub) %>%
            clearControls() %>%
            addPolygons(
              label = labels,
              layerId = ~cod_ibge,
              stroke = FALSE,
              smoothFactor = .5,
              fillOpacity = ifelse(is.na(df_sub[[var_name]]), 1, 0.8),
              fillColor = ~ pal(df_sub[[var_name]]),
              group = "municipalities",
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
              values = ~ df_sub[[var_name]],
              title = title_legend,
              opacity = 0.8
            ) %>%
            # Garante que os tooltips não fiquem presos nas novas camadas
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
        },
        error = function(cond) {
          print(paste("Plot error:", cond))
        }
      )
    })

    # Observa eventos
    observe({
      query <- parseQueryString(session$clientData$url_search)
      update_my_inputs()
    })
  }

  # Retorna objeto server
  server
}
