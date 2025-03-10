# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_ibge_pnadc_cnae/ui.R"
files$server_script <- "scripts/ts_ibge_pnadc_cnae/server.R"
files$param_script <- "scripts/ts_ibge_pnadc_cnae/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/ibge_pnadc_cod_dic.csv"
files$db_file <- "data/ibge_pnadc_cod.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "rendimento_medio" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Mercado de Trabalho"

### Parametros especificos no UI
param$label_var_name <- "VARIÁVEIS:"
param$label_y_name <- "eixo vertical (y)"
param$label_scale_name <- "escala log"
param$label_prop_name <- "proporcional ao trimestre inicial (*)"
param$label_region_name <- "Recorte regional"
param$label_type_name <- "Ocupação"
param$label_sector_name <- "Setor"
param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_cod/"

### Parametros especificos no server
param$title_init <- "Evolução trimestral de" # expressão titulo
param$subtitle_init <- "por ocupação" # expressão subtitulo


# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL

param$filter_choices <- list(
    "Brasil" = list("Brasil", ""),
    "Amaz\u00f4nia Legal" = list("Amaz\u00f4nia Legal", "Fora da Amaz\u00f4nia Legal"),
    "Regi\u00e3o" = list("Norte", "Nordeste", "Sudeste", "Sul", "Centro-Oeste"),
    "UF" = list(
        "RO", "AC", "AM", "RO", "PA", "AP", "TO",
        "MA", "PI", "CE", "RN", "PB", "PE", "AL",
        "SE", "BA", "MG", "ES", "RJ", "SP", "PR",
        "SC", "RS", "MS", "MT", "GO", "DF"
    )
)

param$ocupation_choices <- list(
    "Administradores e especialista em gestão",
    "Ambulantes",
    "Apoio administrativo",
    "Artesões e artes gráficas",
    "Atendimento direto ao público",
    "Cientistas e engenheiros",
    "Coletores de lixo",
    "Dirigentes e gerentes",
    "Domésticos",
    "Escriturários",
    "Extrativistas florestais",
    "Montadores e condutores de veículos",
    "Operários da construção, metalurgia e indústria",
    "Operários de processamento e instalações",
    "Pecuaristas e criadores de animais",
    "Profissionais da saúde",
    "Profissionais de segurança",
    "Profissionais do ensino",
    "Profissionais em alimentação",
    "Serviços de TI e comunicação",
    "Serviços e cuidados pessoais",
    "Serviços financeiros e administrativos",
    "Serviços jurídicos",
    "Trabalhadores no governo",
    "Técnicos de eletricidade e eletrônica",
    "Vendedores"
)

param$ocupation_def <- list("Profissionais do ensino", "Profissionais da saúde") 

param$sector_choices <- list(
    "Todos" = "todos",
    "Formal" = "formal",
    "Informal" = "informal",
    "Público" = "publico",
    "Privado" = "privado"
)

param$sector_def <- "formal"

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
