# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# Funcão para retornar objeto server
get_server <- function(files, param) {
  server <- function(input, output, session) {

    # Carrega os dois recortes (transpostas) uma única vez.
    dfs <- list(
      pais_sec = readRDS(files$db_file_pais_sec), # group = país,  y = seção
      sec_pais = readRDS(files$db_file_sec_pais)  # group = seção, y = país
    )

    # Estado: idioma, orientação e seleções persistentes
    q0 <- parseQueryString(isolate(session$clientData$url_search))

    lang <- reactiveVal(if (identical(q0[["lang"]], "en")) "en" else "pt")
    observeEvent(input$toggle_lang, { lang(ifelse(lang() == "pt", "en", "pt")) })

    mode <- reactiveVal(if (identical(q0[["mode"]], "sec_pais")) "sec_pais" else "pais_sec")
    observeEvent(input$swap, {
      mode(if (mode() == "pais_sec") "sec_pais" else "pais_sec")
    })

    # Seleções mantidas entre transposições e idiomas (sempre em PT; seção em nome completo)
    init_countries <- if (!is.null(q0[["country"]])) unname(unlist(q0[names(q0) == "country"])) else param$defaults$countries
    init_sections  <- if (!is.null(q0[["section"]])) unname(unlist(q0[names(q0) == "section"])) else param$defaults$sections
    kept_countries <- reactiveVal(init_countries)
    kept_sections  <- reactiveVal(init_sections)

    i18n <- reactive({ param$i18n[[lang()]] })

    # Traduz valores `group` (PT) para o idioma ativo, com fallback ao próprio valor
    display_label <- function(values, m, l) {
      if (l == "en") {
        map <- param$filter_labels_en[[m]]
        out <- unname(map[values])
        ifelse(is.na(out), values, out)
      } else {
        values
      }
    }

    # Configuração do recorte ativo
    cfg <- reactive({
      m <- mode(); l <- lang()
      list(m = m, df = dfs[[m]], table = param$tables[[m]][[l]])
    })

    # Textos reativos da sidebar
    output$plot_desc       <- renderText({ i18n()$plot_desc })
    output$label_var_name  <- renderText({ i18n()$label_var_name })
    output$label_scale_name<- renderText({ i18n()$label_scale_name })
    output$label_prop_name <- renderText({ i18n()$label_prop_name })
    output$label_swap      <- renderText({ i18n()$label_swap })
    output$btn_fullscreen  <- renderText({ i18n()$btn_fullscreen })
    output$role_y <- renderText({
      paste0(i18n()$role_y_prefix, i18n()[[mode()]]$dim_y)
    })
    output$role_lines <- renderText({
      paste0(i18n()$role_lines_prefix, i18n()[[mode()]]$dim_lines)
    })
    observeEvent(lang(), {
      updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
    }, ignoreInit = FALSE)

    # Remonta choices/seleção de y e filtro quando orientação ou idioma mudam
    # Mantém as seleções (kept_*) e reordena as choices alfabeticamente no idioma ativo.
    observeEvent(list(mode(), lang()), {
      m <- mode(); l <- lang()
      labs <- i18n()[[m]]
      tbl  <- cfg()$table

      # Choices do eixo y (ordenadas pelo label do idioma ativo)
      ytab <- tbl[which(tbl$y), ]
      ytab <- ytab[order(ytab$label), ]
      y_choices <- append("", grouped_list(ytab))

      # Choices do filtro (valores em PT, labels traduzidos, ordenados pelo label)
      pts  <- setdiff(unique(cfg()$df$group), " - ")
      pts  <- pts[!is.na(pts)]
      disp <- display_label(pts, m, l)
      ord  <- order(disp)
      f_choices <- setNames(pts[ord], disp[ord])

      # Seleção atual a partir do estado mantido
      if (m == "pais_sec") {
        y_sel <- if (length(kept_sections())) kept_sections()[1] else NULL
        f_sel <- kept_countries()
      } else {
        y_sel <- if (length(kept_countries())) kept_countries()[1] else NULL
        f_sel <- kept_sections()
      }

      updateSelectInput(session, "y",
        label = labs$label_y, choices = y_choices, selected = y_sel
      )
      updateSelectizeInput(session, "filter1",
        label = labs$label_filter, choices = f_choices, selected = f_sel
      )
    }, ignoreInit = FALSE)

    # Captura edições do usuário no estado mantido (ignoreNULL evita apagar em transições)
    observeEvent(input$y, {
      if (input$y == "") return()
      if (mode() == "pais_sec") {
        kept_sections(unique(c(input$y, kept_sections())))
      } else {
        kept_countries(unique(c(input$y, kept_countries())))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$filter1, {
      if (mode() == "pais_sec") {
        kept_countries(input$filter1)
      } else {
        kept_sections(input$filter1)
      }
    }, ignoreInit = TRUE)

    # Atualiza a URL (compartilhável: idioma, orientação e seleções)
    update_my_queryString <- function() {
      q <- paste0("?lang=", lang(), "&mode=", mode())
      for (c in kept_countries()) q <- paste0(q, "&country=", utils::URLencode(c, reserved = TRUE))
      for (s in kept_sections())  q <- paste0(q, "&section=", utils::URLencode(s, reserved = TRUE))
      updateQueryString(q, mode = "replace")
    }

    # Título / subtítulo
    output$plot_title <- renderText({
      if (is.null(input$y) || input$y == "") return(" ")
      tbl <- cfg()$table
      y_col <- tbl[which(tbl$var == input$y), ]
      txt <- paste0("", y_col$label)
      if (isTRUE(input$y_option)) txt <- paste0(txt, "*")
      txt
    })
    output$plot_subtitle <- renderText({
      if (is.null(input$y) || input$y == "") " " else paste0("", i18n()$currency, "")
    })

    # Gráfico
    output$plot <- renderPlotly({
      update_my_queryString()

      fig <- plotly_empty()
      tryCatch(
        {
          act <- cfg()
          df  <- act$df
          tbl <- act$table

          if (is.null(input$y) || input$y == "" ||
            is.null(input$filter1) || length(input$filter1) < 1) {
            fig <- plotly_empty()
            stop()
          }

          x_col <- tbl[which(tbl$var == param$x_def), ]
          y_col <- tbl[which(tbl$var == input$y), ]

          df_filtered <- df[which(df$group %in% input$filter1), ]
          df_p <- data.frame(
            x = df_filtered[[x_col$var]],
            y = df_filtered[[input$y]],
            group = df_filtered$group
          )
          df_p$text <- display_label(df_p$group, act$m, lang())
          # Legenda enxuta (nomes de seção são longos); tooltip mantém o nome completo
          leg_max <- 40
          df_p$legend <- ifelse(
            nchar(df_p$text) > leg_max,
            paste0(substr(df_p$text, 1, leg_max - 1), "…"),
            df_p$text
          )

          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y)), ]
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          if (isTRUE(input$y_option) & is.numeric(df_p$y)) {
            df_p <- df_p %>%
              group_by(group) %>%
              arrange(x) %>%
              mutate(aux1 = first(y), y_option = (y / aux1) * 100) %>%
              ungroup()
            df_p$y <- df_p$y_option
          }

          measurement <- if (isTRUE(input$y_option)) "" else i18n()$measurement

          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            x_col$label, ": ", df_p$x, "<br>",
            y_col$label, ": ", measurement, format(df_p$y,
              scientific = FALSE, digits = 2,
              decimal.mark = ",", big.mark = "."
            ),
            "<extra></extra>"
          )

          fig_p <- plot_ly(df_p,
            x = ~x, y = ~y, color = ~legend,
            type = "scatter", mode = "lines",
            text = ~tooltip, hovertemplate = ~tooltip
          )

          x_axis_layout <- list(
            title = x_col$label, titlefont = f1, tickfont = f2,
            automargin = FALSE, autorange = TRUE, showgrid = FALSE, zeroline = FALSE
          )
          y_axis_layout <- list(
            title = y_col$label, titlefont = f1, tickfont = f2,
            automargin = FALSE, autorange = TRUE, showgrid = FALSE, zeroline = FALSE
          )
          if (isTRUE(input$ylog) & is.numeric(df_p$y)) y_axis_layout$type <- "log"
          if (isTRUE(input$y_option)) y_axis_layout$title <- paste0(y_col$label, "*")

          tooltip <- list(bordercolor = "rgba(255, 255, 255, 1)", bgopacity = "0.5", font = f1, align = "left")

          fig_p <- fig_p %>%
            layout(
              font = f1, xaxis = x_axis_layout, yaxis = y_axis_layout,
              showlegend = TRUE, hoverlabel = tooltip
            ) %>%
            config(
              displaylogo = FALSE,
              modeBarButtonsToRemove = c("lasso2d", "select2d", "hoverCompareCartesian")
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
  }

  # Retorna objeto server
  server
}
