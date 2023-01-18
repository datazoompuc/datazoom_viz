# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Cache
cache_folder <- "./cache/app_rk_comex_exp_munic_produtosamz/"
shinyOptions(cache = cachem::cache_disk(cache_folder))
# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/rk_comex_exp_munic_produtosamz/ui.R"
files$server_script <- "scripts/rk_comex_exp_munic_produtosamz/server.R"
files$param_script <- "scripts/rk_comex_exp_munic_produtosamz/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/comex_exp_sh4_munic_dic_en.csv"
files$db_file <- "data/comex_exp_sh4_munic.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "value" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "The municipalities who are the biggest product exporters of the Legal Amazon"

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL
param$x_choices$Comex <- list(param$x_choices$Comex$`Coconuts, Brazil nuts and cashew nuts, fresh or dried, whether or not shelled or peeled`, 
                              param$x_choices$Comex$`Cocoa beans, whole or broken, raw or roasted`,
                              param$x_choices$Comex$`Rough Wood, whether or not stripped of bark or sapwood, or roughly squared`
)

#Mudanças específicas no server

param$label_no_variable<- "No variable selected"
param$ranking_intro<- "Ranking of "
param$label_amazon<- "Legal Amazon"

#Mudanças específicas no UI

param$label_variable<- "VARIABLES"
param$label_x_choice_rk<- "Ranking - horizontal axis (x):"
param$color_bar<- "Bar Colors :"
param$link<-"https://datazoom.shinyapps.io/app_rk_comex_exp_munic_produtosamz_en/"


#Mudanças específicas no UI

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
