# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script     <- "../scripts/ts_comex_exp_pais_sec/ui.R"
files$server_script <- "../scripts/ts_comex_exp_pais_sec/server.R"
files$param_script  <- "../scripts/ts_comex_exp_pais_sec/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

# Dois recortes (transpostas) do mesmo cubo País x Seção:
#   pais_sec -> "fixar seção": eixo y = seção (SEC), linhas/filtro = países
#   sec_pais -> "fixar país" : eixo y = país,        linhas/filtro = seções (SEC)
files$db_file_pais_sec <- "../data/comex_exp_pais_sec.rds"
files$db_file_sec_pais <- "../data/comex_exp_sec_pais.rds"

files$param_pais_sec_pt <- "../data/comex_exp_pais_sec_dic.csv"
files$param_pais_sec_en <- "../data/comex_exp_pais_sec_dic_en.csv"
files$param_sec_pais_pt <- "../data/comex_exp_sec_pais_dic.csv"
files$param_sec_pais_en <- "../data/comex_exp_sec_pais_en_dic.csv"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização
p_pais_sec_pt <- get_db_param(files$param_pais_sec_pt, files$db_file_pais_sec)
p_pais_sec_en <- get_db_param(files$param_pais_sec_en, files$db_file_pais_sec)
p_sec_pais_pt <- get_db_param(files$param_sec_pais_pt, files$db_file_sec_pais)
p_sec_pais_en <- get_db_param(files$param_sec_pais_en, files$db_file_sec_pais)

param <- p_pais_sec_pt

# Tabelas de parâmetros por recorte e idioma (var sempre em PT; só o label muda)
param$tables <- list(
  pais_sec = list(pt = p_pais_sec_pt$table, en = p_pais_sec_en$table),
  sec_pais = list(pt = p_sec_pais_pt$table, en = p_sec_pais_en$table)
)

# Mapas de tradução dos valores do filtro (coluna `group` do .rds, em PT).
# Com os datasets agora completos e consistentes entre as transpostas, cada dicionário EN
# transposto (var em PT -> label em EN) já é o mapa PT -> EN:
#  - modo pais_sec: filtro = país  -> dicionário de sec_pais
#  - modo sec_pais: filtro = seção -> dicionário de pais_sec
filter_map_from <- function(tbl) {
  rows <- tbl[!(tbl$var %in% c("time", "group")), ]
  setNames(rows$label, rows$var)
}
param$filter_labels_en <- list(
  pais_sec = filter_map_from(p_sec_pais_en$table),
  sec_pais = filter_map_from(p_pais_sec_en$table)
)

# Variáveis/colunas padrão dos eixos
param$x_def     <- "time"  # variável padrão do eixo x
param$y_def     <- ""      # variável padrão do eixo y
param$color_def <- "group" # variável padrão de cor
param$text_def  <- "group"
param$group     <- "group"

param$link <- "https://datazoom.shinyapps.io/app_ts_comex_exp_pais_sec/"
param$plot_name <- "Data Zoom Amazônia"

# Seleção inicial (países/seção com números relevantes para a Amazônia)
param$defaults <- list(
  countries = c("China", "Estados Unidos"),
  sections  = c("Produtos minerais")
)

# Internacionalização (textos + labels específicos de cada recorte)
param$i18n <- list(
  pt = list(
    plot_desc         = "Comércio exterior na Amazônia (COMEX): valor da exportação por país de destino",
    label_var_name    = "VARIÁVEIS:",
    label_scale_name  = "Escala log",
    label_prop_name   = "Proporcional ao ano inicial",
    role_y_prefix     = "Eixo Y: ",
    role_lines_prefix = "Linhas: ",
    label_swap        = "Inverter eixos",
    btn_lang          = "English",
    btn_fullscreen    = "Fullscreen",
    currency          = "Em US$",
    measurement       = "US$",
    translate         = FALSE,
    pais_sec = list(label_y = "Seção de produtos (SEC)", label_filter = "Países de destino",
                    dim_y = "Seção (SEC)", dim_lines = "Países"),
    sec_pais = list(label_y = "País de destino", label_filter = "Seções de produtos (SEC)",
                    dim_y = "País", dim_lines = "Seções (SEC)")
  ),
  en = list(
    plot_desc         = "External trade in the Amazon (COMEX): export value by destination country",
    label_var_name    = "VARIABLES:",
    label_scale_name  = "Log scale",
    label_prop_name   = "Proportional to the initial year",
    role_y_prefix     = "Y axis: ",
    role_lines_prefix = "Lines: ",
    label_swap        = "Swap axes",
    btn_lang          = "Português",
    btn_fullscreen    = "Fullscreen",
    currency          = "In US$",
    measurement       = "US$",
    translate         = TRUE,
    pais_sec = list(label_y = "Product section (SEC)", label_filter = "Destination countries",
                    dim_y = "Section (SEC)", dim_lines = "Countries"),
    sec_pais = list(label_y = "Destination country", label_filter = "Product sections (SEC)",
                    dim_y = "Country", dim_lines = "Sections (SEC)")
  )
)

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
