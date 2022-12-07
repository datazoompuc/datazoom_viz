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
library(stringi)

# load data -------------------------------------------------------------------------
# Original raw data can be downloaded at: https://dadosabertos.aneel.gov.br/dataset/relacao-de-empreendimentos-de-geracao-distribuida
# Also can be downloaded at Data Zoom drive:
db_geracao_distribuida <- data.table::fread(file = "C:/Users/DELL/Desktop/empreendimento-geracao-distribuida.csv",
                                            encoding = "Latin-1") %>%
  janitor::clean_names()  
  
db_geracao_distribuida$cod_ibge <- db_geracao_distribuida$cod_municipio_ibge


# replace character "," to "."
db_geracao_distribuida$mda_potencia_instalada_kw <- gsub(",", ".", db_geracao_distribuida$mda_potencia_instalada_kw)
db_geracao_distribuida$qtd_uc_recebe_credito <- gsub(",", ".", db_geracao_distribuida$mda_potencia_instalada_kw)

# ensure variables are numeric
class(db_geracao_distribuida$mda_potencia_instalada_kw) <- "numeric"
class(db_geracao_distribuida$qtd_uc_recebe_credito) <- "numeric"

# convert long data to wide data
db_geracao_distribuida_collapsed <- pivot_wider(
  db_geracao_distribuida,
  id_cols = c(cod_ibge, sig_uf, dsc_fonte_geracao, sig_modalidade_empreendimento),
  id_expand = FALSE,
  names_from = c(dsc_classe_consumo),
  values_from = c(mda_potencia_instalada_kw, qtd_uc_recebe_credito),
  values_fn = sum
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
temporary_data <- sp::merge(shapefile, db_geracao_distribuida_collapsed, by.x = "cod_ibge", by.y = "cod_ibge")

# drop municipalities with empty geometry
temporary_data <- temporary_data[!st_is_empty(temporary_data), , drop = FALSE]

# save simplified sf for faster maps
cols <- colnames(temporary_data)
temporary_data <- rmapshaper::ms_simplify(temporary_data, 
                                keep_shapes = TRUE, 
                                keep = 0.01)

colnames(temporary_data) <- cols

# Relabel variables
temporary_data$sig_modalidade_empreendimento[temporary_data$sig_modalidade_empreendimento == "P"] <- "Microgeração"
temporary_data$sig_modalidade_empreendimento[temporary_data$sig_modalidade_empreendimento == "R"] <- "Autoconsumo "
temporary_data$sig_modalidade_empreendimento[temporary_data$sig_modalidade_empreendimento == "C"] <- "Compartilhada"
temporary_data$sig_modalidade_empreendimento[temporary_data$sig_modalidade_empreendimento == "M"] <- "Múltiplas"

# save at rds format
saveRDS(temporary_data,
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
  x = FALSE,
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

temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_Comercial"] <- "Potência Instalada - Comercial"   
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_Residencial"] <- "Potência Instalada - Residencial"  
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_Industrial"] <- "Potência Instalada - Industrial"   
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_Rural"] <- "Potência Instalada - Rural"  
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_Poder Público"] <- "Potência Instalada - Poder Público" 
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_Serviço Público"] <- "Potência Instalada - Serviço Público" 
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_Iluminação pública"] <- "Potência Instalada - Iluminação pública" 
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_Comercial"] <- "Qtd. de  Unidades - Comercial"   
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_Residencial"] <- "Qtd. de  Unidades - Residencial"     
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_Industrial"] <- "Qtd. de  Unidades - Industrial"     
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_Rural"] <- "Qtd. de  Unidades - Rural"      
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_Poder Público"] <- "Qtd. de  Unidades - Poder Público"     
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_Serviço Público"] <- "Qtd. de  Unidades - Serviço Público"    
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_Iluminação pública"] <- "Qtd. de  Unidades - Iluminação pública"    

# Unidade de medida
temp_param_table$unidade[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw", ignore_case = TRUE))] <- "KiloWatz"
temp_param_table$unidade[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito", ignore_case = TRUE))] <- "Somatório de unidades consumidoras"

# var_group variables
temp_param_table$var_group[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw", ignore_case = TRUE))] <- "POTÊNCIA INSTALADA:"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito", ignore_case = TRUE))] <- "QUANTIDADE DE UNIDADES CONSUMIDORAS:"

# block variables in graphs y-axis

# allow variables in graphs x-axis
temp_param_table$x[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito", ignore_case = TRUE))] <- TRUE
temp_param_table$x[str_detect(temp_param_table$var, regex("mda_potencia_instalada", ignore_case = TRUE))] <- TRUE

# allow variables geometry in maps
temp_param_table$y[temp_param_table$var == "geometry"] <- TRUE

# save csv in utf-8 encoding
write.csv(temp_param_table,
  file = "data/aneel_geracao_distribuida_dic.csv",
  fileEncoding = "UTF-8"
)
