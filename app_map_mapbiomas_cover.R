# Cache
cache_folder <- "map_mapbiomas_cover/cache"
shinyOptions(cache = cachem::cache_disk(cache_folder))

# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)
library(arrow)
library(shinycssloaders)
library(shinyWidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "map_mapbiomas_cover/ui.R"
files$server_script <- "map_mapbiomas_cover/server.R"
files$param_script <- "map_mapbiomas_cover/db_params.R"
files$CSS_script <- "global/dza_lumen.css"
files$param_file <- "map_mapbiomas_cover/dic.csv"
files$db_file <- "map_mapbiomas_cover/mapbiomas_cobertura.parquet"
files$shapefile <- "global/munic_shapefile.rds"
files$legal_amazon <- "global/legal_amazon_boundary.rds"
files$states_boundary <- "global/states_boundary.rds"


# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "Savanna Formation" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "year" # variável padrão do slider
param$text_def <- "municipality" # variável padrão de texto
param$id_def <- "municipality" # variável padrão de id
param$state <- "state" # coluna de estado

param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Mapeamento anual do uso e cobertura da terra no Brasil (Fonte: MapBiomas)"
    #"Cobertura da terra na Amaz\u00f4nia"


####### HEAD
param$plot_desc <- "Áreas de pastagem no Brasil (colocar obs dados)"

param$plot_desc <- "Sa\u00fade na Amaz\u00f4nia: Mortalidade ao n\u00edvel municipal"
####### parent of 90e15e6 (adjusting variables)

param$plot_desc <- "Cobertura vegetal a nível municipal"
####### parent of a0643c6 (Correcting border Legal Amazon)

param$year_inicio <- 1986
param$year_final <- 2023

#parâmetros específicos no UI
param$label_var_name<- "VARI\u00C1VEIS:"
param$label_x_name<- "Vari\u00e1vel selecionada:"
param$label_year<- "Ano referente"
param$label_title<- "Mapa dos munic\u00edpios do Brasil com contorno da Amaz\u00f4nia Legal"
param$label_selected_variable<- "Vari\u00e1vel selecionada: "
param$label_munic_name<- "Munic\u00edpio <b>"
param$label_state_name<- "Estado: <b>"
param$label_measurement_unit<- "Unidade de medida: <b>"
param$label_toggle <- "Propor\u00e7\u00e3o da \u00e1rea dos munic\u00edpios"
param$link<- "https://datazoom.shinyapps.io/app_map_mapbiomas_cover/"
# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
