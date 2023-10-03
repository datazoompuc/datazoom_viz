# packages ----------------------------------------------------------------

library(sf)
library(tidyverse)
library(geobr)
library(datazoom.amazonia)

# l <- load_mapbiomas(dataset = "mapbiomas_cover",
#                raw_data = F,
#                geo_level = "municipality",
#                cover_level = 4)

# loading data ----------------------------------------------------------------

#mapbiomas collection8
x <- readxl::read_xlsx("C:/Users/msses/Desktop/gado_pastagem/gado_pastagem/tabela_geral_mapbiomas_col8_biomas_municipios.xlsx",
                        sheet = 2)

# w <- readxl::read_xlsx("C:/Users/msses/Desktop/gado_pastagem/gado_pastagem/tabela_geral_mapbiomas_col8_biomas_municipios.xlsx",
#                         sheet = 5)
#municipalities
muni <- read_municipality(year = 2021)

#cattle data
cattle <- read.csv("C:/Users/msses/Downloads/censoagro.csv")



#tidying dta ----------------------------------------------------------------

cover <- x %>% ungroup
# trans <- w %>% ungroup


#selecting and filtering to relevant variables and turning data into long type
cover <- cover %>% 
  select(-feature_id, 
         -biome, 
         -level_1,
         -level_2,
         -level_3,
         -color,
         -category,
         -`biome [municipality]`,
         -state_acronym,
         -level_0,
         -class_id,
         -("1985":"2016"))

cover <- cover %>% 
  pivot_longer(cols = "2017":"2022",
               names_to = "year",
               values_to = "area")

#transition db

# trans <- trans %>% 
#   select(-feature_id,-biome,-state_acronym,
#          -("class_id_to":"to_level_3"),
#          -("to_color":"from_level_3"),
#          -("from_color":"2014-2015"))
# 
# trans <- trans %>% 
#   pivot_longer(cols = ("2015-2016":"2021-2022"),
#                names_to = "year",
#                values_to = "area_trans")

muni <- muni %>% 
  select(code_muni, abbrev_state) %>% 
  rename(geocode = code_muni) %>% 
  #filtering out fernando de noronha
  filter(geocode != 2605459)

#adding muni area variable
# filtering only pasture because of the analysis and creating a share variable
cover <- cover %>%
  ungroup() %>%
  group_by(year, geocode, municipality) %>% 
  mutate(muni_area = sum(area, na.rm = T)) %>%
  summarise(muni_area = first(muni_area),
            pasture_area = sum(if_else(level_4 == "Pasture", area, 0), na.rm = T)) %>% 
  mutate(share_past = pasture_area/muni_area) %>%
  ungroup()

# same thing for trans db

# trans <- trans %>% 
#   filter(from_level_4 == "Pasture") %>% 
#   filter(!is.na(area_trans)) %>% 
#   filter(to_level_4 %in% c("Urban Infrastructure",
#                            "Mining",
#                            "Other Non Vegetated Area",
#                            "Other Non Forest Natural Formation", 
#                            "Savanna Formation")) %>%
#   filter(to_level_4 == "Savanna Formation") %>% 
#   group_by(geocode,year,municipality) %>%
#   summarise(area_deg = sum(area_trans, na.rm = T), 
#             area_savana = sum(area_trans, na.rm = T)) %>%
#   ungroup()
# 
# trans <- trans %>% 
#   filter((year != "2015-2020") & (year !=  "2016-2022") & (year !=  "2018-2022")) %>%
#   mutate(year = substr(year, 1, 4)) %>% 
#   filter(year!=2015)

# joining cover e transition

# eeaao <- cover %>% 
#   left_join(trans) %>% 
#   mutate(area_deg = ifelse(is.na(area_deg),
#                            0,
#                            area_deg),
#          area_savana = ifelse(is.na(area_savana),
#                            0,
#                            area_savana))


# erro... dando shares pasto/savana e pasto/deg maiores do que 1 muitas vezes  talvez nao possa comparar
# dados de transicao com dados de land cover

#joining with muni to get geometry
cover <- muni %>% 
  left_join(cover)

#removing other dbs from environment
rm( x,muni)

# raw <- eeaao

# #join with cattle database
cattle <- cattle %>%
  slice(-(1:5))

cattle <- cattle %>% 
  rename(municipality = Tabela.6907...Número.de.estabelecimentos.agropecuários.com.efetivo.da.pecuária.e.Número.de.cabeças..por.tipologia..espécie.da.pecuária.e.condição.do.produtor.em.relação.às.terras) %>% 
  mutate(abbrev_state = str_sub(municipality, -3, -2),
         municipality = str_sub(municipality, 1, -6)) %>% 
  rename(cow = ...3) %>% 
  select(-...2) %>% 
  mutate(cow = ifelse(cow == "X",
                      NA,
                      ifelse(cow == "-",
                             NA,
                             cow)))

final <- cover %>% 
  ungroup() %>% 
  left_join(cattle)

final <- final %>% 
  rename(cod_ibge = geocode,
         ano = year)


data1 <- final %>% 
  select(-cow)

class(data1)

