############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(tidyverse)
library(haven)
library(tibble)
library(zoo)

# ATENCAO, DIRETORIOS PROVISORIOS!!!
base1 <- read_dta("C:/Users/Francisco/Dropbox/Amazonia_Mercado_Trabalho/build/output/_estrutura_emprego_amazonia_legal.dta")
base2 <- read_dta("C:/Users/Francisco/Dropbox/Amazonia_Mercado_Trabalho/build/output/_estrutura_emprego_resto_brasil.dta")

temp <- rbind(base1, base2)
id <- rep("Amazonia", 34)
id <- c(id, rep("Resto", 34))
temp <- cbind(temp, id)

# É preciso converter dados de tempo para trimestrais
temp <- temp %>% 
  mutate(time = paste0(temp$Ano, "-",temp$Trimestre))
temp$time <- as.Date(as.yearqtr(temp$time))
temp$Trimestre <- NULL
temp$Ano <- NULL

saveRDS(temp,
        file = "./data/ibge_pnadc_trabalho.rds")

columns <- colnames(temp)

temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = TRUE,
  label = columns,
  desc = columns,
  group = "Geral",
  tipo = 1,
  categoria= "Economia",
  subcategoria = "Trabalho"
  )

temp_param_table$label[3] <- "Proporção de empregador"
temp_param_table$label[1] <- "Proporção de empregados com carteira assinada"

write.csv(temp_param_table, file = "./data/ibge_pnadc_trabalho_dic.csv")
