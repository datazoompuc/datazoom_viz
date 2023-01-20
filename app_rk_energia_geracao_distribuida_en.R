# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/rk_energia_geracao_distribuida/ui.R"
files$server_script <- "scripts/rk_energia_geracao_distribuida/server.R"
files$param_script <- "scripts/rk_comex_exp_paises/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/aneel_geracao_distribuida_dic_en.csv"
files$db_file <- "data/aneel_geracao_distribuida.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "potencia_outorgada_k_w" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "ano"
param$color_def <- "estado" # variável padrão de cor
param$text_def <- "estado" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "estado" # variável de agrupamento
param$id_def <- "estado" # variável padrão de id

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "States with the greatest installed energy power in the Legal Amazon"

# Parâmetros específicos do UI
param$ui1 <- "VARIABLES:"
param$ui2 <- "Source:"
param$ui3 <- "Origin:"
param$ui4 <- "Type:"
param$ui5 <- "Final fuel:"
param$ui6 <- "https://datazoom.shinyapps.io/app_rk_energia_geracao_distribuida_en/"

# Parâmetros específicos do server
param$server1 <- "No variable selected"
param$server2 <- "Ranking of "
param$server3 <- "Source: "
param$server4 <- ", Origin: "
param$server5 <- ", Type: "
param$server6 <- ", Final Fuel: "

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
