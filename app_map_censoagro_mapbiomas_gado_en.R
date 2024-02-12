# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/map_censoagro_mapbiomas_gado_en/ui.R"
files$server_script <- "scripts/map_censoagro_mapbiomas_gado_en/server.R"
files$param_script <- "scripts/map_censoagro_mapbiomas_gado_en/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/censoagro_mapbiomas_gado_dic_en.csv"
files$db_file <- "data/censoagro_mapbiomas_gado.rds"
files$legal_amazon <- "data/legal_amazon_boundary.rds"
files$states_boundary <- "data/states_boundary.rds"


# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "heads of cattle" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$text_def <- "Municipality" # variável padrão de texto
param$id_def <- "Municipality" # variável padrão de id
param$state <- "State" # coluna de estado


param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Heads of cattle and pasture area"

param$year_inicio <- 2017
param$year_final <- 2017

#parâmetros específicos no UI
param$label_var_name<- "Variables:"
param$label_x_name<- "Select variable (y)"
param$label_year<- "Year"
param$label_title<- "Map of the municipalities in Brazil"
param$label_selected_variable<- "Selected variable:"
param$label_munic_name<- "Municipality: <b>"
param$label_state_name<- "State: <b>"
param$label_measurement_unit<- "Measurement unit: <b>"
param$link<- "https://datazoom.shinyapps.io/app_map_mapbiomas_cobertura_e_savana/"
# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)