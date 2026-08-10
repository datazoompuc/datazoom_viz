# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)
library(shinyWidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/hist_mapbiomas_bovinos/ui.R"
files$server_script <- "../scripts/hist_mapbiomas_bovinos/server.R"
files$param_script <- "../scripts/hist_mapbiomas_bovinos/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file_pt <- "../data/dz_munic_ppm_mapbiomas_dic.csv"
files$param_file_en <- "../data/dz_munic_ppm_mapbiomas_dic_en.csv"
files$db_file <- "../data/dz_munic_ppm_mapbiomas.rds"

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

param$x_def <- "n_bovino_por_area_pastagem" # variável distribuída no eixo x (o y é a contagem)
param$slider_def <- "ano" # variável padrão do slider

param$plot_name <- "Data Zoom Amazônia"
param$link <- "https://datazoom.shinyapps.io/app_hist_mapbiomas_bovinos/"

# Carrega a base uma única vez por processo (e não por sessão)
df <- load_db(files$db_file)

# Chaves neutras dos recortes geográficos: são as mesmas da base, o que permite
# trocar de idioma sem perder a seleção do usuário nem duplicar o .rds
param$geo_keys <- list(
  amazonia = c("AMZ_IN", "AMZ_OUT"),
  regioes = c("R_CO", "R_NE", "R_N", "R_SE", "R_S"),
  estados = levels(df$uf)
)
param$geo_def <- c("AMZ_IN", "AMZ_OUT")

param$i18n <- list(
  pt = list(
    plot_desc       = "Distribuição dos municípios de acordo com o rebanho bovino por hectare de pastagem",
    label_var_name  = "VARIÁVEIS:",
    label_geo_name  = "Subdivisões Geográficas",
    label_scales    = "OPÇÕES DE ESCALA:",
    label_log_name  = "escala log(x+1)",
    slider_prefix   = "Ano: ",
    group_amazonia  = "Amazônia Legal",
    group_regioes   = "Regiões",
    group_estados   = "Estados",
    geo_labels      = c(AMZ_IN = "Amazônia Legal", AMZ_OUT = "Fora da Amazônia Legal",
                        R_N = "Norte", R_NE = "Nordeste", R_CO = "Centro-Oeste",
                        R_SE = "Sudeste", R_S = "Sul"),
    subtitle        = "Distribuição dos Municípios",
    label_count     = "Número de Municípios",
    fmt_log         = "Log(%s + 1)",
    btn_lang        = "English",
    btn_fullscreen  = "Fullscreen"
  ),
  en = list(
    plot_desc       = "Distribution of municipalities by cattle herd per hectare of pasture",
    label_var_name  = "VARIABLES:",
    label_geo_name  = "Geographical Subdivisions",
    label_scales    = "SCALE OPTIONS:",
    label_log_name  = "log scale (x+1)",
    slider_prefix   = "Year: ",
    group_amazonia  = "Legal Amazon",
    group_regioes   = "Regions",
    group_estados   = "States",
    geo_labels      = c(AMZ_IN = "Legal Amazon", AMZ_OUT = "Outside of the Legal Amazon",
                        R_N = "North", R_NE = "Northeast", R_CO = "Midwest",
                        R_SE = "Southeast", R_S = "South"),
    subtitle        = "Distribution of Municipalities",
    label_count     = "Number of Municipalities",
    fmt_log         = "Log(%s + 1)",
    btn_lang        = "Português",
    btn_fullscreen  = "Fullscreen"
  )
)

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param, df)

shinyApp(ui = ui, server = server)
