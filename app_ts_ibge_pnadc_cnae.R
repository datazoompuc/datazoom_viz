# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_ibge_pnadc_cnae/ui.R"
files$server_script <- "scripts/ts_ibge_pnadc_cnae/server.R"
files$param_script <- "scripts/ts_ibge_pnadc_cnae/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/ibge_pnadc_cnae_dic.csv"
files$db_file <- "data/ibge_pnadc_cnae.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Dados compilados sobre atividades econ\u00f4micas gerados a partir da PNAD Cont\u00ednua Trimestral - IBGE"

### Parametros especificos no UI
param$label_var_name <- "VARIÁVEIS:"
param$label_y_name <- "eixo vertical (y)"
param$label_scale_name <- "escala log"
param$label_prop_name <- "proporcional ao trimestre inicial (*)"
param$label_eco_name <- "Estado - Atividades econômicas"
param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_cnae/"

### Parametros especificos no server
param$title_init <- "Evolução trimestral de"  # expressão titulo
param$subtitle_init <- "por atividade econômica" # expressão subtitulo


# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
