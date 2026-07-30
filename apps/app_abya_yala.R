# Carrega bibliotecas
library(shiny)
library(leaflet)
library(shinycssloaders)
library(leaflet.extras)
library(sf)
library(dplyr)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/abya_yala/ui.R"
files$server_script <- "../scripts/abya_yala/server.R"
files$CSS_script <- "../global/abya_yala_lumen.css"
files$db_file <- "../data/abya_yala_terras_indigenas.rds"
files$assets_dir <- "../data/abya_yala_www"

# Carrega scripts
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização
param <- list()
param$plot_name <- "Caminhos de Abya Yala"
param$plot_desc <- "Intelectuais indígenas do continente americano"

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)