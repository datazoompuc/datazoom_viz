############################################################
##
## Generate rds data in the folder ./data/ 
##
## This script must be run periodically to update databases.
##
############################################################

# call packages
library(tidyverse)
library(haven)
library(tibble)
library(zoo)
library(datazoom.social)

# update dates 
#dates <- list(c(1, 2012), c(2, 2012))

#microdata <- load_pnadcontinua(language = 'port',
#                        sources = dates,
#                        download_directory = './Desktop')
#

#################################################
## Mercado de Trabalho na Amazônia Legal
## Ouput data from:
## Dinamismo Economico na Amazonia
## github: https://github.com/FranciscoCavalcanti/Amazonia_Mercado_Trabalho
#################################################

# set path to raw data
user_folder_path <- "C:/Users/Francisco/Dropbox/" # set actual user data path
github_folder_path <- "Amazonia_Mercado_Trabalho/build/output/"  # set github structure path 

# call raw data
base1 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_amazonia_legal.dta"))
base1 <- base1 %>% mutate(id = "Amazônia Legal")
base2 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_resto_brasil.dta"))
base2 <- base2 %>% mutate(id = "Restante do Brasil")

# append all data 
temp <- rbind(base1, base2)

# convert time data to quarterly
temp <- temp %>% 
  mutate(time = paste0(temp$Ano, "-",temp$Trimestre))
temp$time <- as.Date(as.yearqtr(temp$time))
temp$Trimestre <- NULL
temp$Ano <- NULL

# groups at the level: 
temp$group <- temp$id

# change column order
temp <-  temp %>% 
  relocate(id, time, group)

# select relevant variables
temp <-  temp %>% 
  select(id, time, group, 
         taxa_de_desemprego, 
         taxa_de_ocupacao, 
         taxa_de_participacao,
         taxa_de_informalidade,
         taxa_de_desalento, 
         taxa_de_nemnem,
         n_de_desemprego,
         n_de_ocupacao,
         n_de_informalidade,
         n_de_desalento,
         n_de_nemnem
         )

# save at rds format
saveRDS(temp,
        file = "./data/ibge_pnadc_trabalho.rds")

#####################
# Build Dictionary 
#####################

# extract variables from data
columns <- colnames(temp)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = TRUE,
  label = columns,
  desc = columns,
  var_group = "IBGE - PNAD Contínua",
  categoria= "Economia",
  subcategoria = "Trabalho"
  )

# label variables
temp_param_table$label[1] <- "Recorte regional"
temp_param_table$label[2] <- "Ano-Trimestre"
temp_param_table$label[3] <- "Recorte regional"
temp_param_table$label[4] <- "Taxa de desemprego em relação a força de trabalho (%)" 
temp_param_table$label[5] <- "Taxa de ocupação em relação a PIA (%)"
temp_param_table$label[6] <- "Taxa de participação em relação a PIA (%)"
temp_param_table$label[7] <- "Taxa de informalidade em relação aos ocupados (%)"
temp_param_table$label[8] <- "Taxa de desalentados em relação a PIA (%)"
temp_param_table$label[9] <- "Taxa de nem-nem em relação a PIA (%)" 
temp_param_table$label[10] <- "Número de desempregados"
temp_param_table$label[11] <- "Número de ocupados"
temp_param_table$label[12] <- "Número de informais"
temp_param_table$label[13] <- "Número de desalentados"
temp_param_table$label[14] <- "Número de nem-nem"

# block variables in graphs y-axis
temp_param_table$y[1] <- FALSE # Recorte regional
temp_param_table$y[2] <- FALSE # Ano-Trimestre
temp_param_table$y[3] <- FALSE # Recorte regional

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_trabalho_dic.csv", fileEncoding = "UTF-8")

#################################################
## Atividade Econômica na Amazônia Legal
## Ouput data from:
## Dinamismo Economico na Amazonia
## github: https://github.com/FranciscoCavalcanti/Amazonia_Dinamismo_Economico
#################################################

# set path to raw data
user_folder_path <- "C:/Users/Francisco/Dropbox/Datazoom/" # set actual user data path
github_folder_path <- "Amazonia_Dinamismo_Economico/build/output/"  # set github structure path 

# call raw data
base1 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_ac_numero_ocupados_por_atividade_2digitos.dta"))
base1 <- base1 %>% mutate(UF = "AC")
base2 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_am_numero_ocupados_por_atividade_2digitos.dta"))
base2 <- base2 %>% mutate(UF = "AM")
base3 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_ap_numero_ocupados_por_atividade_2digitos.dta"))
base3 <- base3 %>% mutate(UF = "AP")
base4 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_ma_numero_ocupados_por_atividade_2digitos.dta"))
base4 <- base4 %>% mutate(UF = "MA")
base5 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_mt_numero_ocupados_por_atividade_2digitos.dta"))
base5 <- base5 %>% mutate(UF = "MT")
base6 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_pa_numero_ocupados_por_atividade_2digitos.dta"))
base6 <- base6 %>% mutate(UF = "PA")
base7 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_ro_numero_ocupados_por_atividade_2digitos.dta"))
base7 <- base7 %>% mutate(UF = "RO")
base8 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_rr_numero_ocupados_por_atividade_2digitos.dta"))
base8 <- base8 %>% mutate(UF = "RR")
base9 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_to_numero_ocupados_por_atividade_2digitos.dta"))
base9 <- base9 %>% mutate(UF = "TO")

