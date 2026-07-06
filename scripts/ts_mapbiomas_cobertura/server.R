# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# helper: valor lógico com default FALSE
iv <- function(x) if (is.null(x)) FALSE else isTRUE(x)

# Funcão para retornar objeto server
get_server <- function(files, param) {

  # Carrega as duas bases (o toggle geográfico decide qual está ativa)
  df_est   <- readRDS(files$db_file_est)   %>% dplyr::ungroup()
  df_munic <- readRDS(files$db_file_munic) %>% dplyr::ungroup()

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

    # ---------------------------- Nível geográfico ----------------------------
    geo <- reactive({ if (isTRUE(input$geo_munic)) "munic" else "est" })
    df  <- reactive({ if (geo() == "munic") df_munic else df_est })

    # Switches renderizados aqui para que os labels acompanhem o idioma
    output$switches <- renderUI({
      i <- param$i18n[[lang()]]
      gm_default <- {
        q <- parseQueryString(isolate(session$clientData$url_search))
        identical(q[["geo"]], "munic")
      }
      tagList(
        materialSwitch(
          "geo_munic", tags$span(i$label_geo_toggle, class = "switch-label"),
          value = if (is.null(isolate(input$geo_munic))) gm_default else isTRUE(isolate(input$geo_munic)),
          status = "info"
        ),
        materialSwitch(
          "y_index_base", tags$span(i$label_prop_name, class = "switch-label"),
          value = iv(isolate(input$y_index_base)), status = "info"
        ),
        materialSwitch(
          "yprop", tags$span(i$label_prop_muni, class = "switch-label"),
          value = iv(isolate(input$yprop)), status = "info"
        )
      )
    })

    # Switches mutuamente exclusivos
    observeEvent(input$y_index_base, {
      if (isTRUE(input$y_index_base)) {
        updateMaterialSwitch(session, "yprop", value = FALSE)
      }
    }, ignoreInit = TRUE)
    observeEvent(input$yprop, {
      if (isTRUE(input$yprop)) {
        updateMaterialSwitch(session, "y_index_base", value = FALSE)
      }
    }, ignoreInit = TRUE)

    # ---------------------------- Escolhas reativas ----------------------------
    filter_choices <- reactive({
      fc <- sort(unique(df()$group))
      fc[fc != " - " & !is.na(fc)]
    })
    y_choices_lang <- reactive({
      table_lang <- param$tables[[lang()]]
      grouped_list(table_lang[which(table_lang$y), ])
    })

    # Textos da sidebar
    output$plot_desc      <- renderText({ i18n()$plot_desc })
    output$label_var_name <- renderText({ i18n()$label_var_name })

    # ---------------------------- Preenchimento inicial / aleatório ----------------------------
    random_inputs <- function() {
      fc <- filter_choices()
      updateSelectizeInput(session, "filter1",
                           label = i18n()$label_geo_name[[geo()]],
                           choices = fc,
                           selected = sample(fc, min(2, length(fc))))
      yc <- y_choices_lang()
      updateSelectInput(session, "y",
                        label = i18n()$label_y_name,
                        choices = yc,
                        selected = sample(sample(yc, 1)[[1]], 1))
    }

    # ---------------------------- URL <-> inputs ----------------------------
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "lang=", lang(),
        "&", "geo=", geo(),
        "&", "y=", input$y,
        "&", "y_index_base=", iv(input$y_index_base)
      )
      for (i in input$filter1) {
        q_string <- paste0(q_string, "&", "filter=", i)
      }
      updateQueryString(q_string, mode = "replace")
    }

    update_my_inputs <- function() {
      query <- parseQueryString(session$clientData$url_search)
      fc    <- filter_choices()

      if (!is.null(query[["y"]])) {
        updateSelectInput(session, "y",
                          label = i18n()$label_y_name,
                          choices = y_choices_lang(),
                          selected = query[["y"]])
      }
      if (!is.null(query[["y_index_base"]])) {
        updateMaterialSwitch(session, "y_index_base",
                             value = (query[["y_index_base"]] == "TRUE"))
      }
      selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
      if (!is.null(selected) && all(selected %in% fc)) {
        updateSelectizeInput(session, "filter1",
                             label = i18n()$label_geo_name[[geo()]],
                             choices = fc, selected = selected)
      }
      # Se query está vazia, preenche aleatório
      if (is.null(query[["filter"]]) && is.null(query[["y"]])) {
        random_inputs()
      }
    }

    # Retraduz y e labels ao trocar idioma (mantém a seleção atual)
    observeEvent(lang(), {
      updateSelectInput(session, "y",
                        label = i18n()$label_y_name,
                        choices = y_choices_lang(),
                        selected = isolate(input$y))
      updateSelectizeInput(session, "filter1",
                           label = i18n()$label_geo_name[[geo()]],
                           selected = isolate(input$filter1))
    }, ignoreInit = TRUE)

    # Ao trocar de nível geográfico, troca as opções de recorte (a seleção antiga
    # não é válida no outro nível) e sorteia 2 novos
    observeEvent(geo(), {
      fc <- filter_choices()
      updateSelectizeInput(session, "filter1",
                           label = i18n()$label_geo_name[[geo()]],
                           choices = fc,
                           selected = sample(fc, min(2, length(fc))))
    }, ignoreInit = TRUE)

    # ---------------------------- Títulos ----------------------------
    output$plot_title <- renderText({
      if (is.null(input$y) || input$y == "") return(" ")
      table_lang <- param$tables[[lang()]]
      y_col <- table_lang[which(table_lang$var == input$y), ]
      y_col$label
    })

    output$plot_subtitle <- renderText({
      if (is.null(input$y) || input$y == "") return(" ")
      if (isTRUE(input$y_index_base)) return(i18n()$label_prop_name)
      if (isTRUE(input$yprop))        return(i18n()$label_prop_muni)
      i18n()$subtitle_init
    })

    # ---------------------------- Gráfico ----------------------------
    output$plot <- renderPlotly({
      update_my_queryString()

      fig <- plotly_empty()
      tryCatch({
        if (is.null(input$y) || input$y == "" ||
            is.null(input$filter1) || length(input$filter1) < 1) {
          fig <- plotly_empty()
          stop()
        }

        table_lang <- param$tables[[lang()]]
        x_col     <- table_lang[which(table_lang$var == param$x_def), ]
        y_col     <- table_lang[which(table_lang$var == input$y), ]
        color_col <- table_lang[which(table_lang$var == param$color_def), ]

        d <- df()
        df_filtered <- d[which(d$group %in% input$filter1), ]

        df_p <- data.frame(
          df_filtered[x_col$var],
          df_filtered[y_col$var],
          df_filtered[color_col$var]
        )
        colnames(df_p) <- c("x", "y", "color")
        df_p$group <- df_filtered$group
        df_p$text  <- df_p$group

        df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y)), ]
        if (nrow(df_p) < 1) {
          fig <- plotly_empty()
          stop()
        }

        # ---- Botões de transformação ----
        if (is.numeric(df_p$y)) {
          df_p$y_raw <- df_p$y

          # Normalização por área
          if (isTRUE(input$yprop)) {
            df_area <- d %>%
              dplyr::select(group, area_km2) %>%
              dplyr::distinct()
            df_p <- df_p %>%
              dplyr::left_join(df_area, by = "group") %>%
              dplyr::mutate(y = y_raw / area_km2)
          } else {
            df_p$y <- df_p$y_raw
          }

          # Índice base 100 (ano inicial)
          if (isTRUE(input$y_index_base)) {
            df_p <- df_p %>%
              dplyr::group_by(group) %>%
              dplyr::mutate(y = (y / dplyr::first(y)) * 100) %>%
              dplyr::ungroup()
          }
        }

        if (all(is.na(df_p$color))) df_p$color <- " "

        unidade_y <- if (isTRUE(input$yprop) || isTRUE(input$y_index_base)) "%" else "ha"

        df_p$tooltip <- paste0(
          "<b>", df_p$text, "</b><br>",
          i18n()$x_label, ": ", df_p$x, "<br>",
          y_col$label, ": ", format(df_p$y, scientific = FALSE,
                                    digits = 2, decimal.mark = ",",
                                    big.mark = "."), " ", "(", unidade_y, ")"
        )

        df_p <- df_p %>% dplyr::arrange(group, x)

        fig_p <- plot_ly(df_p,
          x = ~x, y = ~y, color = ~group,
          type = "scatter", mode = "lines",
          text = ~tooltip, textposition = "none", hoverinfo = "text"
        )

        x_axis_layout <- list(
          title = i18n()$x_label, titlefont = f1, tickfont = f2,
          automargin = TRUE, autorange = TRUE, showgrid = FALSE, zeroline = FALSE
        )
        y_axis_title <- y_col$label
        if (isTRUE(input$y_index_base)) y_axis_title <- paste0(y_col$label, "*")
        y_axis_layout <- list(
          title = y_axis_title, titlefont = f1, tickfont = f2,
          automargin = FALSE, autorange = TRUE, showgrid = FALSE, zeroline = FALSE
        )

        tooltip <- list(
          bordercolor = "rgba(255, 255, 255, 1)", bgopacity = "0.5", font = f1
        )

        fig_p <- fig_p %>%
          layout(
            font = f1, xaxis = x_axis_layout, yaxis = y_axis_layout,
            showlegend = TRUE, hoverlabel = tooltip
          ) %>%
          config(
            displaylogo = FALSE,
            modeBarButtonsToRemove = c("lasso2d", "select2d", "hoverCompareCartesian")
          )

        fig <- fig_p
      },
      error = function(cond) {
        print("plot error")
        fig <- plotly_empty()
      })
      fig
    })

    # ---------------------------- Startup ----------------------------
    observe({
      update_my_inputs()
    })
  }

  # Retorna objeto server
  server
}
