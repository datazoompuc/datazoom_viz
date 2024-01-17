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
municipalities <- datazoom.amazonia::municipalities
shapefile_mun <- datazoom.amazonia:::external_download("geo_municipalities",source="internal")

municipalities_with_geom <- inner_join(shapefile_mun,municipalities,by="code_muni")

municipalities_with_geom <- municipalities_with_geom[,c("code_muni","geom","legal_amazon")]

municipalities_with_geom <- municipalities_with_geom %>%
  rename(municipality_code=code_muni)


#st_geometry(municipalities_with_geom) <- municipalities_with_geom$geom

#shapefile <- municipalities_with_geom[!st_is_empty(municipalities_with_geom), , drop=FALSE]


shapefile <- municipalities_with_geom %>% 
  sf::st_simplify(dTolerance = 400) %>% 
  sf::st_make_valid()

#colnames(shapefile)

# Merging data + shapefiles ---------------------------------------------------------------
# merge data with shape --------------------------------------------------------
data <- right_join(shapefile,df_wider, by="municipality_code") 


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


saveRDS(data, "data/mapbiomas_cobertura.rds")


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


# temp_param_table$label[temp_param_table$var==	 "Aquicultura"]= "Aquaculture"  
# temp_param_table$label[temp_param_table$var==	 "Praia e Dunas"]="Beach and Dune" 
# temp_param_table$label[temp_param_table$var==	 "Cítricos"] = "Citrus"
# temp_param_table$label[temp_param_table$var==	   "Café" ] = "Coffe"    
# temp_param_table$label[temp_param_table$var==	 "Algodão" ]= "Cotton"
# temp_param_table$label[temp_param_table$var==	 "Formação de Floresta"] = "Forest Formation"
# temp_param_table$label[temp_param_table$var==	   " Plantação de Floresta" ]= "Forest Plantation"         
# temp_param_table$label[temp_param_table$var==	  "Pradaria" ]= "Grassland"                  
# temp_param_table$label[temp_param_table$var==	 "Mineiração"]= "Mining" 
# temp_param_table$label[temp_param_table$var==	 "Mosaico de Uso da Terra"]="Land Use Mosaic"
# temp_param_table$label[temp_param_table$var==	 "Cana-de-açúcar"] = "Sugar Cane" 
# temp_param_table$label[temp_param_table$var==	"Mangue"]= "Magrove"  
# temp_param_table$label[temp_param_table$var==	  "Salar"] = "Salt flat"                
# temp_param_table$label[temp_param_table$var==	  "Não observado"]="Non Observed"                     
# temp_param_table$label[temp_param_table$var==	  "Outras formações naturais não florestais"]= "Other Non Forest Natural Formation"
# temp_param_table$label[temp_param_table$var==	 "Outras áreas não vegetadas"]= "Other Non Vegetated Area" 
# temp_param_table$label[temp_param_table$var==	  "Outras Culturas Perenes"] =  "Other Perennial Crops"           
# temp_param_table$label[temp_param_table$var==	 "Outras Culturas Temporárias"]=  "Other Temporary Crops"            
# temp_param_table$label[temp_param_table$var==	 "Arroz"] =  "Rice"                        
# temp_param_table$label[temp_param_table$var==	 "Rios, Lagos ou Oceanos"] =  "River, Lake and Ocean"            
# temp_param_table$label[temp_param_table$var==	"Afloramento rochoso"] =  "Rocky outcrop"                     
# temp_param_table$label[temp_param_table$var==	  "Formação de Savana" ]=  "Savanna Formation"              
# temp_param_table$label[temp_param_table$var==	  "Soja"] =  "Soy Beans"
# temp_param_table$label[temp_param_table$var==	 "Pastagem" ]=  "Pasture" 
# temp_param_table$label[temp_param_table$var==	"Infraestrutura Urbana"] =  "Urban Infrastructure"
# temp_param_table$label[temp_param_table$var==	"Formação de Floresta"]=  "Forest Formation"                     
# temp_param_table$label[temp_param_table$var==	"Pântano"]=  "Wetland"                          
# temp_param_table$label[temp_param_table$var==	  "Restinga Arborizada"]=  "Wooded Restinga"                 
# temp_param_table$label[temp_param_table$var==	  "Culturas Perenes"]=  "Perennial Crops"                
# temp_param_table$label[temp_param_table$var==	  "Culturas Temporárias" ]=  "Temporary Crops"                
# temp_param_table$label[temp_param_table$var==	 "Agricultura"] =  "Agriculture"                     
# temp_param_table$label[temp_param_table$var==	  "Floresta" ]=  "Forest"                       
# temp_param_table$label[temp_param_table$var==	 "Formação Natural Não Florestal"] =  " Non Forest Natural Formation"   
# temp_param_table$label[temp_param_table$var==	 "Fazenda" ]=  " Farming"                      
# temp_param_table$label[temp_param_table$var==	  "Áreas não vegetadas" ]=  "Non Vegetated Area"           
# temp_param_table$label[temp_param_table$var==	  "Água"] = "Water"                    
# temp_param_table$label[temp_param_table$var==	  "Antrópico"] = "Anthropic"                       
# temp_param_table$label[temp_param_table$var==	"Natural"]=  "Natural"    


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_munic_savana_dic_en.csv", fileEncoding = "UTF-8")





