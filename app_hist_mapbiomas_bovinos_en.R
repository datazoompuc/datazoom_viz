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

files$param_file <- "data/dz_munic_ppm_mapbiomas_dic_en.csv"
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
param$plot_desc <- "Distribution of Municipalities according to Cattle per Hectares of Grazing Area "


# Outros parâmetros e configurações
param$filter_choices <- list("Amazônia Legal" = list("Amazônia Legal", "Fora da Amazônia Legal"),
                             "Regiões" = list("Centro-Oeste", "Nordeste", "Norte", "Sudeste", "Sul"),
                             "Estados" = owdbr::uflist()$UF)

param$year_inicio <- 1985
param$year_final <- 2019

#mudanças específicas no server
param$legal_amazon_in<- "Legal Amazon"
param$legal_amazon_out<- "Outside of the Legal Amazon"
param$bovino<-"Cattle/Hectares of Pasture Area: "
param$munic_dist<- "Distribution of Municipalities"
param$hover<-"Number of Municipalities: %{y}<br>Log(Number of Cattle/Hectares of Pasture Area + 1): %{x}"
param$hover_2<-"Number of Municipalities: %{y}<br>Number of Cattle/Hectares of Pasture Area: %{x}"
param$log_bovino<- "Log(Number of Cattle/Hectares of Pasture Area + 1)"
param$bovino_area_2<- "Bovinos/Hectares de Área de Pastagem"
param$munic_num<- "Number of Municipalities"
#mudanças específicas no UI
param$variable<- "VARIABLES:"
param$logx<-"log scale (x+1)"
param$ref_year<-"Referecing year"
param$link<-"https://datazoom.shinyapps.io/app_hist_mapbiomas_bovinos_en/"

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
