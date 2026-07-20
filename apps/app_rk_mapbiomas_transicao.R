# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script     <- "../scripts/rk_mapbiomas_transicao/ui.R"
files$server_script <- "../scripts/rk_mapbiomas_transicao/server.R"
files$param_script  <- "../scripts/rk_mapbiomas_transicao/db_params.R"
files$CSS_script    <- "../global/dza_lumen.css"

# Dicionários (classes internas em inglês; rótulos PT/EN). est e munic
# compartilham o mesmo dicionário mínimo (time/group/value).
files$param_file_pt <- "../data/mapbiomas_transicao_rk_dic.csv"
files$param_file_en <- "../data/mapbiomas_transicao_rk_dic_en.csv"

# Duas bases: o toggle geográfico troca qual está ativa
files$db_file_est   <- "../data/mapbiomas_transicao_rk_est.rds"
files$db_file_munic <- "../data/mapbiomas_transicao_rk_munic.rds"

# db_file padrão (usado pelo get_db_param para montar as choices iniciais)
files$db_file <- files$db_file_est

# Legenda oficial EN->PT para traduzir os rótulos das classes from/to
files$legenda <- "../data/mapbiomas_legenda.csv"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# -------------------------------- Parâmetros da visualização --------------------------------

param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param <- param_pt
param$tables <- list(
  pt = param_pt$table,
  en = param_en$table
)

param$x_def      <- "value"  # eixo do ranking (área transicionada)
param$color_def  <- "group"  # variável de cor
param$text_def   <- "group"  # texto sobre a barra
param$id_def     <- "group"  # id
param$group      <- "group"  # agrupamento
param$slider_def <- "time"   # animação ano a ano

param$plot_name <- "Data Zoom Amazônia"
param$link      <- "https://datazoom.shinyapps.io/app_rk_mapbiomas_transicao/"

# Textos PT/EN (lang toggle)
param$i18n <- list(
  pt = list(
    plot_desc      = "Transição (mudança) de cobertura e uso do solo (Fonte: MapBiomas)",
    label_var_name = "VARIÁVEIS:",
    label_from     = "Transição de",
    label_to       = "para",
    label_agg      = "Selecione agregação geográfica:",
    label_geo_name = list(est = "Estados", munic = "Municípios"),
    x_label        = "Área",
    measur_unit1   = "Área",
    measur_unit2   = " (ha)",
    to_connector   = " para ",
    server1        = "Ranking - Transição de ",
    server2        = " para ",
    rank_label     = "Ranking",
    slider_prefix  = "Ano: ",
    slider_prefix_cum = "Acumulado até: ",
    subtitle_annual = "Transição em %s (ha)",             # %s = janela selecionada
    subtitle_cum    = "Acumulado desde %s (ha)",          # %s = 1º ano (o ano corrente vai no slider)
    label_accum     = "Acumulado desde %s",               # %s = 1º ano da série
    no_variable    = "Variável não selecionada",
    no_observation = "Não há observações",
    btn_lang       = "English"
  ),
  en = list(
    plot_desc      = "Land use and land cover change (Source: MapBiomas)",
    label_var_name = "VARIABLES:",
    label_from     = "Transition from",
    label_to       = "to",
    label_agg      = "Select geographical aggregation:",
    label_geo_name = list(est = "States", munic = "Municipalities"),
    x_label        = "Area",
    measur_unit1   = "Area",
    measur_unit2   = " (ha)",
    to_connector   = " to ",
    server1        = "Ranking - Transition from ",
    server2        = " to ",
    rank_label     = "Ranking",
    slider_prefix  = "Year: ",
    slider_prefix_cum = "Accumulated to: ",
    subtitle_annual = "Transition in %s (ha)",                # %s = selected window
    subtitle_cum    = "Accumulated since %s (ha)",            # %s = first year (current year shown on the slider)
    label_accum     = "Accumulate since %s",                  # %s = first year
    no_variable    = "No variable selected",
    no_observation = "No observations",
    btn_lang       = "Português"
  )
)

# -------------------------------- Roda a aplicação Shiny --------------------------------
ui     <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
