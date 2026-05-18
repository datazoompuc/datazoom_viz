# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(plotly)
library(htmlwidgets)
library(owdbr)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_energia_amz_exporta/ui.R"
files$server_script <- "../scripts/ts_energia_amz_exporta/server.R"
files$param_script <- "../scripts/ts_energia_amz_exporta/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file_pt <- "../data/energia_amz_exporta_dic.csv"
files$param_file_en <- "../data/energia_amz_exporta_dic_en.csv"
files$db_file <- "../data/energia_amz_exporta.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param <- param_pt
param$tables <- list(
  pt = param_pt$table,
  en = param_en$table
)

param$x_def      <- "ano"
param$y_def      <- ""
param$color_def  <- ""
param$slider_def <- ""
param$text_def   <- ""
param$id_def     <- ""

param$plot_name <- "Data Zoom Amazônia"
param$link      <- "https://datazoom.shinyapps.io/app_ts_energia_amz_exporta/"

param$i18n <- list(
  pt = list(
    plot_desc        = "Dados de Energia do EPE sobre proporção de produção, consumo e consumidores de energia",
    label_var_name   = "VARIÁVEIS:",
    label_y_name     = "Eixo vertical (y)",
    label_scale_name = "Escala log",
    label_prop_name  = "Proporcional ao ano inicial",
    label_geo_name   = "Subdivisão geográfica",
    label_unit_name  = "Unidade de medida",
    translate_names  = FALSE,
    filter_choices   = list(
      "Amazônia Legal" = list("Amazônia Legal"       = "Amazônia Legal",
                                   "Fora da Amazônia Legal" = "Fora da Amazônia Legal"),
      "UF" = owdbr::uflist()$UF
    ),
    uf_map = c("Amazônia Legal"       = "Amazônia Legal",
               "Fora da Amazônia Legal" = "Fora da Amazônia Legal")
  ),
  en = list(
    plot_desc        = "Energy data from EPE on the proportion of energy production, consumption and consumers",
    label_var_name   = "VARIABLES:",
    label_y_name     = "Vertical axis (y)",
    label_scale_name = "Log scale",
    label_prop_name  = "Proportional to the initial year",
    label_geo_name   = "Geographic subdivision",
    label_unit_name  = "Measurement unit",
    translate_names  = TRUE,
    filter_choices   = list(
      "Legal Amazon" = list("Legal Amazon"        = "Amazônia Legal",
                            "Outside Legal Amazon" = "Fora da Amazônia Legal"),
      "UF" = owdbr::uflist()$UF
    ),
    uf_map = c("Amazônia Legal"       = "Legal Amazon",
               "Fora da Amazônia Legal" = "Outside Legal Amazon")
  )
)

# Outros parâmetros e configurações
param$filter_choices <- param$i18n$pt$filter_choices
param$y_choices$`Fonte de dados` <- NULL
param$y_choices[[1]] <- NULL


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
