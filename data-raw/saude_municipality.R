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
         )

dz_munic <- read_rds("data/dz_munic.rds") %>% 
  sf::st_drop_geometry() %>% 
  select(ano, cod_ibge, pop, gdp_deflacionado, gd_ppc_deflacionado) %>% 
  mutate(cod_ibge = as.numeric(substr(cod_ibge, 1, 6)),
         ano = year(ano)) %>% 
  filter(ano >= 2008 & ano <= 2019) %>% 
  distinct()


# merge with dz_munic -----------------------------------------------------
data <- inner_join(dz_munic, df)


# export ------------------------------------------------------------------
saveRDS(data, "data/saude_municipality.rds")


# dictionary --------------------------------------------------------------
dic_saude <- read_excel("data/ext_data/saude/Dados A Saude na Amazonia Legal/dados_mun/variaveis_dados_municipios.xlsx") %>% 
  pull(`Descrição`)

# extract variables from data
columns <- colnames(data)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns,
  desc = columns,
  var_group = "Saúde - DATASUS",
  tipo = 1,
  unidade = "",
  categoria= "Social", 
  subcategoria = "Saúde"
)

temp_param_table$label <- temp_param_table$var
temp_param_table$label[1] <- "Ano"
temp_param_table$label[2] <- "Codigo do municipio"
temp_param_table$label[3] <- "População"
temp_param_table$label[4] <- "PIB real (R$ 2021)"
temp_param_table$label[5] <- "PIB per capita real (R$ 2021)"
temp_param_table$label[6:79] <- dic_saude[3:76]
temp_param_table$label[8] <- "Estado"

temp_param_table$x <- c(FALSE, FALSE, rep(TRUE, 3), rep(FALSE, 7), rep(TRUE, 67))
temp_param_table$y <- c(FALSE, FALSE, rep(TRUE, 3), rep(FALSE, 7), rep(TRUE, 67))
temp_param_table$color <- c(rep(FALSE, 6), rep(TRUE, 2), FALSE, FALSE, TRUE, TRUE, rep(FALSE, 67))
temp_param_table$size <- c(FALSE, FALSE, TRUE, TRUE, TRUE, rep(FALSE, 71), TRUE, TRUE, TRUE)
temp_param_table$slider <- c(TRUE, rep(FALSE, 78))

# var_group variables
temp_param_table$var_group[1:2] <- ""
temp_param_table$var_group[3:5] <- "IBGE"
temp_param_table$var_group[6:12] <- " "

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/saude_municipality_dic.csv", fileEncoding = "UTF-8")

