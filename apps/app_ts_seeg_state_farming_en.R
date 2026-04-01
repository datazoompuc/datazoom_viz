# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_seeg_state_farming/ui.R"
files$server_script <- "../scripts/ts_seeg_state_farming/server.R"
files$param_script <- "../scripts/ts_seeg_state_farming/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file <- "../data/seeg_state_farming_dic_en.csv"
files$db_file <- "../data/seeg_state_farming.rds"

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

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Greenhouse Gas Emissions in Farming  at State Level"
param$plot_y <- "Emissions"

### Parametros especificos no UI
param$label_var_name <- "VARIABLES:"
param$label_y_name <- "vertical axis (y)"
param$label_log_name <- "log scale"
param$label_prop_name <-  "proportional to the initial year (*)"
param$label_geo_name <- "State"
param$link <- "https://datazoom.shinyapps.io/app_ts_seeg_state_farming_en/"

### Parametros especificos no server
param$subtitle_init <- "by State" # expressão subtitulo
param$title_init <- "Total emissions from "
param$tooltip_a <- "Emissions"
param$tooltip_b <-  "Unit of measurement: <b>"
param$tooltip_c <- "Tons"
param$lang = TRUE


# Outros parâmetros e configurações


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
