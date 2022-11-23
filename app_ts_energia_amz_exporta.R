# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_energia_amz_exporta/ui.R"
files$server_script <- "scripts/ts_energia_amz_exporta/server.R"
files$param_script <- "scripts/ts_energia_amz_exporta/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/energia_amz_exporta_dic.csv"
files$db_file <- "data/energia_amz_exporta.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "ano" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$slider_def <- "" # variável padrão do slider
param$text_def <- "" # variável padrão de texto
param$id_def <- "" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Dados de produção, consumo e consumidores de energia"


# Outros parâmetros e configurações
param$y_choices$`Fonte de dados` <- NULL
param$y_choices[[1]] <- NULL


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
