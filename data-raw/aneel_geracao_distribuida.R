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
db_geracao_distribuida <- data.table::fread(
  file = "C:/Users/DELL/Desktop/empreendimento-geracao-distribuida.csv",
  encoding = "Latin-1"
) %>%
  janitor::clean_names()

db_geracao_distribuida$cod_ibge <- db_geracao_distribuida$cod_municipio_ibge


# replace character "," to "."
db_geracao_distribuida$mda_potencia_instalada_kw <- gsub(",", ".", db_geracao_distribuida$mda_potencia_instalada_kw)
db_geracao_distribuida$qtd_uc_recebe_credito <- gsub(",", ".", db_geracao_distribuida$mda_potencia_instalada_kw)

# ensure variables are numeric
class(db_geracao_distribuida$mda_potencia_instalada_kw) <- "numeric"
class(db_geracao_distribuida$qtd_uc_recebe_credito) <- "numeric"

# generate variable of year
db_geracao_distribuida <- db_geracao_distribuida %>%
  mutate(ano_cadastral = as.Date(dth_atualiza_cadastral_empreend, "%d/%m/%Y")) %>%
  mutate(ano_cadastral = year(ano_cadastral))

class(db_geracao_distribuida$ano_cadastral) <- "numeric"

# convert long data to wide data
db_geracao_distribuida_collapsed <- pivot_wider(
  db_geracao_distribuida,
  id_cols = c(cod_ibge, sig_uf, dsc_fonte_geracao, sig_modalidade_empreendimento, ano_cadastral),
  id_expand = FALSE,
  names_from = c(dsc_classe_consumo),
  values_from = c(mda_potencia_instalada_kw, qtd_uc_recebe_credito),
  values_fn = sum
)

remove(db_geracao_distribuida)

# clean names
db_geracao_distribuida_collapsed <- db_geracao_distribuida_collapsed %>% janitor::clean_names()

# sort data
db_geracao_distribuida_collapsed <- db_geracao_distribuida_collapsed %>%
  arrange(cod_ibge, dsc_fonte_geracao, sig_modalidade_empreendimento, ano_cadastral)

###################
# TERRABRASILIS
###################
# read shapefile
shapefile <- st_read("data/shapefiles/municipalities_legal_amazon.shp")

# data too heavy (over 100mb)
# solution: simplify geometry
# shapefile <- sf::st_simplify(shapefile, dTolerance = 400)

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
  keep = 0.01
)

colnames(temporary_data) <- cols

# sort data
temporary_data <- temporary_data %>%
  arrange(cod_ibge, sig_uf, dsc_fonte_geracao, sig_modalidade_empreendimento, ano_cadastral)

# merge with a balanced panel - extract info
years_to_expand <- temporary_data$ano_cadastral %>%
  unique() %>%
  sort()
mun_to_expand <- temporary_data$cod_ibge %>%
  unique() %>%
  sort()
fonte_to_expand <- temporary_data$dsc_fonte_geracao %>%
  unique() %>%
  sort()
mod_to_expand <- temporary_data$sig_modalidade_empreendimento %>%
  unique() %>%
  sort()

# merge with a balanced panel - expand by info
balanced_panel <- expand.grid(mun_to_expand, fonte_to_expand, mod_to_expand, years_to_expand)
colnames(balanced_panel) <- c("cod_ibge", "dsc_fonte_geracao", "sig_modalidade_empreendimento", "ano_cadastral")
balanced_panel <- balanced_panel %>% arrange(cod_ibge, dsc_fonte_geracao, sig_modalidade_empreendimento, ano_cadastral)

# merge with a balanced panel - left join
balanced_panel_merged <- left_join(balanced_panel, temporary_data, by = c("cod_ibge", "dsc_fonte_geracao", "sig_modalidade_empreendimento", "ano_cadastral"))
colnames(balanced_panel_merged)
remove(balanced_panel, db_geracao_distribuida_collapsed)

# convert NA to zero
balanced_panel_merged[is.na(balanced_panel_merged)] <- 0

