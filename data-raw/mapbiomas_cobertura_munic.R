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

saveRDS(dat, file = "data/mapbiomas_cobertura_munic_raw.rds")

################################################################################
# 3. BUILD AND AGGREGATE CLASS LEVELS (0–4)
################################################################################

make_level <- function(dat, drop_levels) {
    # identifica automaticamente o último nível que sobrou
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

saveRDS(datafinal, "data/mapbiomas_cobertura_munic.rds")

datafinal <- readRDS("data/mapbiomas_cobertura_munic.rds")

################################################################################
# 4. RENAME AND TRANSLATE MAPBIOMAS CLASSES
################################################################################

datafinal <- datafinal %>%
    select(
        time,
        municipality_code,
        group,
        "Aquicultura" = "Aquaculture",
        "Praia e Dunas" = "Beach, Dune and Sand Spot",
        "Cítricos" = "Citrus",
        "Café" = "Coffee",
        "Algodão" = "Cotton",
        "Floresta Inundável" = "Floodable Forest",
        "Formação de Floresta" = "Forest Formation",
        "Plantação de Floresta" = "Forest Plantation",
        "Pradaria" = "Grassland",
        "Vegetação Herbácea de Restinga" = "Herbaceous Sandbank Vegetation",
        "Salar" = "Hypersaline Tidal Flat",
        "Mangue" = "Mangrove",
        "Mineiração" = "Mining",
        "Mosaico de Uso da Terra" = "Mosaic of Uses",
        "Não observado" = "Not Observed",
        "Outras áreas não vegetadas" = "Other non Vegetated Areas",
        "Outras Culturas Perenes" = "Other Perennial Crops",
        "Outras Culturas Temporárias" = "Other Temporary Crops",
        "Dendê" = "Palm Oil",
        "Pastagem" = "Pasture",
        "Arroz" = "Rice",
        "Rios, Lagos ou Oceanos" = "River, Lake and Ocean",
        "Afloramento rochoso" = "Rocky Outcrop",
        "Formação de Savana" = "Savanna Formation",
        "Soja" = "Soybean",
        "Cana-de-açúcar" = "Sugar cane",
        "Infraestrutura Urbana" = "Urban Area",
        "Pântano" = "Wetland",
        "Restinga Arborizada" = "Wooded Sandbank Vegetation",
        "Culturas Perenes" = "Perennial Crop",
        "Culturas Temporárias" = "Temporary Crop",
        "Agricultura" = "Agriculture",
        "Fazenda" = "Farming",
        "Floresta" = "Forest",
        "Formação Natural Não Florestal" = "Non Forest Natural Formation",
        "Áreas não vegetadas" = "Non vegetated area",
        "Água" = "Water and Marine Environment",
        "Antrópico" = "Antropic",
        "Natural" = "Natural",
        "Natural/Antrópico" = "Natural/Antropic",
        "Não aplicado" = "Undefined"
    )

datafinal[is.na(datafinal)] <- 0

saveRDS(datafinal, "data/mapbiomas_cobertura_munic.rds")

################################################################################
# 5. ADD MUNICIPAL AREA AND COMPUTE LAND USE SHARE (%)
################################################################################

areas_mun <- readr::read_rds("./app_map_mapbiomas_cover/global/area_municipios.rds")

# une a área ao dataset principal
datafinal_area <- datafinal %>%
    left_join(areas_mun, by = "municipality_code")

# seleciona apenas as colunas de classes
cols_classes <- setdiff(names(datafinal_area),
                        c("time", "municipality_code", "group", "area_km2"))

datafinal_area <- datafinal_area %>%
    mutate(across(all_of(cols_classes),
                  ~ (.x / (area_km2 * 1e6)) * 100,
                  .names = "{.col}_perc"))

saveRDS(datafinal_area, "data/mapbiomas_cobertura_munic_area_part.rds")

################################################################################
# 6. BUILD VARIABLE DICTIONARIES (PT / EN)
################################################################################

columns <- colnames(datafinal)

dic_pt <- tibble(
    var = columns,
    x = c(FALSE, FALSE, TRUE, rep(TRUE, length(columns) - 3)),
    y = c(FALSE, FALSE, TRUE, rep(TRUE, length(columns) - 3)),
    color = c(FALSE, TRUE, rep(FALSE, length(columns) - 2)),
    size = c(FALSE, TRUE, rep(FALSE, length(columns) - 2)),
    slider = c(FALSE, FALSE, TRUE, rep(TRUE, length(columns) - 3)),
    label = columns,
    desc = columns,
    var_group = "Mapbiomas",
    tipo = 1,
    unidade = "m²",
    categoria = "Meio ambiente",
    subcategoria = "Uso da terra"
)

dic_pt$label[1:3] <- c("Ano", "Código do Município", "Município")
dic_pt$desc[1:3]  <- c("Ano", "Código do Município (IBGE)", "Município")

write.csv(dic_pt, "data/mapbiomas_cobertura_munic_dic.csv", fileEncoding = "UTF-8")

# English version
dic_en <- dic_pt
dic_en$label[1:3] <- c("Year", "Municipality Code", "Municipality")
dic_en$desc[1:3]  <- c("Year", "Municipality Code (IBGE)", "Municipality")
dic_en$unidade    <- "m²"
dic_en$categoria  <- "Environment"
dic_en$subcategoria <- "Land use"

write.csv(dic_en, "data/mapbiomas_cobertura_munic_dic_en.csv", fileEncoding = "UTF-8")