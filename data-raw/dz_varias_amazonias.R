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


####################
# 1) Call and clean data
###################

###################
#IMAZON - AMAZON PRESSURE
###################
imazon_amazon_pressure  <- readRDS(file = "data/imazon_amazon_pressure.rds")
imazon_amazon_pressure$cod_munic_ibge <- imazon_amazon_pressure$code_muni
class(imazon_amazon_pressure$cod_munic_ibge) <-  'character'

###################
# IMAZON - IPS 2021
###################

ips <- readRDS(file = "data/ips_2021.rds")
ips <- ips %>%
  janitor::clean_names() %>%
  select(cod_ibge, ips_amazonia_2021)

# drop latitude and longitude info
ips <- ips %>% st_drop_geometry()

ips$cod_munic_ibge <- ips$cod_ibge

###################
#PPM - IBGE
###################
ppm_livestock <- readRDS(file = "data/ppm_municipality_livestock_inventory.rds")

ppm_livestock= ppm_livestock%>%
  dplyr::filter(ano == 2019)%>% # filtra apenas para um ano específico. no caso, o último que é 2019
  dplyr::select(geo_id, num_v2670)

ppm_livestock$cod_munic_ibge <- ppm_livestock$geo_id
class(ppm_livestock$cod_munic_ibge) <-  'character'


###################
#PAM - IBGE - SOJA
###################
pam_municipality_all_crops_2000_19= readRDS('data/pam_municipality_all_crops_2000_19.rds')
pam_municipality_all_crops_2000_19[is.na(pam_municipality_all_crops_2000_19)] <- 0

pam_municipality_all_crops_2000_19 <- pam_municipality_all_crops_2000_19%>%
  dplyr::filter(ano == "2019") %>%  # filtra apenas para um ano específico. no caso, o último que é 2019
  dplyr::select(geo_id, quant_v40124)
  

pam_municipality_all_crops_2000_19$cod_munic_ibge <- pam_municipality_all_crops_2000_19$geo_id
class(pam_municipality_all_crops_2000_19$cod_munic_ibge) <-  'character'

###################
#PIB - IBGE
###################
#pib <- readRDS(file = "data/pib_municipality_dza.rds")
#pib$cod_munic_ibge <- pib$municipio_codigo
#class(pib$cod_munic_ibge) <-  'character'
#class(pib$ano) <-  'character'

###################
# INPE - PRODES
###################
prodes <- readRDS(file = "data/prodes.rds")
prodes <- prodes %>%
  janitor::clean_names()

# generate variable by the share of municipality total area
prodes <- prodes %>%
  mutate(
    prop_desmatado = desmatado / area_km2,
    prop_incremento = incremento / area_km2,
    prop_floresta = floresta / area_km2,
    prop_nao_floresta = nao_floresta / area_km2,
    prop_hidrografia = hidrografia / area_km2
  ) %>%
  select(
    cod_munic_ibge,
    ano,
    desmatado,
    incremento,
    floresta,
    nao_floresta,
    hidrografia,
    prop_desmatado,
    prop_incremento,
    prop_floresta,
    prop_nao_floresta,
    prop_hidrografia
  ) %>%
  arrange(cod_munic_ibge, ano)

prodes <- prodes %>% 
  dplyr::filter(ano == "2021") # filtra apenas para um ano específico. no caso, o último que é 2021
  
# Identify and remove duplicate data
prodes <- prodes %>% distinct(cod_munic_ibge, ano, .keep_all = TRUE)
class(prodes$cod_munic_ibge) <-  'character'
class(prodes$ano) <-  'character'

###########################
# edit data to merge
###########################

#class(deter$ano) <-  'numeric'


###########################
# merge all data
###########################
dz_varias_amazonias <- imazon_amazon_pressure %>%
  full_join(ips, by = c("cod_munic_ibge")) %>%
  full_join(pam_municipality_all_crops_2000_19, by = c("cod_munic_ibge")) %>%
    full_join(ppm_livestock, by = c('cod_munic_ibge')) %>%
  full_join(prodes, by = c('cod_munic_ibge')) %>%
  arrange(cod_munic_ibge, ano) %>%
  relocate(cod_munic_ibge, ano)

# convert time data to date
dz_varias_amazonias$ano <- as.Date(as.yearqtr(dz_varias_amazonias$ano), format = "%Y")
dz_varias_amazonias$estado <- dz_varias_amazonias$uf


# collapse data at level of amazon categories
# that is, at 1) "Não florestal", 2) "Desmatada", 3) "Florestal sob pressão", 4) "Florestal"
dz_varias_amazonias <- dz_varias_amazonias %>% group_by(front_2020, front_2020_label) %>% 
  summarise(ips_amazonia_2021 = mean(ips_amazonia_2021, na.rm = TRUE),
            quant_v40124 = sum(quant_v40124, na.rm = TRUE),
            prop_desmatado = weighted.mean(prop_desmatado, w = area, na.rm = TRUE),
            prop_floresta = weighted.mean(prop_floresta, w = area, na.rm = TRUE),
            desmatado = sum(desmatado, na.rm = TRUE),
            floresta = sum(floresta, na.rm = TRUE),
            num_v2670 = sum(num_v2670, na.rm = TRUE)
            )

# Filtra colunas onde são NA
dz_varias_amazonias <- dz_varias_amazonias[which(!is.na(dz_varias_amazonias$front_2020)), ]

# save data
saveRDS(dz_varias_amazonias,
  file = "./data/dz_varias_amazonias.rds"
)  

#####################
# Build Dictionary
#####################

