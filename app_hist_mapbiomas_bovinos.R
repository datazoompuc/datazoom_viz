# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/hist_mapbiomas_bovinos/ui.R"
files$server_script <- "scripts/hist_mapbiomas_bovinos/server.R"
files$param_script <- "scripts/hist_mapbiomas_bovinos/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/dz_munic_ppm_mapbiomas_dic.csv"
files$db_file <- "data/dz_munic_ppm_mapbiomas.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "ano" # variável padrão do eixo x
param$y_def <- "n_bovino_por_area_pastagem" # variável padrão do eixo y
param$color_def <- "uf" # variável padrão de cor
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "uf" # variável padrão de texto
param$id_def <- "uf" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Distribuição dos Municípios de acordo com Bovino/Hectares de Área de Pastagem"


# Outros parâmetros e configurações
param$filter_choices <- list("Amazônia Legal" = list("Amazônia Legal", "Fora da Amazônia Legal"),
                             "Regiões" = list("Centro-Oeste", "Nordeste", "Norte", "Sudeste", "Sul"),
                             "Estados" = owdbr::uflist()$UF)

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
