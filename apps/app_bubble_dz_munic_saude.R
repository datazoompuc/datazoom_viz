# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(lubridate)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/bubble_dz_munic_saude/ui.R"
files$server_script <- "scripts/bubble_dz_munic_saude/server.R"
files$param_script <- "scripts/bubble/db_params.R"

files$CSS_script <- "global/dza_lumen.css"

files$param_file <- "data/dz_munic_saude_dic.csv"
files$db_file <- "data/dz_munic_saude.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "desmatado" # variável padrão do eixo x
param$y_def <- "t_total" # variável padrão do eixo y
param$color_def <- "estado" # variável padrão de cor
param$size_def <- "pop" # variável padrão de tamanho
param$slider_def <- "ano" # variável padrão do slider
param$text_def <- "nm_municip" # variável padrão de texto
param$id_def <- "cod_ibge" # variável padrão de id


param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Compila\u00e7\u00e3o de dados ao n\u00edvel municipal"

# Outros parâmetros e configurações

#Mudanças específicas no UI
param$link <- "https://datazoom.shinyapps.io/app_bubble_dz_munic_saude/"
param$variable<-"VARI\u00c1VEIS:"
param$label_x<- "eixo horizontal (x)"
param$label_y<- "eixo vertical (y)"
param$log_scale<-"escala log"
param$color_label<- "Cor do marcador:"
param$marker_size<- "Tamanho do marcador"

#Mudanças específicas no server
param$label_by<- " por "
param$label_considering<- "considerando"
param$and <- "e"
param$label_year<- "Ano: "

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
