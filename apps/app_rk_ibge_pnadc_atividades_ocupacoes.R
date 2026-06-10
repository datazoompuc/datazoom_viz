# Cache
cache_folder <- "./cache/app_rk_ibge_pnadc_atividades_ocupacoes/"
shinyOptions(cache = cachem::cache_disk(cache_folder))

# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script     <- "../scripts/rk_ibge_pnadc_atividades_ocupacoes/ui.R"
files$server_script <- "../scripts/rk_ibge_pnadc_atividades_ocupacoes/server.R"
files$param_script  <- "../scripts/ts_ibge_pnadc_cnae/db_params.R"
files$CSS_script    <- "../global/dza_lumen.css"
files$param_file    <- "../data/ibge_pnadc_atividades_ocupacoes_rk_dic.csv"
files$db_file       <- "../data/ibge_pnadc_atividades_ocupacoes.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização
param <- get_db_param(files$param_file, files$db_file)
param$x_def      <- "ocupado"
param$y_def      <- ""
param$slider_def <- "time"
param$color_def  <- "composicao_demografica"
param$text_def   <- "composicao_demografica"
param$group      <- "composicao_demografica"
param$id_def     <- "composicao_demografica"

### Parâmetros específicos no UI
param$label_var_name  <- "VARIÁVEIS:"
param$label_x_name    <- "Eixo horizontal (x)"
param$label_region_name <- "Recorte regional"
param$label_sector_name <- "Setor"
param$label_type_name   <- "Atividade / Ocupação"
param$link <- "https://datazoom.shinyapps.io/app_rk_ibge_pnadc_atividades_ocupacoes/"

### Parâmetros específicos no server
param$title_init    <- "Ranking"
param$subtitle_cnae <- "por atividade econômica"
param$subtitle_cod  <- "por ocupação"

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "Mercado de Trabalho"

param$x_choices[[1]] <- NULL

param$filter_choices <- list(
    "Brasil"         = list("Brasil", ""),
    "Amazônia Legal" = list("Amazônia Legal", "Fora da Amazônia Legal"),
    "Região"   = list("Norte", "Nordeste", "Sudeste", "Sul", "Centro-Oeste"),
    "UF" = list(
        "RO", "AC", "AM", "PA", "AP", "TO",
        "MA", "PI", "CE", "RN", "PB", "PE", "AL",
        "SE", "BA", "MG", "ES", "RJ", "SP", "PR",
        "SC", "RS", "MS", "MT", "GO", "DF"
    )
)
param$group_def <- "Brasil"

param$type_choices <- list(
    "Atividade Econômica" = "CNAE",
    "Ocupação"       = "COD"
)
param$type_def <- "CNAE"

param$sector_choices <- list(
    "Todos"    = "todos",
    "Formal"   = "formal",
    "Informal" = "informal",
    "Público"  = "publico",
    "Privado"  = "privado"
)
param$sector_def <- "formal"

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui     <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
