# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/sankey/ui.R"
files$server_script <- "../scripts/sankey/server.R"
files$param_script <- "../scripts/sankey/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file_pt <- "../data/comex_exp_pais_sec_dic.csv"
files$param_file_en <- "../data/comex_exp_pais_sec_dic_en.csv"
files$db_file <- "../data/comex_exp_pais_sec.rds"
files$aux_pais_file <- "../data/auxiliar_cod_pais.rds"   # SISCOMEX, NO_PT, NO_EN

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (PT como idioma padrão)
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param        <- param_pt
param$tables <- list(pt = param_pt$table, en = param_en$table)

param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "Produtos do reino vegetal" # categoria padrão (var em PT, estável)
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto (quando mouse em cima)
param$group <- "group" # variável de agrupamento

param$plot_name <- "Data Zoom Amazônia"
param$link <- "https://datazoom.shinyapps.io/app_sankey_comex_exp_pais_sec/"

# Ano inicial/final derivados do próprio dado
.time_vals <- readRDS(files$db_file)$time
param$year_inicio <- min(.time_vals, na.rm = TRUE)
param$year_final  <- max(.time_vals, na.rm = TRUE)

# Textos internacionalizados (PT / EN)
param$i18n <- list(
  pt = list(
    plot_desc         = "Comércio exterior na Amazônia (COMEX): Valor da exportação de produtos por país de destino",
    label_var_name    = "VARIÁVEIS:",
    label_x_name      = "Ano",
    label_colour_name = "Categoria de exportação (Agregação da SEC)",
    unit              = "Milhões de ",
    unit2             = " em ",
    btn_lang          = "English",
    btn_fullscreen    = "Fullscreen"
  ),
  en = list(
    plot_desc         = "External trade in the Amazon (COMEX): Products export value per destination country",
    label_var_name    = "VARIABLES:",
    label_x_name      = "Year",
    label_colour_name = "Export Category (SEC aggregation)",
    unit              = "Millions of ",
    unit2             = " in ",
    btn_lang          = "Português",
    btn_fullscreen    = "Fullscreen"
  )
)

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