#saveRDS of the time series
saveRDS(data1, "C:/Users/msses/Documents/GitHub/datazoom_viz/data/mapbiomas8_cover_pasture.rds")


#create the RDS for the cross-section
data2 <- final %>% ungroup %>% 
  filter(ano == 2017)

#creating new variables

data2 <- data2 %>%
  mutate(cow = as.numeric(cow),
         stock_density = ifelse(pasture_area == 0, NA, cow/pasture_area),
         land_efficiency = ifelse(cow == 0, NA, pasture_area/cow))


saveRDS(data2, "C:/Users/msses/Documents/GitHub/datazoom_viz/data/mapbiomas8_cover_pastCattle.rds")

#criar o código para os dicionários
#dic data1 criado a mao


# dictionary --------------------------------------------------------------
# # extract variables from data
# temp_param_table <- read_csv("C:/Users/msses/Documents/GitHub/datazoom_viz/data/dz_munic_saude_dic.csv")
# 
# columns <- colnames(df)
# 
# temp_param_table <- temp_param_table %>%
#   filter(var %in% columns) %>%
#   mutate(unidade = case_when(
#     stringr::str_detect(var, "t_") ~ "Mortalidade por 100 mil habitantes",
#     stringr::str_detect(var, "n_") ~ "Leitos por 100 mil habitantes",
#     TRUE ~ unidade
#   ))
# 
# # save csv in utf-8 encoding
# write.csv(temp_param_table, file = "data/saude_mortalidade_dic.csv", fileEncoding = "UTF-8")
# 
# temp_param_table <- temp_param_table %>%
#   filter(var %in% columns) %>%
#   mutate(unidade = case_when(
#     stringr::str_detect(var, "t_") ~ "Mortality per 100,000 habitantes",
#     stringr::str_detect(var, "n_") ~ "Hospital beds per 100,000 habitantes",
#     TRUE ~ unidade
#   ))
# #renaming the variables to english 
# temp_param_table$label[temp_param_table$var == "cod_ibge"] <- "Municipality code"
# temp_param_table$label[temp_param_table$var == "ano"] <- "Year"
# temp_param_table$label[temp_param_table$var == "t_total"] <- "Gross mortality per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_causas_externas"] <- "Mortality due to external causes per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_cardiovascular"] <- "Mortality due to circulatory system diseases per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_respiratorio"] <- "Mortality due to respiratory system diseases per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_infecciosas"] <- "Mortality due to some infectious and parasitic diseases per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_neoplasias"] <- "Mortality from neoplasms per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_cancer_mama"] <- "Mortality per malign breast neoplasm per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_cancer_colo_do_utero"] <- "Mortality from malign neoplasms of the uterine cervix per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_comunicaveis"] <- "Mortality due to communicable diseases per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_nao_comunicaveis"] <- "Mortality due to non-communicable diseases per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_diabetes"] <- "Mortality due to mellitus diabetes per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_malaria"] <- "Malaria mortality per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_aids"] <- "Mortality due to HIV disease per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_autoprovocadas"] <- "Voluntary self-harm mortality per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_agressoes"] <- "Aggression Mortality per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_acidentes"] <- "Mortality due to accidents per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_transporte"] <- "Mortality due to transport accidents per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_pedestre"] <- "Pedestrian Mortality at transport accidents per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_motociclista"] <- "Motorcycle-Riders Mortality in transport accidents per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_ciclista"] <- "Bike-Riders Mortality in transport accidents per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_infanti"] <- "Child Mortality per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_maternal"] <- "Maternal Mortality per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_fetal"] <- "Fetus Mortality per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_sangue"] <- "Mortality due to blood diseases per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_endocrinas"] <- "Mortality due to endocrine, nutritional and metabolic diseases per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_mentais"] <- "Mortality due to mental and behavioral disorders per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_nervoso"] <- "Mortality due to nervous system diseases per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_olho"] <- "Mortality due to eye diseases and annexes per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_ouvido"] <- "Mortality due to ear and mastoid apophysis diseases per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_digestivo"] <- "Mortality due to gastrointestinal diseases per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_pele"] <- "Mortality due to skin diseases per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_osteomuscular"] <- "Mortality due to diseases of the musculoskeletal and connective tissue system per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_genitourinario"] <- "Mortality due to diseases of the genitourinary system per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_gravidez"] <- "Mortality from pregnancy, childbirth, or the puerperium per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_perinatal"] <- "Mortality due to some diseases originated in the perinatal period per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_malformacoes"] <- "Mortality due to congenital malformations, deformities and chromosomal anomalies per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "t_anormais"] <- "Mortality from symptoms, signs, and abnormal findings on clinical and laboratory examinations per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "n_leitos_existentes"] <- "Number of existing hospital beds per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "n_leitos_sus"] <- "Number of hospital beds available for SUS per 100,000 inhabitants"
# temp_param_table$label[temp_param_table$var == "n_leitos_nao_sus"] <- "Number of hospital beds unavailable for SUS per 100,000 inhabitants"
# 
# 
# 
# # save csv in utf-8 encoding
# write.csv(temp_param_table, file = "data/saude_mortalidade_dic_en.csv", fileEncoding = "UTF-8")
# 
# 
