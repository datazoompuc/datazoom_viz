# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_energia_sistemas_isolados/ui.R"
files$server_script <- "../scripts/ts_energia_sistemas_isolados/server.R"
files$param_script <- "../scripts/ts_energia_sistemas_isolados/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file_pt <- "../data/energia_sistemas_isolados_dic.csv"
files$param_file_en <- "../data/energia_sistemas_isolados_dic_en.csv"
files$db_file <- "../data/energia_sistemas_isolados.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param <- param_pt
param$tables <- list(
  pt = param_pt$table,
  en = param_en$table
)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param$x_def <- "Ano" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "tipo" # variável padrão de cor
param$slider_def <- "" # variável padrão do slider
param$text_def <- "" # variável padrão de texto
param$id_def <- "" # variável padrão de id

param$link <- "https://datazoom.shinyapps.io/app_ts_sistemas_isolados/"


param$plot_name <- "Data Zoom Amazônia"

param$i18n <- list(
  pt = list(
    plot_desc = "Dados dos Sistemas Isolados de Energia",
    label_var_name = "VARIÁVEIS:",
    label_y_name = "Eixo vertical (y)",
    label_scale_name = "Escala log",
    label_prop_name = "Proporcional ao ano inicial",
    label_unit_name = "Unidade de medida",
    translate_names = FALSE
  ),
  en = list(
    plot_desc = "Data from Isolated Systems of Energy",
    label_var_name = "VARIABLES:",
    label_y_name = "Vertical axis (y)",
    label_scale_name = "Log scale",
    label_prop_name = "Proportional to the initial year",
    label_unit_name = "Measurement unit",
    translate_names = TRUE
  )
)

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
