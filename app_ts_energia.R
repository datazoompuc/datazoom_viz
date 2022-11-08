# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_energia/ui.R"
files$server_script <- "scripts/ts_energia/server.R"
files$param_script <- "scripts/ts_energia/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/consumo_e_consumidores_energia_dic.csv"
files$db_file <- "data/consumo_e_consumidores_energia.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "Ano" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "Categoria" # variável padrão de cor
param$slider_def <- "" # variável padrão do slider
param$text_def <- "" # variável padrão de texto
param$id_def <- "" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Dados dos Sistemas Isolados de energia"


# Outros parâmetros e configurações
param$y_choices$`Fonte de dados` <- NULL
param$y_choices$IMAZON <- NULL
param$y_choices$`IBGE - Censo 2000` <- NULL
param$y_choices$`IBGE - Censo 2010` <- NULL
param$y_choices[[1]] <- NULL


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
