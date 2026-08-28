# -------------------------------- Define lógica do server --------------------------------

pallete_discrete <- c("#fcff84","#ffcf48" ,"#c3ff83","#007e47","#00596d","#4fdf94","#99b0c8","#261c4e","#000098","#c368b1","#60458c","#757575")
pallete_continuous <- c("#440154","#481567" ,"#453781","#404788","#39568c","#33638d","#287d8e","#238a8d","#1f968b","#20a387","#29af7f","#3cbb75","#55c667","#73d055","#95d840","#b8de29","#dce319","#fde725")

f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

get_server <- function(files, param) {
    server <- function(input, output, session) {
        
        df <- readRDS(files$db_file)
        
        # --- LANG TOGGLE ---
        lang <- reactiveVal("pt")
        
        observeEvent(input$toggle_lang, {
            lang(ifelse(lang() == "pt", "en", "pt"))
        })
        
        i18n <- reactive({ param$i18n[[lang()]] })
        tbl  <- reactive({ param$tables[[lang()]] })
        
        y_choices_lang <- reactive({
            append("", grouped_list(tbl()[which(tbl()$y)]))
        })
        
        param$filter_choices <- sort(unique(df$group))
        param$filter_choices <- param$filter_choices[which(param$filter_choices != " - ")]
        
        random_inputs <- function() {
            updateSelectInput(session,
                              "filter1",
                              choices = param$filter_choices,
                              selected = sample(param$filter_choices, 2)
            )
            
            selected <- sample(sample(y_choices_lang(), 1)[[1]], 1)
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
                                  selected = query[["y"]])
            }
            
            if (!is.null(query[["ylog"]])) {
                updateCheckboxInput(session, "ylog",
                                    value = (query[["ylog"]] == "TRUE"))
            }
            
            if (!is.null(query[["y_option"]])) {
                updateCheckboxInput(session, "y_option",
                                    value = (query[["y_option"]] == "TRUE"))
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
        
        # Descrição da sidebar e "VARIÁVEIS:" reagem ao idioma
        output$plot_desc_ui <- renderUI({ p(class = "plot_desc", i18n()$plot_desc) })
        output$label_var_name <- renderText({ i18n()$label_var_name })
        output$label_scale_name <- renderText({ i18n()$label_scale_name })
        output$label_axis_name  <- renderText({ i18n()$label_axis_name })
        
        output$plot_title <- renderText({
            text <- " "
            if (is.null(input$y) || input$y == "") {
                text <- " "
            } else {
                y_col <- tbl()[which(tbl()$var == input$y), ]
                text <- paste0("", y_col$label)
                if (input$y_option) {
                    text <- paste0("", y_col$label, "*")
                }
            }
            text
        })
        
        output$plot_subtitle <- renderText({
            if (is.null(input$y) || input$y == "") {
                text <- " "
            } else {
                text <- paste0(i18n()$geo_level)
            }
            text
        })
        
        output$plot <- renderPlotly({
            lang() # força re-render quando o idioma muda
            update_my_queryString()
            
            fig <- plotly_empty()
            tryCatch({
                if (is.null(input$y) || input$y == "" ||
                    is.null(input$filter1) || length(input$filter1) < 1) {
                    fig <- plotly_empty()
                    stop()
                }
                
                x_col <- tbl()[which(tbl()$var == param$x_def), ]
                y_col <- tbl()[which(tbl()$var == input$y), ]
                id_col <- tbl()[which(tbl()$var == param$id_def), ]
                color_col <- tbl()[which(tbl()$var == param$color_def), ]
                
                df_filtered <- df[which(df$group %in% input$filter1), ]
                
                df_p <- data.frame(df_filtered[x_col$var],
                                   df_filtered[y_col$var],
                                   df_filtered[color_col$var]
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
                        mutate(aux1 = first(y),
                               y_option = (y / aux1) * 100)
                    df_p$y <- df_p$y_option
                }
                
                if (all(is.na(df_p$color))) {
                    df_p$color <- " "
                }
                
                df_p$tooltip <- paste0(
                    "<b>", df_p$text, "</b><br>",
                    x_col$label, ": ", df_p$x, "<br>",
                    y_col$label, ": ", df_p$y, "<br>"
                )
                
                pallete <- pallete_discrete
                
                fig_p <- plot_ly(df_p,
                                 x = ~x,
                                 y = ~y,
                                 color = ~group,
                                 type = "scatter",
                                 mode = "lines",
                                 text = ~tooltip
                )
                
                x_axis_layout <- list(
                    title = x_col$label,
                    titlefont = f1,
                    tickfont = f2,
                    automargin = FALSE,
                    autorange = TRUE,
                    showgrid = FALSE,
                    zeroline = FALSE
                )
                y_axis_layout <- list(
                    title = paste0(y_col$label, " (", y_col$unidade, ")"),
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
                    y_axis_layout$title <- paste0(y_col$label, "*")
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
                            "toImage",
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
            })
            fig
        })
        
        # Atualiza labels/choices quando o idioma muda
        observeEvent(lang(), {
            updateSelectInput(session, "y",
                              label = i18n()$label_y_name, choices = y_choices_lang(), selected = isolate(input$y))
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