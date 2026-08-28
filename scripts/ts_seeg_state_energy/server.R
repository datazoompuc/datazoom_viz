# -------------------------------- Define lógica do server --------------------------------

pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725")

f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

get_server <- function(files, param) {
    server <- function(input, output, session) {
        
        # Dado SEMPRE em português internamente — a tradução acontece só na exibição
        df <- readRDS(files$db_file) %>%
            filter(processos_geradores_emissoes != "Nao Identificado") %>%
            filter(processos_geradores_emissoes != "Producao de Combustiveis") %>%
            filter(!is.na(processos_geradores_emissoes))
        
        # --- LANG TOGGLE ---
        lang <- reactiveVal("pt")
        
        observeEvent(input$toggle_lang, {
            lang(ifelse(lang() == "pt", "en", "pt"))
        })
        
        i18n <- reactive({ param$i18n[[lang()]] })
        tbl  <- reactive({ param$tables[[lang()]] })
        
        # Categorias sempre calculadas a partir do PT (fonte da verdade),
        # traduzidas só para exibição
        categorias_pt <- sort(unique(df$processos_geradores_emissoes))
        
        y_choices_lang <- reactive({
            if (lang() == "en") {
                traduzidas <- unname(param$categoria_traducao[categorias_pt])
                setNames(categorias_pt, traduzidas) # value = PT (chave interna), label = EN (exibido)
            } else {
                setNames(categorias_pt, categorias_pt)
            }
        })
        
        param$filter_choices <- sort(unique(df$group))
        param$filter_choices <- param$filter_choices[which(param$filter_choices != " - ")]
        
        random_inputs <- function() {
            updateSelectInput(session,
                              "filter1",
                              choices = param$filter_choices,
                              selected = sample(param$filter_choices, 2)
            )
            
            selected <- sample(categorias_pt, 1)
            updateSelectInput(session,
                              "y",
                              choices = y_choices_lang(),
                              selected = selected
            )
        }
        
        update_my_queryString <- function() {
            q_string <- paste0(
                "?", "y=", input$y,
                "&", "ylog=", input$ylog,
                "&", "y_option=", input$y_option
            )
            
            for (i in input$filter1) {
                q_string <- paste0(
                    q_string,
                    "&", "filter=", i
                )
            }
            
            updateQueryString(q_string, mode = "replace")
        }
        
        update_my_inputs <- function() {
            updateSelectInput(session,
                              "filter1",
                              choices = param$filter_choices,
                              selected = NULL
            )
            
            query <- parseQueryString(session$clientData$url_search)
            
            if (!is.null(query[["y"]])) {
                updateSelectInput(session, "y",
                                  choices = y_choices_lang(),
                                  selected = query[["y"]]
                )
            }
            
            if (!is.null(query[["ylog"]])) {
                updateCheckboxInput(session, "ylog",
                                    value = (query[["ylog"]] == "TRUE")
                )
            }
            
            if (!is.null(query[["y_option"]])) {
                updateCheckboxInput(session, "y_option",
                                    value = (query[["y_option"]] == "TRUE")
                )
            }
            
            selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
            if (!is.null(query[["filter"]])) {
                updateSelectInput(session,
                                  "filter1",
                                  choices = param$filter_choices,
                                  selected = selected
                )
            }
            
            if (is.null(query[["filter"]]) && is.null(query[["y"]])) {
                random_inputs()
            }
        }
        
        output$plot_desc_ui   <- renderUI({ p(class = "plot_desc", i18n()$plot_desc) })
        output$label_var_name <- renderText({ i18n()$label_var_name })
        output$label_log_name <- renderText({ i18n()$label_log_name })
        output$label_prop_name <- renderText({ i18n()$label_prop_name })
        output$label_geo_name  <- renderText({ i18n()$label_geo_name })
        
        output$plot_title <- renderText({
            text <- " "
            if (is.null(input$y) || input$y == "") {
                text <- " "
            } else {
                # input$y é sempre a chave PT; exibe o rótulo no idioma atual
                y_label <- if (lang() == "en") unname(param$categoria_traducao[input$y]) else input$y
                text <- paste0(i18n()$title_init, y_label)
                if (input$y_option) {
                    text <- paste0(text, "*")
                }
            }
            text
        })
        
        output$plot_subtitle <- renderText({
            if (is.null(input$y) || input$y == "") {
                text <- " "
            } else {
                text <- paste0(i18n()$subtitle_init)
            }
            text
        })
        
        output$plot <- renderPlotly({
            lang() # força re-render quando o idioma muda
            update_my_queryString()
            
            fig <- plotly_empty()
            tryCatch(
                {
                    if (is.null(input$y) || input$y == "" ||
                        is.null(input$filter1) || length(input$filter1) < 1) {
                        fig <- plotly_empty()
                        stop()
                    }
                    
                    x_col <- tbl()[which(tbl()$var == param$x_def), ]
                    
                    df_filtered <- df[which(df$group %in% input$filter1), ]
                    
                    df_filtered <- df_filtered %>%
                        filter(processos_geradores_emissoes == input$y) %>%
                        group_by(time, group = gas) %>%
                        summarise(valor = sum(Valor, na.rm = TRUE))
                    
                    df_p <- data.frame(
                        df_filtered[x_col$var],
                        df_filtered["valor"],
                        df_filtered["group"]
                    )
                    colnames(df_p) <- c("x", "y", "color")
                    df_p$group <- df_filtered$group
                    df_p$text <- df_p$group
                    
                    df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y)), ]
                    
                    if (nrow(df_p) < 1) {
                        fig <- plotly_empty()
                        stop()
                    }
                    
                    if (input$y_option & is.numeric(df_p$y)) {
                        df_p <- df_p %>%
                            group_by(df_p$group) %>%
                            mutate(
                                aux1 = first(y),
                                y_option = (y / aux1) * 100
                            )
                        df_p$y <- df_p$y_option
                    }
                    
                    if (all(is.na(df_p$color))) {
                        df_p$color <- " "
                    }
                    
                    df_p$tooltip <- paste0(
                        "<b>", df_p$text, "</b><br>",
                        x_col$label, ": ", df_p$x, "<br>",
                        i18n()$tooltip_a, ": ", format(df_p$y, scientific = FALSE,
                                                       digits = 2,
                                                       decimal.mark = ",",
                                                       big.mark = "."), " ", i18n()$tooltip_c
                    )
                    
                    pallete <- pallete_discrete
                    
                    fig_p <- plot_ly(df_p,
                                     x = ~x,
                                     y = ~y,
                                     color = ~group,
                                     type = "scatter",
                                     mode = "lines",
                                     text = ~tooltip,
                                     hoverinfo = "text"
                    )
                    
                    x_axis_layout <- list(
                        title = x_col$label,
                        titlefont = f1,
                        tickfont = f2,
                        automargin = TRUE,
                        autorange = TRUE,
                        showgrid = FALSE,
                        zeroline = FALSE
                    )
                    y_axis_layout <- list(
                        title = i18n()$plot_y,
                        titlefont = f1,
                        tickfont = f2,
                        automargin = FALSE,
                        autorange = TRUE,
                        showgrid = FALSE,
                        zeroline = FALSE
                    )
                    
                    if (input$ylog & is.numeric(df_p$y)) {
                        y_axis_layout$type <- "log"
                    }
                    
                    if (input$y_option) {
                        y_axis_layout$title <- paste0(i18n()$plot_y, "*")
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
        
        observeEvent(lang(), {
            updateSelectInput(session, "y",
                              choices = y_choices_lang(), selected = isolate(input$y))
            updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
            updateActionButton(session, "ab1", label = i18n()$btn_fullscreen)
        }, ignoreInit = FALSE)
        
        observe({
            query <- parseQueryString(session$clientData$url_search)
            update_my_inputs()
        })
    }
    
    server
}