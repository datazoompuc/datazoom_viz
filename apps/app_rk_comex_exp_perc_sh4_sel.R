# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)
library(shinyWidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/rk_comex_exp_perc_sh4_sel/ui.R"
files$server_script <- "../scripts/rk_comex_exp_perc_sh4_sel/server.R"
files$param_script <- "../scripts/rk_comex_exp_perc_sh4_sel/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/comex_exp_perc_sh4_sel_dic.csv"
files$param_file_en <- "../data/comex_exp_perc_sh4_sel_dic_en.csv"
files$db_file <- "../data/comex_exp_perc_sh4_sel.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param          <- param_pt
param$tables   <- list(pt = param_pt$table, en = param_en$table)

param$x_def <- "value" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id

# Textos internacionalizados
param$i18n <- list(
  pt = list(
    plot_name      = "Data Zoom Amazônia",
    plot_desc      = "Comércio exterior na Amazônia (COMEX) em relação ao comércio internacional (BACI): Proporção do valor da exportação de produtos",
    filter_choices = c("Todos os Produtos", "Produtos Compatíveis com a Floresta"),
    ui1            = "VARIÁVEIS:",
    ui2            = "Tipos de Produto:",
    ui4            = "Ano: ",
    ui5            = "Estado (UF)",
    uf_all         = "Todos",
    btn_lang       = "English",
    server1        = "Variável não selecionada",
    server2        = "Ranking da Proporção das Exportações Mundiais Vindas da Amazônia",
    server3        = "Amazônia Legal",
    server4        = "Unidade de medida: <b>"
  ),
  en = list(
    plot_name      = "Data Zoom Amazônia",
    plot_desc      = "Foreign trade (COMEX) in the Amazon compared to international commerce (BACI): Proportion of products' export values",
    filter_choices = c("All products", "Products Compatible with the Forest"),
    ui1            = "VARIABLES:",
    ui2            = "Product types:",
    ui4            = "Year: ",
    ui5            = "State",
    uf_all         = "All",
    btn_lang       = "Português",
    server1        = "No variable selected",
    server2        = "Proportions of world exports coming from the Amazon Ranking",
    server3        = "Legal Amazon",
    server4        = "Measurement Unit: <b>"
  )
)

# URL de fullscreen
param$ui3 <- "https://datazoom.shinyapps.io/app_rk_comex_exp_perc_sh4_sel/"

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
