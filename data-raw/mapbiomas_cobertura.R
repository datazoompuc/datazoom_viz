################################################################################
#   SETUP
################################################################################

devtools::install_github("datazoompuc/datazoom.amazonia")

library(datazoom.amazonia)
library(readxl)
library(tidyverse)
library(stringr)
library(sf)
library(sp)
library(rmapshaper)
library(arrow)


################################################################################
#   DADOS PARA O      files$db_file
################################################################################

# load data from MAPBIOMAS ---------------------------------------------------------------

# download treated Mapbiomas Cover data in English
data <- load_mapbiomas(
    dataset = "mapbiomas_cover",
    raw_data = FALSE,
    geo_level = "municipality",
    language = "eng"
) |>
    pivot_wider(
        id_cols    = c("biome", "municipality", "state", "municipality_code", "year"),
        names_from = class_level_4,
        values_from = value
    )

# load data OF GEOGRAPHICAL INFO OF EACH MUNICIPALITY ---------------------------------------------------------------

shapefile <- datazoom.amazonia:::external_download("geo_municipalities", source = "internal") |> 
    left_join(datazoom.amazonia::municipalities, by = "code_muni") |> 
    select(municipality_code = code_muni, geom, legal_amazon) |>
    st_make_valid() |>
    st_simplify(dTolerance = 400) |>
    rmapshaper::ms_simplify()

# Add area of each municipality ------------------------------------------

areas_mun <- readr::read_rds(".\\app_map_mapbiomas_cover\\global\\area_municipios.rds")

data <- data |>
    drop_na(municipality_code) |>
    left_join(areas_mun, by = "municipality_code") |>
    rename_with(~sub("^\\\\d+(\\\\.\\\\d+)*\\\\.?\\\\s*", "", .x)) |>
    relocate(municipality_code, municipality, state, year,
             "Forest Formation", "Savanna Formation", "Pasture", "Soybean", "Mining")


################################################################################
# EXPORT
################################################################################


# Export data in parquet format (faster per year)
data |>
    dplyr::group_by(year) |>
    # Write data as .parquet
    arrow::write_dataset(
        path = "app_map_mapbiomas_cover/mapbiomas_cobertura.parquet", 
        format = "parquet")

# Saves shapefile in .rds (parquet does not support geometry)
saveRDS(shapefile, ".\\app_map_mapbiomas_cover\\global\\munic_shapefile.rds")


################################################################################
#   DADOS DICIONARIO PARA O      files$param_file
################################################################################

datafinal <- arrow::read_parquet("./app_map_mapbiomas_cover/mapbiomas_cobertura.parquet") %>% collect()

#####################
# Function to generate base dictionary 
#####################

build_dictionary <- function(data, language = c("pt", "en")) {
    language <- match.arg(language)
    labels <- colnames(data)
    
    base_dict <- tibble(
        var         = labels,
        x           = TRUE,
        y           = TRUE,
        color       = FALSE,
        size        = FALSE,
        slider      = FALSE,
        label       = labels,
        desc        = labels,
        var_group   = "Mapbiomas",
        tipo        = 1,
        unidade     = "ha",
        categoria   = ifelse(language == "pt", "Meio ambiente", "Environment"),
        subcategoria = ifelse(language == "pt", "Uso da terra", "Use of land")
    ) |>
        drop_na() |>
        filter(var != "municipality_code") |> 
        mutate(
            x = replace(x, 1:5, FALSE),
            y = replace(y, 1:5, FALSE),
            slider = replace(slider, 5, TRUE),
            label = replace(label, 3, ifelse(language == "pt", "Município", "Municipality")),
            label = replace(label, 5, ifelse(language == "pt", "Ano", "Year")),
            desc  = label
        )
    
    return(base_dict)
}

#####################
# Function to apply PT-EN translations
#####################

apply_label_translations <- function(dict, translations) {
    dict |>
        mutate(label = ifelse(var %in% names(translations),
                              translations[var],
                              label))
}

#####################
# PT
#####################

translations_pt <- c(
    "Aquaculture" = "Aquicultura",
    "Beach, Dune and Sand Spot" = "Praias, Dunas e Pontos de Areia",
    "Citrus" = "Cítricos",
    "Coffee" = "Café",
    "Cotton" = "Algodão",
    "Forest Formation" = "Formação de Floresta",
    "Forest Plantation" = "Plantação de Floresta",
    "Floodable Forest" = "Floresta Inundável",
    "Grassland" = "Pradaria",
    "Hypersaline Tidal Flat" = "Planícies Hipersalinas Costeiras",
    "Herbaceous Sandbank Vegetation" = "Restinga Herbácea",
    "Mining" = "Mineração",
    "Mosaic of Uses" = "Mosaico de Uso da Terra",
    "Sugar cane" = "Cana-de-açúcar",
    "Magrove" = "Mangue",
    "Salt flat" = "Salar",
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
    "Pasture" = "Pastagem",
    "Urban Area" = "Área Urbana",
    "Wetland" = "Pântano",
    "Wooded Sandbank Vegetation" = "Restinga Arborizada",
    "Palm Oil" = "Óleo de Palma",
    "Perennial Crops" = "Culturas Perenes",
    "Temporary Crops" = "Culturas Temporárias",
    "Agriculture" = "Agricultura",
    "Forest" = "Floresta",
    "Non Forest Natural Formation" = "Formação Natural Não Florestal",
    "Farming" = "Fazenda",
    "Non Vegetated Area" = "Áreas não vegetadas",
    "Water" = "Água",
    "Anthropic" = "Antrópico",
    "Natural" = "Natural"
)

dic_pt <- build_dictionary(datafinal, "pt") |>
    apply_label_translations(translations_pt)

write_csv(dic_pt, "./app_map_mapbiomas_cover/dic.csv")

#####################
# EN
#####################

dic_en <- build_dictionary(datafinal, "en")

write_csv(dic_en, "./app_map_mapbiomas_cover/dic.csv")