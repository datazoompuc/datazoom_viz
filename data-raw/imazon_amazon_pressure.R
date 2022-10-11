############################################################
#### Generate rds data in the folder ./data/
############################################################

#### Packages
library(tidyverse)
library(datazoom.amazonia)
library(janitor)
library(sf)

# Download data

imazon_amazon_pressure <- load_imazon(dataset = "imazon_shp", raw_data = TRUE, geo_level = "municipality", language = "pt") %>%
  janitor::clean_names()

# data too  heavy
# keep with mininal variables
# colnames(imazon_amazon_pressure)
imazon_amazon_pressure <- imazon_amazon_pressure %>%
  sf::st_drop_geometry() %>% 
  mutate(code_muni = as.character(cd_geocmu)) %>%
  select(nm_municip, code_muni, area, uf, front_2020)
  
# Name codes of "front_2020"
imazon_amazon_pressure$front_2020_label[imazon_amazon_pressure$front_2020==0]  <- "Não florestal"
imazon_amazon_pressure$front_2020_label[imazon_amazon_pressure$front_2020==1]  <- "Desmatada"
imazon_amazon_pressure$front_2020_label[imazon_amazon_pressure$front_2020==2]  <- "Florestal sob pressão"
imazon_amazon_pressure$front_2020_label[imazon_amazon_pressure$front_2020==3]  <- "Florestal"
  
#saving 
saveRDS(imazon_amazon_pressure,
        file = "./data/imazon_amazon_pressure.rds"
)

#####################
# Build Dictionary
#####################

# call data
imazon_amazon_pressure <- readRDS("./data/imazon_amazon_pressure.rds")

# extract variables from data
columns <- colnames(imazon_amazon_pressure)

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
  var_group = "",
  unidade = "Unidade de medida",
  categoria = "Social",
  subcategoria = "Desenvolvimento"
)

# label variables
temp_param_table$label[temp_param_table$var == "cod_ibge"] <- "Código IBGE"

# label data category

# subcategoria variables


# block variables in graphs y-axis

# block variables in graphs x-axis

# allow variables in graphs size, color, and slider-axis

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/imazon_amazon_pressure_dic.csv", fileEncoding = "UTF-8")
