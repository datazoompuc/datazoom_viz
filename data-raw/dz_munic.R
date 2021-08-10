############################################################
#### Generate rds data in the folder ./data/ 
############################################################

#### Generate Data: INPE - PRODES: deforestation
library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(geobr)
library(sf)
library(tigris) # geojoin

####################
# Edit data
###################

############################################
##  Data Zoom Amazonia
############################################

# read shapefile
shapefile<-st_read('data/shapefiles/municipalities_legal_amazon.shp')
# plot(shapefile)
# shapefile$cod_ibge

# call data
income <- readRDS(file = "data/income.rds")
income$Ano <- income$Year
income <- income %>% separate(Municipality, c("name_munic", "Estado"), " - ")
class(income$Ano) <-  'numeric'
income$Year <- NULL
income$X <- NULL
income$Employed <- NULL
income$Municipality <- NULL

prodes <- readRDS(file = "data/prodes.rds")
prodes$CodIBGE <- prodes$CodIbge

deter <- readRDS(file = "data/deter.rds")
deter$Estado <- deter$UF
class(deter$CodIBGE) <-  'character'
deter$UF <- NULL

gdp <- readRDS(file = "data/gdp.rds")
gdp$Ano <- gdp$Year
gdp$Year <- NULL
class(gdp$Ano) <-  'numeric'
class(gdp$CodIBGE) <-  'character'

degrad <- readRDS(file = "data/degrad.rds")
degrad$Ano <- degrad$year
degrad$Year <- NULL

ips <- readRDS(file = "data/ips.rds")

employment <- readRDS(file = "data/employment.rds")
employment$Ano <- employment$Year
employment$Year <- NULL
employment <- employment %>% separate(Municipality, c("name_munic", "Estado"), " - ")

#seeg <- readRDS(file = "data/seeg.rds")

# edit data to merge
class(employment$CodIBGE) <-  'character'
class(prodes$CodIBGE) <-  'character'
class(deter$CodIBGE) <-  'character'
class(gdp$CodIBGE) <-  'character'
class(degrad$CodIBGE) <-  'character'
class(ips$cod_municipio) <-  'character'
class(income$CodIBGE) <-  'character'
class(prodes$Ano) <-  'numeric'
class(deter$Ano) <-  'numeric'
class(gdp$Ano) <-  'numeric'
class(degrad$Ano) <-  'numeric'
class(income$Ano) <-  'numeric'
class(ips$cod_municipio) <-  'character'

# merge all data
dz_munic <- income %>%
  full_join(prodes, by = c("CodIBGE","Ano","Estado"))   %>%
  full_join(deter, by = c("CodIBGE","Ano","Estado"))   %>% 
  full_join(degrad, by = c("CodIBGE","Ano")) %>%
  full_join(gdp, by = c("CodIBGE","Ano"))   %>%
  full_join(employment, by = c("CodIBGE","Ano")) %>% 
  full_join(ips, by = c("CodIBGE" = "cod_municipio"))

# colnames(dz_munic)

dz_munic <- transform(dz_munic, name_munic = ifelse(!is.na(name_munic.x), name_munic.x, Municipio.x))
dz_munic <- transform(dz_munic, name_munic = ifelse(!is.na(name_munic), name_munic, municipio))
dz_munic <- transform(dz_munic, name_munic = ifelse(!is.na(name_munic), name_munic, Municipio.y))
dz_munic <- transform(dz_munic, name_munic = ifelse(!is.na(name_munic), name_munic, name_munic.y))
dz_munic <- transform(dz_munic, Estado = ifelse(!is.na(Estado.x), Estado.x, Estado.y))
dz_munic <- transform(dz_munic, Estado = ifelse(!is.na(Estado), Estado, uf))
dz_munic <- transform(dz_munic, Estado = ifelse(!is.na(Estado), Estado, UF))

dz_munic <- dz_munic %>% arrange(CodIBGE, Ano, Estado) 

# edit final data
class(dz_munic)
colnames(dz_munic)

# merge data with amazon municipalities shapefile
dz_munic <- tigris::geo_join(shapefile, dz_munic, by_sp = 'cod_ibge', by_df = 'CodIBGE', how = 'inner')

dz_munic = dz_munic %>%
  tibble::as_tibble() %>%
  janitor::clean_names()

