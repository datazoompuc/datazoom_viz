# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Arquivos
files <- list()
files$ui_script     <- "../scripts/sankey_mapbiomas_transicao/ui.R"
files$server_script <- "../scripts/sankey_mapbiomas_transicao/server.R"
files$param_script  <- "../scripts/sankey_mapbiomas_transicao/db_params.R"
files$CSS_script    <- "../global/dza_lumen.css"

# Dicionários mínimos (est e munic idênticos: time/group/value)
files$param_file_pt <- "../data/mapbiomas_transicao_sankey_dic.csv"
files$param_file_en <- "../data/mapbiomas_transicao_sankey_dic_en.csv"

# Duas bases (toggle geográfico), AMBAS anuais e já sem persistência (from == to).
# Vêm de data-raw/mapbiomas_transicao_sankey.R -- não são as do
# ts_mapbiomas_transicao, que usa outra grade temporal.
files$db_file_est   <- "../data/mapbiomas_transicao_sankey_est.rds"
files$db_file_munic <- "../data/mapbiomas_transicao_sankey_munic.rds"
files$db_file       <- files$db_file_est # p/ get_db_param montar as choices

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

param$y_def <- "value" # área transicionada (largura dos fluxos)
param$group <- "group"

param$plot_name <- "Data Zoom Amazônia"
param$link      <- "https://datazoom.shinyapps.io/app_sankey_mapbiomas_transicao/"

param$i18n <- list(
  pt = list(
    plot_desc       = "Transição (mudança) de cobertura e uso do solo (Fonte: MapBiomas)",
    label_var_name  = "VARIÁVEIS:",
    label_topn_name = "Número de fluxos exibidos",
    # prefixos do slider: no acumulado o passo é o ano final, no normal é a janela
    slider_prefix_window = "Intervalo",
    slider_prefix_accum  = "Acumulado até",
    label_agg       = "Selecione agregação geográfica:",
    label_geo_name  = list(est = "Estados", munic = "Municípios"),
    label_accum     = "Acumulado desde %s",
    to_connector    = "para",
    unit            = "ha",
    subtitle_init   = "área transicionada, em hectares (exclui persistência na mesma classe)",
    subtitle_accum  = "soma dos fluxos desde %s, em hectares (exclui persistência na mesma classe)",
    no_observation  = "Não há observações para a seleção",
    btn_lang        = "English",
    btn_fullscreen  = "Fullscreen"
  ),
  en = list(
    plot_desc       = "Land use and land cover change (Source: MapBiomas)",
    label_var_name  = "VARIABLES:",
    label_topn_name = "Number of flows displayed",
    slider_prefix_window = "Interval",
    slider_prefix_accum  = "Accumulated to",
    label_agg       = "Select geographical aggregation:",
    label_geo_name  = list(est = "States", munic = "Municipalities"),
    label_accum     = "Accumulated since %s",
    to_connector    = "to",
    unit            = "ha",
    subtitle_init   = "transitioned area, in hectares (excludes persistence in the same class)",
    subtitle_accum  = "sum of flows since %s, in hectares (excludes persistence in the same class)",
    no_observation  = "No observations for the selection",
    btn_lang        = "Português",
    btn_fullscreen  = "Fullscreen"
  )
)

# -------------------------------- Roda a aplicação --------------------------------
ui     <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
