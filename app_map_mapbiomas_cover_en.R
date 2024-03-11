# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/map_mapbiomas_cover/ui.R"
files$server_script <- "scripts/map_mapbiomas_cover/server.R"
files$param_script <- "scripts/map_mapbiomas_cover/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/mapbiomas_cobertura_munic_savana_dic_en.csv"
files$db_file <- "data/mapbiomas_cobertura.rds"
files$legal_amazon <- "data/legal_amazon_boundary.rds"
files$states_boundary <- "data/states_boundary.rds"
files$areas_mun <- "data/area_municipios.rds"


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

param$year_inicio <- 1985
param$year_final <- 2022

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
