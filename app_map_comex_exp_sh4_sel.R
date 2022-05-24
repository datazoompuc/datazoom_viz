# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/map_comex_exp_sh4_sel/ui.R"
files$server_script <- "scripts/map_comex_exp_sh4_sel/server.R"
files$param_script <- "scripts/map_comex_exp_sh4_sel/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/comex_exp_munic_sh4_sel_dic.csv"
files$db_file <- "data/comex_exp_munic_sh4_sel.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "Todos os Produtos" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "time" # variável padrão do slider
param$text_def <- "group" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Com\u00e9rcio exterior na Amaz\u00f4nia (COMEX): Valor da exporta\u00e7\u00e3o de produtos"

# Outros parâmetros e configurações
param$x_choices <- c("Produtos Compativeis com a Floresta", "Todos os Produtos")
param$year_inicio <- 1997
param$year_final <- 2021


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
