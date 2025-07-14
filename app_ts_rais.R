# Carrega bibliotecas
library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)
library(shinycssloaders)


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
param$label_y_name <- "Eixo vertical (y)"
param$label_scale_name <- "escala log"
param$label_prop_name <- "proporcional ao ano inicial (*)"
param$label_geo <- "Recorte Geográfico"
param$label_group <- "Agrupamentos"
param$link <- "https://datazoom.shinyapps.io/app_ts_rais/"

### Parametros especificos no server
param$title_init <- "Evolução anual de" # expressão titulo
param$subtitle_init <- "por grupo selecionado" # expressão subtitulo


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
        "Roraima", "Santa Catarina", "São Paulo", "Sergipe", "Tocantins",
    "Amazônia Legal" = list("Amazônia Legal", "Fora da Amazônia Legal")
    )
)

param$group_categories <- list(
    "Todos" = "Todos",
    "Escolaridade" = list(
        "Sem fundamental completo",
        "Médio completo", 
        "Superior completo"
    ),
    "Sexo" = list(
        "Feminino",
        "Masculino"
    ),
    "Faixa Etária" = list(
        "Menor de 18 anos",
        "Entre 18 e 24 anos",
        "Entre 25 e 29 anos",
        "Entre 30 e 39 anos",
        "Entre 40 e 49 anos",
        "Entre 50 e 59 anos",
        "60 anos ou mais"
    ),
    "Raça/Cor" = list(
        "Branca",
        "Preta",
        "Parda",
        "Amarela",
        "Indígena"
    ),
    "Ocupação" = list(
        "Membros das forças armadas, Policiais e bombeiros militares",
        "Membros superiores do poder público, Dirigentes de organizações de interesse público e de empresas, Gerentes",
        "Profissionais das ciências e das artes",
        "Técnicos de nível médio",
        "Trabalhadores agropecuários, florestais e da pesca",
        "Trabalhadores da produção de bens e serviços industriais",
        "Trabalhadores de serviços administrativos",
        "Trabalhadores dos serviços, vendedores do comércio em lojas e mercados",
        "Trabalhadores em serviços de reparação e manutenção"
    ),
    "Setor Econômico" = list(
        "Administração pública, Defesa e Seguridade social",
        "Agricultura, Pecuária, Produção Florestal, Pesca e Aquicultura",
        "Água, Esgoto, Atividades de Gestão de resíduos e Descontaminação",
        "Alojamento e Alimentação",
        "Artes, Cultura, Esporte e Recreação",
        "Atividades Profissionais, Científicas e Técnicas",
        "Atividades administrativas e serviços complementares",
        "Atividades financeiras, de seguros e serviços relacionados",
        "Atividades imobiliárias",
        "Comércio; Reparação de veículos automotores e motocicletas",
        "Construção",
        "Educação",
        "Eletricidade e Gás",
        "Indústrias extrativas",
        "Indústrias de transformação",
        "Informação e Comunicação",
        "Organismos internacionais e outras instituições extraterritoriais",
        "Outras atividades de serviços",
        "Saúde humana e Serviços sociais",
        "Serviços domésticos",
        "Transporte, Armazenagem e Correio"
    )
)

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
