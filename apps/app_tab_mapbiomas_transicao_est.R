# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/tab/ui.R"
files$server_script <- "../scripts/tab/server.R"
files$param_script <- "../scripts/tab/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file <- "../data/mapbiomas_transicao_est_tab_dic.csv"
files$db_file <- "../data/mapbiomas_transicao_est_tab.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "AM" # variável padrão do eixo x
param$y_def <- "2010 a 2015" # variável padrão do eixo y
param$group <- "group" # variável de agrupamento


param$plot_name <- "Data Zoom Amazonia"
param$plot_desc <- "Transição/mudança de cobertura e uso do solo"

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL
param$y_choices[[1]] <- NULL


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
