# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/map_cattle/ui.R"
files$server_script <- "scripts/map_cattle/server.R"
files$param_script <- "scripts/map_cattle/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/censoagro_mapbiomas_gado_dic.csv"
files$db_file <- "data/censoagro_mapbiomas_gado.rds"
files$legal_amazon <- "data/legal_amazon_boundary.rds"
files$states_boundary <- "data/states_boundary.rds"
files$areas_mun <- "data/area_municipios.rds"


# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # car
param$y_def <- "Heads of Cattle" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$text_def <- "Municipality" # variável padrão de texto
param$id_def <- "Municipality" # variável padrão de id
param$state <- "State" # coluna de estado


param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Cabe\u00e7as de Gado e \u00c1rea de Pastagem"

param$year_inicio <- 2017
param$year_final <- 2017

#parâmetros específicos no UI
param$label_var_name<- "VARI\u00C1VEIS:"
param$label_x_name<- "Vari\u00e1vel Selecionada: "
param$label_year<- "Ano"
param$label_title<- "Mapa dos munic\u00edpios do Brasil com contorno da Amaz\u00f4nia Legal"
param$label_selected_variable<- "Vari\u00e1vel selecionada:"
param$label_munic_name<- "Munic\u00edpio: <b>"
param$label_state_name<- "Estado: <b>"
param$label_measurement_unit<- "Unidade de medida: <b>"
param$label_toggle <- "Propor\u00e7\u00e3o da \u00e1rea dos munic\u00edpios"
param$warning_prop <-"Atenção: Esta opção não é valida, no lugar estamos mostrando Gado/ \u00c1rea de Pastagem."
param$warning_prop_label <-"Propor\u00e7\u00e3o"

param$link<- "https://datazoom.shinyapps.io/app_map_cattle/"
# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)