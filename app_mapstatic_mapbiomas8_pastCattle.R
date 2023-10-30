# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/mapstatic_mapbiomas8_pastCattle/ui.R"
files$server_script <- "scripts/mapstatic_mapbiomas8_pastCattle/server.R"
files$param_script <- "scripts/mapstatic_mapbiomas8_pastCattle/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/mapbiomas8_cover_pastCattle_dic.csv"
files$db_file <- "data/mapbiomas8_cover_pastCattle.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "land_efficiency" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "" # variável padrão do slider
param$text_def <- "municipality" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Dados compilados do Instituto do Homem e do Meio Ambiente da Amaz\u00f4nia (Imazon)" ####mudar isso?

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

#parâmetros específicos no UI
param$label_title<-"Mapa dos munic\u00edpios da Amaz\u00f4nia Legal"
param$label_selected_variable<-"Vari\u00e1vel selecionada:"
param$label_var_name<- "VARI\u00C1VEIS::"
param$label_x_name<- "Seleciona vari\u00e1vel"
param$label_munic_name<- "Nome do munic\u00edpio: "
param$label_state<- "Estado: "
param$label_measurement_unit<- "Unidade de Medida: "
param$link<-"https://datazoom.shinyapps.io/app_mapstatic_ips_2021/"#####mudar isso?

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
