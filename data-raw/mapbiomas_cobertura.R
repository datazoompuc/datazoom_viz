################################################################################
#   SETUP
################################################################################

# Directory
#setwd("C:/Users/carol/iCloudDrive/PUC/DATAZOOM/datazoom_viz/datazoom_viz")
setwd("C:/Users/carolinamoura/Documents/GitHub/datazoom_viz")
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

colnames(shapefile)
#[1] "fid"        "nm_municip" "cd_geocmu"  "uf"         "cod_ibge"   "geometry"  
# nao tem variavel amazonia legal 
shapefile <- shapefile[!st_is_empty(shapefile), , drop=FALSE]

# load data OF LIMITES AMAZONIA LEGAL?  ---------------------------------------------------------------
# Source: https://www.ibge.gov.br/geociencias/cartas-e-mapas/mapas-regionais/15819-amazonia-legal.html
#amazonialegal = st_read("data/shapefiles/Limites_Amazonia_Legal_2022.shx")

amazonialegallimite_shapefile <- st_read("data/shapefiles/Limites_Amazonia_Legal_2022_shp/Limites_Amazonia_Legal_2022.shp") %>% 
  sf::st_simplify(dTolerance = 400) %>% 
  sf::st_make_valid()

amazonialegallimite_shapefile <- shapefile[!st_is_empty(amazonialegallimite_shapefile), , drop=FALSE]

amazonialegallimite_shapefile <-amazonialegallimite_shapefile %>% 
  select(-fid, -cd_geocmu)

amazonialegallimite_shapefile <-amazonialegallimite_shapefile %>% 
  rename(geometry_amazonialegallimite =geometry)


# Merging data + shapefiles ---------------------------------------------------------------
# merge data with shape --------------------------------------------------------
data <- sp::merge(shapefile, data.frame(df_wider)) %>% 
  select(-fid, -cd_geocmu)

# merge data-shape with amazonialegallimite_shapefile --------------------------------------
data <- sp::merge(amazonialegallimite_shapefile, data) 

# Declare wich colum has the geographical info --------------------------------------------

# I do the line below, but I am not surethat is possible to set 2 times geometry for a unique data frame. In the script server, we may have to run again the line below. Or even, we have to save the amazonia legal limites shapefile in a different file
st_geometry(data) <- data$geometry_amazonialegallimite

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






