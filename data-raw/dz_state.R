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
class(dz_state$ano) <- 'numeric'
dz_state$ano <- as.Date(as.yearqtr(dz_state$ano), format = "%Y")

# colnames(dz_state)
lala <- colnames(dz_state)
dz_state <- dz_state %>% select(all_of(lala))
dz_state$estado <- dz_state$group

# edit final data
class(dz_state)
colnames(dz_state)

# remove unnecessary columns
dz_state <- subset( dz_state, select = -c(time, time_x, time_y, time_y_y, time_x_x) )

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

# Add Map data
### (NAO SALVEI POR CIMA DO DZ_STATE PARA NAO QUEBRAR VIZ ANTERIORES)
states_geo <- geobr::read_state(simplified = FALSE) %>% 
  select(estado = abbrev_state, geom)

dz_state <- left_join(dz_state, states_geo)
st_geometry(dz_state) <- dz_state$geom

# save simplified sf for faster maps
dz_state_simp <- rmapshaper::ms_simplify(dz_state, keep_shapes = TRUE)
saveRDS(dz_state_simp,
        file = "./data/dz_state_simplified.rds"
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

aux= c(rep(c('Producao da Aquicultura ', 'Valor da produção '),25))
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
  source = c(rep("Geral",3), rep("IBGE - PPM - Efetivo dos rebanhos",10), rep("IBGE - PPM - Origem animal",13), rep("IBGE - PPM - Criação de ovelhas",1), rep("IBGE - PPM - Criação de vacas",1), rep("IBGE - PPM - Aquicultura",48)),
  unidade = "Unidade de medida",
  categoria= c(rep("Geral",3), rep("Produção",73)), # c("Localização", "Unidade de Tempo", rep("Pecuaria",10)), 
  subcategoria = c(rep("Geral",3), rep("Criação animal",73))
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
temp_param_table$label[temp_param_table$var== "alevinos_producao_da_aquicultura"] <- "Produção da Aquicultura Alevinos"
temp_param_table$label[temp_param_table$var== "alevinos_valor_da_producao"] <- "Valor da produção Alevinos"
temp_param_table$label[temp_param_table$var== "camarao_producao_da_aquicultura"] <- "Produção da Aquicultura Camarao"
temp_param_table$label[temp_param_table$var== "camarao_valor_da_producao"] <- "Valor da produção Camarao"
temp_param_table$label[temp_param_table$var== "carpa_producao_da_aquicultura"] <- "Produção da Aquicultura Carpa"
temp_param_table$label[temp_param_table$var== "carpa_valor_da_producao"] <- "Valor da produção Carpa"
temp_param_table$label[temp_param_table$var== "curimata_curimbata_producao_da_aquicultura"] <- "Produção da Aquicultura Curimata, curimbata"
temp_param_table$label[temp_param_table$var== "curimata_curimbata_valor_da_producao"] <- "Valor da produção Curimata, curimbata"
temp_param_table$label[temp_param_table$var== "dourado_producao_da_aquicultura"] <- "Produção da Aquicultura Dourado"
temp_param_table$label[temp_param_table$var== "dourado_valor_da_producao"] <- "Valor da produção Dourado"
temp_param_table$label[temp_param_table$var== "jatuarana_piabanha_e_piracanjuba_producao_da_aquicultura"] <- "Produção da Aquicultura Jatuarana, piabanha e piracanjuba"
temp_param_table$label[temp_param_table$var== "jatuarana_piabanha_e_piracanjuba_valor_da_producao"] <- "Valor da produção Jatuarana, piabanha e piracanjuba"
temp_param_table$label[temp_param_table$var== "lambari_producao_da_aquicultura"] <- "Produção da Aquicultura Lambari"
temp_param_table$label[temp_param_table$var== "lambari_valor_da_producao"] <- "Valor da produção Lambari"
temp_param_table$label[temp_param_table$var== "larvas_e_pos_larvas_de_camarao_producao_da_aquicultura"] <- "Produção da Aquicultura Larvas e pos-larvas de camarao"
temp_param_table$label[temp_param_table$var== "larvas_e_pos_larvas_de_camarao_valor_da_producao"] <- "Valor da produção Larvas e pos-larvas de camarao"
temp_param_table$label[temp_param_table$var== "matrinxa_producao_da_aquicultura"] <- "Produção da Aquicultura Matrinxa"
temp_param_table$label[temp_param_table$var== "matrinxa_valor_da_producao"] <- "Valor da produção Matrinxa"
temp_param_table$label[temp_param_table$var== "ostras_vieiras_e_mexilhoes_producao_da_aquicultura"] <- "Produção da Aquicultura Ostras, vieiras e mexilhoes"
temp_param_table$label[temp_param_table$var== "ostras_vieiras_e_mexilhoes_valor_da_producao"] <- "Valor da produção Ostras, vieiras e mexilhoes"
temp_param_table$label[temp_param_table$var== "outros_peixes_producao_da_aquicultura"] <- "Produção da Aquicultura Outros peixes"
temp_param_table$label[temp_param_table$var== "outros_peixes_valor_da_producao"] <- "Valor da produção Outros peixes"
temp_param_table$label[temp_param_table$var== "outros_produtos_ra_jacare_siri_caranguejo_lagosta_etc_valor_da_producao"] <- "Valor da produção Outros produtos (ra, jacare, siri, caranguejo, lagosta, etc)"
temp_param_table$label[temp_param_table$var== "pacu_e_patinga_producao_da_aquicultura"] <- "Produção da Aquicultura Pacu e patinga"
temp_param_table$label[temp_param_table$var== "pacu_e_patinga_valor_da_producao"] <- "Valor da produção Pacu e patinga"
temp_param_table$label[temp_param_table$var== "piau_piapara_piaucu_piava_producao_da_aquicultura"] <- "Produção da Aquicultura Piau, piapara, piaucu, piava"
temp_param_table$label[temp_param_table$var== "piau_piapara_piaucu_piava_valor_da_producao"] <- "Valor da produção Piau, piapara, piaucu, piava"
temp_param_table$label[temp_param_table$var== "pintado_cachara_cachapira_e_pintachara_surubim_producao_da_aquicultura"] <- "Produção da Aquicultura Pintado, cachara, cachapira e pintachara, surubim"
temp_param_table$label[temp_param_table$var== "pintado_cachara_cachapira_e_pintachara_surubim_valor_da_producao"] <- "Valor da produção Pintado, cachara, cachapira e pintachara, surubim"
temp_param_table$label[temp_param_table$var== "pirapitinga_producao_da_aquicultura"] <- "Produção da Aquicultura Pirapitinga"
temp_param_table$label[temp_param_table$var== "pirapitinga_valor_da_producao"] <- "Valor da produção Pirapitinga"
temp_param_table$label[temp_param_table$var== "pirarucu_producao_da_aquicultura"] <- "Produção da Aquicultura Pirarucu"
temp_param_table$label[temp_param_table$var== "pirarucu_valor_da_producao"] <- "Valor da produção Pirarucu"
temp_param_table$label[temp_param_table$var== "sementes_de_moluscos_producao_da_aquicultura"] <- "Produção da Aquicultura Sementes de moluscos"
temp_param_table$label[temp_param_table$var== "sementes_de_moluscos_valor_da_producao"] <- "Valor da produção Sementes de moluscos"
temp_param_table$label[temp_param_table$var== "tambacu_tambatinga_producao_da_aquicultura"] <- "Produção da Aquicultura Tambacu, tambatinga"
temp_param_table$label[temp_param_table$var== "tambacu_tambatinga_valor_da_producao"] <- "Valor da produção Tambacu, tambatinga"
temp_param_table$label[temp_param_table$var== "tambaqui_producao_da_aquicultura"] <- "Produção da Aquicultura Tambaqui"
temp_param_table$label[temp_param_table$var== "tambaqui_valor_da_producao"] <- "Valor da produção Tambaqui"
temp_param_table$label[temp_param_table$var== "tilapia_producao_da_aquicultura"] <- "Produção da Aquicultura Tilapia"
temp_param_table$label[temp_param_table$var== "tilapia_valor_da_producao"] <- "Valor da produção Tilapia"
temp_param_table$label[temp_param_table$var== "total_valor_da_producao"] <- "Produção da Aquicultura Total"
temp_param_table$label[temp_param_table$var== "traira_e_trairao_producao_da_aquicultura"] <- "Valor da produção Traira e trairao"
temp_param_table$label[temp_param_table$var== "traira_e_trairao_valor_da_producao"] <- "Produção da Aquicultura Traira e trairao"
temp_param_table$label[temp_param_table$var== "truta_producao_da_aquicultura"] <- "Produção da Aquicultura Truta"
temp_param_table$label[temp_param_table$var== "truta_valor_da_producao"] <- "Valor da produção Truta"
temp_param_table$label[temp_param_table$var== "tucunare_producao_da_aquicultura"] <- "Produção da Aquicultura Tucunare"
temp_param_table$label[temp_param_table$var== "tucunare_valor_da_producao"] <- "Valor da produção Tucunare"

#Defining measurement units
temp_param_table$unidade[temp_param_table$var== "bovino_efetivo_dos_rebanhos"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "bubalino_efetivo_dos_rebanhos"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "equino_efetivo_dos_rebanhos"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "suino_total_efetivo_dos_rebanhos"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "caprino_efetivo_dos_rebanhos"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "ovino_efetivo_dos_rebanhos"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "galinaceos_total_efetivo_dos_rebanhos"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "galinaceos_galinhas_efetivo_dos_rebanhos"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "codornas_efetivo_dos_rebanhos"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "suino_matrizes_de_suinos_efetivo_dos_rebanhos"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "valor_v0"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "quant_v2682"] <- "Mil Litros"
temp_param_table$unidade[temp_param_table$var== "valor_v2682"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "quant_v2683"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "valor_v2683"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "quant_v2684"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "valor_v2684"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "quant_v2685"] <- "Mil Dúzias"
temp_param_table$unidade[temp_param_table$var== "valor_v2685"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "quant_v2686"] <- "Mil Dúzias"
temp_param_table$unidade[temp_param_table$var== "valor_v2686"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "quant_v2687"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "valor_v2687"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "ovinos_tosquiados_nos_estabelecimentos_agropecuarios"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "vacas_ordenhadas"] <- "Cabeças"
temp_param_table$unidade[temp_param_table$var== "alevinos_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "alevinos_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "camarao_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "camarao_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "carpa_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "carpa_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "curimata_curimbata_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "curimata_curimbata_valor_da_producao"] <- "Mil Reais - Curimata, curimbata"
temp_param_table$unidade[temp_param_table$var== "dourado_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "dourado_valor_da_producao"] <- "Mil Reais - Golden Dorado"
temp_param_table$unidade[temp_param_table$var== "jatuarana_piabanha_e_piracanjuba_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "jatuarana_piabanha_e_piracanjuba_valor_da_producao"] <- "Mil Reais - Jatuarana, piabanha e piracanjuba"
temp_param_table$unidade[temp_param_table$var== "lambari_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "lambari_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "larvas_e_pos_larvas_de_camarao_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "larvas_e_pos_larvas_de_camarao_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "matrinxa_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "matrinxa_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "ostras_vieiras_e_mexilhoes_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "ostras_vieiras_e_mexilhoes_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "outros_peixes_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "outros_peixes_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "outros_produtos_ra_jacare_siri_caranguejo_lagosta_etc_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "pacu_e_patinga_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "pacu_e_patinga_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "piau_piapara_piaucu_piava_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "piau_piapara_piaucu_piava_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "pintado_cachara_cachapira_e_pintachara_surubim_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "pintado_cachara_cachapira_e_pintachara_surubim_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "pirapitinga_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "pirapitinga_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "pirarucu_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "pirarucu_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "sementes_de_moluscos_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "sementes_de_moluscos_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "tambacu_tambatinga_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "tambacu_tambatinga_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "tambaqui_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "tambaqui_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "tilapia_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "tilapia_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "total_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "traira_e_trairao_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "traira_e_trairao_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "truta_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "truta_valor_da_producao"] <- "Mil Reais"
temp_param_table$unidade[temp_param_table$var== "tucunare_producao_da_aquicultura"] <- "Quilogramas"
temp_param_table$unidade[temp_param_table$var== "tucunare_valor_da_producao"] <- "Mil Reais"

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var== "estado"] <- FALSE
temp_param_table$y[temp_param_table$var== "ano"] <- FALSE
temp_param_table$y[temp_param_table$var== "group"] <- FALSE

# block and variables in graphs x-axis
temp_param_table$x[temp_param_table$var== "estado"] <- FALSE
temp_param_table$x[temp_param_table$var== "group"] <- FALSE

# allow variables in graphs size, color, and slider-axis 
temp_param_table$slider[temp_param_table$var== "ano"]  <- TRUE

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_state_dic.csv", fileEncoding = "UTF-8")


# relabel in english ----------------------------------------------------------------
temp_param_table$label[temp_param_table$var== "estado"] <- "State"
temp_param_table$label[temp_param_table$var== "ano"] <- "Year"
temp_param_table$label[temp_param_table$var== "bovino_efetivo_dos_rebanhos"] <- "Cattle herds"
temp_param_table$label[temp_param_table$var== "bubalino_efetivo_dos_rebanhos"] <- "Buffalo herds"
temp_param_table$label[temp_param_table$var== "equino_efetivo_dos_rebanhos"] <- "Horse herds"
temp_param_table$label[temp_param_table$var== "suino_total_efetivo_dos_rebanhos"] <- "Swine herds - Total"
temp_param_table$label[temp_param_table$var== "caprino_efetivo_dos_rebanhos"] <- "Goat herds"
temp_param_table$label[temp_param_table$var== "ovino_efetivo_dos_rebanhos"] <- "Sheep herds"
temp_param_table$label[temp_param_table$var== "galinaceos_total_efetivo_dos_rebanhos"] <- "Gallinaceous - Total"
temp_param_table$label[temp_param_table$var== "galinaceos_galinhas_efetivo_dos_rebanhos"] <- "Gallinaceous - Chicken"
temp_param_table$label[temp_param_table$var== "codornas_efetivo_dos_rebanhos"] <- "Quail herds"
temp_param_table$label[temp_param_table$var== "suino_matrizes_de_suinos_efetivo_dos_rebanhos"] <- "Swine herds - Swine Matrices"
temp_param_table$label[temp_param_table$var== "valor_v0"] <- "Total Value"
temp_param_table$label[temp_param_table$var== "quant_v2682"] <- "Quantity - Milk"
temp_param_table$label[temp_param_table$var== "valor_v2682"] <- "Value - Milk"
temp_param_table$label[temp_param_table$var== "quant_v2683"] <- "Quantity - Silkworm cocoons"
temp_param_table$label[temp_param_table$var== "valor_v2683"] <- "Value - Silkworm cocoons"
temp_param_table$label[temp_param_table$var== "quant_v2684"] <- "Quantity - Wool"
temp_param_table$label[temp_param_table$var== "valor_v2684"] <- "Value - Wool"
temp_param_table$label[temp_param_table$var== "quant_v2685"] <- "Quantity - Chicken eggs"
temp_param_table$label[temp_param_table$var== "valor_v2685"] <- "Value - Chicken eggs"
temp_param_table$label[temp_param_table$var== "quant_v2686"] <- "Quantity - Quail eggs"
temp_param_table$label[temp_param_table$var== "valor_v2686"] <- "Value - Quail eggs"
temp_param_table$label[temp_param_table$var== "quant_v2687"] <- "Quantity - Bee's honey"
temp_param_table$label[temp_param_table$var== "valor_v2687"] <- "Value - Bee's honey"
temp_param_table$label[temp_param_table$var== "ovinos_tosquiados_nos_estabelecimentos_agropecuarios"] <- "Shorn sheep"
temp_param_table$label[temp_param_table$var== "vacas_ordenhadas"] <- "Cows milked"
temp_param_table$label[temp_param_table$var== "alevinos_producao_da_aquicultura"] <- "Aquaculture Production - Fingerling"
temp_param_table$label[temp_param_table$var== "alevinos_valor_da_producao"] <- "Value - Fingerling"
temp_param_table$label[temp_param_table$var== "camarao_producao_da_aquicultura"] <- "Aquaculture Production - Shrimp"
temp_param_table$label[temp_param_table$var== "camarao_valor_da_producao"] <- "Value - Shrimp"
temp_param_table$label[temp_param_table$var== "carpa_producao_da_aquicultura"] <- "Aquaculture Production - Carp"
temp_param_table$label[temp_param_table$var== "carpa_valor_da_producao"] <- "Value - Carp"
temp_param_table$label[temp_param_table$var== "curimata_curimbata_producao_da_aquicultura"] <- "Aquaculture Production - Curimata, curimbata"
temp_param_table$label[temp_param_table$var== "curimata_curimbata_valor_da_producao"] <- "Value - Curimata, curimbata"
temp_param_table$label[temp_param_table$var== "dourado_producao_da_aquicultura"] <- "Aquaculture Production - Golden Dorado"
temp_param_table$label[temp_param_table$var== "dourado_valor_da_producao"] <- "Value - Golden Dorado"
temp_param_table$label[temp_param_table$var== "jatuarana_piabanha_e_piracanjuba_producao_da_aquicultura"] <- "Aquaculture Production - Jatuarana, piabanha e piracanjuba"
temp_param_table$label[temp_param_table$var== "jatuarana_piabanha_e_piracanjuba_valor_da_producao"] <- "Value - Jatuarana, piabanha e piracanjuba"
temp_param_table$label[temp_param_table$var== "lambari_producao_da_aquicultura"] <- "Aquaculture Production - Lambari"
temp_param_table$label[temp_param_table$var== "lambari_valor_da_producao"] <- "Value - Lambari"
temp_param_table$label[temp_param_table$var== "larvas_e_pos_larvas_de_camarao_producao_da_aquicultura"] <- "Aquaculture Production - Shrimp larvae and post-larvae"
temp_param_table$label[temp_param_table$var== "larvas_e_pos_larvas_de_camarao_valor_da_producao"] <- "Value - Shrimp larvae and post-larvae"
temp_param_table$label[temp_param_table$var== "matrinxa_producao_da_aquicultura"] <- "Aquaculture Production - Matrinxa"
temp_param_table$label[temp_param_table$var== "matrinxa_valor_da_producao"] <- "Value - Matrinxa"
temp_param_table$label[temp_param_table$var== "ostras_vieiras_e_mexilhoes_producao_da_aquicultura"] <- "Aquaculture Production - Oysters, scallops and mussels"
temp_param_table$label[temp_param_table$var== "ostras_vieiras_e_mexilhoes_valor_da_producao"] <- "Value - Oysters, scallops and mussels"
temp_param_table$label[temp_param_table$var== "outros_peixes_producao_da_aquicultura"] <- "Aquaculture Production - Other fish"
temp_param_table$label[temp_param_table$var== "outros_peixes_valor_da_producao"] <- "Value - Other fish"
temp_param_table$label[temp_param_table$var== "outros_produtos_ra_jacare_siri_caranguejo_lagosta_etc_valor_da_producao"] <- "Value - Other products (frog, alligator, crab, lobster, etc)"
temp_param_table$label[temp_param_table$var== "pacu_e_patinga_producao_da_aquicultura"] <- "Aquaculture Production - Pacu and patinga"
temp_param_table$label[temp_param_table$var== "pacu_e_patinga_valor_da_producao"] <- "Value - Pacu and patinga"
temp_param_table$label[temp_param_table$var== "piau_piapara_piaucu_piava_producao_da_aquicultura"] <- "Aquaculture Production - Piau, piapara, piaucu, piava"
temp_param_table$label[temp_param_table$var== "piau_piapara_piaucu_piava_valor_da_producao"] <- "Value - Piau, piapara, piaucu, piava"
temp_param_table$label[temp_param_table$var== "pintado_cachara_cachapira_e_pintachara_surubim_producao_da_aquicultura"] <- "Aquaculture Production - Pintado, cachara, cachapira and pintachara, surubim"
temp_param_table$label[temp_param_table$var== "pintado_cachara_cachapira_e_pintachara_surubim_valor_da_producao"] <- "Value - Pintado, cachara, cachapira and pintachara, surubim"
temp_param_table$label[temp_param_table$var== "pirapitinga_producao_da_aquicultura"] <- "Aquaculture Production - Pirapitinga"
temp_param_table$label[temp_param_table$var== "pirapitinga_valor_da_producao"] <- "Value - Pirapitinga"
temp_param_table$label[temp_param_table$var== "pirarucu_producao_da_aquicultura"] <- "Aquaculture Production - Pirarucu"
temp_param_table$label[temp_param_table$var== "pirarucu_valor_da_producao"] <- "Value - Pirarucu"
temp_param_table$label[temp_param_table$var== "sementes_de_moluscos_producao_da_aquicultura"] <- "Aquaculture Production - Shellfish seed"
temp_param_table$label[temp_param_table$var== "sementes_de_moluscos_valor_da_producao"] <- "Value - Shellfish seed"
temp_param_table$label[temp_param_table$var== "tambacu_tambatinga_producao_da_aquicultura"] <- "Aquaculture Production - Tambacu, tambatinga"
temp_param_table$label[temp_param_table$var== "tambacu_tambatinga_valor_da_producao"] <- "Aquaculture Production - Tambacu, tambatinga"
temp_param_table$label[temp_param_table$var== "tambaqui_producao_da_aquicultura"] <- "Aquaculture Production - Tambaqui"
temp_param_table$label[temp_param_table$var== "tambaqui_valor_da_producao"] <- "Aquaculture Production - Tambaqui"
temp_param_table$label[temp_param_table$var== "tilapia_producao_da_aquicultura"] <- "Aquaculture Production - Tilapia"
temp_param_table$label[temp_param_table$var== "tilapia_valor_da_producao"] <- "Value - Tilapia"
temp_param_table$label[temp_param_table$var== "total_valor_da_producao"] <- "Total Aquaculture Production"
temp_param_table$label[temp_param_table$var== "traira_e_trairao_producao_da_aquicultura"] <- "Aquaculture Production - Traira e trairao"
temp_param_table$label[temp_param_table$var== "traira_e_trairao_valor_da_producao"] <- "Value - Traira e trairao"
temp_param_table$label[temp_param_table$var== "truta_producao_da_aquicultura"] <- "Aquaculture Production - Trout"
temp_param_table$label[temp_param_table$var== "truta_valor_da_producao"] <- "Value - Trout"
temp_param_table$label[temp_param_table$var== "tucunare_producao_da_aquicultura"] <- "Aquaculture Production - Tucunare"
temp_param_table$label[temp_param_table$var== "tucunare_valor_da_producao"] <- "Value - Tucunare"

#Define measurement units
temp_param_table$unidade[temp_param_table$var== "bovino_efetivo_dos_rebanhos"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "bubalino_efetivo_dos_rebanhos"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "equino_efetivo_dos_rebanhos"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "suino_total_efetivo_dos_rebanhos"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "caprino_efetivo_dos_rebanhos"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "ovino_efetivo_dos_rebanhos"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "galinaceos_total_efetivo_dos_rebanhos"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "galinaceos_galinhas_efetivo_dos_rebanhos"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "codornas_efetivo_dos_rebanhos"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "suino_matrizes_de_suinos_efetivo_dos_rebanhos"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "valor_v0"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "quant_v2682"] <- "Thousand Liters"
temp_param_table$unidade[temp_param_table$var== "valor_v2682"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "quant_v2683"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "valor_v2683"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "quant_v2684"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "valor_v2684"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "quant_v2685"] <- "Thousand Dozens"
temp_param_table$unidade[temp_param_table$var== "valor_v2685"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "quant_v2686"] <- "Thousand Dozens"
temp_param_table$unidade[temp_param_table$var== "valor_v2686"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "quant_v2687"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "valor_v2687"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "ovinos_tosquiados_nos_estabelecimentos_agropecuarios"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "vacas_ordenhadas"] <- "Livestock"
temp_param_table$unidade[temp_param_table$var== "alevinos_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "alevinos_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "camarao_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "camarao_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "carpa_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "carpa_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "curimata_curimbata_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "curimata_curimbata_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "dourado_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "dourado_valor_da_producao"] <- "Thousand 'Reais' - Golden Dorado"
temp_param_table$unidade[temp_param_table$var== "jatuarana_piabanha_e_piracanjuba_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "jatuarana_piabanha_e_piracanjuba_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "lambari_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "lambari_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "larvas_e_pos_larvas_de_camarao_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "larvas_e_pos_larvas_de_camarao_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "matrinxa_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "matrinxa_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "ostras_vieiras_e_mexilhoes_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "ostras_vieiras_e_mexilhoes_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "outros_peixes_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "outros_peixes_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "outros_produtos_ra_jacare_siri_caranguejo_lagosta_etc_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "pacu_e_patinga_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "pacu_e_patinga_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "piau_piapara_piaucu_piava_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "piau_piapara_piaucu_piava_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "pintado_cachara_cachapira_e_pintachara_surubim_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "pintado_cachara_cachapira_e_pintachara_surubim_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "pirapitinga_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "pirapitinga_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "pirarucu_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "pirarucu_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "sementes_de_moluscos_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "sementes_de_moluscos_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "tambacu_tambatinga_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "tambacu_tambatinga_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "tambaqui_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "tambaqui_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "tilapia_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "tilapia_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "total_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "traira_e_trairao_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "traira_e_trairao_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "truta_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "truta_valor_da_producao"] <- "Thousand 'Reais'"
temp_param_table$unidade[temp_param_table$var== "tucunare_producao_da_aquicultura"] <- "Kilograms"
temp_param_table$unidade[temp_param_table$var== "tucunare_valor_da_producao"] <- "Thousand 'Reais'"


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/dz_state_dic_en.csv", fileEncoding = "UTF-8")