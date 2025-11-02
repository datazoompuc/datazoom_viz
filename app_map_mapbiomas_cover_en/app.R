# Cache
cache_folder <- "cache"
shinyOptions(cache = cachem::cache_disk(cache_folder))

# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)
library(arrow)
library(shinycssloaders)
library(shinyWidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "ui.R"
files$server_script <- "server.R"
files$param_script <- "global/db_params.R"
files$CSS_script <- "global/dza_lumen.css"
files$param_file <- "dic_en.csv"
files$db_file <- "mapbiomas_cobertura.parquet"
files$shapefile <- "global/munic_shapefile.rds"
files$legal_amazon <- "global/legal_amazon_boundary.rds"
files$states_boundary <- "global/states_boundary.rds"


# Carrega scripts
source(files$param_script)


# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "Savanna Formation" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "year" # variável padrão do slider
param$text_def <- "municipality" # variável padrão de texto
param$id_def <- "municipality" # variável padrão de id
param$state <- "state" # coluna de estado

param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Annual land use and land cover in Brazil (Source: MapBiomas)"
#"Cobertura da terra na Amaz\u00f4nia"

param$year_inicio <- 1986
param$year_final <- 2023

#parâmetros específicos no UI
param$label_var_name<- "VARIABLES:"
param$label_x_name<- "Select variable:"
param$label_year<- "Year:"
param$label_title<- "Map of Brazilian municipalities with Legal Amazon outline"
param$label_selected_variable<- "Selected variable:"
param$label_munic_name<- "Municipality: <b>"
param$label_state_name<- "State: <b>"
param$label_measurement_unit<- "Unit: <b>"
param$label_toggle <- "Proportion of municipality area"
param$link<- "https://datazoom.shinyapps.io/app_map_mapbiomas_cover_en/"
# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

#  -------------------------------- Define UI --------------------------------

ui <- div( # div geral
    includeCSS(files$CSS_script), # Incluí script CSS
    tags$style(type = "text/css", 
               # remove o ultimo ano no slider (2018 e 2019 estavam um em cima do outro)
               # remove tracos intermediarios do slider
               # move botao de play para a esquerda e para baixo
               # aumenta tamanho do botao de play
               "
      .irs-grid-text.js-grid-text-10 {display: none;}
      .irs-grid-pol.small {display: none;}
      .slider-animate-container {width: 5%; margin-top: 1px;}
      .slider-animate-button {font-size: 20px;}
    "),
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3, # dimensão da coluna do bootstrap
             class = "menucol",
             
             # muda cor do background
             tags$style('.menucol {
                             background-color: #50A486;
              }',),
             
             # muda cor do botao 
             tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                          background-color: #48968B !important;
                          border-color: #48968B !important;
              }',),
             
             h2(class = "plot_name", param$plot_name),
             p(class = "plot_desc", param$plot_desc),
             hr(),
             p(class = "vars", param$label_var_name),
             div(
               class = "var_selec_group",
               # Seleciona variável do eixo x
               selectInput(
                 inputId = "x",
                 label = param$label_x_name,
                 choices = param$x_choices,
                 selected = param$x_def,
                 width = "100%"
               )
             ),
             tags$style(HTML("
      .switch-label {
        color: white;
      }
    ")),
             
             div(
               style = "margin-top: 10px;",
               materialSwitch(
                 inputId = "yprop",
                 label = tags$span(param$label_toggle, class = "switch-label"),
                 value = TRUE, 
                 status = "info"
                 
                 # checkboxInput(
                 #     inputId = "yprop",
                 #     param$label_toggle,
                 #     value = TRUE,
                 #     width = "100%"
               )
             ),
             # espaço vazio
             div(class = "fakecheckbox", ),
             div(
               class = "var_selec_group",
               # Seleciona variável do eixo de data
               sliderInput(inputId = "filter1",
                           label = param$label_year,
                           min = param$year_inicio,
                           max = param$year_final,
                           value = param$year_final,
                           step = 1,
                           width = "100%",
                           animate = FALSE,
                           sep = "")
             ),
             # espaço vazio
             div(class = "fakecheckbox", ),
             div(
               shiny::actionButton(inputId = 'ab1', label = "Fullscreen", 
                                   icon = icon("expand"), 
                                   class = "btn-primary",
                                   onclick = paste0("window.open('", param$link, "', '_blank')"))
             ),
      ),
      column(9,
             class = "plotcol h-100",
             textOutput("plot_title"),
             textOutput("plot_subtitle"),
             div( # row do gráfico
               class = "plotrow row justify-content-center flex-grow-1 w-100",
               div(
                 class = "plotdiv w-100 h-100",
                 # Map
                 leafletOutput("map", width = "100%", height = "calc(100vh - 150px)") %>% withSpinner(type = 4,
                                                                                                      color = "#41878C")
               )
             )
      )
    ),
  )

# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis
pallete_discrete <- rev(pallete_discrete)
pallete_continuous <- rev(pallete_continuous)


  server <- function(input, output, session) {
  
  
    df <- arrow::open_dataset(files$db_file)
    shapefile <- readr::read_rds(files$shapefile)
    legal_amazon_boundary <- readr::read_rds(files$legal_amazon)
    states_boundary <- readr::read_rds(files$states_boundary)
    
    # Cria opções para seleção de datas com df em lazy loading
    param$filter_choices <- df %>%
      distinct(year) %>%
      collect() %>%
      arrange(year) %>%
      pull(year)
    
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
        text <- "No variable selected"
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- param$table[which(param$table$var == input$x), ]
        text <- paste0(param$label_selected_variable, x_col$label)
      }
      
      text
    })
    
    # Output gráfico
    output$map <- renderLeaflet({
      
      # Define df_reactived aqui, carregando só as colunas necessárias
      df_reactived <- df %>%
        filter(year == input$filter1) %>%
        select(all_of(c(input$x, "area_km2", param$text_def, param$state, "municipality_code"))) %>%
        collect() # acaba o lazy loading
      
      if (input$yprop) {
        df_reactived <- df_reactived %>%
          mutate(!!input$x := .data[[input$x]] / area_km2)
      }
      
      df_reactived <- inner_join(
        shapefile, df_reactived,
        by = "municipality_code"
      )
      
      # random_inputs() #preenche inputs se estiverem vazios
      update_my_queryString() # atualiza url com parametros dos inputs
      
      fig <- leaflet() %>%
        addProviderTiles(provider = "CartoDB.VoyagerNoLabels") %>%
        setView(-58, -7, zoom = 5) # inicia figura com gráfico em branco
      
      # Define paleta de cores
      pal1 <- pallete_continuous
      if (!is.numeric(df_reactived[[input$x]])) {
        pal1 <- pallete_discrete
      }
      
      # Determina a paleta para as legendas
      pal <- colorBin(palette = pal1, 9, domain = df_reactived[[input$x]])
      
      tryCatch(
        {
          
          # Monta mapa
          
          # Monta html do tooltip
          x_col <- param$table[which(param$table$var == input$x), ]
          if (input$yprop) {
            x_col$unidade <- "%"
          }
          
          
          title_legend <- paste0("", x_col[["label"]])
          labels <- paste0(
            param$label_munic_name, df_reactived[[param$text_def]], "</b> <br>",
            param$label_state_name, df_reactived[[param$state]], "</b> <br>",
            x_col[["label"]], ": <b>", format(df_reactived[[input$x]], 
                                              scientific = FALSE,
                                              digits = 2,
                                              decimal.mark = ".", 
                                              big.mark = ","), "</b> <br>",
            param$label_measurement_unit, x_col[["unidade"]], "</b>"
          ) %>%
            lapply(htmltools::HTML)
          
          fig_p <- df_reactived %>% 
            leaflet() %>%
            addProviderTiles(provider = "CartoDB.VoyagerNoLabels") %>%
            setView(-58, -7, zoom = 5) %>%
            addPolygons(
              label = labels,
              stroke = FALSE,
              smoothFactor = .5,
              fillOpacity = 0.7,
              fillColor = ~ pal(df_reactived[[input$x]]),
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
                      values = ~ df_reactived[[input$x]],
                      title = title_legend,
                      opacity = 0.7
            )
          

          
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
    }) %>%
      bindCache(input$x, input$yprop, input$filter1)
    
    # Observa eventos
    observe({
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)
      update_my_inputs()
    })
  }

  
#  --------------------------------  Roda a aplicação Shiny --------------------------------
  
shinyApp(ui = ui, server = server)

