# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/rk/ui.R"
files$server_script <- "scripts/rk/server.R"
files$param_script <- "scripts/rk/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/mapbiomas_cobertura_munic_dic.csv"
files$db_file <- "data/mapbiomas_cobertura_munic.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) #carrega lista de variáveis e parâmetros
param$x_def <- "" #variável padrão do eixo x
param$y_def <- "" #variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" #variável padrão de cor
param$text_def <- "group" #variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" #variável de agrupamento
param$id_def <- "group" #variável padrão de id

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Mapeamento Anual do Uso e Cobertura da Terra no Brasil"

# Outros parâmetros e configurações

#  --------------------------------  Roda a aplicação Shiny -------------------------------- 
ui <- get_ui(files,param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)