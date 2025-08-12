################################################################################
#   SETUP
################################################################################

# Directory
setwd("C:\\Users\\laura\\OneDrive\\Laura\\economia\\pibic\\datazoom_viz")
# Memory
#Sys.setenv(R_MEM_SIZE = "8G")


Sys.setlocale("LC_ALL","English")
devtools::install_github("datazoompuc/datazoom.amazonia")


# Installing and loading packages (if not exist)
packages_to_install <- c("magrittr","devtools","readxl","tidyverse","stringr","googledrive","sf","sp","rmapshaper")
# Function to install and load a package if not already installed
install_and_load_package <- function(package_name) {
  if (!require(package_name, character.only = TRUE)) {
    install.packages(package_name)
    library(package_name, character.only = TRUE)
  }
}
# Loop through the list of packages and install/load them
for (package in packages_to_install) {
  install_and_load_package(package)
}

library(datazoom.amazonia)
library(readxl)
library(tidyverse)
library(stringr)
library(sf)
library(sp)
library(rmapshaper)


################################################################################
#   DADOS PARA O      files$db_file
################################################################################

# load data from MAPBIOMAS ---------------------------------------------------------------

# download treated Mapbiomas Cover data in English
data <- load_mapbiomas(dataset = "mapbiomas_cover",
                       raw_data = FALSE,
                       geo_level = "municipality",
                       language = "eng")


# Only level 4 interests us 
data <- data %>%
  pivot_wider(id_cols=c("biome","municipality","state","municipality_code","year"), names_from=class_level_4, values_from = value)


# load data OF GEOGRAPHICAL INFO OF EACH MUNICIPALITY ---------------------------------------------------------------
municipalities <- datazoom.amazonia::municipalities
shapefile_mun <- datazoom.amazonia:::external_download("geo_municipalities",source="internal")

municipalities_with_geom <- inner_join(shapefile_mun,municipalities,by="code_muni")

municipalities_with_geom <- municipalities_with_geom[,c("code_muni","geom","legal_amazon")]

municipalities_with_geom <- municipalities_with_geom %>%
  rename(municipality_code=code_muni)


#st_geometry(municipalities_with_geom) <- municipalities_with_geom$geom

#shapefile <- municipalities_with_geom[!st_is_empty(municipalities_with_geom), , drop=FALSE]


shapefile <- municipalities_with_geom %>% 
    sf::st_make_valid() %>%
    sf::st_simplify(dTolerance = 400) 

shapefile <- shapefile %>%
    rmapshaper::ms_simplify()
  

#colnames(shapefile)

# Merging data + shapefiles ---------------------------------------------------------------
# merge data with shape --------------------------------------------------------

# .parquet does not support shapefiles - let's keep them separate
#data <- right_join(shapefile,data, by="municipality_code") 


# Declare wich colum has the geographical info --------------------------------------------

#st_geometry(data) <- data$geom


# saving in the data folder ---------------------------------------------------------------
# export ------------------------------------------------------------------
# save simplified sf for faster maps
#cols <- colnames(data)
#data <- rmapshaper::ms_simplify(data, 
                                # keep_shapes = TRUE, 
                                # keep = 0.01)

#colnames(data) <- cols


areas_mun <- readr::read_rds("global/area_municipios.rds")

# adding area of each municipality
data <- data %>%
    tidyr::drop_na(municipality_code) %>%
    left_join(areas_mun, by = "municipality_code")

# making it lighter

# data <- data %>%
#     select(
#         - c(
#         "Non Observed", starts_with("Other")
#         )
#     )
# 
# data <- data %>%
#     filter(
#         year %in% c(
#             "1985", "1990", "1995", "2000", "2005", "2010", "2015", "2020", "2022"
#         )
#     )

# mapbiomas_cover is not properly treates. Colnames appear as 1.1. Forest Formation instead of simply Forest Formation
## code to remove the leading numbers and dots
### this should no longer be necessary ater data treatment is fixed
names(data) <- sub("^\\d+(\\.\\d+)*\\.?\\s*", "", names(data))

data <- data %>%
    relocate(
        municipality_code, municipality, state, year, "Forest Formation",
        "Savanna Formation", "Pasture", "Soybean", "Mining"
    )

# data <- data %>%
#     mutate(across(where(is.numeric), as.integer))

# we no longer need to drop data to make it lighter
# using .parquet allows us to keep everything

#data <- data %>%
#    filter(
#        as.numeric(year) %% 12 == 6
#    )

# group data by year
## .parquet understands each one as a dif folder - loading is much faster
data |>
    dplyr::group_by(year) |>
    # Write data as .parquet
    arrow::write_dataset(path = "app_map_mapbiomas_cover/mapbiomas_cobertura.parquet", format = "parquet")

# Write spacial data as .rds 
## .parquet does not support spacial data
saveRDS(shapefile, "global/munic_shapefile.rds")


################################################################################
#   DADOS DICIONARIO PARA O      files$param_file
################################################################################

datafinal<-readRDS("data/mapbiomas_cobertura.rds")

#####################
# Build Dictionary 
#####################

# extract variables from data
columns <- colnames(datafinal)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = columns,
  desc = columns,
  var_group = "Mapbiomas",
  tipo = 1,
  unidade = "ha",
  categoria= "Meio ambiente", 
  subcategoria = "Uso da terra"
)

# tentando resolver a questão de terem várias linhas NA 
temp_param_table <-temp_param_table %>%
  drop_na()