# colnames(dz_munic)
dz_munic <- dz_munic %>% select(cod_ibge,
                                nm_municip,
                                uf_x,
                                ano,
                                mean_income,
                                median_income,
                                area_km2,
                                floresta,
                                desmatado,
                                incremento,
                                hidrografia,
                                nao_floresta,
                                area_em_uc_km2,
                                area_em_municipio_km2,
                                degrad_degradation,
                                munic_a_pio,
                                gdp,
                                pop,
                                gd_ppc,
                                salary,
                                employed,
                                firms,
                                ips,
                                geometry)

dz_munic$estado <- dz_munic$uf_x
# unique(dz_munic$uf_x)
dz_munic <- dz_munic %>% dplyr::filter(estado == "AC" | estado == "AP" | estado == "AM" | estado == "PA" | estado == "MA" | estado == "RR" | estado == "RO" | estado == "MT" | estado == "TO") 
class(dz_munic$cod_ibge)
dz_munic$cod_ibge <- as.factor(dz_munic$cod_ibge)
dz_munic$estado <- as.factor(dz_munic$estado)

# convert time data to date
dz_munic$ano <- as.Date(as.yearqtr(dz_munic$ano))

# groups at the level: municipio
dz_munic$group <- dz_munic$name_munic

# unique rows
dz_munic <- unique(dz_munic, by = c(ano, cod_ibge, estado))
dz_munic <- dz_munic %>% group_by(cod_ibge)

# replace NA with column mean for numeric variables that does not vary with time
dz_munic <- dz_munic %>% 
  group_by(cod_ibge) %>% 
  mutate_at(vars(mean_income, median_income, ips),~ifelse(is.na(.x), mean(.x, na.rm = TRUE), .x))  

#
dz_munic <- dz_munic %>%
  arrange(cod_ibge, ano)


dz_munic$geometry <- NULL
  
# save data
saveRDS(dz_munic,
        file = "./data/dz_munic.rds"
)

#####################
# Build Dictionary 
#####################

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
  tipo = 1,
  unidade = "Unidade de medida",
  categoria= "Categoria principal", 
  subcategoria = "Subcategoria"
)

# label variables
temp_param_table$label[1] <- "Código do município"
temp_param_table$label[2] <- "Nome do município"
temp_param_table$label[3] <- "Estado"
temp_param_table$label[4] <- "Ano"
temp_param_table$label[5] <- "Renda média municipal"
temp_param_table$label[6] <- "Renda mediana municipal"
temp_param_table$label[7] <- "Área em km2"
temp_param_table$label[8] <- "Área de floresta"
temp_param_table$label[9] <- "Área de desmatada"
temp_param_table$label[10] <- "Incremento de desmatamento"
temp_param_table$label[11] <- "Área de hidrografia"
temp_param_table$label[12] <- "Área de não floresta"
temp_param_table$label[13] <- "area_em_uc_km2"
temp_param_table$label[14] <- "area_em_municipio_km2"
temp_param_table$label[15] <- "Área de degradação"
temp_param_table$label[16] <- "Nome do município"
temp_param_table$label[17] <- "PIB"
temp_param_table$label[18] <- "População"
temp_param_table$label[19] <- "PIB percapita"
temp_param_table$label[20] <- "Salário médio das pessas ocupadas"
temp_param_table$label[21] <- "Número de pessoas ocupadas"
temp_param_table$label[22] <- "Número de firmas"
temp_param_table$label[23] <- "Índice de Progresso Social (IPS)"
temp_param_table$label[24] <- "Estado"


# label data source
temp_param_table$var_group[1] <- "Geral"
temp_param_table$var_group[2] <- "Geral"
temp_param_table$var_group[3] <- "Geral"
temp_param_table$var_group[4] <- "Geral"
temp_param_table$var_group[5] <- "IBGE"
temp_param_table$var_group[6] <- "IBGE"
temp_param_table$var_group[7] <- "INPE - PRODES"
temp_param_table$var_group[8] <- "INPE - PRODES"
temp_param_table$var_group[9] <- "INPE - PRODES"
temp_param_table$var_group[10] <- "INPE - PRODES"
temp_param_table$var_group[11] <- "INPE - PRODES"
temp_param_table$var_group[12] <- "INPE - PRODES"
temp_param_table$var_group[13] <- "INPE - DETER"
temp_param_table$var_group[14] <- "INPE - DETER"
temp_param_table$var_group[15] <- "INPE - DEGRAD"
temp_param_table$var_group[16] <- "Geral"
temp_param_table$var_group[17] <- "IBGE"
temp_param_table$var_group[18] <- "IBGE"
temp_param_table$var_group[19] <- "IBGE"
temp_param_table$var_group[20] <- "IBGE"
temp_param_table$var_group[21] <- "IBGE"
temp_param_table$var_group[22] <- "IBGE"
temp_param_table$var_group[23] <- "IMAZON"
temp_param_table$var_group[24] <- "Geral"


