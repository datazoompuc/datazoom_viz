############################################################
#### Generate rds data in the folder ./data/ 
############################################################

#### Generate Data: INPE - PRODES: deforestation
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
shapefile<-st_read('data/shapefiles/municipalities_legal_amazon.shp')

# data too heavy (over 100mb)
# solution: simplify geometry
shapefile <- sf::st_simplify(shapefile, dTolerance = 400) 

# plot(shapefile)
# shapefile$cod_ibge

###################
# CENSUS
###################
income <- readRDS(file = "data/income.rds")
income$Ano <- income$Year
income <- income %>% 
  separate(Municipality, c("name_munic", "Estado"), " - ") %>%
  janitor::clean_names() %>%
  select(cod_ibge, name_munic, ano, employed, mean_income, median_income)
class(income$ano) <-  'numeric'
# Reshaping data.frame from long  to wide format
income <- income %>% 
  tidyr::pivot_wider(id_cols = c(cod_ibge, ano),  
                     names_from = ano, 
                     names_prefix = "census", 
                     values_from = c(employed, mean_income, median_income)
                     )  
# Identify and remove duplicate data
income <- income %>% distinct(cod_ibge, .keep_all = TRUE)

###################
# INPE - PRODES
###################
prodes <- readRDS(file = "data/prodes.rds")
prodes <- prodes %>%
  janitor::clean_names()

# generate variable by the share of municipality total area
prodes <- prodes %>%
  mutate(prop_desmatado = desmatado/area_km2,
         prop_incremento = incremento/area_km2,
         prop_floresta = floresta/area_km2,
         prop_nao_floresta = nao_floresta/area_km2,
         prop_hidrografia = hidrografia/area_km2
         ) %>%
  select(cod_ibge, 
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
         ) %>% arrange(cod_ibge, ano)

# Identify and remove duplicate data
prodes <- prodes %>% distinct(cod_ibge, ano, .keep_all = TRUE)

###################
# INPE - DETER
###################
# deter <- readRDS(file = "data/deter.rds")
# deter$Estado <- deter$UF
# class(deter$CodIBGE) <-  'character'
# deter$UF <- NULL
# Reshaping data.frame from long  to wide format
# deter <- deter %>% tidyr::pivot_wider(id_cols = c(CodIBGE, Ano),  names_from = Classe, values_from = c(Area_em_Municipio_km2))  
# Identify and remove duplicate data
# deter <- deter %>% distinct(CodIBGE, Ano, .keep_all = TRUE) %>% arrange(CodIBGE, Ano)

###################
# IBGE - PIB
###################
gdp <- readRDS(file = "data/gdp.rds")
gdp <- gdp %>%
  janitor::clean_names()
gdp$ano <- gdp$year
class(gdp$ano) <-  'numeric'
class(gdp$cod_ibge) <-  'character'
# Replace NA with previous and next rows mean
gdp <- gdp %>%
  group_by(cod_ibge) %>%
  arrange(cod_ibge, ano)
gdp$pop <- zoo::na.approx(gdp$pop)
gdp$gd_ppc <- zoo::na.approx(gdp$gd_ppc)
# Identify and remove duplicate data
gdp <- gdp %>% distinct(cod_ibge, ano, .keep_all = TRUE) %>% arrange(cod_ibge, ano)
# select relevant variables
gdp <- gdp %>% 
  select(cod_ibge, ano, pop, gdp, gd_ppc) %>%
  arrange(cod_ibge, ano)

###################
# INPE - DEGRAD
##################
# degrad <- readRDS(file = "data/degrad.rds")
# degrad$Ano <- degrad$year
# degrad$Year <- NULL

###################
# IMAZON - IPS
###################
ips <- readRDS(file = "data/ips.rds")
ips <- ips %>%
  janitor::clean_names()
# Reshaping data.frame from long  to wide format
ips <- ips %>% 
  tidyr::pivot_wider(
    id_cols = c(cod_municipio, ano),  
    names_from = ano, 
    names_prefix = "ips", 
    values_from = ips
    )  

###################
# IBGE - CEMPRE
###################
cempre_municipality <- readRDS(file = "data/cempre_municipality_dza.rds")
cempre_municipality <- cempre_municipality %>%
  janitor::clean_names()

# Reshaping data.frame from long  to wide format
cempre_municipality <- cempre_municipality %>% 
  tidyr::pivot_wider(
    id_cols = c(municipio_codigo, ano),
    names_from = variavel_codigo, 
    names_prefix = "cempre", 
    values_from = valor)  

cempre_municipality$cod_ibge <- cempre_municipality$municipio_codigo
cempre_municipality$cempre_n_empresas_organizacoes <- cempre_municipality$cempre2585
cempre_municipality$cempre_n_ocupados <- cempre_municipality$cempre707
cempre_municipality$cempre_n_ocupados_assalariados <- cempre_municipality$cempre708
cempre_municipality$cempre_salarios_remuneracoes <- cempre_municipality$cempre662

# Identify and remove duplicate data
cempre_municipality <- cempre_municipality %>% 
  distinct(cod_ibge, ano, .keep_all = TRUE) %>% 
  select(
    cod_ibge,
    ano,
    cempre_n_empresas_organizacoes,
    cempre_n_ocupados,
    cempre_n_ocupados_assalariados,
    cempre_salarios_remuneracoes
  ) %>%
  arrange(cod_ibge, ano) 

