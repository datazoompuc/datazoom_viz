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
files$param_file <- "data/comex_exp_perc_sh4_sel_dic.csv"
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
param$plot_desc <- "Com\u00edrcio exterior na Amaz\u00f4nia (COMEX): Valor da exporta\u00e7\u00e3o de produtos"

# Outros parâmetros e configurações
param$filter_choices <- c("Produtos Compat\u00edveis com a Floresta", "Todos os Produtos")
param$filter_def <- c("Produtos Compat\u00edveis com a Floresta")


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
