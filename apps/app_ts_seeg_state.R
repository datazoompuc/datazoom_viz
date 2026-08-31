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

# Traduções PT->EN de cada categoria, por setor
param$categoria_traducao <- list(
    energy = c(
        "Agropecuario" = "Farming", "Comercial" = "Commercial", "Industrial" = "Industrial",
        "Residencial" = "Residential",
        "Geracao de Eletricidade (Servico Publico)" = "Electricity Generation (Public Service)",
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
        plot_y         = "Emiss\u00F5es",
        label_var_name = "VARI\u00C1VEIS:",
        label_y_name   = "eixo vertical (y)",
        label_log_name = "escala log",
        label_prop_name = "proporcional ao ano inicial (*)",
        label_geo_name = "Estado",
        subtitle_init  = "por Estado",
        title_init     = "Emiss\u00F5es Totais advindas de ",
        tooltip_a      = "Emiss\u00F5es",
        tooltip_c      = "Toneladas",
        btn_lang       = "English",
        btn_fullscreen = "Fullscreen"
    ),
    en = list(
        plot_desc      = "Greenhouse Gas Emissions at State Level, by sector",
        plot_y         = "Emissions",
        label_var_name = "VARIABLES:",
        label_y_name   = "vertical axis (y)",
        label_log_name = "log scale",
        label_prop_name = "proportional to the initial year (*)",
        label_geo_name = "State",
        subtitle_init  = "by State",
        title_init     = "Total emissions from ",
        tooltip_a      = "Emissions",
        tooltip_c      = "Tons",
        btn_lang       = "Português",
        btn_fullscreen = "Fullscreen"
    )
)

ui <- get_ui(files, param)
server <- get_server(files, param)
shinyApp(ui = ui, server = server)