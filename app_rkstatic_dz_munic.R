# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/rkstatic_dz_munic/ui.R"
files$server_script <- "scripts/rkstatic_dz_munic/server.R"
files$param_script <- "scripts/rkstatic_dz_munic/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/dz_munic_dic.csv"
files$db_file <- "data/dz_munic.rds"

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


# Outros parâmetros e configurações
param$x_choices$`Fonte de dados` <- NULL
param$x_choices$IMAZON <- NULL
param$x_choices$`IBGE - Censo 2000` <- NULL
param$x_choices$`IBGE - Censo 2010` <- NULL
param$x_choices[[1]] <- NULL
param$x_choices$`IBGE - CEMPRE` <- NULL
param$x_choices$`INPE - PRODES`$`Proporção de desmatamento na área do município` <- NULL
param$x_choices$`INPE - PRODES`$`Proporção de floresta na área do município` <- NULL
param$x_choices$`INPE - PRODES`$`Proporção de não-floresta na área do município` <- NULL
param$x_choices$`INPE - PRODES`$`Proporção de hidrografia na área do município` <- NULL
param$x_choices$`INPE - PRODES`$`Área total desmatada` <- NULL
param$x_choices$`INPE - PRODES`$`Área total de floresta` <- NULL
param$x_choices$`INPE - PRODES`$`Área total de não-floresta` <- NULL
param$x_choices$`INPE - PRODES`$`Área total de hidrografia` <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
