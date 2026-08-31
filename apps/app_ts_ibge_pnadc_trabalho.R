# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_ibge_pnadc_trabalho/ui.R"
files$server_script <- "../scripts/ts_ibge_pnadc_trabalho/server.R"
files$param_script <- "../scripts/ts_ibge_pnadc_trabalho/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/ibge_pnadc_trabalho_dic.csv"
files$param_file_en <- "../data/ibge_pnadc_trabalho_dic_en.csv"
files$db_file <- "../data/ibge_pnadc_trabalho.rds"
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

param$x_def    <- "time"
param$y_def    <- "taxa_desemprego"
param$slider_def <- "time"
param$color_def <- "composicao_demografica"
param$text_def  <- "group"
param$group     <- "group"

param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_trabalho/"

param$i18n <- list(
    pt = list(
        plot_name      = "Data Zoom Amazônia",
        plot_desc      = "Mercado de Trabalho",
        label_var_name = "VARIÁVEIS:",
        label_y_name   = "Eixo vertical (y)",
        label_geo_name = "Recorte regional",
        label_comp_name = "Composição demográfica",
        subtitle_init  = "por recorte regional e ",
        tooltip_comp   = "Grupo: ",
        btn_lang       = "English",
        dec_mark       = ",",
        big_mark       = "."
    ),
    en = list(
        plot_name      = "Data Zoom Amazônia",
        plot_desc      = "Labor Market",
        label_var_name = "VARIABLES:",
        label_y_name   = "Vertical axis (y)",
        label_geo_name = "Regional scope",
        label_comp_name = "Demographic composition",
        subtitle_init  = "by regional scope and ",
        tooltip_comp   = "Group: ",
        btn_lang       = "Português",
        dec_mark       = ".",
        big_mark       = ","
    )
)

param$filter_geo_def  <- c("Amazônia Legal", "Fora da Amazônia Legal")
param$filter_comp_def <- "Todos"

param$y_choices[[1]]     <- NULL
param$color_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
