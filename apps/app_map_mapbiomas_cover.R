# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)
library(arrow)
library(shinycssloaders)
library(shinyWidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/map_mapbiomas_cover/ui.R"
files$server_script <- "../scripts/map_mapbiomas_cover/server.R"
files$param_script <- "../scripts/map_mapbiomas_cover/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/map_mapbiomas_cover_dic.csv"
files$param_file_en <- "../data/map_mapbiomas_cover_dic_en.csv"
files$db_file <- "../data/mapbiomas_cobertura.parquet"
files$shapefile <- "../global/munic_shapefile.rds"
files$legal_amazon <- "../global/legal_amazon_boundary.rds"
files$states_boundary <- "../global/states_boundary.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/colunas padrões para os eixos do gráfico)
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param        <- param_pt # PT como idioma padrão
param$tables <- list(pt = param_pt$table, en = param_en$table)

param$x_def <- "Savanna Formation" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "year" # variável padrão do slider
param$text_def <- "municipality" # variável padrão de texto
param$id_def <- "municipality" # variável padrão de id
param$state <- "state" # coluna de estado

param$year_inicio <- 1986
param$year_final <- 2023

# Textos internacionalizados
param$i18n <- list(
  pt = list(
    plot_name             = "Data Zoom Amazônia",
    plot_desc              = "Mapeamento anual do uso e cobertura da terra no Brasil (Fonte: MapBiomas)",
    label_var_name         = "VARIÁVEIS:",
    label_x_name           = "Variável selecionada:",
    label_year              = "Ano:",
    label_title             = "Mapa dos municípios do Brasil com contorno da Amazônia Legal",
    label_selected_variable = "Variável selecionada: ",
    subtitle_empty          = "Nenhuma variável selecionada",
    label_munic_name        = "Município: <b>",
    label_state_name        = "Estado: <b>",
    label_measurement_unit  = "Unidade de medida: <b>",
    label_toggle             = "Proporção da área dos municípios",
    btn_lang                 = "English",
    btn_fullscreen           = "Fullscreen"
  ),
  en = list(
    plot_name             = "Data Zoom Amazônia",
    plot_desc              = "Annual land use and land cover in Brazil (Source: MapBiomas)",
    label_var_name         = "VARIABLES:",
    label_x_name           = "Select variable:",
    label_year              = "Year:",
    label_title             = "Map of Brazilian municipalities with Legal Amazon outline",
    label_selected_variable = "Selected variable: ",
    subtitle_empty          = "No variable selected",
    label_munic_name        = "Municipality: <b>",
    label_state_name        = "State: <b>",
    label_measurement_unit  = "Unit: <b>",
    label_toggle             = "Proportion of municipality area",
    btn_lang                 = "Português",
    btn_fullscreen           = "Fullscreen"
  )
)

# Labels iniciais dos inputs (idioma padrão = pt); atualizados via
# updateSelectInput/updateSliderInput no server quando o idioma muda
param$label_x_name <- param$i18n$pt$label_x_name
param$label_year   <- param$i18n$pt$label_year

param$link <- "https://datazoom.shinyapps.io/app_map_mapbiomas_cover/"

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
