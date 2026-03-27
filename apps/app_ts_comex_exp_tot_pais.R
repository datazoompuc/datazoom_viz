# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)
library(shinyWidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_comex_exp_tot_pais/ui.R"
files$server_script <- "scripts/ts_comex_exp_tot_pais/server.R"
files$param_script <- "scripts/ts_comex_exp_tot_pais/db_params.R"

files$CSS_script <- "global/dza_lumen.css"

files$param_file <- "data/comex_exp_tot_pais_dic.csv"
files$db_file <- "data/comex_exp_tot_pais.rds"
files$aux_file <- "data/indice_precos_anual.csv"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "value" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto (quando mouse em cima)
param$group <- "group" # variável de agrupamento
param$lang <- FALSE

param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Com\u00e9rcio exterior na Amaz\u00f4nia (COMEX): Valor da exporta\u00e7\u00e3o de produtos total da Amaz\u00f4nia Legal por país de destino"
param$plot_title <- "Valor total da exporta\u00e7\u00e3o de produtos da Amaz\u00f4nia Legal por país de destino"

param$label_var_name <- "VARIÁVEIS:"
param$label_scales <- "OPÇÕES DE ESCALA:"
param$label_scale_name <- "Escala log"
param$label_axis_name <- "Proporcional ao ano inicial"
param$label_prop <- "% do ano inicial"
param$label_country_filter <- "Países de destino"
param$link <- "https://datazoom.shinyapps.io/app_ts_comex_exp_tot_pais/"
param$currency <- "Em US$"
param$measurement <- "US$"
param$label_deflator <- "Deflacionar (US$ de 1998)"
param$ylabel_deflator <-  "US$ de 1998"
param$subtitle_deflator <- " (deflacionados, base 1998 = 100)"


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
