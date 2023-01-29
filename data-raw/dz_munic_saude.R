# packages ----------------------------------------------------------------
library(tidyverse)
library(datazoom.amazonia)

# load data ---------------------------------------------------------------

# To avoid taking up all the RAM, each year is downloaded and aggregated separately

# SIM - DO data

df_all <- map_dfr(
  1996:2020, 
  
  ~ load_datasus(
    dataset = "datasus_sim_do",
    time_period = .x,
    states = c("RO", "AC", "AM", "RR", "PA", "AP", "TO", "MA", "PI", "BA", "MS", "MT", "GO"),
    raw_data = FALSE,
    keep_all = FALSE,
    language = "pt"
  ) %>%
    filter(legal_amazon == 1) %>%
    mutate(ano = lubridate::year(dtobito)) %>%
    group_by(code_muni, code_state, abbrev_state, ano) %>%
    summarise(across(starts_with("t_"), sum))
)

df_all <- df_all %>%
  drop_na(code_muni) %>%
  select(-t_causas_externas)

# SIM - DOEXT data

df_external_causes <- map_dfr(
  1996:2020, 
  
  ~ load_datasus(
    dataset = "datasus_sim_doext",
    time_period = .x,
    states = "all",
    raw_data = FALSE,
    keep_all = FALSE,
    language = "pt"
  ) %>%
    filter(legal_amazon == 1) %>%
    mutate(ano = lubridate::year(dtobito)) %>%
    select(code_muni, code_state, abbrev_state, ano, t_total) %>%
    group_by(code_muni, code_state, abbrev_state, ano) %>%
    summarise(across(starts_with("t_"), sum)) %>%
    rename("t_causas_externas" = t_total)
) 

# SIM - DOINF data

df_infantil <- map_dfr(
  1996:2020, 
  
  ~ load_datasus(
    dataset = "datasus_sim_doinf",
    time_period = .x,
    states = "all",
    raw_data = FALSE,
    keep_all = FALSE,
    language = "pt"
  ) %>%
    filter(legal_amazon == 1) %>%
    mutate(ano = lubridate::year(dtobito)) %>%
    select(code_muni, code_state, abbrev_state, ano, t_total) %>%
    group_by(code_muni, code_state, abbrev_state, ano) %>%
    summarise(across(starts_with("t_"), sum)) %>%
    rename("t_infantil" = t_total)
)

# SIM - DOMAT data

df_maternal <- map_dfr(
  1996:2020, 
  
  ~ load_datasus(
    dataset = "datasus_sim_domat",
    time_period = .x,
    states = "all",
    raw_data = FALSE,
    keep_all = FALSE,
    language = "pt"
  ) %>%
    filter(legal_amazon == 1) %>%
    mutate(ano = lubridate::year(dtobito)) %>%
    select(code_muni, code_state, abbrev_state, ano, t_total) %>%
    group_by(code_muni, code_state, abbrev_state, ano) %>%
    summarise(across(starts_with("t_"), sum)) %>%
    rename("t_maternal" = t_total)
)

# SIM - DOFET data

df_fetal <- map_dfr(
  1996:2020, 
  
  ~ load_datasus(
    dataset = "datasus_sim_dofet",
    time_period = .x,
    states = "all",
    raw_data = FALSE,
    keep_all = FALSE,
    language = "pt"
  ) %>%
    filter(legal_amazon == 1) %>%
    mutate(ano = lubridate::year(dtobito)) %>%
    select(code_muni, code_state, abbrev_state, ano, t_total) %>%
    group_by(code_muni, code_state, abbrev_state, ano) %>%
    summarise(across(starts_with("t_"), sum)) %>%
    rename("t_fetal" = t_total)
)

# CNES - LT (Leitos) data

df_cnes_lt <- map_dfr(
  2005:2020, 
  
  ~ load_datasus(
    dataset = "datasus_cnes_lt",
    time_period = .x,
    states = c("RO", "AC", "AM", "RR", "PA", "AP", "TO", "MA", "PI", "BA", "MS", "MT", "GO"),
    raw_data = FALSE,
    keep_all = FALSE,
    language = "pt"
  ) %>%
    filter(legal_amazon == 1) %>%
    rename("ano" = year) %>%
    select(code_muni, code_state, abbrev_state, ano, n_leitos_existentes, n_leitos_sus, n_leitos_nao_sus) %>%
    group_by(code_muni, code_state, abbrev_state, ano) %>%
    summarise(across(starts_with("n_"), sum))
)

