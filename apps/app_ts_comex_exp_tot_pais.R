# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)
library(shinyWidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_comex_exp_tot_pais/ui.R"
files$server_script <- "../scripts/ts_comex_exp_tot_pais/server.R"
files$param_script <- "../scripts/ts_comex_exp_tot_pais/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file_pt <- "../data/comex_exp_tot_pais_dic.csv"
files$param_file_en <- "../data/comex_exp_tot_pais_dic_en.csv"
files$db_file <- "../data/comex_exp_tot_pais.rds"
files$aux_file <- "../data/indice_precos_anual.csv"
files$country_map_file <- "../data/paises_traducao.csv"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)

param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file) # carrega lista de variáveis e parâmetros

param        <- param_pt           # PT como idioma padrão
param$tables <- list(
  pt = param_pt$table,
  en = param_en$table
)

param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "value" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto (quando mouse em cima)
param$group <- "group" # variável de agrupamento

param$link <- "https://datazoom.shinyapps.io/app_ts_comex_exp_tot_pais/"

param$i18n <- list(
  pt = list(
      plot_name = "Data Zoom Amaz\u00f4nia",
      plot_desc = "Com\u00e9rcio exterior na Amaz\u00f4nia (COMEX): Valor da exporta\u00e7\u00e3o de produtos total da Amaz\u00f4nia Legal por país de destino",
      plot_title = "Valor total da exporta\u00e7\u00e3o de produtos da Amaz\u00f4nia Legal por país de destino",
      label_var_name = "VARIÁVEIS:",
      label_scales = "OPÇÕES DE ESCALA:",
      label_scale_name = "Escala log",
      label_axis_name = "Proporcional ao ano inicial",
      label_prop = "% do ano inicial",
      label_country_filter = "Países de destino",
      currency = "Em US$",
      measurement = "US$",
      label_deflator = "Deflacionar (US$ de 1998)",
      ylabel_deflator =  "US$ de 1998",
      btn_lang         = "English",
      subtitle_deflator = " (deflacionados, base 1998 = 100)"
  ),
  en = list(
    plot_name = "Data Zoom Amaz\u00f4nia",
    plot_desc = "External trade in the Brazilian Legal Amazon (COMEX): Total export value of products by destination country",
    plot_title = "Total export value of products from the Brazilian Legal Amazon by destination country",
    label_var_name = "VARIABLES:",
    label_scales = "SCALE OPTIONS:",
    label_scale_name = "Log scale",
    label_axis_name = "Proportional to starting year",
    label_prop = "% of starting year",
    label_country_filter = "Destination Countries",
    currency = "In US$",
    measurement = "US$",
    label_deflator   = "Deflate (1998 US$)",
    ylabel_deflator  = "1998 US$",
    btn_lang         = "Português",
    subtitle_deflator = " (deflated, base 1998 = 100)"
  )
)


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
