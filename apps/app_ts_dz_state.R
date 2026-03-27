# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_dz_state/ui.R"
files$server_script <- "../scripts/ts_dz_state/server.R"
files$param_script <- "../scripts/ts_dz_state/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file <- "../data/dz_state_dic.csv"
files$db_file <- "../data/dz_state.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "ano" # variável padrão do eixo x
param$y_def <- "bovino_efetivo_dos_rebanhos" # variável padrão do eixo y
param$slider_def <- "ano"
param$color_def <- "estado" # variável padrão de cor
param$text_def <- "estado" # variável padrão de texto (quando mouse em cima)
param$group <- "estado" # variável de agrupamento


param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Produção Econômica por Estado"

### Parametros especificos no UI
param$label_var_name <- "VARIÁVEIS:"
param$label_y_name <- "eixo vertical (y)"
param$label_scale_name <- "escala log"
param$label_prop_name <- "proporcional ao ano inicial (*)"
param$label_geo_name <- "Subdivisão geográfica"

param$link <- "https://datazoom.shinyapps.io/app_ts_dz_state/"

### Parametros especificos no server
param$subtitle_init <- "por estado"

# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
