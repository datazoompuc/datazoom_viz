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
# TERRABRASILIS
###################
# read shapefile
shapefile <- st_read("data/shapefiles/municipalities_legal_amazon.shp")

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
class(income$ano) <- "numeric"
# Reshaping data.frame from long  to wide format
income <- income %>%
  tidyr::pivot_wider(
    id_cols = c(cod_ibge),
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

# Identify and remove duplicate data
prodes <- prodes %>% distinct(cod_munic_ibge, ano, .keep_all = TRUE)

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
# gdp <- readRDS(file = "data/pib_municipality_dza.rds") # necessario atualizar com esses dados aqui

#código da atualização para incluir dados de 2018 e 2019
# gdp10_19_= read.csv2("data/pibsmunics10_19_.csv")
# 
# gdp18_19= gdp10_19_%>%
#   dplyr::filter(Ano >= 2018)%>%
#   dplyr::filter(Amazônia.Legal == 'Sim')%>%
#   dplyr::select(Código.do.Município,
#                 Nome.do.Município,
#                 Sigla.da.Unidade.da.Federação,
#                 Ano, 
#                 Produto.Interno.Bruto...a.preços.correntes..R..1.000.,
#                 Produto.Interno.Bruto.per.capita...a.preços.correntes..R..1.00.)%>%
#   tidyr::unite(Município, Nome.do.Município,Sigla.da.Unidade.da.Federação, sep=" - ")
# 
# class(gdp18_19$Produto.Interno.Bruto...a.preços.correntes..R..1.000.)= 'numeric'
# class(gdp18_19$Produto.Interno.Bruto.per.capita...a.preços.correntes..R..1.00.)= 'numeric'
# 
# gdp18_19= gdp18_19%>%
#   dplyr::mutate(Pop= round(1000*Produto.Interno.Bruto...a.preços.correntes..R..1.000./Produto.Interno.Bruto.per.capita...a.preços.correntes..R..1.00.),
#                 .before= Produto.Interno.Bruto.per.capita...a.preços.correntes..R..1.00.)%>%
#   dplyr::arrange(Código.do.Município)%>%
#   dplyr::mutate(X= 12353:13896, .before= Código.do.Município)
# 
# colnames(gdp18_19)= colnames(gdp_og)
# gdpatt= dplyr::bind_rows(gdp_og, gdp18_19)%>%
#   dplyr::arrange(CodIBGE)
# gdpatt$X= 1:13896
# 
# saveRDS(gdpatt, file = "data/gdp.rds")

gdp <- readRDS(file = "data/gdp.rds")
gdp <- gdp %>%
  janitor::clean_names()
class(gdp$ano) <- "numeric"
class(gdp$cod_ibge) <- "character"
# Replace NA with previous and next rows mean
gdp <- gdp %>%
  group_by(cod_ibge) %>%
  arrange(cod_ibge, ano)
gdp$pop <- zoo::na.approx(gdp$pop)
gdp$gd_ppc <- zoo::na.approx(gdp$gd_ppc)
# Identify and remove duplicate data
gdp <- gdp %>%
  distinct(cod_ibge, ano, .keep_all = TRUE) %>%
  arrange(cod_ibge, ano)
# select relevant variables
gdp <- gdp %>%
  select(cod_ibge, ano, pop, gdp, gd_ppc) %>%
  arrange(cod_ibge, ano)

# deflacionar gdp (ano base 2021)
gdp$gdp_deflacionado <- gdp$gdp
gdp$gd_ppc_deflacionado <- gdp$gd_ppc

gdp$gd_ppc_deflacionado[gdp$ano == 2002] <- gdp$gd_ppc_deflacionado[gdp$ano == 2002] * 3.059410125
gdp$gd_ppc_deflacionado[gdp$ano == 2003] <- gdp$gd_ppc_deflacionado[gdp$ano == 2003] * 2.67274462
gdp$gd_ppc_deflacionado[gdp$ano == 2004] <- gdp$gd_ppc_deflacionado[gdp$ano == 2004] * 2.481488406
gdp$gd_ppc_deflacionado[gdp$ano == 2005] <- gdp$gd_ppc_deflacionado[gdp$ano == 2005] * 2.310353402
gdp$gd_ppc_deflacionado[gdp$ano == 2006] <- gdp$gd_ppc_deflacionado[gdp$ano == 2006] * 2.185765931
gdp$gd_ppc_deflacionado[gdp$ano == 2007] <- gdp$gd_ppc_deflacionado[gdp$ano == 2007] * 2.122353953
gdp$gd_ppc_deflacionado[gdp$ano == 2008] <- gdp$gd_ppc_deflacionado[gdp$ano == 2008] * 2.029766565
gdp$gd_ppc_deflacionado[gdp$ano == 2009] <- gdp$gd_ppc_deflacionado[gdp$ano == 2009] * 1.917780744
gdp$gd_ppc_deflacionado[gdp$ano == 2010] <- gdp$gd_ppc_deflacionado[gdp$ano == 2010] * 1.833581122
gdp$gd_ppc_deflacionado[gdp$ano == 2011] <- gdp$gd_ppc_deflacionado[gdp$ano == 2011] * 1.729907957
gdp$gd_ppc_deflacionado[gdp$ano == 2012] <- gdp$gd_ppc_deflacionado[gdp$ano == 2012] * 1.62863921
gdp$gd_ppc_deflacionado[gdp$ano == 2013] <- gdp$gd_ppc_deflacionado[gdp$ano == 2013] * 1.534218261
gdp$gd_ppc_deflacionado[gdp$ano == 2014] <- gdp$gd_ppc_deflacionado[gdp$ano == 2014] * 1.453063703
gdp$gd_ppc_deflacionado[gdp$ano == 2015] <- gdp$gd_ppc_deflacionado[gdp$ano == 2015] * 1.356257603
gdp$gd_ppc_deflacionado[gdp$ano == 2016] <- gdp$gd_ppc_deflacionado[gdp$ano == 2016] * 1.225100709
gdp$gd_ppc_deflacionado[gdp$ano == 2017] <- gdp$gd_ppc_deflacionado[gdp$ano == 2017] * 1.162841975
gdp$gd_ppc_deflacionado[gdp$ano == 2018] <- gdp$gd_ppc_deflacionado[gdp$ano == 2018] * 1.130563082
gdp$gd_ppc_deflacionado[gdp$ano == 2019] <- gdp$gd_ppc_deflacionado[gdp$ano == 2019] * 1.089420805
gdp$gd_ppc_deflacionado[gdp$ano == 2020] <- gdp$gd_ppc_deflacionado[gdp$ano == 2020] * 1.045591981
gdp$gd_ppc_deflacionado[gdp$ano == 2021] <- gdp$gd_ppc_deflacionado[gdp$ano == 2021] * 1.0

gdp$gdp_deflacionado[gdp$ano == 2002] <- gdp$gdp_deflacionado[gdp$ano == 2002] * 3.059410125
gdp$gdp_deflacionado[gdp$ano == 2003] <- gdp$gdp_deflacionado[gdp$ano == 2003] * 2.67274462
gdp$gdp_deflacionado[gdp$ano == 2004] <- gdp$gdp_deflacionado[gdp$ano == 2004] * 2.481488406
gdp$gdp_deflacionado[gdp$ano == 2005] <- gdp$gdp_deflacionado[gdp$ano == 2005] * 2.310353402
gdp$gdp_deflacionado[gdp$ano == 2006] <- gdp$gdp_deflacionado[gdp$ano == 2006] * 2.185765931
gdp$gdp_deflacionado[gdp$ano == 2007] <- gdp$gdp_deflacionado[gdp$ano == 2007] * 2.122353953
gdp$gdp_deflacionado[gdp$ano == 2008] <- gdp$gdp_deflacionado[gdp$ano == 2008] * 2.029766565
gdp$gdp_deflacionado[gdp$ano == 2009] <- gdp$gdp_deflacionado[gdp$ano == 2009] * 1.917780744
gdp$gdp_deflacionado[gdp$ano == 2010] <- gdp$gdp_deflacionado[gdp$ano == 2010] * 1.833581122
gdp$gdp_deflacionado[gdp$ano == 2011] <- gdp$gdp_deflacionado[gdp$ano == 2011] * 1.729907957
gdp$gdp_deflacionado[gdp$ano == 2012] <- gdp$gdp_deflacionado[gdp$ano == 2012] * 1.62863921
gdp$gdp_deflacionado[gdp$ano == 2013] <- gdp$gdp_deflacionado[gdp$ano == 2013] * 1.534218261
gdp$gdp_deflacionado[gdp$ano == 2014] <- gdp$gdp_deflacionado[gdp$ano == 2014] * 1.453063703
gdp$gdp_deflacionado[gdp$ano == 2015] <- gdp$gdp_deflacionado[gdp$ano == 2015] * 1.356257603
gdp$gdp_deflacionado[gdp$ano == 2016] <- gdp$gdp_deflacionado[gdp$ano == 2016] * 1.225100709
gdp$gdp_deflacionado[gdp$ano == 2017] <- gdp$gdp_deflacionado[gdp$ano == 2017] * 1.162841975
gdp$gdp_deflacionado[gdp$ano == 2018] <- gdp$gdp_deflacionado[gdp$ano == 2018] * 1.130563082
gdp$gdp_deflacionado[gdp$ano == 2019] <- gdp$gdp_deflacionado[gdp$ano == 2019] * 1.089420805
gdp$gdp_deflacionado[gdp$ano == 2020] <- gdp$gdp_deflacionado[gdp$ano == 2020] * 1.045591981
gdp$gdp_deflacionado[gdp$ano == 2021] <- gdp$gdp_deflacionado[gdp$ano == 2021] * 1.0

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
    id_cols = c(cod_municipio),
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
    values_from = valor
  )

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

