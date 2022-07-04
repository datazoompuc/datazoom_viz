# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/map_saude_mortalidade/ui.R"
files$server_script <- "scripts/map_saude_mortalidade/server.R"
files$param_script <- "scripts/map_saude_mortalidade/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/saude_mortalidade_dic.csv"
files$db_file <- "data/saude_mortalidade.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "t_total" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "nm_municip" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Saúde na Amazônia: Mortalidade ao nível municipal"

param$year_inicio <- 2006
param$year_final <- 2019

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
