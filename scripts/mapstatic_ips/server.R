# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#757575", "#60458c", "#c368b1", "#000098", "#261c4e", "#99b0c8", "#4fdf94", "#00596d", "#007e47", "#c3ff83", "#ffcf48", "#fcff84")
pallete_continuous <- c("#fde725","#dce319", "#b8de29", "#95d840", "#73d055", "#55c667", "#3cbb75", "#29af7f", "#20a387", "#1f968b", "#238a8d", "#287d8e", "#33638d", "#39568c", "#404788", "#453781", "#481567", "#440154") # Viridis inverse

# Fontes

# Funcão para retornar objeto server
get_server <- function(files, param) {

  # Carrega dados
  df <- readRDS(files$db_file)

  server <- function(input, output, session) {
    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      selected <- sample(sample(param$x_choices, 1)[[1]], 1)
      updateSelectInput(session,
        "x",
        choices = param$x_choices,
        selected = selected
      )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "x=", input$x
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
        text <- "Nenhuma vari\u00e1vel selecionada"
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
      if (!is.numeric(df[[input$x]])) {
        pal1 <- pallete_discrete
      }

      # Determina a paleta para as legendas
      pal <- colorBin(palette = pal1, 9, domain = df[[input$x]])

      tryCatch(
        {
          
          # Monta mapa

          # Monta html do tooltip
          x_col <- param$table[which(param$table$var == input$x), ]
          title_legend <- paste0("", x_col$label)
          labels <- paste0(
            param$label_munic_name, "<b>", df$nm_municip, "</b><br>",
            param$label_state, "<b>", df$uf, "</b><br>",
            x_col$label, ": ", "<b>", format(df[[input$x]], scientific = FALSE,
                                             digits = 2,
                                             decimal.mark = ",", 
                                             big.mark = "."), "</b><br>",
            param$label_measurement_unit, "<b>", x_col$unidade, "</b><br>"
          ) %>%
            lapply(htmltools::HTML)

          fig_p <- df %>%
            st_transform(crs = "+init=epsg:4326") %>%
            leaflet() %>%
            addProviderTiles(provider = "CartoDB.VoyagerNoLabels") %>%
            setView(-58, -7, zoom = 5) %>%
            addPolygons(
              label = labels,
              stroke = FALSE,
              smoothFactor = .5,
              fillOpacity = 0.7,
              fillColor = ~ pal(df[[input$x]]),
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
              values = ~ df[[input$x]],
              title = title_legend,
              opacity = 0.7
            )

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
