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

    # Carrega dados
    df <- readRDS(files$db_file)

    # Helper: constrói y_choices para um idioma, ordenado alfabeticamente
    build_y_choices <- function(lang_key) {
      tbl    <- param$tables[[lang_key]]
      y_cols <- tbl[which(tbl$y), ]
      choices <- grouped_list(y_cols)
      choices <- lapply(choices, function(grp) {
        if (length(grp) > 1) grp[order(names(grp))] else grp
      })
      append("", choices)
    }

    # Cria opções para seleção de grupos
    all_groups <- sort(unique(df$group))
    all_groups <- all_groups[all_groups != " - "]

    al_choice  <- "Amazônia Legal"
    munic_only <- sort(all_groups[all_groups != al_choice])

    extract_uf   <- function(x) sub(".*\\s+-\\s+([A-Z]{2})$", "\\1", x)
    extract_name <- function(x) sub("\\s+-\\s+[A-Z]{2}$", "", x)

    ufs <- sort(unique(extract_uf(munic_only)))
    param$filter_choices <- c(al_choice, munic_only)
    param$filter_choices_grouped <- c(
      setNames(list(c(setNames(al_choice, al_choice))), al_choice),
      setNames(
        lapply(ufs, function(uf) {
          muns <- munic_only[extract_uf(munic_only) == uf]
          setNames(muns, extract_name(muns))
        }),
        ufs
      )
    )

    # --- LANG TOGGLE ---
    lang <- reactiveVal("pt")
    i18n <- reactive({ param$i18n[[lang()]] })

    observeEvent(input$toggle_lang, {
      lang(ifelse(lang() == "pt", "en", "pt"))
    })

    # Renderiza textos dinâmicos da sidebar
    output$plot_name_ui     <- renderUI({ h2(class = "plot_name", i18n()$plot_name) })
    output$plot_desc_ui     <- renderUI({ p(class  = "plot_desc", i18n()$plot_desc) })
    output$label_var_name   <- renderText({ i18n()$label_var_name })
    output$label_y_name     <- renderText({ i18n()$label_y_name })
    output$label_mun_filter <- renderText({ i18n()$label_mun_filter })
    output$label_scale_name <- renderText({ i18n()$label_scale_name })
    output$label_axis_name  <- renderText({ i18n()$label_axis_name })

    # Atualiza y_choices e label do botão quando o idioma muda
    observeEvent(lang(), {
      current_y <- isolate(input$y)
      updateSelectInput(session, "y",
        choices  = build_y_choices(lang()),
        selected = current_y
      )
      updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
    }, ignoreInit = FALSE)

    # Função para preencher inputs com valores padrão ao iniciar sem URL
    default_inputs <- function() {
      y_ch   <- build_y_choices(isolate(lang()))
      y_vals <- Filter(nzchar, unlist(y_ch, use.names = FALSE))

      updateSelectInput(session, "filter1",
        choices  = param$filter_choices_grouped,
        selected = al_choice
      )
      updateSelectInput(session, "y",
        choices  = y_ch,
        selected = sample(y_vals, 1)
      )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "y=", input$y,
        "&", "lang=", lang(),
        "&", "ylog=", input$ylog,
        "&", "y_option=", input$y_option
      )

      for (i in input$filter1) {
        q_string <- paste0(q_string, "&filter=", i)
      }


      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Preenche filtro vazio
      updateSelectInput(session,
        "filter1",
        choices = param$filter_choices_grouped,
        selected = NULL
      )

      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["lang"]]) && query[["lang"]] %in% c("pt", "en")) {
        lang(query[["lang"]])
      }

      if (!is.null(query[["y"]])) {
        updateSelectInput(session, "y",
          choices  = build_y_choices(isolate(lang())),
          selected = query[["y"]]
        )
      }

      if (!is.null(query[["ylog"]])) {
        updateCheckboxInput(session, "ylog",
          value = (query[["ylog"]] == "TRUE")
        )
      }

      if (!is.null(query[["y_option"]])) {
        updateCheckboxInput(session, "y_option",
          value = (query[["y_option"]] == "TRUE")
        )
      }

      selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
      if (!is.null(query[["filter"]])) {
        updateSelectInput(session,
          "filter1",
          choices = param$filter_choices_grouped,
          selected = selected
        )
      }

      # Se query está vazia, aplica seleção padrão
      if (is.null(query[["filter"]]) && is.null(query[["y"]])) {
        default_inputs()
      }
    }

    # Output titulo do gráfico
    output$plot_title <- renderText({
      if (is.null(input$y) || input$y == "") return(" ")
      tbl   <- param$tables[[lang()]]
      y_col <- tbl[which(tbl$var == input$y), ]
      label <- if (nrow(y_col) > 0) y_col$label else input$y
      if (isTRUE(input$y_option)) paste0(label, "*") else label
    })

    output$plot_subtitle <- renderText({
      if (is.null(input$y) || input$y == "") " " else i18n()$currency
    })

    # Output gráfico
    output$plot <- renderPlotly({
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco
      tryCatch(
        {
          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(input$y) || input$y == "" ||
            is.null(input$filter1) || length(input$filter1) < 1) {
            fig <- plotly_empty()
            stop()
          }

          tbl       <- param$tables[[lang()]]
          x_col     <- tbl[which(tbl$var == param$x_def), ]
          y_col     <- tbl[which(tbl$var == input$y), ]
          color_col <- tbl[which(tbl$var == param$color_def), ]

          df_filtered <- df[which(df$group %in% input$filter1), ]

          df_p <- data.frame(
            df_filtered[x_col$var],
            df_filtered[y_col$var],
            df_filtered[color_col$var]
          )
          colnames(df_p) <- c("x", "y", "color")
          df_p$group <- df_filtered$group
          df_p$text <- df_p$group

          # Filtra colunas onde x,y e size são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y)), ]

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Proporcional ao ano inicial
          measurement <- i18n()$measurement
          if (isTRUE(input$y_option) && is.numeric(df_p$y)) {
            df_p <- df_p %>%
              group_by(group) %>%
              mutate(y = (y / first(y)) * 100) %>%
              ungroup()
            measurement <- ""
          }

          if (all(is.na(df_p$color))) df_p$color <- " "

          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            i18n()$label_y_name, ": ", y_col$label, "<br>",
            x_col$label, ": ", df_p$x, "<br>",
            i18n()$label_value, ": ", measurement, format(df_p$y, scientific = FALSE, 
                                                          digits = 2,
                                                          decimal.mark = ",", 
                                                          big.mark = "."), "<br>"
          )

          fig_p <- plot_ly(df_p,
            x = ~x,
            y = ~y,
            color = ~group,
            type = "scatter",
            mode = "lines",
            text = ~tooltip,
            hovertemplate = ~tooltip
          )

          # Layout eixos
          x_axis_layout <- list(
            title = x_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )
          y_axis_layout <- list(
            title = if (isTRUE(input$y_option)) paste0(i18n()$label_value, "*") else i18n()$label_value,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )

          if (isTRUE(input$ylog) && is.numeric(df_p$y)) y_axis_layout$type <- "log"

          # Aplica layout
          fig_p <- fig_p %>%
            layout(
              font = f1,
              xaxis = x_axis_layout,
              yaxis = y_axis_layout,
              showlegend = TRUE
            )

          #  Configura botões do plotly
          fig_p <- fig_p %>%
            config(
              # toImageButtonOptions = list(format = "svg"),
              displaylogo = FALSE,
              modeBarButtonsToRemove = c(
                "lasso2d",
                "select2d",
                "hoverCompareCartesian"
              )
            )

          fig <- fig_p # retorna a figura do gráfico
        },
        error = function(cond) {
          print(paste("plot error:", conditionMessage(cond)))
          fig <- plotly_empty()
        }
      )
      fig
    })

    # Observa eventos
    observe({
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)
      update_my_inputs()
    })
  }

  # Retorna objeto server
  server
}
