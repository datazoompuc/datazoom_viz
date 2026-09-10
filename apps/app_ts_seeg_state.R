library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(shinycssloaders)
library(dplyr)

files <- list()
files$ui_script <- "../scripts/ts_seeg_state/ui.R"
files$server_script <- "../scripts/ts_seeg_state/server.R"
files$param_script <- "../scripts/ts_seeg_state/db_params.R"
files$CSS_script <- "../global/dza_lumen.css"

files$param_file_pt <- "../data/seeg_state_energy_dic.csv"
files$param_file_en <- "../data/seeg_state_energy_dic_en.csv"

files$db_file_energy   <- "../data/seeg_state_energy.rds"
files$db_file_farming  <- "../data/seeg_state_farming.rds"
files$db_file_industry <- "../data/seeg_state_industry.rds"
files$db_file <- files$db_file_energy

source(files$param_script)
source(files$ui_script)
source(files$server_script)

param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param        <- param_pt
param$tables <- list(pt = param_pt$table, en = param_en$table)

param$x_def <- "time"
param$plot_name <- "Data Zoom Amazônia"
param$link <- "https://datazoom.shinyapps.io/app_ts_seeg_state/"

# NOVO: quais estados (sigla) têm dado disponível em cada setor -- usado
# para o aviso na tela quando o usuário troca de setor (item 4 do feedback)
param$estados_por_setor <- list(
    energy   = sort(unique(readRDS(files$db_file_energy)$group)),
    farming  = sort(unique(readRDS(files$db_file_farming)$group)),
    industry = sort(unique(readRDS(files$db_file_industry)$group))
)

# Labels em PT COM ACENTO para exibição (o valor interno da categoria
# continua sendo a string crua do dado, sem acento, para bater com o
# filtro -- só a exibição muda). Sem isso, o dropdown em português mostrava
# "Agropecuario", "Sinteticos" etc. sem acentuação (item 1 do feedback).
param$categoria_label_pt <- list(
    energy = c(
        "Agropecuario" = "Agropecu\u00E1rio",
        "Comercial" = "Comercial",
        "Industrial" = "Industrial",
        "Residencial" = "Residencial",
        "Geracao de Eletricidade (Servico Publico)" = "Gera\u00E7\u00E3o de Eletricidade (Servi\u00E7o P\u00FAblico)",
        "Producao de Combustiveis" = "Produ\u00E7\u00E3o de Combust\u00EDveis",
        "Publico" = "P\u00FAblico",
        "Transportes" = "Transportes"
    ),
    farming = c(
        "Arroz" = "Arroz",
        "Asinino" = "Asinino",
        "Bubalino" = "Bubalino",
        "Caprino" = "Caprino",
        "Equino" = "Equino",
        "Gado de Corte" = "Gado de Corte",
        "Gado de Leite" = "Gado de Leite",
        "Muar" = "Muar",
        "Ovino" = "Ovino",
        "Suinos" = "Su\u00EDnos",
        "Aves" = "Aves",
        "Algodao" = "Algod\u00E3o",
        "Cana-de-acucar" = "Cana-de-a\u00E7\u00FAcar",
        "Torta de Filtro" = "Torta de Filtro",
        "Vinhaca" = "Vinha\u00E7a",
        "Fertilizantes Sinteticos" = "Fertilizantes Sint\u00E9ticos",
        "Solos" = "Solos",
        "Aplicacao de Ureia" = "Aplica\u00E7\u00E3o de Ureia",
        "Uso de Calcario" = "Uso de Calc\u00E1rio",
        "Feijao" = "Feij\u00E3o",
        "Mandioca" = "Mandioca",
        "Milho" = "Milho",
        "Outras culturas" = "Outras Culturas",
        "Pastagem" = "Pastagem",
        "Soja" = "Soja",
        "Trigo" = "Trigo",
        "Pastagem Degradada" = "Pastagem Degradada",
        "Pastagem Bem Manejada" = "Pastagem Bem Manejada",
        "Florestas Plantadas" = "Florestas Plantadas",
        "Sistemas Integrados Lavoura-Pecuaria-Floresta" = "Sistemas Integrados Lavoura-Pecu\u00E1ria-Floresta",
        "Lavouras Cultivadas sob Sistema Convencional" = "Lavouras Cultivadas sob Sistema Convencional",
        "Lavouras Cultivadas sob Sistema Plantio Direto" = "Lavouras Cultivadas sob Sistema Plantio Direto"
    ),
    industry = c(
        "Processos Industriais" = "Processos Industriais"
    )
)

