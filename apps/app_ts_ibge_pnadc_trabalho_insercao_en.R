# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_ibge_pnadc_trabalho_insercao/ui.R"
files$server_script <- "../scripts/ts_ibge_pnadc_trabalho_insercao/server.R"
files$param_script <- "../scripts/ts_ibge_pnadc_trabalho_insercao/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file <- "../data/ibge_pnadc_trabalho_insercao_dic_en.csv"
files$db_file <- "../data/ibge_pnadc_trabalho_insercao.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "composicao_demografica" # variável padrão de cor
param$text_def <- "id" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "id" # variável de agrupamento
param$lang <- TRUE

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Insertion of employed persons in the Labor Market"

### Parametros especificos no UI
param$label_var_name <-  "VARIABLES:"
param$label_y_name <- "Vertical axis (y)"
param$label_geo_name <-  "Select region"
param$label_comp_name <-  "Select groups"

param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_trabalho_insercao_en/"

### Parametros especificos no server
param$subtitle_init <- "by region and " # expressão subtitulo
param$tooltip  <- "Group: " # expressão html


# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL
param$y_choices[[1]] <- NULL
param$color_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
