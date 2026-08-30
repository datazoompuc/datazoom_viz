library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)
library(dplyr)

files <- list()
files$ui_script <- "../scripts/ts_seeg_state_industry/ui.R"
files$server_script <- "../scripts/ts_seeg_state_industry/server.R"
files$param_script <- "../scripts/ts_seeg_state_industry/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/seeg_state_industry_dic.csv"
files$param_file_en <- "../data/seeg_state_industry_dic_en.csv"
files$db_file <- "../data/seeg_state_industry.rds"

source(files$param_script)
source(files$ui_script)
source(files$server_script)

param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param        <- param_pt
param$tables <- list(pt = param_pt$table, en = param_en$table)

param$x_def <- "time"
param$y_def <- ""
param$color_def <- "time"
param$slider_def <- "time"
param$text_def <- "group"
param$id_def <- "group"
param$plot_name <- "Data Zoom Amazônia"

# Tradução das categorias de "setor" (aplicada em runtime, não no dado bruto)
param$categoria_traducao <- c(
    "Processos Industriais" = "Industrial Process"
)

param$i18n <- list(
    pt = list(
        plot_desc      = "Emiss\u00F5es de Gases Estufa na Ind\u00FAstria ao n\u00EDvel estadual",
        plot_y         = "Emiss\u00F5es",
        label_var_name = "VARI\u00C1VEIS:",
        label_y_name   = "eixo y (y)",
        label_log_name = "escala log",
        label_prop_name = "proporcional ao ano inicial (*)",
        label_geo_name = "Estado",
        subtitle_init  = "por Estado",
        title_init     = "Emiss\u00F5es Totais advindas de ",
        tooltip_a      = "Emiss\u00F5es",
        tooltip_c      = "Toneladas",
        btn_lang       = "English",
        btn_fullscreen = "Fullscreen"
    ),
    en = list(
        plot_desc      = "Greenhouse Gas Emissions in Industry at State Level",
        plot_y         = "Emissions",
        label_var_name = "VARIABLES:",
        label_y_name   = "vertical axis (y)",
        label_log_name = "log scale",
        label_prop_name = "proportional to the initial year (*)",
        label_geo_name = "State",
        subtitle_init  = "by State",
        title_init     = "Total emissions from ",
        tooltip_a      = "Emissions",
        tooltip_c      = "Tons",
        btn_lang       = "Português",
        btn_fullscreen = "Fullscreen"
    )
)

param$link <- "https://datazoom.shinyapps.io/app_ts_seeg_state_industry/"

ui <- get_ui(files, param)
server <- get_server(files, param)
shinyApp(ui = ui, server = server)