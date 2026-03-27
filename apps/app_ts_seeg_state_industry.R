# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_seeg_state_industry/ui.R"
files$server_script <- "scripts/ts_seeg_state_industry/server.R"
files$param_script <- "scripts/ts_seeg_state_industry/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/seeg_state_industry_dic.csv"
files$db_file <- "data/seeg_state_industry.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "time" # variável padrão de cor
param$slider_def <- "time" # variável padrão do slider
param$text_def <- "group" # variável padrão de texto
param$id_def <- "group" # variável padrão de id

### Parametros especificos no server
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Emissões de Gases Estufa na Indústria ao nível estadual"
param$plot_y <- "Emissões"
param$lang <- FALSE

### Parametros especificos no UI
param$label_var_name <- "VARIÁVEIS:"
param$label_y_name <- "eixo y (y)"
param$label_log_name <- "escala log"
param$label_prop_name <-  "proporcional ao ano inicial (*)"
param$label_geo_name <- "Estado"
param$link <- "https://datazoom.shinyapps.io/app_ts_seeg_state_industry/"

# Outros parâmetros e configurações


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
