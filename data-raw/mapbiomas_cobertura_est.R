################################################################################
#  1. SETUP AND PACKAGE LOADING
################################################################################

devtools::install_github("datazoompuc/datazoom.amazonia")

suppressPackageStartupMessages({
    library(datazoom.amazonia)
    library(dplyr)
    library(tidyr)
    library(readr)
    library(purrr)
    library(tibble)
})

################################################################################
# 2. LOAD DATA
################################################################################

dat <- load_mapbiomas(
    dataset   = "mapbiomas_cover",
    geo_level = "municipality"
)

# municipios da Amazônia Legal
municipios_amazonia <- datazoom.amazonia::municipalities %>%
    filter(legal_amazon == 1) %>%
    transmute(municipality_code = code_muni, uf = name_state)

################################################################################
# 3. BUILD AND AGGREGATE CLASS LEVELS (0–4)
################################################################################

make_level <- function(dat, drop_levels) {
    # remaining levels (class_level_0..4) minus those a dropar
    remaining <- setdiff(paste0("class_level_", 0:4), drop_levels)
    last_level <- tail(remaining, 1)
    
    dat %>%
        # seleciona colunas relevantes, renomeia para padrão interno
        select(
            time = year,
            municipality_code,
            municipality,
            state,
            value,
            aggregation = all_of(last_level)
        ) %>%
        
        inner_join(municipios_amazonia, by = "municipality_code") %>%
        mutate(area = as.numeric(value)) %>%
        select(time, municipality_code, state, aggregation, area)
}

# cria os dataframes por nível 
data1 <- make_level(dat, c("class_level_0", "class_level_1", "class_level_2", "class_level_3"))
data2 <- make_level(dat, c("class_level_0", "class_level_1", "class_level_2", "class_level_4"))
data3 <- make_level(dat, c("class_level_0", "class_level_1", "class_level_3", "class_level_4"))
data4 <- make_level(dat, c("class_level_0", "class_level_2", "class_level_3", "class_level_4"))
data5 <- make_level(dat, c("class_level_1", "class_level_2", "class_level_3", "class_level_4"))

# AGREGA ÁREA POR time + state + aggregation (soma por todos os municípios da Amazônia Legal)
agg_fun <- function(df) {
    df %>%
        group_by(time, state, aggregation) %>%
        summarise(area = sum(area, na.rm = TRUE), .groups = "drop")
}

data_all <- list(data1, data2, data3, data4, data5) %>%
    map_df(agg_fun) %>%
    distinct()

# transforma em wide
datafinal <- data_all %>%
    pivot_wider(
        id_cols = c(time, state),
        names_from = aggregation,
        values_from = area,
        values_fill = 0
    ) %>%
    # mantém a mesma ordem que você espera: group = state, time em seguida
    relocate(state, .before = time) %>%
    rename(group = state)

datafinal[is.na(datafinal)] <- 0

################################################################################
# 4. ADD MUNICIPAL AREA AND COMPUTE LAND USE SHARE (%)
################################################################################

areas_mun <- readr::read_rds("./app_map_mapbiomas_cover/global/area_municipios.rds")

areas_state <- areas_mun %>%
    inner_join(municipios_amazonia, by = "municipality_code") %>%
    group_by(uf) %>%
    summarise(area_km2 = sum(area_km2, na.rm = TRUE), .groups = "drop")

datafinal_area <- datafinal %>%
    left_join(areas_state, by = c("group" = "uf"))

saveRDS(datafinal_area, "data/mapbiomas_cobertura_est.rds")

################################################################################
# 5. BUILD VARIABLE DICTIONARIES (PT / EN)
################################################################################