dz_munic <- read_rds("data/dz_munic.rds") %>% 
  sf::st_drop_geometry() %>% 
  mutate(ano = lubridate::year(ano)) %>%
  filter(ano >= 1996 & ano <= 2020) %>% 
  distinct() %>% 
  mutate(code_muni = as.character(cod_ibge)) %>%
  select(!employed_census2000:median_income_census2010) # remove Census variables

# joining all causes of death + hospital beds ------------------------------------------

df <- list(
  df_all,
  df_external_causes,
  df_infantil,
  df_maternal,
  df_fetal
) %>%
  map(
    . %>%
      ungroup() %>%
      select(code_muni, ano, starts_with("t_")) %>%
      mutate(across(starts_with("t_"), ~ replace(., is.na(.), 0)))
  ) %>%
  reduce(full_join, by = c("code_muni", "ano")) %>%
  mutate(across(code_muni, as.character))

# Joining CNES LT

df <- df_cnes_lt %>%
  ungroup() %>%
  select(code_muni, ano, starts_with("n_")) %>%
  mutate(across(starts_with("n_"), ~ replace(., is.na(.), 0))) %>%
  mutate(across(code_muni, as.character)) %>%
  mutate(across(ano, as.numeric)) %>%
  full_join(df, ., by = c("code_muni", "ano"))

# merge with dz_munic -----------------------------------------------------
data <- inner_join(dz_munic, df, by = c("code_muni", "ano")) %>%
  ungroup() %>%
  mutate(cod_ibge = as.numeric(code_muni)) %>%
  select(-code_muni)

# manipulations -----------------------------------------------------------

# mortality and beds per 100k residents

data <- data %>%
  mutate(across(c(starts_with("t_"), starts_with("n_")),
                ~ 10^5 * ./pop))

# adjusted mortality by age ??

# removing variables that never appear
# (not all CID codes are actually used for deaths)

total_deaths <- data %>%
  summarise(across(c(starts_with("t_"), starts_with("n_")), ~ sum(., na.rm = TRUE)))

drop_vars <- total_deaths %>%
  pivot_longer(everything()) %>%
  filter(value == 0) %>%
  select(name) %>%
  unlist()

data <- data %>%
  select(-any_of(drop_vars))

# export ------------------------------------------------------------------
saveRDS(data, "data/dz_munic_saude.rds")

# dictionary --------------------------------------------------------------

# for the non-datasus variables
dic_dz_munic <- read_csv(file = 'data/dz_munic_dic.csv') %>% 
  filter(var %in% names(data)) %>% 
  select(-`...1`)