# append all data 
temp <- rbind(base1, base2, base3,base4,base5,base6,base7,base8,base9)

# remove rows with missing data 
temp <- na.omit(temp)
temp <- temp %>%
  filter(titulo !="")

# convert time data to quarterly
temp <- temp %>% 
  mutate(time = paste0(temp$Ano, "-",temp$Trimestre))
temp$time <- as.Date(as.yearqtr(temp$time))
temp$Trimestre <- NULL
temp$Ano <- NULL

# groups at the level: Estado e Atividade Economica
temp$group <- paste0(temp$UF," - ", temp$titulo)

# change column order
temp <-  temp %>% 
  relocate(group, time)

# save data at rds format
saveRDS(temp,
        file = "./data/ibge_pnadc_cnae.rds")

#####################
# Build Dictionary 
#####################

# extract variables from data
columns <- colnames(temp)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = TRUE,
  label = columns,
  desc = columns,
  var_group = "IBGE - PNAD Contínua",
  tipo = 1,
  categoria= "Economia", 
  subcategoria = "Mercado de trabalho"
)

# label variables
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

# block variables in graphs y-axis
temp_param_table$y[1] <- FALSE # Atividade econômica
temp_param_table$y[11] <- FALSE # Estado
temp_param_table$y[12] <- FALSE # Trimestre-Ano
temp_param_table$y[13] <- FALSE # Fonte

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_cnae_dic.csv", fileEncoding = "UTF-8")

#################################################
## Ocupações na Amazônia Legal
## Ouput data from:
## Dinamismo Economico na Amazonia
## github: https://github.com/FranciscoCavalcanti/Amazonia_Dinamismo_Economico
#################################################

# set path to raw data
user_folder_path <- "C:/Users/Francisco/Dropbox/Datazoom/" # set actual user data path
github_folder_path <- "Amazonia_Dinamismo_Economico/build/output/"  # set github structure path 

# call raw data
base1 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_ac_numero_ocupados_por_ocupacao_2digitos.dta"))
base1 <- base1 %>% mutate(UF = "AC")
base2 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_am_numero_ocupados_por_ocupacao_2digitos.dta"))
base2 <- base2 %>% mutate(UF = "AM")
base3 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_ap_numero_ocupados_por_ocupacao_2digitos.dta"))
base3 <- base3 %>% mutate(UF = "AP")
base4 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_ma_numero_ocupados_por_ocupacao_2digitos.dta"))
base4 <- base4 %>% mutate(UF = "MA")
base5 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_mt_numero_ocupados_por_ocupacao_2digitos.dta"))
base5 <- base5 %>% mutate(UF = "MT")
base6 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_pa_numero_ocupados_por_ocupacao_2digitos.dta"))
base6 <- base6 %>% mutate(UF = "PA")
base7 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_ro_numero_ocupados_por_ocupacao_2digitos.dta"))
base7 <- base7 %>% mutate(UF = "RO")
base8 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_rr_numero_ocupados_por_ocupacao_2digitos.dta"))
base8 <- base8 %>% mutate(UF = "RR")
base9 <- read_dta(paste0(user_folder_path, github_folder_path, "_amz_to_numero_ocupados_por_ocupacao_2digitos.dta"))
base9 <- base9 %>% mutate(UF = "TO")

# append all data 
temp <- rbind(base1, base2, base3,base4,base5,base6,base7,base8,base9)

# remove rows with missing data 
temp <- na.omit(temp)
temp <- temp %>%
  filter(titulo !="")

# convert time data to quarterly
temp <- temp %>% 
  mutate(time = paste0(temp$Ano, "-",temp$Trimestre))
temp$time <- as.Date(as.yearqtr(temp$time))
temp$Trimestre <- NULL
temp$Ano <- NULL

# groups at the level: Estado e Ocupações
temp$group <- paste0(temp$UF," - ", temp$titulo)

# change column order
temp <-  temp %>% 
  relocate(group, time)

# save data at rds format
saveRDS(temp,
        file = "./data/ibge_pnadc_cod.rds")

#####################
# Build Dictionary 
#####################

# extract variables from data
columns <- colnames(temp)

# generate dictionary
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

# label variables
temp_param_table$label[1] <- "Ocupação"
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

# block variables in graphs y-axis
temp_param_table$y[1] <- FALSE # Ocupação
temp_param_table$y[11] <- FALSE # Estado
temp_param_table$y[12] <- FALSE # Trimestre-Ano
temp_param_table$y[13] <- FALSE # Fonte

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_cod_dic.csv", fileEncoding = "UTF-8")
