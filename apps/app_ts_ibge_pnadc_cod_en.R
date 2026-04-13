# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_ibge_pnadc_cnae/ui.R"
files$server_script <- "../scripts/ts_ibge_pnadc_cnae/server.R"
files$param_script <- "../scripts/ts_ibge_pnadc_cnae/db_params.R"

files$CSS_script <- "../global/dza_lumen.css"

files$param_file <- "../data/ibge_pnadc_cod_dic_en.csv"
files$db_file <- "../data/ibge_pnadc_cod.rds"

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
param$text_def <- "group" # variável padrão de texto (quando mouse em cima)
param$group <- "group" # variável de agrupamento
param$lang <- TRUE



# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Compiled data about type of work occupation generated from the Quarterly Continuous PNAD - IBGE"

### Parametros especificos no UI
param$label_var_name <- "VARIABLES:"
param$label_y_name <- "Vertical axis (y)"
param$label_scale_name <- "Log scale"
param$label_prop_name <- "Proportional to the initial quarter"
param$label_region_name <- "Region"
param$label_type_name <- "Ocupation"
param$label_sector_name <- "Sector"
param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_cod_en/"

### Parametros especificos no server
param$title_init <- "Quarterly evolution of"  # expressão titulo
param$subtitle_init <- "by type of occupation" # expressão subtitulo


# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL

param$filter_choices <- list(
    "Brazil" = list("Brazil" = "Brasil"),
    "Legal Amazon" = list("Legal Amazon" = "Amaz\u00f4nia Legal Legal", 
                          "Outside the Legal Amazon" = "Fora da Amaz\u00f4nia Legal Legal"),
    "Regions" = list(
        "North" = "Norte",
        "Northeast" = "Nordeste",
        "Southeast" = "Sudeste",
        "South" = "Sul",
        "Central-West" = "Centro-Oeste"),
    "UF" = list(
        "AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO", 
        "MA", "MG", "MS", "MT", "PA", "PB", "PE",
        "PI", "PR", "RJ", "RN", "RO", "RR", "RS", 
        "SC", "SE", "SP", "TO"
    )
)

param$ocupation_choices <- list(
    "All" = "Todos",
    "Administrative support" = "Apoio administrativo",
    "Administrators and management specialists" = "Administradores e especialista em gestão",
    "Assemblers and vehicle drivers" = "Montadores e condutores de veículos",
    "Clerks" = "Escriturários",
    "Construction, metallurgy and industry workers" = "Operários da construção, metalurgia e indústria",
    "Craftsmen and graphic arts" = "Artesões e artes gráficas",
    "Customer service" = "Atendimento direto ao público",
    "Directors and managers" = "Dirigentes e gerentes",
    "Domestic workers" = "Domésticos",
    "Education professionals" = "Profissionais do ensino",
    "Electrical and electronics technicians" = "Técnicos de eletricidade e eletrônica",
    "Financial and administrative services" = "Serviços financeiros e administrativos",
    "Food professionals" = "Profissionais em alimentação",
    "Forest extractors" = "Extrativistas florestais",
    "Garbage collectors" = "Coletores de lixo",
    "Government workers" = "Trabalhadores no governo",
    "Healthcare professionals" = "Profissionais da saúde",
    "IT and communication services" = "Serviços de TI e comunicação",
    "Legal services" = "Serviços jurídicos",
    "Livestock farmers and animal breeders" = "Pecuaristas e criadores de animais",
    "Personal care services" = "Serviços e cuidados pessoais",
    "Processing and installation workers" = "Operários de processamento e instalações",
    "Salespeople" = "Vendedores",
    "Scientists and engineers" = "Cientistas e engenheiros",
    "Security professionals" = "Profissionais de segurança",
    "Street vendors" = "Ambulantes"
)

param$ocupation_def <- list("Todos") 

param$sector_choices <- list(
    "All" = "todos",
    "Formal" = "formal",
    "Informal" = "informal",
    "Public" = "publico",
    "Private" = "privado"
)

param$sector_def <- "formal"


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
