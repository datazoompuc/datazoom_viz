# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/map_dz_munic_cempre/ui.R"
files$server_script <- "scripts/map_dz_munic_cempre/server.R"
files$param_script <- "scripts/map_dz_munic_cempre/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/dz_munic_dic_en.csv"
files$db_file <- "data/dz_munic_simplified.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "desmatado" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "nm_municip" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Data compilation at municipality level (CEMPRE)"
param$app <- "IBGE - CEMPRE"

param$year_inicio <- 2006
param$year_final <- 2019

# Outros parâmetros e configurações
param$x_choices <- param$x_choices[param$app]


param$label_var_name <- "VARIABLES:"
param$label_x_name <- "Select variable (x)"
param$label_data_axis_name <- "Reference year"
param$link <- "https://datazoom.shinyapps.io/app_map_dz_munic_cempre_en/"
param$title <- "Legal Amazon municipality map"
param$empty <- "No variable was selected"
param$selected_variable <- "Selected variable: "
param$label_1 <- "Municipality name: "
param$label_2 <- "State: "
param$label_3 <- "Measurement unit: "  


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)