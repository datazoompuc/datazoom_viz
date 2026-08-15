library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

files <- list()
files$ui_script <- "../scripts/rk_sigmine_munic/ui.R"
files$server_script <- "../scripts/rk_sigmine_munic/server.R"
files$param_script <- "../scripts/rk_sigmine_munic/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/sigmine_munic_dic.csv"
files$param_file_en <- "../data/sigmine_munic_en_dic.csv"   # CORRIGIDO: nome certo do arquivo
files$db_file <- "../data/sigmine_munic.rds"

source(files$param_script)
source(files$ui_script)
source(files$server_script)

param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param        <- param_pt
param$tables <- list(pt = param_pt$table, en = param_en$table)

param$x_def <- "Areia"
param$y_def <- ""
param$slider_def <- "time"
param$color_def <- "group"
param$text_def <- "group"
param$group <- "group"
param$id_def <- "group"

param$i18n <- list(
    pt = list(
        ui1 = "VARI\u00C1VEIS:",
        ui2 = "Ranking - eixo horizontal (x):",
        ui3 = "Cor das barras:",
        server0 = "Vari\u00E1vel n\u00E3o selecionada",
        server1 = "Ranking de ",
        server2 = "Amaz\u00F4nia Legal",
        plot_desc = "Transi\u00E7\u00E3o/mudan\u00E7a de cobertura e uso do solo",
        btn_lang = "English",
        btn_fullscreen = "Fullscreen"
    ),
    en = list(
        ui1 = "VARIABLES:",
        ui2 = "Ranking - horizontal axis (x):",
        ui3 = "Bar colors:",                                  # CORRIGIDO: plural
        server0 = "Variable not selected",
        server1 = "Ranking of ",
        server2 = "Legal Amazon",
        plot_desc = "Transition/change of cover and use of land",  # CORRIGIDO: texto exato do app antigo
        btn_lang = "Português",
        btn_fullscreen = "Fullscreen"
    )
)

param$link <- 'https://datazoom.shinyapps.io/app_rk_sigmine_munic/'
param$plot_name <- "Data Zoom Amazônia"

ui <- get_ui(files, param)
server <- get_server(files, param)
shinyApp(ui = ui, server = server)