# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)
library(shinycssloaders)
library(shinyWidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/map_saude_mortalidade/ui.R"
files$server_script <- "../scripts/map_saude_mortalidade/server.R"
files$param_script <- "../scripts/map_saude_mortalidade/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/saude_mortalidade_dic.csv"
files$param_file_en <- "../data/saude_mortalidade_dic_en.csv"
files$db_file <- "../data/saude_mortalidade.rds"
files$legal_amazon <- "../global/legal_amazon_boundary.rds"
files$states_boundary <- "../global/states_boundary.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param        <- param_pt # PT como idioma padrão
param$tables <- list(pt = param_pt$table, en = param_en$table)

param$x_def <- "t_total" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "nm_municip" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id

param$year_inicio <- 2006
param$year_final <- 2019

# Textos internacionalizados
param$i18n <- list(
  pt = list(
    plot_name             = "Data Zoom Amaz\u00f4nia",
    plot_desc             = "Sa\u00fade na Amaz\u00f4nia Legal: Mortalidade ao n\u00edvel municipal",
    label_var_name        = "VARI\u00C1VEIS:",
    label_x_name          = "Seleciona vari\u00e1vel (x)",
    label_year            = "Ano referente",
    label_title           = "Mapa dos munic\u00edpios da Amaz\u00f4nia Legal",
    label_selected_variable = "Vari\u00e1vel selecionada: ",
    subtitle_empty        = "Nenhuma vari\u00e1vel selecionada",
    label_munic_name      = "Nome do munic\u00edpio: <b>",
    label_state_name      = "Estado: <b>",
    label_measurement_unit = "Unidade de medida: <b>",
    btn_lang              = "English",
    btn_fullscreen        = "Tela Cheia"
  ),
  en = list(
    plot_name             = "Data Zoom Amaz\u00f4nia",
    plot_desc             = "Health in the Legal Amazon: Mortality at the municipal level",
    label_var_name        = "VARIABLES:",
    label_x_name          = "variable selection (x)",
    label_year            = "Reference year",
    label_title           = "Legal Amazon Municipalities Map",
    label_selected_variable = "Selected Variable: ",
    subtitle_empty        = "No variable selected",
    label_munic_name      = "Municipalitie's name: <b>",
    label_state_name      = "State's name: <b>",
    label_measurement_unit = "Measurement unit: <b>",
    btn_lang              = "Portugu\u00eas",
    btn_fullscreen        = "Fullscreen"
  )
)

# Labels iniciais dos inputs (idioma padrão = pt); atualizados via
# updateSelectInput/updateSliderInput no server quando o idioma muda
param$label_x_name <- param$i18n$pt$label_x_name
param$label_year   <- param$i18n$pt$label_year

param$link <- "https://datazoom.shinyapps.io/app_map_saude_mortalidade/"

# Inicializa UI
ui <- get_ui(files, param)

# Inicializa server
server <- get_server(files, param)

# Roda aplicação
shinyApp(ui, server)
