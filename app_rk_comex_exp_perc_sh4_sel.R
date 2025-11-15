# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/rk_comex_exp_perc_sh4_sel/ui.R"
files$server_script <- "scripts/rk_comex_exp_perc_sh4_sel/server.R"
files$param_script <- "scripts/rk_comex_exp_perc_sh4_sel/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/comex_exp_perc_sh4_sel_dic.csv"
files$db_file <- "data/comex_exp_perc_sh4_sel.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/colunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "value" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Com\u00e9rcio exterior na Amaz\u00f4nia (COMEX) em rela\u00e7\u00e3o ao comércio internacional (BACI): Propor\u00e7\u00e3o do valor da exporta\u00e7\u00e3o de produtos"

# Outros parâmetros e configurações
param$filter_choices <- c("Todos os Produtos", "Produtos Compat\u00edveis com a Floresta")
param$filter_def <- c("Todos os Produtos")

# Parâmetros específicos do UI
param$ui1 <- "VARI\u00C1VEIS:"
param$ui2 <- "Tipos de Produto:"
param$ui3 <- "https://datazoom.shinyapps.io/app_rk_comex_exp_perc_sh4_sel/"
param$ui4 <- "Ano: "

# Parâmetros específicos do server
param$server1 <- "Vari\u00e1vel n\u00e3o selecionada"
param$server2 <- "Ranking da Propor\u00e7\u00e3o das Exporta\u00e7\u00f5es Mundiais Vindas da Amaz\u00f4nia"
param$server3 <- "Amaz\u00f4nia Legal"
param$server4 <- "Unidade de medida: <b>"
param$lang <- FALSE

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
