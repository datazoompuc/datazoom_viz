# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# Funcão para retornar objeto server
get_server <- function(files, param) {
    
    # Carrega dados
    df <- readRDS(files$db_file)
    time_vector <- tail(unique(df$time), 6) # Seleciona os últimos 6 anos
    df <- df |>
        filter(time %in% time_vector)
    
    server <- function(input, output, session) {
        
        # --- LANG TOGGLE ---
        lang <- reactiveVal("pt")
        
        observeEvent(input$toggle_lang, {
            lang(ifelse(lang() == "pt", "en", "pt"))
        })
        
        i18n <- reactive({ param$i18n[[lang()]] })
        tbl  <- reactive({ param$tables[[lang()]] })
        
        # Choices agrupadas (mesma lógica de grouped_list() do db_params.R), recalculadas por idioma
        x_choices_lang     <- reactive({ append("", grouped_list(tbl()[which(tbl()$x)])) })
        color_choices_lang <- reactive({ append("", grouped_list(tbl()[which(tbl()$color)])) })
        
        # Cria opções para seleção de grupos
        param$filter_choices <- sort(unique(df$group))
        param$filter_choices <- param$filter_choices[which(param$filter_choices != " - ")]
        
        # Funcão para preencher inputs com coluna/variável aleatória
        random_inputs <- function() {
            if (input$x == "") {
                updateSelectInput(session, "x",
                                  choices = x_choices_lang(),
                                  selected = sample(param$x_cols$var, 1)
                )
            }
            
            if (input$color == "") {
                updateSelectInput(session, "color",
                                  choices = color_choices_lang(),
                                  selected = sample(param$color_cols$var, 1)
                )
            }
        }
        
        # Função para atualizar url do app com parâmetros dos inputs
        update_my_queryString <- function() {
            q_string <- paste0(
                "?", "x=", input$x,
                "&", "color=", input$color
            )
            updateQueryString(q_string, mode = "replace")
        }
        
        # Função para atualizar inputs a partir da URL
        update_my_inputs <- function() {
            query <- parseQueryString(session$clientData$url_search)
            
            if (!is.null(query[["x"]])) {
                updateSelectInput(session, "x",
                                  choices = x_choices_lang(),
                                  selected = query[["x"]]
                )
            }
            
            if (!is.null(query[["color"]])) {
                updateSelectInput(session, "color",
                                  choices = color_choices_lang(),
                                  selected = query[["color"]]
                )
            }
        }
        
        # NOVO: descrição da sidebar e "VARIÁVEIS:" reagem ao idioma
        output$plot_desc_ui <- renderUI({ p(class = "plot_desc", i18n()$plot_desc) })
        output$label_ui1    <- renderText({ i18n()$ui1 })
        
        # Output título do gráfico
        output$plot_title <- renderText({
            text <- " "
            if (is.null(input$x) || input$x == "" ||
                is.null(input$color) || input$color == "") {
                text <- i18n()$server0
            } else {
                x_col <- tbl()[which(tbl()$var == input$x), ]
                text <- paste0(i18n()$server1, x_col$label)
            }
            text
        })
        
        output$plot_subtitle <- renderText({
            text <- " "
            if (is.null(input$color) || input$color == "") {
                text <- " "
            } else {
                text <- paste0(i18n()$server2)
            }
            text
        })
        
        # Output gráfico
        output$plot <- renderPlotly({
            
            lang() # força re-render quando o idioma muda
            update_my_queryString()
            
            fig <- plotly_empty()
            
            tryCatch(
                {
                    if (is.null(input$x) || input$x == "" ||
                        is.null(input$color) || input$color == "") {
                        fig <- plotly_empty()
                        stop()
                    }
                    
                    x_col <- tbl()[which(tbl()$var == input$x), ]
                    color_col <- tbl()[which(tbl()$var == input$color), ]
                    slider_col <- tbl()[which(tbl()$var == param$slider_def), ]
                    text_col <- tbl()[which(tbl()$var == param$text_def), ]
                    id_col <- tbl()[which(tbl()$var == param$id_def), ]
                    
                    y_col <- list()
                    y_col$var <- "rank"
                    y_col$label <- "Ranking"
                    
                    df_p <- data.frame(
                        df[x_col$var],
                        NA,
                        df[color_col$var],
                        df[slider_col$var],
                        df["group"],
                        df["group"],
                        df[id_col$var]
                    )
                    
                    colnames(df_p) <- c("x", "y", "color", "slider", "text", "group", "id")
                    
                    df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$color)), ]
                    
                    if (nrow(df_p) < 1) {
                        fig <- plotly_empty()
                        stop()
                    }
                    
                    df_p <- df_p[which(df_p$group != " - "), ]
                    
                    df_p <- df_p %>%
                        group_by(slider) %>%
                        mutate(y = order(order(x, decreasing = TRUE))) %>%
                        arrange(y, .by_group = TRUE)
                    
                    df_p$y[is.na(df_p$y)] <- max(df_p$y) + 1
                    df_p$x[is.na(df_p$x)] <- 0
                    
                    if (all(is.na(df_p$color))) {
                        df_p$color <- " "
                    }
                    
                    top_n <- 10
                    top_groups <- unique(df_p$group[which(df_p$y <= top_n)])
                    df_p <- df_p %>% filter(group %in% top_groups)
                    
                    df_p$tooltip <- paste0(
                        "<b>", df_p$text, "</b><br>",
                        "(", df_p$slider, ")", "<br><br>",
                        x_col$label, ": ", format(df_p$x, scientific = FALSE,
                                                  digits = 2,
                                                  decimal.mark = ",",
                                                  big.mark = ".")," ", x_col$unidade, "<br>",
                        y_col$label, ": ", df_p$y, "<br>",
                        color_col$label, ": ", df_p$color
                    )
                    
                    pallete <- pallete_continuous
                    if (!is.numeric(df_p$color)) {
                        pallete <- pallete_discrete
                    }
                    
                    min_x <- min(0, min(df_p$x))
                    max_x <- max(0, max(df_p$x))
                    
                    fig_p <- plot_ly(df_p,
                                     x = ~x,
                                     y = ~y,
                                     color = ~color,
                                     colors = pallete,
                                     frame = ~slider,
                                     text = ~tooltip,
                                     textposition = "middle right",
                                     showlegend = FALSE,
                                     hoverinfo = "text"
                    )
                    
                    fig_p <- fig_p %>% add_segments(
                        x = 0,
                        xend = ~x,
                        y = ~y,
                        yend = ~y,
                        split = ~id,
                        color = ~color,
                        line = list(width = 30),
                        opacity = 0.7
                    )
                    
                    fig_p <- fig_p %>% add_text(
                        x = 0.01 * max_x,
                        text = ~text,
                        ids = ~id,
                        hoverinfo = "none",
                        textfont = f1,
                        textposition = "middle right"
                    )
                    
                    if (length(unique(df_p$slider)) > 1) {
                        fig_p <- fig_p %>% animation_slider(currentvalue = list(prefix = "Ano: ", font = f1))
                        
                        fig_p <- fig_p %>% animation_button(label = "Play")
                        
                        fig_p$x$layout$updatemenus <- list(
                            list(
                                type = "buttons",
                                direction = "right",
                                showactive = FALSE,
                                x = 0,
                                y = 0,
                                xanchor = "top",
                                yanchor = "right",
                                pad = list(t = 60, r = 5),
                                buttons = list(
                                    list(
                                        method = "animate",
                                        label = "\u25B6",
                                        args = list(
                                            NA,
                                            list(
                                                mode = "immediate",
                                                transition = list(duration = 1500, easing = "linear", redraw = TRUE),
                                                fromcurrent = TRUE,
                                                frame = list(redraw = TRUE, duration = 1500)
                                            )
                                        )
                                    ),
                                    list(
                                        method = "animate",
                                        label = "I I",
                                        args = list(
                                            list(),
                                            list(
                                                mode = "immediate",
                                                transition = list(duration = 0),
                                                frame = list(redraw = FALSE, duration = 0)
                                            )
                                        )
                                    )
                                )
                            )
                        )
                        
                        first_frame <- min(df_p$slider)
                        last_frame <- max(df_p$slider)
                        fig_p <- fig_p %>% onRender("
            function(el,x,data){
              Plotly.animate(el, data, {frame: [{duration: 0}]})
            }",
                                                    data = c(first_frame, last_frame)
                        )
                    }
                    
                    # Unidade explícita no eixo X (reaproveita x_col$unidade, já usado no tooltip)
                    x_axis_layout <- list(
                        title = paste0(x_col$label, " (", x_col$unidade, ")"),
                        titlefont = f1,
                        tickfont = f2,
                        automargin = FALSE,
                        autorange = FALSE,
                        range = c(min_x, max_x),
                        showgrid = FALSE,
                        zeroline = FALSE
                    )
                    y_axis_layout <- list(
                        title = y_col$label,
                        titlefont = f1,
                        tickfont = f2,
                        automargin = FALSE,
                        autorange = FALSE,
                        showgrid = FALSE,
                        zeroline = FALSE,
                        dtick = 1,
                        tick0 = 1,
                        range = c(top_n + 0.5, 0.5),
                        type = "numeric"
                    )
                    
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
                            legend = list(title = list(text = color_col$label)),
                            hoverlabel = tooltip
                        )
                    
                    fig <- fig %>% animation_opts(
                        1500,
                        easing = "linear", redraw = FALSE
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
        
        # Atualiza labels/choices dos inputs e dos botões quando o idioma muda
        observeEvent(lang(), {
            updateSelectInput(session, "x",
                              label = i18n()$ui2, choices = x_choices_lang(), selected = isolate(input$x))
            updateSelectInput(session, "color",
                              label = i18n()$ui3, choices = color_choices_lang(), selected = isolate(input$color))
            updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
            updateActionButton(session, "ab1", label = i18n()$btn_fullscreen)
        }, ignoreInit = FALSE)
        
        # Observa eventos
        observe({
            query <- parseQueryString(session$clientData$url_search)
            update_my_inputs()
        })
    }
    
    server
}