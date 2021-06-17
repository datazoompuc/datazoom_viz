############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(tidyverse)
library(haven)
library(tibble)
library(zoo)
library(datazoom.social)


dates <- list(c(1, 2012), c(2, 2012))

microdata <- load_pnadcontinua(language = 'port',
                        sources = dates,
                        download_directory = './Desktop')




# ATENCAO, DIRETORIOS PROVISORIOS!!!
#base1 <- read_dta("C:/Users/Francisco/Dropbox/Amazonia_Mercado_Trabalho/build/output/_estrutura_emprego_amazonia_legal.dta")
#base2 <- read_dta("C:/Users/Francisco/Dropbox/Amazonia_Mercado_Trabalho/build/output/_estrutura_emprego_resto_brasil.dta")

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

#################################################
base1 <- read_dta("C:/Users/Francisco/Dropbox/Datazoom/Amazonia_Dinamismo_Economico/build/output/_amz_am_numero_ocupados_por_atividade_2digitos.dta")
temp  <- base1 %>% mutate(UF = "AM")

# É preciso converter dados de tempo para trimestrais
temp <- temp %>% 
  mutate(time = paste0(temp$Ano, "-",temp$Trimestre))
temp$time <- as.Date(as.yearqtr(temp$time))
temp$Trimestre <- NULL
temp$Ano <- NULL

temp$group <- paste0(temp$UF," - ", temp$titulo)

saveRDS(temp,
        file = "./data/ibge_pnadc_dinamismo_economico.rds")

columns <- colnames(temp)

temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = TRUE,
  label = columns,
  desc = columns,
  var_group = "PNADC IBGE",
  tipo = 1,
  categoria= "Economia",
  subcategoria = "Trabalho"
)

temp_param_table$label[1] <- "Proporção de empregador"
temp_param_table$label[2] <- "Numéro de ocupados"
temp_param_table$label[3] <- "Numéro de ocupados no setor formal"
#depois preencher

write.csv(temp_param_table, file = "./data/ibge_pnadc_dinamismo_economico_dic.csv")