# variables of interest have to represent the cumulative sum over time
balanced_panel_merged <- balanced_panel_merged %>%
  group_by(cod_ibge, dsc_fonte_geracao, sig_modalidade_empreendimento) %>%
  dplyr::mutate(
    mda_potencia_instalada_kw_comercial = cumsum(mda_potencia_instalada_kw_comercial),
    mda_potencia_instalada_kw_residencial = cumsum(mda_potencia_instalada_kw_residencial),
    mda_potencia_instalada_kw_industrial = cumsum(mda_potencia_instalada_kw_industrial),
    mda_potencia_instalada_kw_rural = cumsum(mda_potencia_instalada_kw_rural),
    mda_potencia_instalada_kw_poder_publico = cumsum(mda_potencia_instalada_kw_poder_publico),
    mda_potencia_instalada_kw_servico_publico = cumsum(mda_potencia_instalada_kw_servico_publico),
    mda_potencia_instalada_kw_iluminacao_publica = cumsum(mda_potencia_instalada_kw_iluminacao_publica),
    qtd_uc_recebe_credito_comercial = cumsum(qtd_uc_recebe_credito_comercial),
    qtd_uc_recebe_credito_residencial = cumsum(qtd_uc_recebe_credito_residencial),
    qtd_uc_recebe_credito_industrial = cumsum(qtd_uc_recebe_credito_industrial),
    qtd_uc_recebe_credito_rural = cumsum(qtd_uc_recebe_credito_rural),
    qtd_uc_recebe_credito_poder_publico = cumsum(qtd_uc_recebe_credito_poder_publico),
    qtd_uc_recebe_credito_servico_publico = cumsum(qtd_uc_recebe_credito_servico_publico),
    qtd_uc_recebe_credito_iluminacao_publica = cumsum(qtd_uc_recebe_credito_iluminacao_publica)
  )

# relabel variables
balanced_panel_merged$sig_modalidade_empreendimento[balanced_panel_merged$sig_modalidade_empreendimento == "P"] <- "Microgeração"
balanced_panel_merged$sig_modalidade_empreendimento[balanced_panel_merged$sig_modalidade_empreendimento == "R"] <- "Autoconsumo "
balanced_panel_merged$sig_modalidade_empreendimento[balanced_panel_merged$sig_modalidade_empreendimento == "C"] <- "Compartilhada"
balanced_panel_merged$sig_modalidade_empreendimento[balanced_panel_merged$sig_modalidade_empreendimento == "M"] <- "Múltiplas"

# save at rds format
saveRDS(balanced_panel_merged,
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

temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_comercial"] <- "Potência Instalada - Comercial"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_residencial"] <- "Potência Instalada - Residencial"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_industrial"] <- "Potência Instalada - Industrial"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_rural"] <- "Potência Instalada - Rural"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_poder_publico"] <- "Potência Instalada - Poder Público"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_servico_publico"] <- "Potência Instalada - Serviço Público"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_iluminacao_publica"] <- "Potência Instalada - Iluminação pública"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_comercial"] <- "Qtd. de  Unidades - Comercial"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_residencial"] <- "Qtd. de  Unidades - Residencial"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_industrial"] <- "Qtd. de  Unidades - Industrial"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_rural"] <- "Qtd. de  Unidades - Rural"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_poder_publico"] <- "Qtd. de  Unidades - Poder Público"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_servico_publico"] <- "Qtd. de  Unidades - Serviço Público"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_iluminacao_publica pública"] <- "Qtd. de  Unidades - Iluminação pública"
temp_param_table$label[temp_param_table$var == "ano_cadastral"] <- "Ano"


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

# allow variables in graphs slider
temp_param_table$slider[temp_param_table$var == "ano_cadastral"] <- TRUE

# allow variables geometry in maps
temp_param_table$geometry[temp_param_table$var == "geometry"] <- TRUE

# save csv in utf-8 encoding
write.csv(temp_param_table,
  file = "data/aneel_geracao_distribuida_dic.csv",
  fileEncoding = "UTF-8"
)
