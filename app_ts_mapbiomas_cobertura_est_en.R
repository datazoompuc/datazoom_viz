# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "ts_mapbiomas_cobertura_est/ui.R"
files$server_script <- "ts_mapbiomas_cobertura_est/server.R"
files$param_script <- "ts_mapbiomas_cobertura_est/db_params.R"

files$CSS_script <- "global/dza_lumen.css"

files$param_file <- "ts_mapbiomas_cobertura_est/mapbiomas_cobertura_est_dic_en.csv"
files$db_file <- "ts_mapbiomas_cobertura_est/mapbiomas_cobertura_est.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$x_label <- "Year"  # título do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto (quando mouse em cima)
param$group <- "group" # variável de agrupamento


param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Annual Mapping of Land Use and Coverage in Brazil (Data Source: MAPBIOMAS)"

### Parametros especificos no UI
param$label_var_name <- "VARIABLES:"
param$label_y_name <- "Select variable"
param$label_prop_name <-  "Proportional to starting year"
param$label_prop_muni <- "Proportional to states' areas"
param$label_geo_name <- "States"
param$link <- "https://datazoom.shinyapps.io/app_ts_mapbiomas_cobertura_est_en/"

### Parametros especificos no server
param$subtitle_init <- "per hectare " # expressão titulo


# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)