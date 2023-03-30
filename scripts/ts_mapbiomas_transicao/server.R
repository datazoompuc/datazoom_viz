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

    if(param$lang) {
        
        df$from <- df$from %>%
            str_replace_all( c("Não Observado" = "Non Observed",
                               "Formação de Savana" = "Savanna Formation",
                               "Pradaria" = "Grassland",
                               "Infraestrutura Urbana" = "Urban Infrastructure",
                               "Soja" = "Soy Beans",
                               "Mangue" = "Magrove",
                               "Outras Formações Não Florestais Naturais" = "Other Non Forest Natural Formation",
                               "Mosaico de Agricultura e Pastagem" = "Mosaic of Agriculture and Pasture",
                               "Outras áreas não vegetadas" = "Other Non Vegetated Area",
                               "Salar" = "Salt flat",
                               "Restinga Arborizada" = "Wooded Restinga",
                               "Mineiração" = "Mining",
                               "Café" = "Coffe",
                               "Algodão" = "Cotton",
                               "Formação de Floresta" = "Forest Formation",
                               "Pântano" = "Wetland",
                               "Pastagem" = "Pasture",
                               "Rios, Lagos ou Oceanos" = "River, Lake and Ocean",
                               "Outros Cultivos Temporários" = "Other Temporary Crops",
                               "Plantação de Floresta" = "Forest Plantation",
                               "Cana-de-açúcar" = "Sugar Cane",
                               "Praia e Dunas" = "Beach and Dune",
                               "Aquacultura" = "Aquaculture",
                               "Outros Cultivos Perenes" = "Other Perennial Crops",
                               "Restinga Herbácea/Arbustiva" = "Restinga Herbacea/Arbustiva",
                               "Afloramento Rochoso" = "Rocky outcrop",
                               "Cultivos Cítricos" = "Citrus",
                               "Arroz" = "Rice"))
        df$to <- df$to %>%
            str_replace_all( c("Não Observado" = "Non Observed",
                               "Formação de Savana" = "Savanna Formation",
                               "Pradaria" = "Grassland",
                               "Infraestrutura Urbana" = "Urban Infrastructure",
                               "Soja" = "Soy Beans",
                               "Mangue" = "Magrove",
                               "Outras Formações Não Florestais Naturais" = "Other Non Forest Natural Formation",
                               "Mosaico de Agricultura e Pastagem" = "Mosaic of Agriculture and Pasture",
                               "Outras áreas não vegetadas" = "Other Non Vegetated Area",
                               "Salar" = "Salt flat",
                               "Restinga Arborizada" = "Wooded Restinga",
                               "Mineiração" = "Mining",
                               "Café" = "Coffe",
                               "Algodão" = "Cotton",
                               "Formação de Floresta" = "Forest Formation",
                               "Pântano" = "Wetland",
                               "Pastagem" = "Pasture",
                               "Rios, Lagos ou Oceanos" = "River, Lake and Ocean",
                               "Outros Cultivos Temporários" = "Other Temporary Crops",
                               "Plantação de Floresta" = "Forest Plantation",
                               "Cana-de-açúcar" = "Sugar Cane",
                               "Praia e Dunas" = "Beach and Dune",
                               "Aquacultura" = "Aquaculture",
                               "Outros Cultivos Perenes" = "Other Perennial Crops",
                               "Restinga Herbácea/Arbustiva" = "Restinga Herbacea/Arbustiva",
                               "Afloramento Rochoso" = "Rocky outcrop",
                               "Cultivos Cítricos" = "Citrus",
                               "Arroz" = "Rice"))
        
    }
    
    # Cria opções para seleção de grupos
    param$x_from_choices <- sort(unique(df$from))
    param$x_to_choices <- sort(unique(df$to))
    
    param$filter_choices <- sort(unique(df$group))
    
    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
        
      updateSelectInput(session,
        "x_from",
        choices = param$x_from_choices,
        selected = sample(param$x_from_choices, 1) 
      )

      updateSelectInput(session,
        "x_to",
        choices = param$x_to_choices,
        selected = sample(param$x_to_choices, 1)
      )
      
      updateSelectInput(session,
                          inputId = "filter1",
                          choices = param$filter_choices,
                          selected = sample(param$filter_choices, 2)
      )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "x_from=", input$x_from,
        "&", "x_to=", input$x_to,
        "&", "y_option=", input$y_option
      )

      for (i in input$filter1) {
        q_string <- paste0(
          q_string,
          "&", "filter1=", i
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

      if (!is.null(query[["x_from"]])) {
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

      if (!is.null(query[["y_option"]])) {
        updateCheckboxInput(session, "y_option",
          value = (query[["y_option"]] == "TRUE")
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
      
      # Se query está vazia, preenche aleatório
      if (is.null(query[["filter1"]]) && is.null(query[["x_from"]]) && is.null(query[["x_to"]])) {
        random_inputs() # preenche inputs se estiverem vazios
      }
    }

    # Output titulo do gráfico
    

    # Output gráfico
    output$plot <- renderPlotly({
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco
      tryCatch(
        {
          
            
          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          # Cria dataframe do gráfico
          x_col <- param$table[which(param$table$var == param$x_def), ]
          y_col <- param$table[which(param$table$var == param$y_def), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]
          color_col <- param$table[which(param$table$var == param$color_def), ]
          y_col$label <- param$label_y_name
          # Filtra dataframe com grupos selecionados
          df_filtered <- df %>% 
                            filter(group %in% input$filter1) %>%
                            filter(to == input$x_to) %>%
                            filter(from == input$x_from)
         
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
            
            #Título para quando não há observações
            output$plot_title <- renderText({
                text <- 
                # Se algum campo estiver vazio retorna texto vazio
                if (is.null(input$x_from) || input$x_from == "") {
                    text <- " "
                } else {
                    # Monta titulo a partir do parâmetro pré-definido
                    
                    text <- paste(param$no_observation_title)
                    
                }
                
                text
            })
            #Subtítulo para quando não há observações
            output$plot_subtitle <- renderText({
                
                #Monta subtítulo a partir de variáveis selecionadas e parâmetro pré-definido
                text <- paste(input$x_from, param$to, input$x_to, param$no_observation_subtitle, sep = " ")
                
                text
                
            })
            
            stop()
          } else {
              
              #Título para quando há observações
              output$plot_title <- renderText({
                  text <- " "
                  # Se algum campo estiver vazio retorna texto vazio
                  if (is.null(input$x_from) || input$x_from == "") {
                      text <- " "
                  } else {
                      # Monta titulo a partir de variáveis selecionadas nos inputs
                      
                      text <- paste(input$x_from, param$to, input$x_to, sep = " ")
                      
                  }
                  
                  text
              })
              
              #Subtítulo para quando há observações
              output$plot_subtitle <- renderText({
                  # Se algum campo estiver vazio retorna texto vazio
                  if (is.null(input$x_from) || input$x_from == "") {
                      text <- " "
                  } else {
                      text <- paste(param$subtitle_init)
                  }
                  
                  text
              })
              
          }

          # Alternativa de medida para y
          if (input$y_option & is.numeric(df_p$y)) {
            df_p <- df_p %>%
              group_by(df_p$group) %>%
              mutate(
                aux1 = first(y),
                y_option = (y / aux1) * 100
              )
            df_p$y <- df_p$y_option
          }

          # Se a coluna de cor for toda NA, preenche com strings em branco
          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }

          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            x_col$label, ": ", df_p$x, "<br>",
            y_col$label, ": ", df_p$y, param$measur_unit2 <- "m<sup>2</sup>"  ,"<br>"
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
            hoverinfo = "text"
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

          if (input$y_option) {
            y_axis_layout$title <- paste0(y_col$label, "*")
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
