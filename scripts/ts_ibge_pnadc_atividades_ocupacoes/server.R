# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84","#ffcf48" ,"#c3ff83","#007e47","#00596d","#4fdf94","#99b0c8","#261c4e","#000098","#c368b1","#60458c","#757575")
pallete_continuous <- c("#440154","#481567" ,"#453781","#404788","#39568c","#33638d","#287d8e","#238a8d","#1f968b","#20a387","#29af7f","#3cbb75","#55c667","#73d055","#95d840","#b8de29","#dce319","#fde725")

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

get_server <- function(files, param) {
    server <- function(input, output, session) {

        df <- readRDS(files$db_file)

        # Lê categories uma vez ao iniciar
        categories_df <- read.csv(
            files$categories_file, sep = ";",
            stringsAsFactors = FALSE, fileEncoding = "UTF-8"
        )

        # Helper: constrói choices a partir de pnadc_categories.csv 
        read_pnadc_choices <- function(filter_id, lang_val = "pt") {
            cats <- categories_df[categories_df$filter_id == filter_id & nzchar(categories_df$value), ]
            cats <- cats[order(cats$ord_group, cats$ord_item), ]
            out  <- list()
            for (g_pt in unique(cats$group_pt)) {
                items  <- cats[cats$group_pt == g_pt, ]
                if (g_pt == "UF") items <- items[order(items$value), ]
                g_label        <- if (lang_val == "pt") items$group_pt[1] else items$group_en[1]
                labels         <- if (g_pt == "UF") items$value else if (lang_val == "pt") items$label_pt else items$label_en
                out[[g_label]] <- as.list(setNames(items$value, labels))
            }
            out
        }

        # Helper: constrói choices de filter2
        build_ocupation_choices <- function(lang_val = "pt") {
            t    <- param$i18n[[lang_val]]
            lbl  <- function(x) if (lang_val == "pt") x$label_pt else x$label_en
            get_sorted <- function(fid) {
                x <- categories_df[categories_df$filter_id == fid & nzchar(categories_df$value) & categories_df$value != "Todos", ]
                x[order(lbl(x)), ]
            }
            cnae <- get_sorted("cnae")
            cod  <- get_sorted("cod")
            choices <- list()
            choices[[t$label_all]]  <- setNames(list("All::Todos"), if (lang_val == "pt") "Todos" else "All")
            choices[[t$label_cnae]] <- as.list(setNames(paste0("CNAE::", cnae$value), lbl(cnae)))
            choices[[t$label_cod]]  <- as.list(setNames(paste0("COD::",  cod$value),  lbl(cod)))
            choices
        }

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
        output$plot_name_ui  <- renderUI({ h2(class = "plot_name", txt()$plot_name) })
        output$plot_desc_ui  <- renderUI({ p(class  = "plot_desc", txt()$plot_desc) })
        output$label_var_ui  <- renderUI({ p(class  = "vars",      txt()$label_var_name) })
        output$label_scale_ui <- renderUI({ tags$span(txt()$label_scale_name, class = "switch-title") })
        output$label_prop_ui  <- renderUI({ tags$span(txt()$label_prop_name,  class = "switch-title") })
        output$last_quarter_ui <- renderUI({
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

        # Atualiza todos os inputs quando a língua muda
        observeEvent(lang(), {
            t   <- txt()
            tbl <- param_tbl()

            updateSelectInput(session, "y",
                              label   = t$label_y_name,
                              choices = setNames(tbl$var[tbl$y], tbl$label[tbl$y]),
                              selected = isolate(if (!is.null(input$y)) input$y else param$y_def))

            sel1 <- isolate(input$filter1)
            sel2 <- isolate(input$filter2)
            sel3 <- isolate(input$filter3)
            if (is.null(sel1) || length(sel1) == 0) sel1 <- c("Amaz\u00f4nia Legal", "Brasil")
            if (is.null(sel2) || length(sel2) == 0) sel2 <- param$ocupation_def
            if (is.null(sel3) || length(sel3) == 0) sel3 <- param$sector_def

            updateSelectizeInput(session, "filter1",
                                 label    = t$label_region_name,
                                 choices  = read_pnadc_choices("region", lang()),
                                 selected = sel1,
                                 options  = list(maxItems = 20))

            updateSelectizeInput(session, "filter2",
                                 label    = t$label_type_name,
                                 choices  = build_ocupation_choices(lang()),
                                 selected = sel2,
                                 options  = list(maxItems = 20))

            updateSelectizeInput(session, "filter3",
                                 label    = t$label_sector_name,
                                 choices  = read_pnadc_choices("sector", lang()),
                                 selected = sel3,
                                 options  = list(maxItems = 1))

            updateActionButton(session, "toggle_lang", label = t$btn_lang)

        }, ignoreInit = FALSE)

        # Função para atualizar url do app com parâmetros dos inputs
        update_my_queryString <- function() {
            q_string <- paste0(
                "?","y=",input$y,
                "&","ylog=",input$ylog,
                "&","y_option=",input$y_option
            )
            if (lang() == "en") q_string <- paste0(q_string, "&lang=en")
            for (i in input$filter1)  q_string <- paste0(q_string, "&filter=",  i)
            for (j in input$filter2)  q_string <- paste0(q_string, "&filter2=", j)
            for (k in input$filter3)  q_string <- paste0(q_string, "&filter3=", k)
            updateQueryString(q_string, mode = "replace")
        }

        # Função para atualizar inputs a partir da URL
        update_my_inputs <- function() {
            query <- parseQueryString(session$clientData$url_search)

            if (!is.null(query[['y']])) {
                updateSelectInput(session, "y", selected = query[['y']])
            }
            if (!is.null(query[['ylog']])) {
                updateCheckboxInput(session, "ylog", value = (query[['ylog']] == "TRUE"))
            }
            if (!is.null(query[['y_option']])) {
                updateCheckboxInput(session, "y_option", value = (query[['y_option']] == "TRUE"))
            }
            selected1 <- unlist(query[names(query) == "filter"],  use.names = FALSE)
            if (length(selected1) > 0) updateSelectizeInput(session, "filter1", selected = selected1)

            selected2 <- unlist(query[names(query) == "filter2"], use.names = FALSE)
            if (length(selected2) > 0) updateSelectizeInput(session, "filter2", selected = selected2)

            selected3 <- unlist(query[names(query) == "filter3"], use.names = FALSE)
            if (length(selected3) > 0) updateSelectizeInput(session, "filter3", selected = selected3)
        }

        # Título do gráfico
        output$plot_title <- renderText({
            req(input$y)
            tbl <- param_tbl()
            y_label <- tbl$label[tbl$var == input$y]
            title <- paste(txt()$title_init, y_label)
            if (isTRUE(input$y_option)) paste0(title, "*") else title
        })

        output$plot_subtitle <- renderText({
            req(input$y)
            txt()$subtitle
        })

        # Gráfico principal
        output$plot <- renderPlotly({
            update_my_queryString()

            fig <- plotly_empty()
            tryCatch({
                if (is.null(input$y) || input$y == "" ||
                    is.null(input$filter1) || length(input$filter1) < 1) stop()

                x_col     <- param_tbl()[param_tbl()$var == param$x_def, ]
                y_col     <- param_tbl()[param_tbl()$var == input$y, ]
                color_col <- param$table[param$table$var == param$color_def, ]

                # Parseia valores prefixados do filter2
                sel      <- input$filter2
                is_todos <- "All::Todos" %in% sel
                cnae_sel <- sub("^CNAE::", "", sel[startsWith(sel, "CNAE::")])
                cod_sel  <- sub("^COD::",  "", sel[startsWith(sel, "COD::")])

                df_filtered <- df %>%
                    dplyr::filter(
                        group %in% input$filter1 &
                        setor %in% input$filter3 &
                        (
                            (is_todos & id == "All") |
                            (id == "CNAE" & composicao_demografica %in% cnae_sel) |
                            (id == "COD"  & composicao_demografica %in% cod_sel)
                        )
                    )

                df_p <- data.frame(
                    df_filtered[x_col$var],
                    df_filtered[y_col$var],
                    df_filtered[color_col$var]
                )
                colnames(df_p) <- c("x", "y", "color")
                df_p$group               <- df_filtered$group
                df_p$composicao_demografica <- df_filtered$composicao_demografica
                df_p$id                  <- df_filtered$id

                # Traduz labels de legenda/tooltip quando em inglês
                group_disp <- df_p$group
                cd_disp    <- df_p$composicao_demografica
                if (lang() == "en") {
                    region_rows <- categories_df[categories_df$filter_id == "region" & nzchar(categories_df$value), ]
                    region_lkp  <- setNames(region_rows$label_en, region_rows$value)
                    group_disp  <- ifelse(group_disp %in% names(region_lkp), region_lkp[group_disp], group_disp)

                    act_rows <- categories_df[categories_df$filter_id %in% c("cnae", "cod") & nzchar(categories_df$value), ]
                    act_lkp  <- setNames(act_rows$label_en, act_rows$value)
                    cd_disp  <- ifelse(cd_disp %in% names(act_lkp), act_lkp[cd_disp], cd_disp)
                }
                df_p$text <- paste(group_disp, "-", cd_disp)

                df_p <- df_p[!is.na(df_p$x) & !is.na(df_p$y), ]
                if (nrow(df_p) < 1) stop()

                # Labels com ambiguidade (mesmo nome em CNAE e COD) recebem sufixo
                ambiguous <- df_p %>%
                    dplyr::filter(id != "All") %>%
                    dplyr::group_by(composicao_demografica) %>%
                    dplyr::summarize(n_ids = dplyr::n_distinct(id), .groups = "drop") %>%
                    dplyr::filter(n_ids > 1) %>%
                    dplyr::pull(composicao_demografica)

                df_p$combined <- ifelse(
                    df_p$id != "All" & df_p$composicao_demografica %in% ambiguous,
                    paste0(df_p$text, " (", df_p$id, ")"),
                    df_p$text
                )

                if (isTRUE(input$y_option) && is.numeric(df_p$y)) {
                    df_p <- df_p %>%
                        dplyr::ungroup() %>%
                        dplyr::arrange(x) %>%
                        dplyr::mutate(y = 100 * y / dplyr::first(y), .by = combined)
                }

                if (all(is.na(df_p$color))) df_p$color <- " "

                t <- txt()
                df_p$tooltip <- paste0(
                    "<b>", df_p$combined, "</b><br>",
                    x_col$label, ": ", paste0("T", quarter(df_p$x), "-", year(df_p$x)), "<br>",
                    y_col$label, ": ", format(df_p$y,
                                              scientific  = FALSE,
                                              digits      = 2,
                                              decimal.mark = t$dec_mark,
                                              big.mark     = t$big_mark), "<br>"
                )

                y_title <- if (isTRUE(input$y_option)) paste0(y_col$label, "*") else y_col$label
                if (isTRUE(input$ylog) && is.numeric(df_p$y)) y_title <- paste0(y_title, " (log)")

                x_axis_layout <- list(
                    title = x_col$label, titlefont = f1, tickfont = f2,
                    automargin = FALSE, autorange = TRUE, showgrid = FALSE, zeroline = FALSE
                )
                y_axis_layout <- list(
                    title = y_title, titlefont = f1, tickfont = f2,
                    automargin = FALSE, autorange = TRUE, showgrid = FALSE, zeroline = FALSE
                )
                if (isTRUE(input$ylog) && is.numeric(df_p$y)) y_axis_layout$type <- "log"

                tooltip_style <- list(bordercolor = "rgba(255,255,255,1)", bgopacity = "0.5", font = f1)

                fig_p <- plot_ly(df_p,
                                 x = ~x, y = ~y, color = ~combined,
                                 type = "scatter", mode = "lines",
                                 text = ~tooltip, hoverinfo = "text") %>%
                    layout(font = f1, xaxis = x_axis_layout, yaxis = y_axis_layout,
                           showlegend = TRUE, hoverlabel = tooltip_style) %>%
                    config(displaylogo = FALSE,
                           modeBarButtonsToRemove = c("lasso2d", "select2d", "hoverCompareCartesian"))

                fig <- fig_p
            },
            error = function(cond) {
                print("plot error")
                fig <<- plotly_empty()
            })
            fig
        })

        observe({
            query <- parseQueryString(session$clientData$url_search)
            update_my_inputs()
        })
    }

    server
}
