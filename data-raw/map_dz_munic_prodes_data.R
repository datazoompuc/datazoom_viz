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
library(here)
library(data.table)
library(purrr)
library(glue)
library(plyr)
library(lubridate)

original <- readRDS(here::here("data", "dz_munic.rds"))

####################
# 1) Call and clean data
###################

###################
# TERRABRASILIS
###################
# read shapefile
#shapefile <- st_read("./data/shapefiles/municipalities_legal_amazon.shp")

munic <- readRDS(here::here("global", "munic_shapefile.rds"))
lgl_amazon <- readRDS(here::here("global", "legal_amazon_boundary.rds"))

#st_crs(munic)
#st_crs(lgl_amazon)


# 1) Mesma projecao e tirar Z/M se houver
munic      <- st_zm(munic, drop = TRUE, what = "ZM")
lgl_amazon <- st_zm(lgl_amazon, drop = TRUE, what = "ZM")
munic      <- st_transform(munic, st_crs(lgl_amazon))

# 2) Corrigir geometrias invalidas
munic_fix      <- st_make_valid(munic)
lgl_amazon_fix <- lgl_amazon %>% 
  st_make_valid() %>% 
  st_union()              # vira 1 poligono continuo

# se ainda der erro com S2, desligar temporariamente
sf_use_s2(FALSE)

# Intersecao / filtro espacial
munic_amazon <- st_intersection(munic_fix, lgl_amazon_fix)

# alternativa (costuma ser mais leve):
# munic_amazon <- st_filter(munic_fix, lgl_amazon_fix, .predicate = st_intersects)

# reativar S2 depois
sf_use_s2(TRUE)

shapefile <- munic_amazon

#plot(st_geometry(munic_amazon))

# data too heavy (over 100mb)
# solution: simplify geometry
#shapefile <- sf::st_simplify(shapefile, dTolerance = 400)

# plot(shapefile)
# shapefile$cod_ibge

###################
# CENSUS
###################
income <- fread(here::here("data", "income.csv"), encoding = "Latin-1")

colnames(income) <- c("municipio", "renda_media_dom_per_capita")

income <- income %>% 
  mutate(cod_ibge = str_sub(municipio, end = 6),
         municipio = str_sub(municipio, start = 7) %>% str_squish(),
         Ano = 2010)

# income <- income %>%
#     separate(Municipality, c("name_munic", "Estado"), " - ") %>%
#     janitor::clean_names() %>%
#     select(cod_ibge, name_munic, ano, employed, mean_income, median_income)
income$ano <- 2010
class(income$ano) <- "numeric"

income <- income %>% 
  mutate(id = cod_ibge) %>% 
  select(-Ano)

cod_ibge_mun <- datazoom.amazonia::municipalities %>% 
  select(cod_ibge = code_muni, municipio = name_muni, code_state) %>% 
  mutate(id = cod_ibge %>% str_sub(end = -2))

income <- income %>% 
  left_join(cod_ibge_mun, by = "id") %>% 
  mutate(municipio = municipio.y) %>% 
  select(municipio,
         cod_ibge = cod_ibge.y,
         ano,
         renda_media_dom_per_capita) %>% 
  mutate(cod_ibge = cod_ibge %>% as.character())


###################
# INPE - PRODES
###################
prodes <- readRDS(here::here("data", "prodes.rds"))
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

prodes_new <- readRDS(here::here("data", "prodes_2022_2024.rds"))
prodes_new <- prodes_new %>% 
    janitor::clean_names()

# generate variable by the share of municipality total area
prodes_new <- prodes_new %>% 
    mutate(incremento = desmatamento_km2 - lag(desmatamento_km2),
           prop_desmatado = desmatamento_km2 / area_km2,
           prop_incremento = incremento / area_km2) 

# UNFINISHED: variables floresta, nao_floresta, hidrografia missing


###################
# IMAZON - IPS
###################

ips_2014 <- readxl::read_xlsx(here::here("data", "IPS_amazonia_2023.xlsx"),
                              sheet = 4) %>%
  janitor::clean_names() %>% 
  select(cod_ibge = codigo_ibge, 
         municipio,
         estado,
         ips_amazonia_2014)
