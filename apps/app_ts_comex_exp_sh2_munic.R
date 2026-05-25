# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_comex_exp_sh2_munic/ui.R"
files$server_script <- "../scripts/ts_comex_exp_sh2_munic/server.R"
files$param_script <- "../scripts/ts_comex_exp_sh2_munic/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file_pt <- "../data/comex_exp_sh2_munic_dic.csv"
files$param_file_en <- "../data/comex_exp_sh2_munic_en_dic.csv"
files$db_file <- "../data/comex_exp_sh2_munic.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros base (PT como padrão)
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param <- param_pt
param$tables <- list(pt = param_pt$table, en = param_en$table)

param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto (quando mouse em cima)
param$group <- "group" # variável de agrupamento

param$link <- "https://datazoom.shinyapps.io/app_ts_comex_exp_sh2_munic/"

param$i18n <- list(
  pt = list(
    plot_name        = "Data Zoom Amazônia",
    plot_desc        = "Comércio exterior na Amazônia (COMEX): Valor da exportação de produtos por município",
    label_var_name   = "VARIÁVEIS:",
    label_y_name     = "Categoria de exportação (agregação da SH2)",
    label_scale_name = "Escala log",
    label_axis_name  = "Proporcional ao ano inicial",
    label_mun_filter = "Recorte Regional",
    currency         = "Por US$",
    measurement      = "US$ ",
    label_value      = "Valor",
    btn_lang         = "English"
  ),
  en = list(
    plot_name        = "Data Zoom Amazônia",
    plot_desc        = "External trade in the Amazon (COMEX): Products export value per municipality",
    label_var_name   = "VARIABLES:",
    label_y_name     = "Export Category (SH2 aggregation)",
    label_scale_name = "Log scale",
    label_axis_name  = "Proportional to starting year",
    label_mun_filter = "Regional Scope",
    currency         = "Per US$",
    measurement      = "US$ ",
    label_value      = "Value",
    btn_lang         = "Português"
  )
)

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
