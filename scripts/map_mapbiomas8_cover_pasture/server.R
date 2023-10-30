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
  df <- readRDS(files$db_file) %>% st_transform(crs = "+init=epsg:4326")

  server <- function(input, output, session) {
    df_reactived <- reactive({
      w <- df %>%
        filter(ano == input$filter1)

      return(w)
    })

    # Cria opções para seleção de datas
    param$filter_choices <- sort(unique(df$ano))

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      selected <- "t_total"
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
    output$map <- renderLeaflet({
      # Define the palette before using it
      if (is.numeric(df_reactived()[[input$x]][1])) {
        pal1 <- pallete_continuous
      } else {
        pal1 <- pallete_discrete
      }
      
      # Compute mean and standard deviation values
      sorted <- sort(c(df[[input$x]]), na.last = FALSE)
      max_val <- min(df[[input$x]], na.rm = TRUE)  # Calculate the maximum value
      
      # Calculate breaks based on your requirements
      breaks_stats <- c(min(df[[input$x]], na.rm = TRUE),
                        unique(c(
                          sorted[as.integer(length(sorted)/10)*1], 
                          sorted[as.integer(length(sorted)/10)*2], 
                          sorted[as.integer(length(sorted)/10)*3], 
                          sorted[as.integer(length(sorted)/10)*4], 
                          sorted[as.integer(length(sorted)/10)*5], 
                          sorted[as.integer(length(sorted)/10)*6],
                          sorted[as.integer(length(sorted)/10)*7],
                          sorted[as.integer(length(sorted)/10)*8],
                          sorted[as.integer(length(sorted)/10)*9]
                        )),
                        max(df[[input$x]], na.rm = TRUE))
      
      # Ensure the last break extends to the maximum value of the data
      if (max_val > tail(breaks_stats, n=1)) {
        breaks_stats <- c(breaks_stats, max_val)
      }
      
      
      # Use colorBin with the breaks
      pal <- colorBin(palette = pal1, bins = breaks_stats, domain = df[[input$x]])
      
      # Tooltip labels
      title_legend <- if(input$x == "pasture_area") "Pasture Area" else "Share of Pasture"
      labels <- paste0(
        "Municipality: ", df_reactived()$municipality, "<br>",
        "State: ", df_reactived()$abbrev_state, "<br>",
        title_legend, ": <b>", format(df_reactived()[[input$x]], 
                                      scientific = FALSE,
                                      digits = 2,
                                      decimal.mark = ",", 
                                      big.mark = "."), "</b>"
      ) %>%
        lapply(htmltools::HTML)
      
      ###definindo limites para os estados da amazonia legal
      
      amazonialegal = st_read("data/shapefiles/Limites_Amazonia_Legal_2022.shx")


      fig <- df_reactived() %>% 
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
      fig <- fig %>%
          addPolylines(data = amazonialegal, color = "black", weight = 3)
      
      return(fig)
    })
    

    # Observa eventos
    observe({
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)
      update_my_inputs()
    })
  }
  error = function(cond) {
    # if an error is encountered, print it for debugging
    print(cond)
  }

  # Retorna objeto server
  server
}