# remover o codigo do municipio, pois nao será utilizado aqui
temp_param_table <- temp_param_table %>%
  filter(var != "municipality_code")


temp_param_table$label[5] <- "Ano"
temp_param_table$label[3] <- "Município"
temp_param_table$desc[5] <- "Ano"
temp_param_table$desc[3] <- "Município"
temp_param_table$x[1:5] <- FALSE
temp_param_table$x[36] <- FALSE
temp_param_table$y[1:5] <- FALSE
temp_param_table$y[36] <- FALSE

#temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, 37))
#temp_param_table$size <- c(FALSE, TRUE, rep(FALSE, 37))
temp_param_table$slider[5] <- TRUE


temp_param_table$label[temp_param_table$var== "Aquaculture"] = "Aquicultura"
temp_param_table$label[temp_param_table$var== "Beach and Dune"] = "Praia e Dunas"
temp_param_table$label[temp_param_table$var== "Citrus"] = "Cítricos"
temp_param_table$label[temp_param_table$var== "Coffe"] = "Café"
temp_param_table$label[temp_param_table$var== "Cotton"] = "Algodão"
temp_param_table$label[temp_param_table$var== "Forest Formation"] = "Formação de Floresta"
temp_param_table$label[temp_param_table$var== "Forest Plantation"] = " Plantação de Floresta"
temp_param_table$label[temp_param_table$var== "Grassland"] = "Pradaria"
temp_param_table$label[temp_param_table$var== "Mining"] = "Mineiração"
temp_param_table$label[temp_param_table$var== "Land Use Mosaic"] = "Mosaico de Uso da Terra"
temp_param_table$label[temp_param_table$var== "Sugar Cane"] = "Cana-de-açúcar"
temp_param_table$label[temp_param_table$var== "Magrove"] = "Mangue"
temp_param_table$label[temp_param_table$var== "Salt flat"] = "Salar"
temp_param_table$label[temp_param_table$var== "Non Observed"] = "Não observado"
temp_param_table$label[temp_param_table$var== "Other Non Forest Natural Formation"] = "Outras formações naturais não florestais"
temp_param_table$label[temp_param_table$var== "Other Non Vegetated Area"] = "Outras áreas não vegetadas"
temp_param_table$label[temp_param_table$var== "Other Perennial Crops"] = "Outras Culturas Perenes"
temp_param_table$label[temp_param_table$var== "Other Temporary Crops"] = "Outras Culturas Temporárias"
temp_param_table$label[temp_param_table$var== "Rice"] = "Arroz"
temp_param_table$label[temp_param_table$var== "River, Lake and Ocean"] = "Rios, Lagos ou Oceanos"
temp_param_table$label[temp_param_table$var== "Rocky outcrop"] = "Afloramento rochoso"
temp_param_table$label[temp_param_table$var== "Savanna Formation"] = "Formação de Savana"
temp_param_table$label[temp_param_table$var== "Soy Beans"] = "Soja"
temp_param_table$label[temp_param_table$var== "Pasture"] = "Pastagem"
temp_param_table$label[temp_param_table$var== "Urban Infrastructure"] = "Infraestrutura Urbana"
temp_param_table$label[temp_param_table$var== "Forest Formation"] = "Formação de Floresta"
temp_param_table$label[temp_param_table$var== "Wetland"] = "Pântano"
temp_param_table$label[temp_param_table$var== "Wooded Restinga"] = "Restinga Arborizada"
temp_param_table$label[temp_param_table$var== "Perennial Crops"] = "Culturas Perenes"
temp_param_table$label[temp_param_table$var== "Temporary Crops"] = "Culturas Temporárias"
temp_param_table$label[temp_param_table$var== "Agriculture"] = "Agricultura"
temp_param_table$label[temp_param_table$var== "Forest"] = "Floresta"
temp_param_table$label[temp_param_table$var== " Non Forest Natural Formation"] = "Formação Natural Não Florestal"
temp_param_table$label[temp_param_table$var== " Farming"] = "Fazenda"
temp_param_table$label[temp_param_table$var== "Non Vegetated Area"] = "Áreas não vegetadas"
temp_param_table$label[temp_param_table$var== "Water"] = "Água"
temp_param_table$label[temp_param_table$var== "Anthropic"] = "Antrópico"
temp_param_table$label[temp_param_table$var== "Natural"] = "Natural"


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_munic_savana_dic.csv", fileEncoding = "UTF-8")


##############################
# Build Dictionary in English
##############################

#exclui a variável que não será utilizada na construção do dicionário
datafinal<-datafinal %>%
  select(-municipality_code)

# extract variables from data
columns <- colnames(datafinal)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = columns,
  desc = columns,
  var_group = "Mapbiomas",
  tipo = 1,
  unidade = "ha",
  categoria= "Environment", 
  subcategoria = "Use of land"
)


temp_param_table$label[5] <- "Year"
temp_param_table$label[3] <- "Municipality"
temp_param_table$desc[5] <- "Year"
temp_param_table$desc[3] <- "Municipality"
temp_param_table$x[1:5] <- FALSE
temp_param_table$x[36] <- FALSE
temp_param_table$y[1:5] <- FALSE
temp_param_table$y[36] <- FALSE

#temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, 37))
#temp_param_table$size <- c(FALSE, TRUE, rep(FALSE, 37))
temp_param_table$slider[5] <- TRUE

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_munic_savana_dic_en.csv", fileEncoding = "UTF-8")

