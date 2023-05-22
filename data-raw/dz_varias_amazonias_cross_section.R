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
  select(cod_ibge, ips_amazonia_2021, qualidade_da_educacao_ideb_2019)

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

pib <- read.csv2(file = "data/pibsmunics10_19_.csv")

pib <- pib %>% filter(Ano == 2019)

pib <- pib %>% 
  mutate(valor_adicionado_bruto = Produto.Interno.Bruto...a.preços.correntes..R..1.000.,
         pib_preco_corrente = Produto.Interno.Bruto...a.preços.correntes..R..1.000.,
         pib_percapita_preco_corrente = Produto.Interno.Bruto.per.capita...a.preços.correntes..R..1.00.,
         cod_munic_ibge = Código.do.Município) %>%
  select(cod_munic_ibge, valor_adicionado_bruto, pib_preco_corrente, pib_percapita_preco_corrente) %>% arrange()

class(pib$valor_adicionado_bruto) <- "numeric"
class(pib$pib_preco_corrente) <- "numeric"
class(pib$pib_percapita_preco_corrente) <- "numeric"
class(pib$cod_munic_ibge) <-  'character'

# retorna numero da populacao
pib <- pib %>%
  mutate(populacao = (pib_preco_corrente/pib_percapita_preco_corrente)*1000)

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
dz_varias_amazonias_cross_section <- imazon_amazon_pressure %>%
  full_join(ips, by = c("cod_munic_ibge")) %>%
  full_join(pam_municipality_all_crops_2000_19, by = c("cod_munic_ibge")) %>%
    full_join(ppm_livestock, by = c('cod_munic_ibge')) %>%
  full_join(prodes, by = c('cod_munic_ibge')) %>%
  full_join(pib, by = c('cod_munic_ibge')) %>%
  arrange(cod_munic_ibge, ano) %>%
  relocate(cod_munic_ibge, ano)

# convert time data to date
dz_varias_amazonias_cross_section$ano <- as.Date(as.yearqtr(dz_varias_amazonias_cross_section$ano), format = "%Y")
dz_varias_amazonias_cross_section$estado <- dz_varias_amazonias_cross_section$uf


# generate variable regarding population density
# that is, population size divided by area (in km2)
dz_varias_amazonias_cross_section <- dz_varias_amazonias_cross_section %>%
  mutate(population_density = populacao/area) # people/km2

# collapse data at level of amazon categories
# that is, at 1) "Não florestal", 2) "Desmatada", 3) "Florestal sob pressão", 4) "Florestal"
dz_varias_amazonias_cross_section <- dz_varias_amazonias_cross_section %>% group_by(front_2020, front_2020_label) %>% 
  summarise(ips_amazonia_2021 = mean(ips_amazonia_2021, na.rm = TRUE),
            qualidade_da_educacao_ideb_2019 = mean(qualidade_da_educacao_ideb_2019, na.rm = TRUE),
            quant_v40124 = sum(quant_v40124, na.rm = TRUE),
            prop_desmatado = weighted.mean(prop_desmatado, w = area, na.rm = TRUE),
            prop_floresta = weighted.mean(prop_floresta, w = area, na.rm = TRUE),
            desmatado = sum(desmatado, na.rm = TRUE),
            floresta = sum(floresta, na.rm = TRUE),
            num_v2670 = sum(num_v2670, na.rm = TRUE),
            pib_percapita_preco_corrente = weighted.mean(pib_percapita_preco_corrente, w = populacao),
            populacao = mean(populacao),
            population_density = mean(population_density)
            )

# Filtra colunas onde são NA
dz_varias_amazonias_cross_section <- dz_varias_amazonias_cross_section[which(!is.na(dz_varias_amazonias_cross_section$front_2020)), ]

# save data
saveRDS(dz_varias_amazonias_cross_section,
  file = "./data/dz_varias_amazonias_cross_section.rds"
)  

#####################
# Build Dictionary
#####################

# call data
dz_varias_amazonias_cross_section <- readRDS("./data/dz_varias_amazonias_cross_section.rds")

# extract variables from data
columns <- colnames(dz_varias_amazonias_cross_section)

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

temp_param_table$label[temp_param_table$var == "front_2020"] <- "Categoria numérica de município"
temp_param_table$label[temp_param_table$var == "front_2020_label"] <- "Categoria de município"

