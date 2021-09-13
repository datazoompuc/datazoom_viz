############################################################
#### Generate rds data in the folder ./data/ 
############################################################

#### Call library
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
# PPM ppm_state_livestock_inventory
###################
ppm_state_livestock_inventory <- readRDS(file = "data/ppm_state_livestock_inventory.rds")

ppm_state_livestock_inventory$ano <- ppm_state_livestock_inventory$time
ppm_state_livestock_inventory <- ppm_state_livestock_inventory %>% 
  janitor::clean_names() 

###################
# PPM ppm_state_animal_origin_production
###################
ppm_state_animal_origin_production <- readRDS(file = "data/ppm_state_animal_origin_production.rds")

ppm_state_animal_origin_production$ano <- ppm_state_animal_origin_production$time
ppm_state_animal_origin_production <- ppm_state_animal_origin_production %>% 
  janitor::clean_names() 


###################
# PPM ppm_state_sheep_farming
###################
ppm_state_sheep_farming <- readRDS(file = "data/ppm_state_sheep_farming.rds")

ppm_state_sheep_farming$ano <- ppm_state_sheep_farming$time
ppm_state_sheep_farming <- ppm_state_sheep_farming %>% 
  janitor::clean_names() 

###################
# PPM ppm_state_cow_farming
###################
ppm_state_cow_farming <- readRDS(file = "data/ppm_state_cow_farming.rds")

ppm_state_cow_farming$ano <- ppm_state_cow_farming$time
ppm_state_cow_farming <- ppm_state_cow_farming %>% 
  janitor::clean_names() 

###################
# PPM ppm_state_aquaculture
###################
ppm_state_aquaculture <- readRDS(file = "data/ppm_state_aquaculture.rds")

ppm_state_aquaculture$ano <- ppm_state_aquaculture$time
ppm_state_aquaculture <- ppm_state_aquaculture %>% 
  janitor::clean_names() 

###########################
# edit data to merge
###########################
#class(ppm_state_sheep_farming$group) <-  'character'

###########################
# merge all data
###########################
dz_state <- ppm_state_livestock_inventory %>%
  full_join(ppm_state_animal_origin_production, by = c("group","ano"))   %>%
  full_join(ppm_state_sheep_farming, by = c("group","ano"))   %>%
  full_join(ppm_state_cow_farming, by = c("group","ano")) %>% 
  full_join(ppm_state_aquaculture, by = c("group","ano")) %>% 
  arrange(group, ano) %>%
  relocate(group, ano)

# clean column names
dz_state <- dz_state %>%
  janitor::clean_names()

# convert time data to date
dz_state$ano <- as.Date(as.yearqtr(dz_state$ano), format = "%Y")

# colnames(dz_state)
lala <- colnames(dz_state)
dz_state <- dz_state %>% select(all_of(lala))
dz_state$estado <- dz_state$group

# edit final data
class(dz_state)
colnames(dz_state)

# remove unnecessary columns
dz_state <- subset( dz_state, select = -c(time, time_x, group, time_y, time_y_y, time_x_x) )

# keep only uf from amazon
dz_state <- dz_state %>% dplyr::filter(estado == "AC" | estado == "AP" | estado == "AM" | estado == "PA" | estado == "MA" | estado == "RR" | estado == "RO" | estado == "MT" | estado == "TO") 
class(dz_state$estado)
dz_state$estado <- as.factor(dz_state$estado)

# unique rows
dz_state <- unique(dz_state, by = c(estado, ano))
dz_state <- dz_state %>% group_by(estado, ano)

# arrange data by municipality and year
dz_state <- dz_state %>%
  arrange(estado, ano) %>%
  relocate(estado, ano)

# Identify and remove duplicate data
dz_state <- dz_state %>% distinct(estado, ano, .keep_all = TRUE)

# save data
saveRDS(dz_state,
        file = "./data/dz_state.rds"
)

#####################
# Build Dictionary 
#####################

# call data
dz_state <- readRDS("./data/dz_state.rds")

# extract variables from data
columns <- colnames(dz_state)

#livestock_inventory
dic_ppm_livestock_inventory= load_dictionary(dataset = 'ppm_livestock_inventory')
aux= c(rep('Efetivo dos Rebanhos: ',11))
label_livestock = paste0(aux, c(dic_ppm_livestock_inventory$var_pt[1:11]))
# remove missing columns in dz_state
label_livestock[! label_livestock %in% c("Efetivo dos Rebanhos: Suino - Matrizes de Suinos")]

