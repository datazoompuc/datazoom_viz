# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "ui.R"
files$server_script <- "server.R"
files$param_script <- "global/db_params.R"
files$CSS_script <- "global/dza_lumen.css"
files$param_file <- "data/ibge_pnadc_cnae_dic.csv"
files$db_file <- "data/ibge_pnadc_cnae.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Compiled data about economic activities generated from the Quarterly Continuous PNAD - IBGE"

### Parametros especificos no UI
param$label_var_name <- "VARIABLES:"
param$label_y_name <- "vertical axis (y)"
param$label_scale_name <- "log scale"
param$label_prop_name <- "proportional to the initial quarter (*)"
param$label_eco_name <- "State - Economic activities"

param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_cnae_en/"

### Parametros especificos no server
param$title_init <- "Quarterly evolution of"  # expressão titulo
param$subtitle_init <- "by economic activities" # expressão subtitulo


# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
