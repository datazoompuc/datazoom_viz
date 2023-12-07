################################################################################
#   SETUP
################################################################################

# Directory
setwd("C:/Users/carol/iCloudDrive/PUC/DATAZOOM/datazoom_viz/datazoom_viz")

# Memory
#Sys.setenv(R_MEM_SIZE = "8G")


Sys.setlocale("LC_ALL","English")
devtools::install_github("datazoompuc/datazoom.amazonia")


# Installing and loading packages (if not exist)
packages_to_install <- c("magrittr","devtools","readxl","tidyverse","stringr","googledrive","sf","sp")
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



################################################################################
#   DADOS PARA O      files$db_file
################################################################################

# load data from MAPBIOMAS ---------------------------------------------------------------

# download treated Mapbiomas Cover data in English
df <- load_mapbiomas(dataset = "mapbiomas_cover",
                       raw_data = FALSE,
                       geo_level = "municipality",
                       language = "eng")


# Only level 4 interests us 
df_wider <- df %>%
  pivot_wider(id_cols=c("biome","municipality","state","municipality_code","year"), names_from=level_4, values_from = value)


# load data OF GEOGRAPHICAL INFO OF EACH MUNICIPALITY ---------------------------------------------------------------
shapefile <- st_read("data/shapefiles/municipalities_legal_amazon.shp") %>% 
  sf::st_simplify(dTolerance = 400) %>% 
  sf::st_make_valid()

shapefile <- shapefile[!st_is_empty(shapefile), , drop=FALSE]

# load data OF AMAZONIA LEGAL?  ---------------------------------------------------------------
# Source: https://www.ibge.gov.br/geociencias/cartas-e-mapas/mapas-regionais/15819-amazonia-legal.html
#amazonialegal = st_read("data/shapefiles/Limites_Amazonia_Legal_2022.shx")

"C:\Users\carol\iCloudDrive\PUC\DATAZOOM\datazoom_viz\datazoom_viz\data\shapefiles\Limites_Amazonia_Legal_2022.shp"
amazonialegallimite_shapefile <- st_read("data/shapefiles/Limites_Amazonia_Legal_2022.shp") %>% 
  sf::st_simplify(dTolerance = 400) %>% 
  sf::st_make_valid()

amazonialegallimite_shapefile <- shapefile[!st_is_empty(amazonialegallimite_shapefile), , drop=FALSE]

# Merging data + shapefile ---------------------------------------------------------------
# merge with shape --------------------------------------------------------
data <- sp::merge(shapefile, data.frame(df_wider)) %>% 
  select(-fid, -cd_geocmu)

st_geometry(data) <- data$geometry


# saving in the data folder ---------------------------------------------------------------
# export ------------------------------------------------------------------
# save simplified sf for faster maps
cols <- colnames(data)
data <- rmapshaper::ms_simplify(data, 
                                keep_shapes = TRUE, 
                                keep = 0.01)

colnames(data) <- cols


saveRDS(data, "data/mapbiomas_cobertura.rds")


################################################################################
#   DADOS DICIONARIO PARA O      files$param_file
################################################################################

# dictionary --------------------------------------------------------------
# extract variables from data
temp_param_table <- read_csv("data/dz_munic_saude_dic.csv")

columns <- colnames(df)

temp_param_table <- temp_param_table %>%
  filter(var %in% columns) %>%
  mutate(unidade = case_when(
    stringr::str_detect(var, "t_") ~ "Mortalidade por 100 mil habitantes",
    stringr::str_detect(var, "n_") ~ "Leitos por 100 mil habitantes",
    TRUE ~ unidade
  ))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/saude_mortalidade_dic.csv", fileEncoding = "UTF-8")








