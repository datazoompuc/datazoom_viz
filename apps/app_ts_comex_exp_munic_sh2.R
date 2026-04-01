# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_comex_exp_munic_sh2/ui.R"
files$server_script <- "../scripts/ts_comex_exp_munic_sh2/server.R"
files$param_script <- "../scripts/ts_comex_exp_munic_sh2/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file <- "../data/comex_exp_munic_sh2_dic.csv"
files$db_file <- "../data/comex_exp_munic_sh2.rds"

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
param$lang <- FALSE


param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Com\u00e9rcio exterior na Amaz\u00f4nia (COMEX): Valor da exporta\u00e7\u00e3o de produtos por munic\u00edpio"

# Outros parâmetros e configurações

param$label_var_name <- "VARIÁVEIS:"
param$label_y_name <- "Município da Amazônia"
param$label_scale_name <- "escala log"
param$label_axis_name <- "proporcional ao ano inicial (*)"
param$label_mun_filter <- "Categorias de exportação (agregação do SH2)"
param$link <- "https://datazoom.shinyapps.io/app_ts_comex_exp_munic_sh2/"
param$currency <- "Por R$"
param$measurement <- "R$ "

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
