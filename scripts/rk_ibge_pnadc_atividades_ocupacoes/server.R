# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete   <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725")

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

get_server <- function(files, param) {

    df <- readRDS(files$db_file) %>%
        dplyr::filter(id != "All")

    server <- function(input, output, session) {

        update_my_queryString <- function() {
            q_string <- paste0("?x=", input$x, "&filter2=", input$filter2)
            for (i in input$filter1) {
                q_string <- paste0(q_string, "&filter=", i)
            }
            for (k in input$filter3) {
                q_string <- paste0(q_string, "&filter3=", k)
            }
            updateQueryString(q_string, mode = "replace")
        }

        update_my_inputs <- function() {
            updateSelectInput(session, "filter2",
                              choices  = param$type_choices,
                              selected = param$type_def)
            updateSelectInput(session, "filter1",
                              choices  = param$filter_choices,
                              selected = c("Amazônia Legal", "Brasil"))
            updateSelectInput(session, "filter3",
                              choices  = param$sector_choices,
                              selected = param$sector_def)

            query <- parseQueryString(session$clientData$url_search)

            if (!is.null(query[["x"]])) {
                updateSelectInput(session, "x",
                                  choices  = param$x_choices,
                                  selected = query[["x"]])
            }

            if (!is.null(query[["filter2"]])) {
                updateSelectInput(session, "filter2",
                                  choices  = param$type_choices,
                                  selected = query[["filter2"]])
            }

            selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
            if (!is.null(query[["filter"]])) {
                updateSelectInput(session, "filter1",
                                  choices  = param$filter_choices,
                                  selected = selected)
            }

            selected3 <- unlist(query[names(query) == "filter3"], use.names = FALSE)
            if (!is.null(query[["filter3"]])) {
                updateSelectInput(session, "filter3",
                                  choices  = param$sector_choices,
                                  selected = selected3)
            }
        }

        output$plot_title <- renderText({
            if (is.null(input$x) || input$x == "") return(param$novar)
            x_col <- param$table[which(param$table$var == input$x), ]
            paste0(param$title_init, " ", x_col$label)
        })

        output$plot_subtitle <- renderText({
            if (is.null(input$x) || input$x == "") return(" ")
            if (is.null(input$filter2) || input$filter2 == "CNAE") param$subtitle_cnae else param$subtitle_cod
        })

        output$plot <- renderPlotly({
            update_my_queryString()

            fig <- plotly_empty()
            tryCatch({
                if (is.null(input$x) || input$x == "") stop()
                req(input$filter1, input$filter2, input$filter3)

                x_col      <- param$table[which(param$table$var == input$x), ]
                color_col  <- param$table[which(param$table$var == param$color_def), ]
                slider_col <- param$table[which(param$table$var == param$slider_def), ]
                text_col   <- param$table[which(param$table$var == param$text_def), ]
                id_col     <- param$table[which(param$table$var == param$id_def), ]

                y_col <- list(var = "rank", label = "Ranking")

                df_filtered <- df %>%
                    dplyr::filter(group %in% input$filter1,
                                  setor %in% input$filter3,
                                  id    == input$filter2)

                df_p <- data.frame(
                    df_filtered[x_col$var],
                    NA,
                    df_filtered[color_col$var],
                    df_filtered[slider_col$var],
                    df_filtered[text_col$var],
                    df_filtered[color_col$var],
                    df_filtered[id_col$var]
                )
                colnames(df_p) <- c("x", "y", "color", "slider", "text", "group", "id")

                df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$color)), ]
                if (nrow(df_p) < 1) stop()

                df_p <- df_p %>%
                    dplyr::group_by(slider) %>%
                    dplyr::mutate(y = order(order(x, decreasing = TRUE))) %>%
                    dplyr::arrange(y, .by_group = TRUE)

                df_p$y[is.na(df_p$y)] <- max(df_p$y) + 1
                df_p$x[is.na(df_p$x)] <- 0

                if (all(is.na(df_p$color))) df_p$color <- " "

                top_n      <- 10
                top_groups <- unique(df_p$color[which(df_p$y <= top_n)])
                df_p       <- df_p %>% dplyr::filter(color %in% top_groups)

                df_p$tooltip <- paste0(
                    "<b>", df_p$text, "</b><br>",
                    "(", df_p$slider, ")", "<br><br>",
                    x_col$label, ": ", format(df_p$x,
                                              scientific   = FALSE,
                                              digits       = 2,
                                              decimal.mark = ",",
                                              big.mark     = "."), "<br>",
                    y_col$label, ": ", df_p$y, "<br>",
                    color_col$label, ": ", df_p$color
                )

                pallete <- if (!is.numeric(df_p$color)) pallete_discrete else pallete_continuous

                min_x <- min(0, min(df_p$x))
                max_x <- max(0, max(df_p$x))

                fig_p <- plot_ly(df_p,
                                 x            = ~x,
                                 y            = ~y,
                                 color        = ~color,
                                 colors       = pallete,
                                 frame        = ~slider,
                                 text         = ~tooltip,
                                 textposition = "middle right",
                                 showlegend   = FALSE,
                                 hoverinfo    = "text")

                fig_p <- fig_p %>% add_segments(
                    x = 0, xend = ~x, y = ~y, yend = ~y,
                    split = ~id, color = ~color,
                    line = list(width = 30), opacity = 0.7)

                fig_p <- fig_p %>% add_text(
                    x = 0.01 * max_x, text = ~text, ids = ~id,
                    hoverinfo = "none", textfont = f1, textposition = "middle right")

                if (length(unique(df_p$slider)) > 1) {
                    fig_p <- fig_p %>% animation_slider(currentvalue = list(prefix = "Ano: ", font = f1))
                    fig_p <- fig_p %>% animation_button(label = "Play")
                    fig_p$x$layout$updatemenus <- list(list(
                        type = "buttons", direction = "right", showactive = FALSE,
                        x = 0, y = 0, xanchor = "top", yanchor = "right",
                        pad = list(t = 60, r = 5),
                        buttons = list(
                            list(method = "animate", label = "▶",
                                 args = list(NA, list(mode = "immediate",
                                                      transition = list(duration = 1500, easing = "linear", redraw = TRUE),
                                                      fromcurrent = TRUE,
                                                      frame = list(redraw = TRUE, duration = 1500)))),
                            list(method = "animate", label = "I I",
                                 args = list(list(), list(mode = "immediate",
                                                          transition = list(duration = 0),
                                                          frame = list(redraw = FALSE, duration = 0))))
                        )
                    ))
                    first_frame <- min(df_p$slider)
                    last_frame  <- max(df_p$slider)
                    fig_p <- fig_p %>% onRender("
                        function(el,x,data){
                          Plotly.animate(el, data, {frame: [{duration: 0}]})
                        }", data = c(first_frame, last_frame))
                }

                fig_p <- fig_p %>%
                    layout(
                        font   = f1,
                        xaxis  = list(title = x_col$label, titlefont = f1, tickfont = f2,
                                      automargin = FALSE, autorange = FALSE,
                                      range = c(min_x, max_x), showgrid = FALSE, zeroline = FALSE),
                        yaxis  = list(title = y_col$label, titlefont = f1, tickfont = f2,
                                      tickformat = "1", automargin = FALSE, autorange = FALSE,
                                      showgrid = FALSE, zeroline = FALSE,
                                      dtick = 1, tick0 = 1, range = c(top_n + 0.5, 0.5), type = "numeric"),
                        showlegend = TRUE,
                        legend     = list(title = list(text = color_col$label)),
                        hoverlabel = list(bordercolor = "rgba(255,255,255,1)", bgopacity = "0.5", font = f1)
                    ) %>%
                    animation_opts(1500, easing = "linear", redraw = FALSE) %>%
                    config(displaylogo = FALSE,
                           modeBarButtonsToRemove = c("lasso2d", "select2d", "hoverCompareCartesian"))

                fig <- fig_p
            }, error = function(e) {
                print(paste("plot error:", e$message))
                fig <<- plotly_empty()
            })
            fig
        }) %>%
            bindCache(input$x, input$filter1, input$filter2, input$filter3)

        output$deflator_notice_ui <- renderUI({
            last_ano <- max(df$Ano)
            last_tri <- max(df$Trimestre[df$Ano == last_ano])
            tags$p(
                style = "color: rgba(255,255,255,0.7); font-size: 12px; margin-top: 10px; margin-bottom: 4px;",
                paste0("Valores em R$ de ", last_ano, "-T", last_tri)
            )
        })

        observe({
            query <- parseQueryString(session$clientData$url_search)
            update_my_inputs()
        })
    }

    server
}
