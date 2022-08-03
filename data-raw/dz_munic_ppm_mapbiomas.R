############################################################
#### Generate rds data in the folder ./data/
############################################################

#### Packages
library(tidyverse)
library(readxl)
library(tibble)
library(zoo)
library(sf)
library(sp)
library(scales) # to use label_percent()
library(datazoom.amazonia)

####################
# 1) Call and clean data
###################

###################
#PPM - IBGE
###################

ppm_livestock <- readRDS(file = "data/ppm_municipality_livestock_inventory.rds")

###################
#MAPBIONMAS - COBERTURA
###################

data_frame_mapbiomas <-datazoom.amazonia::load_mapbiomas(dataset = "mapbiomas_cover",
                                                         cover_level = "4",
                                                         geo_level = "municipality", 
                                                         raw_data = FALSE)

###########################
# edit data to merge
###########################

class(data_frame_mapbiomas$territory_id ) <- 'numeric'
class(data_frame_mapbiomas$year) <- 'numeric'

class(ppm_livestock$geo_id) <- 'numeric'
class(ppm_livestock$ano) <- 'numeric'

###########################
# merge all data
###########################
dz_munic_ppm_mapbiomas <- data_frame_mapbiomas %>%
  full_join(ppm_livestock, 
            by = c('territory_id' = 'geo_id', 'year' = 'ano')
            ) 


# generate varialbe - número de cabeças por hectare de pastagem por município
dz_munic_ppm_mapbiomas <- dz_munic_ppm_mapbiomas %>%
  mutate(n_bovino_por_area_pastagem = num_v2670/pasture) 
  

# colnames(dz_munic_ppm_mapbiomas)

dz_munic_ppm_mapbiomas <- dz_munic_ppm_mapbiomas %>% 
  select(territory_id, municipality, state, year, n_bovino_por_area_pastagem) %>%
  arrange(territory_id, year) %>%
  relocate(territory_id, year)

# edit dataset
dz_munic_ppm_mapbiomas$cod_ibge <- dz_munic_ppm_mapbiomas$territory_id
dz_munic_ppm_mapbiomas$nm_municip <- dz_munic_ppm_mapbiomas$municipality
dz_munic_ppm_mapbiomas$ano <- dz_munic_ppm_mapbiomas$year
dz_munic_ppm_mapbiomas$uf <- dz_munic_ppm_mapbiomas$state
dz_munic_ppm_mapbiomas$municipality <- NULL
dz_munic_ppm_mapbiomas$territory_id <- NULL
dz_munic_ppm_mapbiomas$year <- NULL
dz_munic_ppm_mapbiomas$state <- NULL

# edit final data
class(dz_munic_ppm_mapbiomas)
colnames(dz_munic_ppm_mapbiomas)
class(dz_munic_ppm_mapbiomas$cod_ibge)
dz_munic_ppm_mapbiomas$cod_ibge <- as.factor(dz_munic_ppm_mapbiomas$cod_ibge)
dz_munic_ppm_mapbiomas$uf <- as.factor(dz_munic_ppm_mapbiomas$uf)

# clean column names
dz_munic_ppm_mapbiomas <- dz_munic_ppm_mapbiomas %>%
  janitor::clean_names()

# convert time data to date
#dz_munic_ppm_mapbiomas$ano <- as.Date(as.yearqtr(dz_munic_ppm_mapbiomas$ano), format = "%Y")

# unique rows
dz_munic_ppm_mapbiomas <- dz_munic_ppm_mapbiomas %>% 
  group_by(cod_ibge, ano)

# arrange data by municipality and year
dz_munic_ppm_mapbiomas <- dz_munic_ppm_mapbiomas %>%
  arrange(cod_ibge, ano) %>%
  relocate(cod_ibge, ano)

# Identify and remove duplicate data
dz_munic_ppm_mapbiomas <- dz_munic_ppm_mapbiomas %>% 
  distinct(cod_ibge, ano, .keep_all = TRUE)

# limiting decimal places)
# for the variables with proportions, limiting to 4 decimal places
dz_munic_ppm_mapbiomas <- dz_munic_ppm_mapbiomas %>%
  mutate(across(c(
    .data$n_bovino_por_area_pastagem
  ), ~ round(., digits = 2)))

