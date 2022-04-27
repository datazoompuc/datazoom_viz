# packages ----------------------------------------------------------------
library(tidyverse)
library(lubridate)
library(readxl)


# load data ---------------------------------------------------------------
df <- read_csv("data/ext_data/saude/Dados A Saude na Amazonia Legal/dados_mun/df_mun.csv") %>% 
  select(-N) %>% 
  rename(cod_ibge = cod_mun) %>% 
  distinct() %>% 
  mutate(d_am_legal = factor(d_am_legal, levels = c(0, 1), labels = c("Não", "Sim")),
         d_hidro_oper = factor(d_hidro_oper, levels = c(0, 1), labels = c("Não", "Sim")),
         d_min_ilegal = factor(d_min_ilegal, levels = c(0, 1), labels = c("Não", "Sim"))
  ) %>% 
  select(ano, cod_ibge, contains("adj"), t_mama:siops_desprecpropsaude_def_pc)

dz_munic <- read_rds("data/dz_munic.rds") %>% 
  sf::st_drop_geometry() %>% 
  mutate(cod_ibge = as.numeric(substr(cod_ibge, 1, 6)),
         ano = year(ano)) %>% 
  filter(ano >= 2008 & ano <= 2019) %>% 
  distinct() %>% 
  select(!employed_census2000:median_income_census2010) # remove Census variables
  

# merge with dz_munic -----------------------------------------------------
data <- inner_join(dz_munic, df)


# export ------------------------------------------------------------------
saveRDS(data, "data/dz_munic_saude.rds")


# dictionary --------------------------------------------------------------
# extract variables from data
columns <- colnames(data)

# read separate dics and filter for existing variables
dic_dz_munic <- read_csv(file = 'data/dz_munic_dic.csv') %>% 
  filter(var %in% columns) %>% 
  select(-`...1`)

dic_saude <- read_csv(file = 'data/saude_municipality_dic.csv') %>% 
  filter(var %in% columns, !var %in% dic_dz_munic$var) %>% 
  select(!c(`...1`, tipo))

# join dictionaries
temp_param_table <- rbind(dic_dz_munic, dic_saude)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/dz_munic_saude_dic.csv", fileEncoding = "UTF-8")