# seeg <- readRDS(file = "data/seeg.rds")

###################
#PPM - IBGE
###################

ppm_livestock <- readRDS(file = "data/ppm_municipality_livestock_inventory.rds")

#munics <- readxl::read_xls("data\\RELATORIO_DTB_BRASIL_MUNICIPIO.xls") %>%
 # dplyr::select("Código Município Completo", "Nome_Município")
#ppm_livestock$group <- plyr::mapvalues(ppm_livestock$group, from = munics$Nome_Município, to = munics$`Código Município Completo`)

ppm_livestock= ppm_livestock%>%
  dplyr::filter(ano >= 2000)%>%
  dplyr::select(geo_id, ano, num_v2670, num_v32794, num_v32796)

###################
#PAM - IBGE
###################

# ##GENERATING ALL CROPS DATA FOR 2000 TO 2019 AND SELECTING SPECIFIC VARIABLES -> soja, arroz, milho e mandioca
# pam_municipality_all_crops_2000_19= datazoom.amazonia::load_pam(dataset = 'pam_all_crops', raw_data = FALSE, geo_level = 'municipality', time_period = 2000:2010, language = 'pt')
# pam_municipality_all_crops_2011_19= datazoom.amazonia::load_pam(dataset = 'pam_all_crops', raw_data = FALSE, geo_level = 'municipality', time_period = 2011:2019, language = 'pt')
# 
# pam_municipality_all_crops_2000_10 = lapply(pam_municipality_all_crops_2000_10, as.numeric)
# pam_municipality_all_crops_2000_10 <- as.data.frame(pam_municipality_all_crops_2000_10)
# pam_municipality_all_crops_2000_10$geo_id = as.character(pam_municipality_all_crops_2000_10$geo_id)
# pam_municipality_all_crops_2000_10$ano = as.character(pam_municipality_all_crops_2000_10$ano)
# 
# pam_municipality_all_crops_2011_19 = lapply(pam_municipality_all_crops_2011_19, as.numeric)
# pam_municipality_all_crops_2011_19 <- as.data.frame(pam_municipality_all_crops_2011_19)
# pam_municipality_all_crops_2011_19$geo_id = as.character(pam_municipality_all_crops_2011_19$geo_id)
# pam_municipality_all_crops_2011_19$ano = as.character(pam_municipality_all_crops_2011_19$ano)
# 
# pam_municipality_all_crops_2000_19= bind_rows(pam_municipality_all_crops_2000_10, pam_municipality_all_crops_2011_19)
# 
# # selecting most relevant variables: soja=v40124, arroz=v40102, milho=v40122, mandioca=v40119
# pam_municipality_all_crops_2000_19= pam_municipality_all_crops_2000_19%>%
#   dplyr::select(.data$geo_id, .data$ano, dplyr::ends_with('40124'), dplyr::ends_with('40102'), dplyr::ends_with('40122'), dplyr::ends_with('40119') )
# 
# saveRDS(pam_municipality_all_crops_2000_19, "data/pam_municipality_all_crops_2000_19.rds")

