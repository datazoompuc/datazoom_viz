# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/map_dz_state/ui.R"
files$server_script <- "scripts/map_dz_state/server.R"
files$param_script <- "scripts/map_dz_state/db_params.R"
files$CSS_script <- "global/dza_lumen.css"
files$param_file <- "data/dz_state_dic.csv"
files$db_file <- "data/dz_state_simplified.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "estado" # variável padrão de texto
param$id_def <- "group" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Compilação de dados ao nível estadual"

# Outros parâmetros e configurações
param$x_choices$`Fonte de dados` <- NULL
param$x_choices[[1]] <- NULL
param$x_choices$`IBGE - Censo 2000` <- NULL
param$x_choices$`IBGE - Censo 2010` <- NULL
param$x_choices$IMAZON <- NULL
param$x_choices$Geral <- NULL

param$year_inicio <- 2000
param$year_final <- 2019

#Mudanças específicas no server
param$title<-"Mapa dos estados da Amazônia Legal"
param$no_selec_var<-"Nenhuma variável selecionada"
param$selec_var<-"Variável selecionada: "
param$state<- "Estado: "
param$measurement_unit<-"Unidade de medida: "

#Mudanças específicas no UI
param$variable<- "VARI\u00C1VEIS::"
param$variable_x<- "Seleciona variável (x)"
param$year_ref<- "Ano referente"
param$link<-'https://datazoom.shinyapps.io/app_map_dz_state/'

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
