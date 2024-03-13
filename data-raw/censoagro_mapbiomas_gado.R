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

# load data from CENSO AGRO ---------------------------------------------------------------

censo <- load_censoagro(
  dataset = "livestock_production",
  raw_data = FALSE,
  geo_level = "municipality",
  time_period = 2017
)


censo <- censo %>%
  select(-"numero_de_estabelecimentos_agropecuarios_com_efetivo_da_pecuaria_v10010") %>%
  dplyr::rename(municipality_code="geo_id")%>%
  dplyr::rename(year="ano")%>%
  dplyr::rename("heads of cattle"="numero_de_cabecas_v2209")
    
nrow(censo) # [1] 5549
censo <- distinct(censo) 
nrow(censo) # 5549


table(censo$year)
# 2017 
# 5549 

munic_distinct <-distinct(data.frame(censo$municipality_code)) # 5549


# load data from MAPBIOMAS ---------------------------------------------------------------

# download treated Mapbiomas Cover data in English
df <- load_mapbiomas(dataset = "mapbiomas_cover",
                     raw_data = FALSE,
                     geo_level = "municipality",
                     language = "eng")


# Only level 4 interests us 
df_wider <- df %>%
  pivot_wider(id_cols=c("biome","municipality","state","municipality_code","year"), names_from=level_4, values_from = value)

# select the variables we are interested on 
colnames(df_wider)

df_wider <- df_wider %>%
  select("municipality_code", "year","Pasture")

df_wider <- df_wider %>%
  filter(year==2017)

df_wider <-distinct(df_wider)
#6535

munic_distinct <-distinct(data.frame(df_wider$municipality_code)) # 5571

df_wider <- df_wider %>%
  group_by(municipality_code) %>%
  mutate(Pasture= sum(Pasture,na.rm=TRUE))

df_wider <-distinct(df_wider) # 5571


# load data OF GEOGRAPHICAL INFO OF EACH MUNICIPALITY ---------------------------------------------------------------
municipalities <- datazoom.amazonia::municipalities
shapefile_mun <- datazoom.amazonia:::external_download("geo_municipalities",source="internal")

municipalities_with_geom <- inner_join(shapefile_mun,municipalities,by="code_muni")

municipalities_with_geom <- municipalities_with_geom[,c("code_muni","name_muni.x","name_state.x","geom")]

municipalities_with_geom <- municipalities_with_geom %>%
  rename(municipality_code=code_muni)%>%
  rename(municipality_name=name_muni.x)%>%
  rename(state_name=name_state.x)


#st_geometry(municipalities_with_geom) <- municipalities_with_geom$geom

#shapefile <- municipalities_with_geom[!st_is_empty(municipalities_with_geom), , drop=FALSE]


shapefile <- municipalities_with_geom %>% 
  sf::st_simplify(dTolerance = 400) %>% 
  sf::st_make_valid()

#colnames(shapefile)

# Merging data + shapefiles ---------------------------------------------------------------

# merge censo agro with mapbiomas --------------------------------------------------------
class(censo$municipality_code)
class(df_wider$municipality_code)
censo$municipality_code <- as.numeric(censo$municipality_code)


censo_df_wider <-full_join(censo,df_wider,by=c("year","municipality_code"))
nrow(censo) #5549
nrow(df_wider)
nrow(censo_df_wider)
ncol(censo)
ncol(df_wider)
ncol(censo_df_wider)
  
# merge data with shape --------------------------------------------------------
data <- right_join(shapefile,censo_df_wider, by="municipality_code") 


# Declare wich colum has the geographical info --------------------------------------------

st_geometry(data) <- data$geom


# saving in the data folder ---------------------------------------------------------------
# export ------------------------------------------------------------------
# save simplified sf for faster maps
#cols <- colnames(data)
#data <- rmapshaper::ms_simplify(data, 
# keep_shapes = TRUE, 
# keep = 0.01)

#colnames(data) <- cols



# adding a variable ------------------------------------------------------------------
data <- data %>%
  rename("Heads of Cattle" = "heads of cattle")

munic_distinct <-distinct(data.frame(data$municipality_code)) # 5572

class(data$`Heads of Cattle`)
class(data$Pasture)

data <- data %>%
  relocate(geom , .after = year)

data <- data %>%
  mutate(state_name=ifelse(state_name=="Amazônas","Amazonas",state_name))

# adding munic areas

areas_mun <- readr::read_rds("data/area_municipios.rds")

# adding area of each municipality
data <- data %>%
    left_join(areas_mun, by = "municipality_code")

saveRDS(data, "data/censoagro_mapbiomas_gado.rds")


################################################################################
#   DADOS DICIONARIO PARA O      files$param_file
################################################################################

datafinal<-readRDS("data/censoagro_mapbiomas_gado.rds")

#####################
# Build Dictionary 
#####################

# extract variables from data
columns <- colnames(datafinal)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = FALSE,
  y = FALSE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = columns,
  desc = columns,
  var_group = "Censo Agro and MapBiomas",
  tipo = 1,
  unidade = "",
  categoria= "", 
  subcategoria = ""
)

# tentando resolver a questão de terem várias linhas NA 
temp_param_table <-temp_param_table %>%
  drop_na()

# remover o codigo do municipio, pois nao será utilizado aqui
temp_param_table <- temp_param_table %>%
  filter(var != "municipality_code")


temp_param_table$label[3] <- "Year"
temp_param_table$label[1] <- "Municipality"
temp_param_table$label[2] <- "State"
temp_param_table$desc[3] <- "Year"
temp_param_table$desc[1] <- "Municipality"
temp_param_table$desc[2] <- "State"
temp_param_table$y[3] <- TRUE
temp_param_table$x[5:7] <- TRUE
temp_param_table$unidade[5] <- "Number"
temp_param_table$unidade[6] <- "ha"
temp_param_table$unidade[7] <- "Proportion"

#temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, 37))
#temp_param_table$size <- c(FALSE, TRUE, rep(FALSE, 37))
#temp_param_table$slider[2] <- TRUE

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/censoagro_mapbiomas_gado_dic_en.csv", fileEncoding = "UTF-8")


##################################
# Build Dictionary in Portuguese #
##################################

# extract variables from data
columns <- colnames(datafinal)

# generate dictionary
temp_param_table <- tibble(
    var = columns,
    x = FALSE,
    y = FALSE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Censo Agro e MapBiomas",
    tipo = 1,
    unidade = "",
    categoria= "", 
    subcategoria = ""
)

# tentando resolver a questão de terem várias linhas NA 
temp_param_table <-temp_param_table %>%
    drop_na()

# remover o codigo do municipio, pois nao será utilizado aqui
temp_param_table <- temp_param_table %>%
    filter(var != "municipality_code")


temp_param_table$label[3] <- "Ano"
temp_param_table$label[1] <- "Município"
temp_param_table$label[2] <- "Estado"
temp_param_table$desc[3] <- "Ano"
temp_param_table$desc[1] <- "Município"
temp_param_table$desc[2] <- "Estado"
temp_param_table$y[3] <- TRUE
temp_param_table$x[5:7] <- TRUE
temp_param_table$unidade[5] <- "Número"
temp_param_table$unidade[6] <- "ha"
temp_param_table$unidade[7] <- "Proporção" 
temp_param_table$label[5] <- temp_param_table$desc[5] <- "Cabeças de Gado"
temp_param_table$label[6] <- temp_param_table$desc[6] <- "Área de Pastagem"
temp_param_table$label[7] <- temp_param_table$desc[7] <- "Gado / Área de Pastagem"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/censoagro_mapbiomas_gado_dic.csv", fileEncoding = "UTF-8")