pam_municipality_all_crops_2000_19= readRDS('data/pam_municipality_all_crops_2000_19.rds')
pam_municipality_all_crops_2000_19[is.na(pam_municipality_all_crops_2000_19)] <- 0  

###########################
# edit data to merge
###########################
class(income$cod_ibge) <-  'character'
class(ppm_livestock$geo_id) <-  'character'
class(cempre_municipality$cod_ibge) <-  'character'
class(prodes$cod_munic_ibge) <-  'character'
#class(deter$cod_ibge) <-  'character'
class(gdp$cod_ibge) <-  'character'
#class(degrad$cod_ibge) <-  'character'
class(ips$cod_municipio) <-  'character'
class(income$cod_ibge) <-  'character'
#class(ppm_livestock$group) <-  'character'


class(cempre_municipality$ano) <-  'numeric'
class(prodes$ano) <-  'numeric'
#class(deter$ano) <-  'numeric'
class(gdp$ano) <-  'numeric'
#class(degrad$ano) <-  'numeric'
#class(income$ano) <-  'numeric'
class(ips$cod_municipio) <-  'character'
class(pam_municipality_all_crops_2000_19$ano) <- 'numeric'

###########################
# merge all data
###########################
dz_munic <- income %>%
  full_join(prodes, by = c("cod_ibge" = "cod_munic_ibge")) %>%
  full_join(gdp, by = c("cod_ibge", "ano")) %>%
  full_join(cempre_municipality, by = c("cod_ibge", "ano")) %>%
  full_join(ips, by = c("cod_ibge" = "cod_municipio")) %>%
  full_join(ppm_livestock, by = c('cod_ibge' = 'geo_id', 'ano')) %>%
  full_join(pam_municipality_all_crops_2000_19, by = c('cod_ibge' = 'geo_id', 'ano' = 'ano')) %>%
  arrange(cod_ibge, ano) %>%
  relocate(cod_ibge, ano)

# colnames(dz_munic)
#dz_munic$name_munic <- dz_munic$name_munic.x
#dz_munic <- dz_munic %>% transform(estado = ifelse(!is.na(estado.x), estado.x, estado.y))

# edit final data
class(dz_munic)
colnames(dz_munic)

# edit data to merge
class(dz_munic$ano) <- "numeric"

# clean column names
dz_munic <- dz_munic %>%
  janitor::clean_names()

######################################################
# merge data with amazon municipalities shapefile
######################################################
map_dz_munic <- sp::merge(shapefile, dz_munic, by.x = "cod_ibge", by.y = "cod_ibge")

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
                                    num_v32794,
                                    num_v32796,
                                    area_plantada_dest_colheita_v40124,
                                    quant_v40124,
                                    area_plantada_dest_colheita_v40102,
                                    quant_v40102,
                                    area_plantada_dest_colheita_v40122,
                                    quant_v40122,
                                    area_plantada_dest_colheita_v40119,
                                    quant_v40119,
                                    gdp_deflacionado,
                                    gd_ppc_deflacionado)


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
dz_munic <- dz_munic[!st_is_empty(dz_munic), , drop = FALSE]

# limiting decimal places
dz_munic <- dz_munic %>%
  mutate(across(where(is.numeric) & !c(
    .data$prop_desmatado, .data$prop_floresta, .data$prop_incremento,
    .data$prop_hidrografia, .data$prop_nao_floresta
  ), ~ round(., digits = 1)))
# for the variables with proportions, limiting to 4 decimal places
dz_munic <- dz_munic %>%
  mutate(across(c(
    .data$prop_desmatado, .data$prop_floresta, .data$prop_incremento,
    .data$prop_hidrografia, .data$prop_nao_floresta
  ), ~ round(. * 100, digits = 1)))

# convert time data to date
# dz_munic$newdate <- as.Date(as.yearqtr(dz_munic$ano), format = "%Y")
# dz_munic$newdate <- strptime(as.character(dz_munic$newdate), "%Y-%m-%d")
# dz_munic$ano <- year(as.Date(as.yearqtr(dz_munic$ano), format = "%Y"))
# dz_munic$newdate <- NULL

# save data
saveRDS(dz_munic,
  file = "./data/dz_munic.rds"
)

# save simplified sf for faster maps
dz_munic_simp <- rmapshaper::ms_simplify(dz_munic, 
                                         keep_shapes = TRUE, 
                                         keep = 0.01)
readr::write_rds(dz_munic_simp,
        file = "./data/dz_munic_simplified.rds"
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
  categoria = "Categoria principal",
  subcategoria = "Subcategoria"
)

