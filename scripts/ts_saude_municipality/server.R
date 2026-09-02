# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# Funcão para retornar objeto server
get_server <- function(files, param) {
  server <- function(input, output, session) {
    
    # --- LANG TOGGLE & LOCALIZATION ---
    # Reativo de idioma
    lang <- reactiveVal("pt")
    
    # Troca o idioma quando o botão é clicado
    observeEvent(input$toggle_lang, {
      lang(ifelse(lang() == "pt", "en", "pt"))
    })
    
    # Atalho para traduções e tabela ativa
    i18n <- reactive({ param$i18n[[lang()]] })
    active_table <- reactive({ param$tables[[lang()]] })
    
    # Renderiza textos dinâmicos da UI
    output$plot_name_ui  <- renderUI({ h2(class = "plot_name", param$plot_name) })
    output$plot_desc_ui  <- renderUI({ p(class = "plot_desc", i18n()$plot_desc) })
    output$label_var_name <- renderText({ i18n()$label_var_name })
    output$label_scale_name <- renderText({ i18n()$label_scale_name })
    output$label_prop_name  <- renderText({ i18n()$label_prop_name })

    # Carrega dados
    df <- readRDS(files$db_file)
    all_municipios <- sort(unique(df$municipio))

    # Atualiza choices e labels ao trocar idioma
    observeEvent(lang(), {
      tbl <- active_table()
      y_sel <- isolate(input$y)
      if (is.null(y_sel) || y_sel == "") y_sel <- param$y_def
      
      updateSelectInput(
        session,
        "y",
        label    = i18n()$label_y_name,
        choices  = setNames(tbl$var[tbl$y], tbl$label[tbl$y]),
        selected = y_sel
      )
      
      updateSelectizeInput(
        session,
        "filter1",
        label    = i18n()$label_geo_name,
        choices  = all_municipios,
        server   = TRUE
      )
      
      updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
      updateActionButton(session, "ab1",         label = i18n()$btn_fullscreen)
    }, ignoreInit = TRUE)

    # Inicializa escolhas do seletor de municípios (server-side para fluidez)
    updateSelectizeInput(
      session,
      "filter1",
      choices  = all_municipios,
      selected = param$munic_def,
      server   = TRUE
    )

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "lang=", lang(),
        "&", "y=", input$y,
        "&", "ylog=", input$ylog,
        "&", "y_index_base=", input$y_index_base
      )

      for (i in input$filter1) {
        q_string <- paste0(q_string, "&", "filter=", i)
      }

      updateQueryString(q_string, mode = "replace")
    }

    # Flag R simples — não reativa, portanto não cria dependências.
    # Garante que update_my_inputs só processa a URL uma vez (no carregamento inicial).
    .url_read <- FALSE

    update_my_inputs <- function() {
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["lang"]]) && query[["lang"]] %in% c("pt", "en")) {
        lang(query[["lang"]])
      }

      if (!is.null(query[["y"]])) {
        updateSelectInput(session, "y",
          choices  = setNames(active_table()$var[active_table()$y],
                              active_table()$label[active_table()$y]),
          selected = query[["y"]]
        )
      }

       if (!is.null(query[["ylog"]])) {
         updateMaterialSwitch(session, "ylog",
           value = (query[["ylog"]] == "TRUE")
         )
       }

      if (!is.null(query[["y_index_base"]])) {
        updateMaterialSwitch(session, "y_index_base",
          value = (query[["y_index_base"]] == "TRUE")
        )
      }

      selected_filter <- unlist(query[names(query) == "filter"], use.names = FALSE)
      if (!is.null(query[["filter"]])) {
        updateSelectizeInput(session, "filter1",
          choices  = all_municipios,
          selected = selected_filter,
          server   = TRUE
        )
      }
    }

    # Output titulo do gráfico
    output$plot_title <- renderText({
      text <- " "
      if (is.null(input$y) || input$y == "") {
        text <- " "
      } else {
        y_col <- active_table()[which(active_table()$var == input$y), ]
        text <- paste0("", y_col$label)
        if (input$y_index_base) {
          text <- paste0("", y_col$label, "*")
        }
      }
      text
    })
    
    output$plot_subtitle <- renderText({
        if (is.null(input$y) || input$y == "") return(" ")
        
        subtitles <- c(i18n()$label_municipal)
        
        # Botões ativos
        if (isTRUE(input$y_index_base)) {
            subtitles <- c(subtitles, i18n()$label_prop_name)
        }
        if (isTRUE(input$ylog)) {
            subtitles <- c(subtitles, i18n()$label_scale_name)
        }
        
        if (length(subtitles) > 0) {
            return(paste(subtitles, collapse = i18n()$label_and))
        }
        
        i18n()$stitle_init
    })
    
    # Atualiza a URL em observer separado para não criar loop com renderPlotly
    observe({
      update_my_queryString()
    })

    # Output gráfico
    output$plot <- renderPlotly({
      
      fig <- plotly_empty()
      tryCatch(
        {
          if (is.null(input$y) || input$y == "" ||
              is.null(input$filter1) || length(input$filter1) < 1) {
            fig <- plotly_empty()
            stop()
          }

          x_col <- active_table()[which(active_table()$var == param$x_def), ]
          y_col <- active_table()[which(active_table()$var == input$y), ]
          id_col <- active_table()[which(active_table()$var == param$id_def), ]
          color_col <- active_table()[which(active_table()$var == param$color_def), ]

          # Filtra dataframe com municípios selecionados
          df_filtered <- reactive({
              df[which(df$municipio %in% input$filter1), ]
          })

          df_p <- data.frame(
              x       = as.numeric(df_filtered()[[x_col$var]]),
              y       = df_filtered()[[y_col$var]],
              color   = df_filtered()[[color_col$var]],
              municipio = df_filtered()$municipio,
              stringsAsFactors = FALSE
          )
          df_p$text <- df_p$municipio

          # Filtra colunas onde x e y são NA
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y)), ]

          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Alternativa de medida para y
          if (input$y_index_base & is.numeric(df_p$y)) {
            df_p <- df_p %>%
              group_by(df_p$municipio) %>%
              mutate(
                aux1 = first(y),
                y_index_base = (y / aux1) * 100
              )
            df_p$y <- df_p$y_index_base
          }

          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }
          
          # Se o switch log estiver ativado, aplicamos log10 diretamente no R
          if (isTRUE(input$ylog)) {
            df_p <- df_p[which(df_p$y > 0), ]
            df_p$original_y <- df_p$y
            df_p$y <- log10(df_p$y)
            y_axis_title <- paste0(y_col$label, " (Log)")
          } else {
            df_p$original_y <- df_p$y
            y_axis_title <- y_col$label
          }

          # Formatação conforme idioma
          dec_mark <- if (lang() == "pt") "," else "."
          big_mark <- if (lang() == "pt") "." else ","

          # Monta html do tooltip usando os valores originais não transformados
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            x_col$label, ": ", df_p$x, "<br>",
            y_col$label, ": ", format(df_p$original_y, scientific = FALSE,
                                      digits = 2,
                                      decimal.mark = dec_mark, 
                                      big.mark = big_mark), "<br>"
          )

          pallete <- pallete_discrete

          fig_p <- plot_ly(df_p,
            x = ~x,
            y = ~y,
            color = ~municipio,
            type = "scatter",
            mode = "lines",
            text = ~tooltip,
            hoverinfo = "text"
          )

          x_axis_layout <- list(
            title = x_col$label,
            type = "linear",
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )
          
          # Configura eixo Y como linear (uma vez que os dados já foram calculados com log10 no R)
          y_axis_layout <- list(
            title = y_axis_title,
            type = "linear",
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )

          # Se estiver em escala logarítmica, configuramos os ticks manualmente
          # para exibirem os valores originais correspondentes às potências de 10.
          if (isTRUE(input$ylog) && nrow(df_p) > 0) {
            y_range <- range(df_p$y, na.rm = TRUE)
            # Cria ticks a cada inteiro de potência de 10 (ex: 10^0, 10^1, 10^2)
            tick_values <- seq(floor(y_range[1]), ceiling(y_range[2]), by = 1)
            y_axis_layout$tickvals <- tick_values
            y_axis_layout$ticktext <- format(10^tick_values, big.mark = big_mark, scientific = FALSE)
          }

          if (input$y_index_base) {
            y_axis_layout$title <- paste0(y_axis_title, "*")
          }

          tooltip <- list(
            bordercolor = "rgba(255, 255, 255, 1)",
            bgopacity = "0.5",
            font = f1
          )

          fig_p <- fig_p %>%
            layout(
              font = f1,
              xaxis = x_axis_layout,
              yaxis = y_axis_layout,
              showlegend = TRUE,
              hoverlabel = tooltip
            )

          fig_p <- fig_p %>%
            config(
              displaylogo = FALSE,
              modeBarButtonsToRemove = c(
                "lasso2d",
                "select2d",
                "hoverCompareCartesian"
              )
            )

          fig <- fig_p
        },
        error = function(cond) {
          print("plot error")
          fig <- plotly_empty()
        }
      )
      fig
    })

    # Lê a URL uma única vez na inicialização.
    # A flag .url_read (R simples, não reativa) bloqueia re-execuções causadas
    # pelo próprio app ao escrever a queryString via update_my_queryString().
    observeEvent(session$clientData$url_search, {
      if (.url_read) return(invisible(NULL))
      .url_read <<- TRUE
      update_my_inputs()
    }, ignoreInit = FALSE)
  }

  server
}
