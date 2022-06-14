# packages ----------------------------------------------------------------
library(tidyverse)
#library(datazoom.amazonia)
devtools::load_all("./../datazoom.amazonia") # While load_datasus hasn't been pushed to main

# load data ---------------------------------------------------------------

# To avoid taking up all the RAM, each year is downloaded and aggregated separately

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
    rename("t_infantil" = t_total)
)

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

dz_munic <- read_rds("data/dz_munic.rds") %>% 
  sf::st_drop_geometry() %>% 
  mutate(ano = lubridate::year(ano)) %>%
  filter(ano >= 1996 & ano <= 2020) %>% 
  distinct() %>% 
  mutate(code_muni = as.character(cod_ibge)) %>%
  select(!employed_census2000:median_income_census2010) # remove Census variables

# joining all causes of death ---------------------------------------------

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
      mutate(across(starts_with("_t"), ~ replace(., is.na(.), 0)))
  ) %>%
  reduce(full_join, by = c("code_muni", "ano")) %>%
  mutate(across(code_muni, as.character))

# merge with dz_munic -----------------------------------------------------
data <- inner_join(dz_munic, df, by = c("code_muni", "ano")) %>%
  ungroup() %>%
  mutate(cod_ibge = as.numeric(code_muni)) %>%
  select(-code_muni)


# export ------------------------------------------------------------------
saveRDS(data, "data/dz_munic_mortalidade.rds")

# dictionary --------------------------------------------------------------
columns <- names(data)

# for the non-datasus variables
dic_dz_munic <- read_csv(file = 'data/dz_munic_dic.csv') %>% 
  filter(var %in% columns) %>% 
  select(-`...1`)

# building health dictionary
dic_mortalidade <- load_dictionary("datasus_sim") %>%
  filter(is_cid_code) %>%
  select("var" = name_pt, "label" = label_pt)

# Adding external causes, infantile, maternal, and fetal deaths manually since they aren't in the original database
dic_mortalidade <- dic_mortalidade %>%
  bind_rows(
    tribble(~ var, ~ label,
            "t_infantil", "Mortes infantis",
            "t_maternal", "Mortes maternas",
            "t_fetal", "Mortes fetais")
  )

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
         var_group = "Saúde - DATASUS",
         unidade = NA,
         categoria = "Social",
         subcategoria = "Saúde")

# join dictionaries
temp_param_table <- rbind(dic_dz_munic, dic_mortalidade)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/dz_munic_mortalidade_dic.csv", fileEncoding = "UTF-8")
