# Carrega bibliotecas
library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "../scripts/ts_rais/ui.R"
files$server_script <- "../scripts/ts_rais/server.R"
files$param_script <- "../scripts/ts_rais/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"
files$param_file <- "../data/rais_groups_dic_en.csv"
files$db_file <- "../data/rais_groups.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização
param <- get_db_param(files$param_file, files$db_file)
param$x_def <- "year"
param$y_def <- "real_avg_w"
param$slider_def <- "year"
param$color_def <- "setor"
param$text_def <- "ocupacao"
param$group <- "uf"

# Textos e rótulos da interface
param$plot_name <- "Data Zoom RAIS"
param$plot_desc <- "Compiled data on the Brazilian labor market based on RAIS microdata."

param$label_var_name <- "VARIABLES:"
param$label_y_name <- "vertical axis (y)"
param$label_scale_name <- "log scale"
param$label_prop_name <- "proportional to the initial year (*)"
param$label_geo <- "Select region"
param$label_group <- "Select group"

param$title_init <- "Annual evolution of"
param$subtitle_init <- "by selected group"
param$no_data_msg <- "No data found for the selected filters"
param$axis_x_title <- "Year"
param$axis_y_title <- "Value"

param$link <- "https://datazoom.shinyapps.io/app_ts_rais_en/"

# Opções de seleção
param$geo_choices <- list(
    "Brazil" = list("Brazil" = "Brasil"),
    "Legal Amazon" = list("Legal Amazon" = "Amazônia Legal", 
                          "Outside the Legal Amazon" = "Fora da Amazônia Legal"),
    "Regions" = list(
        "North" = "Norte",
        "Northeast" = "Nordeste",
        "Southeast" = "Sudeste",
        "South" = "Sul",
        "Central-West" = "Centro-Oeste"
    ),
    "States" = list(
        "Acre" = "Acre",
        "Alagoas" = "Alagoas",
        "Amapá" = "Amapá",
        "Amazonas" = "Amazonas",
        "Bahia" = "Bahia",
        "Ceará" = "Ceará",
        "Federal District" = "Distrito Federal",
        "Espírito Santo" = "Espírito Santo",
        "Goiás" = "Goiás",
        "Maranhão" = "Maranhão",
        "Mato Grosso" = "Mato Grosso",
        "Mato Grosso do Sul" = "Mato Grosso do Sul",
        "Minas Gerais" = "Minas Gerais",
        "Pará" = "Pará",
        "Paraíba" = "Paraíba",
        "Paraná" = "Paraná",
        "Pernambuco" = "Pernambuco",
        "Piauí" = "Piauí",
        "Rio de Janeiro" = "Rio de Janeiro",
        "Rio Grande do Norte" = "Rio Grande do Norte",
        "Rio Grande do Sul" = "Rio Grande do Sul",
        "Rondônia" = "Rondônia",
        "Roraima" = "Roraima",
        "Santa Catarina" = "Santa Catarina",
        "São Paulo" = "São Paulo",
        "Sergipe" = "Sergipe",
        "Tocantins" = "Tocantins"
    )
)

param$group_categories <- list(
    "All" = "Todos",
    
    "Level of Education" = list(
        "Less than primary education completed" = "Sem fundamental completo",
        "Completed secondary education" = "Médio completo",
        "Completed higher education" = "Superior completo"
    ),
    
    "Gender" = list(
        "Female" = "Feminino",
        "Male" = "Masculino"
    ),
    "Age Group" = list(
        "Under 18 years old" = "Menor de 18 anos",
        "Age group between 18 and 24 years old" = "Entre 18 e 24 anos",
        "Age group between 25 and 29 years old" = "Entre 25 e 29 anos",
        "Age group between 30 and 39 years old" = "Entre 30 e 39 anos",
        "Age group between 40 and 49 years old" = "Entre 40 e 49 anos",
        "Age group between 50 and 59 years old" = "Entre 50 e 59 anos",
        "Age group between 60 years and over" = "60 anos ou mais"
    ),
    
    "Race/Color" = list(
        "White" = "Branca",
        "Black" = "Preta",
        "Brown (Pardo)" = "Parda",
        "Yellow (Asian)" = "Amarela",
        "Indigenous" = "Indígena"
    ),
    
    "Occupation" = list(
        "Administrative support workers" =
            "Trabalhadores de serviços administrativos",
        "Agricultural, forestry, and fishery workers" =
            "Trabalhadores agropecuários, florestais e da pesca",
        "Members of the armed forces, police, and military firefighters" =
            "Membros das forças armadas, Policiais e bombeiros militares",
        "Production workers in industry and related services" =
            "Trabalhadores da produção de bens e serviços industriais",
        "Professionals in science and the arts" =
            "Profissionais das ciências e das artes",
        "Repair and maintenance workers" =
            "Trabalhadores em serviços de reparação e manutenção",
        "Senior public officials, executives, and managers" =
            "Membros superiores do poder público, Dirigentes de organizações de interesse público e de empresas, Gerentes",
        "Service and sales workers in shops and markets" =
            "Trabalhadores dos serviços, vendedores do comércio em lojas e mercados",
        "Technicians and associate professionals" =
            "Técnicos de nível médio"
    ),
    
    "Economic Sector" = list(
        "Accommodation and food services" = "Alojamento e Alimentação",
        "Administrative and support service activities" =
            "Atividades administrativas e serviços complementares",
        "Agriculture, livestock, forestry, fishing, and aquaculture" =
            "Agricultura, Pecuária, Produção Florestal, Pesca e Aquicultura",
        "Arts, culture, sports, and recreation" =
            "Artes, Cultura, Esporte e Recreação",
        "Construction" = "Construção",
        "Domestic services" = "Serviços domésticos",
        "Education" = "Educação",
        "Electricity and gas supply" = "Eletricidade e Gás",
        "Financial and insurance activities" =
            "Atividades financeiras, de seguros e serviços relacionados",
        "Human health and social work activities" =
            "Saúde humana e Serviços sociais",
        "Information and communication" = "Informação e Comunicação",
        "International organizations and other extraterritorial institutions" =
            "Organismos internacionais e outras instituições extraterritoriais",
        "Manufacturing" = "Indústrias de transformação",
        "Mining and quarrying" = "Indústrias extrativas",
        "Other service activities" = "Outras atividades de serviços",
        "Professional, scientific, and technical activities" =
            "Atividades Profissionais, Científicas e Técnicas",
        "Public administration, defense, and social security" =
            "Administração pública, Defesa e Seguridade social",
        "Real estate activities" = "Atividades imobiliárias",
        "Transportation, storage, and postal services" =
            "Transporte, Armazenagem e Correio",
        "Water supply, sewage, waste management, and remediation" =
            "Água, Esgoto, Atividades de Gestão de resíduos e Descontaminação",
        "Wholesale and retail trade; repair of motor vehicles and motorcycles" =
            "Comércio; Reparação de veículos automotores e motocicletas"
    )
    
)

#  --------------------------------  Roda a aplicação Shiny --------------------------------

ui <- get_ui(files, param)
server <- get_server(files, param)
shinyApp(ui = ui, server = server)
