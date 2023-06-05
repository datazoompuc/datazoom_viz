# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_dz_munic/ui.R"
files$server_script <- "scripts/ts_dz_munic/server.R"
files$param_script <- "scripts/ts_dz_munic/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/dz_munic_dic_en.csv"
files$db_file <- "data/dz_munic.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "ano" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "ano" # variável padrão de cor
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "nm_municip" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Compilation of data at the municipality-level"

### Parametros especificos no UI
param$label_var_name <- "VARIABLES:"
param$label_y_name <- "vertical axis (y)"
param$label_scale_name <- "log scale"
param$label_prop_name <- "proportional to the initial year (*)"
param$label_geo_name <- "Geographical subdivision"

param$link <- "https://datazoom.shinyapps.io/app_ts_dz_munic_en/"

### Parametros especificos no server
param$subtitle_init <- "by municipality" # primeira palavra do subtitulo

# Outros parâmetros e configurações
param$y_choices$`Fonte de dados` <- NULL
param$y_choices$IMAZON <- NULL
param$y_choices$`IBGE - Censo 2000` <- NULL
param$y_choices$`IBGE - Censo 2010` <- NULL
param$y_choices[[1]] <- NULL


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
