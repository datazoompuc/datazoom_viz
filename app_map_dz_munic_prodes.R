# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/map_dz_munic_prodes/ui.R"
files$server_script <- "scripts/map/server.R"
files$param_script <- "scripts/map/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/dz_munic_dic.csv"
files$db_file <- "data/dz_munic_simplified.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "desmatado" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "nm_municip" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Compilação de dados ao nível municipal (PRODES)"
param$app <- "INPE - PRODES"

param$year_inicio <- 2000
param$year_final <- 2021

#parâmetros específicos no Server
param$label_title<- "Mapa dos municípios da Amazônia Legal"
param$label_munic<- "Nome do Município <b>"
param$label_state<- "Estado: <b>"
param$label_measurement_unit<- "Unidade de medida: <b>"

#parametros especificos no UI
param$label_var_name<-  "VARI\u00C1VEIS:"
param$label_x_name<- "Seleciona variável (x)"
param$ref_year<- "Ano Referente"
# Outros parâmetros e configurações
param$x_choices <- param$x_choices[param$app]


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
