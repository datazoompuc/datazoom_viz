############################################################
#### Generate rds data in the folder ./data/ 
############################################################

#### call packages
library(tidyverse)
library(tibble)
library(zoo)
library(sf)
library(geobr)
library(fst) # fast, easy and flexible way to serialize data frames

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

prodes <- readRDS(file = "data/prodes.rds")
prodes$CodIBGE <- prodes$CodIbge

gdp <- readRDS(file = "data/gdp.rds")
gdp$Ano <- gdp$Year
gdp$Year <- NULL
class(gdp$Ano) <-  'numeric'
class(gdp$CodIBGE) <-  'character'

#seeg <- readRDS(file = "data/seeg.rds")

# edit data to merge
class(prodes$CodIBGE) <-  'character'
class(gdp$CodIBGE) <-  'character'
class(gdp$Ano) <-  'numeric'

# merge all data
map_dz_munic <- prodes %>%
  full_join(gdp, by = c("CodIBGE","Ano"))

# colnames(map_dz_munic)
map_dz_munic <- map_dz_munic %>% arrange(CodIBGE, Ano, Estado) 

# edit final data
class(map_dz_munic)
colnames(map_dz_munic)
colnames(shapefile)

# merge data with amazon municipalities shapefile
map_dz_munic <- sp::merge(shapefile, map_dz_munic, by.x = 'cod_ibge', by.y = 'CodIBGE')

class(xxx)

# convert time data to date
map_dz_munic$Ano <- as.Date(as.yearqtr(map_dz_munic$Ano))

# colnames(map_dz_munic)
colnames(map_dz_munic)
map_dz_munic <- map_dz_munic %>% select(fid,
                                nm_municip,
                                uf,
                                cod_ibge,
                                Desmatado,
                                Incremento,
                                Floresta,
                                NaoFloresta,
                                Ano,
                                GDP,
                                Pop,
                                GDPpc,
                                geometry)

map_dz_munic$cod_ibge <- as.factor(map_dz_munic$cod_ibge)
map_dz_munic$estado <- as.factor(map_dz_munic$uf)

# groups at the level: municipio
map_dz_munic$group <- map_dz_munic$nm_municip

class(map_dz_munic)



map_dz_munic <- sf::st_simplify(map_dz_munic, dTolerance = 100) #
class(map_dz_munic)

  
# save data
saveRDS(map_dz_munic,
        file = "./data/map_dz_munic.rds"
)

# plot(map_dz_munic)

# save data in fst
# dat = map_dz_munic %>%
#   tibble::as_tibble() %>%
#   janitor::clean_names()

# dat$geometry <- NULL 
# fst_file <- paste0("./data/xxxmap_dz_munic.fst")
# write_fst(dat, fst_file)
# zzz <- read_fst(path = "data/xxxmap_dz_munic.fst")
##################################################################
# Build Dictionary 
##################################################################

map_dz_munic <- readRDS("./data/map_dz_munic.rds")

# extract variables from data
columns <- colnames(map_dz_munic)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = FALSE,
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

##################################################################
# label variables
##################################################################
temp_param_table$label[1] <- "Código do município"
temp_param_table$label[2] <- "Nome do município"
temp_param_table$label[3] <- "Estado"
temp_param_table$label[4] <- "Codigo IBGE"
temp_param_table$label[5] <- "Área de desmatada"
temp_param_table$label[6] <- "Incremento de desmatamento"
temp_param_table$label[7] <- "Área de floresta"
temp_param_table$label[8] <- "Área de não floresta"
temp_param_table$label[9] <- "Ano"
temp_param_table$label[10] <- "PIB"
temp_param_table$label[11] <- "População"
temp_param_table$label[12] <- "PIB percapita"
temp_param_table$label[13] <- "Geometry"
temp_param_table$label[14] <- "Estado"
temp_param_table$label[15] <- "Group"

##################################################################
# label data source
##################################################################
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
temp_param_table$var_group[12] <- "IBGE"
temp_param_table$var_group[13] <- "Terrabrasilis"
temp_param_table$var_group[14] <- "IBGE"
temp_param_table$var_group[15] <- "Geral"

##################################################################
# label data category
##################################################################
temp_param_table$categoria[1] <- "Unidade geográfica"
temp_param_table$categoria[2] <- "Unidade de tempo"
temp_param_table$categoria[3] <- "Unidade geográfica"
temp_param_table$categoria[3] <- "Unidade geográfica"


##################################################################
# label data subcategory
##################################################################
temp_param_table$subcategoria[1] <- "Município"
temp_param_table$subcategoria[2] <- "Anual"
temp_param_table$subcategoria[3] <- "Estado"

##################################################################
# block variables in graphs y-axis
##################################################################
temp_param_table$y[1] <- FALSE # "Codigo do município"
temp_param_table$y[2] <- FALSE # "nm_municip"
temp_param_table$y[3] <- FALSE # "uf_x"
temp_param_table$y[4] <- FALSE # 
temp_param_table$y[9] <- FALSE # "Ano"
temp_param_table$y[14] <- FALSE # 
temp_param_table$y[15] <- FALSE # 

##################################################################
# block and variables in graphs x-axis
##################################################################
temp_param_table$x[1] <- FALSE # "Codigo do municipio"
temp_param_table$x[2] <- FALSE # "nm_municip"
temp_param_table$x[3] <- FALSE # "uf_x"
temp_param_table$x[4] <- FALSE #  
temp_param_table$y[9] <- FALSE # "Ano"
temp_param_table$y[14] <- FALSE # 
temp_param_table$y[15] <- FALSE # 

##################################################################
# allow variables in graphs size, color, and slider-axis 
##################################################################
## size
## color
## slider
temp_param_table$slider[9] <- TRUE # "ano"

##################################################################
# save csv in utf-8 encoding
##################################################################
write.csv(temp_param_table, file = "./data/map_dz_munic_dic.csv", fileEncoding = "UTF-8")