# building health dictionary
dic_mortalidade <- tribble(
  ~var, ~label, ~var_group,
  "t_total", "Mortalidade bruta por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_causas_externas", "Mortalidade por causas externas por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_cardiovascular", "Mortalidade por doen\u00e7as do aparelho circulat\u00f3rio por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_respiratorio", "Mortalidade por doen\u00e7as do aparelho respirat\u00f3rio por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_infecciosas", "Mortalidade por algumas doen\u00e7as infecciosas e parasit\u00e1rias por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_neoplasias", "Mortalidade por neoplasias por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_cancer_mama", "Mortalidade por neoplasia maligna da mama por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_cancer_colo_do_utero", "Mortalidade por neoplasia maligna do colo do \u00fatero por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_comunicaveis", "Mortalidade por doen\u00e7as comunic\u00e1veis por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_nao_comunicaveis", "Mortalidade por doen\u00e7as n\u00e3o comunic\u00e1veis por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_diabetes", "Mortalidade por diabetes mellitus por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_malaria", "Mortalidade por mal\u00e1ria por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_aids", "Mortalidade por doen\u00e7a por HIV por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_autoprovocadas", "Mortalidade por les\u00f5es autoprovocadas voluntariamente por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_agressoes", "Mortalidade por agress\u00f5es por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_acidentes", "Mortalidade por acidentes por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_transporte", "Mortalidade por acidentes de transporte por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_pedestre", "Mortalidade de pedestres em acidentes de transporte por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_motociclista", "Mortalidade de motociclistas em acidentes de transporte por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_ciclista", "Mortalidade de ciclistas em acidentes de transporte por 100 mil habitantes", "Saúde - DATASUS - SIM",
  
  "t_srag", "Mortalidade por s\u00edndrome respirat\u00f3ria aguda grave por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_cigarro_eletronico", "Mortalidade por transtornos relacionados a uso de vaporizador ou cigarro eletr\u00f4nico por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_covid_identificada", "Mortalidade por COVID-19 com v\u00edrus identificado por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_covid_nao_identificada", "Mortalidade por COVID-19 com v\u00edrus n\u00e3o identificado por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_covid_historico", "Mortalidade por hist\u00f3rico pessoal de COVID-19 por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_pos_covid", "Mortalidade por condi\u00e7\u00e3o p\u00f3s-COVID por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_inflamacao_covid", "Mortalidade por s\u00edndrome inflamat\u00f3ria multissist\u00eamica associada a COVID-19 por 100 mil habitantes", "Saúde - DATASUS - SIM",
  
  "t_infantil", "Mortalidade infantil por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_maternal", "Mortalidade materna por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_fetal", "Mortalidade fetal por 100 mil habitantes", "Saúde - DATASUS - SIM",
  
  "t_sangue", "Mortalidade por doen\u00e7as do sangue por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_endocrinas", "Mortalidade por doen\u00e7as end\u00f3crinas, nutricionais de metab\u00f3licas por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_mentais", "Mortalidade por transtornos mentais e comportamentais por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_nervoso", "Mortalidade por doen\u00e7as do sistema nervoso por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_olho", "Mortalidade por doen\u00e7as do olho e anexos por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_ouvido", "Mortalidade por doen\u00e7as do ouvido e da ap\u00f3fise mastoide por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_digestivo", "Mortalidade por doen\u00e7as do aparelho digestivo por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_pele", "Mortalidade por doen\u00e7as da pele por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_osteomuscular", "Mortalidade por doen\u00e7as do sistema osteomuscular e do tecido conjuntivo por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_genitourinario", "Mortalidade por doen\u00e7as do aparelho genitourin\u00e1rio por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_gravidez", "Mortalidade decorrente de gravidez, parto, ou puerp\u00e9rio por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_perinatal", "Mortalidade por algumas afec\u00e7\u00f5es originadas no perinatal por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_malformacoes", "Mortalidade por malforma\u00e7\u00f5es cong\u00eanitas, deformidades e anomalias cromoss\u00f4micas por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_anormais", "Mortalidade por sintomas, sinais e achados anormais de exames cl\u00ednicos e de laborat\u00f3rio por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_lesoes", "Mortalidade por les\u00f5es, envenenamentos e algumas outras causas externas por 100 mil habitantes", "Saúde - DATASUS - SIM",
  "t_influencia", "Mortalidade por fatores que exercem influ\u00eancia sobre o contato com servi\u00e7os de sa\u00fade por 100 mil habitantes", "Saúde - DATASUS - SIM",
  
  "n_leitos_existentes", "N\u00famero de leitos existentes por 100 mil habitantes",  "Saúde - DATASUS - CNES",
  "n_leitos_sus", "N\u00famero de leitos dispon\u00edveis para o SUS por 100 mil habitantes",  "Saúde - DATASUS - CNES",
  "n_leitos_nao_sus", "N\u00famero de leitos n\u00e3o dispon\u00edveis para o SUS por 100 mil habitantes",  "Saúde - DATASUS - CNES",
  )

dic_mortalidade <- dic_mortalidade %>%
  filter(var %in% names(data))

# Adding the remainder of the dictionary columns

dic_mortalidade <- dic_mortalidade %>%
  mutate(var = var,
         x = TRUE,
         y = TRUE,
         color = FALSE,
         size = FALSE,
         slider = FALSE,
         geometry = FALSE,
         label = label,
         desc = var,
         var_group = var_group,
         unidade = NA,
         categoria = "Social",
         subcategoria = "Saúde")

# join dictionaries
temp_param_table <- rbind(dic_dz_munic, dic_mortalidade)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/dz_munic_saude_dic.csv", fileEncoding = "UTF-8")

#######################################
# building English health dictionary
#######################################
 
