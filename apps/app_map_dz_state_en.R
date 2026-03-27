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
files$param_file <- "data/dz_state_dic_en.csv"
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
param$plot_desc <- "Data compiled at the state level"

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
param$title<-"Legal Amazon's States Map"
param$no_selec_var<-"No variables selected"
param$selec_var<-"Selected variable: "
param$state<- "State: "
param$measurement_unit<-"Measurement Unit: "

#Mudanças específicas no UI
param$variable<- "VARIABLES"
param$variable_x<- "Variable selection (x)"
param$year_ref<- "Referecing year"
param$link<-'https://datazoom.shinyapps.io/app_map_dz_state_en/'

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
