# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_ibge_pnadc_trabalho/ui.R"
files$server_script <- "scripts/ts_ibge_pnadc_trabalho/server.R"
files$param_script <- "scripts/ts_ibge_pnadc_trabalho/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/ibge_pnadc_trabalho_dic.csv"
files$db_file <- "data/ibge_pnadc_trabalho.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "taxa_desemprego" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "composicao_demografica" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Mercado de Trabalho"

### Parametros especificos no UI
param$label_var_name <- "VARIÁVEIS:"
param$label_y_name <- "Eixo vertical (y)"
param$label_geo_name <-  "Selecione recorte regional"
param$label_comp_name <-  "Selecione grupos"
param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_trabalho/"

### Parametros especificos no server
param$subtitle_init <- "por recorte regional e " # expressão subtitulo
param$tooltip <- "Grupo: "  #expressão html
param$lang <- FALSE


# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL
param$y_choices[[1]] <- NULL
param$color_choices[[1]] <- NULL

##
param$filter_choices <- list(
    "Brasil" = list("Brasil", ""),
    "Amaz\u00f4nia Legal" = list("Amaz\u00f4nia Legal", "Fora da Amaz\u00f4nia Legal"),
    "Regi\u00e3o" = list("Norte", "Nordeste", "Sudeste", "Sul", "Centro-Oeste"),
    "UF" = list("RO", "AC", "AM", "RO", "PA", "AP", "TO",
                "MA", "PI", "CE", "RN", "PB", "PE", "AL",
                "SE", "BA", "MG", "ES", "RJ", "SP", "PR",
                "SC", "RS", "MS", "MT", "GO", "DF")
)

param$filter_composicao_demografica_choices <- list(
    "Todos" = list("Todos", ""),
    "Sexo" = list("Homem", "Mulher"),
    "Faixa Et\u00e1ria" = list("Entre 14 e 17 anos",
                               "Entre 18 e 24 anos",
                               "Entre 25 e 29 anos",
                               "Entre 30 e 39 anos",
                               "Entre 40 e 49 anos",
                               "Entre 50 e 59 anos",
                               "60 anos ou mais"),
    "Escolaridade" = list("Sem instru\u00e7\u00e3o",
                          "1 a 7 anos de estudo",
                          "8 a 11 anos de estudo",
                          "9 a 14 anos de estudo",
                          "15 ou mais anos de estudo")
)

param$filter_geo_def <- list("Amaz\u00f4nia Legal", "Fora da Amaz\u00f4nia Legal")

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)