# label variables
temp_param_table$label[temp_param_table$var == "cod_ibge"] <- "Código do município"
temp_param_table$label[temp_param_table$var == "nm_municip"] <- "Nome do município"
temp_param_table$label[temp_param_table$var == "uf"] <- "Estado"
temp_param_table$label[temp_param_table$var == "ano"] <- "Ano"
temp_param_table$label[temp_param_table$var == "employed_census2000"] <- "Número de ocupados - Censo 2000"
temp_param_table$label[temp_param_table$var == "employed_census2010"] <- "Número de ocupados - Censo 2010"
temp_param_table$label[temp_param_table$var == "mean_income_census2000"] <- "Rendimento médio - Censo 2000"
temp_param_table$label[temp_param_table$var == "mean_income_census2010"] <- "Rendimento médio - Censo 2010"
temp_param_table$label[temp_param_table$var == "median_income_census2000"] <- "Rendimento mediano - Censo 2000"
temp_param_table$label[temp_param_table$var == "median_income_census2010"] <- "Rendimento mediano - Censo 2010"
temp_param_table$label[temp_param_table$var == "desmatado"] <- "Área total desmatada"
temp_param_table$label[temp_param_table$var == "incremento"] <- "Área total de incremento de desmatamento"
temp_param_table$label[temp_param_table$var == "floresta"] <- "Área total de floresta"
temp_param_table$label[temp_param_table$var == "nao_floresta"] <- "Área total de não-floresta"
temp_param_table$label[temp_param_table$var == "hidrografia"] <- "Área total de hidrografia"
temp_param_table$label[temp_param_table$var == "prop_desmatado"] <- "Proporção de desmatamento na área do município"
temp_param_table$label[temp_param_table$var == "prop_incremento"] <- "Proporção de incremento de desmatamento na área do município"
temp_param_table$label[temp_param_table$var == "prop_floresta"] <- "Proporção de floresta na área do município"
temp_param_table$label[temp_param_table$var == "prop_nao_floresta"] <- "Proporção de não-floresta na área do município"
temp_param_table$label[temp_param_table$var == "prop_hidrografia"] <- "Proporção de hidrografia na área do município"
temp_param_table$label[temp_param_table$var == "pop"] <- "População"
temp_param_table$label[temp_param_table$var == "gdp"] <- "PIB nominal"
temp_param_table$label[temp_param_table$var == "gd_ppc"] <- "PIB per capita nominal"
temp_param_table$label[temp_param_table$var == "gdp_deflacionado"] <- "PIB real (R$ 2021)"
temp_param_table$label[temp_param_table$var == "gd_ppc_deflacionado"] <- "PIB per capita real (R$ 2021)"
temp_param_table$label[temp_param_table$var == "cempre_n_empresas_organizacoes"] <- "Número de empresas e outras organizações"
temp_param_table$label[temp_param_table$var == "cempre_n_ocupados"] <- "Número de pessoas ocupadas"
temp_param_table$label[temp_param_table$var == "cempre_n_ocupados_assalariados"] <- "Número de pessoas ocupadas assalariadas"
temp_param_table$label[temp_param_table$var == "cempre_salarios_remuneracoes"] <- "Salários e outras remunerações"
temp_param_table$label[temp_param_table$var == "ips2018"] <- "IPS 2018"
temp_param_table$label[temp_param_table$var == "ips2014"] <- "IPS 2014"
temp_param_table$label[temp_param_table$var == "estado"] <- "Estado"
temp_param_table$label[temp_param_table$var == "geometry"] <- "Geometria"
temp_param_table$label[temp_param_table$var == "num_v2670"] <- "Efetivo dos Rebanhos Bovino"
temp_param_table$label[temp_param_table$var == "num_v2672"] <- "Efetivo dos Rebanhos Equino"
temp_param_table$label[temp_param_table$var == "num_v2675"] <- "Efetivo dos Rebanhos Bubalin"
temp_param_table$label[temp_param_table$var == "num_v2677"] <- "Efetivo dos Rebanhos Ovino"
temp_param_table$label[temp_param_table$var == "num_v2680"] <- "Efetivo dos Rebanhos Codornas"
temp_param_table$label[temp_param_table$var == "num_v2681"] <- "Efetivo dos Rebanhos Caprino"
temp_param_table$label[temp_param_table$var == "num_v32793"] <- "Efetivo dos Rebanhos Galinaceos - Galinhas"
temp_param_table$label[temp_param_table$var == "num_v32794"] <- "Efetivo dos Rebanhos Suino - Total"
temp_param_table$label[temp_param_table$var == "num_v32795"] <- "Efetivo dos Rebanhos Suino - Matrizes de Suinos"
temp_param_table$label[temp_param_table$var == "num_v32796"] <- "Efetivo dos Rebanhos Galinaceos - Total"

# unidade variables
temp_param_table$unidade[temp_param_table$var == "ano"] <- "Ano"
temp_param_table$unidade[temp_param_table$var == "employed_census2000"] <- "Pessoas"
temp_param_table$unidade[temp_param_table$var == "employed_census2010"] <- "Pessoas"
temp_param_table$unidade[temp_param_table$var == "mean_income_census2000"] <- "R$ em 2000"
temp_param_table$unidade[temp_param_table$var == "mean_income_census2010"] <- "R$ em 2010"
temp_param_table$unidade[temp_param_table$var == "median_income_census2000"] <- "R$ em 2000"
temp_param_table$unidade[temp_param_table$var == "median_income_census2010"] <- "R$ em 2010"
temp_param_table$unidade[temp_param_table$var == "desmatado"] <- "Km2"
temp_param_table$unidade[temp_param_table$var == "incremento"] <- "Km2"
temp_param_table$unidade[temp_param_table$var == "floresta"] <- "Km2"
temp_param_table$unidade[temp_param_table$var == "nao_floresta"] <- "Km2"
temp_param_table$unidade[temp_param_table$var == "hidrografia"] <- "Km2"
temp_param_table$unidade[temp_param_table$var == "prop_desmatado"] <- "%"
temp_param_table$unidade[temp_param_table$var == "prop_incremento"] <- "%"
temp_param_table$unidade[temp_param_table$var == "prop_floresta"] <- "%"
temp_param_table$unidade[temp_param_table$var == "prop_nao_floresta"] <- "%"
temp_param_table$unidade[temp_param_table$var == "prop_hidrografia"] <- "%"
temp_param_table$unidade[temp_param_table$var == "pop"] <- "Pessoas"
temp_param_table$unidade[temp_param_table$var == "gdp"] <- "1000 R$"
temp_param_table$unidade[temp_param_table$var == "gd_ppc"] <- "R$"
temp_param_table$unidade[temp_param_table$var == "gdp_deflacionado"] <- "1000 R$"
temp_param_table$unidade[temp_param_table$var == "gd_ppc_deflacionado"] <- "1000 R$"
temp_param_table$unidade[temp_param_table$var == "cempre_n_empresas_organizacoes"] <- "Estabelecimentos"
temp_param_table$unidade[temp_param_table$var == "cempre_n_ocupados"] <- "Pessoas"
temp_param_table$unidade[temp_param_table$var == "cempre_n_ocupados_assalariados"] <- "Pessoas"
temp_param_table$unidade[temp_param_table$var == "cempre_salarios_remuneracoes"] <- "R$"
temp_param_table$unidade[temp_param_table$var == "ips2018"] <- "Índice de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "ips2014"] <- "Índice de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "num_v2670"] <- "Cabeça de animais"
temp_param_table$unidade[temp_param_table$var == "num_v2672"] <- "Cabeça de animais"
temp_param_table$unidade[temp_param_table$var == "num_v2675"] <- "Cabeça de animais"
temp_param_table$unidade[temp_param_table$var == "num_v2677"] <- "Cabeça de animais"
temp_param_table$unidade[temp_param_table$var == "num_v2680"] <- "Cabeça de animais"
temp_param_table$unidade[temp_param_table$var == "num_v2681"] <- "Cabeça de animais"
temp_param_table$unidade[temp_param_table$var == "num_v32793"] <- "Cabeça de animais"
temp_param_table$unidade[temp_param_table$var == "num_v32794"] <- "Cabeça de animais"
temp_param_table$unidade[temp_param_table$var == "num_v32795"] <- "Cabeça de animais"
temp_param_table$unidade[temp_param_table$var == "num_v32796"] <- "Cabeça de animais"
temp_param_table$unidade[temp_param_table$var == "geometry"] <- ""
temp_param_table$unidade[temp_param_table$var == "estado"] <- ""
temp_param_table$unidade[temp_param_table$var == "group"] <- ""

