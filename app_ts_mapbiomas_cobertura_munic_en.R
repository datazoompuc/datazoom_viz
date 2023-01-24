# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_mapbiomas_cobertura_munic/ui.R"
files$server_script <- "scripts/ts_mapbiomas_cobertura_munic/server.R"
files$param_script <- "scripts/ts_mapbiomas_cobertura_munic/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/mapbiomas_cobertura_munic_dic_en.csv"
files$db_file <- "data/mapbiomas_cobertura_munic.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto (quando mouse em cima)
param$group <- "group" # variável de agrupamento


param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Annual Mapping of Land Use and Coverage in Brazil"

### Parametros especificos no UI
param$label_var_name <- "VARIABLES:"
param$label_y_name <- "vertical axis (y)"
param$label_log_name <- "log scale"
param$label_prop_name <-  "proportional to the initial year (*)"
param$label_geo_name <- "Municipalities"
param$link <- "https://datazoom.shinyapps.io/app_ts_mapbiomas_cobertura_munic_en/"

### Parametros especificos no server
param$subtitle_init <- "by Territory " # expressão titulo


# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