# Traduções PT->EN de cada categoria, por setor (chave = valor cru do dado)
param$categoria_traducao <- list(
    energy = c(
        "Agropecuario" = "Farming", "Comercial" = "Commercial", "Industrial" = "Industrial",
        "Residencial" = "Residential",
        "Geracao de Eletricidade (Servico Publico)" = "Electricity Generation (Public Service)",
        "Producao de Combustiveis" = "Fuel Production",
        "Transportes" = "Transports", "Publico" = "Public"
    ),
    farming = c(
        "Arroz" = "Rice", "Asinino" = "Donkey", "Bubalino" = "Water Buffalo", "Caprino" = "Goat",
        "Equino" = "Horse", "Gado de Corte" = "Beef Cattle", "Gado de Leite" = "Dairy Cattle",
        "Muar" = "Mule", "Ovino" = "Sheep", "Suinos" = "Pigs", "Aves" = "Poultry",
        "Algodao" = "Cotton", "Cana-de-acucar" = "Sugarcane", "Torta de Filtro" = "Filter Cake",
        "Vinhaca" = "Vinasse", "Fertilizantes Sinteticos" = "Synthetic Fertilizers", "Solos" = "Soils",
        "Aplicacao de Ureia" = "Urea Application", "Uso de Calcario" = "Limestone Use",
        "Feijao" = "Beans", "Mandioca" = "Cassava", "Milho" = "Corn", "Outras culturas" = "Other Crops",
        "Pastagem" = "Pasture", "Soja" = "Soybean", "Trigo" = "Wheat",
        "Pastagem Degradada" = "Degraded Pasture", "Pastagem Bem Manejada" = "Well-managed Pasture",
        "Florestas Plantadas" = "Planted Forests",
        "Sistemas Integrados Lavoura-Pecuaria-Floresta" = "Integrated Crop-Livestock-Forest Systems"
    ),
    industry = c(
        "Processos Industriais" = "Industrial Process"
    )
)

param$setor_labels <- list(
    pt = c(energy = "Energia", farming = "Agropecu\u00E1ria", industry = "Ind\u00FAstria"),
    en = c(energy = "Energy", farming = "Farming", industry = "Industry")
)

param$i18n <- list(
    pt = list(
        plot_desc      = "Emiss\u00F5es de Gases Estufa ao n\u00EDvel estadual, por setor",
        plot_y         = "Emiss\u00F5es (t)",
        label_var_name = "VARI\u00C1VEIS:",
        label_y_name   = "eixo vertical (y)",
        label_log_name = "Escala Log",
        label_prop_name = "Proporcional ao Ano Inicial (%)",
        label_geo_name = "Estado",
        subtitle_init  = "por Estado",
        title_init     = "Emiss\u00F5es Totais advindas de ",
        tooltip_a      = "Emiss\u00F5es",
        tooltip_c      = "Toneladas",
        tooltip_prop   = "%",
        # NOVO: disclaimers (itens 4 e 6 do feedback)
        disclaimer_setor = list(
            energy   = "Emiss\u00F5es de energia usada no setor (ex: combust\u00EDvel de m\u00E1quinas), n\u00E3o emiss\u00F5es biol\u00F3gicas diretas.",
            farming  = "Emiss\u00F5es biol\u00F3gicas diretas da agropecu\u00E1ria (rebanhos, solos, culturas).",
            industry = NULL
        ),
        disclaimer_estados = "Dados dispon\u00EDveis apenas para: ",
        btn_lang       = "English",
        btn_fullscreen = "Fullscreen"
    ),
    en = list(
        plot_desc      = "Greenhouse Gas Emissions at State Level, by sector",
        plot_y         = "Emissions (t)",
        label_var_name = "VARIABLES:",
        label_y_name   = "vertical axis (y)",
        label_log_name = "Log Scale",
        label_prop_name = "Proportional to Initial Year (%)",
        label_geo_name = "State",
        subtitle_init  = "by State",
        title_init     = "Total emissions from ",
        tooltip_a      = "Emissions",
        tooltip_c      = "Tons",
        tooltip_prop   = "%",
        disclaimer_setor = list(
            energy   = "Emissions from energy used in the sector (e.g. machinery fuel), not direct biological emissions.",
            farming  = "Direct biological emissions from farming (livestock, soils, crops).",
            industry = NULL
        ),
        disclaimer_estados = "Data available only for: ",
        btn_lang       = "Portugu\u00EAs",
        btn_fullscreen = "Fullscreen"
    )
)

ui <- get_ui(files, param)
server <- get_server(files, param)
shinyApp(ui = ui, server = server)