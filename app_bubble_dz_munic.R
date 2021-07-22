# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/bubble/ui.R"
files$server_script <- "scripts/bubble/server.R"
files$param_script <- "scripts/bubble/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/dz_munic_dic.csv"
files$db_file <- "data/dz_munic.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) #carrega lista de variáveis e parâmetros
param$x_def <- "Desmatado" #variável padrão do eixo x
param$y_def <- "Salario" #variável padrão do eixo y
param$color_def <- "Estado.x" #variável padrão de cor
param$size_def <- "IPS" #variável padrão de tamanho
param$slider_def <- "Ano" #variável padrão do slider
param$text_def <- "Municipio" #variável padrão de texto
param$id_def <- "CodIBGE" #variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Compilação de dados ao nível municipal"

# Outros parâmetros e configurações

#  --------------------------------  Roda a aplicação Shiny -------------------------------- 
ui <- get_ui(files,param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