label_livestock <- subset(label_livestock, select = -c("Efetivo dos Rebanhos: Suino - Matrizes de Suinos") )



#animal_origin_production
dic_ppm_animal_origin_production= load_dictionary(dataset = 'ppm_animal_origin_production')%>%
  arrange(var_code)

vec= NULL
for(i in 2:7){
  vec= c(vec, rep(dic_ppm_animal_origin_production$var_pt[i],2))
} 
vec= c('',vec)
aux= c('Valor Total', rep(c('Quantidade ', 'Valor '),6))
label_animal_origin_production= paste0(aux,vec)

#sheep_farming 
dic_ppm_sheep_farming= load_dictionary(dataset = 'ppm_sheep_farming')
label_sheep_farming = c(dic_ppm_sheep_farming$var_pt[1:1])

#ppm_cow_farming 
dic_ppm_cow_farming= load_dictionary(dataset = 'ppm_cow_farming')
label_cow_farming = c(dic_ppm_cow_farming$var_pt[1:1])

#ppm_aquaculture
dic_ppm_aquaculture= load_dictionary(dataset = 'ppm_aquaculture')%>%
  dplyr::arrange(var_pt)
vec= NULL
for(i in 1:25){
  vec= c(vec, rep(dic_ppm_aquaculture$var_pt[i],2))
}

aux= c(rep(c('Producao da Aquicultura ', 'Valor da Producao '),25))
label_aquaculture= paste0(aux,vec)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns, # c(label_livestock, label_animal_origin_production, label_cow_farming, label_aquaculture)
  desc = columns,
  source = c(rep("Geral",2), rep("IBGE - PPM",73)),
  unidade = "Unidade de medida",
  categoria= c(rep("Geral",2), rep("Produção",73)), # c("Localização", "Unidade de Tempo", rep("Pecuaria",10)), 
  subcategoria = c(rep("Geral",2), rep("Criação animal",73))
)

