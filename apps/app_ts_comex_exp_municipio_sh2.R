# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script     <- "../scripts/ts_comex_exp_municipio_sh2/ui.R"
files$server_script <- "../scripts/ts_comex_exp_municipio_sh2/server.R"
files$param_script  <- "../scripts/ts_comex_exp_municipio_sh2/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

# Dois recortes (transpostas) de Município x Produto (SH2):
#   munic_sh2 -> "Eixo Y: Município": y = município, linhas = produtos (SH2)
#   sh2_munic -> "Eixo Y: Produto"  : y = produto (SH2), linhas = municípios
files$db_file_munic_sh2 <- "../data/comex_exp_munic_sh2.rds"
files$db_file_sh2_munic <- "../data/comex_exp_sh2_munic.rds"

files$param_munic_sh2_pt <- "../data/comex_exp_munic_sh2_dic.csv"
files$param_munic_sh2_en <- "../data/comex_exp_munic_sh2_en_dic.csv"
files$param_sh2_munic_pt <- "../data/comex_exp_sh2_munic_dic.csv"
files$param_sh2_munic_en <- "../data/comex_exp_sh2_munic_en_dic.csv"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização
p_munic_sh2_pt <- get_db_param(files$param_munic_sh2_pt, files$db_file_munic_sh2)
p_munic_sh2_en <- get_db_param(files$param_munic_sh2_en, files$db_file_munic_sh2)
p_sh2_munic_pt <- get_db_param(files$param_sh2_munic_pt, files$db_file_sh2_munic)
p_sh2_munic_en <- get_db_param(files$param_sh2_munic_en, files$db_file_sh2_munic)

param <- p_munic_sh2_pt

param$tables <- list(
  munic_sh2 = list(pt = p_munic_sh2_pt$table, en = p_munic_sh2_en$table),
  sh2_munic = list(pt = p_sh2_munic_pt$table, en = p_sh2_munic_en$table)
)

# Mapas de tradução dos valores (coluna `group` do .rds, em PT):
# - modo munic_sh2: usa o dicionário EN transposto
# - modo sh2_munic: filtro = município (nome próprio e sem tradução)
filter_map_from <- function(tbl) {
  rows <- tbl[!(tbl$var %in% c("time", "group")), ]
  setNames(rows$label, rows$var)
}
param$filter_labels_en <- list(
  munic_sh2 = filter_map_from(p_sh2_munic_en$table),
  sh2_munic = setNames(character(0), character(0))
)

# Variáveis padrão dos eixos
param$x_def     <- "time"
param$y_def     <- ""
param$color_def <- "group"
param$text_def  <- "group"
param$group     <- "group"

param$link <- "https://datazoom.shinyapps.io/app_ts_comex_exp_municipio_sh2/"
param$plot_name <- "Data Zoom Amazônia"

# Seleção inicial
param$defaults <- list(
  munis = c("Manaus - AM"),
  products = c(
    "Máquinas, aparelhos e materiais elétricos, e suas partes; aparelhos de gravação ou de reprodução de som, aparelhos de gravação ou de reprodução de imagens e de som em televisão, e suas partes e acessórios",
    "Preparações alimentícias diversas"
  )
)

# Internacionalização
param$i18n <- list(
  pt = list(
    plot_desc         = "Comércio exterior na Amazônia (COMEX): valor da exportação por município",
    label_var_name    = "VARIÁVEIS:",
    label_scale_name  = "Escala log",
    label_prop_name   = "Proporcional ao ano inicial",
    role_y_prefix     = "Eixo Y: ",
    role_lines_prefix = "Linhas: ",
    label_swap        = "Inverter eixos",
    label_y_axis      = "Valor exportado",
    btn_lang          = "English",
    btn_fullscreen    = "Fullscreen",
    currency          = "Em US$",
    measurement       = "US$",
    translate         = FALSE,
    munic_sh2 = list(label_y = "Município da Amazônia", label_filter = "Produtos (capítulo SH2)",
                     dim_y = "Município", dim_lines = "Produtos (SH2)"),
    sh2_munic = list(label_y = "Produto (capítulo SH2)", label_filter = "Municípios da Amazônia",
                     dim_y = "Produto (SH2)", dim_lines = "Municípios")
  ),
  en = list(
    plot_desc         = "External trade in the Amazon (COMEX): export value by municipality",
    label_var_name    = "VARIABLES:",
    label_scale_name  = "Log scale",
    label_prop_name   = "Proportional to the initial year",
    role_y_prefix     = "Y axis: ",
    role_lines_prefix = "Lines: ",
    label_swap        = "Swap axes",
    label_y_axis      = "Export value",
    btn_lang          = "Português",
    btn_fullscreen    = "Fullscreen",
    currency          = "In US$",
    measurement       = "US$",
    translate         = TRUE,
    munic_sh2 = list(label_y = "Amazon municipality", label_filter = "Products (HS2 chapter)",
                     dim_y = "Municipality", dim_lines = "Products (HS2)"),
    sh2_munic = list(label_y = "Product (HS2 chapter)", label_filter = "Amazon municipalities",
                     dim_y = "Product (HS2)", dim_lines = "Municipalities")
  )
)

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
