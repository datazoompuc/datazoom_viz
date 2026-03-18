# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "ts_ibge_pnadc_trabalho_insercao/ui.R"
files$server_script <- "ts_ibge_pnadc_trabalho_insercao/server.R"
files$param_script <- "ts_ibge_pnadc_trabalho_insercao/db_params.R"
files$CSS_script <- "global/dza_lumen.css"
files$param_file <- "ts_ibge_pnadc_trabalho_insercao/ibge_pnadc_trabalho_insercao_dic.csv"
files$db_file <- "ts_ibge_pnadc_trabalho_insercao/ibge_pnadc_trabalho.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "prop_informal" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "composicao_demografica" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$lang <- FALSE

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Inserção dos Ocupados no Mercado de Trabalho"

### Parametros especificos no UI
param$label_var_name <- "VARIÁVEIS:"
param$label_y_name <- "Eixo vertical (y)"
param$label_geo_name <-  "Selecione recorte regional"
param$label_comp_name <-  "Selecione grupos"

param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_trabalho_insercao/"

### Parametros especificos no server
param$subtitle_init <- "por recorte regional e " # expressão subtitulo
param$tooltip  <- "Grupo: " # expressão html

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL
param$y_choices[[1]] <- NULL
param$color_choices[[1]] <- NULL


param$filter_geo_def <- list("Amaz\u00f4nia Legal", "Fora da Amaz\u00f4nia Legal")

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
