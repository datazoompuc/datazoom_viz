# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# Funcão para retornar objeto server
get_server <- function(files, param) {
  server <- function(input, output, session) {

    # Carrega dados
    df <- readRDS(files$db_file) %>% 
      filter(!is.na(uf))
    
    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      updateSelectInput(session,
        "filter1",
        choices = param$filter_choices,
        selected = c("Amazônia Legal", "Fora da Amazônia Legal") # 1 significa o numero de parametros aleatórios que são escolhidos na geração do gráfico
      )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "ylog=", input$ylog
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
      # Preenche filtro vazio
      updateSelectInput(session,
        "filter1",
        choices = param$filter_choices,
        selected = NULL
      )

      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["ylog"]])) {
        updateCheckboxInput(session, "ylog",
                            value = (query[["ylog"]] == "TRUE")
        )
      }
      
      selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
      if (!is.null(query[["filter"]])) {
        updateSelectInput(session,
                          "filter1",
                          choices = param$filter_choices,
                          selected = selected
        )
      }

      # Se query está vazia, preenche aleatório
      if (is.null(query[["filter"]])) {
        random_inputs() # preenche inputs se estiverem vazios
      }
    }

    # Output titulo do gráfico
    output$plot_title <- renderText({
      
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$filter1)) {
        text <- "Bovino/Hectares de Área de Pastagem: "
      } else {
        # Monta titulo a partir de variáveis selecionadas nos inputs
        text <- "Bovino/Hectares de Área de Pastagem: "
        filt <- paste(sapply(input$filter1, paste, collapse = ", "), 
                      collapse = ", ")
        text <- paste0(text, filt)
      }

      text
    })
    output$plot_subtitle <- renderText({
      
      
      
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$filter1)) {
        text <- " "
      } else {
        text <- paste0("Distribuição dos Municípios")
      }

      text
    })

    # Output gráfico
    output$plot <- renderPlotly({
      
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco
      tryCatch(
        {
          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(input$filter1) || length(input$filter1) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          x_col <- param$table[which(param$table$var == param$x_def), ]
          y_col <- param$table[which(param$table$var == param$y_def), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]
          slider_col <- param$table[which(param$table$var == param$slider_def), ]
          color_col <- param$table[which(param$table$var == param$color_def), ]

          # Filtra dataframe com grupos selecionados
          df_filtered <- df[which(df$uf %in% input$filter1), ]
          
          df_p <- data.frame(
            df_filtered[x_col$var],
            df_filtered[y_col$var],
            df_filtered["uf"],
            df_filtered[slider_col$var]
          )
          colnames(df_p) <- c("x", "y", "group", "slider")
          df_p$text <- df_p$group

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

          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            "Número de Bovino/Hectares de Área de Pastagem", ": ", 
            format(df_p$y, scientific = FALSE,
                                      digits = 2,
                                      decimal.mark = ",", 
                                      big.mark = "."), "<br>"
          )

          # Define paleta de cores
          pallete <- pallete_discrete

          # Monta gráfico
          ### Aplicando log(x+1)
          if (input$ylog) {
            fig_p <- plot_ly(df_p,
                             x = ~log10(y+1),
                             color = ~group,
                             colors = pallete,
                             type = "histogram",
                             frame = ~slider,
                             textposition = "middle right",
                             showlegend = TRUE,
                             # marker = list(
                             #  opacity = 0.5,
                             #  line = list(width = 1, color = 'white')
                             # ),
                             hoverinfo = "text",
                             hovertemplate = "Número de Municípios: %{y}<br>Log(Número de Bovino/Hectares de Área de Pastagem + 1): %{x}"
            )
          } else {
            fig_p <- plot_ly(df_p,
                             x = ~y,
                             color = ~group,
                             colors = pallete,
                             type = "histogram",
                             frame = ~slider,
                             textposition = "middle right",
                             showlegend = TRUE,
                             # marker = list(
                             #  opacity = 0.5,
                             #  line = list(width = 1, color = 'white')
                             # ),
                             hoverinfo = "text",
                             hovertemplate = "Número de Municípios: %{y}<br>Número de Bovino/Hectares de Área de Pastagem: %{x}"
            )
          }
          

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
                    label = "\u25B6",
                    args = list(
                      NA, # primeiro arg vazio para play
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
            title = "Bovinos/Hectares de Área de Pastagem",
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )
          y_axis_layout <- list(
            title = "Número de Municípios",
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
              xaxis = x_axis_layout,
              yaxis = y_axis_layout,
              showlegend = TRUE,
              hoverlabel = tooltip
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
