# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_sigmine/ui.R"
files$server_script <- "../scripts/ts_sigmine/server.R"
files$param_script <- "../scripts/ts_sigmine/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file <- "../data/sigmine_munic_en_dic.csv"
files$db_file <- "../data/sigmine_munic.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) #carrega lista de variáveis e parâmetros
param$x_def <- "time" #variável padrão do eixo x
param$y_def <- "area" #variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" #variável padrão de cor
param$text_def <- "group" #variável padrão de texto (quando mouse em cima)
param$group <- "group" #variável de agrupamento


param$plot_name <- "Data Zoom Amazonia"
param$plot_desc <- "Transition/change in coverage and soil use"


param$label_var_name <- "VARIABLES:"
param$label_y_name <- "vertical axis (y)"
param$label_scale_name <- "log scale"
param$label_axis_name <- "proportional to starting year (*)"
param$label_mun_filter <- "Geographic subdivision"
param$geo_level <- "Per geographic subdivision"

# Outros parâmetros e configurações


#  --------------------------------  Roda a aplicação Shiny -------------------------------- 
ui <- get_ui(files,param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
