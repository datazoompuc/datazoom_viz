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
      w <- df %>% filter(Ano == "input$date")
      return(w)
    })
    
    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if(is.null(input$x) || input$x == "" ) {
        text <- " "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- param$table[which(param$table$var == input$x), ]
        text <-  paste0(x_col$label)
      }
      
      text
    })
    
    # Output gráfico
    output$map <- renderLeaflet({
      
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
        
        browser()
        
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
                    values = ~ x, 
                    title = "Desmatado titulo", 
                    opacity = 0.7)
        
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
  }
  
  # Retorna objeto server
  server
}