# Label
temp_param_table$label[temp_param_table$var== "estado"] <- "Estado"
temp_param_table$label[temp_param_table$var== "ano"] <- "Ano"
temp_param_table$label[temp_param_table$var== "bovino_efetivo_dos_rebanhos"] <- "Efetivo dos Rebanhos: Bovino"
temp_param_table$label[temp_param_table$var== "bubalino_efetivo_dos_rebanhos"] <- "Efetivo dos Rebanhos: Bubalino"
temp_param_table$label[temp_param_table$var== "equino_efetivo_dos_rebanhos"] <- "Efetivo dos Rebanhos: Equino"
temp_param_table$label[temp_param_table$var== "suino_total_efetivo_dos_rebanhos"] <- "Efetivo dos Rebanhos: Suino - Total"
temp_param_table$label[temp_param_table$var== "caprino_efetivo_dos_rebanhos"] <- "Efetivo dos Rebanhos: Caprino"
temp_param_table$label[temp_param_table$var== "ovino_efetivo_dos_rebanhos"] <- "Efetivo dos Rebanhos: Ovino"
temp_param_table$label[temp_param_table$var== "galinaceos_total_efetivo_dos_rebanhos"] <- "Efetivo dos Rebanhos: Galinaceos - Total"
temp_param_table$label[temp_param_table$var== "galinaceos_galinhas_efetivo_dos_rebanhos"] <- "Efetivo dos Rebanhos: Galinaceos - Galinha"
temp_param_table$label[temp_param_table$var== "codornas_efetivo_dos_rebanhos"] <- "Efetivo dos Rebanhos: Codornas"
temp_param_table$label[temp_param_table$var== "suino_matrizes_de_suinos_efetivo_dos_rebanhos"] <- "Efetivo dos Rebanhos: Suino - Matrizes de Suinos"
temp_param_table$label[temp_param_table$var== "valor_v0"] <- "Valor Total"
temp_param_table$label[temp_param_table$var== "quant_v2682"] <- "Quantidade Leite"
temp_param_table$label[temp_param_table$var== "valor_v2682"] <- "Valor Leite"
temp_param_table$label[temp_param_table$var== "quant_v2683"] <- "Quantidade casulos do bicho-da-seda"
temp_param_table$label[temp_param_table$var== "valor_v2683"] <- "Valor casulos do bicho-da-seda"
temp_param_table$label[temp_param_table$var== "quant_v2684"] <- "Quantidade La"
temp_param_table$label[temp_param_table$var== "valor_v2684"] <- "Valor La"
temp_param_table$label[temp_param_table$var== "quant_v2685"] <- "Quantidade ovos de galinha"
temp_param_table$label[temp_param_table$var== "valor_v2685"] <- "Valor ovos de galinha"
temp_param_table$label[temp_param_table$var== "quant_v2686"] <- "Quantidade Ovos de codorna"
temp_param_table$label[temp_param_table$var== "valor_v2686"] <- "Valor Ovos de codorna"
temp_param_table$label[temp_param_table$var== "quant_v2687"] <- "Quantidade Mel de abelha"
temp_param_table$label[temp_param_table$var== "valor_v2687"] <- "Valor Mel de abelha"
temp_param_table$label[temp_param_table$var== "ovinos_tosquiados_nos_estabelecimentos_agropecuarios"] <- "Ovinos tosquiados"
temp_param_table$label[temp_param_table$var== "vacas_ordenhadas"] <- "Vacas ordenhadas"
temp_param_table$label[temp_param_table$var== "alevinos_producao_da_aquicultura"] <- "Producao da Aquicultura Alevinos"
temp_param_table$label[temp_param_table$var== "alevinos_valor_da_producao"] <- "Valor da Producao Alevinos"
temp_param_table$label[temp_param_table$var== "camarao_producao_da_aquicultura"] <- "Producao da Aquicultura Camarao"
temp_param_table$label[temp_param_table$var== "camarao_valor_da_producao"] <- "Valor da Producao Camarao"
temp_param_table$label[temp_param_table$var== "carpa_producao_da_aquicultura"] <- "Producao da Aquicultura Carpa"
temp_param_table$label[temp_param_table$var== "carpa_valor_da_producao"] <- "Valor da Producao Carpa"
temp_param_table$label[temp_param_table$var== "curimata_curimbata_producao_da_aquicultura"] <- "Producao da Aquicultura Curimata, curimbata"
temp_param_table$label[temp_param_table$var== "curimata_curimbata_valor_da_producao"] <- "Valor da Producao Curimata, curimbata"
temp_param_table$label[temp_param_table$var== "dourado_producao_da_aquicultura"] <- "Producao da Aquicultura Dourado"
temp_param_table$label[temp_param_table$var== "dourado_valor_da_producao"] <- "Valor da Producao Dourado"
temp_param_table$label[temp_param_table$var== "jatuarana_piabanha_e_piracanjuba_producao_da_aquicultura"] <- "Producao da Aquicultura Jatuarana, piabanha e piracanjuba"
temp_param_table$label[temp_param_table$var== "jatuarana_piabanha_e_piracanjuba_valor_da_producao"] <- "Valor da Producao Jatuarana, piabanha e piracanjuba"
temp_param_table$label[temp_param_table$var== "lambari_producao_da_aquicultura"] <- "Producao da Aquicultura Lambari"
temp_param_table$label[temp_param_table$var== "lambari_valor_da_producao"] <- "Valor da Producao Lambari"
temp_param_table$label[temp_param_table$var== "larvas_e_pos_larvas_de_camarao_producao_da_aquicultura"] <- "Producao da Aquicultura Larvas e pos-larvas de camarao"
temp_param_table$label[temp_param_table$var== "larvas_e_pos_larvas_de_camarao_valor_da_producao"] <- "Valor da Producao Larvas e pos-larvas de camarao"
temp_param_table$label[temp_param_table$var== "matrinxa_producao_da_aquicultura"] <- "Producao da Aquicultura Matrinxa"
temp_param_table$label[temp_param_table$var== "matrinxa_valor_da_producao"] <- "Valor da Producao Matrinxa"
temp_param_table$label[temp_param_table$var== "ostras_vieiras_e_mexilhoes_producao_da_aquicultura"] <- "Producao da Aquicultura Ostras, vieiras e mexilhoes"
temp_param_table$label[temp_param_table$var== "ostras_vieiras_e_mexilhoes_valor_da_producao"] <- "Valor da Producao Ostras, vieiras e mexilhoes"
temp_param_table$label[temp_param_table$var== "outros_peixes_producao_da_aquicultura"] <- "Producao da Aquicultura Outros peixes"
temp_param_table$label[temp_param_table$var== "outros_peixes_valor_da_producao"] <- "Valor da Producao Outros peixes"
temp_param_table$label[temp_param_table$var== "outros_produtos_ra_jacare_siri_caranguejo_lagosta_etc_valor_da_producao"] <- "Valor da Producao Outros produtos (ra, jacare, siri, caranguejo, lagosta, etc)"
temp_param_table$label[temp_param_table$var== "pacu_e_patinga_producao_da_aquicultura"] <- "Producao da Aquicultura Pacu e patinga"
temp_param_table$label[temp_param_table$var== "pacu_e_patinga_valor_da_producao"] <- "Valor da Producao Pacu e patinga"
temp_param_table$label[temp_param_table$var== "piau_piapara_piaucu_piava_producao_da_aquicultura"] <- "Producao da Aquicultura Piau, piapara, piaucu, piava"
temp_param_table$label[temp_param_table$var== "piau_piapara_piaucu_piava_valor_da_producao"] <- "Valor da Producao Piau, piapara, piaucu, piava"
temp_param_table$label[temp_param_table$var== "pintado_cachara_cachapira_e_pintachara_surubim_producao_da_aquicultura"] <- "Producao da Aquicultura Pintado, cachara, cachapira e pintachara, surubim"
temp_param_table$label[temp_param_table$var== "pintado_cachara_cachapira_e_pintachara_surubim_valor_da_producao"] <- "Valor da Producao Pintado, cachara, cachapira e pintachara, surubim"
temp_param_table$label[temp_param_table$var== "pirapitinga_producao_da_aquicultura"] <- "Producao da Aquicultura Pirapitinga"
temp_param_table$label[temp_param_table$var== "pirapitinga_valor_da_producao"] <- "Valor da Producao Pirapitinga"
temp_param_table$label[temp_param_table$var== "pirarucu_producao_da_aquicultura"] <- "Producao da Aquicultura Pirarucu"
temp_param_table$label[temp_param_table$var== "pirarucu_valor_da_producao"] <- "Valor da Producao Pirarucu"
temp_param_table$label[temp_param_table$var== "sementes_de_moluscos_producao_da_aquicultura"] <- "Producao da Aquicultura Sementes de moluscos"
temp_param_table$label[temp_param_table$var== "sementes_de_moluscos_valor_da_producao"] <- "Valor da Producao Sementes de moluscos"
temp_param_table$label[temp_param_table$var== "tambacu_tambatinga_producao_da_aquicultura"] <- "Producao da Aquicultura Tambacu, tambatinga"
temp_param_table$label[temp_param_table$var== "tambacu_tambatinga_valor_da_producao"] <- "Valor da Producao Tambacu, tambatinga"
temp_param_table$label[temp_param_table$var== "tambaqui_producao_da_aquicultura"] <- "Producao da Aquicultura Tambaqui"
temp_param_table$label[temp_param_table$var== "tambaqui_valor_da_producao"] <- "Valor da Producao Tambaqui"
temp_param_table$label[temp_param_table$var== "tilapia_producao_da_aquicultura"] <- "Producao da Aquicultura Tilapia"
temp_param_table$label[temp_param_table$var== "tilapia_valor_da_producao"] <- "Valor da Producao Tilapia"
temp_param_table$label[temp_param_table$var== "total_valor_da_producao"] <- "Producao da Aquicultura Total"
temp_param_table$label[temp_param_table$var== "traira_e_trairao_producao_da_aquicultura"] <- "Valor da Producao Total"
temp_param_table$label[temp_param_table$var== "traira_e_trairao_valor_da_producao"] <- "Producao da Aquicultura Traira e trairao"
temp_param_table$label[temp_param_table$var== "truta_producao_da_aquicultura"] <- "Producao da Aquicultura Truta"
temp_param_table$label[temp_param_table$var== "truta_valor_da_producao"] <- "Valor da Producao Truta"
temp_param_table$label[temp_param_table$var== "tucunare_producao_da_aquicultura"] <- "Producao da Aquicultura Tucunare"
temp_param_table$label[temp_param_table$var== "tucunare_valor_da_producao"] <- "Valor da Producao Tucunare"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_state_dic.csv", fileEncoding = "UTF-8")