library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

files <- list()
files$ui_script <- "../scripts/ts_sigmine/ui.R"
files$server_script <- "../scripts/ts_sigmine/server.R"
files$param_script <- "../scripts/ts_sigmine/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/sigmine_munic_dic.csv"
files$param_file_en <- "../data/sigmine_munic_en_dic.csv"
files$db_file <- "../data/sigmine_munic.rds"

source(files$param_script)
source(files$ui_script)
source(files$server_script)

param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param        <- param_pt
param$tables <- list(pt = param_pt$table, en = param_en$table)

param$x_def <- "time"
param$y_def <- "area"
param$slider_def <- "time"
param$color_def <- "group"
param$text_def <- "group"
param$group <- "group"

param$i18n <- list(
    pt = list(
        plot_desc        = "Ranking municipal de \u00E1rea de minera\u00E7\u00E3o ativa, por tipo de min\u00E9rio",
        label_var_name   = "VARI\u00C1VEIS:",
        label_y_name     = "eixo vertical (y)",
        label_scale_name = "escala log",
        label_axis_name  = "proporcional ao ano inicial (*)",
        label_mun_filter = "Subdivis\u00E3o geogr\u00E1fica",
        geo_level        = "Por subdivis\u00E3o geogr\u00E1fica",
        btn_lang         = "English",
        btn_fullscreen   = "Fullscreen"
    ),
    en = list(
        plot_desc        = "Municipal ranking of active mining area, by mineral type",
        label_var_name   = "VARIABLES:",
        label_y_name     = "vertical axis (y)",
        label_scale_name = "log scale",
        label_axis_name  = "proportional to starting year (*)",
        label_mun_filter = "Geographic subdivision",
        geo_level        = "Per geographic subdivision",
        btn_lang         = "Português",
        btn_fullscreen   = "Fullscreen"
    )
)

param$plot_name <- "Data Zoom Amazônia"
param$link <- 'https://datazoom.shinyapps.io/app_ts_sigmine/'

ui <- get_ui(files, param)
server <- get_server(files, param)
shinyApp(ui = ui, server = server)