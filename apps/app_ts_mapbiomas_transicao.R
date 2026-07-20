# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Arquivos
files <- list()
files$ui_script     <- "../scripts/ts_mapbiomas_transicao/ui.R"
files$server_script <- "../scripts/ts_mapbiomas_transicao/server.R"
files$param_script  <- "../scripts/ts_mapbiomas_transicao/db_params.R"
files$CSS_script    <- "../global/dza_lumen.css"

# Dicionários mínimos (est e munic idênticos: time/group/value)
files$param_file_pt <- "../data/mapbiomas_transicao_est_dic.csv"
files$param_file_en <- "../data/mapbiomas_transicao_est_dic_en.csv"

# Duas bases (toggle geográfico)
files$db_file_est   <- "../data/mapbiomas_transicao_est.rds"
files$db_file_munic <- "../data/mapbiomas_transicao_munic.rds"
files$db_file       <- files$db_file_est   # p/ get_db_param montar as choices

# Legenda oficial EN->PT (rótulos das classes from/to)
files$legenda <- "../data/mapbiomas_legenda.csv"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# -------------------------------- Parâmetros --------------------------------

param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param <- param_pt
param$tables <- list(pt = param_pt$table, en = param_en$table)

param$x_def      <- "time"    # eixo X (intervalo)
param$y_def      <- "value"   # eixo Y (área transicionada)
param$color_def  <- "group"
param$text_def   <- "group"
param$id_def     <- "group"
param$group      <- "group"
param$slider_def <- "time"

param$plot_name <- "Data Zoom Amazônia"
param$link      <- "https://datazoom.shinyapps.io/app_ts_mapbiomas_transicao/"

param$i18n <- list(
  pt = list(
    plot_desc      = "Transição (mudança) de cobertura e uso do solo (Fonte: MapBiomas)",
    label_var_name = "VARIÁVEIS:",
    label_from     = "Transição de",
    label_to       = "para",
    label_agg      = "Selecione agregação geográfica:",
    label_geo_name = list(est = "Estados", munic = "Municípios"),
    label_prop     = "Proporcional ao intervalo inicial",
    label_accum    = "Acumulado desde %s",
    x_label        = "Intervalo",
    y_label        = "Área",
    to_connector   = "para",
    subtitle_init  = "por hectare",
    subtitle_prop  = "proporcional ao intervalo inicial (índice 100)",
    subtitle_cum   = "acumulado desde %s (ha)",
    no_observation = "Não há observações para a seleção",
    btn_lang       = "English"
  ),
  en = list(
    plot_desc      = "Land use and land cover change (Source: MapBiomas)",
    label_var_name = "VARIABLES:",
    label_from     = "Transition from",
    label_to       = "to",
    label_agg      = "Select geographical aggregation:",
    label_geo_name = list(est = "States", munic = "Municipalities"),
    label_prop     = "Proportional to initial interval",
    label_accum    = "Accumulated since %s",
    x_label        = "Interval",
    y_label        = "Area",
    to_connector   = "to",
    subtitle_init  = "per hectare",
    subtitle_prop  = "proportional to initial interval (index 100)",
    subtitle_cum   = "accumulated since %s (ha)",
    no_observation = "No observations for the selection",
    btn_lang       = "Português"
  )
)

# -------------------------------- Roda a aplicação --------------------------------
ui     <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
