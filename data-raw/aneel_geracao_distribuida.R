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
# URL do arquivo no portal de dados abertos da ANEEL (atualizado diariamente):
url_aneel <- "https://dadosabertos.aneel.gov.br/dataset/5e0fafd2-21b9-4d5b-b622-40438d40aba2/resource/b1bd71e7-d0ad-4214-9053-cbd58e9564a7/download/empreendimento-geracao-distribuida.csv"

temp_aneel <- tempfile(fileext = ".csv")
download.file(url_aneel, destfile = temp_aneel, mode = "wb", quiet = FALSE)

db_geracao_distribuida <- data.table::fread(
  file = temp_aneel,
  encoding = "Latin-1"
) %>%
  janitor::clean_names()

db_geracao_distribuida$cod_ibge <- db_geracao_distribuida$cod_municipio_ibge
db_geracao_distribuida$code_muni <- db_geracao_distribuida$cod_municipio_ibge

# keep with only amazon cities
amz_cities <- datazoom.amazonia::municipalities
db_geracao_distribuida <- left_join(db_geracao_distribuida, amz_cities, by = c("code_muni"))

#db_geracao_distribuida <- db_geracao_distribuida %>%
#  filter(legal_amazon ==1)

# trim whitespace em dsc_classe_consumo para evitar duplicatas como "REBR" vs "REBR "
db_geracao_distribuida$dsc_classe_consumo <- trimws(db_geracao_distribuida$dsc_classe_consumo)

# replace character "," to "."
db_geracao_distribuida$mda_potencia_instalada_kw <- gsub(",", ".", db_geracao_distribuida$mda_potencia_instalada_kw)
db_geracao_distribuida$qtd_uc_recebe_credito <- gsub(",", ".", db_geracao_distribuida$qtd_uc_recebe_credito)

# ensure variables are numeric
db_geracao_distribuida$mda_potencia_instalada_kw <- as.numeric(db_geracao_distribuida$mda_potencia_instalada_kw)
db_geracao_distribuida$qtd_uc_recebe_credito <- as.numeric(db_geracao_distribuida$qtd_uc_recebe_credito)

# generate variable of year
# usa AnmPeriodoReferencia ("MM/YYYY") quando disponível; fallback: DthAtualizaCadastralEmpreend
db_geracao_distribuida <- db_geracao_distribuida %>%
  mutate(
    ano_cadastral = as.integer(substr(anm_periodo_referencia, 4, 7)),
    ano_cadastral = if_else(
      is.na(ano_cadastral),
      year(as.Date(dth_atualiza_cadastral_empreend, "%d/%m/%Y")),
      ano_cadastral
    )
  )

db_geracao_distribuida$ano_cadastral <- as.numeric(db_geracao_distribuida$ano_cadastral)

# convert long data to wide data

## ## ## ## ## ## ## ## ## ## ## ## 
## Por: AMZ vs. Fora AMZ
## ## ## ## ## ## ## ## ## ## ## ## 

colnames(db_geracao_distribuida)

db_geracao_distribuida_amazon <- db_geracao_distribuida %>%
  mutate(id = case_when(legal_amazon ==1 ~ "Amazônia Legal",
                        legal_amazon !=1 ~ "Fora da Amazônia Legal"
  ) 
  )

db_geracao_distribuida_amazon$id[is.na(db_geracao_distribuida_amazon$id)] <- "Fora da Amazônia Legal"

db_geracao_distribuida_amazon <- pivot_wider(
  db_geracao_distribuida_amazon,
  id_cols = c(id, dsc_fonte_geracao, sig_modalidade_empreendimento, dsc_porte, ano_cadastral),
  id_expand = TRUE,
  names_from = c(dsc_classe_consumo),
  values_from = c(mda_potencia_instalada_kw, qtd_uc_recebe_credito),
  values_fn = sum
)  %>% janitor::clean_names()

# convert NA to zero
colnames(db_geracao_distribuida_amazon)
db_geracao_distribuida_amazon[is.na(db_geracao_distribuida_amazon)] <- 0

## ## ## ## ## ## ## ## ## ## ## ## 
## Por estados
## ## ## ## ## ## ## ## ## ## ## ## 
colnames(db_geracao_distribuida)
db_geracao_distribuida$code_state %>% unique() %>% sort()

