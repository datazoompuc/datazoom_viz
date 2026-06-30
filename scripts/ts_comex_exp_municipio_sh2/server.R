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

    # Carrega os dois recortes (transpostas)
    dfs <- list(
      munic_sh2 = readRDS(files$db_file_munic_sh2), # group = produto (SH2), y = município
      sh2_munic = readRDS(files$db_file_sh2_munic)  # group = município, y = produto (SH2)
    )

    # Estado: idioma, orientação e seleções persistentes
    q0 <- parseQueryString(isolate(session$clientData$url_search))

    lang <- reactiveVal(if (identical(q0[["lang"]], "en")) "en" else "pt")
    observeEvent(input$toggle_lang, { lang(ifelse(lang() == "pt", "en", "pt")) })

    mode <- reactiveVal(if (identical(q0[["mode"]], "sh2_munic")) "sh2_munic" else "munic_sh2")
    observeEvent(input$swap, {
      mode(if (mode() == "munic_sh2") "sh2_munic" else "munic_sh2")
    })

    # Seleções mantidas entre transposições e idiomas (em PT; produto em nome completo)
    init_munis    <- if (!is.null(q0[["muni"]]))    unname(unlist(q0[names(q0) == "muni"]))    else param$defaults$munis
    init_products <- if (!is.null(q0[["product"]])) unname(unlist(q0[names(q0) == "product"])) else param$defaults$products
    kept_munis    <- reactiveVal(init_munis)
    kept_products <- reactiveVal(init_products)

    i18n <- reactive({ param$i18n[[lang()]] })

    # Destaca "Amazônia Legal" em uma categoria própria, no topo, separada dos municípios
    al_label <- "Amazônia Legal"
    with_legal_amazon_group <- function(values, labels, group_label) {
      is_al <- values == al_label
      out <- list()
      if (any(is_al)) {
        out[[al_label]] <- setNames(as.list(values[is_al]), labels[is_al])
      }
      rest <- which(!is_al)
      if (length(rest)) {
        ord <- order(labels[rest])
        out[[group_label]] <- setNames(as.list(values[rest][ord]), labels[rest][ord])
      }
      out
    }

    # Traduz valores `group` (PT) para o idioma ativo
    display_label <- function(values, m, l) {
      map <- param$filter_labels_en[[m]]
      if (l == "en" && length(map) > 0) {
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
    output$plot_desc        <- renderText({ i18n()$plot_desc })
    output$label_var_name   <- renderText({ i18n()$label_var_name })
    output$label_scale_name <- renderText({ i18n()$label_scale_name })
    output$label_prop_name  <- renderText({ i18n()$label_prop_name })
    output$label_swap       <- renderText({ i18n()$label_swap })
    output$btn_fullscreen   <- renderText({ i18n()$btn_fullscreen })
    output$role_y     <- renderText({ paste0(i18n()$role_y_prefix, i18n()[[mode()]]$dim_y) })
    output$role_lines <- renderText({ paste0(i18n()$role_lines_prefix, i18n()[[mode()]]$dim_lines) })
    observeEvent(lang(), {
      updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
    }, ignoreInit = FALSE)

    # Remonta choices/seleção de y e filtro quando orientação ou idioma mudam
    observeEvent(list(mode(), lang()), {
      m <- mode(); l <- lang()
      labs <- i18n()[[m]]
      tbl  <- cfg()$table

      ytab <- tbl[which(tbl$y), ]
      ytab <- ytab[order(ytab$label), ]
      # eixo y = município (modo munic_sh2): "Amazônia Legal" em categoria própria no topo
      y_choices <- if (m == "munic_sh2") {
        append("", with_legal_amazon_group(ytab$var, ytab$label, labs$dim_y))
      } else {
        append("", grouped_list(ytab))
      }

      pts  <- setdiff(unique(cfg()$df$group), " - ")
      pts  <- pts[!is.na(pts)]
      disp <- display_label(pts, m, l)
      ord  <- order(disp)
      # filtro = município (modo sh2_munic): mesma lógica de destaque
      f_choices <- if (m == "sh2_munic") {
        with_legal_amazon_group(pts, disp, labs$dim_lines)
      } else {
        setNames(pts[ord], disp[ord])
      }

      if (m == "munic_sh2") {
        y_sel <- if (length(kept_munis())) kept_munis()[1] else NULL
        f_sel <- kept_products()
      } else {
        y_sel <- if (length(kept_products())) kept_products()[1] else NULL
        f_sel <- kept_munis()
      }

      updateSelectInput(session, "y",
        label = labs$label_y, choices = y_choices, selected = y_sel
      )
      updateSelectizeInput(session, "filter1",
        label = labs$label_filter, choices = f_choices, selected = f_sel
      )
    }, ignoreInit = FALSE)

    # Captura edições do usuário no estado mantido
    observeEvent(input$y, {
      if (input$y == "") return()
      if (mode() == "munic_sh2") {
        kept_munis(unique(c(input$y, kept_munis())))
      } else {
        kept_products(unique(c(input$y, kept_products())))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$filter1, {
      if (mode() == "munic_sh2") {
        kept_products(input$filter1)
      } else {
        kept_munis(input$filter1)
      }
    }, ignoreInit = TRUE)

    # Atualiza a URL
    update_my_queryString <- function() {
      q <- paste0("?lang=", lang(), "&mode=", mode())
      for (mu in kept_munis())    q <- paste0(q, "&muni=", utils::URLencode(mu, reserved = TRUE))
      for (pr in kept_products()) q <- paste0(q, "&product=", utils::URLencode(pr, reserved = TRUE))
      updateQueryString(q, mode = "replace")
    }

    # Título
    output$plot_title <- renderText({
      if (is.null(input$y) || input$y == "") return(" ")
      tbl <- cfg()$table
      y_col <- tbl[which(tbl$var == input$y), ]
      txt <- paste0("", y_col$label)
      if (isTRUE(input$y_option)) txt <- paste0(txt, "*")
      txt
    })
    
    # subtítulo
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
            return(plotly_empty(type = "scatter", mode = "lines"))
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
          # Legenda enxuta (nomes de produto são longos); tooltip mantém o nome completo
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
          # Eixo Y: label fixo
          y_axis_layout <- list(
            title = i18n()$label_y_axis, titlefont = f1, tickfont = f2,
            automargin = FALSE, autorange = TRUE, showgrid = FALSE, zeroline = FALSE
          )
          if (isTRUE(input$ylog) & is.numeric(df_p$y)) y_axis_layout$type <- "log"
          if (isTRUE(input$y_option)) y_axis_layout$title <- paste0(i18n()$label_y_axis, "*")

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
