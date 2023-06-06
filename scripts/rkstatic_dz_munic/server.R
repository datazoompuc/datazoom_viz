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
  df$geometry <- NULL

  server <- function(input, output, session) {

    # Cria opções para seleção de grupos
    param$filter_choices <- sort(unique(df$uf))
    param$filter_choices <- param$filter_choices[which(param$filter_choices != " - ")]


    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {

      # se input está vazio preenche com valor aleatório da lista de colunas
      if (is.null(input$filter1)) {
        updateSelectInput(session,
          "filter1",
          choices = param$filter_choices,
          selected = param$filter_choices
        )
      }
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "x=", input$x,
        "&", "slider=", input$slider[1],
        "&", "slider=", input$slider[2]
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
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["x"]])) {
        # se tem x na url atribui valor ao selecinput x
        updateSelectInput(session, "x",
          choices = param$x_choices,
          selected = query[["x"]]
        )
      }

      selected <- unlist(query[names(query) == "slider"], use.names = FALSE)
      if (!is.null(query[["slider"]])) {
        updateSliderInput(session,
          "slider",
          value = as.Date(selected, "%Y-%m-%d"),
          timeFormat = "%Y"
        )
      }


      selected <- unlist(query[names(query) == "filter1"], use.names = FALSE)
      if (!is.null(query[["filter1"]])) {
        updateSelectInput(session,
          "filter1",
          choices = param$filter_choices,
          selected = selected
        )
      }
    }


    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$x) || input$x == "") {
        text <- param$label_novariable
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- param$table[which(param$table$var == input$x), ]

        text <- paste0(param$rk_of, x_col$label)
      }

      text
    })
    output$plot_subtitle <- renderText({
      text <- " "

      # Monta título a partir de variáveis selecionadas nos inputs
      color_col <- param$table[which(param$table$var == "nm_municip"), ]
      text <- paste0(param$label_legal_amazon)

      text
    })


    # Output gráfico
    output$plot <- renderPlotly({
      update_my_queryString() # atualiza url com parametros dos inputs

      random_inputs() # preenche inputs se estiverem vazios

      fig <- plotly_empty() # inicia figura com gráfico em branco

      tryCatch(
        {

          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(input$x) || input$x == "" ||
            is.null(input$filter1) || length(input$filter1) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          x_col <- param$table[which(param$table$var == input$x), ]
          color_col <- param$table[which(param$table$var == "nm_municip"), ]
          slider_col <- param$table[which(param$table$var == param$slider_def), ]
          text_col <- param$table[which(param$table$var == param$text_def), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]

          # Cria coluna vazia para o ranking
          y_col <- list()
          y_col$var <- "rank"
          y_col$label <- "Ranking"


          df_reactived <- reactive({
            w <- df %>%
              filter(year(ano) >= year(input$slider[1]) &
                year(ano) <= year(input$slider[2])) %>%
              filter(uf %in% input$filter1) %>%
              group_by(cod_ibge, nm_municip, uf, group) %>%
              summarise(
                incremento = sum(incremento, na.rm = TRUE),
                prop_incremento = sum(prop_incremento, na.rm = TRUE)
              )

            return(w)
          })

          df_p <- data.frame(
            df_reactived()[x_col$var],
            NA,
            df_reactived()[color_col$var],
            df_reactived()["group"],
            df_reactived()["group"],
            df_reactived()[id_col$var]
          )

          colnames(df_p) <- c("x", "y", "color", "text", "group", "id")


          # Filtra colunas onde variáveis são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$color)), ]

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Filtra sem grupo
          df_p <- df_p[which(df_p$group != " - "), ]

          # Ordena base por variável de ranking e preenche y
          df_p <- df_p %>%
            mutate(y = order(order(x, decreasing = TRUE))) %>% # rank pela var de x
            arrange(y, .by_group = TRUE) # ordena por rank e ano

          # Se o rank for NA coloca para o final do ranking e zera x
          df_p$y[is.na(df_p$y)] <- max(df_p$y) + 1
          df_p$x[is.na(df_p$x)] <- 0

          # Se a coluna de cor for toda NA, preenche com strings em branco
          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }

          # Deixa somente grupos que tem rank <n em algum momento
          top_n <- 10
          top_groups <- unique(df_p$group[which(df_p$y <= top_n)])
          df_p <- df_p %>% filter(group %in% top_groups)

          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            x_col$label, ": ", df_p$x, "<br>",
            y_col$label, ": ", df_p$y, "<br>",
            color_col$label, ": ", df_p$color
          )

          # Define paleta de cores
          pallete <- pallete_continuous
          if (!is.numeric(df_p$color)) {
            pallete <- pallete_discrete
          }

          # Calcula menor e maior valor de x
          min_x <- min(0, min(df_p$x))
          max_x <- max(0, max(df_p$x))

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
            # marker = list(
            #  opacity = 0.5,
            #  line = list(width = 1, color = 'white')
            # ),
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

          if (!is.numeric(df_p$color)) {
            # adiciona barra sem split para a legenda
            fig_p <- fig_p %>% add_segments(
              hoverinfo = "none",
              showlegend = TRUE,
              x = 0,
              xend = 0,
              y = ~y,
              yend = ~y,
              color = ~color,
              line = list(width = 30),
              opacity = 0.7
            )
          } else {
            fig_p <- fig_p %>% colorbar(title = color_col$label)
          }

          # Layout eixos
          x_axis_layout <- list(
            title = x_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = FALSE,
            range = c(min_x, max_x), # fixa range do x
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

          # Tipo de eixo (se log selecionado)
          # if (input$xlog & is.numeric(df_p$x)) {
          #  x_axis_layout$type <- "log"
          # }

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
            )

          fig <- fig %>% animation_opts(
            1500,
            easing = "linear", redraw = FALSE
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