ips_2018 <- readxl::read_xlsx(here::here("data", "IPS_amazonia_2023.xlsx"),
                              sheet = 3) %>%
  janitor::clean_names() %>% 
  select(cod_ibge = codigo_ibge, 
         municipio,
         estado,
         ips_amazonia_2018)

ips_2021 <- readRDS(here::here("data", "ips_2021_atualizado.rds")) %>% select(cod_ibge, ips_2021 = ips_amazonia_2021) %>% 
  st_drop_geometry() %>% 
  mutate(cod_ibge = cod_ibge %>% as.character() %>% as.numeric())
ips_2023 <- readRDS(here::here("data", "ips_2023.rds")) %>% select(cod_ibge, ips_2023 = ips_amazonia_2023) %>% 
  st_drop_geometry() %>% 
  mutate(cod_ibge = cod_ibge %>% as.character() %>% as.numeric())

ips <- ips_2021 %>% 
  left_join(ips_2023, by = c("cod_ibge")) %>% 
  left_join(ips_2018, by = c("cod_ibge")) %>% 
  left_join(ips_2014, by = c("cod_ibge")) %>% 
  select(-ends_with("y")) %>% 
  dplyr::rename(municipio = municipio.x,
         estado = estado.x,
         ips_2018 = ips_amazonia_2018,
         ips_2014 = ips_amazonia_2014)

###################
# CEMPRE
###################

cempre_municipality <- readRDS(file = "./data/cempre_municipality_dza.rds")



###################
#PPM - IBGE
###################

ppm_livestock <- readRDS(file = "./data/ppm_municipality_livestock_inventory.rds")


ppm_livestock= ppm_livestock %>%
  dplyr::rename(ano = time,
         municipio = group) %>% 
  dplyr::filter(ano >= 2000)%>%
  dplyr::select(geo_id, municipio, ano, num_v2670, num_v32794, num_v32796) 

###################
#PAM - IBGE
###################

cols_pam <- c("area_plantada_dest_colheita_v40124",
              "quant_v40124",
              "area_plantada_dest_colheita_v40102",
              "quant_v40102",
              "area_plantada_dest_colheita_v40122",
              "quant_v40122",
              "area_plantada_dest_colheita_v40119",
              "quant_v40119")

pam_municipality_all_crops <- map(2000:2024, ~ readRDS(glue::glue("./data/pam_municipality_all_crops{.x}.rds")) %>% 
                                    select(geo_id, ano, cols_pam))

pam_municipality_all_crops <- pam_municipality_all_crops %>% 
  bind_rows() %>% 
  mutate(across(area_plantada_dest_colheita_v40124:quant_v40119, ~ .x %>% as.numeric())) %>% 
  mutate(across(area_plantada_dest_colheita_v40124:quant_v40119, ~ if_else(is.na(.x), 0, .x))) 


###########################
# edit data to merge
###########################
class(income$cod_ibge) <-  'character'
class(ppm_livestock$geo_id) <-  'character'
class(cempre_municipality$cod_ibge) <-  'character'
class(prodes$cod_munic_ibge) <-  'character'
#class(deter$cod_ibge) <-  'character'
#class(degrad$cod_ibge) <-  'character'
class(ips$cod_ibge) <-  'character'
class(income$cod_ibge) <-  'character'
#class(ppm_livestock$group) <-  'character'


class(cempre_municipality$ano) <-  'numeric'
class(prodes$ano) <-  'numeric'
#class(deter$ano) <-  'numeric'
#class(degrad$ano) <-  'numeric'
#class(income$ano) <-  'numeric'
class(ips$cod_ibge) <-  'character'
class(pam_municipality_all_crops$ano) <- 'numeric'


