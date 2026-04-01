# Cache
cache_folder <- "./cache/app_rk_comex_exp_paises/"
shinyOptions(cache = cachem::cache_disk(cache_folder))

# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/rk_comex_exp_paises/ui.R"
files$server_script <- "../scripts/rk_comex_exp_paises/server.R"
files$param_script <- "../scripts/rk_comex_exp_paises/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file <- "../data/comex_exp_tot_pais_dic.csv"
files$db_file <- "../data/comex_exp_tot_pais.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "value" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id
param$unit <- "R$" #Unidade de Medida
param$unit_text <- "Unidade de Medida" #Texto para unidade de medida

# Parâmetros específicos do UI
param$ui1 <- "VARI\u00C1VEIS:"
param$ui2 <- "Ranking - eixo horizontal (x):"
param$ui3 <- "Cor das barras:"
param$ui4 <- "https://datazoom.shinyapps.io/app_rk_comex_exp_paises/"

# Parâmetros específicos do server
param$server1 <- "Variável não selecionada"
param$server2 <- "Ranking de "
param$server3 <- "Amazônia Legal"
param$lang <- FALSE

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Países que mais importam da Amazônia Legal"

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