# var_group variables
temp_param_table$var_group[temp_param_table$var == "ano"] <- ""
temp_param_table$var_group[temp_param_table$var == "employed_census2000"] <- "IBGE - Censo 2000"
temp_param_table$var_group[temp_param_table$var == "employed_census2010"] <- "IBGE - Censo 2010"
temp_param_table$var_group[temp_param_table$var == "mean_income_census2000"] <- "IBGE - Censo 2000"
temp_param_table$var_group[temp_param_table$var == "mean_income_census2010"] <- "IBGE - Censo 2010"
temp_param_table$var_group[temp_param_table$var == "median_income_census2000"] <- "IBGE - Censo 2000"
temp_param_table$var_group[temp_param_table$var == "median_income_census2010"] <- "IBGE - Censo 2010"
temp_param_table$var_group[temp_param_table$var == "desmatado"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "incremento"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "floresta"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "nao_floresta"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "hidrografia"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "prop_desmatado"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "prop_incremento"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "prop_floresta"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "prop_nao_floresta"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "prop_hidrografia"] <- "INPE - PRODES"
temp_param_table$var_group[temp_param_table$var == "pop"] <- "IBGE"
temp_param_table$var_group[temp_param_table$var == "gdp"] <- "IBGE"
temp_param_table$var_group[temp_param_table$var == "gd_ppc"] <- "IBGE"
temp_param_table$var_group[temp_param_table$var == "gdp_deflacionado"] <- "IBGE"
temp_param_table$var_group[temp_param_table$var == "gd_ppc_deflacionado"] <- "IBGE"
temp_param_table$var_group[temp_param_table$var == "cempre_n_empresas_organizacoes"] <- "IBGE - CEMPRE"
temp_param_table$var_group[temp_param_table$var == "cempre_n_ocupados"] <- "IBGE - CEMPRE"
temp_param_table$var_group[temp_param_table$var == "cempre_n_ocupados_assalariados"] <- "IBGE - CEMPRE"
temp_param_table$var_group[temp_param_table$var == "cempre_salarios_remuneracoes"] <- "IBGE - CEMPRE"
temp_param_table$var_group[temp_param_table$var == "ips2018"] <- "IMAZON"
temp_param_table$var_group[temp_param_table$var == "ips2014"] <- "IMAZON"
temp_param_table$var_group[temp_param_table$var == "num_v2670"] <- "IBGE - PPM"
temp_param_table$var_group[temp_param_table$var == "num_v2672"] <- "IBGE - PPM"
temp_param_table$var_group[temp_param_table$var == "num_v2675"] <- "IBGE - PPM"
temp_param_table$var_group[temp_param_table$var == "num_v2677"] <- "IBGE - PPM"
temp_param_table$var_group[temp_param_table$var == "num_v2680"] <- "IBGE - PPM"
temp_param_table$var_group[temp_param_table$var == "num_v2681"] <- "IBGE - PPM"
temp_param_table$var_group[temp_param_table$var == "num_v32793"] <- "IBGE - PPM"
temp_param_table$var_group[temp_param_table$var == "num_v32794"] <- "IBGE - PPM"
temp_param_table$var_group[temp_param_table$var == "num_v32795"] <- "IBGE - PPM"
temp_param_table$var_group[temp_param_table$var == "num_v32796"] <- "IBGE - PPM"
temp_param_table$var_group[temp_param_table$var == "geometry"] <- "Terrabrasilis"
temp_param_table$var_group[temp_param_table$var == "estado"] <- "Geral"
temp_param_table$var_group[temp_param_table$var == "group"] <- ""

