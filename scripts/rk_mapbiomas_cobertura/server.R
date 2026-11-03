# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores (discreta: cada barra é um estado/município, não há mais var. contínua de cor)
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# helper: valor lógico com default FALSE
iv <- function(x) if (is.null(x)) FALSE else isTRUE(x)

# Funcão para retornar objeto server
get_server <- function(files, param) {

  # Carrega as duas bases (o toggle geográfico decide qual está ativa)
  # uma base longa; as tabelas largas (uma coluna por classe) saem dela
  base_cobertura <- readRDS(files$db_file_base)
  df_est   <- cobertura_larga(base_cobertura, "est")   %>% dplyr::ungroup()
  df_munic <- cobertura_larga(base_cobertura, "munic") %>% dplyr::ungroup()

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
    # Estado/Município via dois actionButton -- mesmo padrão do toggle SH2/SEC em
    # scripts/ts_comex_exp_municipio/server.R e do toggle geográfico de scripts/ts_mapbiomas_cobertura/server.R
    geo <- reactiveVal({
      query <- parseQueryString(isolate(session$clientData$url_search))
      if (identical(query[["geo"]], "munic")) "munic" else "est"
    })
    observeEvent(input$geo_est,   { geo("est") })
    observeEvent(input$geo_munic, { geo("munic") })
    observeEvent(geo(), {
      session$sendCustomMessage("setGeo", geo())
    }, ignoreInit = FALSE)

    df <- reactive({ if (geo() == "munic") df_munic else df_est })

    # Guarda a última classe (x) escolhida pelo usuário, para restaurar ao trocar
    # entre estado e município (troca de geo não deveria mudar a classe selecionada,
    # já que est e munic compartilham as mesmas colunas)
    kept_x <- reactiveVal(NULL)
    observeEvent(input$x, {
      if (!is.null(input$x) && input$x != "") kept_x(input$x)
    }, ignoreInit = TRUE)

    # Switch renderizado aqui para que o label acompanhe o idioma
    output$switches <- renderUI({
      i <- param$i18n[[lang()]]
      tagList(
        materialSwitch(
          "yprop", tags$span(i$label_prop_muni, class = "switch-label"),
          value = iv(isolate(input$yprop)), status = "info"
        )
      )
    })

    output$plot_name_ui    <- renderUI({ h2(class = "plot_name", param$plot_name) })
    output$plot_desc_ui    <- renderUI({ p(class = "plot_desc", i18n()$plot_desc) })
    output$label_var_name  <- renderText({ i18n()$label_var_name })
    output$label_agg       <- renderText({ i18n()$label_agg })
    output$label_geo_est   <- renderText({ i18n()$label_geo_name$est })
    output$label_geo_munic <- renderText({ i18n()$label_geo_name$munic })

    # ---------------------------- Escolhas reativas ----------------------------
    x_choices_lang <- reactive({
      table_lang <- param$tables[[lang()]]
      grouped_list(table_lang[which(table_lang$x), ])
    })

    # ---------------------------- Preenchimento inicial / aleatório ----------------------------
    random_inputs <- function() {
      xc <- x_choices_lang()
      updateSelectInput(session, "x",
                        label = i18n()$label_x_name,
                        choices = xc,
                        selected = sample(sample(xc, 1)[[1]], 1))
    }

    # ---------------------------- URL <-> inputs ----------------------------
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "lang=", lang(),
        "&", "geo=", geo(),
        "&", "x=", input$x,
        "&", "yprop=", iv(input$yprop)
      )
      updateQueryString(q_string, mode = "replace")
    }

    update_my_inputs <- function() {
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["x"]])) {
        updateSelectInput(session, "x",
                          label = i18n()$label_x_name,
                          choices = x_choices_lang(),
                          selected = query[["x"]])
      }
      if (!is.null(query[["yprop"]])) {
        updateMaterialSwitch(session, "yprop", value = (query[["yprop"]] == "TRUE"))
      }
      # Se query está vazia, preenche aleatório
      if (is.null(query[["x"]])) {
        random_inputs()
      }
    }

    # Retraduz x e labels ao trocar idioma (mantém a seleção atual)
    observeEvent(lang(), {
      updateSelectInput(session, "x",
                        label = i18n()$label_x_name,
                        choices = x_choices_lang(),
                        selected = isolate(input$x))
    }, ignoreInit = TRUE)

    # Ao trocar de nível geográfico, restaura a classe selecionada (est e munic
    # compartilham as mesmas colunas de classe, então não sorteamos de novo)
    observeEvent(geo(), {
      kx <- isolate(kept_x())
      if (!is.null(kx) && kx != "") {
        updateSelectInput(session, "x",
                          label = i18n()$label_x_name,
                          choices = x_choices_lang(),
                          selected = kx)
      }
    }, ignoreInit = TRUE)

    # ---------------------------- Títulos ----------------------------
    output$plot_title <- renderText({
      if (is.null(input$x) || input$x == "") return(i18n()$server_empty)
      table_lang <- param$tables[[lang()]]
      x_col <- table_lang[which(table_lang$var == input$x), ]
      paste0(i18n()$title_prefix, x_col$label)
    })

    output$plot_subtitle <- renderText({
      if (is.null(input$x) || input$x == "") return(" ")
      i18n()$subtitle_text
    })

    # ---------------------------- Gráfico ----------------------------
    output$plot <- renderPlotly({
      update_my_queryString()

      fig <- plotly_empty()
      tryCatch({
        if (is.null(input$x) || input$x == "") {
          fig <- plotly_empty()
          stop()
        }

        table_lang <- param$tables[[lang()]]
        x_col <- table_lang[which(table_lang$var == input$x), ]

        d <- df()

        df_p <- data.frame(
          x      = d[[input$x]],
          y      = NA,
          slider = d[[param$slider_def]],
          group  = d[["group"]]
        )
        df_p$text <- df_p$group
        df_p$id   <- df_p$group

        # Área sempre junto (usada no tooltip e, se yprop, também na normalização)
        df_area <- d %>%
          dplyr::select(group, area_km2) %>%
          dplyr::distinct()
        df_p <- df_p %>%
          dplyr::left_join(df_area, by = "group")

        # Normalização por área (proporção da área do estado/município)
        if (iv(input$yprop)) {
          df_p <- df_p %>% dplyr::mutate(x = x / area_km2)
        }

        df_p <- df_p[which(!is.na(df_p$x)), ]
        if (nrow(df_p) < 1) {
          fig <- plotly_empty()
          stop()
        }
        df_p <- df_p[which(df_p$group != " - "), ]

        # Ordena base por variável de ranking e preenche y
        df_p <- df_p %>%
          dplyr::group_by(slider) %>% # para cada ano
          dplyr::mutate(y = order(order(x, decreasing = TRUE))) %>% # rank pela var de x
          dplyr::arrange(y, .by_group = TRUE) # ordena por rank e ano

        # Se o rank for NA coloca para o final do ranking e zera x
        df_p$y[is.na(df_p$y)] <- max(df_p$y) + 1
        df_p$x[is.na(df_p$x)] <- 0

        # Deixa somente grupos que tem rank <n em algum momento
        top_n <- 10
        top_groups <- unique(df_p$group[which(df_p$y <= top_n)])
        df_p <- df_p %>% dplyr::filter(group %in% top_groups)

        unidade_x <- if (iv(input$yprop)) "%" else "ha"

        # Monta html do tooltip (valores com precisão exata: round() em casas
        # decimais, não format(..., digits=) que arredonda por algarismos
        # significativos e engole a parte decimal em números grandes)
        area_line <- if (iv(input$yprop)) {
          paste0(i18n()$label_area, ": ", trimws(format(round(df_p$area_km2, 2), scientific = FALSE,
                                                  decimal.mark = ",",
                                                  big.mark = ".")), " km²<br>")
        } else {
          ""
        }
        df_p$tooltip <- paste0(
          "<b>", df_p$text, "</b><br>",
          "(", df_p$slider, ")", "<br><br>",
          area_line,
          x_col$label, ": ", trimws(format(round(df_p$x, 2), scientific = FALSE,
                                    decimal.mark = ",",
                                    big.mark = ".")), " ", unidade_x
        )

        # Calcula menor e maior valor de x
        min_x <- min(0, min(df_p$x))
        max_x <- max(0, max(df_p$x))

        # Monta gráfico (cada barra colorida por estado/município)
        fig_p <- plot_ly(df_p,
          x = ~x,
          y = ~y,
          color = ~group,
          colors = pallete_discrete,
          frame = ~slider,
          text = ~tooltip,
          textposition = "middle right",
          showlegend = FALSE,
          hoverinfo = "text"
        )

        # adiciona barras
        fig_p <- fig_p %>% add_segments(
          x = 0,
          xend = ~x,
          y = ~y,
          yend = ~y,
          split = ~id,
          color = ~group,
          line = list(width = 30),
          opacity = 0.7
        )

        # adiciona textos
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
          fig_p <- fig_p %>% animation_slider(currentvalue = list(prefix = i18n()$year_prefix, font = f1))
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
          title = paste0(x_col$label, " (", unidade_x, ")"),
          titlefont = f1,
          tickfont = f2,
          automargin = FALSE,
          autorange = FALSE,
          range = c(min_x, max_x),
          showgrid = FALSE,
          zeroline = FALSE
        )
        y_axis_layout <- list(
          title = i18n()$ranking_label,
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

        tooltip_layout <- list(
          bordercolor = "rgba(255, 255, 255, 1)",
          bgopacity = "0.5",
          font = f1
        )

        fig_p <- fig_p %>%
          layout(
            font = f1,
            xaxis = x_axis_layout,
            yaxis = y_axis_layout,
            showlegend = FALSE,
            hoverlabel = tooltip_layout
          ) %>%
          animation_opts(1500, easing = "linear", redraw = FALSE) %>%
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
      })
      fig
    }) %>%
      bindCache(input$x, input$yprop, geo(), lang())

    # ---------------------------- Startup ----------------------------
    # observeEvent (não observe) para não recriar o vínculo reativo em toda
    # troca de geo/idioma -- mesmo cuidado de scripts/ts_mapbiomas_cobertura/server.R
    observeEvent(session$clientData$url_search, {
      update_my_inputs()
    }, ignoreInit = FALSE)
  }

  # Retorna objeto server
  server
}
