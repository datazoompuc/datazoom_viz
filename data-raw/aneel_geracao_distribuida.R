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
  id_cols = c(cod_ibge, sig_uf, sig_tipo_geracao, sig_modalidade_empreendimento),
  id_expand = FALSE,
  names_from = c(dsc_classe_consumo, 
                 dsc_fonte_geracao),
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

temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UFV_Radiação solar"] <- "Potência Instalada - Comercial - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_UFV_Radiação solar"] <- "Potência Instalada - Residencial - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_R_UFV_Radiação solar"] <- "Potência Instalada - Residencial - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UFV_Radiação solar"] <- "Potência Instalada - Industrial - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UFV_Radiação solar"] <- "Potência Instalada - Rural - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder Público_P_UFV_Radiação solar"] <- "Potência Instalada - Poder Público - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UFV_Radiação solar"] <- "Potência Instalada - Comercial - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Serviço Público_P_UFV_Radiação solar"] <- "Potência Instalada - Serviço Público - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_C_UFV_Radiação solar"] <- "Potência Instalada - Residencial - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UFV_Radiação solar"] <- "Potência Instalada - Rural - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UFV_Radiação solar"] <- "Potência Instalada - Industrial - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_M_UFV_Radiação solar"] <- "Potência Instalada - Comercial - Múltiplo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_C_UFV_Radiação solar"] <- "Potência Instalada - Comercial - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_C_UFV_Radiação solar"] <- "Potência Instalada - Rural - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder Público_R_UFV_Radiação solar"] <- "Potência Instalada - Poder Público - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Gás de Alto Forno - Biomassa"] <- "Potência Instalada - Comercial - Microgeração - UTE - Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_Gás de Alto Forno - Biomassa"] <- "Potência Instalada - Comercial - Autoconsumo - UTE - Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_EOL_Cinética do vento"] <- "Potência Instalada - Comercial - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Iluminação pública_P_UFV_Radiação solar"] <- "Potência Instalada - Iluminação pública - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_Gás Natural"] <- "Potência Instalada - Comercial - Autoconsumo - UTE - Gás Natural"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_Bagaço de Cana de Açúcar"] <- "Potência Instalada - Comercial - Autoconsumo - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Serviço Público_R_UFV_Radiação solar"] <- "Potência Instalada - Serviço Público - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_C_UFV_Radiação solar"] <- "Potência Instalada - Industrial - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_EOL_Cinética do vento"] <- "Potência Instalada - Residencial - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_EOL_Cinética do vento"] <- "Potência Instalada - Industrial - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder Público_P_EOL_Cinética do vento"] <- "Potência Instalada - Poder Público - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_EOL_Cinética do vento"] <- "Potência Instalada - Rural - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_EOL_Cinética do vento"] <- "Potência Instalada - Comercial - Autoconsumo - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_C_EOL_Cinética do vento"] <- "Potência Instalada - Comercial - Compartilhada - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_R_EOL_Cinética do vento"] <- "Potência Instalada - Residencial - Autoconsumo - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UTE_Bagaço de Cana de Açúcar"] <- "Potência Instalada - Rural - Autoconsumo - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UTE_Biogás-AGR"] <- "Potência Instalada - Rural - Autoconsumo - UTE - Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Biogás - RA"] <- "Potência Instalada - Rural - Microgeração - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UTE_Biogás - RA"] <- "Potência Instalada - Rural - Autoconsumo - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_C_UTE_Biogás - RA"] <- "Potência Instalada - Comercial - Compartilhada - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Biogás - RA"] <- "Potência Instalada - Comercial - Microgeração - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_CGH_Potencial hidráulico"] <- "Potência Instalada - Rural - Microgeração - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_UTE_Biogás - RA"] <- "Potência Instalada - Residencial - Microgeração - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Bagaço de Cana de Açúcar"] <- "Potência Instalada - Industrial - Microgeração - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_M_UFV_Radiação solar"] <- "Potência Instalada - Residencial - Múltiplo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_M_UFV_Radiação solar"] <- "Potência Instalada - Rural - Múltiplo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_M_UFV_Radiação solar"] <- "Potência Instalada - Industrial - Múltiplo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Biogás-AGR"] <- "Potência Instalada - Rural - Microgeração - UTE - Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Biogás - Floresta"] <- "Potência Instalada - Comercial - Microgeração - UTE - BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Biogás - RU"] <- "Potência Instalada - Rural - Microgeração - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Iluminação pública_R_UFV_Radiação solar"] <- "Potência Instalada - Iluminação pública - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_Biogás - RA"] <- "Potência Instalada - Comercial - Autoconsumo - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UTE_Biogás - RU"] <- "Potência Instalada - Rural - Autoconsumo - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UTE_Biogás - Floresta"] <- "Potência Instalada - Rural - Autoconsumo - UTE - BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_CGH_Potencial hidráulico"] <- "Potência Instalada - Comercial - Autoconsumo - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_CGH_Potencial hidráulico"] <- "Potência Instalada - Industrial - Microgeração - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_CGH_Potencial hidráulico"] <- "Potência Instalada - Comercial - Microgeração - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_C_CGH_Potencial hidráulico"] <- "Potência Instalada - Comercial - Compartilhada - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_CGH_Potencial hidráulico"] <- "Potência Instalada - Rural - Autoconsumo - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Bagaço de Cana de Açúcar"] <- "Potência Instalada - Rural - Microgeração - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Biogás - Floresta"] <- "Potência Instalada - Rural - Microgeração - UTE - BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_CGH_Potencial hidráulico"] <- "Potência Instalada - Industrial - Autoconsumo - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UTE_Gás de Alto Forno - Biomassa"] <- "Potência Instalada - Industrial - Autoconsumo - UTE - Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_C_CGH_Potencial hidráulico"] <- "Potência Instalada - Rural - Compartilhada - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_C_CGH_Potencial hidráulico"] <- "Potência Instalada - Industrial - Compartilhada - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder Público_C_UFV_Radiação solar"] <- "Potência Instalada - Poder Público - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Bagaço de Cana de Açúcar"] <- "Potência Instalada - Comercial - Microgeração - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Gás de Alto Forno - Biomassa"] <- "Potência Instalada - Industrial - Microgeração - UTE - Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Biogás - RA"] <- "Potência Instalada - Industrial - Microgeração - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Resíduos Sólidos Urbanos - RU"] <- "Potência Instalada - Rural - Microgeração - UTE - Resíduos Sólidos Urbanos - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_UTE_Bagaço de Cana de Açúcar"] <- "Potência Instalada - Residencial - Microgeração - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder Público_M_UFV_Radiação solar"] <- "Potência Instalada - Poder Público - Múltiplo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Biogás - RU"] <- "Potência Instalada - Comercial - Microgeração - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Biogás - RU"] <- "Potência Instalada - Industrial - Microgeração - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder Público_P_UTE_Biogás - RA"] <- "Potência Instalada - Poder Público - Microgeração - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Resíduos Florestais"] <- "Potência Instalada - Industrial - Microgeração - UTE - Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder Público_R_UTE_Biogás - RU"] <- "Potência Instalada - Poder Público - Autoconsumo - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Resíduos Florestais"] <- "Potência Instalada - Comercial - Microgeração - UTE - Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Biogás-AGR"] <- "Potência Instalada - Industrial - Microgeração - UTE - Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_C_UTE_Biogás - RA"] <- "Potência Instalada - Rural - Compartilhada - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_Biogás - Floresta"] <- "Potência Instalada - Comercial - Autoconsumo - UTE - BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder Público_P_CGH_Potencial hidráulico"] <- "Potência Instalada - Poder Público - Microgeração - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UTE_Biogás-AGR"] <- "Potência Instalada - Industrial - Autoconsumo - UTE - Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UTE_Biogás - RU"] <- "Potência Instalada - Industrial - Autoconsumo - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial__UFV_Radiação solar"] <- "Potência Instalada - Residencial - UFV Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_C_UTE_Resíduos Florestais"] <- "Potência Instalada - Comercial - Compartilhada - UTE - Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Casca de Arroz"] <- "Potência Instalada - Industrial - Microgeração - UTE - Casca de Arroz"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_CGH_Potencial hidráulico"] <- "Potência Instalada - Residencial - Microgeração - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Resíduos Florestais"] <- "Potência Instalada - Rural - Microgeração - UTE - Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UTE_Casca de Arroz"] <- "Potência Instalada - Industrial - Autoconsumo - UTE - Casca de Arroz"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Gás Natural"] <- "Potência Instalada - Comercial - Microgeração - UTE - Gás Natural"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_Biogás - RU"] <- "Potência Instalada - Comercial - Autoconsumo - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Serviço Público_P_EOL_Cinética do vento"] <- "Potência Instalada - Serviço Público - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Resíduos Sólidos Urbanos - RU"] <- "Potência Instalada - Industrial - Microgeração - UTE - Resíduos Sólidos Urbanos - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_EOL_Cinética do vento"] <- "Potência Instalada - Industrial - Autoconsumo - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_R_UTE_Biogás - RA"] <- "Potência Instalada - Residencial - Autoconsumo - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Serviço Público_C_UFV_Radiação solar"] <- "Potência Instalada - Serviço Público - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_UTE_Gás Natural"] <- "Potência Instalada - Residencial - Microgeração - UTE - Gás Natural"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Iluminação pública_C_UFV_Radiação solar"] <- "Potência Instalada - Iluminação pública - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UTE_Gás Natural"] <- "Potência Instalada - Industrial - Autoconsumo - UTE - Gás Natural"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Biogás-AGR"] <- "Potência Instalada - Comercial - Microgeração - UTE - Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Gás de Alto Forno - Biomassa"] <- "Potência Instalada - Rural - Microgeração - UTE - Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UFV_Radiação solar"] <- " Qtd. de  Unidades - Comercial - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_UFV_Radiação solar"] <- " Qtd. de  Unidades - Residencial - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_R_UFV_Radiação solar"] <- " Qtd. de  Unidades - Residencial - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UFV_Radiação solar"] <- " Qtd. de  Unidades - Industrial - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UFV_Radiação solar"] <- " Qtd. de  Unidades - Rural - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder Público_P_UFV_Radiação solar"] <- " Qtd. de  Unidades - Poder Público - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UFV_Radiação solar"] <- " Qtd. de  Unidades - Comercial - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Serviço Público_P_UFV_Radiação solar"] <- " Qtd. de  Unidades - Serviço Público - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_C_UFV_Radiação solar"] <- " Qtd. de  Unidades - Residencial - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UFV_Radiação solar"] <- " Qtd. de  Unidades - Rural - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UFV_Radiação solar"] <- " Qtd. de  Unidades - Industrial - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_M_UFV_Radiação solar"] <- " Qtd. de  Unidades - Comercial - Múltiplo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_C_UFV_Radiação solar"] <- " Qtd. de  Unidades - Comercial - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_C_UFV_Radiação solar"] <- " Qtd. de  Unidades - Rural - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder Público_R_UFV_Radiação solar"] <- " Qtd. de  Unidades - Poder Público - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Gás de Alto Forno - Biomassa"] <- " Qtd. de  Unidades - Comercial - Microgeração - UTE - Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_Gás de Alto Forno - Biomassa"] <- " Qtd. de  Unidades - Comercial - Autoconsumo - UTE - Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_EOL_Cinética do vento"] <- " Qtd. de  Unidades - Comercial - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Iluminação pública_P_UFV_Radiação solar"] <- " Qtd. de  Unidades - Iluminação pública - Microgeração - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_Gás Natural"] <- " Qtd. de  Unidades - Comercial - Autoconsumo - UTE - Gás Natural"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_Bagaço de Cana de Açúcar"] <- " Qtd. de  Unidades - Comercial - Autoconsumo - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Serviço Público_R_UFV_Radiação solar"] <- " Qtd. de  Unidades - Serviço Público - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_C_UFV_Radiação solar"] <- " Qtd. de  Unidades - Industrial - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_EOL_Cinética do vento"] <- " Qtd. de  Unidades - Residencial - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_EOL_Cinética do vento"] <- " Qtd. de  Unidades - Industrial - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder Público_P_EOL_Cinética do vento"] <- " Qtd. de  Unidades - Poder Público - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_EOL_Cinética do vento"] <- " Qtd. de  Unidades - Rural - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_EOL_Cinética do vento"] <- " Qtd. de  Unidades - Comercial - Autoconsumo - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_C_EOL_Cinética do vento"] <- " Qtd. de  Unidades - Comercial - Compartilhada - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_R_EOL_Cinética do vento"] <- " Qtd. de  Unidades - Residencial - Autoconsumo - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UTE_Bagaço de Cana de Açúcar"] <- " Qtd. de  Unidades - Rural - Autoconsumo - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UTE_Biogás-AGR"] <- " Qtd. de  Unidades - Rural - Autoconsumo - UTE - Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Biogás - RA"] <- " Qtd. de  Unidades - Rural - Microgeração - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UTE_Biogás - RA"] <- " Qtd. de  Unidades - Rural - Autoconsumo - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_C_UTE_Biogás - RA"] <- " Qtd. de  Unidades - Comercial - Compartilhada - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Biogás - RA"] <- " Qtd. de  Unidades - Comercial - Microgeração - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_CGH_Potencial hidráulico"] <- " Qtd. de  Unidades - Rural - Microgeração - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_UTE_Biogás - RA"] <- " Qtd. de  Unidades - Residencial - Microgeração - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Bagaço de Cana de Açúcar"] <- " Qtd. de  Unidades - Industrial - Microgeração - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_M_UFV_Radiação solar"] <- " Qtd. de  Unidades - Residencial - Múltiplo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_M_UFV_Radiação solar"] <- " Qtd. de  Unidades - Rural - Múltiplo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_M_UFV_Radiação solar"] <- " Qtd. de  Unidades - Industrial - Múltiplo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Biogás-AGR"] <- " Qtd. de  Unidades - Rural - Microgeração - UTE - Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Biogás - Floresta"] <- " Qtd. de  Unidades - Comercial - Microgeração - UTE - BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Biogás - RU"] <- " Qtd. de  Unidades - Rural - Microgeração - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Iluminação pública_R_UFV_Radiação solar"] <- " Qtd. de  Unidades - Iluminação pública - Autoconsumo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_Biogás - RA"] <- " Qtd. de  Unidades - Comercial - Autoconsumo - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UTE_Biogás - RU"] <- " Qtd. de  Unidades - Rural - Autoconsumo - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UTE_Biogás - Floresta"] <- " Qtd. de  Unidades - Rural - Autoconsumo - UTE - BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_CGH_Potencial hidráulico"] <- " Qtd. de  Unidades - Comercial - Autoconsumo - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_CGH_Potencial hidráulico"] <- " Qtd. de  Unidades - Industrial - Microgeração - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_CGH_Potencial hidráulico"] <- " Qtd. de  Unidades - Comercial - Microgeração - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_C_CGH_Potencial hidráulico"] <- " Qtd. de  Unidades - Comercial - Compartilhada - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_CGH_Potencial hidráulico"] <- " Qtd. de  Unidades - Rural - Autoconsumo - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Bagaço de Cana de Açúcar"] <- " Qtd. de  Unidades - Rural - Microgeração - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Biogás - Floresta"] <- " Qtd. de  Unidades - Rural - Microgeração - UTE - BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_CGH_Potencial hidráulico"] <- " Qtd. de  Unidades - Industrial - Autoconsumo - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UTE_Gás de Alto Forno - Biomassa"] <- " Qtd. de  Unidades - Industrial - Autoconsumo - UTE - Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_C_CGH_Potencial hidráulico"] <- " Qtd. de  Unidades - Rural - Compartilhada - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_C_CGH_Potencial hidráulico"] <- " Qtd. de  Unidades - Industrial - Compartilhada - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder Público_C_UFV_Radiação solar"] <- " Qtd. de  Unidades - Poder Público - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Bagaço de Cana de Açúcar"] <- " Qtd. de  Unidades - Comercial - Microgeração - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Gás de Alto Forno - Biomassa"] <- " Qtd. de  Unidades - Industrial - Microgeração - UTE - Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Biogás - RA"] <- " Qtd. de  Unidades - Industrial - Microgeração - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Resíduos Sólidos Urbanos - RU"] <- " Qtd. de  Unidades - Rural - Microgeração - UTE - Resíduos Sólidos Urbanos - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_UTE_Bagaço de Cana de Açúcar"] <- " Qtd. de  Unidades - Residencial - Microgeração - UTE - Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder Público_M_UFV_Radiação solar"] <- " Qtd. de  Unidades - Poder Público - Múltiplo - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Biogás - RU"] <- " Qtd. de  Unidades - Comercial - Microgeração - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Biogás - RU"] <- " Qtd. de  Unidades - Industrial - Microgeração - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder Público_P_UTE_Biogás - RA"] <- " Qtd. de  Unidades - Poder Público - Microgeração - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Resíduos Florestais"] <- " Qtd. de  Unidades - Industrial - Microgeração - UTE - Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder Público_R_UTE_Biogás - RU"] <- " Qtd. de  Unidades - Poder Público - Autoconsumo - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Resíduos Florestais"] <- " Qtd. de  Unidades - Comercial - Microgeração - UTE - Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Biogás-AGR"] <- " Qtd. de  Unidades - Industrial - Microgeração - UTE - Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_C_UTE_Biogás - RA"] <- " Qtd. de  Unidades - Rural - Compartilhada - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_Biogás - Floresta"] <- " Qtd. de  Unidades - Comercial - Autoconsumo - UTE - BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder Público_P_CGH_Potencial hidráulico"] <- " Qtd. de  Unidades - Poder Público - Microgeração - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UTE_Biogás-AGR"] <- " Qtd. de  Unidades - Industrial - Autoconsumo - UTE - Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UTE_Biogás - RU"] <- " Qtd. de  Unidades - Industrial - Autoconsumo - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_NA_UFV_Radiação solar"] <- " Qtd. de  Unidades - Residencial - UFV Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_C_UTE_Resíduos Florestais"] <- " Qtd. de  Unidades - Comercial - Compartilhada - UTE - Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Casca de Arroz"] <- " Qtd. de  Unidades - Industrial - Microgeração - UTE - Casca de Arroz"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_CGH_Potencial hidráulico"] <- " Qtd. de  Unidades - Residencial - Microgeração - CGH - Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Resíduos Florestais"] <- " Qtd. de  Unidades - Rural - Microgeração - UTE - Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UTE_Casca de Arroz"] <- " Qtd. de  Unidades - Industrial - Autoconsumo - UTE - Casca de Arroz"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Gás Natural"] <- " Qtd. de  Unidades - Comercial - Microgeração - UTE - Gás Natural"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_Biogás - RU"] <- " Qtd. de  Unidades - Comercial - Autoconsumo - UTE - BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Serviço Público_P_EOL_Cinética do vento"] <- " Qtd. de  Unidades - Serviço Público - Microgeração - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Resíduos Sólidos Urbanos - RU"] <- " Qtd. de  Unidades - Industrial - Microgeração - UTE - Resíduos Sólidos Urbanos - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_EOL_Cinética do vento"] <- " Qtd. de  Unidades - Industrial - Autoconsumo - EOL - Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_R_UTE_Biogás - RA"] <- " Qtd. de  Unidades - Residencial - Autoconsumo - UTE - BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Serviço Público_C_UFV_Radiação solar"] <- " Qtd. de  Unidades - Serviço Público - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_UTE_Gás Natural"] <- " Qtd. de  Unidades - Residencial - Microgeração - UTE - Gás Natural"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Iluminação pública_C_UFV_Radiação solar"] <- " Qtd. de  Unidades - Iluminação pública - Compartilhada - UFV - Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UTE_Gás Natural"] <- " Qtd. de  Unidades - Industrial - Autoconsumo - UTE - Gás Natural"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Biogás-AGR"] <- " Qtd. de  Unidades - Comercial - Microgeração - UTE - Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Gás de Alto Forno - Biomassa"] <- " Qtd. de  Unidades - Rural - Microgeração - UTE - Gás de Alto Forno - Biomassa"