db_geracao_distribuida_uf <- db_geracao_distribuida %>%
  mutate(id = case_when(code_state ==11 ~ "R. Norte: RO",
                        code_state ==12 ~ "R. Norte: AC",
                        code_state ==13 ~ "R. Norte: AM",
                        code_state ==14 ~ "R. Norte: RR",
                        code_state ==15 ~ "R. Norte: PA",
                        code_state ==16 ~ "R. Norte: AP",
                        code_state ==17 ~ "R. Norte: TO",
                        code_state ==21 ~ "R. Nordeste: MA",
                        code_state ==22 ~ "R. Nordeste: MA",
                        code_state ==23 ~ "R. Nordeste: CE",
                        code_state ==24 ~ "R. Nordeste: RN",
                        code_state ==25 ~ "R. Nordeste: PB",
                        code_state ==26 ~ "R. Nordeste: PE",
                        code_state ==27 ~ "R. Nordeste: AL",
                        code_state ==28 ~ "R. Nordeste: SE",
                        code_state ==29 ~ "R. Nordeste: BA",
                        code_state ==31 ~ "R. Sudeste: MG",
                        code_state ==32 ~ "R. Sudeste: ES",
                        code_state ==33 ~ "R. Sudeste: RJ",
                        code_state ==35 ~ "R. Sudeste: SP",
                        code_state ==41 ~ "R. Sul: PR",
                        code_state ==42 ~ "R. Sul: SC",
                        code_state ==43 ~ "R. Sul: RS",
                        code_state ==50 ~ "R. Centro-Oeste: MS",
                        code_state ==51 ~ "R. Centro-Oeste: MT",
                        code_state ==52 ~ "R. Centro-Oeste: GO",
                        code_state ==53 ~ "R. Centro-Oeste: DF"
                        )
         )

db_geracao_distribuida_uf$id[is.na(db_geracao_distribuida_uf$id)] <- ""

db_geracao_distribuida_uf <- pivot_wider(
  db_geracao_distribuida_uf,
  id_cols = c(id, dsc_fonte_geracao, sig_modalidade_empreendimento, dsc_porte, ano_cadastral),
  id_expand = TRUE,
  names_from = c(dsc_classe_consumo),
  values_from = c(mda_potencia_instalada_kw, qtd_uc_recebe_credito),
  values_fn = sum
) %>% janitor::clean_names()

# convert NA to zero
colnames(db_geracao_distribuida_uf)
db_geracao_distribuida_uf[is.na(db_geracao_distribuida_uf)] <- 0

# Append datasets into one
append_data <- rbind(db_geracao_distribuida_amazon, db_geracao_distribuida_uf)

# clean names
append_data <- append_data %>% janitor::clean_names()

# sort data
append_data <- append_data %>%
  arrange(id, dsc_fonte_geracao, sig_modalidade_empreendimento, dsc_porte, ano_cadastral)

# variables of interest have to represent the cumulative sum over time
append_data <- append_data %>%
  arrange(id, dsc_fonte_geracao, sig_modalidade_empreendimento, dsc_porte, ano_cadastral) %>%
  group_by(id, dsc_fonte_geracao, sig_modalidade_empreendimento, dsc_porte) %>%
  dplyr::mutate(
    across(starts_with("mda_potencia_instalada_kw_"), cumsum),
    across(starts_with("qtd_uc_recebe_credito_"), cumsum),
    mda_potencia_instalada_kw_total = rowSums(across(starts_with("mda_potencia_instalada_kw_")), na.rm = TRUE),
    qtd_uc_recebe_credito_total     = rowSums(across(starts_with("qtd_uc_recebe_credito_")),     na.rm = TRUE)
  ) 

# filter years above 2013
append_data$ano_cadastral %>% unique
#append_data <- append_data %>%
#  filter(ano_cadastral>=2013)
#append_data$ano_cadastral %>% unique  
  
# sort data
append_data <- append_data %>%
  arrange(id, dsc_fonte_geracao, sig_modalidade_empreendimento, dsc_porte, ano_cadastral)

# relabel variables
append_data$sig_modalidade_empreendimento %>% unique() %>% sort()
append_data$dsc_fonte_geracao %>% unique() %>% sort()
append_data$dsc_porte %>% unique() %>% sort()

append_data$sig_modalidade_empreendimento[append_data$sig_modalidade_empreendimento == "P"] <- "Microgera\u00e7\u00e3o ou Minigera\u00e7\u00e3o distribuída"
append_data$sig_modalidade_empreendimento[append_data$sig_modalidade_empreendimento == "R"] <- "Autoconsumo remoto"
append_data$sig_modalidade_empreendimento[append_data$sig_modalidade_empreendimento == "C"] <- "Geração compartilhada"
append_data$sig_modalidade_empreendimento[append_data$sig_modalidade_empreendimento == "M"] <- "Múltiplas unidades consumidoras"
append_data$sig_modalidade_empreendimento[append_data$sig_modalidade_empreendimento == ""] <- "Indefinido"

