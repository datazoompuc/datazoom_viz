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

  # Carrega índice de preços anual
  indice <- read.csv(files$aux_file, stringsAsFactors = FALSE)
  indice$time <- as.integer(indice$CO_ANO)
  indice$indice_anual_base1998 <- as.numeric(indice$indice_anual_base1998)
  indice <- indice[, c("time", "indice_anual_base1998")]

  # Tabela de tradução de países
  paises <- read.csv(files$country_map_file, stringsAsFactors = FALSE)
  country_map <- setNames(paises$en, paises$pt)

  server <- function(input, output, session) {

    # --- LANG TOGGLE ---

    lang <- reactiveVal("pt")

    observeEvent(input$toggle_lang, {
      lang(ifelse(lang() == "pt", "en", "pt"))
    })

    i18n <- reactive({ param$i18n[[lang()]] })

    # df reativo: aplica tradução de países quando EN
    df_plot <- reactive({
      if (lang() == "en") {
        df %>% mutate(group = dplyr::recode(group, !!!country_map))
      } else {
        df
      }
    })

    # Renderiza textos dinâmicos da sidebar
    output$plot_name_ui  <- renderUI({ h2(class = "plot_name", i18n()$plot_name) })
    output$plot_desc_ui  <- renderUI({ p(class = "plot_desc", i18n()$plot_desc) })
    output$label_deflator <- renderText({ i18n()$label_deflator })

    # Atualiza botão quando idioma muda
    observeEvent(lang(), {
      updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
    }, ignoreInit = FALSE)

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0("?", "lang=", lang())
      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      query <- parseQueryString(session$clientData$url_search)
      if (!is.null(query[["lang"]]) && query[["lang"]] %in% c("pt", "en")) {
        lang(query[["lang"]])
      }
    }

    # Output título do gráfico
    output$plot_title <- renderText({ i18n()$plot_title })
    output$plot_subtitle <- renderText({ i18n()$subtitle })

    # Output gráfico
    output$plot <- renderPlotly({
      update_my_queryString()

      fig <- plotly_empty()
      tryCatch(
        {
          df_cur <- df_plot()

          x_col     <- param$table[which(param$table$var == param$x_def), ]
          color_col <- param$table[which(param$table$var == param$color_def), ]
          slider_col <- param$table[which(param$table$var == param$slider_def), ]
          id_col    <- param$table[which(param$table$var == param$id_def), ]

          # Coluna de ranking (calculada)
          y_col <- list()
          y_col$var <- "rank"
          y_col$label <- i18n()$y_label

          df_p <- data.frame(
            df_cur[x_col$var],
            NA,
            df_cur[color_col$var],
            df_cur[slider_col$var],
            df_cur["group"],
            df_cur["group"],
            df_cur[id_col$var]
          )
          colnames(df_p) <- c("x", "y", "color", "slider", "text", "group", "id")

          # Filtra colunas onde variáveis são NA
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$color)), ]

          # Aplica deflação ao valor antes de calcular o ranking
          if (isTRUE(input$ydefl)) {
            df_p <- df_p[df_p$slider >= 1998, ]
            df_p$indice_anual_base1998 <- indice$indice_anual_base1998[
              match(df_p$slider, indice$time)
            ]
            df_p <- df_p[!is.na(df_p$indice_anual_base1998), ]
            df_p$x <- df_p$x * (100 / df_p$indice_anual_base1998)
          }

          # Se dataset estiver vazio, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Filtra sem grupo
          df_p <- df_p[which(df_p$group != " - "), ]

          # Ordena base por variável de ranking e preenche y
          df_p <- df_p %>%
            group_by(slider) %>%
            mutate(y = order(order(x, decreasing = TRUE))) %>%
            arrange(y, .by_group = TRUE)

          df_p$y[is.na(df_p$y)] <- max(df_p$y) + 1
          df_p$x[is.na(df_p$x)] <- 0

          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }

          # Deixa somente grupos que tem rank <= top_n em algum momento
          top_n <- 10
          top_groups <- unique(df_p$group[which(df_p$y <= top_n)])
          df_p <- df_p %>% filter(group %in% top_groups)

          x_label_full <- if (isTRUE(input$ydefl)) paste0(i18n()$x_label, " (", i18n()$ylabel_deflator, ")") else i18n()$x_label

          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            "(", df_p$slider, ")", "<br><br>",
            x_label_full, ": ", format(df_p$x, scientific = FALSE,
                                          digits = 2,
                                          decimal.mark = ",",
                                          big.mark = "."), "<br>",
            i18n()$y_label, ": ", df_p$y, "<br>",
            if (isTRUE(input$ydefl)) i18n()$ylabel_deflator else paste0(i18n()$unit_text, ": ", param$unit), "<br>",
            i18n()$color_label, ": ", df_p$color
          )

          # Define paleta de cores
          pallete <- pallete_continuous
          if (!is.numeric(df_p$color)) {
            pallete <- pallete_discrete
          }

          # Calcula menor e maior valor de x
          min_x <- min(0, min(df_p$x))
          max_x <- max(0, max(df_p$x))

          # Monta gráfico base
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
          ) %>% animation_opts(frame = 1500, transition = 1500, easing = "linear", redraw = FALSE)

          # Adiciona barras
          fig_p <- fig_p %>% add_segments(
            x = 0,
            xend = ~x,
            y = ~y,
            yend = ~y,
            color = ~color,
            line = list(width = 30),
            opacity = 0.7
          )

          # Adiciona textos
          fig_p <- fig_p %>% add_text(
            x = 0.01 * max_x,
            text = ~text,
            ids = ~id,
            hoverinfo = "none",
            textfont = f1,
            textposition = "middle right"
          )

          # Parâmetros animação e slider (se tiver mais de um frame)
          if (length(unique(df_p$slider)) > 1) {
            fig_p <- plotly_build(fig_p)
            idx <- which(vapply(fig_p$x$layout$sliders, function(s) inherits(s, "aniSlider"), logical(1)))
            if (length(idx) == 1) {
              fig_p$x$layout$sliders[[idx]]$currentvalue <- list(prefix = i18n()$year_prefix, font = f1)
            }

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
                    label = "▶",
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

            # Pula animação para último frame (custom JS)
            first_frame <- min(df_p$slider)
            last_frame <- max(df_p$slider)
            fig_p <- fig_p %>% onRender("
            function(el,x,data){
              Plotly.animate(el, data, {frame: [{duration: 0}]})
            }",
              data = c(first_frame, last_frame)
            )
          }

          # Layout eixos
          x_axis_layout <- list(
            title = x_label_full,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = FALSE,
            range = c(min_x, max_x),
            showgrid = FALSE,
            zeroline = FALSE
          )
          y_axis_layout <- list(
            title = i18n()$y_label,
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

          # Layout hover/tooltip
          tooltip <- list(
            bordercolor = "rgba(255, 255, 255, 1)",
            bgopacity = "0.5",
            font = f1
          )

          # Aplica layout
          fig_p <- fig_p %>%
            layout(
              font = f1,
              xaxis = x_axis_layout,
              yaxis = y_axis_layout,
              showlegend = TRUE,
              legend = list(title = list(text = i18n()$color_label)),
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

    # Observa eventos
    observe({
      query <- parseQueryString(session$clientData$url_search)
      update_my_inputs()
    })
  }

  # Retorna objeto server
  server
}