# Unidade de medida
temp_param_table$unidade[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw", ignore_case = TRUE))] <- "KiloWatz"
temp_param_table$unidade[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito", ignore_case = TRUE))] <- "Somatório de unidades consumidoras"

temp_param_table$unidade[temp_param_table$var == "mda_potencia_instalada_kw"] <- "KiloWatz"

# var_group variables
temp_param_table$var_group[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw_Industrial", ignore_case = TRUE))] <- "POTÊNCIA INSTALADA: INDUSTRIAL"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw_Residencial", ignore_case = TRUE))] <- "POTÊNCIA INSTALADA: RESIDENCIAL"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw_Rural", ignore_case = TRUE))] <- "POTÊNCIA INSTALADA: RURAL"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw_Poder", ignore_case = TRUE))] <- "POTÊNCIA INSTALADA: PODER PÚBLICO"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw_Comercial", ignore_case = TRUE))] <- "POTÊNCIA INSTALADA: COMERCIAL"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw_Iluminação", ignore_case = TRUE))] <- "POTÊNCIA INSTALADA: ILUMINAÇÃO PÚBLICA"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw_Serviço", ignore_case = TRUE))] <- "POTÊNCIA INSTALADA: SERVIÇO PÚBLICO"

temp_param_table$var_group[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito_Industrial", ignore_case = TRUE))] <- "QUANTIDADE DE UNIDADES CONSUMIDORAS: INDUSTRIAL"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito_Residencial", ignore_case = TRUE))] <- "QUANTIDADE DE UNIDADES CONSUMIDORAS: RESIDENCIAL"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito_Rural", ignore_case = TRUE))] <- "QUANTIDADE DE UNIDADES CONSUMIDORAS: RURAL"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito_Poder", ignore_case = TRUE))] <- "QUANTIDADE DE UNIDADES CONSUMIDORAS: PODER PÚBLICO"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito_Comercial", ignore_case = TRUE))] <- "QUANTIDADE DE UNIDADES CONSUMIDORAS: COMERCIAL"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito_Iluminação", ignore_case = TRUE))] <- "QUANTIDADE DE UNIDADES CONSUMIDORAS: ILUMINAÇÃO PÚBLICA"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito_Serviço", ignore_case = TRUE))] <- "QUANTIDADE DE UNIDADES CONSUMIDORAS: SERVIÇO PÚBLICO"

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