# label data category
temp_param_table$categoria[temp_param_table$var == "ano"] <- "Unidade de tempo"
temp_param_table$categoria[temp_param_table$var == "employed_census2000"] <- "Mercado de trabalho"
temp_param_table$categoria[temp_param_table$var == "employed_census2010"] <- "Mercado de trabalho"
temp_param_table$categoria[temp_param_table$var == "mean_income_census2000"] <- "Mercado de trabalho"
temp_param_table$categoria[temp_param_table$var == "mean_income_census2010"] <- "Mercado de trabalho"
temp_param_table$categoria[temp_param_table$var == "median_income_census2000"] <- "Mercado de trabalho"
temp_param_table$categoria[temp_param_table$var == "median_income_census2010"] <- "Mercado de trabalho"
temp_param_table$categoria[temp_param_table$var == "desmatado"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "incremento"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "floresta"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "nao_floresta"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "hidrografia"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "prop_desmatado"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "prop_incremento"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "prop_floresta"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "prop_nao_floresta"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "prop_hidrografia"] <- "Meio ambiente"
temp_param_table$categoria[temp_param_table$var == "pop"] <- "Demografia"
temp_param_table$categoria[temp_param_table$var == "gdp"] <- "Economia"
temp_param_table$categoria[temp_param_table$var == "gd_ppc"] <- "Economia"
temp_param_table$categoria[temp_param_table$var == "gdp_deflacionado"] <- "Economia"
temp_param_table$categoria[temp_param_table$var == "gd_ppc_deflacionado"] <- "Economia"
temp_param_table$categoria[temp_param_table$var == "cempre_n_empresas_organizacoes"] <- "Mercado de trabalho"
temp_param_table$categoria[temp_param_table$var == "cempre_n_ocupados"] <- "Mercado de trabalho"
temp_param_table$categoria[temp_param_table$var == "cempre_n_ocupados_assalariados"] <- "Mercado de trabalho"
temp_param_table$categoria[temp_param_table$var == "cempre_salarios_remuneracoes"] <- "Mercado de trabalho"
temp_param_table$categoria[temp_param_table$var == "ips2018"] <- "Social"
temp_param_table$categoria[temp_param_table$var == "ips2014"] <- "Social"
temp_param_table$categoria[temp_param_table$var == "num_v2670"] <- "Produção Econômica"
temp_param_table$categoria[temp_param_table$var == "num_v2672"] <- "Produção Econômica"
temp_param_table$categoria[temp_param_table$var == "num_v2675"] <- "Produção Econômica"
temp_param_table$categoria[temp_param_table$var == "num_v2677"] <- "Produção Econômica"
temp_param_table$categoria[temp_param_table$var == "num_v2680"] <- "Produção Econômica"
temp_param_table$categoria[temp_param_table$var == "num_v2681"] <- "Produção Econômica"
temp_param_table$categoria[temp_param_table$var == "num_v32793"] <- "Produção Econômica"
temp_param_table$categoria[temp_param_table$var == "num_v32794"] <- "Produção Econômica"
temp_param_table$categoria[temp_param_table$var == "num_v32795"] <- "Produção Econômica"
temp_param_table$categoria[temp_param_table$var == "num_v32796"] <- "Produção Econômica"
temp_param_table$categoria[temp_param_table$var == "geometry"] <- ""
temp_param_table$categoria[temp_param_table$var == "estado"] <- ""
temp_param_table$categoria[temp_param_table$var == "group"] <- ""

# subcategoria variables
temp_param_table$subcategoria[temp_param_table$var == "ano"] <- "Ano"
temp_param_table$subcategoria[temp_param_table$var == "employed_census2000"] <- "Emprego"
temp_param_table$subcategoria[temp_param_table$var == "employed_census2010"] <- "Emprego"
temp_param_table$subcategoria[temp_param_table$var == "mean_income_census2000"] <- "Rendimento"
temp_param_table$subcategoria[temp_param_table$var == "mean_income_census2010"] <- "Rendimento"
temp_param_table$subcategoria[temp_param_table$var == "median_income_census2000"] <- "Rendimento"
temp_param_table$subcategoria[temp_param_table$var == "median_income_census2010"] <- "Rendimento"
temp_param_table$subcategoria[temp_param_table$var == "desmatado"] <- "Desmatamento"
temp_param_table$subcategoria[temp_param_table$var == "incremento"] <- "Desmatamento"
temp_param_table$subcategoria[temp_param_table$var == "floresta"] <- "Floresta"
temp_param_table$subcategoria[temp_param_table$var == "nao_floresta"] <- "Geografia"
temp_param_table$subcategoria[temp_param_table$var == "hidrografia"] <- "Geografia"
temp_param_table$subcategoria[temp_param_table$var == "prop_desmatado"] <- "Desmatamento"
temp_param_table$subcategoria[temp_param_table$var == "prop_incremento"] <- "Desmatamento"
temp_param_table$subcategoria[temp_param_table$var == "prop_floresta"] <- "Floresta"
temp_param_table$subcategoria[temp_param_table$var == "prop_nao_floresta"] <- "Geografia"
temp_param_table$subcategoria[temp_param_table$var == "prop_hidrografia"] <- "Geografia"
temp_param_table$subcategoria[temp_param_table$var == "pop"] <- "População"
temp_param_table$subcategoria[temp_param_table$var == "gdp"] <- "Desenvolvimento"
temp_param_table$subcategoria[temp_param_table$var == "gd_ppc"] <- "Desenvolvimento"
temp_param_table$subcategoria[temp_param_table$var == "gdp_deflacionado"] <- "Desenvolvimento"
temp_param_table$subcategoria[temp_param_table$var == "gd_ppc_deflacionado"] <- "Desenvolvimento"
temp_param_table$subcategoria[temp_param_table$var == "cempre_n_empresas_organizacoes"] <- "Empresa"
temp_param_table$subcategoria[temp_param_table$var == "cempre_n_ocupados"] <- "Trabalho"
temp_param_table$subcategoria[temp_param_table$var == "cempre_n_ocupados_assalariados"] <- "Trabalho"
temp_param_table$subcategoria[temp_param_table$var == "cempre_salarios_remuneracoes"] <- "Rendimento"
temp_param_table$subcategoria[temp_param_table$var == "ips2018"] <- "Desenvolvimento"
temp_param_table$subcategoria[temp_param_table$var == "ips2014"] <- "Desenvolvimento"
temp_param_table$subcategoria[temp_param_table$var == "num_v2670"] <- "Pecuária"
temp_param_table$subcategoria[temp_param_table$var == "num_v2672"] <- "Pecuária"
temp_param_table$subcategoria[temp_param_table$var == "num_v2675"] <- "Pecuária"
temp_param_table$subcategoria[temp_param_table$var == "num_v2677"] <- "Pecuária"
temp_param_table$subcategoria[temp_param_table$var == "num_v2680"] <- "Pecuária"
temp_param_table$subcategoria[temp_param_table$var == "num_v2681"] <- "Pecuária"
temp_param_table$subcategoria[temp_param_table$var == "num_v32793"] <- "Pecuária"
temp_param_table$subcategoria[temp_param_table$var == "num_v32794"] <- "Pecuária"
temp_param_table$subcategoria[temp_param_table$var == "num_v32795"] <- "Pecuária"
temp_param_table$subcategoria[temp_param_table$var == "num_v32796"] <- "Pecuária"
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

#filtering the ppm obs, because there is already a .csv dictionary for ppm livestock inventory
temp_param_table= temp_param_table%>%
  dplyr::filter(!startsWith(.data$var, 'num'))
#adding ppm dictionary
metappm= read.csv(file = 'data/ppm_municipality_livestock_inventory_dic.csv')
metappm <- metappm%>%
  dplyr::mutate(geometry = FALSE, desc= var)%>%
  dplyr::rename(var_group = source)%>%
  dplyr::select(-X, - tipo)%>%
  dplyr::filter(endsWith(.data$var, 'v2670')|endsWith(.data$var, 'v32794')|endsWith(.data$var, 'v32796'))
