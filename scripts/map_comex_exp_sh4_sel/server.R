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
  df <- readRDS(files$db_file) %>% 
    st_transform(crs = "+init=epsg:4326")

  server <- function(input, output, session) {
    df_reactived <- reactive({
      w <- df %>%
        filter(time == input$filter1)

      if (input$x == "Produtos Compativeis com a Floresta") {
          w <- w %>% 
            filter(floresta)
      } else {
        w <- w %>% 
          filter(!floresta)
      }
      
      return(w)
    })

    # Cria opções para seleção de datas
    param$filter_choices <- sort(unique(df$time))

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      updateSelectizeInput(session,
                           "filter1",
                           choices = param$filter_choices,
                           selected = param$year_final
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
      selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
      updateSelectizeInput(session,
        "filter1",
        choices = param$filter_choices,
        selected = selected
      )

      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      # Se query está vazia, preenche aleatório
      if (is.null(query[["filter"]])) {
        random_inputs() # preenche inputs se estiverem vazios
      }
    }

    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$filter1) || input$filter1 == "") {
        text <- " "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        text <- paste0("Mapa dos municípios da Amazônia Legal")
      }

      text
    })
    output$plot_subtitle <- renderText({
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$filter1) || input$filter1 == "") {
        text <- "Nenhuma variável selecionada"
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        text <- paste0("Principal produto exportado: ", input$x)
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
      if (!is.numeric(df_reactived()[["nome_sh2"]])) {
        pal1 <- pallete_discrete
      }

      # Determina a paleta para as legendas
      pal <- colorFactor(palette = pal1, domain = df[["nome_sh2"]])

      tryCatch(
        {
          
          # Monta mapa
          
          # Monta html do tooltip
          x_col <- param$table[which(param$table$var == "produto_principal"), ]
          title_legend <- paste0("", x_col$label)
          labels <- paste0(
            "Nome do município: <b>", df_reactived()$nm_municip, "</b> <br>",
            "Estado: <b>", df_reactived()$uf, "</b> <br>",
            x_col$label, ": <b>", df_reactived()[["produto_principal"]], "</b> <br>",
            "Valor", ": ", format(df_reactived()$maximo_produto, scientific = FALSE,
                                  digits = 2,
                                  decimal.mark = ",", 
                                  big.mark = "."), "<br>",
            "Unidade de medida: <b>", "% das exportações do produto vindas da Amazônia no ano", "</b>"
          ) %>%
            lapply(htmltools::HTML)

          fig_p <- df_reactived() %>% 
            leaflet() %>%
            addProviderTiles(provider = "CartoDB.VoyagerNoLabels") %>%
            setView(-58, -7, zoom = 5) %>%
            addPolygons(
              data = df_reactived(),
              label = labels,
              stroke = FALSE,
              smoothFactor = .5,
              fillOpacity = 0.7,
              fillColor = ~ pal(df_reactived()[["nome_sh2"]]),
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
              values = ~ df_reactived()[["nome_sh2"]],
              title = "Categoria do Principal Produto",
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
