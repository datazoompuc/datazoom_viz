# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/sankey/ui.R"
files$server_script <- "scripts/sankey/server.R"
files$param_script <- "scripts/sankey/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/comex_exp_pais_sec_en_dic.csv"
files$db_file <- "data/comex_exp_pais_sec.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "Produtos do reino vegetal" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto (quando mouse em cima)
param$group <- "group" # variável de agrupamento


param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "External trade in the Amazon (COMEX): Products export value per destination country"

# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL
param$year_inicio <- 1997
param$year_final <- 2021

param$label_var_name <- "VARIABLES:"
param$label_x_name <- "Export Category (SEC agreggation)"
param$label_colour_name <- "Year"
param$link <- "https://datazoom.shinyapps.io/app_sankey_comex_exp_pais_sec_en/"


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
