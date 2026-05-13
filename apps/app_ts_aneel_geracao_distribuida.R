# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_aneel_geracao_distribuida/ui.R"
files$server_script <- "../scripts/ts_aneel_geracao_distribuida/server.R"

files$param_script <- "../scripts/ts_aneel_geracao_distribuida/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"

files$param_file_pt <- "../data/aneel_geracao_distribuida_dic.csv"
files$param_file_en <- "../data/aneel_geracao_distribuida_dic_en.csv"
files$db_file <- "../data/aneel_geracao_distribuida.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/colunas padrões para os eixos do gráfico)

param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param <- param_pt
param$tables <- list(
  pt = param_pt$table,
  en = param_en$table
)
param$x_def <- "ano_cadastral" # variável padrão do eixo x
param$y_def <- "mda_potencia_instalada_kw_total" # variável padrão do eixo y
param$color_def <- "id" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "ano_cadastral" # variável padrão do slider
param$text_def <- "id" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$id_def <- "id" # variável padrão de id
param$group <- "id" # variável de agrupamento

param$plot_name <- "Data Zoom Amazônia"
param$link <- "https://datazoom.shinyapps.io/app_ts_aneel_geracao_distribuida/"

param$i18n <- list(
  pt = list(
    plot_desc             = "Dados compilados da Agência Nacional de Energia Elétrica (ANEEL)",
    label_y_name          = "Eixo vertical (y)",
    label_region_name     = "Selecione recorte regional",
    label_var_name        = "FILTROS:",
    label_type_name       = "Modalidade de empreendimento",
    label_source_name     = "Fonte de geração",
    label_size_name       = "Porte do empreendimento",
    subtitle_init         = "por recorte regional e filtrado por ",
    subtitle_sep          = "e",
    filter_def            = c("Amazônia Legal", "Fora da Amazônia Legal"),
    filter_modalidade_def = "Microgeração ou Minigeração distribuída",
    filter_fonte_def      = "Radiação solar",
    filter_porte_def      = "Microgeração",
    server_empty          = "Variável no eixo Y não selecionada",
    tooltip_year          = "Ano",
    tooltip_modalidade    = "Modalidade de empreendimento",
    tooltip_fonte         = "Fonte de geração",
    tooltip_porte         = "Porte",
    tooltip_unit          = "Unidade de medida"
  ),
  en = list(
    plot_desc             = "Data compiled from the National Agency of Electrical Energy (ANEEL)",
    label_y_name          = "Vertical axis (y)",
    label_region_name     = "Select regions of interest",
    label_var_name        = "FILTERS:",
    label_type_name       = "Type of enterprise",
    label_source_name     = "Generation source",
    label_size_name       = "Size of enterprise",
    subtitle_init         = "by regions of interest and filtered by ",
    subtitle_sep          = "and",
    filter_def            = c("Legal Amazon", "Outside Legal Amazon"),
    filter_modalidade_def = "Microgeneration or Distributed Minigeneration",
    filter_fonte_def      = "Solar Radiation",
    filter_porte_def      = "Microgeneration",
    server_empty          = "No Y-axis variable selected",
    tooltip_year          = "Year",
    tooltip_modalidade    = "Type of enterprise",
    tooltip_fonte         = "Generation source",
    tooltip_porte         = "Size",
    tooltip_unit          = "Unit of measurement"
  )
)

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL
param$y_choices[[1]] <- NULL
param$color_choices[[1]] <- NULL


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
