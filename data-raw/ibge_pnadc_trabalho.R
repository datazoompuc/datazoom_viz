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

write.csv(temp_param_table, file = "./data/ibge_pnadc_trabalho_dic.csv", fileEncoding = "UTF-8")

#################################################
## Dinamismo Economico na Amazonia
#################################################

input_folder_path <- "C:/Users/Francisco/Dropbox/Datazoom/Amazonia_Dinamismo_Economico/build/output/"

base1 <- read_dta(paste0(input_folder_path, "_amz_ac_numero_ocupados_por_atividade_2digitos.dta"))
base1 <- base1 %>% mutate(UF = "AC")
base2 <- read_dta(paste0(input_folder_path, "_amz_am_numero_ocupados_por_atividade_2digitos.dta"))
base2 <- base2 %>% mutate(UF = "AM")
base3 <- read_dta(paste0(input_folder_path, "_amz_ap_numero_ocupados_por_atividade_2digitos.dta"))
base3 <- base3 %>% mutate(UF = "AP")
base4 <- read_dta(paste0(input_folder_path, "_amz_ma_numero_ocupados_por_atividade_2digitos.dta"))
base4 <- base4 %>% mutate(UF = "MA")
base5 <- read_dta(paste0(input_folder_path, "_amz_mt_numero_ocupados_por_atividade_2digitos.dta"))
base5 <- base5 %>% mutate(UF = "MT")
base6 <- read_dta(paste0(input_folder_path, "_amz_pa_numero_ocupados_por_atividade_2digitos.dta"))
base6 <- base6 %>% mutate(UF = "PA")
base7 <- read_dta(paste0(input_folder_path, "_amz_ro_numero_ocupados_por_atividade_2digitos.dta"))
base7 <- base7 %>% mutate(UF = "RO")
base8 <- read_dta(paste0(input_folder_path, "_amz_rr_numero_ocupados_por_atividade_2digitos.dta"))
base8 <- base8 %>% mutate(UF = "RR")
base9 <- read_dta(paste0(input_folder_path, "_amz_to_numero_ocupados_por_atividade_2digitos.dta"))
base9 <- base9 %>% mutate(UF = "TO")

# Append data 
temp <- rbind(base1, base2, base3,base4,base5,base6,base7,base8,base9)

# Remove rows with missing data 
temp <- na.omit(temp)

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

temp_param_table$label[1] <- "Atividade econômica"
temp_param_table$label[2] <- "Número de ocupados"
temp_param_table$label[3] <- "Número de ocupados no setor formal"
temp_param_table$label[4] <- "Número de ocupados no setor informal"
temp_param_table$label[5] <- "Número de ocupados no setor público"
temp_param_table$label[6] <- "Número de ocupados no setor privado"
temp_param_table$label[7] <- "Rendimento mensal médio"
temp_param_table$label[8] <- "Rendimento mensal médio no setor formal"
temp_param_table$label[9] <- "Rendimento mensal médio no setor informal"
temp_param_table$label[10] <- "Massa salarial"
temp_param_table$label[11] <- "Estado"
temp_param_table$label[12] <- "Trimestre-Ano"
temp_param_table$label[13] <- "Fonte"

temp_param_table$y[1] <- FALSE
temp_param_table$y[11] <- FALSE
temp_param_table$y[12] <- FALSE
temp_param_table$y[13] <- FALSE

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_dinamismo_economico_dic.csv", fileEncoding = "UTF-8")
