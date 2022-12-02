#######################
## Geração Distribuída
#######################

# Sistema de Informações de Geração da Aneel
# fonte: Agencia Nacional de Energia Elétrica
# https://dadosabertos.aneel.gov.br/dataset/relacao-de-empreendimentos-de-geracao-distribuida


# packages --------------------------------------------------------------------------
library(tidyverse)
library(lubridate)
library(datazoom.amazonia)
library(sf)
library(sp)
library(scales) # to use label_percent()
library(rmapshaper)

# load data -------------------------------------------------------------------------
db_geracao_distribuida <- read_csv2(file = "C:/Users/DELL/Desktop/empreendimento-geracao-distribuida.csv") %>%
  janitor::clean_names()

# colnames(db_geracao_distribuida)
# db_geracao_distribuida$sig_uf %>% unique()
# db_geracao_distribuida$cod_municipio_ibge %>% unique()
# db_geracao_distribuida$cod_municipio_ibge %>% unique()

# munic_amz_legal <- datazoom.amazonia::municipalities %>%
#filter(legal_amazon == 1)

# code_muni <- munic_amz_legal$code_muni %>% unique()

# colnames(munic_amz_legal)
# munic_amz_legal$code_state %>% unique()
# munic_amz_legal$code_muni %>% unique()

# df_filtrado <- db_geracao_distribuida %>%
# filter(cod_municipio_ibge %in% code_muni)

# colnames(db_geracao_distribuida)
db_geracao_distribuida <- db_geracao_distribuida %>%
  group_by(cod_municipio_ibge, 
           sig_uf, 
           dsc_classe_consumo, 
           sig_modalidade_empreendimento, 
           sig_tipo_geracao, 
           dsc_fonte_geracao) %>%
  summarise(
    mda_potencia_instalada_kw = sum(mda_potencia_instalada_kw),
    qtd_uc_recebe_credito = sum(qtd_uc_recebe_credito)
  )

###################
# TERRABRASILIS
###################
# read shapefile
shapefile <- st_read("data/shapefiles/municipalities_legal_amazon.shp")

# data too heavy (over 100mb)
# solution: simplify geometry
#shapefile <- sf::st_simplify(shapefile, dTolerance = 400)

# plot(shapefile)
# shapefile$cod_ibge

######################################################
# merge data with amazon municipalities shapefile
######################################################
temporary_data <- sp::merge(shapefile, db_geracao_distribuida, by.x = "cod_ibge", by.y = "cod_municipio_ibge")

# drop municipalities with empty geometry
temporary_data <- temporary_data[!st_is_empty(temporary_data), , drop = FALSE]

# save simplified sf for faster maps
cols <- colnames(temporary_data)
temporary_data <- rmapshaper::ms_simplify(temporary_data, 
                                keep_shapes = TRUE, 
                                keep = 0.01)

colnames(temporary_data) <- cols

# long to wide
zzz <- temporary_data
zzz$geometry <- NULL

hhh <- pivot_wider(
  zzz,
  id_cols = c(cod_ibge),
  id_expand = FALSE,
  names_from = c(dsc_classe_consumo, 
                 sig_modalidade_empreendimento, 
                 sig_tipo_geracao, 
                 dsc_fonte_geracao),
  values_from = mda_potencia_instalada_kw
)

yyyy <- sp::merge(temporary_data, hhh, by.x = "cod_ibge", by.y = "cod_ibge")

# save at rds format
saveRDS(yyyy,
  file = "./data/aneel_geracao_distribuida.rds"
)

#####################
# Build Dictionary
#####################

# call data
temp <- readRDS("./data/aneel_geracao_distribuida.rds")

columns <- colnames(temp)

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
  var_group = "Energia - ANEEL",
  tipo = 1,
  unidade = "",
  categoria = "Economia",
  subcategoria = "Energia"
)

# Label
temp_param_table$label <- temp_param_table$var
temp_param_table$label[temp_param_table$var == "dsc_classe_consumo"] <- "Classificação de consumo"
temp_param_table$label[temp_param_table$var == "sig_modalidade_empreendimento"] <- "Sigla da modalidade"
temp_param_table$label[temp_param_table$var == "sig_tipo_geracao"] <- "Tipo de geração"
temp_param_table$label[temp_param_table$var == "dsc_fonte_geracao"] <- "Combustível usado"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw"] <- "Potência instalada"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito"] <- "Quantidade de unidades consumidoras"

# Unidade de medida
temp_param_table$unidade[temp_param_table$var == "mda_potencia_instalada_kw"] <- "KiloWatz"

# var_group variables
temp_param_table$var_group[temp_param_table$var == "mda_potencia_instalada_kw"] <- "Produção"
temp_param_table$var_group[temp_param_table$var == "qtd_uc_recebe_credito"] <- "Demanda"

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "dsc_classe_consumo"] <- FALSE
temp_param_table$y[temp_param_table$var == "sig_modalidade_empreendimento"] <- FALSE
temp_param_table$y[temp_param_table$var == "sig_tipo_geracao"] <- FALSE
temp_param_table$y[temp_param_table$var == "dsc_fonte_geracao"] <- FALSE

# block variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "dsc_classe_consumo"] <- FALSE
temp_param_table$x[temp_param_table$var == "sig_modalidade_empreendimento"] <- FALSE
temp_param_table$x[temp_param_table$var == "sig_tipo_geracao"] <- FALSE
temp_param_table$x[temp_param_table$var == "dsc_fonte_geracao"] <- FALSE

# allow variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "mda_potencia_instalada_kw"] <- TRUE
temp_param_table$y[temp_param_table$var == "qtd_uc_recebe_credito"] <- TRUE

# allow variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "mda_potencia_instalada_kw"] <- TRUE
temp_param_table$x[temp_param_table$var == "qtd_uc_recebe_credito"] <- TRUE

# allow variables geometry in maps
temp_param_table$y[temp_param_table$var == "geometry"] <- TRUE

# save csv in utf-8 encoding
write.csv(temp_param_table,
  file = "data/aneel_geracao_distribuida_dic.csv",
  fileEncoding = "UTF-8"
)