metappm$var_group= 'IBGE - PPM'

temp_param_table= dplyr::bind_rows(temp_param_table, metappm)

# allow variables in graphs size, color, and slider-axis
temp_param_table$size[temp_param_table$var == "employed_census2000"] <- TRUE #
temp_param_table$size[temp_param_table$var == "employed_census2010"] <- TRUE #
temp_param_table$size[temp_param_table$var == "mean_income_census2000"] <- TRUE #
temp_param_table$size[temp_param_table$var == "mean_income_census2010"] <- TRUE #
temp_param_table$size[temp_param_table$var == "median_income_census2000"] <- TRUE #
temp_param_table$size[temp_param_table$var == "median_income_census2010"] <- TRUE #
temp_param_table$size[temp_param_table$var == "ips2014"] <- TRUE #
temp_param_table$size[temp_param_table$var == "ips2018"] <- TRUE #
temp_param_table$size[temp_param_table$var == "pop"] <- TRUE #

temp_param_table$color[temp_param_table$var == "employed_census2000"] <- TRUE #
temp_param_table$color[temp_param_table$var == "employed_census2010"] <- TRUE #
temp_param_table$color[temp_param_table$var == "mean_income_census2000"] <- TRUE #
temp_param_table$color[temp_param_table$var == "mean_income_census2010"] <- TRUE #
temp_param_table$color[temp_param_table$var == "median_income_census2000"] <- TRUE #
temp_param_table$color[temp_param_table$var == "median_income_census2010"] <- TRUE #
temp_param_table$color[temp_param_table$var == "ips2014"] <- TRUE #
temp_param_table$color[temp_param_table$var == "ips2018"] <- TRUE #
temp_param_table$color[temp_param_table$var == "pop"] <- TRUE #
temp_param_table$color[temp_param_table$var == "estado"] <- TRUE #

temp_param_table$slider[temp_param_table$var == "ano"] <- TRUE # "ano"


#filtering the pam obs, because there is already a .csv dictionary for ppm livestock inventory
temp_param_table= temp_param_table%>%
  dplyr::filter(!startsWith(.data$var, 'quant'))%>%
  dplyr::filter(!startsWith(.data$var, 'area_plantada_dest_colheita'))


#adding pam dictionary
metapam= read.csv(file = 'data/pam_state_all_crops_dic.csv')
metapam <- metapam%>%
  dplyr::mutate(geometry = FALSE, desc= var)%>%
  dplyr::rename(var_group = source)%>%
  dplyr::select(-X, - tipo)%>%
  dplyr::filter(endsWith(.data$var, 'v40124')|endsWith(.data$var, 'v40102')|endsWith(.data$var, 'v40122')|endsWith(.data$var, 'v40119'))%>%
  dplyr::filter(startsWith(.data$var, 'quant')|startsWith(.data$var, 'area_plantada_dest_colheita'))
metapam$var_group= 'IBGE - PAM'

temp_param_table= dplyr::bind_rows(temp_param_table, metapam)


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_munic_dic.csv", fileEncoding = "UTF-8")


# relabel in english ----------------------------------------------------------------
temp_param_table$label[temp_param_table$var == "cod_ibge"] <- "Municipality code"
temp_param_table$label[temp_param_table$var == "nm_municip"] <- "Municipality name"
temp_param_table$label[temp_param_table$var == "uf"] <- "State"
temp_param_table$label[temp_param_table$var == "ano"] <- "Year"
temp_param_table$label[temp_param_table$var == "employed_census2000"] <- "Employed persons - Censo 2000"
temp_param_table$label[temp_param_table$var == "employed_census2010"] <- "Employed persons - Censo 2010"
temp_param_table$label[temp_param_table$var == "mean_income_census2000"] <- "Mean income - Censo 2000"
temp_param_table$label[temp_param_table$var == "mean_income_census2010"] <- "Mean income - Censo 2010"
temp_param_table$label[temp_param_table$var == "median_income_census2000"] <- "Median income - Censo 2000"
temp_param_table$label[temp_param_table$var == "median_income_census2010"] <- "Median income - Censo 2010"
temp_param_table$label[temp_param_table$var == "desmatado"] <- "Total deforested area"
temp_param_table$label[temp_param_table$var == "incremento"] <- "Total area of deforestation increment"
temp_param_table$label[temp_param_table$var == "floresta"] <- "Total forest area"
temp_param_table$label[temp_param_table$var == "nao_floresta"] <- "Total non-forest area"
temp_param_table$label[temp_param_table$var == "hidrografia"] <- "Total area of hydrography"
temp_param_table$label[temp_param_table$var == "prop_desmatado"] <- "Proportion of deforested area in the municipality"
temp_param_table$label[temp_param_table$var == "prop_incremento"] <- "Proportion of deforestation increment area in the municipality"
temp_param_table$label[temp_param_table$var == "prop_floresta"] <- "Proportion of forest area in the municipality"
temp_param_table$label[temp_param_table$var == "prop_nao_floresta"] <- "Proportion of non-forest area in the municipality"
temp_param_table$label[temp_param_table$var == "prop_hidrografia"] <- "Proportion of hydrography area in the municipality"
temp_param_table$label[temp_param_table$var == "pop"] <- "Population"
temp_param_table$label[temp_param_table$var == "gdp"] <- "Nominal GDP"
temp_param_table$label[temp_param_table$var == "gd_ppc"] <- "Nominal GDP per capita"
temp_param_table$label[temp_param_table$var == "gdp_deflacionado"] <- "Real GDP (R$ 2021)"
temp_param_table$label[temp_param_table$var == "gd_ppc_deflacionado"] <- "Real GDP per capita (R$ 2021)"
temp_param_table$label[temp_param_table$var == "cempre_n_empresas_organizacoes"] <- "Number of companies and other organizations"
temp_param_table$label[temp_param_table$var == "cempre_n_ocupados"] <- "Employed persons"
temp_param_table$label[temp_param_table$var == "cempre_n_ocupados_assalariados"] <- "Employed paid persons"
temp_param_table$label[temp_param_table$var == "cempre_salarios_remuneracoes"] <- "Wages"
temp_param_table$label[temp_param_table$var == "ips2018"] <- "IPS 2018"
temp_param_table$label[temp_param_table$var == "ips2014"] <- "IPS 2014"
temp_param_table$label[temp_param_table$var == "estado"] <- "State"
temp_param_table$label[temp_param_table$var == "geometry"] <- "Geometry"
temp_param_table$label[temp_param_table$var == "num_v2670"] <- "Cattle herds"
temp_param_table$label[temp_param_table$var == "num_v2672"] <- "Horse herds"
temp_param_table$label[temp_param_table$var == "num_v2675"] <- "Buffalo herds"
temp_param_table$label[temp_param_table$var == "num_v2677"] <- "Sheep herds"
temp_param_table$label[temp_param_table$var == "num_v2680"] <- "Quail herds"
temp_param_table$label[temp_param_table$var == "num_v2681"] <- "Goat herds"
temp_param_table$label[temp_param_table$var == "num_v32793"] <- "Gallinaceous - Chicken"
temp_param_table$label[temp_param_table$var == "num_v32794"] <- "Swine herds - Total"
temp_param_table$label[temp_param_table$var == "num_v32795"] <- "Swine herds - Matrizes de Suinos"
temp_param_table$label[temp_param_table$var == "num_v32796"] <- "Gallinaceous - Total"
temp_param_table$label[temp_param_table$var == "area_plantada_dest_colheita_v40102"] <- "Area Planted or Destined for Harvesting - Rice"
temp_param_table$label[temp_param_table$var == "quant_v40102"] <- "Quantity - Rice"
temp_param_table$label[temp_param_table$var == "area_plantada_dest_colheita_v40119"] <- "Area Planted or Destined for Harvesting - Manioc"
temp_param_table$label[temp_param_table$var == "quant_v40119"] <- "Quantity - Manioc"
temp_param_table$label[temp_param_table$var == "area_plantada_dest_colheita_v40122"] <- "Area Planted or Destined for Harvesting - Corn"
temp_param_table$label[temp_param_table$var == "quant_v40122"] <- "Quantity - Corn"
temp_param_table$label[temp_param_table$var == "area_plantada_dest_colheita_v40124"] <- "Area Planted or Destined for Harvesting - Soy"
temp_param_table$label[temp_param_table$var == "quant_v40124"] <- "Quantity - Soy"

