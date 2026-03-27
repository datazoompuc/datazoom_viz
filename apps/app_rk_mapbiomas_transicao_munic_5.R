# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/rk_mapbiomas_transition_est/ui.R"
files$server_script <- "../scripts/rk_mapbiomas_transition_est/server.R"
files$param_script <- "../scripts/rk_mapbiomas_transition_est/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file <- "../data/mapbiomas_transicao_munic_dic.csv"
files$db_file <- "../data/mapbiomas_transicao_munic_5.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "value" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time_span"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id
param$measur_unit1 <- "Área" # Texto "Unidade de Medida" para tooltip
param$measur_unit2 <- " (ha)" # a unidade de medida
param$ui_label_1 <- " Transição de " # opção de transicao de
param$ui_label_2 <- " para " # opção de transicao para
param$to <- " para " # parametro que define conectivo das variaveis do eixo x
param$x_label <- "Área"

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Transição (mudança) de cobertura e uso do solo. Fonte: MapBiomas"
param$subtitle <- "Contém dados de municípios da Amazônia Legal"
param$no_variables <- "Variável não selecionada" # titulo do grafico caso nenhuma observacao seja selecionada
param$no_observations <- "Não há observações" # titulo do grafico caso nao haja observacoes na base

param$ui1 <- "VARI\u00C1VEIS:"
param$link <- 'https://datazoom.shinyapps.io/app_rk_mapbiomas_transicao_munic_5/'
param$lang = FALSE

param$server1 <- " Transição de "
param$server2 <- " para "

# Outros parâmetros e configurações

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
