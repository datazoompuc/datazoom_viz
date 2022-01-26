# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_comex_exp_pais_sec/ui.R"
files$server_script <- "scripts/ts_comex_exp_pais_sec/server.R"
files$param_script <- "scripts/ts_comex_exp_pais_sec/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/comex_exp_pais_sec_dic.csv"
files$db_file <- "data/comex_exp_pais_sec.rds"

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


param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Com\u00e9rcio exterior na Amaz\u00f4nia (COMEX): Valor da exporta\u00e7\u00e3o de produtos por  pa\u00eds de destino"

# Outros parâmetros e configurações


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
