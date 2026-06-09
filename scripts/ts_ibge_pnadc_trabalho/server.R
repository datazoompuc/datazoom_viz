# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

get_server <- function(files, param) {

    df <- readRDS(files$db_file)

    categories_df <- read.csv(
        files$categories_file, sep = ";",
        stringsAsFactors = FALSE, fileEncoding = "UTF-8"
    )

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

    # Helper: traduz vetor de valores PT para labels PT ou EN usando categories_df
    translate_values <- function(filter_id, values, lang_val = "pt") {
        cats <- categories_df[categories_df$filter_id == filter_id & nzchar(categories_df$value), ]
        label_col <- if (lang_val == "pt") cats$label_pt else cats$label_en
        lookup <- setNames(label_col, cats$value)
        # UFs ficam iguais (sem tradução)
        translated <- lookup[values]
        ifelse(is.na(translated), values, translated)
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

        # Atualiza inputs quando a língua muda
        observeEvent(lang(), {
            t   <- txt()
            tbl <- param_tbl()

            updateSelectInput(session, "y",
                              label    = t$label_y_name,
                              choices  = setNames(tbl$var[tbl$y], tbl$label[tbl$y]),
                              selected = isolate(if (!is.null(input$y)) input$y else param$y_def))

            sel1 <- isolate(input$filter1)
            sel2 <- isolate(input$filter_composicao_demografica)
            if (is.null(sel1) || length(sel1) == 0) sel1 <- param$filter_geo_def
            if (is.null(sel2) || length(sel2) == 0) sel2 <- param$filter_comp_def

            updateSelectizeInput(session, "filter1",
                                 label    = t$label_geo_name,
                                 choices  = read_pnadc_choices("region", lang()),
                                 selected = sel1,
                                 options  = list(maxItems = 20))

            updateSelectizeInput(session, "filter_composicao_demografica",
                                 label    = t$label_comp_name,
                                 choices  = read_pnadc_choices("composicao_demografica", lang()),
                                 selected = sel2,
                                 options  = list(maxItems = 5))

            updateActionButton(session, "toggle_lang", label = t$btn_lang)
        })

        # Inicializa inputs a partir da URL na primeira carga (isolate evita re-execução ao trocar língua)
        observe({
            query    <- parseQueryString(session$clientData$url_search)
            lang_val <- isolate(lang())
            t        <- param$i18n[[lang_val]]
            tbl      <- param$tables[[lang_val]]

            sel1  <- if (!is.null(query[["filter"]])) unlist(query[names(query) == "filter"]) else param$filter_geo_def
            sel2  <- if (!is.null(query[["filter_composicao"]])) strsplit(query[["filter_composicao"]], ",")[[1]] else param$filter_comp_def
            y_sel <- if (!is.null(query[["y"]])) query[["y"]] else param$y_def

            updateSelectInput(session, "y",
                              choices  = setNames(tbl$var[tbl$y], tbl$label[tbl$y]),
                              selected = y_sel)

            updateSelectizeInput(session, "filter1",
                                 label    = t$label_geo_name,
                                 choices  = read_pnadc_choices("region", lang_val),
                                 selected = sel1,
                                 options  = list(maxItems = 20))

            updateSelectizeInput(session, "filter_composicao_demografica",
                                 label    = t$label_comp_name,
                                 choices  = read_pnadc_choices("composicao_demografica", lang_val),
                                 selected = sel2,
                                 options  = list(maxItems = 5))
        })

        # Atualiza URL
        update_my_queryString <- function() {
            q_string <- paste0("?y=", input$y,
                               "&filter_composicao=", paste(input$filter_composicao_demografica, collapse = ","))
            for (i in input$filter1) {
                q_string <- paste0(q_string, "&filter=", i)
            }
            updateQueryString(q_string, mode = "replace")
        }

        # Dataframe reativo filtrado por composição demográfica
        df_reactived <- reactive({
            req(input$filter_composicao_demografica)
            df %>% dplyr::filter(composicao_demografica %in% input$filter_composicao_demografica)
        })

        # Título e subtítulo
        output$plot_title <- renderText({
            req(input$y)
            tbl <- param_tbl()
            y_col <- tbl[which(tbl$var == input$y), ]
            if (nrow(y_col) == 0) return(" ")
            y_col$desc[1]
        })

        output$plot_subtitle <- renderText({
            req(input$y)
            t    <- txt()
            comp <- input$filter_composicao_demografica
            if (is.null(comp) || length(comp) == 0) return(" ")
            comp_lbl <- translate_values("composicao_demografica", comp, lang())
            paste0(t$subtitle_init, paste(comp_lbl, collapse = ", "))
        })

        # Gráfico
        output$plot <- renderPlotly({
            update_my_queryString()

            fig <- plotly_empty()
            tryCatch({
                req(input$y, input$filter1, input$filter_composicao_demografica)
                if (length(input$filter1) < 1 || length(input$filter_composicao_demografica) < 1) stop()

                t   <- txt()
                tbl <- param_tbl()

                x_col     <- tbl[which(tbl$var == param$x_def), ]
                y_col     <- tbl[which(tbl$var == input$y), ]
                color_col <- tbl[which(tbl$var == param$color_def), ]

                df_filtered <- df_reactived()[which(df_reactived()$group %in% input$filter1), ]

                if (nrow(df_filtered) < 1) stop()

                df_p <- data.frame(
                    x     = df_filtered[[x_col$var]],
                    y     = df_filtered[[y_col$var]],
                    group = df_filtered$group,
                    comp  = df_filtered$composicao_demografica
                )

                # Traduz group e comp para a língua activa
                lg <- lang()
                df_p$group_lbl <- translate_values("region",                 df_p$group, lg)
                df_p$comp_lbl  <- translate_values("composicao_demografica", df_p$comp,  lg)

                # Chave de série: simples quando só 1 composição, composta quando múltiplas
                df_p$series <- if (length(input$filter_composicao_demografica) == 1) {
                    df_p$group_lbl
                } else {
                    paste(df_p$group_lbl, "·", df_p$comp_lbl)
                }

                df_p <- df_p[!is.na(df_p$x) & !is.na(df_p$y), ]
                if (nrow(df_p) < 1) stop()

                df_p$tooltip <- paste0(
                    "<b>", df_p$series, "</b><br>",
                    x_col$label, ": ", paste0(lubridate::year(df_p$x), "-T", lubridate::quarter(df_p$x)), "<br>",
                    t$tooltip_comp, df_p$comp_lbl, "<br>",
                    y_col$label, ": ", format(100 * df_p$y,
                                              scientific  = FALSE,
                                              digits      = 2,
                                              decimal.mark = t$dec_mark,
                                              big.mark    = t$big_mark), "%<br>"
                )

                fig_p <- plot_ly(df_p,
                                 x        = ~x,
                                 y        = ~y,
                                 color    = ~series,
                                 type     = "scatter",
                                 mode     = "lines+markers",
                                 text     = ~tooltip,
                                 hoverinfo = "text")

                fig_p <- fig_p %>%
                    layout(
                        font  = f1,
                        xaxis = list(
                            title     = x_col$label,
                            titlefont = f1,
                            tickfont  = f2,
                            autorange = TRUE,
                            showgrid  = FALSE,
                            zeroline  = FALSE
                        ),
                        yaxis = list(
                            title      = y_col$label,
                            titlefont  = f1,
                            tickfont   = f2,
                            tickformat = ".2%",
                            autorange  = TRUE,
                            showgrid   = FALSE,
                            zeroline   = FALSE
                        ),
                        showlegend = TRUE,
                        hoverlabel = list(bordercolor = "rgba(255,255,255,1)", bgopacity = "0.5", font = f1)
                    ) %>%
                    config(
                        displaylogo = FALSE,
                        modeBarButtonsToRemove = c("lasso2d", "select2d", "hoverCompareCartesian")
                    )

                fig <- fig_p
            }, error = function(e) {
                print(paste("plot error:", e$message))
            })
            fig
        })
    }

    server
}
