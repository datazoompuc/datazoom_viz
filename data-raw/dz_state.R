############################################################
#### Generate rds data in the folder ./data/ 
############################################################

#### Call library
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
# TERRABRASILIS
###################
# read shapefile
# shapefile<-st_read('data/shapefiles/municipalities_legal_amazon.shp')

# data too heavy (over 100mb)
# solution: simplify geometry
# shapefile <- sf::st_simplify(shapefile, dTolerance = 400) 

# plot(shapefile)
# shapefile$group

###################
# PPM
###################
ppm_state_animal_origin_production <- readRDS(file = "data/ppm_state_animal_origin_production.rds")

ppm_state_animal_origin_production$ano <- ppm_state_animal_origin_production$time
ppm_state_animal_origin_production <- ppm_state_animal_origin_production %>% 
  janitor::clean_names() 

###################
# INPE - PRODES
###################
###################
ppm_state_aquaculture <- readRDS(file = "data/ppm_state_aquaculture.rds")

ppm_state_aquaculture$ano <- ppm_state_aquaculture$time
ppm_state_aquaculture <- ppm_state_aquaculture %>% 
  janitor::clean_names() 

###################
# INPE - PRODES
###################
###################
ppm_state_cow_farming <- readRDS(file = "data/ppm_state_cow_farming.rds")

ppm_state_cow_farming$ano <- ppm_state_cow_farming$time
ppm_state_cow_farming <- ppm_state_cow_farming %>% 
  janitor::clean_names() 
###################
# INPE - PRODES
###################
###################
ppm_state_livestock_inventory <- readRDS(file = "data/ppm_state_livestock_inventory.rds")

ppm_state_livestock_inventory$ano <- ppm_state_livestock_inventory$time
ppm_state_livestock_inventory <- ppm_state_livestock_inventory %>% 
  janitor::clean_names() 

###################
# INPE - PRODES
###################
###################
ppm_state_sheep_farming <- readRDS(file = "data/ppm_state_sheep_farming.rds")

ppm_state_sheep_farming$ano <- ppm_state_sheep_farming$time
ppm_state_sheep_farming <- ppm_state_sheep_farming %>% 
  janitor::clean_names() 
###########################
# edit data to merge
###########################
#class(ppm_state_sheep_farming$group) <-  'character'
#class(ppm_state_sheep_farming$group) <-  'character'

###########################
# merge all data
###########################
dz_state <- ppm_state_animal_origin_production %>%
  full_join(ppm_state_aquaculture, by = c("group","ano"))   %>%
  full_join(ppm_state_cow_farming, by = c("group","ano"))   %>%
  full_join(ppm_state_livestock_inventory, by = c("group","ano")) %>% 
  full_join(ppm_state_sheep_farming, by = c("group","ano")) %>% 
  arrange(group, ano) %>%
  relocate(group, ano)

# edit final data
class(dz_state)
colnames(dz_state)

# edit data to merge
class(dz_state$ano) <-  'numeric'

# clean column names
dz_state <- dz_state %>%
  janitor::clean_names()

######################################################
# merge data with amazon municipalities shapefile
######################################################
map_dz_state <- sp::merge(shapefile, dz_state, by.x = 'group', by.y = 'group')

# convert time data to date
map_dz_state$ano <- as.Date(as.yearqtr(map_dz_state$ano), format = "%Y")

# colnames(map_dz_state)
dz_state <- map_dz_state %>% select(group,
                                    nm_municip,
                                    uf,
                                    ano,
                                    employed_census2000,
                                    employed_census2010,
                                    mean_income_census2000,
                                    mean_income_census2010,
                                    median_income_census2000,
                                    median_income_census2010,
                                    desmatado,
                                    incremento,
                                    floresta,
                                    nao_floresta,
                                    hidrografia,
                                    prop_desmatado,
                                    prop_incremento,prop_floresta,
                                    prop_nao_floresta,
                                    prop_hidrografia,
                                    pop,gdp,
                                    gd_ppc,
                                    cempre_n_empresas_organizacoes,
                                    cempre_n_ocupados,
                                    cempre_n_ocupados_assalariados,
                                    cempre_salarios_remuneracoes,
                                    ips2018,
                                    ips2014,
                                    geometry)


dz_state$estado <- dz_state$uf

