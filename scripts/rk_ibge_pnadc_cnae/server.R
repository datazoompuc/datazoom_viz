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
        df <- readRDS(files$db_file) %>%
            filter(composicao_demografica != "Todos")
      
        # Função para atualizar url do app com parâmetros dos inputs
        update_my_queryString <- function() {
            q_string <- paste0(
                "?","x=",input$x
            )
            
            for (i in input$filter1) {
                q_string <- paste0(
                    q_string,
                    "&","filter=",i
                )
            }
            
            for (k in input$filter3) {
                q_string <- paste0(
                    q_string,
                    "&","filter3=",k
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
                              selected = c("Amazônia Legal", "Brasil")
            )
            
            updateSelectInput(session, 
                              "filter3", 
                              choices = param$sector_choices, 
                              selected = param$sector_def
            )
            
            #Pega parametros da url e atribui aos selectinputs
            query <- parseQueryString(session$clientData$url_search)
            
            if (!is.null(query[['x']])) {
                updateSelectInput(session,  "x",
                                  choices = param$x_choices,
                                  selected = query[['x']])
            } 
            
            selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
            if (!is.null(query[["filter"]])) {
                updateSelectInput(session,
                                  "filter1",
                                  choices = param$filter_choices,
                                  selected = selected
                )
            }
            
            selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
            if (!is.null(query[["filter"]])) {
                updateSelectInput(session,
                                  "filter3",
                                  choices = param$sector_choices,
                                  selected = selected
                )
            }
        }


    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$x) || input$x == "") {
        text <- param$novar
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- param$table[which(param$table$var == input$x), ]
        
        text <-  paste0(param$title_init, " ", x_col$label)
      }

      text
    })
    output$plot_subtitle <- renderText({
        # Se algum campo estiver vazio retorna texto vazio
        if(is.null(input$x) || input$x == "") {
            text <- " "
        } else {
            text <- paste0(param$subtitle_init)
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
          if (is.null(input$x) || input$x == "") {
            fig <- plotly_empty()
            stop()
          }

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          x_col <- param$table[which(param$table$var == input$x), ]
          color_col <- param$table[which(param$table$var == param$color_def), ]
          slider_col <- param$table[which(param$table$var == param$slider_def), ]
          text_col <- param$table[which(param$table$var == param$text_def), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]

          # Cria coluna vazia para o ranking
          y_col <- list()
          y_col$var <- "rank"
          y_col$label <- "Ranking"

          df_filtered <- df %>%
              dplyr::filter((group %in% input$filter1) &
                                (setor %in% input$filter3))
          
          df_p <- data.frame(
            df_filtered[x_col$var],
            NA,
            df_filtered[color_col$var],
            df_filtered[slider_col$var],
            df_filtered[text_col$var],
            df_filtered[color_col$var],
            df_filtered[id_col$var]
          )

          colnames(df_p) <- c("x", "y", "color", "slider", "text", "group", "id")

          # Filtra colunas onde variáveis são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$color)), ]

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Ordena base por variável de ranking e preenche y
          df_p <- df_p %>%
            group_by(slider) %>% # para cada ano
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
          top_groups <- unique(df_p$color[which(df_p$y <= top_n)])
          df_p <- df_p %>% filter(color %in% top_groups)

          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            "(", df_p$slider, ")", "<br><br>",
            x_col$label, ": ", format(df_p$x, scientific = FALSE,
                                      digits = 2,
                                      decimal.mark = ",", 
                                      big.mark = "."), "<br>",
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
            frame = ~slider,
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
            tickformat = "1",
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
            )

          fig_p <- fig_p %>% animation_opts(
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
    }) %>%
      bindCache(input$x, input$filter1, input$filter3)

    output$deflator_notice_ui <- renderUI({
        last_ano <- max(df$Ano)
        last_tri <- max(df$Trimestre[df$Ano == last_ano])
        tags$p(
            style = "color: rgba(255,255,255,0.7); font-size: 12px; margin-top: 10px; margin-bottom: 4px;",
            paste0("Valores em R$ de ", last_ano, "-T", last_tri)
        )
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
