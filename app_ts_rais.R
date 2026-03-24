# Carrega bibliotecas
library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)
library(shinycssloaders)
library(shinyWidgets)


# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_rais/ui.R"
files$server_script <- "scripts/ts_rais/server.R"
files$param_script <- "scripts/ts_rais/db_params.R"
files$CSS_script <- "global/dza_lumen.css"
files$param_file_pt <- "data/rais_groups_dic.csv"
files$param_file_en <- "data/rais_groups_dic_en.csv"
files$db_file <- "data/rais_groups.rds"

files$group_groups <- "data/group_groups.csv"
files$group_levels <- "data/group_levels.csv"
files$geo_groups <- "data/geo_groups.csv"
files$geo_levels <- "data/geo_levels.csv"


# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros 
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file) 

param <- param_pt # usa PT como padrão inicial

# guarda as duas tabelas para alternar no server
param$tables <- list(
    pt = param_pt$table,
    en = param_en$table
)

param$i18n <- list(
    pt = list(
        plot_name = "Data Zoom RAIS",
        plot_desc = "Dados compilados sobre o mercado de trabalho brasileiro gerados a partir da RAIS",
        label_var_name = "VARIÁVEIS:",
        label_y_name = "Eixo vertical (y)",
        label_scale_name = "Escala log",
        label_prop_name = "Proporcional ao ano inicial",
        label_geo = "Selecione recorte geográfico",
        label_group = "Selecione agrupamento",
        title_init = "Evolução anual do",
        subtitle_init = "por grupo selecionado",
        no_data_msg = "Nenhum dado encontrado com os filtros selecionados",
        axis_x_title = "Ano",
        axis_y_title = "Valor",
        btn_fullscreen = "Fullscreen",
        btn_lang = "English",          # mostra o “alvo” quando estiver em PT
        y_rel_suffix = "(% do ano base)",
        locale = "pt-BR",
        dec_mark = ",",
        big_mark = "."
    ),
    en = list(
        plot_name = "Data Zoom RAIS",
        plot_desc = "Compiled data on the Brazilian labor market based on RAIS microdata.",
        label_var_name = "VARIABLES:",
        label_y_name = "Vertical axis (y)",
        label_scale_name = "Log scale",
        label_prop_name = "Relative to base year",
        label_geo = "Select region",
        label_group = "Select group",
        title_init = "Annual evolution of",
        subtitle_init = "by selected group",
        no_data_msg = "No data found for the selected filters",
        axis_x_title = "Year",
        axis_y_title = "Value",
        btn_fullscreen = "Fullscreen",
        btn_lang = "Português",        # mostra o “alvo” quando estiver em EN
        y_rel_suffix = "(% of base year)",
        locale = "en-US",
        dec_mark = ".",
        big_mark = ","
    )
)


param$x_def <- "year" # variável padrão do eixo x
param$y_def <- "real_avg_w" # variável padrão do eixo y
param$slider_def <- "year"
param$color_def <- "setor" # variável padrão de cor
param$text_def <- "ocupacao" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "uf" # variável de agrupamento
param$link <- "https://datazoom.shinyapps.io/app_ts_rais/"



param$geo_choices <- list(
    "Brasil" = list("Brasil"),
    "Amazônia Legal" = list("Amazônia Legal", "Fora da Amazônia Legal"),
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
