# Cache
cache_folder <- "./cache/app_rk_comex_exp_munic_produtosamz/"
shinyOptions(cache = cachem::cache_disk(cache_folder))

# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/rk_comex_exp_munic_produtosamz/ui.R"
files$server_script <- "scripts/rk_comex_exp_munic_produtosamz/server.R"
files$param_script <- "scripts/rk_comex_exp_munic_produtosamz/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/comex_exp_sh4_munic_dic.csv"
files$db_file <- "data/comex_exp_sh4_munic.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/colunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "value" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id
param$lang <- FALSE

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "municípios que mais exportam produtos da Amazônia Legal"

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL
param$x_choices$Comex <- list(param$x_choices$Comex$`Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados`, 
                              param$x_choices$Comex$`Cacau inteiro ou partido, em bruto ou torrado`,
                              param$x_choices$Comex$`Madeira em bruto, mesmo descascada, desalburnada ou esquadriada`
                              )
#Mudanças específicas no server
param$label_no_variable<- paste0("Variável não selecionada")
param$x_label<- "Valor"
param$ranking_intro<- "Ranking de"
param$label_amazon<- paste0("Amazônia Legal")

#Mudanças específicas no UI

param$label_variable<- "VARI\u00C1VEIS:"
param$label_x_choice_rk<- "Ranking - eixo horizontal (x):"
param$color_bar<- "Cor das barras:"
param$link<-"https://datazoom.shinyapps.io/app_rk_comex_exp_munic_produtosamz/"


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
