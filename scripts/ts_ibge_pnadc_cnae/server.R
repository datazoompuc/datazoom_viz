# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84","#ffcf48" ,"#c3ff83","#007e47","#00596d","#4fdf94","#99b0c8","#261c4e","#000098","#c368b1","#60458c","#757575")
pallete_continuous <- c("#440154","#481567" ,"#453781","#404788","#39568c","#33638d","#287d8e","#238a8d","#1f968b","#20a387","#29af7f","#3cbb75","#55c667","#73d055","#95d840","#b8de29","#dce319","#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# Funcão para retornar objeto server
get_server <- function(files, param) {
  server <- function(input, output, session) {
    
    # Carrega dados
    df <- readRDS(files$db_file)

    # Cria opções para seleção de grupos
    param$filter_choices <- sort(unique(df$group))
    param$filter_choices <- param$filter_choices[which(param$filter_choices != " - ")]
    
    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function( ) {
      updateSelectInput(session, 
                        "filter1", 
                        choices = param$filter_choices, 
                        selected = sample(param$filter_choices,2) #2 significa o numero de parametros aleatórios que são escolhidos na geração do gráfico
      )
      
      selected <- sample(sample(param$y_choices,1)[[1]],1)
      updateSelectInput(session, 
                        "y", 
                        choices = param$y_choices, 
                        selected = selected
      )
    }
    
    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?","y=",input$y,
        "&","ylog=",input$ylog
      )
      
      for (i in input$filter1) {
        q_string <- paste0(
          q_string,
          "&","filter=",i
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
      
      #Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)
      
      if (!is.null(query[['y']])) {
        updateSelectInput(session,  "y",
                          choices = param$y_choices,
                          selected = query[['y']])
      } 
      
      if (!is.null(query[['ylog']])) {
        updateCheckboxInput(session, "ylog",
                            value = (query[['ylog']] == "TRUE"))
      }
      
      selected <- unlist(query[names(query) == "filter"], use.names=FALSE)
      if (!is.null(query[['filter']])) {
        updateSelectInput(session, 
                          "filter1", 
                          choices = param$filter_choices,
                          selected = selected
        )
      }
      
      # Se query está vazia, preenche aleatório
      if (is.null(query[['filter']]) && is.null(query[['y']]) ) {
        random_inputs() #preenche inputs se estiverem vazios
      }
      
    }
    
    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if(is.null(input$y) || input$y == "") {
        text <- " "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        y_col <- param$table[which(param$table$var == input$y), ]
        
        text <-  paste0("Variação trimestral de ", y_col$label)
      }
      
      text
    })
    output$plot_subtitle <- renderText({
      # Se algum campo estiver vazio retorna texto vazio
      if(is.null(input$y) || input$y == "") {
        text <- " "
      } else {
        text <-  paste0("por Atividade econômica")
      }
      
      text
    })
    
    # Output gráfico
    output$plot <- renderPlotly({
      update_my_queryString()  #atualiza url com parametros dos inputs
      
      fig <- plotly_empty() #inicia figura com gráfico em branco
      tryCatch({
        # Se algum campo estiver vazio retorna gráfico vazio
        if(is.null(input$y) || input$y == "" || 
           is.null(input$filter1) || length(input$filter1) < 1) {
          fig <- plotly_empty()
          stop()
        }
        
        #Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
        # Cria dataframe do gráfico
        x_col <- param$table[which(param$table$var == param$x_def),]
        y_col <- param$table[which(param$table$var == input$y),]
        id_col <- param$table[which(param$table$var == param$id_def), ]
        color_col <- param$table[which(param$table$var == param$color_def), ]
        
        # Filtra dataframe com grupos selecionados
        df_filtered <- df[which(df$group %in% input$filter1),]
        
        df_p <- data.frame(df_filtered[x_col$var],
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
        
        # Se a coluna de cor for toda NA, preenche com strings em branco
        if (all(is.na(df_p$color))) {
          df_p$color <- " "
        }
        
        # Monta html do tooltip
        df_p$tooltip <- paste0(
          "<b>",df_p$text,"</b><br>",
          x_col$label,": ",df_p$x,"<br>",
          y_col$label,": ",df_p$y,"<br>"
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
                         text = ~tooltip
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
            #toImageButtonOptions = list(format = "svg"),
            displaylogo = FALSE,
            modeBarButtonsToRemove = c(
              "toImage",
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
      })
      fig
    })
    
    # Observa eventos
    observe({
      #Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)
      update_my_inputs()
    })
  }
  
  # Retorna objeto server
  server
}