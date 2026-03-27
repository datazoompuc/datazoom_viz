# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/mapstatic/ui.R"
files$server_script <- "scripts/mapstatic/server.R"
files$param_script <- "scripts/mapstatic/db_params.R"
files$CSS_script <- "global/dza_lumen.css"
files$param_file <- "data/dz_munic_dic.csv"
files$db_file <- "data/dz_munic_simplified.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "ips2018" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "nm_municip" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Compilação de dados ao nível municipal"

# Outros parâmetros e configurações
param$x_choices$`Fonte de dados` <- NULL
param$x_choices[[1]] <- NULL
param$x_choices$`INPE - PRODES` <- NULL
param$x_choices$`IBGE - CEMPRE` <- NULL
param$x_choices$`IBGE - PPM` <- NULL
param$x_choices$`IBGE - PAM` <- NULL

param$label_var_name <- "VARIÁVEIS:"
param$label_x_name <- "Seleciona variável (x)"
param$link <- "https://datazoom.shinyapps.io/app_mapstatic_dz_munic/"
param$title <- "Mapa dos municípios da Amazônia Legal"
param$empty <- "Nenhuma variável selecionada"
param$selected_variable <- "Variável selecionada: "
param$label_1 <- "Nome do município: "
param$label_2 <- "Estado: "
param$label_3 <- "Unidade de medida: "   

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
