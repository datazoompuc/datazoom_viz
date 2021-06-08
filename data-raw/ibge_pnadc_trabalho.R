############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(tidyverse)
library(haven)
library(tibble)

# ATENCAO, DIRETORIOS PROVISORIOS!!!
base1 <- read_dta("C:/Users/Francisco/Dropbox/Amazonia_Mercado_Trabalho/build/output/_estrutura_emprego_amazonia_legal.dta")
base2 <- read_dta("C:/Users/Francisco/Dropbox/Amazonia_Mercado_Trabalho/build/output/_estrutura_emprego_resto_brasil.dta")

temp <- rbind(base1, base2)

saveRDS(temp,
        file = "./data/ibge_pnadc_trabalho.rds")

columns <- colnames(temp)

temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = TRUE,
  label = columns,
  desc = columns
  )

write.csv(temp_param_table, file = "./data/ibge_pnadc_trabalho_dic.csv")
