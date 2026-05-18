# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/rk_energia_geracao_distribuida/ui.R"
files$server_script <- "../scripts/rk_energia_geracao_distribuida/server.R"
files$param_script <- "../scripts/rk_energia_geracao_distribuida/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file_pt <- "../data/aneel_siga_geracao_distribuida_dic.csv"
files$param_file_en <- "../data/aneel_siga_geracao_distribuida_dic_en.csv"
files$db_file <- "../data/aneel_siga_geracao_distribuida.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/colunas padrões para os eixos do gráfico)
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param <- param_pt
param$tables <- list(
  pt = param_pt$table,
  en = param_en$table
)
param$x_def <- "potencia_outorgada_kw" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "ano"
param$color_def <- "estado" # variável padrão de cor
param$text_def <- "estado" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "estado" # variável de agrupamento
param$id_def <- "estado" # variável padrão de id

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$link <- "https://datazoom.shinyapps.io/app_rk_energia_geracao_distribuida/"

param$i18n <- list(
  pt = list(
    plot_desc = "Estados com maior capacidade instalada de energia na Amazônia Legal",
    ui1       = "VARIÁVEIS:",
    ui2       = "Fonte:",
    ui3       = "Origem:",
    ui4       = "Tipo:",
    ui5       = "Combustível final:",
    server1   = "Variável não selecionada",
    server2   = "Ranking de ",
    server3   = "Fonte: ",
    server4   = "Origem: ",
    server5   = "Tipo: ",
    server6   = "Combustível Final: ",
    server7   = "Todos"
  ),
  en = list(
    plot_desc = "States with the greatest installed energy power in the Legal Amazon",
    ui1       = "VARIABLES:",
    ui2       = "Source:",
    ui3       = "Origin:",
    ui4       = "Type:",
    ui5       = "Final fuel:",
    server1   = "No variable selected",
    server2   = "Ranking of ",
    server3   = "Source: ",
    server4   = "Origin: ",
    server5   = "Type: ",
    server6   = "Final Fuel: ",
    server7   = "All"
  )
)

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