temp_param_table$label[temp_param_table$var == "ips_amazonia_2021"] <- "Indice de Progresso Social 2021"
temp_param_table$label[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "Qualidade da educação IDEB 2019"

temp_param_table$label[temp_param_table$var == "desmatado"] <- "Área total desmatada"
temp_param_table$label[temp_param_table$var == "floresta"] <- "Área total florestal"
temp_param_table$label[temp_param_table$var == "prop_desmatado"] <- "Proporção média de desmatamento pela área"
temp_param_table$label[temp_param_table$var == "prop_floresta"] <- "Proporção média de floresta pela área"

temp_param_table$label[temp_param_table$var == "quant_v40124"] <- "Quantidade de soja"
temp_param_table$label[temp_param_table$var == "num_v2670"] <- "Quantidade de rebanho bovino"

temp_param_table$label[temp_param_table$var == "pib_percapita_preco_corrente"] <- "PIB per capita de 2019"
temp_param_table$label[temp_param_table$var == "populacao"] <- "População média municipal em 2019"
temp_param_table$label[temp_param_table$var == "population_density"] <- "Densidade populacional em 2019"

# unidade de medida das variaveis

temp_param_table$unidade[temp_param_table$var == "ips_amazonia_2021"] <- "Índice de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "Nota IDEB (0-10)"

temp_param_table$unidade[temp_param_table$var == "desmatado"] <- "Km²  em 2021"
temp_param_table$unidade[temp_param_table$var == "floresta"] <- "Km² em 2021"

temp_param_table$unidade[temp_param_table$var == "prop_desmatado"] <- "Percentual em 2021"
temp_param_table$unidade[temp_param_table$var == "prop_floresta"] <- "Percentual em 2021"

temp_param_table$unidade[temp_param_table$var == "quant_v40124"] <- "Grãos em 2019"
temp_param_table$unidade[temp_param_table$var == "num_v2670"] <- "Cabeça de animais em 2019"

temp_param_table$unidade[temp_param_table$var == "pib_percapita_preco_corrente"] <- "R$ em 2019"
temp_param_table$unidade[temp_param_table$var == "populacao"] <- "Pessoas"
temp_param_table$unidade[temp_param_table$var == "population_density"] <- "Pessoas por km²"

# var_group variables

temp_param_table$var_group[temp_param_table$var == "front_2020"] <- "IMAZON"
temp_param_table$var_group[temp_param_table$var == "front_2020_label"] <- "IMAZON"
temp_param_table$var_group[temp_param_table$var == "ips_amazonia_2021"] <- "IMAZON"
temp_param_table$var_group[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "IDEB"

temp_param_table$var_group[temp_param_table$var == "desmatado"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "floresta"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "prop_desmatado"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "prop_floresta"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "quant_v40124"] <- "IBGE - PAM"
temp_param_table$var_group[temp_param_table$var == "num_v2670"] <- "IBGE - PPM"
temp_param_table$var_group[temp_param_table$var == "pib_percapita_preco_corrente"] <- "IBGE"
temp_param_table$var_group[temp_param_table$var == "populacao"] <- "IBGE"
temp_param_table$var_group[temp_param_table$var == "population_density"] <- "IBGE"

# label data source

temp_param_table$source[temp_param_table$var == "front_2020"] <- "IMAZON"
temp_param_table$source[temp_param_table$var == "front_2020_label"] <- "IMAZON"

temp_param_table$source[temp_param_table$var == "ips_amazonia_2021"] <- "IMAZON"
temp_param_table$source[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "IDEB"

temp_param_table$source[temp_param_table$var == "desmatado"] <- "INPE - PRODES"
temp_param_table$source[temp_param_table$var == "floresta"] <- "INPE - PRODES"
temp_param_table$source[temp_param_table$var == "prop_desmatado"] <- "INPE - PRODES"
temp_param_table$source[temp_param_table$var == "prop_floresta"] <- "INPE - PRODES"
temp_param_table$source[temp_param_table$var == "quant_v40124"] <- "IBGE - PAM"
temp_param_table$source[temp_param_table$var == "num_v2670"] <- "IBGE - PPM"
temp_param_table$source[temp_param_table$var == "pib_percapita_preco_corrente"] <- "IBGE"
temp_param_table$source[temp_param_table$var == "populacao"] <- "IBGE"
temp_param_table$source[temp_param_table$var == "population_density"] <- "IBGE"

# categoria variables

temp_param_table$categoria[temp_param_table$var == "front_2020"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "front_2020_label"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "ips_amazonia_2021"] <- "Social"
temp_param_table$categoria[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "Educação"

temp_param_table$categoria[temp_param_table$var == "desmatado"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "floresta"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "prop_desmatado"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "prop_floresta"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "quant_v40124"] <- "Agricultura"
temp_param_table$categoria[temp_param_table$var == "num_v2670"] <- "Pecuária"
temp_param_table$categoria[temp_param_table$var == "pib_percapita_preco_corrente"] <- "Economia"
temp_param_table$categoria[temp_param_table$var == "populacao"] <- "Demografia"
temp_param_table$categoria[temp_param_table$var == "population_density"] <- "Demografia"

# subcategoria variables

temp_param_table$subcategoria[temp_param_table$var == "front_2020"] <- "Meio ambiente"
temp_param_table$subcategoria[temp_param_table$var == "front_2020_label"] <- "Meio ambiente"
temp_param_table$subcategoria[temp_param_table$var == "ips_amazonia_2021"] <- "Social"
temp_param_table$subcategoria[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "Educação"
temp_param_table$subcategoria[temp_param_table$var == "desmatado"] <- "Desmatamento"
temp_param_table$subcategoria[temp_param_table$var == "floresta"] <- "Floresta"
temp_param_table$subcategoria[temp_param_table$var == "prop_desmatado"] <- "Desmatamento"
temp_param_table$subcategoria[temp_param_table$var == "prop_floresta"] <- "Floresta"
temp_param_table$subcategoria[temp_param_table$var == "quant_v40124"] <- "Agricultura"
temp_param_table$subcategoria[temp_param_table$var == "num_v2670"] <- "Pecuária"
temp_param_table$subcategoria[temp_param_table$var == "pib_percapita_preco_corrente"] <- "Economia"
temp_param_table$subcategoria[temp_param_table$var == "populacao"] <- "Demografia"
temp_param_table$subcategoria[temp_param_table$var == "population_density"] <- "Demografia"

# allow variables in graphs size, color, and slider-axis

temp_param_table$color[temp_param_table$var == "front_2020"] <- TRUE #
temp_param_table$color[temp_param_table$var == "front_2020_label"] <- TRUE #

# allow variables in graphs x-axis

temp_param_table$x[temp_param_table$var == "front_2020"] <- TRUE
temp_param_table$x[temp_param_table$var == "front_2020_label"] <- TRUE # 

# disable variables in graphs y-axis

temp_param_table$y[temp_param_table$var == "front_2020"] <- FALSE
temp_param_table$y[temp_param_table$var == "front_2020_label"] <- FALSE # 

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_varias_amazonias_cross_section_dic.csv", fileEncoding = "UTF-8")
