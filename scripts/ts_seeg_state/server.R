# -------------------------------- Define lógica do server --------------------------------

pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

get_server <- function(files, param) {
    server <- function(input, output, session) {
        
        df_list <- list(
            energy   = readRDS(files$db_file_energy) %>%
                filter(processos_geradores_emissoes != "Nao Identificado") %>%
                filter(processos_geradores_emissoes != "Producao de Combustiveis") %>%
                filter(processos_geradores_emissoes != "NA") %>%
                filter(!is.na(processos_geradores_emissoes)) %>%
                rename(categoria = processos_geradores_emissoes),
            farming  = readRDS(files$db_file_farming) %>%
                filter(emissores != "Lavouras Cultivadas sob Sistema Convencional") %>%
                filter(emissores != "Lavouras Cultivadas sob Sistema Plantio Direto") %>%
                rename(categoria = emissores),
            industry = readRDS(files$db_file_industry) %>%
                filter(!is.na(group)) %>%
                rename(categoria = setor)
        )
        
        # --- LANG TOGGLE ---
        lang <- reactiveVal("pt")
        observeEvent(input$toggle_lang, { lang(ifelse(lang() == "pt", "en", "pt")) })
        i18n <- reactive({ param$i18n[[lang()]] })
        tbl  <- reactive({ param$tables[[lang()]] })
        
        # Escolhas agrupadas por setor, em ordem alfabética (label de exibição),
        # com chave "setor::categoria" (categoria = valor cru do dado, para
        # bater com o filtro sem ambiguidade entre setores)
        y_choices_lang <- reactive({
            setores <- names(df_list)
            lapply_result <- lapply(setores, function(s) {
                cats <- sort(unique(df_list[[s]]$categoria))
                chave <- paste0(s, "::", cats)
                if (lang() == "en") {
                    labels <- unname(param$categoria_traducao[[s]][cats])
                } else {
                    labels <- unname(param$categoria_label_pt[[s]][cats])
                }
                labels[is.na(labels)] <- cats[is.na(labels)]  # fallback: nome cru se faltar tradução/label
                # ordena alfabeticamente pelo label de exibição, não pela chave crua
                ord <- order(labels)
                setNames(chave[ord], labels[ord])
            })
            setNames(lapply_result, unname(param$setor_labels[[lang()]][setores]))
        })
        
        parse_selection <- function(sel) {
            partes <- strsplit(sel, "::", fixed = TRUE)[[1]]
            list(setor = partes[1], categoria = partes[2])
        }
        
        label_categoria <- function(setor, categoria) {
            if (lang() == "en") {
                lbl <- unname(param$categoria_traducao[[setor]][categoria])
            } else {
                lbl <- unname(param$categoria_label_pt[[setor]][categoria])
            }
            if (is.na(lbl)) categoria else lbl
        }
        
        param$filter_choices <- reactive({
            if (is.null(input$y) || input$y == "") return(character(0))
            s <- parse_selection(input$y)$setor
            fc <- sort(unique(df_list[[s]]$group))
            fc[fc != " - " & !is.na(fc)]
        })
        
        random_inputs <- function() {
            todas <- unlist(y_choices_lang(), use.names = FALSE)
            sel <- sample(todas, 1)
            updateSelectInput(session, "y", choices = y_choices_lang(), selected = sel)
            s <- parse_selection(sel)$setor
            fc <- sort(unique(df_list[[s]]$group))
            fc <- fc[fc != " - " & !is.na(fc)]
            updateSelectInput(session, "filter1", choices = fc, selected = sample(fc, 1))
        }
        
        update_my_queryString <- function() {
            q_string <- paste0("?", "y=", input$y, "&", "ylog=", input$ylog, "&", "y_option=", input$y_option)
            for (i in input$filter1) q_string <- paste0(q_string, "&", "filter=", i)
            updateQueryString(q_string, mode = "replace")
        }
        
        update_my_inputs <- function() {
            query <- parseQueryString(session$clientData$url_search)
            if (!is.null(query[["y"]])) {
                s <- parse_selection(query[["y"]])$setor
                fc <- sort(unique(df_list[[s]]$group)); fc <- fc[fc != " - " & !is.na(fc)]
                updateSelectInput(session, "y", choices = y_choices_lang(), selected = query[["y"]])
                updateSelectInput(session, "filter1", choices = fc,
                                  selected = if (!is.null(query[["filter"]])) unlist(query[names(query) == "filter"], use.names = FALSE) else NULL)
            }
            if (!is.null(query[["ylog"]])) updateCheckboxInput(session, "ylog", value = (query[["ylog"]] == "TRUE"))
            if (!is.null(query[["y_option"]])) updateCheckboxInput(session, "y_option", value = (query[["y_option"]] == "TRUE"))
            if (is.null(query[["y"]])) random_inputs()
        }
        
        output$plot_desc_ui   <- renderUI({ p(class = "plot_desc", i18n()$plot_desc) })
        output$label_var_name <- renderText({ i18n()$label_var_name })
        output$label_log_name <- renderText({ i18n()$label_log_name })
        output$label_prop_name <- renderText({ i18n()$label_prop_name })
        output$label_geo_name  <- renderText({ i18n()$label_geo_name })
        
        # NOVO (itens 4 e 6): disclaimer do setor + estados disponíveis
        output$setor_disclaimer <- renderText({
            if (is.null(input$y) || input$y == "") return("")
            s <- parse_selection(input$y)$setor
            disc_setor <- i18n()$disclaimer_setor[[s]]
            estados <- sort(unique(df_list[[s]]$group))
            estados <- estados[estados != " - " & !is.na(estados)]
            txt <- paste0(i18n()$disclaimer_estados, paste(estados, collapse = ", "))
            if (!is.null(disc_setor)) txt <- paste0(disc_setor, " ", txt)
            txt
        })
        
        output$plot_title <- renderText({
            if (is.null(input$y) || input$y == "") return(" ")
            p <- parse_selection(input$y)
            label <- label_categoria(p$setor, p$categoria)
            text <- paste0(i18n()$title_init, label)
            if (isTRUE(input$y_option)) text <- paste0(text, "*")
            text
        })
        
        output$plot_subtitle <- renderText({
            if (is.null(input$y) || input$y == "") return(" ")
            i18n()$subtitle_init
        })
        
        output$plot <- renderPlotly({
            lang()
            update_my_queryString()
            fig <- plotly_empty()
            tryCatch({
                if (is.null(input$y) || input$y == "" || is.null(input$filter1) || length(input$filter1) < 1) {
                    fig <- plotly_empty(); stop()
                }
                p <- parse_selection(input$y)
                df <- df_list[[p$setor]]
                x_col <- tbl()[which(tbl()$var == param$x_def), ]
                
                df_filtered <- df[which(df$group %in% input$filter1), ]
                df_filtered <- df_filtered %>%
                    filter(categoria == p$categoria) %>%
                    group_by(time, group = gas) %>%
                    summarise(valor = sum(Valor, na.rm = TRUE), .groups = "drop")
                
                df_p <- data.frame(df_filtered[x_col$var], df_filtered["valor"], df_filtered["group"])
                colnames(df_p) <- c("x", "y", "color")
                df_p$group <- df_filtered$group
                df_p$text <- df_p$group
                df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y)), ]
                if (nrow(df_p) < 1) { fig <- plotly_empty(); stop() }
                
                # unidade de medida (item 3): toneladas por padrão, % se proporcional
                unidade <- if (isTRUE(input$y_option)) i18n()$tooltip_prop else i18n()$tooltip_c
                
                if (isTRUE(input$y_option) & is.numeric(df_p$y)) {
                    df_p <- df_p %>% group_by(df_p$group) %>%
                        mutate(aux1 = first(y), y_option = (y / aux1) * 100)
                    df_p$y <- df_p$y_option
                }
                if (all(is.na(df_p$color))) df_p$color <- " "
                
                # tooltip com ~2 casas decimais (item 7 de outro pedido) e unidade
                # correta conforme o modo (item 2: % no proporcional, não toneladas)
                df_p$tooltip <- paste0(
                    "<b>", df_p$text, "</b><br>", x_col$label, ": ", df_p$x, "<br>",
                    i18n()$tooltip_a, ": ", trimws(format(round(df_p$y, 2), scientific = FALSE,
                                                          decimal.mark = ",", big.mark = ".")), " ", unidade
                )
                
                fig_p <- plot_ly(df_p, x = ~x, y = ~y, color = ~group, type = "scatter",
                                 mode = "lines", text = ~tooltip, hoverinfo = "text")
                
                x_axis_layout <- list(title = x_col$label, titlefont = f1, tickfont = f2,
                                      automargin = TRUE, autorange = TRUE, showgrid = FALSE, zeroline = FALSE)
                
                # unidade no título do eixo Y (item 3), trocando conforme o modo
                y_title <- paste0(i18n()$plot_y, " (", unidade, ")")
                y_axis_layout <- list(title = y_title, titlefont = f1, tickfont = f2,
                                      automargin = FALSE, autorange = TRUE, showgrid = FALSE, zeroline = FALSE)
                if (isTRUE(input$ylog) & is.numeric(df_p$y)) y_axis_layout$type <- "log"
                if (isTRUE(input$y_option)) y_axis_layout$title <- paste0(y_title, "*")
                
                fig_p <- fig_p %>%
                    layout(font = f1, xaxis = x_axis_layout, yaxis = y_axis_layout,
                           showlegend = TRUE,
                           hoverlabel = list(bordercolor = "rgba(255,255,255,1)", bgopacity = "0.5", font = f1)) %>%
                    config(displaylogo = FALSE,
                           modeBarButtonsToRemove = c("lasso2d", "select2d", "hoverCompareCartesian"))
                
                fig <- fig_p
            }, error = function(cond) { print("plot error"); fig <- plotly_empty() })
            fig
        })
        
        observeEvent(lang(), {
            updateSelectInput(session, "y", choices = y_choices_lang(), selected = isolate(input$y))
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