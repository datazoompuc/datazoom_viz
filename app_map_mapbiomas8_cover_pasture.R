# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)
library(geobr)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/map_mapbiomas8_cover_pasture/ui.R"
files$server_script <- "scripts/map_mapbiomas8_cover_pasture/server.R"
files$param_script <- "scripts/map_mapbiomas8_cover_pasture/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/mapbiomas8_cover_pasture_dic.csv"
files$db_file <- "data/mapbiomas8_cover_pasture.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "pasture_area" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "municipality" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Alterar Descrição"

param$year_inicio <- 2017
param$year_final <- 2022

#parâmetros específicos no UI
param$label_var_name<- "VARI\u00C1VEIS:"
param$label_x_name<- "Seleciona variável (x)"
param$label_year<- "Ano referente"
param$label_title<- "Mapa dos munic\u00edpios da Amaz\u00f4nia Legal"
param$label_selected_variable<- "Vari\u00e1vel selecionada:"
param$label_munic_name<- "Nome do município <b>"
param$label_state_name<- "Estado: <b>"
param$label_measurement_unit<- "Unidade de medida: <b>"
param$link<- "https://datazoom.shinyapps.io/app_map_saude_mortalidade/"
# Outros parâmetros e configurações
#param$x_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