# unique(dz_state$uf_x)
# dz_state <- dz_state %>% dplyr::filter(estado == "AC" | estado == "AP" | estado == "AM" | estado == "PA" | estado == "MA" | estado == "RR" | estado == "RO" | estado == "MT" | estado == "TO") 
class(dz_state$group)
dz_state$group <- as.factor(dz_state$group)
dz_state$estado <- as.factor(dz_state$estado)

# groups at the level: municipio
dz_state$group <- dz_state$nm_municip

# unique rows
# dz_state <- unique(dz_state, by = c(ano, group, estado))
dz_state <- dz_state %>% group_by(group, ano)

# arrange data by municipality and year
dz_state <- dz_state %>%
  arrange(group, ano)

# Identify and remove duplicate data
# xxx <- dz_state %>% distinct(group, ano, .keep_all = TRUE)

# drop municipalities with empty geometry
dz_state = dz_state[!st_is_empty(dz_state),,drop=FALSE]

# save data
saveRDS(dz_state,
        file = "./data/dz_state.rds"
)

#####################
# Build Dictionary 
#####################

# call data
dz_state <- readRDS("./data/dz_state.rds")

# extract variables from data
columns <- colnames(dz_state)

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
  categoria= "Categoria principal", 
  subcategoria = "Subcategoria"
)

# label variables
temp_param_table$label[1] <- "Código do município"
temp_param_table$label[2] <- "Nome do município"
temp_param_table$label[3] <- "Estado"
temp_param_table$label[4] <- "Ano"
# Census data
temp_param_table$label[5] <- "Número de ocupados - Censo 2000"
temp_param_table$label[6] <- "Número de ocupados - Censo 2010"
temp_param_table$label[7] <- "Rendimento médio - Censo 2000"
temp_param_table$label[8] <- "Rendimento médio - Censo 2010"
temp_param_table$label[9] <- "Rendimento mediano - Censo 2000"
temp_param_table$label[10] <- "Rendimento mediano - Censo 2010"
#INPE-PRODES
temp_param_table$label[11] <- "Área total desmatada"
temp_param_table$label[12] <- "Área total de incremento de desmatamento"
temp_param_table$label[13] <- "Área total de floresta"
temp_param_table$label[14] <- "Área total de não-floresta"
temp_param_table$label[15] <- "Área total de hidrografia"
temp_param_table$label[16] <- "Proporção de desmatamento na área do município"
temp_param_table$label[17] <- "Proporção de incremento de desmatamento na área do município"
temp_param_table$label[18] <- "Proporção de floresta na área do município"
temp_param_table$label[19] <- "Proporção de não-floresta na área do município"
temp_param_table$label[20] <- "Proporção de hidrografia na área do município"
# IBGE
temp_param_table$label[21] <- "População"
temp_param_table$label[22] <- "PIB"
temp_param_table$label[23] <- "PIB percapita"
# CEMPRE
temp_param_table$label[24] <- "Número de empresas e outras organizações"
temp_param_table$label[25] <- "Número de pessoas ocupadas"
temp_param_table$label[26] <- "Número de pessoas ocupadas assalariadas"
temp_param_table$label[27] <- "Salários e outras remunerações"
# IPS
temp_param_table$label[28] <- "IPS 2018"
temp_param_table$label[29] <- "IPS 2014"
temp_param_table$label[30] <- "Estado"
temp_param_table$label[31] <- "Geometria"

# unidade variables
temp_param_table$unidade[4] <- "Ano"
temp_param_table$unidade[5] <- "Pessoas"
temp_param_table$unidade[6] <- "Pessoas"
temp_param_table$unidade[7] <- "R$ em 2000"
temp_param_table$unidade[8] <- "R$ em 2010"
temp_param_table$unidade[9] <- "R$ em 2000"
temp_param_table$unidade[10] <- "R$ em 2010"
temp_param_table$unidade[11] <- "Km2"
temp_param_table$unidade[12] <- "Km2"
temp_param_table$unidade[13] <- "Km2"
temp_param_table$unidade[14] <- "Km2"
temp_param_table$unidade[15] <- "Km2"
temp_param_table$unidade[16] <- "%"
temp_param_table$unidade[17] <- "%"
temp_param_table$unidade[18] <- "%"
temp_param_table$unidade[19] <- "%"
temp_param_table$unidade[20] <- "%"
temp_param_table$unidade[21] <- "Pessoas"
temp_param_table$unidade[22] <- "R$"
temp_param_table$unidade[23] <- "R$"
temp_param_table$unidade[24] <- "Estabelecimentos"
temp_param_table$unidade[25] <- "Pessoas"
temp_param_table$unidade[26] <- "Pessoas"
temp_param_table$unidade[27] <- "R$"
temp_param_table$unidade[28] <- "Índice de 0 a 100"
temp_param_table$unidade[29] <- "Índice de 0 a 100"
temp_param_table$unidade[30] <- "Estado"
temp_param_table$unidade[31] <- "Geometria"

