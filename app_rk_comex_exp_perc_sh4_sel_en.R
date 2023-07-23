# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/rk_comex_exp_perc_sh4_sel/ui.R"
files$server_script <- "scripts/rk_comex_exp_perc_sh4_sel/server.R"
files$param_script <- "scripts/rk_comex_exp_perc_sh4_sel/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/comex_exp_perc_sh4_sel_dic_en.csv"
files$db_file <- "data/comex_exp_perc_sh4_sel.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "value" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Foreign trade (COMEX) in the Amazon compared to international commerce (BACI): Proportion of products' export values"

# Outros parâmetros e configurações
param$filter_choices <- c("Products Compatible with the Forest", "All products")
param$filter_def <- c("Products Compatible with the Forest")

# Parâmetros específicos do UI
param$ui1 <- "VARIABLES:"
param$ui2 <- "Product types:"
param$ui3 <- "https://datazoom.shinyapps.io/app_rk_comex_exp_perc_sh4_sel_en/"

# Parâmetros específicos do server
param$server1 <- "No variable selected"
param$server2 <- "Proportions of world exports coming from the Amazon Ranking"
param$server3 <- "Legal Amazon"
param$server4 <- "Unit measure: <b>"
param$server5 <- "Year: "
param$lang <- TRUE

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
