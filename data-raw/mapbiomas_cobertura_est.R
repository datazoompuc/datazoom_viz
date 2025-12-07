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
    mutate(group = tolower(group)) %>%
    left_join(
        areas_state %>% mutate(uf = tolower(uf)),
        by = c("group" = "uf")
    )

saveRDS(datafinal_area, "data/mapbiomas_cobertura_est.rds")

################################################################################
# 5. BUILD VARIABLE DICTIONARIES (PT / EN)
################################################################################

columns <- colnames(datafinal)

# seu vetor de tradução EN -> PT (o que você já tem)
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
    "Natural/Antropic" = "Natural/Antropico",
    "Undefined" = "Não aplicado"
)

#  DICIONÁRIO EM PORTUGUÊS (var = nomes exatamente como em datafinal) 
dic_pt <- tibble::tibble(
    var         = columns,                        
    x           = !(columns %in% c("group", "time")),
    y           = !(columns %in% c("group", "time")),
    color       = ifelse(columns == "group", TRUE, FALSE),
    size        = !(columns %in% c("group", "time")),  # TRUE para quase tudo exceto group/time
    slider      = !(columns %in% c("group", "time")),  # TRUE para quase tudo exceto group/time
    label       = columns,  
    desc        = columns,  
    var_group   = "Mapbiomas",
    tipo        = 1,
    unidade     = "ha",
    categoria   = "Meio ambiente",
    subcategoria= "Uso da terra"
)

# garantir explicitamente group/time falsos
dic_pt <- dic_pt %>%
    dplyr::mutate(
        size   = ifelse(var %in% c("group", "time"), FALSE, size),
        slider = ifelse(var %in% c("group", "time"), FALSE, slider)
    )

# ajustar área (se sua coluna se chamar 'area_km2' mantenha, senão adapte)
if ("area_km2" %in% dic_pt$var) {
    dic_pt <- dic_pt %>%
        dplyr::mutate(
            slider  = ifelse(var == "area_km2", FALSE, slider),
            label   = ifelse(var == "area_km2", "Área do município (ha)", label),
            desc    = ifelse(var == "area_km2", "Área territorial do município em hectares (agregada por estado)", desc),
            unidade = ifelse(var == "area_km2", "ha", unidade)
        )
}

# aplicar traduções: se a coluna do datafinal é um nome em inglês presente no vetor, usar tradução
# caso as colunas já estejam em PT, isso não muda
dic_pt <- dic_pt %>%
    dplyr::mutate(
        # se var corresponde exatamente a uma chave EN do vetor, substitui label por tradução PT
        label = ifelse(var %in% names(translate_en_to_pt),
                       translate_en_to_pt[var],
                       label),
        # desc em PT (pode colocar a mesma coisa que label)
        desc  = label
    )

readr::write_csv(dic_pt, "data/mapbiomas_cobertura_est_dic.csv")

# DICIONÁRIO EM INGLÊS 
dic_en <- dic_pt %>%
    dplyr::mutate(
        # se var originalmente estava em EN (chave do vetor), label deve ser o EN
        label = ifelse(var %in% names(translate_en_to_pt),
                       var,
                       label),
        desc = label,
        categoria = "Environment",
        subcategoria = "Land use"
    )

readr::write_csv(dic_en, "data/mapbiomas_cobertura_est_dic_en.csv")