# var_group variables
temp_param_table$var_group[1] <- "Geral"
temp_param_table$var_group[2] <- "Geral"
temp_param_table$var_group[3] <- "Geral"
temp_param_table$var_group[4] <- "Geral"
temp_param_table$var_group[5] <- "IBGE - Censo 2000"
temp_param_table$var_group[6] <- "IBGE - Censo 2010"
temp_param_table$var_group[7] <- "IBGE - Censo 2000"
temp_param_table$var_group[8] <- "IBGE - Censo 2010"
temp_param_table$var_group[9] <- "IBGE - Censo 2000"
temp_param_table$var_group[10] <- "IBGE - Censo 2010"
temp_param_table$var_group[11] <- "INPE - PRODES"
temp_param_table$var_group[12] <- "INPE - PRODES"
temp_param_table$var_group[13] <- "INPE - PRODES"
temp_param_table$var_group[14] <- "INPE - PRODES"
temp_param_table$var_group[15] <- "INPE - PRODES"
temp_param_table$var_group[16] <- "INPE - PRODES"
temp_param_table$var_group[17] <- "INPE - PRODES"
temp_param_table$var_group[18] <- "INPE - PRODES"
temp_param_table$var_group[19] <- "INPE - PRODES"
temp_param_table$var_group[20] <- "INPE - PRODES"
temp_param_table$var_group[21] <- "IBGE - CEMPRE"
temp_param_table$var_group[22] <- "IBGE - CEMPRE"
temp_param_table$var_group[23] <- "IBGE - CEMPRE"
temp_param_table$var_group[24] <- "IBGE - CEMPRE"
temp_param_table$var_group[25] <- "IBGE - CEMPRE"
temp_param_table$var_group[26] <- "IBGE - CEMPRE"
temp_param_table$var_group[27] <- "IBGE - CEMPRE"
temp_param_table$var_group[28] <- "IMAZON"
temp_param_table$var_group[29] <- "IMAZON"
temp_param_table$var_group[30] <- "Geral"
temp_param_table$var_group[31] <- "Terrabrasilis"

# label data category
temp_param_table$categoria[1] <- "Unidade geográfica"
temp_param_table$categoria[2] <- "Unidade geográfica"
temp_param_table$categoria[3] <- "Unidade geográfica"
temp_param_table$categoria[4] <- "Unidade de tempo"
# Census data
temp_param_table$categoria[5] <- "Mercado de trabalho"
temp_param_table$categoria[6] <- "Mercado de trabalho"
temp_param_table$categoria[7] <- "Mercado de trabalho"
temp_param_table$categoria[8] <- "Mercado de trabalho"
temp_param_table$categoria[9] <- "Mercado de trabalho"
temp_param_table$categoria[10] <- "Mercado de trabalho"
#INPE-PRODES
temp_param_table$categoria[11] <- "Meio ambiente"
temp_param_table$categoria[12] <- "Meio ambiente"
temp_param_table$categoria[13] <- "Meio ambiente"
temp_param_table$categoria[14] <- "Meio ambiente"
temp_param_table$categoria[15] <- "Meio ambiente"
temp_param_table$categoria[16] <- "Meio ambiente"
temp_param_table$categoria[17] <- "Meio ambiente"
temp_param_table$categoria[18] <- "Meio ambiente"
temp_param_table$categoria[19] <- "Meio ambiente"
temp_param_table$categoria[20] <- "Meio ambiente"
# IBGE
temp_param_table$categoria[21] <- "Demografia"
temp_param_table$categoria[22] <- "Economia"
temp_param_table$categoria[23] <- "Economia"
# CEMPRE
temp_param_table$categoria[24] <- "Economia"
temp_param_table$categoria[25] <- "Mercado de trabalho"
temp_param_table$categoria[26] <- "Mercado de trabalho"
temp_param_table$categoria[27] <- "Mercado de trabalho"
# IPS
temp_param_table$categoria[28] <- "Social"
temp_param_table$categoria[29] <- "Social"
temp_param_table$categoria[30] <- "Unidade geográfica"
temp_param_table$categoria[31] <- "Unidade geográfica"

