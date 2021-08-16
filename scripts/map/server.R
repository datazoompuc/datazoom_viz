# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84","#ffcf48" ,"#c3ff83","#007e47","#00596d","#4fdf94","#99b0c8","#261c4e","#000098","#c368b1","#60458c","#757575")
pallete_continuous <- c("#440154","#481567" ,"#453781","#404788","#39568c","#33638d","#287d8e","#238a8d","#1f968b","#20a387","#29af7f","#3cbb75","#55c667","#73d055","#95d840","#b8de29","#dce319","#fde725") # Viridis

# Fontes

# Funcão para retornar objeto server
get_server <- function(files, param) {
  server <- function(input, output, session) {
    
    # Carrega dados
    df <- readRDS(files$db_file)
    
    df_fixed_in_time <- reactive({
      w <- df %>% filter(Ano == input$filter1)
      return(w)
    })
    
    # Cria opções para seleção de datas
    param$filter_choices <- sort(unique(df$Ano))

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function( ) {
      updateSelectInput(session, 
                        "filter1", 
                        choices = param$filter_choices, 
                        selected = sample(param$filter_choices,1) #1 significa o numero de parametros aleatórios que são escolhidos na geração do gráfico
      )
      updateSelectInput(session, 
                        "x", 
                        choices = param$x_choices, 
                        selected = sample(param$x_choices,1)
      )
    }
    
    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?","x=",input$x,
        "&","filter=",input$filter1
        )
      
      updateQueryString(q_string, mode = "replace")
    }
    
    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      #Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)
      
      # Preenche filtro vazio
      if (!is.null(query[['x']])) {
        # se tem x na url atribui valor ao selecinput x
        updateSelectInput(session, "x",
                          choices = param$x_choices,
                          selected = query[['x']])
      }
      
      selected <- unlist(query[names(query) == "filter"], use.names=FALSE)
      updateSelectizeInput(session, 
                        "filter1", 
                        choices = param$filter_choices,
                        selected = selected
      )
      
      #Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)
      
      # Se query está vazia, preenche aleatório
      if (is.null(query[['filter']]) && is.null(query[['x']]) ) {
        random_inputs() #preenche inputs se estiverem vazios
      }
      
    }    
    
    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if(is.null(input$x) || input$x == "") {
        text <- " errei aqui "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- param$table[which(param$table$var == input$x), ]
        text <-  paste0("Variação trimestral de ", x_col$label, "no ano de :")
      }
      
      text
    })
    output$plot_subtitle <- renderText({
      # Se algum campo estiver vazio retorna texto vazio
      if(is.null(input$x) || input$x == "") {
        text <- " problema aqui"
      } else {
        text <-  paste0("por Atividade econômica")
      }
      
      text
    })    
    
    # Output gráfico
    output$map <- renderLeaflet({
      
      #random_inputs() #preenche inputs se estiverem vazios
      update_my_queryString()  #atualiza url com parametros dos inputs
      
      fig <- leaflet() %>%
        addProviderTiles(provider = "Stamen.Watercolor") %>%
        setView(-58, -7, zoom = 5) #inicia figura com gráfico em branco
      
      tryCatch({
        # Define paleta de cores
        pal1 <- pallete_continuous
        if(!is.numeric(df$x)){
          pal1 <- pallete_discrete
        }
        
        # Monta mapa
        
        pal <- colorBin(palette = pal1, 9, domain = df$x)
        
        # Monta html do tooltip
        labels <- paste0("qwer ") %>% 
          lapply(htmltools::HTML)

        fig_p <- df_fixed_in_time() %>%  
          st_transform(crs = "+init=epsg:4326") %>%
          leaflet() %>%
          addProviderTiles(provider = "Stamen.Watercolor") %>%
          setView(-58, -7, zoom = 5) %>%
          addPolygons(label = labels, 
                      stroke = FALSE, 
                      smoothFactor = .5, 
                      fillOpacity = 0.7,
                      fillColor = ~pal(df_fixed_in_time()$x),
                      highlightOptions = highlightOptions(weight = 5, 
                                                          fillOpacity = 1, 
                                                          color = "black", 
                                                          opacity = 1, 
                                                          bringToFront = TRUE)) %>%
          addLegend("bottomright", 
                    pal = pal, 
                    values = ~x, 
                    title = "Desmatado titulo", 
                    opacity = 0.7)
        
        fig <- fig_p # retorna a figura do gráfico
      },
      error = function(cond) {
        # se encontrar erro retorna fig em branco
        print("plot error 03")
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