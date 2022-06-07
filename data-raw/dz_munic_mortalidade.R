# packages ----------------------------------------------------------------
library(tidyverse)
#library(datazoom.amazonia)
devtools::load_all("./../datazoom.amazonia")

# load data ---------------------------------------------------------------

# To reduce memory use, each year is downloaded and aggregated separately

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
  filter(ano >= 1996 & ano <= 2020) %>% 
  distinct() %>% 
  select(!employed_census2000:median_income_census2010) # remove Census variables

# joining all causes of death ---------------------------------------------

df <- list(
  df_all,
  df_external_causes,
  df_infantil,
  df_maternal,
  df_fetal
) %>%
  reduce(full_join, by = c("code_muni", "year"))

# merge with dz_munic -----------------------------------------------------
data <- inner_join(dz_munic, df, by = c("code_muni", "ano"))


# export ------------------------------------------------------------------
saveRDS(data, "data/dz_munic_saude.rds")