# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_ibge_pnadc_atividades_ocupacoes/ui.R"
files$server_script <- "../scripts/ts_ibge_pnadc_atividades_ocupacoes/server.R"
files$param_script <- "../scripts/ts_ibge_pnadc_atividades_ocupacoes/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/ibge_pnadc_cnae_dic.csv"
files$param_file_en <- "../data/ibge_pnadc_cnae_dic_en.csv"
files$db_file <- "../data/ibge_pnadc_atividades_ocupacoes.rds"
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

param$x_def <- "time"
param$y_def <- "rendimento_medio"
param$slider_def <- "time"
param$color_def <- "group"
param$text_def <- "group"
param$group <- "group"

param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_atividades_ocupacoes/"

param$i18n <- list(
    pt = list(
        plot_name = "Data Zoom Amaz\u00f4nia",
        plot_desc = "Dados sobre atividades econ\u00f4micas gerados a partir da PNAD Cont\u00ednua Trimestral - IBGE",
        label_var_name = "VARI\u00c1VEIS:",
        label_y_name = "Eixo vertical",
        label_scale_name = "Escala log",
        label_prop_name = "Proporcional ao trimestre inicial",
        label_region_name = "Recorte regional",
        label_type_name = "Atividade / Ocupa\u00e7\u00e3o",
        label_sector_name = "Setor",
        label_all = "Geral",
        label_cnae = "Atividade Econ\u00f4mica",
        label_cod = "Ocupa\u00e7\u00e3o",
        title_init = "Evolu\u00e7\u00e3o trimestral de",
        subtitle = "por atividade / ocupa\u00e7\u00e3o",
        no_data_msg = "Nenhum dado encontrado com os filtros selecionados",
        btn_lang = "English",
        dec_mark = ",",
        big_mark = "."
    ),
    en = list(
        plot_name = "Data Zoom Amaz\u00f4nia",
        plot_desc = "Compiled data about economic activities generated from the Quarterly Continuous PNAD - IBGE",
        label_var_name = "VARIABLES:",
        label_y_name = "Vertical axis",
        label_scale_name = "Log scale",
        label_prop_name = "Proportional to the initial quarter",
        label_region_name = "Regional scope",
        label_type_name = "Activity / Occupation",
        label_sector_name = "Sector",
        label_all = "General",
        label_cnae = "Economic Activity",
        label_cod = "Occupation",
        title_init = "Quarterly evolution of",
        subtitle = "by activity / occupation",
        subtitle_both = "by economic activity / occupation",
        no_data_msg = "No data found for the selected filters",
        btn_lang = "Portugu\u00eas",
        dec_mark = ".",
        big_mark = ","
    )
)

param$ocupation_def <- "All::Todos"
param$sector_def <- "formal"
param$y_choices[[1]] <- NULL

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
