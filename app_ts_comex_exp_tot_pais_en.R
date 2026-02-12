# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)
library(shinyWidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "ts_comex_exp_tot_pais/ui.R"
files$server_script <- "ts_comex_exp_tot_pais/server.R"
files$param_script <- "ts_comex_exp_tot_pais/db_params.R"

files$CSS_script <- "global/dza_lumen.css"

files$param_file <- "ts_comex_exp_tot_pais/comex_exp_tot_pais_dic_en.csv"
files$db_file <- "ts_comex_exp_tot_pais/comex_exp_tot_pais.rds"
files$aux_file <- "ts_comex_exp_tot_pais/indice_precos_anual.csv"

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
param$lang <- TRUE

param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "External trade in the Brazilian Legal Amazon (COMEX): Total export value of products by destination country"
param$plot_title <- "Total export value of products from the Brazilian Legal Amazon by destination country"


param$label_var_name <- "VARIABLES:"
param$label_scales <- "SCALE OPTIONS:"
param$label_scale_name <- "Log scale"
param$label_axis_name <- "Proportional to starting year"
param$label_prop <- "% of starting year"
param$label_country_filter <- "Destination Countries"
param$link <- "https://datazoom.shinyapps.io/app_ts_comex_exp_tot_pais_en/"
param$currency <- "In US$"
param$measurement <- "US$"
param$label_deflator   <- "Deflate (1998 US$)"
param$ylabel_deflator  <- "1998 US$"
param$subtitle_deflator <- " (deflated, base 1998 = 100)"


# Outros parâmetros e configurações


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
