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
files$param_script <- "../global/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file <- "dic_en.csv"
files$db_file <- "mapbiomas_cobertura.parquet"
files$shapefile <- "../global/munic_shapefile.rds"
files$legal_amazon <- "../global/legal_amazon_boundary.rds"
files$states_boundary <- "../global/states_boundary.rds"


# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

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

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
