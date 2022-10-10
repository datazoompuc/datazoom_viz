############################################################
#### Generate rds data in the folder ./data/
############################################################

#### Packages
library(tidyverse)
library(datazoom.amazonia)
library(janitor)

# Download data

imazon_amazon_pressure <- load_imazon(dataset = "imazon_shp", raw_data = TRUE, geo_level = "municipality", language = "pt") %>%
  janitor::clean_names()


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
write.csv(temp_param_table, file = "./data/imazon_amazon_pressure.csv", fileEncoding = "UTF-8")
