# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_saude_municipality/ui.R"
files$server_script <- "../scripts/ts_saude_municipality/server.R"
files$param_script <- "../scripts/ts_saude_municipality/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file <- "../data/saude_municipality_dic.csv"
files$param_file_en <- "../data/saude_municipality_dic_en.csv"
files$db_file <- "../data/saude_municipality.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/colunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) 
param_en <- get_db_param(files$param_file_en, files$db_file)

# Dicionários de tabelas ativas por idioma
param$tables <- list(
  pt = param$table,
  en = param_en$table
)

param$x_def <- "ano" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "ano" # variável padrão de cor
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "municipio" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Dados de Saúde ao nível municipal"

# --- ESTRUTURAÇÃO DE TRADUÇÃO (I18N) ---
param$i18n <- list(
  pt = list(
    plot_desc = "Dados de Saúde ao nível municipal",
    label_var_name = "VARIÁVEIS:",
    label_y_name = "Variável selecionada",
    label_scale_name = "Escala log",
    label_prop_name = "Proporcional ao ano inicial",
    label_uf_name = "Estados",
    label_geo_name = "Municípios",
    label_aggregate_name = "Agregar por estado",
    label_municipal = "Por município",
    label_state = "Agregado por estado",
    stitle_init = "por Município ",
    label_and = " e ",
    btn_lang = "English",
    btn_fullscreen = "Tela Cheia",
    label_agg = "Nível geográfico",
    label_geo_est = "ESTADO",
    label_geo_munic = "MUNICÍPIO"
  ),
  en = list(
    plot_desc = "Health Data at municipal level",
    label_var_name = "VARIABLES:",
    label_y_name = "Selected variable",
    label_scale_name = "Log scale",
    label_prop_name = "Proportional to initial year",
    label_uf_name = "States",
    label_geo_name = "Municipalities",
    label_aggregate_name = "Aggregate by state",
    label_municipal = "By municipality",
    label_state = "Aggregated by state",
    stitle_init = "by Municipality ",
    label_and = " and ",
    btn_lang = "Português",
    btn_fullscreen = "Fullscreen",
    label_agg = "Geographical level",
    label_geo_est = "STATE",
    label_geo_munic = "MUNICIPALITY"
  )
)

param$link <- "https://datazoom.shinyapps.io/app_ts_saude_municipality/"

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
