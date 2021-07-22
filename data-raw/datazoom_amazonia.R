############################################################
#### Generate rds data in the folder ./data/ 
############################################################

#### Generate Data: INPE - PRODES: deforestation
library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)

#### Generate Data: INPE - PRODES: deforestation
prodes <- load_prodes(
  c(2000:2021),
  space_aggregation = "municipality",
  language = "pt"
)

saveRDS(data,
  file = "./data/prodes.rds"
)

#### Generate Data: INPE - DETER: deforestation warnings
deter <- load_deter(
  source = "amazonia",
  time_aggregation = "year",
  space_aggregation = "municipality",
  language = "pt"
)

saveRDS(deter,
     file = "./data/deter.rds"
)

#### Generate Data: INPE - DEGRAD: degradation (Work In Progress)
degrad <- load_degrad(c(2007:2016), 
                    time_aggregation = "year", 
                    space_aggregation = "municipality", 
                    language = "pt")

saveRDS(degrad,
     file = "./data/degrad.rds"
)

#### Generate Data: MDIC - COMEX: exports and imports

imp_ncm <- load_comex(year, ncm = TRUE, imp = TRUE, language = "pt")

saveRDS(imp_ncm,
        file = "./data/imp_ncm.rds"
)

#### Generate Data: IBGE - PIB-Munic: gdp
gdp_pop1 <- load_gdp(c(2000:2009)) # Quantidade limite de valores solicitados: 50000
gdp_pop2 <- load_gdp(c(2010:2017)) # Quantidade limite de valores solicitados: 50000
gdp <- rbind(gdp_pop1, gdp_pop2)


saveRDS(gdp,
     file = "./data/gdp.rds"
)

#### Generate Data: IBGE - CEMPRE: formal employment
employment1 <- load_amazon_employment(c(2006:2010), space_aggregation = "municipality", language = "pt")
employment2 <- load_amazon_employment(c(2010:2015), space_aggregation = "municipality", language = "pt")
employment3 <- load_amazon_employment(c(2016:2020), space_aggregation = "municipality", language = "pt")

employment <- rbind(employment1, employment2)
employment <- rbind(employment, employment3)

saveRDS(employment,
     file = "./data/employment.rds"
)

#### Generate Data: IBGE - Census: income
income <- load_amazon_income(2010, space_aggregation = "municipality", language = "pt")

saveRDS(income,
     file = "./data/income.rds"
)

#### Generate Data: IBGE - SIGMINE: mining area
sigmine <- load_sigmine(space_aggregation = 'municipality', source = NULL)

saveRDS(sigmine,
     file = "./data/sigmine.rds"
)

#### Generate Data: IBGE - PPM
ppm_cow_farm <- load_ppm(type=94 ,years = 2000:2019, aggregation_level = "municipality", language = "pt")
ppm_cattle_number <- load_ppm(type=3939 ,years = 2000:2019, aggregation_level = "municipality", language = "pt")
ppm_animal_orig_prod <- load_ppm(type=74 ,years = 2000:2019, aggregation_level = "municipality", language = "pt")
ppm_water_orig_prod <- load_ppm(type=3940 ,years = 2000:2019, aggregation_level = "municipality", language = "pt")

saveRDS(ppm_cow_farm,
        file = "./data/ppm_cow_farm.rds"
)

saveRDS(ppm_cattle_number,
        file = "./data/ppm_cattle_number.rds"
)
saveRDS(ppm_animal_orig_prod,
        file = "./data/ppm_animal_orig_prod.rds"
)
saveRDS(ppm_water_orig_prod,
        file = "./data/ppm_water_orig_prod.rds"
)

#### Generate Data: IBGE - PAM: agricultural data
pam <- load_pam_permanent(2015, aggregation_level = "municipality", language = "pt")

saveRDS(pam,
     file = "./data/pam.rds"
)

#### Generate Data: IBGE - PEVS: silviculture and plant extraction data
pevs <- datazoom.amazonia::load_pevs_areasilv(2017, aggregation_level = "municipality", language = "pt")

saveRDS(pevs,
     file = "./data/pevs.rds"
)

#### Generate Data: MAPBIOMAS: land covering
mapbiomas <- load_mapbiomas_covering(space_aggregation = 'municipality', path = NULL, covering = 3, years = c(2000:2010))

saveRDS(mapbiomas,
     file = "./data/mapbiomas.rds"
)

#### Generate Data: IMAZON - IPS: Social Progress Index by municipality
ips <- load_IPS(download_directory = getwd(), language = "pt")

saveRDS(ips,
     file = "./data/ips.rds"
)

#### Generate Data: SEEG - Greenhouse gases emissions by municipality
seeg <- load_seeg(language = "pt")

saveRDS(seeg,
     file = "./data/seeg.rds"
)


############################################
##  Data Zoom Amazonia
############################################

# call data
income <- readRDS(file = "data/income.rds")
prodes <- readRDS(file = "data/prodes.rds")
deter <- readRDS(file = "data/deter.rds")
gdp <- readRDS(file = "data/gdp.rds")
degrad <- readRDS(file = "data/degrad.rds")
ips <- readRDS(file = "data/ips.rds")
employment <- readRDS(file = "data/employment.rds")
#seeg <- readRDS(file = "data/seeg.rds")

# edit data to merge
class(gdp$Ano) <-  'numeric'
class(gdp$CodIBGE) <-  'character'
class(income$Ano) <-  'numeric'
class(deter$CodIBGE) <-  'character'
class(employment$CodIBGE) <-  'character'
class(employment$Ano) <-  'numeric'
class(ips$cod_municipio) <-  'character'

