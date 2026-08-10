# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/map_dz_munic_cempre/ui.R"
files$server_script <- "../scripts/map_dz_munic_cempre/server.R"
files$param_script <- "../scripts/map_dz_munic_cempre/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/dz_munic_dic.csv"
files$param_file_en <- "../data/dz_munic_dic_en.csv"
files$db_file <- "../data/cempre_municipality_dza.rds"
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

param$x_def <- "cempre_n_empresas_organizacoes" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "nm_municip" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$app <- "IBGE - CEMPRE"

param$year_inicio <- 2006
param$year_final <- 2020

# Textos internacionalizados
param$i18n <- list(
  pt = list(
    plot_name              = "Data Zoom Amazônia",
    plot_desc               = "Compilação de dados ao nível municipal (CEMPRE)",
    label_var_name          = "VARIÁVEIS:",
    label_x_name            = "Seleciona variável (x)",
    label_year               = "Ano referente",
    label_title              = "Mapa dos municípios da Amazônia Legal",
    subtitle_empty           = "Nenhuma variável selecionada",
    label_munic_name         = "Nome do Município <b>",
    label_state_name         = "Estado: <b>",
    label_measurement_unit   = "Unidade de medida: <b>",
    btn_lang                  = "English",
    btn_fullscreen            = "Fullscreen"
  ),
  en = list(
    plot_name              = "Data Zoom Amazônia",
    plot_desc               = "Data compilation at municipality level (CEMPRE)",
    label_var_name          = "VARIABLES:",
    label_x_name            = "Select variable (x)",
    label_year               = "Reference year",
    label_title              = "Legal Amazon municipality map",
    subtitle_empty           = "No variable was selected",
    label_munic_name         = "Municipality name: <b>",
    label_state_name         = "State: <b>",
    label_measurement_unit   = "Measurement unit: <b>",
    btn_lang                  = "Português",
    btn_fullscreen            = "Fullscreen"
  )
)

# Labels iniciais dos inputs (idioma padrão = pt); atualizados via
# updateSelectInput/updateSliderInput no server quando o idioma muda
param$label_x_name <- param$i18n$pt$label_x_name
param$ref_year     <- param$i18n$pt$label_year

param$link <- "https://datazoom.shinyapps.io/app_map_dz_munic_cempre/"

# Outros parâmetros e configurações
param$x_choices <- param$x_choices[param$app][[1]] # só as 4 variáveis do grupo IBGE - CEMPRE

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
