# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_saude_municipality/ui.R"
files$server_script <- "scripts/ts_saude_municipality/server.R"
files$param_script <- "scripts/ts_saude_municipality/db_params.R"

files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/saude_municipality_dic_en.csv"
files$db_file <- "data/saude_municipality.rds"

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
param$text_def <- "municipio" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Health data at the municipal level"

### Parametros especificos no UI
param$label_var_name <- "VARIABLES:"
param$label_y_name <- "Selected variable"
param$label_log_name <-  "Log scale"
param$label_prop_name <-  "Proportional to the initial year"
param$label_uf_name <-  "States"
param$label_geo_name <- "Municipalities"
param$link <- "https://datazoom.shinyapps.io/app_ts_saude_municipality_en/"
param$label_aggregate_name <- "Aggregate by state"
param$label_municipal <- "By municipality"
param$label_state <- "Aggregated by state"
param$stitle_init <- "by Municipality "

### Parametros especificos no server
param$stitle_init <- "by Municipality " # expressão titulo
param$label_and <- " and "


# Outros parâmetros e configurações
param$y_choices$IBGE <- NULL
param$y_choices[[1]] <- NULL
param$uf_choices <- c("RO", "AC", "AM", "RR", "PA", "AP", "TO", "MA", 
                      "PI", "BA", "MS", "MT", "GO")
param$uf_def <- "RO"
param$munic_def <- c("Alta Floresta D'Oeste (RO)", "Ariquemes (RO)")

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
