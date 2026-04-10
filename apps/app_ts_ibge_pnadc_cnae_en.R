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
files$param_file <- "../data/ibge_pnadc_cnae_dic_en.csv"
files$db_file <- "../data/ibge_pnadc_cnae.rds"

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
param$group <- "group" # variável de agrupamento

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Compiled data about economic activities generated from the Quarterly Continuous PNAD - IBGE"

### Parametros especificos no UI
param$label_var_name <- "VARIABLES:"
param$label_y_name <- "Vertical axis"
param$label_scale_name <- "Log scale"
param$label_prop_name <- "Proportional to the initial quarter"
#param$label_eco_name <- "State - Economic activities"
param$label_region_name <- "Regional scope"
param$label_type_name <- "Economic activity"
param$label_sector_name <- "Sector"


param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_cnae_en/"

### Parametros especificos no server
param$title_init <- "Quarterly evolution of"  # expressão titulo
param$subtitle_init <- "by economic activities" # expressão subtitulo


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
    "Arts, culture, sports and recreation" = "Artes, cultura, esportes e recreação",
    "Automobiles and transport equipment" = "Automóveis e equipamentos de transporte",
    "Chemicals, pharmaceuticals, rubber and plastics" = "Químicos, farmacêuticos, borracha e plástico",
    "Construction" = "Construção",
    "Domestic services" = "Serviços domésticos",
    "Education" = "Educação",
    "Electronics, machinery and equipment" = "Eletrônicos, máquinas e equipamentos",
    "Financial and insurance services" = "Serviços financeiros e de seguros",
    "Fishing, hunting and aquaculture" = "Pesca, caça e aquicultura",
    "Food, beverages and tobacco" = "Alimentos, bebidas e fumo",
    "Food services" = "Serviços de alimentação",
    "Furniture" = "Móveis",
    "Health and social care" = "Saúde e assistência social",
    "Information and communication services" = "Serviços de informação e comunicação",
    "Labor outsourcing" = "Terceirização de mão-de-obra",
    "Legal services" = "Serviços jurídicos",
    "Livestock and animal husbandry" = "Pecuária e criação de animais",
    "Lodging and tourism" = "Estadia e turismo",
    "Metal products, non-metallic minerals and metallurgy" = "Produtos de metal, minerais não-metálicos e metalurgia",
    "Other" = "Outros",
    "Personal services (hairdressers, laundries, etc.)" = "Serviços pessoais (cabelereiros, lavanderias, etc.)",
    "Professional, scientific and technical activities" = "Atividades profissionais, científicas e técnicas",
    "Public administration, defense and social security" = "Administração pública, defesa e seguridade social",
    "Religious, union and employer organizations" = "Organizações religiosas, sindicais e patronais",
    "Security and buildings" = "Segurança e edifícios",
    "Textiles, clothing, leather and footwear" = "Têxtil, vestuário, couro e calçados",
    "Trade" = "Comércio",
    "Transport and mail" = "Transporte e correio",
    "Wood, pulp and paper" = "Madeira, celulose e papel"
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
