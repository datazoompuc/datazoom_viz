# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(shinycssloaders)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_rais/ui.R"
files$server_script <- "scripts/ts_rais/server.R"
files$param_script <- "scripts/ts_rais/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/rais_groups_dic.csv"
files$db_file <- "data/rais_groups.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "year" # variável padrão do eixo x
param$y_def <- "real_avg_w" # variável padrão do eixo y
param$slider_def <- "year"
param$color_def <- "setor" # variável padrão de cor
param$text_def <- "ocupacao" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "uf" # variável de agrupamento

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom RAIS"
param$plot_desc <- "Dados compilados sobre o mercado de trabalho brasileiro gerados a partir da RAIS"

### Parametros especificos no UI
param$label_var_name <- "VARIÁVEIS:"
param$label_y_name <- "eixo vertical (y)"
param$label_scale_name <- "escala log"
param$label_prop_name <- "proporcional ao ano inicial (*)"
param$label_geo <- "Recorte Geográfico"
param$label_sect <- "Setores econômicos"
param$link <- "https://datazoom.shinyapps.io/app_ts_rais/"

### Parametros especificos no server
param$title_init <- "Evolução anual de" # expressão titulo
param$subtitle_init <- "por setor econômico" # expressão subtitulo


# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL

param$geo_choices <- list(
    "Brasil" = list("Brasil", ""),
    "Regiões" = list("Norte", "Nordeste", "Sudeste", "Sul", "Centro-Oeste"),
    "Estados" = list(
        "Acre", "Alagoas", "Amapá", "Amazonas", "Bahia", "Ceará", 
        "Distrito Federal", "Espírito Santo", "Goiás", "Maranhão", 
        "Mato Grosso", "Mato Grosso do Sul", "Minas Gerais", "Pará", 
        "Paraíba", "Paraná", "Pernambuco", "Piauí", "Rio de Janeiro",
        "Rio Grande do Norte", "Rio Grande do Sul", "Rondônia", 
        "Roraima", "Santa Catarina", "São Paulo", "Sergipe", "Tocantins"
    )
)
param$sect_choices <- list(
    "Todos os setores" = "Todos os setores",
    "Administração Pública" = "Administração pública, Defesa e Seguridade social",
    "Agricultura e Pecuária" = "Agricultura, Pecuária, Produção Florestal, Pesca e Aquicultura",
    "Alojamento e Alimentação" = "Alojamento e Alimentação",
    "Artes e Cultura" = "Artes, Cultura, Esporte e Recreação",
    "Comércio" = "Comércio; Reparação de veículos automotores e motocicletas",
    "Construção" = "Construção",
    "Educação" = "Educação",
    "Energia e Saneamento" = c("Eletricidade e Gás", "Água, Esgoto, Atividades de Gestão de resíduos e Descontaminação"),
    "Finanças e Seguros" = "Atividades financeiras, de seguros e serviços relacionados",
    "Indústrias" = c("Indústrias de transformação", "Indústrias extrativas"),
    "Informação e Comunicação" = "Informação e Comunicação",
    "Profissionais e Técnicos" = "Atividades Profissionais, Científicas e Técnicas",
    "Saúde e Serviços Sociais" = "Saúde humana e Serviços sociais",
    "Serviços Administrativos" = "Atividades administrativas e serviços complementares",
    "Serviços Domésticos" = "Serviços domésticos",
    "Transporte e Correio" = "Transporte, Armazenagem e Correio",
    "Outros Serviços" = c("Outras atividades de serviços", "Atividades imobiliárias", "Organismos internacionais e outras instituições extraterritoriais")
)
#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