# subcategoria variables
temp_param_table$subcategoria[1] <- "Município"
temp_param_table$subcategoria[2] <- "Município"
temp_param_table$subcategoria[3] <- "Estado"
temp_param_table$subcategoria[4] <- "Tempo"
# Census data
temp_param_table$subcategoria[5] <- "Trabalho"
temp_param_table$subcategoria[6] <- "Trabalho"
temp_param_table$subcategoria[7] <- "Rendimento"
temp_param_table$subcategoria[8] <- "Rendimento"
temp_param_table$subcategoria[9] <- "Rendimento"
temp_param_table$subcategoria[10] <- "Rendimento"
#INPE-PRODES
temp_param_table$subcategoria[11] <- "Desmatamento"
temp_param_table$subcategoria[12] <- "Desmatamento"
temp_param_table$subcategoria[13] <- "Floresta"
temp_param_table$subcategoria[14] <- "Geografia"
temp_param_table$subcategoria[15] <- "Geografia"
temp_param_table$subcategoria[16] <- "Desmatamento"
temp_param_table$subcategoria[17] <- "Desmatamento"
temp_param_table$subcategoria[18] <- "Floresta"
temp_param_table$subcategoria[19] <- "Geografia"
temp_param_table$subcategoria[20] <- "Geografia"
# IBGE
temp_param_table$subcategoria[21] <- "População"
temp_param_table$subcategoria[22] <- "Desenvolvimento"
temp_param_table$subcategoria[23] <- "Desenvolvimento"
# CEMPRE
temp_param_table$subcategoria[24] <- "Produção"
temp_param_table$subcategoria[25] <- "Trabalho"
temp_param_table$subcategoria[26] <- "Trabalho"
temp_param_table$subcategoria[27] <- "Rendimento"
# IPS
temp_param_table$subcategoria[28] <- "Desenvolvimento"
temp_param_table$subcategoria[29] <- "Desenvolvimento"
temp_param_table$subcategoria[30] <- "Estado"
temp_param_table$subcategoria[31] <- "Geografia"

# block variables in graphs y-axis
temp_param_table$y[1] <- FALSE # "Código do município"
temp_param_table$y[2] <- FALSE # "nm_municip"
temp_param_table$y[3] <- FALSE # "uf_x"
temp_param_table$y[4] <- FALSE # "ano"

temp_param_table$y[30] <- FALSE # "geometry"
temp_param_table$y[31] <- FALSE # "estado"


# block and variables in graphs x-axis
temp_param_table$x[1] <- FALSE # "Código do município"
temp_param_table$x[2] <- FALSE # "nm_municip"
temp_param_table$x[3] <- FALSE # "uf_x"
temp_param_table$x[4] <- FALSE # "ano"
temp_param_table$x[30] <- FALSE # "geometry"
temp_param_table$x[31] <- FALSE # "estado"

# allow variables in graphs size, color, and slider-axis 
temp_param_table$size[5] <- TRUE # 
temp_param_table$size[6] <- TRUE # 
temp_param_table$size[7] <- TRUE #
temp_param_table$size[8] <- TRUE #
temp_param_table$size[9] <- TRUE #
temp_param_table$size[10] <- TRUE #
temp_param_table$size[21] <- TRUE #

temp_param_table$size[28] <- TRUE # "Índice de Progresso Social (IPS)"
temp_param_table$size[29] <- TRUE # "Índice de Progresso Social (IPS)"
temp_param_table$color[5] <- TRUE # 
temp_param_table$color[6] <- TRUE # 
temp_param_table$color[7] <- TRUE #
temp_param_table$color[8] <- TRUE #
temp_param_table$color[9] <- TRUE #
temp_param_table$color[10] <- TRUE #
temp_param_table$color[21] <- TRUE #

temp_param_table$color[28] <- TRUE # "Índice de Progresso Social (IPS)"
temp_param_table$color[29] <- TRUE # "Índice de Progresso Social (IPS)"
temp_param_table$color[30] <- TRUE # "Estado"

temp_param_table$slider[4] <- TRUE # "ano"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_state_dic.csv", fileEncoding = "UTF-8")