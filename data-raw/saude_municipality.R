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

# dictionary in english --------------------------------------------------------------
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
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Municipality code"
temp_param_table$label[3] <- "Population"
temp_param_table$label[4] <- "Real GDP (R$ 2021)"
temp_param_table$label[5] <- "Real GDP per capita (R$ 2021)"
temp_param_table$label[6] <- "Municipalitie's name"
temp_param_table$label[7] <- "Region"
temp_param_table$label[8] <- "State's name"
temp_param_table$label[9] <- "State"
temp_param_table$label[10] <- "Belongs to the Legal Amazon (1) or not (0)" 
temp_param_table$label[11] <- "Municipalities with hydroelectric plants operating (1) or not(0)"
temp_param_table$label[12] <- "Municipalities with illegal mining (1) or not (0)"
temp_param_table$label[13] <- "Gross mortality per 100,000 inhabitants"
temp_param_table$label[14] <- "Age-adjusted mortality per 100,000 inhabitants"
temp_param_table$label[15] <- "Mortality due to non-communicable causes per 100,000 inhabitants"
temp_param_table$label[16] <- "Adjusted mortality due to communicable causes per 100,000 inhabitants"
temp_param_table$label[17] <- "Mortality due to external causes per 100,000 inhabitants"
temp_param_table$label[18] <- "Adjusted mortality due to external causes per 100,000 inhabitants"
temp_param_table$label[19] <- "Mortality due to communicable causes per 100,000 inhabitants"
temp_param_table$label[20] <- "Adjusted mortality due to non-communicable causes  per 100,000 inhabitants "
temp_param_table$label[21] <- "Mortality due to undefined causes per 100,000 inhabitants"
temp_param_table$label[22] <- "Adjusted mortality due to cardiovascular diseases  per 100,000 inhabitants "
temp_param_table$label[23] <- "Adjusted mortality due to diabetes  per 100,000 inhabitants "
temp_param_table$label[24] <- "Adjusted mortality due to neoplasms per 100,000 inhabitants "
temp_param_table$label[25] <- "Adjusted mortality due to violence  per 100,000 inhabitants "
temp_param_table$label[26] <- "Adjusted mortality due to traffic-accidents per 100,000 inhabitants "
temp_param_table$label[27] <- "Adjusted mortality due to unintentional accidents  per 100,000 inhabitants "
temp_param_table$label[28] <- "Adjusted mortality due to accidents involving motorcycle  per 100,000 inhabitants "
temp_param_table$label[29] <- "Adjusted mortality due to accidents not involving motorcycle  per 100,000 inhabitants "
temp_param_table$label[30] <- "Adjusted mortality due to Malaria per 100,000 inhabitants "
temp_param_table$label[31] <- "Adjusted mortality due to AIDS per 100,000 inhabitants " 
temp_param_table$label[32] <- "Adjusted mortality due to waterborne diseases per 100,000 inhabitants "
temp_param_table$label[33] <- "Adjusted mortality due to respiratory disease per 100,000 inhabitants "
temp_param_table$label[34] <- "Mortality due to breast cancer per 100,000 women"
temp_param_table$label[35] <- "Mortality due to cervical cancer  per 100,000 women"
temp_param_table$label[36] <- "Mortality due to violence per 100,000 women"
temp_param_table$label[37] <- "Percentage born with low birth weight"
temp_param_table$label[38] <- "Percentage of pregnancies between 10 and 19 years old"
temp_param_table$label[39] <- "Gross indigenous mortality per 100,000 inhabitants"
temp_param_table$label[40] <- "Indigenous mortality due to communicable causes per 100,000 inhabitants"
temp_param_table$label[41] <- "Indigenous mortality due to non-communicable causes per 100,000 inhabitants"
temp_param_table$label[42] <- "Indigenous mortality due to external causes 100,000 inhabitants"
temp_param_table$label[43] <- "Indigenous mortality due to undefined causes per 100,000 inhabitants"
temp_param_table$label[44] <- "Indigenous infant mortality per thousand live births"
temp_param_table$label[45] <- "Percentage of Family Health Strategy (eSF) coverage"
temp_param_table$label[46] <- "Percentage of Primary Care coverage (AB Teams + eSF Teams)"
temp_param_table$label[47] <- "Percentage of coverage by Community Health Agents (ACS)"
temp_param_table$label[48] <- "eSF (Family Health Strategy) teams per 1,000 km2"
temp_param_table$label[59] <- "AB (Primary Care) teams per 1,000 km2"
temp_param_table$label[50] <- "ACS (Community Health Agent) per 1,000 km2"
temp_param_table$label[51] <- "Riverside and Fluvial Family Health Facilities"
temp_param_table$label[52] <- "Riverside and Fluvial Family Health Teams"
temp_param_table$label[53] <- "Total hospital beds"
temp_param_table$label[54] <- "SUS hospital beds"
temp_param_table$label[55] <- "Total ICU hospital beds"
temp_param_table$label[56] <- "SUS ICU hospital beds"
temp_param_table$label[57] <- "Distance to the nearest urgent-emergency service"
temp_param_table$label[58] <- "Distance to the nearest medium complexity service"
temp_param_table$label[59] <- "Distance to the nearest high complexity service"
temp_param_table$label[60] <- "Distance to the nearest ICU"
temp_param_table$label[61] <- "Distance to nearest dialysis facility"
temp_param_table$label[62] <- "Distance to the nearest chemotherapy service"
temp_param_table$label[63] <- " Doctors per 100,000 inhabitants"
temp_param_table$label[64] <- " Nursing Professionals per 100,000 inhabitants"
temp_param_table$label[65] <- "Cardiologists per 100,000 inhabitants"
temp_param_table$label[66] <- "Gynecologists per 100,000 inhabitants"
temp_param_table$label[67] <- "Endocrinologists per 100,000 inhabitants"
temp_param_table$label[68] <- "Oncologists per 100,000 inhabitants"
temp_param_table$label[69] <- "Doctors of the More Doctors Program"
temp_param_table$label[70] <- "Proportion of doctors from the More Doctors Program over the total number of doctors"
temp_param_table$label[71] <- "Proportion of beneficiaries of private health plans"
temp_param_table$label[72] <- "Proportion of hospitals not affiliated with SUS"
temp_param_table$label[73] <- "Private hospital beds per 100,000 inhabitants"
temp_param_table$label[74] <- "Private ICU hospital beds per 100,000 inhabitants"
temp_param_table$label[75] <- "Private hospitals affiliated with SUS per 100,000 inhabitants"
temp_param_table$label[76] <- "Private hospitals not affiliated with SUS per 100,000 inhabitants"
temp_param_table$label[77] <- "Total spending on health per capita"
temp_param_table$label[78] <- "Transfers per capita"
temp_param_table$label[79] <- "Own resource per capita"
temp_param_table$label[8] <- "State's name"

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
write.csv(temp_param_table, file = "data/saude_municipality_dic_en.csv", fileEncoding = "UTF-8")

