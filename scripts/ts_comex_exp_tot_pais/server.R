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
    
    # Carrega índice de preços anual
    indice <- read.csv(files$aux_file,
                       stringsAsFactors = FALSE)
    
    # Garante tipos e nomes compatíveis com o df principal
    indice$time <- as.integer(indice$CO_ANO)
    indice$indice_anual_base1998 <- as.numeric(indice$indice_anual_base1998)
    indice <- indice[, c("time", "indice_anual_base1998")]

    # Tabela de tradução de países
    paises <- read.csv(files$country_map_file, stringsAsFactors = FALSE)
    country_map <- setNames(paises$en, paises$pt)

    #######
    # --- LANG TOGGLE ---
    
    # Reativo que guarda o idioma atual ("pt" ou "en")
    lang <- reactiveVal("pt")
    
    # Troca o idioma quando o botão é clicado
    observeEvent(input$toggle_lang, {
      lang(ifelse(lang() == "pt", "en", "pt"))
    })
    
    # Atalho para os textos do idioma ativo
    i18n <- reactive({ param$i18n[[lang()]] })

    # df reativo: aplica tradução de países quando EN
    df_plot <- reactive({
      if (lang() == "en") {
        df %>% mutate(group = dplyr::recode(group, !!!country_map))
      } else {
        df
      }
    })

    # Renderiza os textos dinâmicos da sidebar
    output$plot_name_ui  <- renderUI({ h2(class = "plot_name", i18n()$plot_name) })
    output$plot_desc_ui  <- renderUI({ p(class = "plot_desc", i18n()$plot_desc) })
    output$label_var_name      <- renderText({ i18n()$label_var_name })
    output$label_country_filter <- renderText({ i18n()$label_country_filter })
    output$label_deflator      <- renderText({ i18n()$label_deflator })
    output$label_scales        <- renderText({ i18n()$label_scales })
    output$label_scale_name    <- renderText({ i18n()$label_scale_name })
    output$label_axis_name     <- renderText({ i18n()$label_axis_name })
    
    # Atualiza inputs e botões quando o idioma muda
    observeEvent(lang(), {

      # Atualiza choices do filtro de países com nomes traduzidos e mantém seleção
      choices <- sort(unique(df_plot()$group))
      choices <- choices[choices != " - "]

      current <- isolate(input$filter1)
      if (is.null(current) || length(current) == 0) {
        selected <- NULL
      } else if (lang() == "en") {
        selected <- dplyr::recode(current, !!!country_map)
      } else {
        inv_map <- setNames(names(country_map), unname(country_map))
        selected <- dplyr::recode(current, !!!inv_map)
      }
      updateSelectInput(session, "filter1", choices = choices, selected = selected)

      # Atualiza o label dos botões
      updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
    }, ignoreInit = FALSE)


    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      choices <- sort(unique(df_plot()$group))
      choices <- choices[choices != " - "]
      updateSelectInput(session,
        "filter1",
        choices = choices,
        selected = sample(choices, 3) # numero de parametros aleatórios que são escolhidos na geração do gráfico
      )

    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "&", "lang=", lang(),
        "&", "y_option=", param$y_def
      )

      for (i in input$filter1) {
        q_string <- paste0(
          q_string,
          "&", "filter=", i
        )
      }


      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      choices <- sort(unique(df_plot()$group))
      choices <- choices[choices != " - "]

      # Preenche filtro vazio
      updateSelectInput(session,
        "filter1",
        choices = choices,
        selected = NULL
      )

      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["lang"]]) && query[["lang"]] %in% c("pt", "en")) {
        lang(query[["lang"]])
      }

      if (!is.null(query[["ylog"]])) {
        updateCheckboxInput(session, "ylog",
          value = (query[["ylog"]] == "TRUE")
        )
      }



      selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
      if (!is.null(query[["filter"]])) {
        updateSelectInput(session,
          "filter1",
          choices = choices,
          selected = selected
        )
      }

      # Se query está vazia, preenche aleatório
      if (is.null(query[["filter"]]) && is.null(query[["y"]])) {
        random_inputs() # preenche inputs se estiverem vazios
      }
    }

    # Se marcar LOG, desmarca PROPORCIONAL
    observeEvent(input$ylog, ignoreInit = TRUE, {
        if (isTRUE(input$ylog) && isTRUE(input$y_option)) {
            updateCheckboxInput(session, "y_option", value = FALSE)
        }
    })

    # Se marcar PROPORCIONAL, desmarca LOG
    observeEvent(input$y_option, ignoreInit = TRUE, {
        if (isTRUE(input$y_option) && isTRUE(input$ylog)) {
            updateCheckboxInput(session, "ylog", value = FALSE)
        }
    })

    # Output titulo do gráfico
    output$plot_title <- renderText({
      text <- param$plot_title
      
      text <- i18n()$plot_title

      text
    })
    output$plot_subtitle <- renderText({
        if (is.null(param$y_def) || param$y_def == "")
            return("")
        

        if (isTRUE(input$y_option) && isTRUE(input$ydefl)) {
            paste0(i18n()$ylabel_deflator, " ", i18n()$label_prop)

        } else if (isTRUE(input$y_option)) {
            paste0(i18n()$currency, " ", i18n()$label_prop)

        } else if (isTRUE(input$ydefl)) {
            paste0(i18n()$currency, i18n()$subtitle_deflator)
        } else {
            i18n()$currency
        }
    })

    # Output gráfico
    output$plot <- renderPlotly({
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco
      tryCatch(
        {
          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(param$y_def) || param$y_def == "" ||
            is.null(input$filter1) || length(input$filter1) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          # Cria dataframe do gráfico
          tbl       <- param$tables[[lang()]]
          x_col     <- tbl[which(tbl$var == param$x_def), ]
          y_col     <- tbl[which(tbl$var == param$y_def), ]
          id_col    <- tbl[which(tbl$var == param$id_def), ]
          color_col <- tbl[which(tbl$var == param$color_def), ]

          # Filtra dataframe com grupos selecionados
          df_filtered <- df_plot()[which(df_plot()$group %in% input$filter1), ]

          # Decide qual variável vai para o eixo Y:
          #   - nominal (original) quando ydefl == FALSE
          #   - deflacionada quando ydefl == TRUE
          y_var <- y_col$var  # padrão: coluna original

          if (isTRUE(input$ydefl)) {
              # Remove anos sem índice (ex.: 1997)
              df_filtered <- df_filtered[df_filtered$time >= 1998, ]

              # Anexa o índice via match, sem mudar ordem nem número de linhas
              df_filtered$indice_anual_base1998 <- indice$indice_anual_base1998[
                  match(df_filtered$time, indice$time)
              ]

              # Se por algum motivo faltar índice para algum ano, joga fora
              df_filtered <- df_filtered[!is.na(df_filtered$indice_anual_base1998), ]

              # Cria uma coluna nova deflacionada (US$ de 1998)
              df_filtered$y_defl <- df_filtered[[y_col$var]] *
                  (100 / df_filtered$indice_anual_base1998)

              y_var <- "y_defl"
          }

          df_p <- data.frame(
            df_filtered[x_col$var],
            df_filtered[[y_var]],
            df_filtered[color_col$var]
          )
          colnames(df_p) <- c("x", "y", "color")
          df_p$group <- df_filtered$group
          df_p$text <- df_p$group

          if (isTRUE(input$y_option)) {
              # garante ordem por país e ano
              df_p <- df_p[order(df_p$group, df_p$x), ]

              # Proporcional ao ano inicial (índice 100)
              df_p <- df_p %>%
                  group_by(group) %>%
                  mutate(
                      y = 100 * y / first(na.omit(y))
                  ) %>%
                  ungroup()
          }

          # Filtra colunas onde x,y e size são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y)), ]
          

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }


          # Se a coluna de cor for toda NA, preenche com strings em branco
          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }

          measurement_label <- case_when(
          isTRUE(input$y_option) ~ i18n()$label_prop,
          isTRUE(input$ydefl)    ~ i18n()$ylabel_deflator,
          TRUE                   ~ i18n()$measurement
          )


          # Monta html do tooltip
          df_p$tooltip <- paste0(
              "<b>", df_p$text, "</b><br>",
              x_col$label, ": ", df_p$x, "<br>",
              y_col$label, " (", measurement_label, "): ",
              format(df_p$y,
                     scientific   = FALSE,
                     digits       = 2,
                     decimal.mark = ",",
                     big.mark     = "."),
              "<br>"
          )

          # Define paleta de cores
          pallete <- pallete_discrete

          # Monta gráfico
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
            title = y_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )

          if (input$ylog & is.numeric(df_p$y)) {
              y_axis_layout$type <- "log"
          }

          label_defl_suffix <- if (isTRUE(input$ydefl)) paste0(" (", i18n()$ylabel_deflator, ")") else ""

          label_prop_suffix <- if (isTRUE(input$y_option)) paste0(" (", i18n()$label_prop, ")") else ""


          y_axis_layout$title <- paste0(y_col$label, label_defl_suffix, label_prop_suffix)

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
              showlegend = TRUE
            )

          #  Configura botões do plotly
          fig_p <- fig_p %>%
              plotly::config(
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
          # se encontrar erro retorna fig em branco
          print("plot error")
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
