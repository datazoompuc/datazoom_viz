# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_comex_exp_tot_pais/ui.R"
files$server_script <- "scripts/ts_comex_exp_tot_pais/server.R"
files$param_script <- "scripts/ts_comex_exp_tot_pais/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/comex_exp_tot_pais_en_dic.csv"
files$db_file <- "data/comex_exp_tot_pais.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "value" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto (quando mouse em cima)
param$group <- "group" # variável de agrupamento
param$lang <- TRUE


param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "External trade in the Amazon (COMEX): Total products export value of Amazonia Legal per destination country"


param$label_var_name <- "VARIABLES:"
param$label_y_name <- "Value (only option)"
param$label_scale_name <- "log scale"
param$label_axis_name <- "proportional to starting year (*)"
param$label_mun_filter <- "Destination Countries"
param$link <- "https://datazoom.shinyapps.io/app_ts_comex_exp_tot_pais_en/"
param$currency <- "Per R$"
param$measurement <- "R$ "

# Outros parâmetros e configurações


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
