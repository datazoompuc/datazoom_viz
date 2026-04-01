# Cache
cache_folder <- "./cache/app_rk_ibge_pnadc_cod_en/"
shinyOptions(cache = cachem::cache_disk(cache_folder))

# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/rk_ibge_pnadc_cnae/ui.R"
files$server_script <- "../scripts/rk_ibge_pnadc_cnae/server.R"
files$param_script <- "../scripts/ts_ibge_pnadc_cnae/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file <- "../data/ibge_pnadc_cod_rk_dic_en.csv"
files$db_file <- "../data/ibge_pnadc_cod.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "n_ocu_cod" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id

# Parâmetros específicos do UI
param$vars <- "VARIABLES:"
param$xaxis <- "Ranking - horizontal axis (x):"
param$cor <- "Bar colors:"
param$link <- "https://datazoom.shinyapps.io/app_rk_ibge_pnadc_cod_en/"


# Parâmetros específicos do server
param$novar <- "No variable selected"
param$title <- "Ranking of "
param$AL <- "Legal Amazon"
param$lang <- TRUE
    
# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Occupation type - Aggregated data of municipalities in the Legal Amazon (Source: IBGE)"

# Outros parâmetros e configurações
param$x_choices$`IBGE - Continuous PNAD`$`Occupation type` <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
