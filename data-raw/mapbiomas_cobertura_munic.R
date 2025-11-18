################################################################################
# 1. SETUP AND PACKAGE LOADING
################################################################################

devtools::install_github("datazoompuc/datazoom.amazonia")

suppressPackageStartupMessages({
    library(datazoom.amazonia)
    library(dplyr)
    library(tidyr)
    library(readr)
    library(stringr)
    library(purrr)
})

################################################################################
# 2. LOAD AND SAVE RAW MAPBIOMAS DATA
################################################################################

dat <- load_mapbiomas(dataset = "mapbiomas_cover", 
                      geo_level = "municipality")

################################################################################
# 3. BUILD AND AGGREGATE CLASS LEVELS (0–4)
################################################################################

make_level <- function(dat, drop_levels) {
    remaining <- setdiff(paste0("class_level_", 0:4), drop_levels)
    last_level <- tail(remaining, 1)
    
    dat %>%
        mutate(group = paste(municipality, "-", state)) %>%
        select(-municipality, -state, -biome, -class, -all_of(drop_levels)) %>%
        relocate(year, municipality_code, value, group) %>%
        rename(time = year, aggregation = !!sym(last_level), area = value)
}

# criar listas dos níveis (ajustando o que é excluído em cada um)
data1 <- make_level(dat, c("class_level_0", "class_level_1", "class_level_2", "class_level_3"))
data2 <- make_level(dat, c("class_level_0", "class_level_1", "class_level_2", "class_level_4"))
data3 <- make_level(dat, c("class_level_0", "class_level_1", "class_level_3", "class_level_4"))
data4 <- make_level(dat, c("class_level_0", "class_level_2", "class_level_3", "class_level_4"))
data5 <- make_level(dat, c("class_level_1", "class_level_2", "class_level_3", "class_level_4"))

# agregação
agg_fun <- function(df) {
    df$area <- as.numeric(df$area)
    aggregate(area ~ time + municipality_code + group + aggregation, df, sum)
}

data_list <- list(data1, data2, data3, data4, data5)
data_all <- bind_rows(lapply(data_list, agg_fun)) %>% distinct()

datafinal <- data_all %>%
    pivot_wider(names_from = aggregation, values_from = area, values_fill = 0)

datafinal[is.na(datafinal)] <- 0

municipios_amazonia <- datazoom.amazonia::municipalities %>%
    filter(legal_amazon == 1) %>%
    select(municipality_code = code_muni)

datafinal <- datafinal %>%
    inner_join(municipios_amazonia, by = "municipality_code")

################################################################################
# 4. ADD MUNICIPAL AREA AND COMPUTE LAND USE SHARE (%)
################################################################################

areas_mun <- readr::read_rds("./app_map_mapbiomas_cover/global/area_municipios.rds")

# une a área ao dataset principal
datafinal_area <- datafinal %>%
    left_join(areas_mun, by = "municipality_code")

# seleciona apenas as colunas de classes
cols_classes <- setdiff(names(datafinal_area),
                        c("time", "municipality_code", "group", "area_km2"))

# --- Save English version (default) ---
saveRDS(datafinal_area, "data/mapbiomas_cobertura_munic_en.rds")

# --- Create Portuguese version ---
translate_names <- c(
    "Aquaculture" = "Aquicultura",
    "Beach, Dune and Sand Spot" = "Praia e Dunas",
    "Citrus" = "Cítricos",
    "Coffee" = "Café",
    "Cotton" = "Algodão",
    "Floodable Forest" = "Floresta Inundável",
    "Forest Formation" = "Formação de Floresta",
    "Forest Plantation" = "Plantação de Floresta",
    "Grassland" = "Pradaria",
    "Herbaceous Sandbank Vegetation" = "Vegetação Herbácea de Restinga",
    "Hypersaline Tidal Flat" = "Salar",
    "Mangrove" = "Mangue",
    "Mining" = "Mineiração",
    "Mosaic of Uses" = "Mosaico de Uso da Terra",
    "Not Observed" = "Não observado",
    "Other non Vegetated Areas" = "Outras áreas não vegetadas",
    "Other Perennial Crops" = "Outras Culturas Perenes",
    "Other Temporary Crops" = "Outras Culturas Temporárias",
    "Palm Oil" = "Dendê",
    "Pasture" = "Pastagem",
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
    "Natural/Antropic" = "Natural/Antrópico",
    "Undefined" = "Não aplicado"
)

datafinal_pt <- datafinal_area
names(datafinal_pt) <- ifelse(names(datafinal_pt) %in% names(translate_names),
                              translate_names[names(datafinal_pt)],
                              names(datafinal_pt))

saveRDS(datafinal_pt, "data/mapbiomas_cobertura_munic_pt.rds")

################################################################################
# 5. BUILD VARIABLE DICTIONARIES (PT / EN)
################################################################################

# remove municipality_code (chave técnica, não usada na visualização)
data_dic <- datafinal_area %>%
    select(-municipality_code)

columns <- colnames(data_dic)

# DICIONÁRIO EM INGLÊS (baseado no MapBiomas original)
dic_en <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = TRUE,
    label = columns,
    desc = columns,
    var_group = "Mapbiomas",
    tipo = 1,
    unidade = "ha",
    categoria = "Environment",
    subcategoria = "Land use"
)

# Corrige campos fixos
dic_en$color[dic_en$var == "group"] <- TRUE
dic_en$size[dic_en$var == "group"] <- TRUE
dic_en$x[dic_en$var == "group"] <- FALSE
dic_en$y[dic_en$var == "group"] <- FALSE

dic_en$x[dic_en$var == "time"] <- FALSE
dic_en$y[dic_en$var == "time"] <- FALSE
dic_en$slider[dic_en$var == "time"] <- FALSE


dic_en$label[dic_en$var == "time"] <- "Year"
dic_en$label[dic_en$var == "group"] <- "Municipality"
dic_en$desc[dic_en$var == "time"] <- "Year"
dic_en$desc[dic_en$var == "group"] <- "Municipality"

dic_en$x[dic_en$var == "area_km2"] <- FALSE
dic_en$y[dic_en$var == "area_km2"] <- FALSE
dic_en$color[dic_en$var == "area_km2"] <- FALSE
dic_en$size[dic_en$var == "area_km2"] <- FALSE
dic_en$slider[dic_en$var == "area_km2"] <- FALSE
dic_en$label[dic_en$var == "area_km2"] <- "Área do município (km²)"
dic_en$desc[dic_en$var == "area_km2"] <- "Área territorial do município em quilômetros quadrados"

write.csv(dic_en, "data/mapbiomas_cobertura_munic_dic_en.csv",
          fileEncoding = "UTF-8", row.names = FALSE)

# PORTUGUESE DICTIONARY (TRANSLATED FROM ENGLISH)

dic_pt <- dic_en

# traduz tanto var quanto label com o mesmo vetor central
dic_pt$var   <- dplyr::recode(dic_pt$var, !!!translate_names)
dic_pt$label <- dplyr::recode(dic_pt$label, !!!translate_names)

# corrige metadados
dic_pt$label[dic_pt$var == "time"] <- "Ano"
dic_pt$label[dic_pt$var == "group"] <- "Município"
dic_pt$desc[dic_pt$var == "time"] <- "Ano"
dic_pt$desc[dic_pt$var == "group"] <- "Município"
dic_pt$categoria <- "Meio ambiente"
dic_pt$subcategoria <- "Uso da terra"

write.csv(dic_pt, "data/mapbiomas_cobertura_munic_dic.csv",
          fileEncoding = "UTF-8", row.names = FALSE)