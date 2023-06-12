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
    df$geometry <- NULL

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      # se input está vazio preenche com valor aleatório da lista de colunas
      if (input$x == "") {
        updateSelectInput(session, "x",
          choices = param$x_choices,
          selected = sample(param$x_cols$var, 1)
        )
      }

      if (input$y == "") {
        updateSelectInput(session, "y",
          choices = param$y_choices,
          selected = sample(param$y_cols$var, 1)
        )
      }

      if (input$size == "") {
        updateSelectInput(session, "size",
          choices = param$size_choices,
          selected = sample(param$size_cols$var, 1)
        )
      }

      if (input$color == "") {
        updateSelectInput(session, "color",
          choices = param$color_choices,
          selected = sample(param$color_cols$var, 1)
        )
      }
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "x=", input$x,
        "&", "xlog=", input$xlog,
        "&", "y=", input$y,
        "&", "ylog=", input$ylog,
        "&", "size=", input$size,
        "&", "color=", input$color
      )
      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["x"]])) {
        # se tem x na url atribui valor ao selecinput x
        updateSelectInput(session, "x",
          choices = param$x_choices,
          selected = query[["x"]]
        )
      }

      if (!is.null(query[["y"]])) {
        updateSelectInput(session, "y",
          choices = param$y_choices,
          selected = query[["y"]]
        )
      }

      if (!is.null(query[["size"]])) {
        updateSelectInput(session, "size",
          choices = param$size_choices,
          selected = query[["size"]]
        )
      }

      if (!is.null(query[["color"]])) {
        updateSelectInput(session, "color",
          choices = param$color_choices,
          selected = query[["color"]]
        )
      }
      if (!is.null(query[["xlog"]])) {
        updateCheckboxInput(session, "xlog",
          value = (query[["xlog"]] == "TRUE")
        )
      }
      if (!is.null(query[["ylog"]])) {
        updateCheckboxInput(session, "ylog",
          value = (query[["ylog"]] == "TRUE")
        )
      }
    }

    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$x) || input$x == "" ||
        is.null(input$y) || input$y == "") {
        text <- " "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- param$table[which(param$table$var == input$x), ]
        y_col <- param$table[which(param$table$var == input$y), ]

        text <- paste0(x_col$label, " ", param$sep, " ", y_col$label)
      }

      text
    })
    output$plot_subtitle <- renderText({
      text <- " "

      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$color) || input$color == "" ||
        is.null(input$size) || input$size == "") {
        text <- " "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        color_col <- param$table[which(param$table$var == input$color), ]
        size_col <- param$table[which(param$table$var == input$size), ]

        text <- paste0(param$subtitle_init, " ", color_col$label, " ", param$subtitle_sep, 
                       " ", size_col$label)
      }

      text
    })

    # Output gráfico
    output$plot <- renderPlotly({

      # random_inputs() #preenche inputs se estiverem vazios
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco

      tryCatch(
        {

          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(input$x) || input$x == "" ||
            is.null(input$y) || input$y == "" ||
            is.null(input$color) || input$color == "" ||
            is.null(input$size) || input$size == "") {
            fig <- plotly_empty()
            stop()
          }

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          x_col <- param$table[which(param$table$var == input$x), ]
          y_col <- param$table[which(param$table$var == input$y), ]
          color_col <- param$table[which(param$table$var == input$color), ]
          size_col <- param$table[which(param$table$var == input$size), ]
          slider_col <- param$table[which(param$table$var == param$slider_def), ]
          text_col <- param$table[which(param$table$var == param$text_def), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]

          df_p <- data.frame(
            df[x_col$var],
            df[y_col$var],
            df[color_col$var],
            df[size_col$var],
            df[slider_col$var],
            df[text_col$var],
            df[id_col$var]
          )

          colnames(df_p) <- c("x", "y", "color", "size", "slider", "text", "id")

          # Filtra colunas onde x,y e size são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y) & !is.na(df_p$size)), ]

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Se a coluna de cor for toda NA, preenche com strings em branco
          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }

          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            "(", lubridate::year(df_p$slider), ")", "<br><br>",
            x_col$label, ": ", df_p$x, "<br>",
            y_col$label, ": ", df_p$y, "<br>",
            size_col$label, ": ", df_p$size, "<br>",
            color_col$label, ": ", df_p$color
          )

          # Define paleta de cores
          pallete <- pallete_continuous
          if (!is.numeric(df_p$color)) {
            pallete <- pallete_discrete
          }

          # Monta gráfico
          sizes <- c(100, 2000)

          fig_p <- plot_ly(
            df_p,
            type = "scatter",
            mode = "markers",
            x = ~x,
            y = ~y,
            size = ~size,
            color = ~color,
            colors = pallete,
            frame = ~slider %>% lubridate::year(),
            ids = ~id,
            text = ~tooltip,
            hoverinfo = "text",
            sizes = sizes,
            marker = list(
              opacity = 0.5,
              line = list(width = 1, color = "white")
            )
          )

          # Parâmetros animação e slider (se tiver mais de um frame)
          if (length(unique(df_p$slider)) > 1) {
            # Edita slider
            fig_p <- fig_p %>% animation_slider(currentvalue = list(prefix = "Ano: ", font = f1))

            # Botões da animação
            #  edita botão padrão (editar move ele para o updatemenus)
            fig_p <- fig_p %>% animation_button(label = "Play")

            #  sobrescreve updatemenus, adicionando play e pause
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
                      NA, # primeiro arg vazio para play
                      list(
                        mode = "immediate",
                        transition = list(duration = 1500, easing = "linear"),
                        fromcurrent = TRUE,
                        frame = list(redraw = FALSE, duration = 1500)
                      )
                    )
                  ),
                  list(
                    method = "animate",
                    # label = "<U+25FC>",
                    label = "I I",
                    args = list(
                      list(), # primeiro arg lista vazia para pause
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

          # Tipo de eixo (se log selecionado)
          if (input$xlog & is.numeric(df_p$x)) {
            x_axis_layout$type <- "log"
          }
          if (input$ylog & is.numeric(df_p$y)) {
            y_axis_layout$type <- "log"
          }

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
              hoverlabel = tooltip
            ) %>%
            colorbar(title = color_col$label)

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
