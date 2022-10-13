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

    browser()

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
         updateSelectInput(session, 
          "y",
          choices = param$y_def,
          selected = param$y_def 
        )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {

      q_string <- paste0(
        "?", "y=", input$y
      )
      
      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["x"]])) {
        # se tem x na url atribui valor ao selecinput x
        updateSelectInput(session, 
          "x",
          choices = param$x_choices,
          selected = query[["x"]]
        )
      }

      if (!is.null(query[["y"]])) {
        updateSelectInput(session, 
          "y",
          choices = param$y_choices,
          selected = query[["y"]]
        )
      }

     # Se query está vazia, preenche aleatório
      if (is.null(query[["y"]])) {
        random_inputs() # preenche inputs se estiverem vazios
      }
    }

    # Output titulo do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$y) || input$y == "") {
        text <- "Variável não selecionada"
      } else {
        # Monta titulo a partir de variáveis selecionadas nos inputs
        y_col <- param$table[which(param$table$var == input$y), ]

        text <- paste0("Ranking de", y_col$label)
      }

      text
    })

    # Output subtitulo do gráfico
    output$plot_subtitle <- renderText({
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$y) || input$y == "") {
        text <- "Subtitulo "
      } else {
        text <- paste0("Subtitulo lala")
      }

      text
    })

    # Output gráfico
    output$plot <- renderPlotly({

      browser()

      update_my_queryString() # atualiza url com parametros dos inputs

      #random_inputs()

      fig <- plotly_empty() # inicia figura com gráfico em branco

      tryCatch(
        {
          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(input$y) || input$y == "") {
            fig <- plotly_empty()
            print("Y variable empty")
            stop()
          }

          browser()

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          y_col <- param$table[which(param$table$var == input$y), ]
          x_col <- param$table[which(param$table$var == param$x_def), ]
          text_col <- param$table[which(param$table$var == param$text_def), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]          

          df_p <- data.frame(
            df[y_col$var],
            df[x_col$var]
          )

          colnames(df_p) <- c("y_variable", "x_variable")
          
          df_p$group <- df$group
          df_p$text <- df$group

          # Filtra colunas onde x,y e size são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$y_variable)), ]

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            print("database empty")
            stop()
          }

          # Se a coluna de cor for toda NA, preenche com strings em branco
          if (all(is.na(df_p$x_variable))) {
            df_p$x_variable <- " "
            print("x variable empty")
          }

          # Define paleta de cores
          pallete <- pallete_discrete

          # Monta gráfico
          fig_p <- plot_ly(
            df_p,            
            type = "bar",
            x = ~x_variable,
            y = ~y_variable,
            colors = pallete,
            hoverlabel = "text"
          )

          # Layout eixos
          y_axis_layout <- list(
            title = y_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
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
