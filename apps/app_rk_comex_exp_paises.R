# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/rk_comex_exp_paises/ui.R"
files$server_script <- "../scripts/rk_comex_exp_paises/server.R"
files$param_script <- "../scripts/rk_comex_exp_paises/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/comex_exp_tot_pais_dic.csv"
files$param_file_en <- "../data/comex_exp_tot_pais_dic_en.csv"
files$db_file <- "../data/comex_exp_tot_pais.rds"
files$country_map_file <- "../data/paises_traducao.csv"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)
param        <- param_pt
param$tables <- list(pt = param_pt$table, en = param_en$table)

param$x_def <- "value" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id
param$unit <- "R$" #Unidade de Medida

# Textos internacionalizados
param$i18n <- list(
  pt = list(
    plot_name   = "Data Zoom Amazônia",
    plot_desc   = "Países que mais importam da Amazônia Legal",
    plot_title  = "Ranking de Valor",
    subtitle    = "Amazônia Legal",
    x_label     = "Valor",
    y_label     = "Ranking",
    color_label = "País",
    unit_text   = "Unidade de Medida",
    year_prefix = "Ano: ",
    btn_lang    = "English"
  ),
  en = list(
    plot_name   = "Data Zoom Amazônia",
    plot_desc   = "Countries that most import from the Legal Amazon",
    plot_title  = "Value Ranking",
    subtitle    = "Legal Amazon",
    x_label     = "Value",
    y_label     = "Rank",
    color_label = "Country",
    unit_text   = "Unit of Measurement",
    year_prefix = "Year: ",
    btn_lang    = "Português"
  )
)

param$link <- "https://datazoom.shinyapps.io/app_rk_comex_exp_paises/"

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
