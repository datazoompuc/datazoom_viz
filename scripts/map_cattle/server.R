# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis
pallete_discrete <- rev(pallete_discrete)
pallete_continuous <- rev(pallete_continuous)

# Fontes

# Funcão para retornar objeto server
get_server <- function(files, param) {

  # Carrega dados
  library(sf)
  
  library(sf)
  df <- readRDS(files$db_file)
  
  areas_mun <- readr::read_rds(files$areas_mun)
  
  # adding area of each municipality
  df <- df %>%
    left_join(areas_mun, by = "municipality_code")
  
  micro <- geobr::lookup_muni("all") %>%
      select("municipality_code" = code_muni, code_micro, name_micro)

  server <- function(input, output, session) {
    df_reactived <- reactive({
      w <- df

      
      # quando e escolhida a caixinha de proporcao,
      # input$yprop se torna TRUE.
      # nesse caso, modifico o data frame para dividir pela area
      # do municipio
      # if (input$yprop ) {
      #   w[[input$x]] <- w[[input$x]]/w[["area_km2"]]
      # }
      
      if (input$yprop) {
        if(input$x=="Heads of Cattle / Pasture"){
          w[[input$x]] <- NA
        }else{
          w[[input$x]] <- w[[input$x]]/w[["area_km2"]]
        }

      }
      
      return(w)
    })

    # Cria opções para seleção de datas
    param$filter_choices <- sort(unique(df$year))

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      selected <- param$x_def
      updateSelectInput(session,
        "x",
        choices = param$x_choices,
        selected = selected
      )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "x=", input$x,
        "&", "prop=", input$yprop,
        "&", "filter=", input$filter1
      )

      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      # Preenche filtro vazio
      if (!is.null(query[["x"]])) {
        # se tem x na url atribui valor ao selecinput x
        updateSelectInput(session, "x",
          choices = param$x_choices,
          selected = query[["x"]]
        )
      }

      selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
      updateSelectizeInput(session,
        "filter1",
        choices = param$filter_choices,
        selected = selected
      )

      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      # Se query está vazia, preenche aleatório
      if (is.null(query[["filter"]]) && is.null(query[["x"]])) {
        random_inputs() # preenche inputs se estiverem vazios
      }
    }

    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$x) || input$x == "") {
        text <- " "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- param$table[which(param$table$var == input$x), ]
        text <- param$label_title
      }

      text
    })
    output$plot_subtitle <- renderText({
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$x) || input$x == "") {
        text <- "Nenhuma variável selecionada"
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- param$table[which(param$table$var == input$x), ]
        text <- paste0(param$label_selected_variable, x_col$label)
      }

      text
    })

    # Output gráfico
    output$map <- renderLeaflet({

      # random_inputs() #preenche inputs se estiverem vazios
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- leaflet() %>%
        addProviderTiles(provider = "CartoDB.VoyagerNoLabels") %>%
        setView(-58, -7, zoom = 5) # inicia figura com gráfico em branco

      # Define paleta de cores
      pal1 <- pallete_continuous
      if (!is.numeric(df_reactived()[[input$x]])) {
        pal1 <- pallete_discrete
      }

      # Compute mean and standard deviation values
      sorted <- sort(c(df[[input$x]]), na.last = FALSE)
      max_val <- min(df[[input$x]], na.rm = TRUE)  # Calculate the maximum value
      
      # Calculate breaks based on your requirements
      breaks_stats <- c(min(df[[input$x]], na.rm = TRUE),
                        sorted[as.integer(length(sorted)/10)*1], 
                        sorted[as.integer(length(sorted)/10)*2], 
                        sorted[as.integer(length(sorted)/10)*3], 
                        sorted[as.integer(length(sorted)/10)*4], 
                        sorted[as.integer(length(sorted)/10)*5], 
                        sorted[as.integer(length(sorted)/10)*6],
                        sorted[as.integer(length(sorted)/10)*7],
                        sorted[as.integer(length(sorted)/10)*8],
                        sorted[as.integer(length(sorted)/10)*9],
                        max(df[[input$x]], na.rm = TRUE))
      
      # Ensure the last break extends to the maximum value of the data
      if (max_val > tail(breaks_stats, n=1)) {
          breaks_stats <- c(breaks_stats, max_val)
      }
      
      # Use colorBin with the breaks
          if (input$x == "Heads of Cattle / Pasture"){
              pal <- colorBin(palette = pal1, bins = breaks_stats, domain = df_reactived()[[input$x]])
          }
          else {
              pal <- colorBin(palette = pal1, 9, domain = df_reactived()[[input$x]])
          }
      
    

      tryCatch(
        {
          
          # Monta mapa

          # Monta html do tooltip
          # x_col <- reactive(
          #   {
          #     col <- param$table[which(param$table$var == input$x), ]
          #     
          #     # mudar a unidade quanto se escolhe proporcao
          #     if (input$yprop) {
          #       col$unidade <- "%"
          #     }
          #     
          #     return(col)
          #   }
          # )
          x_col <- param$table[which(param$table$var == input$x), ]
          
          if (input$yprop) {
            x_col$unidade <- "%"
              }
          
          
          title_legend <- paste0("", x_col$label)
          #title_legend <- paste0("", x_col()[["label"]])
          
          labels <- paste0(
            param$label_munic_name, df_reactived()$municipality_name, "</b> <br>",
            param$label_state_name, df_reactived()$state_name, "</b> <br>",
            x_col$label, ": <b>", format(df_reactived()[[input$x]], 
                                         scientific = FALSE,
                                         digits = 2,
                                         decimal.mark = ",", 
                                         big.mark = "."), "</b> <br>",
            param$label_measurement_unit, x_col$unidade, "</b>"
          ) %>%
            lapply(htmltools::HTML)

          fig_p <- df_reactived() %>% 
            leaflet() %>%
            addProviderTiles(provider = "CartoDB.VoyagerNoLabels") %>%
            setView(-58, -7, zoom = 5) %>%
            addPolygons(
              label = labels,
              stroke = FALSE,
              smoothFactor = .5,
              fillOpacity = 0.7,
              fillColor = ~ pal(df_reactived()[[input$x]]),
              highlightOptions = highlightOptions(
                weight = 5,
                fillOpacity = 1,
                color = "black",
                opacity = 1,
                bringToFront = TRUE
              )
            ) %>%
            addLegend("bottomright",
              pal = pal,
              values = ~ df_reactived()[[input$x]],
              title = title_legend,
              opacity = 0.7
            )

          legal_amazon_boundary <- readr::read_rds(files$legal_amazon)
          
          states_boundary <- readr::read_rds(files$states_boundary)
          
          fig_p <- fig_p %>%
              addPolylines(data = states_boundary, color = "grey", weight = 1) %>%
              addPolylines(data = legal_amazon_boundary, color = "black", weight = 2)
          
          
          fig <- fig_p # retorna a figura do gráfico
        },
        error = function(cond) {
          # se encontrar erro retorna fig em branco
          print("Plot error in tryCatch environment")
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
