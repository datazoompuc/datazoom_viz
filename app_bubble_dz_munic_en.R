# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(lubridate)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/bubble/ui.R"
files$server_script <- "scripts/bubble/server.R"
files$param_script <- "scripts/bubble/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/dz_munic_dic_en.csv"
files$db_file <- "data/dz_munic.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "desmatado" # variável padrão do eixo x
param$y_def <- "gd_ppc_deflacionado" # variável padrão do eixo y
param$color_def <- "estado" # variável padrão de cor
param$size_def <- "pop" # variável padrão de tamanho
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "nm_municip" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Compilation of data at the municipality-level"

### Parametros especificos no UI
param$label_var_name <- "VARIABLES:"
param$label_x_name <- "horizontal axis (x)"
param$label_y_name <- "vertical axis (y)"
param$label_color_name <- "Marker color:"
param$label_size_name <- "Marker size:"

param$link <- "https://datazoom.shinyapps.io/app_bubble_dz_munic_en/"

### Parametros especificos no server
param$sep <- "by"                    # separador no titulo 
param$subtitle_init <- "considering" # primeira palavra do subtitulo 
param$subtitle_sep <- "and"          # separador no subtitulo

# Outros parâmetros e configurações

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
