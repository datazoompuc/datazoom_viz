# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_ibge_pnadc_trabalho/ui.R"
files$server_script <- "scripts/ts_ibge_pnadc_trabalho/server.R"
files$param_script <- "scripts/ts_ibge_pnadc_trabalho/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/ibge_pnadc_trabalho_dic.csv"
files$db_file <- "data/ibge_pnadc_trabalho.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "taxa_de_desemprego" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "id" # variável padrão de cor
param$text_def <- "id" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "id" # variável de agrupamento

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Mercado de Trabalho"

# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
