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
    
    param$y_choices <- sort(unique(df$time))
    
    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function( ) {
      updateSelectInput(session, 
                        "y", 
                        choices = param$y_choices, 
                        selected = param$y_def
      )
      
      updateSelectInput(session, 
                        "filter1", 
                        choices = param$filter_choices, 
                        selected = sample(param$filter_choices, 1) #2 significa o numero de parametros aleatórios que são escolhidos na geração do gráfico
      )
      
    }
    
    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?","y=",input$y,
        "&","filter=",input$filter1
      )
      
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
    
    # Output titulo do gráfico
    output$plot_title <- renderText({
      text <- "Matriz de Transição - Cobertura e Uso do Solo"
      
      text
    })
    output$plot_subtitle <- renderText({
      # Se algum campo estiver vazio retorna texto vazio
      if(is.null(input$y) || input$y == "") {
        text <- " "
      } else {
        text <-  paste0("por hectare")
      }
      
      text
    })
    
    # Output gráfico
    output$table <- renderTable({
      update_my_queryString()  #atualiza url com parametros dos inputs
      
      tryCatch({
        # Se algum campo estiver vazio retorna gráfico vazio
        if(is.null(input$y) || input$y == "" || 
           is.null(input$filter1) || length(input$filter1) < 1) {
          tab <- data.frame()
          stop()
        }
        
        df_reactived <- reactive({
          w <- df %>%
            filter(time == input$y) %>%
            filter(group == input$filter1) %>% 
            tidyr::pivot_wider(id_cols = from, 
                               names_from = to, 
                               values_from = area) %>% 
            replace(is.na(.), 0) %>% 
            as.data.frame()
          
          rownames(w) <- w$from
          w$from <- NULL
          w[w == 0] <- NA
          
          return(w)
        })
        
        tab <- df_reactived()
      },
      error = function(cond) {
        # se encontrar erro retorna fig em branco
        print("table error")
        tab <- data.frame()
      })
      tab
    }, rownames = TRUE, na = "-")
    
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