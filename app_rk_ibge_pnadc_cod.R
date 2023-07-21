# Cache
cache_folder <- "./cache/app_rk_ibge_pnadc_cod/"
shinyOptions(cache = cachem::cache_disk(cache_folder))

# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/rk_ibge_pnadc_cod/ui.R"
files$server_script <- "scripts/rk_ibge_pnadc_cod/server.R"
files$param_script <- "scripts/rk/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/ibge_pnadc_ranking_cod_dic.csv"
files$db_file <- "data/ibge_pnadc_ranking_cod.rds"

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
param$vars <- "VARI\u00C1VEIS:"
param$xaxis <- "Ranking - eixo horizontal (x):"
param$cor <- "Cor das barras:"
param$link <- "https://datazoom.shinyapps.io/app_rk_ibge_pnadc_cod/"

# Parâmetros específicos do server
param$novar <- "Variável não selecionada"
param$title <- "Ranking de "
param$AL <- "Amazônia Legal"
param$lang <- FALSE

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Tipo de Ocupação - Dados agregados dos municípios da Amazônia Legal (Fonte : IBGE)"

# Outros parâmetros e configurações
param$x_choices$`IBGE - PNAD Contínua`$`Tipo de ocupação` <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
