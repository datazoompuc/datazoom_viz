# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(lubridate)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/bar/ui.R"
files$server_script <- "scripts/bar/server.R"
files$param_script <- "scripts/bar/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/dz_varias_amazonias_cross_section_dic.csv"
files$db_file <- "data/dz_varias_amazonias_cross_section.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "front_2020_label" # variável padrão do eixo x
param$y_def <- "desmatado" # variável padrão do eixo y
param$color_def <- "front_2020_label" # variável padrão de cor
param$text_def <- "front_2020_label" # variável padrão de texto (quando mouse em cima)
param$group <- "front_2020_label" # variável de agrupamento


param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Diferença entre várias amaz\u00f4nias em indicadores mais recentes"

# Outros parâmetros e configurações

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
