# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/rkstatic_dz_munic/ui.R"
files$server_script <- "../scripts/rkstatic_dz_munic/server.R"
files$param_script <- "../scripts/rkstatic_dz_munic/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file <- "../data/dz_munic_dic.csv"
files$db_file <- "../data/dz_munic.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "incremento" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "ano"
param$color_def <- "nm_municip" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Campeões do desmatamento"

#Mudanças específicas do server
param$label_novariable<- "Variável não selecionada"
param$rk_of<- "Ranking de "
param$label_legal_amazon<- "Amazônia Legal"

#Mudanças específicas do UI
param$label_variable<- "VARI\u00C1VEIS: "
param$rk_x_choice<- "Ranking - eixo horizontal (x):"
param$link<-"https://datazoom.shinyapps.io/app_rkstatic_dz_munic/"
param$label_geog_subdiv<- "Subdivisão geográfica"
param$time_interval<- "Intervalo de tempo: "

# Outros parâmetros e configurações
param$x_choices <- list("INPE - PRODES" = list("Área total de incremento de desmatamento" = "incremento",
                                               "Proporção de incremento de desmatamento na área do município" = "prop_incremento"))


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