###########################
# merge all data
###########################
dz_munic <- income %>% 
  full_join(prodes, by = c("cod_ibge" = "cod_munic_ibge","ano")) %>%
  full_join(cempre_municipality, by = c("cod_ibge", "ano")) %>%
  full_join(ips %>% select(-municipio), by = c("cod_ibge" = "cod_ibge")) %>%
  full_join(ppm_livestock %>% select(-municipio), by = c('cod_ibge' = 'geo_id', 'ano')) %>%
  full_join(pam_municipality_all_crops, by = c('cod_ibge' = 'geo_id', 'ano' = 'ano')) %>%
  arrange(cod_ibge, ano) %>%
  relocate(cod_ibge, ano)

dz_munic$municipio <- plyr::mapvalues(dz_munic$cod_ibge, from = datazoom.amazonia::municipalities$code_muni, to = datazoom.amazonia::municipalities$municipality_mapbiomas)

dz_munic$uf <- plyr::mapvalues(dz_munic$cod_ibge, from = datazoom.amazonia::municipalities$code_muni, to = datazoom.amazonia::municipalities$abbrev_state)


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
map_dz_munic <- sp::merge(shapefile, dz_munic, by.x = "municipality_code", by.y = "cod_ibge")

# convert time data to date
map_dz_munic$ano <- as.Date(as.yearqtr(map_dz_munic$ano), format = "%Y")

# colnames(map_dz_munic)
dz_munic <- map_dz_munic %>% select(cod_ibge = municipality_code,
                                    nm_municip = municipio,
                                    uf,
                                    ano,
                                    desmatado,
                                    incremento,
                                    floresta,
                                    nao_floresta,
                                    hidrografia,
                                    prop_desmatado,
                                    prop_incremento,prop_floresta,
                                    prop_nao_floresta,
                                    prop_hidrografia,
                                    cempre_n_empresas_organizacoes,
                                    cempre_n_ocupados,
                                    cempre_n_ocupados_assalariados,
                                    cempre_salarios_remuneracoes,
                                    ips2018 = ips_2018,
                                    ips2014 = ips_2014,
                                    geometry = geom,
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
                                    quant_v40119)



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

census_2000_2010 <- original %>% 
  select(cod_ibge,
         employed_census2000,
         employed_census2010,
         mean_income_census2000,
         mean_income_census2010,
         median_income_census2000,
         median_income_census2010) %>% 
  distinct() %>% 
  st_drop_geometry()

dz_munic <- dz_munic %>% 
  left_join(census_2000_2010, 
            by = c("cod_ibge"))


nrow_dz_munic <- dz_munic %>% nrow()

gdp <- data.frame(
    pop = rep(NA_real_, nrow_dz_munic),
    gdp = rep(NA_real_, nrow_dz_munic),
    gd_ppc = rep(NA_real_, nrow_dz_munic),
    gdp_deflacionado = rep(NA_real_, nrow_dz_munic),
    gd_ppc_deflacionado = rep(NA_real_, nrow_dz_munic)
)

dz_munic <- dz_munic %>% cbind(gdp)

new_years <- seq(original$ano %>% year() %>% max(na.rm = T) + 1, dz_munic$ano %>% year() %>% max(na.rm = T))

dz_munic <- dz_munic %>% 
  filter(year(ano) %in% new_years)

dz_munic <- dz_munic[colnames(original)]

map_dz_munic_prodes_data <- rbind(original %>% distinct(), dz_munic)


## dz_munic_simplified ##

dz_munic_simplified <- readRDS("data/dz_munic_simplified.rds")

map_dz_munic_prodes_data_simplified <- map_dz_munic_prodes_data[colnames(dz_munic_simplified)]

map_dz_munic_prodes_data_simplified <- map_dz_munic_prodes_data_simplified %>% 
    ungroup() %>% 
    as.data.frame() %>% 
    st_as_sf() %>% 
    rmapshaper::ms_simplify(map_dz_munic_prodes_data_simplified,
                            keep_shapes = T,
                            keep = 0.01)


# O ms)simplify acima da o seguinte erro:
#Error in charToDate(x) : 
#    character string is not in a standard unambiguous format



# save data
saveRDS(dz_munic,
        file = "./data/map_dz_munic_prodes_data.rds"
)