# label data category
temp_param_table$categoria[1] <- "Unidade geográfica"
temp_param_table$categoria[2] <- "Unidade de tempo"
temp_param_table$categoria[3] <- "Unidade geográfica"
temp_param_table$categoria[4] <- "Meio ambiente"
temp_param_table$categoria[5] <- "Meio ambiente"
temp_param_table$categoria[6] <- "Meio ambiente"
temp_param_table$categoria[7] <- "Meio ambiente"
temp_param_table$categoria[8] <- "Meio ambiente"
temp_param_table$categoria[9] <- "Meio ambiente"
temp_param_table$categoria[10] <- "Meio ambiente"
temp_param_table$categoria[11] <- "Meio ambiente"
temp_param_table$categoria[12] <- "Unidade geográfica"
temp_param_table$categoria[13] <- "Economia"
temp_param_table$categoria[14] <- "Economia"
temp_param_table$categoria[15] <- "Economia"
temp_param_table$categoria[16] <- "Economia"
temp_param_table$categoria[17] <- "Economia"
temp_param_table$categoria[18] <- "Economia"
temp_param_table$categoria[19] <- "Economia"
temp_param_table$categoria[20] <- "Economia"
temp_param_table$categoria[21] <- "Economia"
temp_param_table$categoria[22] <- "Economia"
temp_param_table$categoria[23] <- "Social"
temp_param_table$categoria[24] <- "Unidade geográfica"

# label data subcategory
temp_param_table$subcategoria[1] <- "Município"
temp_param_table$subcategoria[2] <- "Anual"
temp_param_table$subcategoria[3] <- "Estado"
temp_param_table$subcategoria[4] <- "Rendimento"
temp_param_table$subcategoria[5] <- "Rendimento"
temp_param_table$subcategoria[6] <- "Mercado de trabalho"
temp_param_table$subcategoria[7] <- "Rendimento"
temp_param_table$subcategoria[8] <- "Mercado de trabalho"
temp_param_table$subcategoria[9] <- "Mercado de trabalho"
temp_param_table$subcategoria[10] <- "Desmatamento"
temp_param_table$subcategoria[11] <- "Degradação"
temp_param_table$subcategoria[12] <- "Município"
temp_param_table$subcategoria[13] <- "Desenvolvimento"

# block variables in graphs y-axis
temp_param_table$y[1] <- FALSE # "C?digo do munic?pio"
temp_param_table$y[2] <- FALSE # "nm_municip"
temp_param_table$y[3] <- FALSE # "uf_x"
temp_param_table$y[4] <- FALSE # "ano"
temp_param_table$y[16] <- FALSE # "munic_a_pio"
temp_param_table$y[24] <- FALSE # "estado"


# block and variables in graphs x-axis
temp_param_table$x[1] <- FALSE # "C?digo do munic?pio"
temp_param_table$x[2] <- FALSE # "nm_municip"
temp_param_table$x[3] <- FALSE # "uf_x"
temp_param_table$x[4] <- FALSE # "ano"
temp_param_table$x[16] <- FALSE # "munic_a_pio"
temp_param_table$x[24] <- TRUE # "estado"


# allow variables in graphs size, color, and slider-axis 
temp_param_table$size[5] <- TRUE # "Renda média municipal"
temp_param_table$size[6] <- TRUE # "Renda mediana municipal"
temp_param_table$size[7] <- TRUE # "area_km2"
temp_param_table$size[23] <- TRUE # "Índice de Progresso Social (IPS)"

temp_param_table$color[5] <- TRUE # "Renda m?dia municipal"
temp_param_table$color[6] <- TRUE # "Renda mediana municipal"
temp_param_table$color[23] <- TRUE # "Índice de Progresso Social (IPS)""
temp_param_table$color[24] <- TRUE # "Estado"

temp_param_table$slider[4] <- TRUE # "ano"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_munic_dic.csv", fileEncoding = "UTF-8")