# relabel in english ----------------------------------------------------------------
temp_param_table$unidade[temp_param_table$var == "ano"] <- "Year"
temp_param_table$unidade[temp_param_table$var == "employed_census2000"] <- "People"
temp_param_table$unidade[temp_param_table$var == "employed_census2010"] <- "People"
temp_param_table$unidade[temp_param_table$var == "mean_income_census2000"] <- "R$ in 2000"
temp_param_table$unidade[temp_param_table$var == "mean_income_census2010"] <- "R$ in 2010"
temp_param_table$unidade[temp_param_table$var == "median_income_census2000"] <- "R$ in 2000"
temp_param_table$unidade[temp_param_table$var == "median_income_census2010"] <- "R$ in 2010"
temp_param_table$unidade[temp_param_table$var == "desmatado"] <- "Km2"
temp_param_table$unidade[temp_param_table$var == "incremento"] <- "Km2"
temp_param_table$unidade[temp_param_table$var == "floresta"] <- "Km2"
temp_param_table$unidade[temp_param_table$var == "nao_floresta"] <- "Km2"
temp_param_table$unidade[temp_param_table$var == "hidrografia"] <- "Km2"
temp_param_table$unidade[temp_param_table$var == "prop_desmatado"] <- "%"
temp_param_table$unidade[temp_param_table$var == "prop_incremento"] <- "%"
temp_param_table$unidade[temp_param_table$var == "prop_floresta"] <- "%"
temp_param_table$unidade[temp_param_table$var == "prop_nao_floresta"] <- "%"
temp_param_table$unidade[temp_param_table$var == "prop_hidrografia"] <- "%"
temp_param_table$unidade[temp_param_table$var == "pop"] <- "People"
temp_param_table$unidade[temp_param_table$var == "gdp"] <- "1000 R$"
temp_param_table$unidade[temp_param_table$var == "gd_ppc"] <- "R$"
temp_param_table$unidade[temp_param_table$var == "gdp_deflacionado"] <- "1000 R$"
temp_param_table$unidade[temp_param_table$var == "gd_ppc_deflacionado"] <- "1000 R$"
temp_param_table$unidade[temp_param_table$var == "cempre_n_empresas_organizacoes"] <- "Establishments"
temp_param_table$unidade[temp_param_table$var == "cempre_n_ocupados"] <- "People"
temp_param_table$unidade[temp_param_table$var == "cempre_n_ocupados_assalariados"] <- "People"
temp_param_table$unidade[temp_param_table$var == "cempre_salarios_remuneracoes"] <- "R$"
temp_param_table$unidade[temp_param_table$var == "ips2018"] <- "0 to 100 Index"
temp_param_table$unidade[temp_param_table$var == "ips2014"] <- "0 to 100 Index"
temp_param_table$unidade[temp_param_table$var == "num_v2670"] <- "Animal Unit"
temp_param_table$unidade[temp_param_table$var == "num_v2672"] <- "Animal Unit"
temp_param_table$unidade[temp_param_table$var == "num_v2675"] <- "Animal Unit"
temp_param_table$unidade[temp_param_table$var == "num_v2677"] <- "Animal Unit"
temp_param_table$unidade[temp_param_table$var == "num_v2680"] <- "Animal Unit"
temp_param_table$unidade[temp_param_table$var == "num_v2681"] <- "Animal Unit"
temp_param_table$unidade[temp_param_table$var == "num_v32793"] <- "Animal Unit"
temp_param_table$unidade[temp_param_table$var == "num_v32794"] <- "Animal Unit"
temp_param_table$unidade[temp_param_table$var == "num_v32795"] <- "Animal Unit"
temp_param_table$unidade[temp_param_table$var == "num_v32796"] <- "Animal Unit"
temp_param_table$unidade[temp_param_table$var == "geometry"] <- ""
temp_param_table$unidade[temp_param_table$var == "estado"] <- ""
temp_param_table$unidade[temp_param_table$var == "group"] <- ""


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_munic_dic_en.csv", fileEncoding = "UTF-8")
