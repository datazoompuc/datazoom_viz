# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_mapbiomas_cobertura_est/ui.R"
files$server_script <- "scripts/ts_mapbiomas_cobertura_est/server.R"
files$param_script <- "scripts/ts_mapbiomas_cobertura_est/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/mapbiomas_cobertura_est_dic.csv"
files$db_file <- "data/mapbiomas_cobertura_est.rds"

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


param$plot_name <- "Data Zoom Amazonia"
param$plot_desc <- "Mapeamento Anual do Uso e Cobertura da Terra no Brasil"

### Parametros especificos no UI
param$label_var_name <- "VARIÁVEIS:"
param$label_y_name <- "eixo vertical (y)"
param$label_log_name <- "escala log"
param$label_prop_name <-  "proporcional ao ano inicial (*)"
param$label_geo_name <- "Subdivisão geográfica"
param$link <- "https://datazoom.shinyapps.io/app_ts_mapbiomas_cobertura_est/"

### Parametros especificos no server
param$subtitle_init <- "por hectare" # expressão titulo

# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
