Sys.setlocale("LC_ALL","English")
devtools::install_github("datazoompuc/datazoom.amazonia")
setwd("C:/Users/carol/iCloudDrive/PUC/DATAZOOM/datazoom_viz/datazoom_viz")
Sys.setenv(R_MAX_MEM_SIZE = "8G")

# Check the current memory limit
memory.limit()

# Set the memory limit to 8 gigabytes
memory.limit(size = 8000)


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




