# Cache
cache_folder <- "./cache/app_rk_ibge_pnadc_cod/"
shinyOptions(cache = cachem::cache_disk(cache_folder))

# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/rk_ibge_pnadc_cnae/ui.R"
files$server_script <- "../scripts/rk_ibge_pnadc_cnae/server.R"
files$param_script <- "../scripts/ts_ibge_pnadc_cnae/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file <- "../data/ibge_pnadc_cod_rk_dic.csv"
files$db_file <- "../data/ibge_pnadc_cod.rds"

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

### Parametros especificos no UI
param$label_var_name <- "VARIÁVEIS:"
param$label_x_name <- "eixo horizontal (x)"

param$label_region_name <- "Recorte regional"
param$label_sector_name <- "Setor"
param$link <- "https://datazoom.shinyapps.io/app_rk_ibge_pnadc_cod/"

### Parametros especificos no server
param$title_init <- "Ranking" # expressão titulo
param$subtitle_init <- "por ocupação" # expressão subtitulo

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Mercado de Trabalho"

# Outros parâmetros e configurações

param$x_choices[[1]] <- NULL

param$filter_choices <- list(
    "Brasil" = list("Brasil", ""),
    "Amaz\u00f4nia Legal" = list("Amaz\u00f4nia Legal", "Fora da Amaz\u00f4nia Legal"),
    "Regi\u00e3o" = list("Norte", "Nordeste", "Sudeste", "Sul", "Centro-Oeste"),
    "UF" = list(
        "RO", "AC", "AM", "RO", "PA", "AP", "TO",
        "MA", "PI", "CE", "RN", "PB", "PE", "AL",
        "SE", "BA", "MG", "ES", "RJ", "SP", "PR",
        "SC", "RS", "MS", "MT", "GO", "DF"
    )
)

param$group_def <- "Brasil"

param$sector_choices <- list(
    "Todos" = "todos",
    "Formal" = "formal",
    "Informal" = "informal",
    "Público" = "publico",
    "Privado" = "privado"
)

param$sector_def <- "formal"

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
