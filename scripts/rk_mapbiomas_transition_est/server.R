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
  
   if(param$lang) {
  
       df$to <- df$to %>% str_replace_all(c(" para " = " to ",
                                                                            "Aquacultura" = "Aquaculture",
                                                                              "Mosaico de Agricultura e Pastagem" = "Mosaic of Agriculture and Pasture",
                                                                              "Outros Cultivos Perenes" = "Other Perennial Crops",
                                                                              "Outros Cultivos Perenes" = "Othere Perennial Crops",
                                                                              "Restinga Arborizada" = "Wooded Restinga",
                                                                              "Outras \u00e1reas n\u00e3o vegetadas" = "Other Non Vegetated Area",
                                                                              "Restinga Herb\u00e1cea/Arbustiva" = "Restinga Herbacea/Arbustiva",
                                                                              "Afloramento Rochoso" = "Rocky Outcrop",
                                                                              "Outros Cultivos Tempor\u00e1rios" = "Other Temporary Crops",
                                                                              "Outras Forma\u00e7\u00f5es N\u00e3o Florestais Naturais" = "Other Non Forest Natural Formation",
                                                                              "Rios, Lagos ou Oceanos" = "River, Lake and Ocean",
                                                                              "Outros Cultivos Tempor\u00e1rios" = "Othere Temporary Crops",
                                                                              "Planta\u00e7\u00e3o de Floresta" = "Forest Plantation",
                                                                              "N\u00e3o Observado" = "Non Observed",
                                                                              "Forma\u00e7\u00e3o de Floresta" = "Forest Formation",
                                                                              "Forma\u00e7\u00e3o de Savana" = "Savanna Formation",
                                                                              "P\u00e2ntano" = "Wetland",
                                                                              "Pradaria" = "Grassland",
                                                                              "Infraestrutura Urbana" = "Urban Infrastructure",
                                                                              "Soja" = "Soy Beans",
                                                                              "Mangue" = "Magrove",
                                                                              "Mineira\u00e7\u00e3o" = "Mining",
                                                                              "Praia e Dunas" = "Beaches and Dunes",
                                                                              "Caf\u00e9" = "Coffee",
                                                                              "Cultivos C\u00edtricos" = "Citrus",
                                                                              "Arroz" = "Rice",
                                                                              "Algod\u00e3o" = "Cotton",
                                                                              "Cana-de-a\u00e7\u00facar" = "Sugar Cane",
                                                                              "Pastagem" = "Pasture"))
       
       df$from <- df$from %>% str_replace_all(c(" para " = " to ",
                                            "Aquacultura" = "Aquaculture",
                                            "Mosaico de Agricultura e Pastagem" = "Mosaic of Agriculture and Pasture",
                                            "Outros Cultivos Perenes" = "Other Perennial Crops",
                                            "Outros Cultivos Perenes" = "Othere Perennial Crops",
                                            "Restinga Arborizada" = "Wooded Restinga",
                                            "Outras \u00e1reas n\u00e3o vegetadas" = "Other Non Vegetated Area",
                                            "Restinga Herb\u00e1cea/Arbustiva" = "Restinga Herbacea/Arbustiva",
                                            "Afloramento Rochoso" = "Rocky Outcrop",
                                            "Outros Cultivos Tempor\u00e1rios" = "Other Temporary Crops",
                                            "Outras Forma\u00e7\u00f5es N\u00e3o Florestais Naturais" = "Other Non Forest Natural Formation",
                                            "Rios, Lagos ou Oceanos" = "River, Lake and Ocean",
                                            "Outros Cultivos Tempor\u00e1rios" = "Othere Temporary Crops",
                                            "Planta\u00e7\u00e3o de Floresta" = "Forest Plantation",
                                            "N\u00e3o Observado" = "Non Observed",
                                            "Forma\u00e7\u00e3o de Floresta" = "Forest Formation",
                                            "Forma\u00e7\u00e3o de Savana" = "Savanna Formation",
                                            "P\u00e2ntano" = "Wetland",
                                            "Pradaria" = "Grassland",
                                            "Infraestrutura Urbana" = "Urban Infrastructure",
                                            "Soja" = "Soy Beans",
                                            "Mangue" = "Magrove",
                                            "Mineira\u00e7\u00e3o" = "Mining",
                                            "Praia e Dunas" = "Beaches and Dunes",
                                            "Caf\u00e9" = "Coffee",
                                            "Cultivos C\u00edtricos" = "Citrus",
                                            "Arroz" = "Rice",
                                            "Algod\u00e3o" = "Cotton",
                                            "Cana-de-a\u00e7\u00facar" = "Sugar Cane",
                                            "Pastagem" = "Pasture"))
       
   }
  
  server <- function(input, output, session) {
      
      
      df_reactived <- reactive({
          
          if (input$x_from != "") df <- df %>% filter(from == input$x_from)
          if (input$x_to != "") df <- df %>% filter(to == input$x_to)
    
          return(df)
      })
      
      # Cria opções para seleção das variaveis de transição
      param$x_from_choices <- sort(unique(df$from))
      param$x_to_choices <- sort(unique(df$to))
      
      # Adicionar opcoes no ui
      updateSelectInput(session, "x_from",
                        choices = param$x_from_choices)
      
      updateSelectInput(session, "x_to",
                        choices = param$x_to_choices)
     
      
    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      # se input está vazio preenche com valor aleatório da lista de colunas
      if (input$x_from == "") {
        updateSelectInput(session, "x_from",
          choices = param$x_from_choices,
          selected = sample(param$x_from_choices, 1)
        )
      }

      if (input$x_to == "") {
        updateSelectInput(session, "x_to",
          choices = param$x_to_choices,
          selected = sample(param$x_to_choices, 1)
        )
      }
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "x_from=", input$x_from,
        "&", "x_to=", input$x_to
      )
      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["x_from"]])) {
        # se tem x na url atribui valor ao selecinput x
        updateSelectInput(session, "x_from",
          choices = param$x_from_choices,
          selected = query[["x_from"]]
        )
      }

      if (!is.null(query[["x_to"]])) {
        updateSelectInput(session, "x_to",
          choices = param$x_to_choices,
          selected = query[["x_to"]]
        )
      }
    }


    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$x_from) || input$x_from == "" ||
        is.null(input$x_to) || input$x_to == "") {
          
        text <- param$no_variable
      
        } else if (nrow(df) == 0) {
        
          text <- param$no_observation
          
      } else {
          
          # Monta título a partir de variáveis selecionadas nos inputs
        text <- paste0(param$server1, input$x_from, param$server2, input$x_to)
        
      }

      text
    })
    output$plot_subtitle <- renderText({
      text <- " "

      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$x_from) || input$x_from == "" ||
          is.null(input$x_to) || input$x_to == "" ||
          nrow(df) == 0) {
        text <- " "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        text <- paste0(param$subtitle)
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
            
          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          x_col <- param$table[which(param$table$var == param$x_def), ]
          color_col <- param$table[which(param$table$var == param$color_def), ]
          slider_col <- param$table[which(param$table$var == param$slider_def), ]
          text_col <- param$table[which(param$table$var == param$text_def), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]
          
          # Cria coluna vazia para o ranking
          y_col <- list()
          y_col$var <- "rank"
          y_col$label <- "Ranking"
          x_col$label <- param$x_label
          
          df_p <- data.frame(
           df_reactived()[x_col$var],
            NA,
           df_reactived()[color_col$var],
           df_reactived()[slider_col$var],
           df_reactived()[text_col$var],
           df_reactived()[color_col$var],
           df_reactived()[id_col$var]
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
          top_groups <- unique(df_p$group[which(df_p$y <= top_n)])
          df_p <- df_p %>% filter(group %in% top_groups)

          # Define os parametros do tooltip como sendo os inputs
          param$label_x_from <- paste(input$x_from)
          param$label_x_to <- paste(input$x_to)
          
          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            "(", df_p$slider, ")", "<br><br>",
            param$label_x_from, param$to, param$label_x_to, "<br>",
            param$measur_unit1, ": ", format(df_p$x, scientific = FALSE,
                                      digits = 2,
                                      decimal.mark = ",", 
                                      big.mark = "."),param$measur_unit2 ,"<br>",
            y_col$label, ": ", df_p$y, "<br>"
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
    }) %>%
      bindCache(input$x_from, input$x_to)

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
