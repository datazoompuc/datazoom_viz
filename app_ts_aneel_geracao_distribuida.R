# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_aneel_geracao_distribuida/ui.R"
files$server_script <- "scripts/ts_aneel_geracao_distribuida/server.R"

files$param_script <- "scripts/ts_aneel_geracao_distribuida/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"

files$param_file <- "data/aneel_geracao_distribuida_dic.csv"
files$db_file <- "data/aneel_geracao_distribuida.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/colunas padrões para os eixos do gráfico)

param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "ano_cadastral" # variável padrão do eixo x
param$filter_sig_modalidade_empreendimento_def <- "Autoconsumo" # variável padrão do filtro
param$filter_dsc_fonte_geracao_def <- "" # variável padrão do filtro
param$y_def <- "mda_potencia_instalada_kw_residencial" # variável padrão do eixo y
param$color_def <- "id" # variável padrão de cor
param$size_def <- "" # variável padrão de tamanho
param$slider_def <- "ano_cadastral" # variável padrão do slider
param$text_def <- "nm_municip" # variável padrão de texto
param$id_def <- "id" # variável padrão de id

param$text_def <- "id" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "id" # variável de agrupamento

param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Dados compilados da Ag\u00eancia Nacional de Energia El\u00e9trica (ANEEL)"

### Parametros especificos no UI
param$label_y_name <- "Eixo vertical (y)"
param$label_region_name <- "Selecione recorte regional"
param$label_var_name <- "FILTROS:"
param$label_type_name <- "Modalidade de empreendimento"
param$label_source_name <- "Fonte de geração"
param$label_size_name <- "Porte do empreendimento"

param$link <- "https://datazoom.shinyapps.io/app_ts_aneel_geracao_distribuida/"

### Parametros especificos no server
param$subtitle_init <- "por recorte regional e filtrado por " # primeira palavra do subtitulo
param$subtitle_sep <- "e"                                     # separador no subtitulo
param$lang <- FALSE


# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL
param$y_choices[[1]] <- NULL
param$color_choices[[1]] <- NULL


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
