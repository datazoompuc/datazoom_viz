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
base1 <- base1 %>% mutate(id = "Amazônia")
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
temp_param_table$label[1] <- "Proporção de empregados com carteira assinada"
temp_param_table$label[2] <- "Proporção de empregados sem carteira assinada"
temp_param_table$label[3] <- "Proporção de empregador"
temp_param_table$label[4] <- "Proporção conta própria"
temp_param_table$label[5] <- "Proporção conta própria que contribui para INSS"
temp_param_table$label[6] <- "Proporção conta própria que não contribui para INSS"
temp_param_table$label[7] <- "Proporção de militares"
temp_param_table$label[8] <- "Proporção home office"
temp_param_table$label[9] <- "Taxa de desemprego"
temp_param_table$label[10] <- "Taxa de ocupação"
temp_param_table$label[11] <- "Taxa de participação"
temp_param_table$label[12] <- "Taxa de informalidade"
temp_param_table$label[13] <- "Taxa de desalentados"
temp_param_table$label[14] <- "Taxa de nem-nem"
temp_param_table$label[15] <- "Número de desempregados"
temp_param_table$label[16] <- "Número de ocupados"
temp_param_table$label[17] <- "Número de informais"
temp_param_table$label[18] <- "Número de desalentados"
temp_param_table$label[19] <- "Número de nem-nem"
temp_param_table$label[20] <- "Número de empregados com carteira assinada"
temp_param_table$label[21] <- "Número de empregados sem carteira assinada"
temp_param_table$label[22] <- "Número de empregadores"
temp_param_table$label[23] <- "Número de conta própria"
temp_param_table$label[24] <- "Número de conta própria que contribui para INSS"
temp_param_table$label[25] <- "Número de conta própria que não contribui para INSS"
temp_param_table$label[26] <- "Número de militares"
temp_param_table$label[27] <- "Número de home-office"
temp_param_table$label[28] <- "Número de pessoas educação"
temp_param_table$label[29] <- "Número de "
temp_param_table$label[30] <- "Número de "
temp_param_table$label[31] <- "Número de "
temp_param_table$label[32] <- "Número de "
temp_param_table$label[33] <- "Número de "
temp_param_table$label[34] <- "Número de "
temp_param_table$label[35] <- "Número de "
temp_param_table$label[36] <- "Número de "
temp_param_table$label[37] <- "Número de "
temp_param_table$label[38] <- "Número de "
temp_param_table$label[39] <- "Número de "
temp_param_table$label[40] <- "Número de "
temp_param_table$label[41] <- "Número de "
temp_param_table$label[42] <- "Número de "
temp_param_table$label[43] <- "Número de "
temp_param_table$label[44] <- "Número de "
temp_param_table$label[45] <- "Número de "
temp_param_table$label[46] <- "Número de "
temp_param_table$label[47] <- "Número de "
temp_param_table$label[48] <- "Número de "
temp_param_table$label[49] <- "Número de "
temp_param_table$label[50] <- "Número de "
temp_param_table$label[51] <- "Número de "
temp_param_table$label[52] <- "Número de "
temp_param_table$label[53] <- "Número de "
temp_param_table$label[54] <- "Número de "
temp_param_table$label[55] <- "Número de "
temp_param_table$label[56] <- "Número de "
temp_param_table$label[57] <- "Número de "
temp_param_table$label[58] <- "Número de "
temp_param_table$label[59] <- "Número de "
temp_param_table$label[60] <- "Número de "
temp_param_table$label[61] <- "Número de "
temp_param_table$label[62] <- "Número de "
temp_param_table$label[63] <- "Número de "
temp_param_table$label[64] <- "Número de "
temp_param_table$label[65] <- "Número de "
temp_param_table$label[66] <- "Número de "
temp_param_table$label[67] <- "Número de "
temp_param_table$label[68] <- "Número de "
temp_param_table$label[69] <- "Número de "
temp_param_table$label[70] <- "Número de "
temp_param_table$label[71] <- "Número de "
temp_param_table$label[72] <- "Número de "
temp_param_table$label[73] <- "Número de "
temp_param_table$label[74] <- "Número de "
temp_param_table$label[75] <- "Número de "
temp_param_table$label[76] <- "Número de "
temp_param_table$label[77] <- "Número de "
temp_param_table$label[78] <- "Número de "
temp_param_table$label[79] <- "Número de "
temp_param_table$label[80] <- "Número de "
temp_param_table$label[81] <- "Número de "
temp_param_table$label[82] <- "Número de "
temp_param_table$label[83] <- "Número de "
temp_param_table$label[84] <- "Número de "
temp_param_table$label[85] <- "Número de "
temp_param_table$label[86] <- "Número de "
temp_param_table$label[87] <- "Número de "
temp_param_table$label[88] <- "Número de "
temp_param_table$label[89] <- "Número de "
temp_param_table$label[90] <- "Número de "
temp_param_table$label[91] <- "Número de "
temp_param_table$label[92] <- "Número de "
temp_param_table$label[93] <- "Número de "
temp_param_table$label[94] <- "Número de "
temp_param_table$label[95] <- "Número de "
temp_param_table$label[96] <- "Número de "
temp_param_table$label[97] <- "Número de "
temp_param_table$label[98] <- "Número de "
temp_param_table$label[99] <- "Número de "
temp_param_table$label[100] <- "Número de "
temp_param_table$label[101] <- "Número de "
temp_param_table$label[102] <- "Número de "
temp_param_table$label[103] <- "Número de "
temp_param_table$label[104] <- "Número de "
temp_param_table$label[105] <- "Número de "
temp_param_table$label[106] <- "Número de "
temp_param_table$label[107] <- "Número de "
temp_param_table$label[108] <- "Número de "
temp_param_table$label[109] <- "Número de "
temp_param_table$label[110] <- "Número de "
temp_param_table$label[111] <- "Número de "
temp_param_table$label[112] <- "Número de "
temp_param_table$label[113] <- "Número de "
temp_param_table$label[114] <- "Número de "
temp_param_table$label[115] <- "Número de "
temp_param_table$label[116] <- "Número de "
temp_param_table$label[117] <- "Número de "
temp_param_table$label[118] <- "Número de "
temp_param_table$label[119] <- "Número de "
temp_param_table$label[120] <- "Número de "
temp_param_table$label[121] <- "Número de "
temp_param_table$label[122] <- "Número de "
temp_param_table$label[123] <- "Número de "
temp_param_table$label[124] <- "Número de "
temp_param_table$label[125] <- "Número de "
temp_param_table$label[126] <- "Número de "
temp_param_table$label[127] <- "Número de "
temp_param_table$label[128] <- "Número de "
temp_param_table$label[129] <- "Número de "
temp_param_table$label[130] <- "Número de "
temp_param_table$label[131] <- "Número de "
temp_param_table$label[132] <- "Número de "
temp_param_table$label[133] <- "Número de "
temp_param_table$label[134] <- "Número de "
temp_param_table$label[135] <- "Número de "
temp_param_table$label[136] <- "Número de "
temp_param_table$label[137] <- "Número de "
temp_param_table$label[138] <- "Número de "
temp_param_table$label[139] <- "Número de "
temp_param_table$label[140] <- "Número de "
temp_param_table$label[141] <- "Número de "
temp_param_table$label[142] <- "Número de "
temp_param_table$label[143] <- "Número de "
temp_param_table$label[144] <- "Número de "
temp_param_table$label[145] <- "Número de "
temp_param_table$label[146] <- "Número de "
temp_param_table$label[147] <- "Número de "
temp_param_table$label[148] <- "Número de "
temp_param_table$label[149] <- "Número de "
temp_param_table$label[150] <- "Número de "
temp_param_table$label[151] <- "Número de "
temp_param_table$label[152] <- "Número de "
temp_param_table$label[153] <- "Número de nem-nem na zona urbana"

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