#####################################
# for the non-datasus variables
#####################################
dic_dz_munic <- read_csv(file = 'data/dz_munic_dic_en.csv') %>% 
    filter(var %in% names(data)) %>% 
    select(-`...1`)

#################################################################
dic_mortalidade <- tribble(
    ~var, ~label, ~var_group,
    "t_total", "Gross mortality per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_causas_externas", "Mortality from external causes per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_cardiovascular", "Mortality from circulatory system diseases per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_respiratorio", "Mortality from respitarory system diseases per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_infecciosas", "Mortality from some infectious and parasitic diseases per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_neoplasias", "Mortality from neoplasms per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_cancer_mama", "Mortality from malignant neoplasm of the breast per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_cancer_colo_do_utero", "Cervical cancer mortality per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_comunicaveis", "Mortality from communicable diseases per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_nao_comunicaveis", "Mortality from non-communicable diseases per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_diabetes", "Mortality from diabetes mellitus per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_malaria", "Mortality from malaria per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_aids", "Mortality from HIV disease per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_autoprovocadas", "Voluntary self-harm mortality per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_agressoes", "Mortality from assaults per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_acidentes", "Mortality from accidents per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_transporte", "Mortality from transport accidents per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_pedestre", "Pedestrian mortality in transport accidents per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_motociclista", "Mortality of motorcyclists in transport accidents per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_ciclista", "Mortality of cyclists in transport accidents per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    
    "t_srag", "Mortality from severe acute respiratory syndrome per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_cigarro_eletronico", "Mortality from vaporizer or electronic cigarette use disorders per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_covid_identificada", "Mortality from COVID-19 with identified virus per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_covid_nao_identificada", "Mortality from COVID-19 with unidentified virus per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_covid_historico", "Mortality from personal history of COVID-19 per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_pos_covid", "Mortality by cardiovascular conditions-COVID per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_inflamacao_covid", "Mortality from multisystemic inflammatory syndrome associated with COVID-19 per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    
    "t_infantil", "Child Mortality per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_maternal", "Maternal mortality per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_fetal", "Foetal mortality per 100000 inhabitants per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    
    "t_sangue", "Mortality from blood diseases per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_endocrinas", "Mortality from endocrine, nutritional and metabolic diseases per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_mentais", "Mortality from mental and behavioural disorders per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_nervoso", "Mortality from diseases of the nervous system per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_olho", "Mortality from diseases of the eye and adnexa per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_ouvido", "Mortality from diseases of the ear and mastoid appendage per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_digestivo", "Mortality from digestive tract diseases per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_pele", "Mortality from skin diseases per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_osteomuscular", "Mortality from diseases of the musculoskeletal system and connective tissue per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_genitourinario", "Mortality from diseases of the genitourinary system per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_gravidez", "Mortality from pregnancy, childbirth or puerperium per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_perinatal", "Mortality from some perinatal conditions per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_malformacoes", "Mortality due to congenital malformations, deformities and chromosomal abnormalities per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_anormais", "Mortality from symptoms, signs and abnormal findings on clinical and laboratory examinations per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_lesoes", "Mortality from injuries, poisoning and some other external causes per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    "t_influencia", "Mortality by factors influencing contact with health services per 100,000 inhabitants", "Saúde - DATASUS - SIM",
    
    "n_leitos_existentes", "Number of existing beds per 100,000 inhabitants",  "Saúde - DATASUS - CNES",
    "n_leitos_sus", "Number of beds available for SUS per 100,000 inhabitants",  "Saúde - DATASUS - CNES",
    "n_leitos_nao_sus", "Number of beds not available for SUS per 100,000 inhabitants",  "Saúde - DATASUS - CNES",
)

dic_mortalidade <- dic_mortalidade %>%
    filter(var %in% names(data))

# Adding the remainder of the dictionary columns

dic_mortalidade <- dic_mortalidade %>%
    mutate(var = var,
           x = TRUE,
           y = TRUE,
           color = FALSE,
           size = FALSE,
           slider = FALSE,
           geometry = FALSE,
           label = label,
           desc = var,
           var_group = var_group,
           unidade = NA,
           categoria = "Social",
           subcategoria = "Saúde")

# join dictionaries
temp_param_table <- rbind(dic_dz_munic, dic_mortalidade)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/dz_munic_saude_dic_en.csv", fileEncoding = "UTF-8")