# merge all data
dz_munic <- income %>%
  full_join(prodes, by = c("CodIBGE","Ano", "Estado"))   %>%
  full_join(deter, by = c("CodIBGE","Ano"))   %>%
  full_join(gdp, by = c("CodIBGE","Ano", "Estado"))   %>%
  full_join(degrad, by = c("CodIBGE","Ano", "Estado")) %>%
  full_join(employment, by = c("CodIBGE","Ano")) %>% 
  full_join(ips, by = c("CodIBGE" = "cod_municipio"))
  

# edit final data
column(dz_munic)
class(dz_munic)
colnames(dz_munic)
  
dz_munic <- dz_munic %>% select(CodIBGE,
                                Ano,
                                Estado.x,
                                Renda_media,
                                Renda_mediana,
                                Ocupados,
                                Salario,
                                Empregados,
                                Firmas,
                                Desmatado,
                                Degradacao,
                                Municipio,
                                IPS)

# edit data format
class(dz_munic$CodIBGE)
dz_munic$CodIBGE <- as.factor(dz_munic$CodIBGE)
class(dz_munic$Estado.x)
dz_munic$Estado <- as.factor(dz_munic$Estado.x)

# convert time data to date
dz_munic$Ano <- as.Date(as.yearqtr(dz_munic$Ano))

# groups at the level: municipio
dz_munic$group <- dz_munic$Municipio

# unique rows
dz_munic <- unique(dz_munic, by = c(Ano, CodIBGE, Estado))
dz_munic <- dz_munic %>% group_by(CodIBGE)

# replace NA with column mean for numeric variables that does not vary with time
dz_munic <- dz_munic %>% 
  group_by(CodIBGE) %>% 
  mutate_at(vars(Renda_media, Renda_mediana),~ifelse(is.na(.x), mean(.x, na.rm = TRUE), .x))  

#
dz_munic <- dz_munic %>%
  arrange(CodIBGE, Ano)

# save data
saveRDS(dz_munic,
        file = "./data/dz_munic.rds"
)

#####################
# Build Dictionary 
#####################

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
temp_param_table$label[2] <- "Ano"
temp_param_table$label[3] <- "Estado"
temp_param_table$label[4] <- "Renda média municipal"
temp_param_table$label[5] <- "Renda mediana municipal"
temp_param_table$label[6] <- "Número de pessoas ocupadas"
temp_param_table$label[7] <- "Salário médio das pessas ocupadas"
temp_param_table$label[8] <- "Número de pessoas empregadas"
temp_param_table$label[9] <- "Número de firmas"
temp_param_table$label[10] <- "Área desmatada"
temp_param_table$label[11] <- "Área degradada"
temp_param_table$label[12] <- "Município"
temp_param_table$label[13] <- "Índice de Progresso Social (IPS)"

# label data source
temp_param_table$var_group[1] <- "Geral"
temp_param_table$var_group[2] <- "Geral"
temp_param_table$var_group[3] <- "Geral"
temp_param_table$var_group[4] <- "IBGE"
temp_param_table$var_group[5] <- "IBGE"
temp_param_table$var_group[6] <- "IBGE"
temp_param_table$var_group[7] <- "IBGE"
temp_param_table$var_group[8] <- "IBGE"
temp_param_table$var_group[9] <- "IBGE"
temp_param_table$var_group[10] <- "INPE - PRODES"
temp_param_table$var_group[11] <- "INPE - PRODES"
temp_param_table$var_group[12] <- "Geral"
temp_param_table$var_group[13] <- "IMAZON"

# label data category
temp_param_table$categoria[1] <- "Unidade geográfica"
temp_param_table$categoria[2] <- "Unidade de tempo"
temp_param_table$categoria[3] <- "Unidade geográfica"
temp_param_table$categoria[4] <- "Economia"
temp_param_table$categoria[5] <- "Economia"
temp_param_table$categoria[6] <- "Economia"
temp_param_table$categoria[7] <- "Economia"
temp_param_table$categoria[8] <- "Economia"
temp_param_table$categoria[9] <- "Economia"
temp_param_table$categoria[10] <- "Meio ambiente"
temp_param_table$categoria[11] <- "Meio ambiente"
temp_param_table$categoria[12] <- "Unidade geográfica"
temp_param_table$categoria[13] <- "Social"


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
temp_param_table$y[1] <- FALSE # "Código do município"
temp_param_table$y[2] <- FALSE # "Ano"
temp_param_table$y[3] <- FALSE # "Estado"
temp_param_table$y[12] <- FALSE # "Município"

# block and variables in graphs x-axis
temp_param_table$x[1] <- FALSE # "Código do município"
temp_param_table$x[2] <- FALSE # "Ano"
temp_param_table$x[12] <- FALSE # "Município"

# allow variables in graphs size, color, and slider-axis 
temp_param_table$size[4] <- TRUE # "Renda média municipal"
temp_param_table$size[5] <- TRUE # "Renda mediana municipal"
temp_param_table$size[13] <- TRUE # "Índice de Progresso Social (IPS)"

temp_param_table$color[3] <- TRUE # "Estado"
temp_param_table$color[4] <- TRUE # "Renda média municipal"
temp_param_table$color[5] <- TRUE # "Renda mediana municipal"
temp_param_table$color[13] <- TRUE # "Índice de Progresso Social (IPS)""

temp_param_table$slider[2] <- TRUE # "Ano"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_munic_dic.csv", fileEncoding = "UTF-8")
