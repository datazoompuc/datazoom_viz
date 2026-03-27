# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(stringr)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_mapbiomas_transicao/ui.R"
files$server_script <- "../scripts/ts_mapbiomas_transicao/server.R"
files$param_script <- "../scripts/ts_mapbiomas_transicao/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file <- "../data/mapbiomas_transicao_est_dic.csv"
files$db_file <- "../data/mapbiomas_transicao_est.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "value" # variável padrão do eixo y
param$slider_def <- "time"
param$id_def <- "group"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto (quando mouse em cima)
param$group <- "group" # variável de agrupamento
param$x_from_def <- "Afloramento Rochoso"
param$x_to_def <- "Afloramento Rochoso"
param$measur_unit2 <- " (ha)" 

param$label_x_from_name <- "Transição de"
param$label_x_to_name <- "para"
param$to <- "para" # preposição que liga variavel de origem para final da transição
param$no_observation_title <- "Sem observações"
param$no_observation_subtitle <- "não possui observações para o(s) estado(s) selecionado(s)"

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Transição (mudança) de cobertura e uso do solo. Fonte: MapBiomas"
param$lang <- FALSE

### Parametros especificos no UI
param$label_var_name <- "VARIÁVEIS:"
param$label_y_name <- "Área"
param$label_log_name <- "escala log"
param$label_prop_name <-  "proporcional ao intervalo de tempo inicial (*)"
param$label_geo_name <- "Subdivisão geográfica"
param$link <- "https://datazoom.shinyapps.io/app_ts_mapbiomas_transicao_est/"

### Parametros especificos no server
param$subtitle_init <- "por hectare" # expressão titulo

# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
