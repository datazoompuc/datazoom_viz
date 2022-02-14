############################################################
#### Generate rds data in the folder ./data/
############################################################

#### Packages
library(tidyverse)
library(tibble)
library(zoo)
library(sf)
library(sp)
library(scales) # to use label_percent()
library(datazoom.amazonia)
library(rmapshaper)

####################
# 1) Call and clean data
###################
ips_2021 <- readxl::read_xlsx("C:\\Users\\DELL\\Desktop\\IPS_Amazonia_2021.xlsx")

ips_2021 <- ips_2021 %>%
  mutate(cod_ibge = `Código IBGE` )

###################
# TERRABRASILIS
###################
# read shapefile
shapefile <- st_read("data/shapefiles/municipalities_legal_amazon.shp")

# data too heavy (over 100mb)
# solution: simplify geometry
shapefile <- sf::st_simplify(shapefile, dTolerance = 400)

# plot(shapefile)
# shapefile$cod_ibge
  
######################################################
# merge data with amazon municipalities shapefile
######################################################
temporary_data <- sp::merge(shapefile, ips_2021, by.x = "cod_ibge", by.y = "cod_ibge")

temporary_data$estado <- temporary_data$uf

# unique(temporary_data$uf)
# temporary_data <- temporary_data %>% dplyr::filter(estado == "AC" | estado == "AP" | estado == "AM" | estado == "PA" | estado == "MA" | estado == "RR" | estado == "RO" | estado == "MT" | estado == "TO")
class(temporary_data$cod_ibge)
temporary_data$cod_ibge <- as.factor(temporary_data$cod_ibge)
temporary_data$estado <- as.factor(temporary_data$estado)

# groups at the level: municipio
temporary_data$group <- temporary_data$nm_municip

# unique rows
# temporary_data <- unique(temporary_data, by = c(cod_ibge, estado))
temporary_data <- temporary_data %>% group_by(cod_ibge, ano)

# arrange data by
temporary_data <- temporary_data %>%
  arrange(cod_ibge)

# Identify and remove duplicate data
# xxx <- temporary_data %>% distinct(cod_ibge, ano, .keep_all = TRUE)

# drop municipalities with empty geometry
temporary_data <- temporary_data[!st_is_empty(temporary_data), , drop = FALSE]

ips_2021 <- temporary_data
remove(temporary_data)

# save simplified sf for faster maps
ips_2021 <- rmapshaper::ms_simplify(ips_2021, 
                                         keep_shapes = TRUE, 
                                         keep = 0.01)
# save data
saveRDS(ips_2021,
        file = "./data/ips_2021.rds"
)

#####################
# Build Dictionary
#####################

# call data
ips_2021 <- readRDS("./data/ips_2021.rds")

# extract variables from data
columns <- colnames(ips_2021)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns,
  desc = columns,
  var_group = "Fonte de dados",
  unidade = "Unidade de medida",
  categoria = "Categoria principal",
  subcategoria = "Subcategoria"
)

# label variables
temp_param_table$label[temp_param_table$var == "cod_ibge"] <- "Código do município"
temp_param_table$label[temp_param_table$var == "nm_municip"] <- "Nome do município"
temp_param_table$label[temp_param_table$var == "uf"] <- "Estado"

# unidade variables
temp_param_table$unidade[temp_param_table$var == "geometry"] <- ""
temp_param_table$unidade[temp_param_table$var == "estado"] <- ""
temp_param_table$unidade[temp_param_table$var == "group"] <- ""

# var_group variables
temp_param_table$var_group[temp_param_table$var == "geometry"] <- "Terrabrasilis"
temp_param_table$var_group[temp_param_table$var == "estado"] <- "Geral"
temp_param_table$var_group[temp_param_table$var == "group"] <- ""

# label data category
temp_param_table$categoria[temp_param_table$var == "geometry"] <- ""
temp_param_table$categoria[temp_param_table$var == "estado"] <- ""
temp_param_table$categoria[temp_param_table$var == "group"] <- ""

# subcategoria variables
temp_param_table$subcategoria[temp_param_table$var == "geometry"] <- ""
temp_param_table$subcategoria[temp_param_table$var == "estado"] <- ""
temp_param_table$subcategoria[temp_param_table$var == "group"] <- ""

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "cod_ibge"] <- FALSE # "Código do município"
temp_param_table$y[temp_param_table$var == "nm_municip"] <- FALSE # "nm_municip"
temp_param_table$y[temp_param_table$var == "uf"] <- FALSE # "uf_x"
temp_param_table$y[temp_param_table$var == "ano"] <- FALSE # "ano"
temp_param_table$y[temp_param_table$var == "geometry"] <- FALSE # "geometry"
temp_param_table$y[temp_param_table$var == "group"] <- FALSE # "estado"
temp_param_table$y[temp_param_table$var == "estado"] <- FALSE # "estado"
temp_param_table$y[temp_param_table$var == "group"] <- FALSE 

# block variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "cod_ibge"] <- FALSE # "Código do município"
temp_param_table$x[temp_param_table$var == "nm_municip"] <- FALSE # "nm_municip"
temp_param_table$x[temp_param_table$var == "uf"] <- FALSE # "uf_x"
temp_param_table$x[temp_param_table$var == "ano"] <- FALSE # "ano"
temp_param_table$x[temp_param_table$var == "geometry"] <- FALSE # "geometry"
temp_param_table$x[temp_param_table$var == "estado"] <- FALSE # "estado"
temp_param_table$x[temp_param_table$var == "group"] <- FALSE 

# allow variables in graphs size, color, and slider-axis
temp_param_table$color[temp_param_table$var == "estado"] <- TRUE #

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ips_2021_dic.csv", fileEncoding = "UTF-8")
