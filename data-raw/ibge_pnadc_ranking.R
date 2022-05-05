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

#################################################
## Atividade Econômica na Amazônia Legal
## Ouput data from:
## Dinamismo Economico na Amazonia
## github: https://github.com/FranciscoCavalcanti/Amazonia_Dinamismo_Economico
#################################################

# set path to raw data
user_folder_path <- "C:/Users/DELL/Documents/GitHub/" # set actual user data path
github_folder_path <- "Amazonia_Dinamismo_Economico/build/output/" # set github structure path

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


temp <-  temp %>% 
  group_by(titulo, time) %>%
  arrange(titulo, time) %>%
  summarise(n_ocu_cnae = sum(n_ocu_cnae),
            n_ocu_cnae_formal = sum(n_ocu_cnae_formal),
            n_ocu_cnae_informal = sum(n_ocu_cnae_informal),
            n_ocu_cnae_publico = sum(n_ocu_cnae_publico),
            n_ocu_cnae_privado = sum(n_ocu_cnae_privado)
            ) %>%
  mutate(group = titulo)

temp$titulo <- NULL
temp$UF <- NULL

# change column order
temp <-  temp %>% 
  relocate(group, time)

# save data at rds format
saveRDS(temp,
        file = "./data/ibge_pnadc_ranking_cnae.rds")

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
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = columns,
  desc = columns,
  var_group = "IBGE - PNAD Contínua",
  tipo = 1,
  categoria= "Economia", 
  subcategoria = "Mercado de trabalho"
)

# label variables
temp_param_table$label[temp_param_table$var == "group"] <- "Atividade econômica"
temp_param_table$label[temp_param_table$var == "time"] <- "Trimestre-Ano"
temp_param_table$label[temp_param_table$var == "n_ocu_cnae"] <- "Número de ocupados"
temp_param_table$label[temp_param_table$var == "n_ocu_cnae_formal"] <- "Número de ocupados no setor formal"
temp_param_table$label[temp_param_table$var == "n_ocu_cnae_informal"] <- "Número de ocupados no setor informal"
temp_param_table$label[temp_param_table$var == "n_ocu_cnae_publico"] <- "Número de ocupados no setor público"
temp_param_table$label[temp_param_table$var == "n_ocu_cnae_privado"] <- "Número de ocupados no setor privado"

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "time"] <- FALSE # Ano-Trimestre

# block variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "time"] <- FALSE # Ano-Trimestre

# allow variables in graphs size and color-axis
temp_param_table$size[temp_param_table$var == "group"] <- TRUE # Atividade econômica
temp_param_table$color[temp_param_table$var == "group"] <- TRUE # Atividade econômica

# allow variables in graphs size and color-axis

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_ranking_cnae_dic.csv", fileEncoding = "UTF-8")


#################################################
## Tipo de Ocupação na Amazônia Legal
## Ouput data from:
## Dinamismo Economico na Amazonia
## github: https://github.com/FranciscoCavalcanti/Amazonia_Dinamismo_Economico
#################################################

# set path to raw data
user_folder_path <- "C:/Users/DELL/Documents/GitHub/" # set actual user data path
github_folder_path <- "Amazonia_Dinamismo_Economico/build/output/" # set github structure path

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

# groups at the level: Estado e Tipo de Ocupação
temp$group <- paste0(temp$UF," - ", temp$titulo)


temp <-  temp %>% 
  group_by(titulo, time) %>%
  arrange(titulo, time) %>%
  summarise(n_ocu_cod = sum(n_ocu_cod),
            n_ocu_cod_formal = sum(n_ocu_cod_formal),
            n_ocu_cod_informal = sum(n_ocu_cod_informal),
            n_ocu_cod_publico = sum(n_ocu_cod_publico),
            n_ocu_cod_privado = sum(n_ocu_cod_privado)
            ) %>%
  mutate(group = titulo)

temp$titulo <- NULL
temp$UF <- NULL

# change column order
temp <-  temp %>% 
  relocate(group, time)

# save data at rds format
saveRDS(temp,
        file = "./data/ibge_pnadc_ranking_cod.rds")

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
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = columns,
  desc = columns,
  var_group = "IBGE - PNAD Contínua",
  tipo = 1,
  categoria= "Economia", 
  subcategoria = "Mercado de trabalho"
)

# label variables
temp_param_table$label[temp_param_table$var == "group"] <- "Tipo de ocupação"
temp_param_table$label[temp_param_table$var == "time"] <- "Trimestre-Ano"
temp_param_table$label[temp_param_table$var == "n_ocu_cod"] <- "Número de ocupados"
temp_param_table$label[temp_param_table$var == "n_ocu_cod_formal"] <- "Número de ocupados no setor formal"
temp_param_table$label[temp_param_table$var == "n_ocu_cod_informal"] <- "Número de ocupados no setor informal"
temp_param_table$label[temp_param_table$var == "n_ocu_cod_publico"] <- "Número de ocupados no setor público"
temp_param_table$label[temp_param_table$var == "n_ocu_cod_privado"] <- "Número de ocupados no setor privado"


# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "time"] <- FALSE # Ano-Trimestre

# block variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "time"] <- FALSE # Ano-Trimestre

# allow variables in graphs size and color-axis
temp_param_table$size[temp_param_table$var == "group"] <- TRUE # Atividade econômica
temp_param_table$color[temp_param_table$var == "group"] <- TRUE # Atividade econômica

# allow variables in graphs size and color-axis

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_ranking_cod_dic.csv", fileEncoding = "UTF-8")