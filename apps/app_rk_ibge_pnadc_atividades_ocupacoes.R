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
files$ui_script       <- "../scripts/rk_ibge_pnadc_atividades_ocupacoes/ui.R"
files$server_script   <- "../scripts/rk_ibge_pnadc_atividades_ocupacoes/server.R"
files$param_script    <- "../scripts/ts_ibge_pnadc_cnae/db_params.R"
files$CSS_script      <- "../global/dza_lumen.css"
files$param_file_pt   <- "../data/ibge_pnadc_atividades_ocupacoes_rk_dic.csv"
files$param_file_en   <- "../data/ibge_pnadc_atividades_ocupacoes_rk_dic_en.csv"
files$db_file         <- "../data/ibge_pnadc_atividades_ocupacoes.rds"
files$categories_file <- "../data/pnadc_categories.csv"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param <- param_pt
param$tables <- list(
    pt = param_pt$table,
    en = param_en$table
)

param$x_def      <- "ocupado"
param$y_def      <- ""
param$slider_def <- "time"
param$color_def  <- "composicao_demografica"
param$text_def   <- "composicao_demografica"
param$group      <- "composicao_demografica"
param$id_def     <- "composicao_demografica"

param$link <- "https://datazoom.shinyapps.io/app_rk_ibge_pnadc_atividades_ocupacoes/"

param$i18n <- list(
    pt = list(
        plot_name      = "Data Zoom Amazônia",
        plot_desc      = "Mercado de Trabalho",
        label_var_name = "VARIÁVEIS:",
        label_x_name   = "Eixo horizontal (x)",
        label_region_name = "Recorte regional",
        label_sector_name = "Setor",
        label_type_name   = "Atividade / Ocupação",
        type_cnae      = "Atividade Econômica",
        type_cod       = "Ocupação",
        title_init     = "Ranking",
        subtitle_cnae  = "por atividade econômica",
        subtitle_cod   = "por ocupação",
        slider_prefix  = "Ano: ",
        btn_lang       = "English",
        dec_mark       = ",",
        big_mark       = "."
    ),
    en = list(
        plot_name      = "Data Zoom Amazônia",
        plot_desc      = "Labor Market",
        label_var_name = "VARIABLES:",
        label_x_name   = "Horizontal axis (x)",
        label_region_name = "Regional scope",
        label_sector_name = "Sector",
        label_type_name   = "Activity / Occupation",
        type_cnae      = "Economic Activity",
        type_cod       = "Occupation",
        title_init     = "Ranking",
        subtitle_cnae  = "by economic activity",
        subtitle_cod   = "by occupation",
        slider_prefix  = "Year: ",
        btn_lang       = "Português",
        dec_mark       = ".",
        big_mark       = ","
    )
)

param$group_def  <- "Brasil"
param$type_def   <- "CNAE"
param$sector_def <- "formal"

param$x_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui     <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
