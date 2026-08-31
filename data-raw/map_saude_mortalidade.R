# packages ----------------------------------------------------------------
library(tidyverse)
library(sf)
library(sp)


# load data ---------------------------------------------------------------
df <- read_rds("data/dz_munic_saude.rds") %>% 
  select(ano, cod_ibge, nm_municip, uf, starts_with("t_"), starts_with("n_"))

shapefile <- readRDS("global/munic_shapefile.rds") %>%
  filter(legal_amazon == 1) %>%
  rename(cod_ibge = municipality_code) %>%
  mutate(cod_ibge = as.numeric(cod_ibge))


# merge with shape --------------------------------------------------------
data <- shapefile %>%
  inner_join(df, by = "cod_ibge")

# export ------------------------------------------------------------------
saveRDS(data, "data/saude_mortalidade.rds")


# dictionary --------------------------------------------------------------
# extract variables from data
temp_param_table <- read_csv("data/dz_munic_saude_dic.csv")

columns <- colnames(df)

temp_param_table <- temp_param_table %>%
  filter(var %in% columns) %>%
  mutate(
    unidade = case_when(
      stringr::str_detect(var, "t_") ~ "por 100 mil habitantes",
      stringr::str_detect(var, "n_") ~ "por 100 mil habitantes",
      TRUE ~ unidade
    ),
    label = stringr::str_remove(label, " por 100 mil habitantes")
  )

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/saude_mortalidade_dic.csv", fileEncoding = "UTF-8")

temp_param_table <- temp_param_table %>%
    filter(var %in% columns) %>%
    mutate(unidade = case_when(
        stringr::str_detect(var, "t_") ~ "per 100,000 inhabitants",
        stringr::str_detect(var, "n_") ~ "per 100,000 inhabitants",
        TRUE ~ unidade
    ))
#renaming the variables to english 
temp_param_table$label[temp_param_table$var == "cod_ibge"] <- "Municipality code"
temp_param_table$label[temp_param_table$var == "ano"] <- "Year"
temp_param_table$label[temp_param_table$var == "t_total"] <- "Gross mortality per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_causas_externas"] <- "Mortality due to external causes per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_cardiovascular"] <- "Mortality due to circulatory system diseases per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_respiratorio"] <- "Mortality due to respiratory system diseases per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_infecciosas"] <- "Mortality due to some infectious and parasitic diseases per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_neoplasias"] <- "Mortality from neoplasms per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_cancer_mama"] <- "Mortality per malign breast neoplasm per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_cancer_colo_do_utero"] <- "Mortality from malign neoplasms of the uterine cervix per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_comunicaveis"] <- "Mortality due to communicable diseases per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_nao_comunicaveis"] <- "Mortality due to non-communicable diseases per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_diabetes"] <- "Mortality due to mellitus diabetes per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_malaria"] <- "Malaria mortality per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_aids"] <- "Mortality due to HIV disease per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_autoprovocadas"] <- "Voluntary self-harm mortality per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_agressoes"] <- "Aggression Mortality per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_acidentes"] <- "Mortality due to accidents per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_transporte"] <- "Mortality due to transport accidents per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_pedestre"] <- "Pedestrian Mortality at transport accidents per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_motociclista"] <- "Motorcycle-Riders Mortality in transport accidents per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_ciclista"] <- "Bike-Riders Mortality in transport accidents per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_infanti"] <- "Child Mortality per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_maternal"] <- "Maternal Mortality per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_fetal"] <- "Fetus Mortality per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_sangue"] <- "Mortality due to blood diseases per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_endocrinas"] <- "Mortality due to endocrine, nutritional and metabolic diseases per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_mentais"] <- "Mortality due to mental and behavioral disorders per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_nervoso"] <- "Mortality due to nervous system diseases per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_olho"] <- "Mortality due to eye diseases and annexes per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_ouvido"] <- "Mortality due to ear and mastoid apophysis diseases per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_digestivo"] <- "Mortality due to gastrointestinal diseases per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_pele"] <- "Mortality due to skin diseases per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_osteomuscular"] <- "Mortality due to diseases of the musculoskeletal and connective tissue system per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_genitourinario"] <- "Mortality due to diseases of the genitourinary system per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_gravidez"] <- "Mortality from pregnancy, childbirth, or the puerperium per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_perinatal"] <- "Mortality due to some diseases originated in the perinatal period per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_malformacoes"] <- "Mortality due to congenital malformations, deformities and chromosomal anomalies per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "t_anormais"] <- "Mortality from symptoms, signs, and abnormal findings on clinical and laboratory examinations per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "n_leitos_existentes"] <- "Number of existing hospital beds per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "n_leitos_sus"] <- "Number of hospital beds available for SUS per 100,000 inhabitants"
temp_param_table$label[temp_param_table$var == "n_leitos_nao_sus"] <- "Number of hospital beds unavailable for SUS per 100,000 inhabitants"

temp_param_table$label <- stringr::str_remove(temp_param_table$label, " per 100,000 inhabitants")

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/saude_mortalidade_dic_en.csv", fileEncoding = "UTF-8")