append_data$dsc_porte[append_data$dsc_porte == "Microgeracao"] <- "Microgera\u00e7\u00e3o"
append_data$dsc_porte[append_data$dsc_porte == "Minigeracao"] <- "Minigera\u00e7\u00e3o"
append_data$dsc_porte[append_data$dsc_porte == ""] <- "Outro"

# generate variables
append_data$group <- append_data$id

# save at rds format
saveRDS(append_data,
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
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_total"] <- "Total de Potência Instalada"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_consumo_proprio"] <- "Potência Instalada - Consumo Próprio"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_rebr"] <- "Potência Instalada - REBR"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_comercial"] <- "Qtd. de  Unidades - Comercial"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_residencial"] <- "Qtd. de  Unidades - Residencial"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_industrial"] <- "Qtd. de  Unidades - Industrial"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_rural"] <- "Qtd. de  Unidades - Rural"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_poder_publico"] <- "Qtd. de  Unidades - Poder Público"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_servico_publico"] <- "Qtd. de  Unidades - Serviço Público"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_iluminacao_publica"] <- "Qtd. de  Unidades - Iluminação pública"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_total"] <- "Total de Qtd. de  Unidades"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_consumo_proprio"] <- "Qtd. de  Unidades - Consumo Próprio"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_rebr"] <- "Qtd. de  Unidades - REBR"
temp_param_table$label[temp_param_table$var == "ano_cadastral"] <- "Ano"


# Unidade de medida
temp_param_table$unidade[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw", ignore_case = TRUE))] <- "kilowatt"

temp_param_table$unidade[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito", ignore_case = TRUE))] <- "Somatório de unidades consumidoras"

# var_group variables
temp_param_table$var_group[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw", ignore_case = TRUE))] <- "POTÊNCIA INSTALADA:"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito", ignore_case = TRUE))] <- "QUANTIDADE DE UNIDADES CONSUMIDORAS:"

# allow variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "ano_cadastral"] <- TRUE

# allow variables in graphs y-axis
temp_param_table$y[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito", ignore_case = TRUE))] <- TRUE
temp_param_table$y[str_detect(temp_param_table$var, regex("mda_potencia_instalada", ignore_case = TRUE))] <- TRUE

# allow variables in graphs slider
temp_param_table$slider[temp_param_table$var == "ano_cadastral"] <- TRUE

# save csv in utf-8 encoding
write.csv(temp_param_table,
  file = "data/aneel_geracao_distribuida_dic.csv",
  fileEncoding = "UTF-8"
)

# translate to english --------------------------------------------------------------
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_comercial"] <- "Installed Capacity - Commercial"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_residencial"] <- "Installed Capacity - Residential"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_industrial"] <- "Installed Capacity - Industrial"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_rural"] <- "Installed Capacity - Rural"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_poder_publico"] <- "Installed Capacity - Public Authority"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_servico_publico"] <- "Installed Capacity - Public Service"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_iluminacao_publica"] <- "Installed Capacity - Public Lighting"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_total"] <- "Total Installed Capacity"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_consumo_proprio"] <- "Installed Capacity - Own Consumption"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw_rebr"] <- "Installed Capacity - REBR"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_comercial"] <- "Number of Units - Commercial"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_residencial"] <- "Number of Units - Residential"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_industrial"] <- "Number of Units - Industrial"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_rural"] <- "Number of Units - Rural"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_poder_publico"] <- "Number of Units - Public Authority"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_servico_publico"] <- "Number of Units - Public Service"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_iluminacao_publica"] <- "Number of Units - Public Lighting"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_total"] <- "Total Number of Units"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_consumo_proprio"] <- "Number of Units - Own Consumption"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito_rebr"] <- "Number of Units - REBR"
temp_param_table$label[temp_param_table$var == "ano_cadastral"] <- "Year"


# Unidade de medida
temp_param_table$unidade[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw", ignore_case = TRUE))] <- "kilowatt"
temp_param_table$unidade[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito", ignore_case = TRUE))] <- "Sum of consumer units"

# var_group variables
temp_param_table$var_group[str_detect(temp_param_table$var, regex("mda_potencia_instalada_kw", ignore_case = TRUE))] <- "INSTALLED CAPACITY::"
temp_param_table$var_group[str_detect(temp_param_table$var, regex("qtd_uc_recebe_credito", ignore_case = TRUE))] <- "NUMBER OF CONSUMER UNITS:"


# save csv in utf-8 encoding
write.csv(temp_param_table,
          file = "./data/aneel_geracao_distribuida_dic_en.csv",
          fileEncoding = "UTF-8"

)