# adding regions
dz_munic_ppm_mapbiomas <- dz_munic_ppm_mapbiomas%>%
  mutate(regiao= case_when(uf == 'AC' | uf == 'AM' | uf == 'AP' | uf == 'PA' | uf == 'RO' | uf == 'RR' | uf == 'TO' ~ "Norte",
                           uf == 'AL' | uf == 'BA' | uf == 'CE' | uf == 'MA' | uf == 'PI' | uf == 'PB' | uf == 'RN' | uf == 'SE' ~ "Nordeste",
                           uf == 'MS' | uf == 'MT' | uf == 'GO' | uf == 'DF' ~ "Centro-Oeste",
                           uf == 'ES' | uf == 'MG' | uf == 'RJ' | uf == 'SP' ~ "Sudeste",
                           uf == 'PR' | uf == 'RS' | uf == 'SC' ~ "Sul"))

# adding legal_amazon dummy
legal_amazon <- read_excel("data/lista_de_municipios_Amazonia_Legal_2021.xlsx")
legal_amazon <- legal_amazon$CD_MUN

dz_munic_ppm_mapbiomas <- dz_munic_ppm_mapbiomas%>%
  mutate(legal_amazon= case_when(cod_ibge %in% legal_amazon ~ TRUE,
                                 TRUE ~ FALSE))
# save data
readr::write_rds(dz_munic_ppm_mapbiomas,
        file = "./data/dz_munic_ppm_mapbiomas.rds"
)

#####################
# Build Dictionary
#####################

# call data
dz_munic_ppm_mapbiomas <- readRDS("./data/dz_munic_ppm_mapbiomas.rds")

# extract variables from data
columns <- colnames(dz_munic_ppm_mapbiomas)

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
temp_param_table$label[temp_param_table$var == "cod_ibge"] <- "C\u00f3digo do município"
temp_param_table$label[temp_param_table$var == "nm_municip"] <- "Nome do município"
temp_param_table$label[temp_param_table$var == "uf"] <- "Estado"
temp_param_table$label[temp_param_table$var == "regiao"] <- "Região"
temp_param_table$label[temp_param_table$var == "legal_amazon"] <- "Amazônia Legal"
temp_param_table$label[temp_param_table$var == "ano"] <- "Ano"
temp_param_table$label[temp_param_table$var == "n_bovino_por_area_pastagem"] <- "Rebanho por área de pasto"

# unidade variables
temp_param_table$unidade[temp_param_table$var == "cod_ibge"] <- ""
temp_param_table$unidade[temp_param_table$var == "nm_municip"] <- ""
temp_param_table$unidade[temp_param_table$var == "uf"] <- ""
temp_param_table$unidade[temp_param_table$var == "regiao"] <- ""
temp_param_table$unidade[temp_param_table$var == "legal_amazon"] <- ""
temp_param_table$unidade[temp_param_table$var == "ano"] <- "Ano"
temp_param_table$unidade[temp_param_table$var == "n_bovino_por_area_pastagem"] <- "Rebano bovino por área (ha) de pastagem"

# var_group variables
temp_param_table$var_group[temp_param_table$var == "n_bovino_por_area_pastagem"] <- "IBGE - PPM e MAPBIOMAS"

# label data category
temp_param_table$categoria[temp_param_table$var == "ano"] <- "Unidade de tempo"
temp_param_table$categoria[temp_param_table$var == "n_bovino_por_area_pastagem"] <- "Produção Econômica"

# subcategoria variables
temp_param_table$subcategoria[temp_param_table$var == "ano"] <- "Ano"
temp_param_table$subcategoria[temp_param_table$var == "n_bovino_por_area_pastagem"] <- "Pecuária"

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "cod_ibge"] <- FALSE
temp_param_table$y[temp_param_table$var == "nm_municip"] <- FALSE
temp_param_table$y[temp_param_table$var == "uf"] <- TRUE
temp_param_table$y[temp_param_table$var == "ano"] <- TRUE
temp_param_table$y[temp_param_table$var == "n_bovino_por_area_pastagem"] <- TRUE

# block variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "cod_ibge"] <- FALSE
temp_param_table$x[temp_param_table$var == "nm_municip"] <- FALSE
temp_param_table$x[temp_param_table$var == "uf"] <- TRUE
temp_param_table$x[temp_param_table$var == "ano"] <- TRUE
temp_param_table$x[temp_param_table$var == "n_bovino_por_area_pastagem"] <- TRUE

# allow variables in graphs size, color, and slider-axis
temp_param_table$size[temp_param_table$var == "uf"] <- TRUE #
temp_param_table$color[temp_param_table$var == "uf"] <- TRUE #
temp_param_table$slider[temp_param_table$var == "ano"] <- TRUE # "ano"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_munic_ppm_mapbiomas_dic.csv", fileEncoding = "UTF-8")
