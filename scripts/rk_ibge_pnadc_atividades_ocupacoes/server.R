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

    categories_df <- read.csv(
        files$categories_file, sep = ";",
        stringsAsFactors = FALSE, fileEncoding = "UTF-8"
    )

    translate_values <- function(filter_id, values, lang_val = "pt") {
        cats      <- categories_df[categories_df$filter_id == filter_id & nzchar(categories_df$value), ]
        label_col <- if (lang_val == "pt") cats$label_pt else cats$label_en
        lookup    <- setNames(label_col, cats$value)
        translated <- lookup[values]
        ifelse(is.na(translated), values, translated)
    }

    read_pnadc_choices <- function(filter_id, lang_val = "pt") {
        cats <- categories_df[categories_df$filter_id == filter_id & nzchar(categories_df$value), ]
        cats <- cats[order(cats$ord_group, cats$ord_item), ]
        out  <- list()
        for (g_pt in unique(cats$group_pt)) {
            items   <- cats[cats$group_pt == g_pt, ]
            if (g_pt == "UF") items <- items[order(items$value), ]
            g_label        <- if (lang_val == "pt") items$group_pt[1] else items$group_en[1]
            labels         <- if (g_pt == "UF") items$value else if (lang_val == "pt") items$label_pt else items$label_en
            out[[g_label]] <- as.list(setNames(items$value, labels))
        }
        out
    }

    server <- function(input, output, session) {

        # Reativo de língua
        lang <- reactiveVal({
            query <- parseQueryString(isolate(session$clientData$url_search))
            if (identical(query[["lang"]], "en")) "en" else "pt"
        })

        observeEvent(input$toggle_lang, {
            lang(ifelse(lang() == "pt", "en", "pt"))
        })

        txt       <- reactive({ param$i18n[[lang()]] })
        param_tbl <- reactive({ param$tables[[lang()]] })

        # Textos dinâmicos do menu
        output$plot_name_ui <- renderUI({ h2(class = "plot_name", txt()$plot_name) })
        output$plot_desc_ui <- renderUI({ p(class  = "plot_desc", txt()$plot_desc) })
        output$label_var_ui <- renderUI({ p(class  = "vars",      txt()$label_var_name) })

        output$deflator_notice_ui <- renderUI({
            last_ano <- max(df$Ano)
            last_tri <- max(df$Trimestre[df$Ano == last_ano])
            notice <- if (lang() == "pt")
                paste0("Valores em R$ de ", last_ano, "-T", last_tri)
            else
                paste0("Values in ", last_ano, "-Q", last_tri, " BRL")
            tags$p(
                style = "color: rgba(255,255,255,0.7); font-size: 12px; margin-top: 10px; margin-bottom: 4px;",
                notice
            )
        })

        # Atualiza inputs quando a língua muda
        observeEvent(lang(), {
            t   <- txt()
            tbl <- param_tbl()

            updateSelectInput(session, "x",
                              label    = t$label_x_name,
                              choices  = setNames(tbl$var[tbl$x], tbl$label[tbl$x]),
                              selected = isolate(if (!is.null(input$x)) input$x else param$x_def))

            sel1 <- isolate(input$filter1)
            sel3 <- isolate(input$filter3)
            sel2 <- isolate(input$filter2)
            if (is.null(sel1) || !nzchar(sel1)) sel1 <- param$group_def
            if (is.null(sel3) || !nzchar(sel3)) sel3 <- param$sector_def

            type_choices <- setNames(list("CNAE", "COD"), c(t$type_cnae, t$type_cod))
            updateSelectInput(session, "filter2",
                              label    = t$label_type_name,
                              choices  = type_choices,
                              selected = if (!is.null(sel2)) sel2 else param$type_def)

            updateSelectizeInput(session, "filter1",
                                 label    = t$label_region_name,
                                 choices  = read_pnadc_choices("region", lang()),
                                 selected = sel1)

            updateSelectizeInput(session, "filter3",
                                 label    = t$label_sector_name,
                                 choices  = read_pnadc_choices("sector", lang()),
                                 selected = sel3)

            updateActionButton(session, "toggle_lang", label = t$btn_lang)
        })

        # Inicializa inputs a partir da URL na primeira carga
        observe({
            query    <- parseQueryString(session$clientData$url_search)
            lang_val <- isolate(lang())
            t        <- param$i18n[[lang_val]]
            tbl      <- param$tables[[lang_val]]

            x_sel <- if (!is.null(query[["x"]])) query[["x"]] else param$x_def
            sel2  <- if (!is.null(query[["filter2"]])) query[["filter2"]] else param$type_def
            sel1  <- if (!is.null(query[["filter"]])) unlist(query[names(query) == "filter"]) else param$group_def
            sel3  <- if (!is.null(query[["filter3"]])) unlist(query[names(query) == "filter3"]) else param$sector_def

            updateSelectInput(session, "x",
                              choices  = setNames(tbl$var[tbl$x], tbl$label[tbl$x]),
                              selected = x_sel)

            type_choices <- setNames(list("CNAE", "COD"), c(t$type_cnae, t$type_cod))
            updateSelectInput(session, "filter2",
                              label    = t$label_type_name,
                              choices  = type_choices,
                              selected = sel2)

            updateSelectizeInput(session, "filter1",
                                 label    = t$label_region_name,
                                 choices  = read_pnadc_choices("region", lang_val),
                                 selected = sel1)

            updateSelectizeInput(session, "filter3",
                                 label    = t$label_sector_name,
                                 choices  = read_pnadc_choices("sector", lang_val),
                                 selected = sel3)
        })

        # Atualiza URL (preserva lang=en quando activo)
        update_my_queryString <- function() {
            q_string <- paste0("?x=", input$x, "&filter2=", input$filter2,
                               "&filter=", input$filter1,
                               "&filter3=", input$filter3)
            if (lang() == "en") q_string <- paste0(q_string, "&lang=en")
            updateQueryString(q_string, mode = "replace")
        }

        output$plot_title <- renderText({
            if (is.null(input$x) || input$x == "") return(" ")
            tbl   <- param_tbl()
            x_col <- tbl[which(tbl$var == input$x), ]
            paste0(txt()$title_init, " ", x_col$label)
        })

        output$plot_subtitle <- renderText({
            if (is.null(input$x) || input$x == "") return(" ")
            t <- txt()
            if (is.null(input$filter2) || input$filter2 == "CNAE") t$subtitle_cnae else t$subtitle_cod
        })

        output$plot <- renderPlotly({
            update_my_queryString()

            fig <- plotly_empty()
            tryCatch({
                if (is.null(input$x) || input$x == "") stop()
                req(input$filter1, input$filter2, input$filter3)

                t   <- txt()
                tbl <- param_tbl()

                x_col      <- tbl[which(tbl$var == input$x), ]
                color_col  <- tbl[which(tbl$var == param$color_def), ]
                slider_col <- tbl[which(tbl$var == param$slider_def), ]
                text_col   <- tbl[which(tbl$var == param$text_def), ]
                id_col     <- tbl[which(tbl$var == param$id_def), ]

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

                # Traduz labels das barras via pnadc_categories.csv
                fid <- tolower(input$filter2)  # "cnae" ou "cod"
                df_p$text  <- translate_values(fid, df_p$text,  lang())
                df_p$color <- translate_values(fid, df_p$color, lang())

                # Formata slider como "2025-T1" / "2025-Q1"
                q_sep <- if (lang() == "pt") "-T" else "-Q"
                df_p$slider <- paste0(lubridate::year(df_p$slider), q_sep,
                                      lubridate::quarter(df_p$slider))

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
                                              decimal.mark = t$dec_mark,
                                              big.mark     = t$big_mark), "<br>",
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
                    fig_p <- fig_p %>%
                        animation_slider(currentvalue = list(prefix = "", font = f1)) %>%
                        animation_button(label = "Play")

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
            bindCache(input$x, input$filter1, input$filter2, input$filter3, lang())

    }

    server
}
