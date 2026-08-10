# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/rk_comex_exp_munic_produtosamz/ui.R"
files$server_script <- "../scripts/rk_comex_exp_munic_produtosamz/server.R"
files$param_script <- "../scripts/rk_comex_exp_munic_produtosamz/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file_pt <- "../data/comex_exp_sh4_munic_dic.csv"
files$param_file_en <- "../data/comex_exp_sh4_munic_dic_en.csv"
files$db_file <- "../data/comex_exp_sh4_munic.rds"
files$aux_file <- "../data/auxiliar_cod_sh4.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/colunas padrões para os eixos do gráfico)
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param <- param_pt # usa PT como padrão inicial
param$tables <- list(
    pt = param_pt$table,
    en = param_en$table
)
param$x_def <- "value" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id
param$i18n <- list(
    pt = list(
        plot_name = "Data Zoom Amazônia",
        plot_desc = "municípios que mais exportam produtos da Amazônia Legal",
        plot_title = "Ranking de exportação por município",
        label_variable = "VARI\u00C1VEIS:",
        label_x_choice_rk = "Categoria de produtos:",
        label_no_variable = "Variável não selecionada",
        x_label = "Valor (US$ FOB)",
        pct_anual = "Participação no ano: ",
        ranking_label = "Ranking",
        slider_prefix = "Ano: ",
        btn_lang = "English",
        btn_fullscreen = "Fullscreen",
        dec_mark = ",",
        big_mark = "."
    ),
    en = list(
        plot_name = "Data Zoom Amazônia",
        plot_desc = "The municipalities with the highest exports of Legal Amazon products",
        plot_title = "Export ranking by municipality",
        label_variable = "VARIABLES:",
        label_x_choice_rk = "Product categories:",
        label_no_variable = "No variable selected",
        x_label = "Value (US$ FOB)",
        pct_anual = "Share of annual exports: ",
        ranking_label = "Ranking",
        slider_prefix = "Year: ",
        btn_lang = "Portugu\u00EAs",
        btn_fullscreen = "Fullscreen",
        dec_mark = ".",
        big_mark = ","
    )
)

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL

param$link<-"https://datazoom.shinyapps.io/app_rk_comex_exp_munic_produtosamz/"


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
