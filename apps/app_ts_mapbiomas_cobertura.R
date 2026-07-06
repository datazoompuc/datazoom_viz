# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script     <- "../scripts/ts_mapbiomas_cobertura/ui.R"
files$server_script <- "../scripts/ts_mapbiomas_cobertura/server.R"
files$param_script  <- "../scripts/ts_mapbiomas_cobertura/db_params.R"
files$CSS_script    <- "../global/dza_lumen.css"

# Dicionários (classes internas em inglês; rótulos PT/EN). As classes de est e
# munic são idênticas, então usamos o dicionário do est para os rótulos do eixo Y.
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

param$x_def      <- "time"   # variável padrão do eixo x
param$y_def      <- ""       # variável padrão do eixo y
param$color_def  <- "group"  # variável padrão de cor
param$text_def   <- "group"  # variável padrão de texto (mouseover)
param$id_def     <- "group"  # variável de id
param$group      <- "group"  # variável de agrupamento
param$slider_def <- "time"

param$plot_name <- "Data Zoom Amazônia"
param$link      <- "https://datazoom.shinyapps.io/app_ts_mapbiomas_cobertura/"

# Textos PT/EN (lang toggle)
param$i18n <- list(
  pt = list(
    plot_desc        = "Mapeamento Anual do Uso e Cobertura da Terra no Brasil (Fonte: MapBiomas)",
    label_var_name   = "VARIÁVEIS:",
    label_y_name     = "Variável selecionada",
    label_geo_name   = list(est = "Estados", munic = "Municípios"),
    label_geo_toggle = "Ver por município",
    label_prop_name  = "Proporcional ao ano inicial",
    label_prop_muni  = "Proporção da área",
    x_label          = "Ano",
    subtitle_init    = "por hectare",
    server_empty     = "Variável no eixo Y não selecionada",
    btn_lang         = "English",
    tooltip_unit     = "Unidade de medida"
  ),
  en = list(
    plot_desc        = "Annual Land Use and Land Cover Mapping in Brazil (Source: MapBiomas)",
    label_var_name   = "VARIABLES:",
    label_y_name     = "Selected variable",
    label_geo_name   = list(est = "States", munic = "Municipalities"),
    label_geo_toggle = "View by municipality",
    label_prop_name  = "Proportional to initial year",
    label_prop_muni  = "Proportion of area",
    x_label          = "Year",
    subtitle_init    = "per hectare",
    server_empty     = "No Y-axis variable selected",
    btn_lang         = "Português",
    tooltip_unit     = "Unit of measurement"
  )
)

# Remove a primeira choice vazia dos selects
param$y_choices[[1]] <- NULL

# -------------------------------- Roda a aplicação Shiny --------------------------------
ui     <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
