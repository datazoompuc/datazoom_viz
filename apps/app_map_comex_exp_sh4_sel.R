# Carrega bibliotecas
library(shiny)
library(tidyverse)
library(leaflet)
library(sf)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/map_comex_exp_sh4_sel/ui.R"
files$server_script <- "../scripts/map_comex_exp_sh4_sel/server.R"
files$param_script <- "../scripts/map_comex_exp_sh4_sel/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/comex_exp_munic_sh4_sel_dic.csv"
files$param_file_en <- "../data/comex_exp_munic_sh4_sel_dic_en.csv"
files$db_file <- "../data/comex_exp_munic_sh4_sel.rds"
files$aux_file <- "../data/auxiliar_cod_sh4.rds"   # nomes SH4/SH2 em PT e EN

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (PT como idioma padrão)
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param        <- param_pt
param$tables <- list(pt = param_pt$table, en = param_en$table)

# Colunas padrão para os eixos/dimensões
param$x_def      <- "all"      # valor (idioma-independente) do seletor x
param$slider_def <- "time"
param$text_def   <- "group"
param$id_def     <- "cod_ibge"

# Ano inicial/final derivados do próprio dado (evita hardcode)
.time_vals <- readRDS(files$db_file)$time
param$year_inicio <- min(.time_vals, na.rm = TRUE)
param$year_final  <- max(.time_vals, na.rm = TRUE)

# Nome do app (igual nos dois idiomas)
param$plot_name <- "Data Zoom Amazônia"
param$link <- "https://datazoom.shinyapps.io/app_map_comex_exp_sh4_sel/"

# Textos internacionalizados (PT / EN)
param$i18n <- list(
  pt = list(
    plot_desc      = "Comércio exterior na Amazônia (COMEX): Valor da exportação de produtos",
    topo           = "VARIÁVEIS:",
    varxlabel      = "Tipo de produto:",
    vardatelabel   = "Ano referente",
    # opções do seletor x (valores fixos: forest/all/razao)
    x_forest       = "Produtos Compatíveis com a Floresta",
    x_all          = "Todos os Produtos",
    x_razao        = "Razão: Floresta / Outros produtos",
    titulo1        = "Mapa dos municípios da Amazônia Legal",
    titulo2        = "Nenhuma variável selecionada",
    titulo3        = "Principal produto exportado: ",
    tooltip1       = "Nome do município:",
    tooltip2       = "Estado:",
    tooltip3       = "Principal Produto:",
    tooltip4       = "Categoria do Principal Produto:",
    tooltip5       = "Valor: ",
    tooltip6       = "Unidade de medida:",
    tooltip7       = "% das exportações do produto vindas da Amazônia no ano",
    legend         = "Categoria do Principal Produto",
    # classes da visão "Razão"
    ratio_same     = "Mesmo produto",
    ratio_nao      = "Principal produto não compatível",
    ratio_sim      = "Principal produto compatível",
    btn_lang       = "English",
    btn_fullscreen = "Fullscreen"
  ),
  en = list(
    plot_desc      = "Foreign trade in the Amazon: Value of the product's export",
    topo           = "VARIABLES:",
    varxlabel      = "Product type:",
    vardatelabel   = "Reference year",
    x_forest       = "Forest Compatible Products",
    x_all          = "All Products",
    x_razao        = "Ratio: Forest / Other products",
    titulo1        = "Legal Amazon's municipalities map",
    titulo2        = "No variable selected",
    titulo3        = "Main exported product: ",
    tooltip1       = "Municipality name:",
    tooltip2       = "State:",
    tooltip3       = "Main product:",
    tooltip4       = "Main product's category:",
    tooltip5       = "Value: ",
    tooltip6       = "Unit measure:",
    tooltip7       = "% of the product's exports that came from the Amazon in the reference year",
    legend         = "Main Product's Category",
    ratio_same     = "Same product",
    ratio_nao      = "Main product not compatible",
    ratio_sim      = "Main product compatible",
    btn_lang       = "Português",
    btn_fullscreen = "Fullscreen"
  )
)

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
