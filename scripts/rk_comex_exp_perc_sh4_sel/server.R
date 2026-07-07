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
  df_raw <- readRDS(files$db_file)

  # UFs e anos disponíveis (calculados uma vez a partir dos dados)
  param_ufs <- sort(unique(df_raw$uf))
  years     <- sort(unique(df_raw$time))

  # Pré-calcula range global do eixo X (para manter escala fixa)
  df_x_all <- df_raw %>%
      dplyr::group_by(time, group, floresta) %>%
      dplyr::summarise(value = sum(value * 100, na.rm = TRUE), .groups = "drop")

  min_x <- min(0, min(df_x_all$value, na.rm = TRUE))
  max_x <- max(0, max(df_x_all$value, na.rm = TRUE))


  server <- function(input, output, session) {

    # ---- Controle de idioma ----
    lang <- reactiveVal("pt")

    observeEvent(input$toggle_lang, {
      lang(ifelse(lang() == "pt", "en", "pt"))
    })

    i18n <- reactive({ param$i18n[[lang()]] })

    # Atualiza UI quando idioma muda
    observeEvent(lang(), {

      # Preserva seleção do filtro de floresta
      prev_lang <- ifelse(lang() == "en", "pt", "en")
      was_forest <- isTRUE(
        isolate(input$forest_filter) == param$i18n[[prev_lang]]$filter_choices[2]
      )
      new_selected_forest <- i18n()$filter_choices[ifelse(was_forest, 2, 1)]

      updateSelectInput(session, "forest_filter",
        label    = i18n()$ui2,
        choices  = i18n()$filter_choices,
        selected = new_selected_forest
      )
      updateSelectInput(session, "uf_filter",
        label   = i18n()$ui5,
        choices = c(i18n()$uf_all, param_ufs),
        selected = i18n()$uf_all
      )
      updateActionButton(session, "toggle_lang",
        label = i18n()$btn_lang
      )
    }, ignoreInit = FALSE)

    # ---- Textos dinâmicos da sidebar ----
    output$plot_name_ui <- renderUI({ h2(class = "plot_name", i18n()$plot_name) })
    output$plot_desc_ui <- renderUI({ p(class = "plot_desc",  i18n()$plot_desc)  })
    output$label_ui1    <- renderText({ i18n()$ui1 })

    # ---- Slider de ano
    output$year_slider <- renderUI({
      sliderInput(
        inputId = "year_filter",
        label   = i18n()$ui4,
        min     = min(years),
        max     = max(years),
        value   = max(years),
        step    = 1,
        sep     = "",
        animate = animationOptions(
          interval    = 2000,
          playButton  = "▶",
          pauseButton = "⏸"
        )
      )
    })

    # ---- Tabela de parâmetros do idioma ativo ----
    active_table <- reactive({ param$tables[[lang()]] })

    # ---- Reactive de dados filtrados ----
    df_reactived <- reactive({

      w <- df_raw

      # aplica língua: usa group_en quando EN
      if (lang() == "en") {
        w <- w %>% dplyr::mutate(group = group_en)
      }

      # trunca labels longos (mantém lab completo para tooltip)
      w <- w %>%
        dplyr::mutate(
          lab   = group,
          group = ifelse(nchar(group) >= 40,
                         paste0(substr(group, 1, 60), "..."),
                         group),
          value = value * 100
        )

      # filtro floresta
      if (!is.null(input$forest_filter) &&
          input$forest_filter == i18n()$filter_choices[2]) {
        w <- w %>% dplyr::filter(floresta)
      }

      # filtro ano
      w <- w %>% dplyr::filter(time == input$year_filter)

      # filtro UF
      if (!is.null(input$uf_filter) &&
          input$uf_filter != i18n()$uf_all) {
        w <- w %>% dplyr::filter(uf == input$uf_filter)
      } else {
        w <- w %>%
          dplyr::group_by(time, group, floresta, lab) %>%
          dplyr::summarise(value = sum(value, na.rm = TRUE), .groups = "drop")
      }

      return(w)
    })


    # Output título do gráfico
    output$plot_title <- renderText({
      if (is.null(input$forest_filter) || input$forest_filter == "") {
        i18n()$server1
      } else {
        i18n()$server2
      }
    })

    output$plot_subtitle <- renderText({
      if (is.null(input$forest_filter) || input$forest_filter == "") {
        " "
      } else {
        paste0(i18n()$server3, " (", input$year_filter, ")")
      }
    })

    # Output gráfico
    output$plot <- renderPlotly({

      updateQueryString(paste0("?lang=", lang()), mode = "replace")

      fig <- plotly_empty()

      tryCatch(
        {
          if (is.null(input$forest_filter) || input$forest_filter == "") {
            fig <- plotly_empty()
            stop()
          }

          tbl      <- active_table()
          x_col    <- tbl[which(tbl$var == "value"), ]
          color_col <- tbl[which(tbl$var == "group"), ]
          id_col   <- tbl[which(tbl$var == param$id_def), ]

          # Cria coluna vazia para o ranking
          y_col <- list(var = "rank", label = "Ranking")

          df <- df_reactived()
          
          df_p <- df %>%
              dplyr::mutate(
                  x     = .data[[x_col$var]],      
                  color = .data[[color_col$var]],  
                  text  = group,
                  id    = .data[[id_col$var]],
                  lab   = lab,
                  y     = NA_real_
              ) %>%
              dplyr::select(x, y, color, text, group, id, lab)
          
          
          # Filtra colunas onde variáveis são NA (não serão exibidas no gráfico de qualquer forma) 
          df_p <- df_p[!is.na(df_p$x) & !is.na(df_p$color), , drop = FALSE]

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco 
          if (nrow(df_p) < 1) { 
              fig <- plotly_empty() 
              stop() 
          }
          
          # Filtra sem grupo 
          df_p <- df_p[which(df_p$group != " - "), ]
         
          # monta base do gráfico com coluna de frame = ano
          df_p <- df_p %>%
              mutate(y = order(order(x, decreasing = TRUE))) %>% # rank pela var de x
              arrange(y) # ordena por rank e ano
          
          # Se o rank for NA coloca para o final do ranking e zera x 
          df_p$y[is.na(df_p$y)] <- max(df_p$y, na.rm = TRUE) + 1
          df_p$x[is.na(df_p$x)] <- 0
          
          
          # Se a coluna de cor for toda NA, preenche com strings em branco 
          if (all(is.na(df_p$color))) { 
              df_p$color <- " " 
              }
          
          
          # top_n global 
          top_n <- 10
          top_groups <- unique(df_p$group[df_p$y <= top_n])
          df_p <- df_p[df_p$group %in% top_groups, , drop = FALSE]


         
          ## tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$lab, "</b><br>",
            "(", input$year_filter, ")", "<br><br>",
            x_col$label, ": ",
            format(df_p$x, scientific = FALSE,
                   digits = 2,
                   decimal.mark = ",",
                   big.mark = "."), " %", "<br>",
            y_col$label, ": ", df_p$y, "<br>",
            i18n()$server4, x_col$unidade, "</b>"
          )
          
          # paleta
          pallete <- pallete_continuous 
          if (!is.numeric(df_p$color)) { 
              pallete <- pallete_discrete 
              }

          # Monta gráfico

          # base do gráfico
          fig_p <- plot_ly(df_p,
            x = ~x,
            y = ~y,
            color = ~color,
            colors = pallete,
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
            color = ~color,
            line = list(width = 30),
            opacity = 0.7
          )

          # adiciona textos
          fig_p <- fig_p %>% add_text(
            x = 0.01 * max_x, # ~x/2,
            text = ~text,
            ids = ~id,
            hoverinfo = "none",
            textfont = f1,
            textposition = "middle right"
          )


          # Layout eixos
          x_axis_layout <- list(
            title = x_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = FALSE,
            range = c(min_x, max_x),
            showgrid = FALSE,
            zeroline = FALSE
          )
          y_axis_layout <- list(
            title = y_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = FALSE,
            showgrid = FALSE,
            zeroline = FALSE,
            dtick = 1,
            tick0 = 1,
            range = c(top_n + 0.5, 0.5), # fixa range do y somente para top 10
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
                  legend = list(title = list(text = color_col$label)),
                  hoverlabel = tooltip
              ) %>%
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
              # se encontrar erro retorna fig em branco
              print("plot error")
              fig <- plotly_empty()
          }
        )
      fig
    })

    # Lê parâmetros da URL na inicialização
    observe({
      query <- parseQueryString(session$clientData$url_search)
      if (!is.null(query[["lang"]]) && query[["lang"]] %in% c("pt", "en")) {
        lang(query[["lang"]])
      }
    })

  }
  server
}
