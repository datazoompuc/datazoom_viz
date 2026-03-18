# Cache
cache_folder <- "./cache/app_rk_ibge_pnadc_cnae_en/"
shinyOptions(cache = cachem::cache_disk(cache_folder))

# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "rk_ibge_pnadc_cnae/ui.R"
files$server_script <- "rk_ibge_pnadc_cnae/server.R"
files$param_script <- "rk_ibge_pnadc_cnae/db_params.R"
files$CSS_script <- "global/dza_lumen.css"
files$param_file <- "rk_ibge_pnadc_cnae/ibge_pnadc_cnae_rk_dic_en.csv"
files$db_file <- "rk_ibge_pnadc_cnae/ibge_pnadc_cnae.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "ocupado" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "composicao_demografica" # variável padrão de cor
param$text_def <- "composicao_demografica" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "composicao_demografica" # variável de agrupamento
param$id_def <- "composicao_demografica" # variável padrão de id

# Parâmetros específicos do UI
param$label_var_name <- "VARIABLES:"
param$label_x_name <- "Ranking - horizontal axis (x):"

param$label_region_name <- "Region"
param$label_sector_name <- "Sector"
param$link <- "https://datazoom.shinyapps.io/app_rk_ibge_pnadc_cnae_en/"

# Parâmetros específicos do server
param$novar <- "No variable selected"
param$title_init <- "Ranking of "
param$subtitle_init <- "by economic activity"
param$lang <- TRUE

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Economic Activities - Aggregated data of municipalities in the Legal Amazon (Source: IBGE)"

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

param$filter_choices <- list(
    "Brazil" = list("Brazil", ""),
    "Legal Amazon" = list("Legal Amazon", "Outside the Legal Amazon"),
    "Region" = list("North", "Northeast", "Southeast", "South", "Central-West"),
    "UF" = list(
        "RO", "AC", "AM", "RO", "PA", "AP", "TO",
        "MA", "PI", "CE", "RN", "PB", "PE", "AL",
        "SE", "BA", "MG", "ES", "RJ", "SP", "PR",
        "SC", "RS", "MS", "MT", "GO", "DF"
    )
)

param$group_def <- "Brasil"

param$sector_choices <- list(
    "All" = "all",
    "Formal" = "formal",
    "Informal" = "informal",
    "Public" = "public",
    "Private" = "private"
)

param$sector_def <- "formal"

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
