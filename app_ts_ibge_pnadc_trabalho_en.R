# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "ts_ibge_pnadc_trabalho/ui.R"
files$server_script <- "ts_ibge_pnadc_trabalho/server.R"
files$param_script <- "ts_ibge_pnadc_trabalho/db_params.R"
files$CSS_script <- "global/dza_lumen.css"
files$param_file <- "ts_ibge_pnadc_trabalho/ibge_pnadc_trabalho_dic_en.csv"
files$db_file <- "ts_ibge_pnadc_trabalho/ibge_pnadc_trabalho_en.rds"

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
param$plot_desc <- "Labor Market"

### Parametros especificos no UI
param$label_var_name <-  "VARIABLES:"
param$label_y_name <- "Vertical axis (y)"
param$label_geo_name <-  "Select region"
param$label_comp_name <-  "Select groups"

param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_trabalho_en/"

### Parametros especificos no server
param$subtitle_init <- "by region and " # expressão subtitulo
param$tooltip <- "Group: "  #expressão html
param$lang <- TRUE


# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL
param$y_choices[[1]] <- NULL
param$color_choices[[1]] <- NULL

##
param$filter_choices <- list(
    "Brazil" = list("Brazil", ""),
    "Legal Amazon" = list("Legal Amazon", "Outside Legal Amazon"),
    "Regions" = list("North", "Northeast", "Southeast", "South", "Central-West"),
    "UF" = list("RO", "AC", "AM", "RO", "PA", "AP", "TO",
                "MA", "PI", "CE", "RN", "PB", "PE", "AL",
                "SE", "BA", "MG", "ES", "RJ", "SP", "PR",
                "SC", "RS", "MS", "MT", "GO", "DF")
)

param$filter_composicao_demografica_choices <- list(
    "All" = list("All", ""),
    "Sex" = list("Male", "Female"),
    "Age Group" = list("Between 14 and 17",
                               "Between 18 and 24",
                               "Between 25 and 29",
                               "Between 30 and 39",
                               "Between 40 and 49",
                               "Between 50 and 59",
                               "60 or older"),
    "Schooling" = list("No formal education",
                          "1-7 years of schooling",
                          "8-11 years of schooling",
                          "9-14 years of schooling",
                          "15 or more years of schooling")
)

param$filter_geo_def <- list("Legal Amazon", "Outside Legal Amazon")

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