###################
# SEEG
###################

#seeg <- readRDS(file = "data/seeg.rds")

###################
#PPM
###################

ppm_livestock <- readRDS(file = 'data/ppm_municipality_livestock_inventory.rds')

munics= readxl::read_xls("data\\RELATORIO_DTB_BRASIL_MUNICIPIO.xls")%>%
  dplyr::select('Código Município Completo', 'Nome_Município')
ppm_livestock$group= plyr::mapvalues(ppm_livestock$group, from = munics$Nome_Município , to = munics$`Código Município Completo`)

ppm_livestock= ppm_livestock%>%
  dplyr::filter(time >= 2000)

###########################
# edit data to merge
###########################
class(cempre_municipality$cod_ibge) <-  'character'
class(prodes$cod_ibge) <-  'character'
class(deter$cod_ibge) <-  'character'
class(gdp$cod_ibge) <-  'character'
class(degrad$cod_ibge) <-  'character'
class(ips$cod_municipio) <-  'character'
class(income$cod_ibge) <-  'character'
class(cempre_municipality$ano) <-  'numeric'

class(prodes$ano) <-  'numeric'
class(deter$ano) <-  'numeric'
class(gdp$ano) <-  'numeric'
class(degrad$ano) <-  'numeric'
class(income$ano) <-  'numeric'
class(ips$cod_municipio) <-  'character'

###########################
# merge all data
###########################
dz_munic <- income %>%
  full_join(prodes, by = c("cod_ibge"))   %>%
  full_join(gdp, by = c("cod_ibge","ano"))   %>%
  full_join(cempre_municipality, by = c("cod_ibge","ano")) %>% 
  full_join(ips, by = c("cod_ibge" = "cod_municipio")) %>%
  full_join(ppm_livestock, by = c('cod_ibge' = 'group', 'ano' = 'time'))%>%
  arrange(cod_ibge, ano) %>%
  relocate(cod_ibge, ano)

# colnames(dz_munic)
dz_munic$name_munic <- dz_munic$name_munic.x
dz_munic <- dz_munic %>% transform(estado = ifelse(!is.na(estado.x), estado.x, estado.y))

# edit final data
class(dz_munic)
colnames(dz_munic)

# edit data to merge
class(dz_munic$ano) <-  'numeric'

# clean column names
dz_munic <- dz_munic %>%
  janitor::clean_names()

######################################################
# merge data with amazon municipalities shapefile
######################################################
map_dz_munic <- sp::merge(shapefile, dz_munic, by.x = 'cod_ibge', by.y = 'cod_ibge')

# convert time data to date
map_dz_munic$ano <- as.Date(as.yearqtr(map_dz_munic$ano), format = "%Y")

# colnames(map_dz_munic)
dz_munic <- map_dz_munic %>% select(cod_ibge,
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
                                    geometry,
                                    num_v2670,
                                    num_v2672,
                                    num_v2675,
                                    num_v2677,
                                    num_v2680,
                                    num_v2681,
                                    num_v32793,
                                    num_v32794,
                                    num_v32795,
                                    num_v32796)


dz_munic$estado <- dz_munic$uf

# unique(dz_munic$uf_x)
# dz_munic <- dz_munic %>% dplyr::filter(estado == "AC" | estado == "AP" | estado == "AM" | estado == "PA" | estado == "MA" | estado == "RR" | estado == "RO" | estado == "MT" | estado == "TO") 
class(dz_munic$cod_ibge)
dz_munic$cod_ibge <- as.factor(dz_munic$cod_ibge)
dz_munic$estado <- as.factor(dz_munic$estado)

# groups at the level: municipio
dz_munic$group <- dz_munic$nm_municip

# unique rows
# dz_munic <- unique(dz_munic, by = c(ano, cod_ibge, estado))
dz_munic <- dz_munic %>% group_by(cod_ibge, ano)

# arrange data by municipality and year
dz_munic <- dz_munic %>%
  arrange(cod_ibge, ano)

# Identify and remove duplicate data
# xxx <- dz_munic %>% distinct(cod_ibge, ano, .keep_all = TRUE)

# drop municipalities with empty geometry
dz_munic = dz_munic[!st_is_empty(dz_munic),,drop=FALSE]

#limiting decimal places
dz_munic= dz_munic %>% 
  mutate(across(where(is.numeric), ~ round(., digits = 1)))

# save data
saveRDS(dz_munic,
        file = "./data/dz_munic.rds"
)

#####################
# Build Dictionary 
#####################

# call data
dz_munic <- readRDS("./data/dz_munic.rds")

# extract variables from data
columns <- colnames(dz_munic)

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

#filtering the ppm obs, because there is already a .csv dictionary for ppm livestock inventory
temp_param_table= temp_param_table%>%
  filter(!startsWith(.data$var, 'num'))

metappm= read.csv(file = 'data/ppm_municipality_livestock_inventory_dic.csv')
metappm <- metappm%>%
  dplyr::mutate(geometry = FALSE, desc= var)%>%
  dplyr::rename(var_group = source)%>%
  dplyr::select(-X, - tipo)
metappm= metappm[-1,]
metappm= metappm[-1,]
metappm$var_group= 'IBGE - PPM'

temp_param_table= dplyr::bind_rows(temp_param_table, metappm)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_munic_dic.csv", fileEncoding = "UTF-8")