# call data
dz_varias_amazonias.rds <- readRDS("./data/dz_varias_amazonias.rds")

# extract variables from data
columns <- colnames(dz_varias_amazonias.rds)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = FALSE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns,
  desc = columns,
  groups = columns,
  var_group = "Fonte de dados",
  source = "Fonte de dados",
  unidade = "Unidade de medida",
  categoria = "Categoria principal",
  subcategoria = "Subcategoria"
)

# label variables
temp_param_table$label[temp_param_table$var == "front_2020"] <- "Categoria numérica de munic\u00edpio"
temp_param_table$label[temp_param_table$var == "front_2020_label"] <- "Categoria de munic\u00edpio"

temp_param_table$label[temp_param_table$var == "ips_amazonia_2021"] <- "Indice de Progresso Social 2021"

temp_param_table$label[temp_param_table$var == "desmatado"] <- "\u00c1rea total desmatada"
temp_param_table$label[temp_param_table$var == "floresta"] <- "\u00c1rea total florestal"
temp_param_table$label[temp_param_table$var == "prop_desmatado"] <- "Proporção média de desmatamento pela \u00c1rea"
temp_param_table$label[temp_param_table$var == "prop_floresta"] <- "Proporção média de floresta pela \u00c1rea"

temp_param_table$label[temp_param_table$var == "quant_v40124"] <- "Quantidade de soja"
temp_param_table$label[temp_param_table$var == "num_v2670"] <- "Quantidade de rebanho bovino"

# unidade de medida das variaveis
temp_param_table$unidade[temp_param_table$var == "ips_amazonia_2021"] <- "Índice de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "desmatado"] <- "Km2 em 2021"
temp_param_table$unidade[temp_param_table$var == "floresta"] <- "Km2 em 2021"

temp_param_table$unidade[temp_param_table$var == "prop_desmatado"] <- "Percentual em 2021"
temp_param_table$unidade[temp_param_table$var == "prop_floresta"] <- "Percentual em 2021"

temp_param_table$unidade[temp_param_table$var == "quant_v40124"] <- "Grãos em 2019"
temp_param_table$unidade[temp_param_table$var == "num_v2670"] <- "Cabeça de animais em 2019"

# var_group variables
temp_param_table$var_group[temp_param_table$var == "front_2020"] <- "IMAZON"
temp_param_table$var_group[temp_param_table$var == "front_2020_label"] <- "IMAZON"
temp_param_table$var_group[temp_param_table$var == "ips_amazonia_2021"] <- "IMAZON"
temp_param_table$var_group[temp_param_table$var == "desmatado"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "floresta"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "prop_desmatado"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "prop_floresta"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "quant_v40124"] <- "IBGE - PAM"
temp_param_table$var_group[temp_param_table$var == "num_v2670"] <- "IBGE - PPM"

# label data source
temp_param_table$source[temp_param_table$var == "front_2020"] <- "IMAZON"
temp_param_table$source[temp_param_table$var == "front_2020_label"] <- "IMAZON"
temp_param_table$source[temp_param_table$var == "ips_amazonia_2021"] <- "IMAZON"
temp_param_table$source[temp_param_table$var == "desmatado"] <- "INPE - PRODES"
temp_param_table$source[temp_param_table$var == "floresta"] <- "INPE - PRODES"
temp_param_table$source[temp_param_table$var == "prop_desmatado"] <- "INPE - PRODES"
temp_param_table$source[temp_param_table$var == "prop_floresta"] <- "INPE - PRODES"
temp_param_table$source[temp_param_table$var == "quant_v40124"] <- "IBGE - PAM"
temp_param_table$source[temp_param_table$var == "num_v2670"] <- "IBGE - PPM"

# categoria variables
temp_param_table$categoria[temp_param_table$var == "front_2020"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "front_2020_label"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "ips_amazonia_2021"] <- "Social"
temp_param_table$categoria[temp_param_table$var == "desmatado"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "floresta"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "prop_desmatado"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "prop_floresta"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "quant_v40124"] <- "Agricultura"
temp_param_table$categoria[temp_param_table$var == "num_v2670"] <- "Pecuária"

# subcategoria variables
temp_param_table$subcategoria[temp_param_table$var == "front_2020"] <- "Meio ambiente"
temp_param_table$subcategoria[temp_param_table$var == "front_2020_label"] <- "Meio ambiente"
temp_param_table$subcategoria[temp_param_table$var == "ips_amazonia_2021"] <- "Social"
temp_param_table$subcategoria[temp_param_table$var == "desmatado"] <- "Desmatamento"
temp_param_table$subcategoria[temp_param_table$var == "floresta"] <- "Floresta"
temp_param_table$subcategoria[temp_param_table$var == "prop_desmatado"] <- "Desmatamento"
temp_param_table$subcategoria[temp_param_table$var == "prop_floresta"] <- "Floresta"
temp_param_table$subcategoria[temp_param_table$var == "quant_v40124"] <- "Agricultura"
temp_param_table$subcategoria[temp_param_table$var == "num_v2670"] <- "Pecuária"

# allow variables in graphs size, color, and slider-axis
temp_param_table$color[temp_param_table$var == "front_2020"] <- TRUE #
temp_param_table$color[temp_param_table$var == "front_2020_label"] <- TRUE #

# allow variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "front_2020"] <- TRUE
temp_param_table$x[temp_param_table$var == "front_2020_label"] <- TRUE # 

# disablle variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "front_2020"] <- FALSE
temp_param_table$y[temp_param_table$var == "front_2020_label"] <- FALSE # 

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_varias_amazonias_dic.csv", fileEncoding = "UTF-8")