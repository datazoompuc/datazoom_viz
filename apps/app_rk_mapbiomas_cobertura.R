# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script     <- "../scripts/rk_mapbiomas_cobertura/ui.R"
files$server_script <- "../scripts/rk_mapbiomas_cobertura/server.R"
files$param_script  <- "../scripts/rk_mapbiomas_cobertura/db_params.R"
files$CSS_script    <- "../global/dza_lumen.css"

# Dicionários (classes internas em inglês; rótulos PT/EN). As classes de est e
# munic são idênticas, então usamos o dicionário do est para os rótulos do eixo X.
files$param_file_pt <- "../data/mapbiomas_cobertura_est_dic.csv"
files$param_file_en <- "../data/mapbiomas_cobertura_est_dic_en.csv"

# Duas bases: o toggle geográfico troca qual está ativa
files$db_file_est   <- "../data/mapbiomas_cobertura_est.rds"
files$db_file_munic <- "../data/mapbiomas_cobertura_munic.rds"

# db_file padrão (usado pelo get_db_param para montar as choices iniciais)
files$db_file <- files$db_file_est

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

param$x_def      <- ""     # variável padrão do eixo x (sorteada ao carregar)
param$slider_def <- "time"

param$plot_name <- "Data Zoom Amazônia"
param$link      <- "https://datazoom.shinyapps.io/app_rk_mapbiomas_cobertura/"

# Textos PT/EN (lang toggle)
param$i18n <- list(
  pt = list(
    plot_desc       = "Mapeamento Anual do Uso e Cobertura da Terra no Brasil (Fonte: MapBiomas)",
    label_var_name  = "VARIÁVEIS:",
    label_x_name    = "Ranking - eixo horizontal (x):",
    label_agg       = "Selecione agregação geográfica:",
    label_geo_name  = list(est = "Estados", munic = "Municípios"),
    label_prop_muni = "Proporção da área",
    label_area      = "Área",
    year_prefix     = "Ano: ",
    ranking_label   = "Ranking",
    title_prefix    = "Ranking de ",
    subtitle_text   = "Amazônia Legal",
    server_empty    = "Variável não selecionada",
    btn_lang        = "English"
  ),
  en = list(
    plot_desc       = "Annual Land Use and Land Cover Mapping in Brazil (Source: MapBiomas)",
    label_var_name  = "VARIABLES:",
    label_x_name    = "Ranking - horizontal axis (x):",
    label_agg       = "Select geographical aggregation:",
    label_geo_name  = list(est = "States", munic = "Municipalities"),
    label_prop_muni = "Proportion of area",
    label_area      = "Area",
    year_prefix     = "Year: ",
    ranking_label   = "Ranking",
    title_prefix    = "Ranking of ",
    subtitle_text   = "Legal Amazon",
    server_empty    = "No variable selected",
    btn_lang        = "Português"
  )
)

# Remove a primeira choice vazia do select (o app sorteia uma classe ao carregar)
param$x_choices[[1]] <- NULL

# -------------------------------- Roda a aplicação Shiny --------------------------------
ui     <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