# helper: vetor de traduções (EN -> PT) (comuns entre seus mapeamentos)
translate_en_to_pt <- c(
    "Aquaculture" = "Aquicultura",
    "Beach, Dune and Sand Spot" = "Praia e Dunas",
    "Citrus" = "Cítricos",
    "Coffee" = "Café",
    "Cotton" = "Algodão",
    "Forest Formation" = "Formação de Floresta",
    "Forest Plantation" = "Plantação de Floresta",
    "Floodable Forest" = "Floresta Inundável",
    "Grassland" = "Pradaria",
    "Hypersaline Tidal Flat" = "Salar",
    "Herbaceous Sandbank Vegetation" = "Restinga Herbácea",
    "Mangrove" = "Mangue",
    "Mining" = "Mineração",
    "Mosaic of Uses" = "Mosaico de Uso da Terra",
    "Not Observed" = "Não observado",
    "Other Non Forest Natural Formation" = "Outras formações naturais não florestais",
    "Other non Vegetated Areas" = "Outras áreas não vegetadas",
    "Other Perennial Crops" = "Outras Culturas Perenes",
    "Other Temporary Crops" = "Outras Culturas Temporárias",
    "Rice" = "Arroz",
    "River, Lake and Ocean" = "Rios, Lagos ou Oceanos",
    "Rocky Outcrop" = "Afloramento rochoso",
    "Savanna Formation" = "Formação de Savana",
    "Soybean" = "Soja",
    "Sugar cane" = "Cana-de-açúcar",
    "Urban Area" = "Infraestrutura Urbana",
    "Wetland" = "Pântano",
    "Wooded Sandbank Vegetation" = "Restinga Arborizada",
    "Perennial Crop" = "Culturas Perenes",
    "Temporary Crop" = "Culturas Temporárias",
    "Agriculture" = "Agricultura",
    "Farming" = "Fazenda",
    "Forest" = "Floresta",
    "Non Forest Natural Formation" = "Formação Natural Não Florestal",
    "Non vegetated area" = "Áreas não vegetadas",
    "Water and Marine Environment" = "Água",
    "Antropic" = "Antrópico",
    "Natural" = "Natural",
    "Undefined" = "Não aplicado"
)

# colunas para dicionário
columns <- colnames(datafinal)
special_vars <- c("group", "time")


dic_en <- tibble(
    var         = columns,
    x           = columns != "group" & columns != "time",
    y           = columns != "group" & columns != "time",
    color       = columns == "group",
    size        = !(columns %in% c("group", "time")),   # TRUE para quase tudo, FALSE para group/time
    slider      = !(columns %in% c("group", "time")),   # TRUE para quase tudo, FALSE para group/time
    label       = columns,
    desc        = columns,
    var_group   = "Mapbiomas",
    tipo        = 1,
    unidade     = "ha",
    categoria   = "Environment",
    subcategoria = "Land use"
)

# Ajustes fixos
dic_en <- dic_en %>%
    mutate(
        # garantir explicitamente que group e time têm size = FALSE e slider = FALSE
        size   = if_else(var %in% c("group", "time"), FALSE, size),
        slider = if_else(var %in% c("group", "time"), FALSE, slider),
        
        # color permanece TRUE só para group
        color  = if_else(var == "group", TRUE, FALSE),
        
        # x/y para group/time = FALSE (já definido acima, mas reforço explicitamente)
        x = if_else(var %in% c("group", "time"), FALSE, x),
        y = if_else(var %in% c("group", "time"), FALSE, y),
        
        # labels/descriptions fixos para group/time
        label = if_else(var == "time", "Year", label),
        label = if_else(var == "group", "State", label),
        desc  = if_else(var == "time", "Year", desc),
        desc  = if_else(var == "group", "State", desc)
    )

# Ajuste área_km2
dic_en <- dic_en %>%
    mutate(
        slider  = if_else(var == "area_km2", FALSE, slider),
        label   = if_else(var == "area_km2", "Municipality area (ha)", label),
        desc    = if_else(var == "area_km2",
                          "Territorial area of municipality in hectares (aggregated by state)",
                          desc),
        unidade = if_else(var == "area_km2", "ha", unidade)
    )

write.csv(dic_en, "data/mapbiomas_cobertura_est_dic_en.csv",
          fileEncoding = "UTF-8", row.names = FALSE)


# dicionario em português

dic_pt <- dic_en

dic_pt$label <- ifelse(dic_pt$label %in% names(translate_en_to_pt),
                       translate_en_to_pt[dic_pt$label],
                       dic_pt$label)

dic_pt$var <- ifelse(dic_pt$var %in% names(translate_en_to_pt),
                     translate_en_to_pt[dic_pt$var],
                     dic_pt$var)

# Ajustes fixos PT
dic_pt <- dic_pt %>%
    mutate(
        label = if_else(var == "time", "Ano", label),
        label = if_else(var == "group", "UF", label),
        desc  = if_else(var == "time", "Ano", desc),
        desc  = if_else(var == "group", "UF", desc),
        categoria = "Meio ambiente",
        subcategoria = "Uso da terra"
    )

write.csv(dic_pt, "data/mapbiomas_cobertura_est_dic.csv",
          fileEncoding = "UTF-8", row.names = FALSE)