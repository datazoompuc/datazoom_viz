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

#################################################
## Mercado de Trabalho na Amazônia Legal
## Ouput data from:
## Dinamismo Economico na Amazonia
## github: https://github.com/FranciscoCavalcanti/Amazonia_Mercado_Trabalho
#################################################

# set path to raw data
user_folder_path <- "C:\\Users\\Acer\\Documents\\GitHub\\" # set actual user data path
github_folder_path <- "Amazonia_Mercado_Trabalho/build/output/" # set github structure path

# call raw data
base1 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_amazonia_legal.dta"))
base1 <- base1 %>% mutate(id = "Amazônia Legal", composicao_demografica = "Todas as pessoas (PIA)")

base2 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_resto_brasil.dta"))
base2 <- base2 %>% mutate(id = "Restante do Brasil", composicao_demografica = "Todas as pessoas (PIA)")

base3 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_rondonia.dta"))
base3 <- base3 %>% mutate(id = "Rondônia", composicao_demografica = "Todas as pessoas (PIA)")

base4 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_acre.dta"))
base4 <- base4 %>% mutate(id = "Acre", composicao_demografica = "Todas as pessoas (PIA)")

base5 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_amazonas.dta"))
base5 <- base5 %>% mutate(id = "Amazonas", composicao_demografica = "Todas as pessoas (PIA)")

base6 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_roraima.dta"))
base6 <- base6 %>% mutate(id = "Roraima", composicao_demografica = "Todas as pessoas (PIA)")

base7 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_para.dta"))
base7 <- base7 %>% mutate(id = "Pará", composicao_demografica = "Todas as pessoas (PIA)")

base8 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_amapa.dta"))
base8 <- base8 %>% mutate(id = "Amapá", composicao_demografica = "Todas as pessoas (PIA)")

base9 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_tocantins.dta"))
base9 <- base9 %>% mutate(id = "Tocantins", composicao_demografica = "Todas as pessoas (PIA)")

base10 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_matogrosso.dta"))
base10 <- base10 %>% mutate(id = "Mato Grosso", composicao_demografica = "Todas as pessoas (PIA)")

# append all data
temp <- rbind(base1, base2)
temp <- rbind(temp, base2)
temp <- rbind(temp, base3)
temp <- rbind(temp, base4)
temp <- rbind(temp, base5)
temp <- rbind(temp, base6)
temp <- rbind(temp, base7)
temp <- rbind(temp, base8)
temp <- rbind(temp, base9)
temp <- rbind(temp, base10)

# convert time data to quarterly
temp <- temp %>%
  mutate(time = paste0(temp$Ano, "-", temp$Trimestre))

temp$time <- as.Date(as.yearqtr(temp$time))
temp$Trimestre <- NULL
temp$Ano <- NULL

# generate variables for each demographic composition
temp1 <- temp %>% mutate(
  taxa_de_desemprego_faixa_genero1 = ((n_de_pea_faixa_genero1 - n_de_ocupado_faixa_genero1) / n_de_pea_faixa_genero1) * 100,
  taxa_de_desemprego_faixa_genero2 = ((n_de_pea_faixa_genero2 - n_de_ocupado_faixa_genero2) / n_de_pea_faixa_genero2) * 100,
  taxa_de_desemprego_faixa_educ1 = ((n_de_pea_faixa_educ1 - n_de_ocupado_faixa_educ1) / n_de_pea_faixa_educ1) * 100,
  taxa_de_desemprego_faixa_educ2 = ((n_de_pea_faixa_educ2 - n_de_ocupado_faixa_educ2) / n_de_pea_faixa_educ2) * 100,
  taxa_de_desemprego_faixa_educ3 = ((n_de_pea_faixa_educ3 - n_de_ocupado_faixa_educ3) / n_de_pea_faixa_educ3) * 100,
  taxa_de_desemprego_faixa_educ4 = ((n_de_pea_faixa_educ4 - n_de_ocupado_faixa_educ4) / n_de_pea_faixa_educ4) * 100,
  taxa_de_desemprego_faixa_educ5 = ((n_de_pea_faixa_educ5 - n_de_ocupado_faixa_educ5) / n_de_pea_faixa_educ5) * 100,
  taxa_de_desemprego_faixa_etaria2 = ((n_de_pea_faixa_etaria2 - n_de_ocupado_faixa_etaria2) / n_de_pea_faixa_etaria2) * 100,
  taxa_de_desemprego_faixa_etaria3 = ((n_de_pea_faixa_etaria3 - n_de_ocupado_faixa_etaria3) / n_de_pea_faixa_etaria3) * 100,
  taxa_de_desemprego_faixa_etaria4 = ((n_de_pea_faixa_etaria4 - n_de_ocupado_faixa_etaria4) / n_de_pea_faixa_etaria4) * 100,
  taxa_de_desemprego_faixa_etaria5 = ((n_de_pea_faixa_etaria5 - n_de_ocupado_faixa_etaria5) / n_de_pea_faixa_etaria5) * 100,
  taxa_de_desemprego_faixa_etaria6 = ((n_de_pea_faixa_etaria6 - n_de_ocupado_faixa_etaria6) / n_de_pea_faixa_etaria6) * 100,
  taxa_de_desemprego_faixa_etaria7 = ((n_de_pea_faixa_etaria7 - n_de_ocupado_faixa_etaria7) / n_de_pea_faixa_etaria7) * 100,
  taxa_de_ocupacao_faixa_genero1 = ((n_de_ocupado_faixa_genero1) / n_faixa_genero1) * 100,
  taxa_de_ocupacao_faixa_genero2 = ((n_de_ocupado_faixa_genero2) / n_faixa_genero2) * 100,
  taxa_de_ocupacao_faixa_educ1 = ((n_de_ocupado_faixa_educ1) / n_faixa_educ1) * 100,
  taxa_de_ocupacao_faixa_educ2 = ((n_de_ocupado_faixa_educ2) / n_faixa_educ2) * 100,
  taxa_de_ocupacao_faixa_educ3 = ((n_de_ocupado_faixa_educ3) / n_faixa_educ3) * 100,
  taxa_de_ocupacao_faixa_educ4 = ((n_de_ocupado_faixa_educ4) / n_faixa_educ4) * 100,
  taxa_de_ocupacao_faixa_educ5 = ((n_de_ocupado_faixa_educ5) / n_faixa_educ5) * 100,
  taxa_de_ocupacao_faixa_etaria2 = ((n_de_ocupado_faixa_etaria2) / n_faixa_etaria2) * 100,
  taxa_de_ocupacao_faixa_etaria3 = ((n_de_ocupado_faixa_etaria3) / n_faixa_etaria3) * 100,
  taxa_de_ocupacao_faixa_etaria4 = ((n_de_ocupado_faixa_etaria4) / n_faixa_etaria4) * 100,
  taxa_de_ocupacao_faixa_etaria5 = ((n_de_ocupado_faixa_etaria5) / n_faixa_etaria5) * 100,
  taxa_de_ocupacao_faixa_etaria6 = ((n_de_ocupado_faixa_etaria6) / n_faixa_etaria6) * 100,
  taxa_de_ocupacao_faixa_etaria7 = ((n_de_ocupado_faixa_etaria7) / n_faixa_etaria7) * 100,
  taxa_de_participacao_faixa_genero1 = ((n_de_pea_faixa_genero1) / n_faixa_genero1) * 100,
  taxa_de_participacao_faixa_genero2 = ((n_de_pea_faixa_genero2) / n_faixa_genero2) * 100,
  taxa_de_participacao_faixa_educ1 = ((n_de_pea_faixa_educ1) / n_faixa_educ1) * 100,
  taxa_de_participacao_faixa_educ2 = ((n_de_pea_faixa_educ2) / n_faixa_educ2) * 100,
  taxa_de_participacao_faixa_educ3 = ((n_de_pea_faixa_educ3) / n_faixa_educ3) * 100,
  taxa_de_participacao_faixa_educ4 = ((n_de_pea_faixa_educ4) / n_faixa_educ4) * 100,
  taxa_de_participacao_faixa_educ5 = ((n_de_pea_faixa_educ5) / n_faixa_educ5) * 100,
  taxa_de_participacao_faixa_etaria2 = ((n_de_pea_faixa_etaria2) / n_faixa_etaria2) * 100,
  taxa_de_participacao_faixa_etaria3 = ((n_de_pea_faixa_etaria3) / n_faixa_etaria3) * 100,
  taxa_de_participacao_faixa_etaria4 = ((n_de_pea_faixa_etaria4) / n_faixa_etaria4) * 100,
  taxa_de_participacao_faixa_etaria5 = ((n_de_pea_faixa_etaria5) / n_faixa_etaria5) * 100,
  taxa_de_participacao_faixa_etaria6 = ((n_de_pea_faixa_etaria6) / n_faixa_etaria6) * 100,
  taxa_de_participacao_faixa_etaria7 = ((n_de_pea_faixa_etaria7) / n_faixa_etaria7) * 100,
  taxa_de_informalidade_faixa_genero1 = ((n_de_informal_faixa_genero1) / n_de_ocupado_faixa_genero1) * 100,
  taxa_de_informalidade_faixa_genero2 = ((n_de_informal_faixa_genero2) / n_de_ocupado_faixa_genero2) * 100,
  taxa_de_informalidade_faixa_educ1 = ((n_de_informal_faixa_educ1) / n_de_ocupado_faixa_educ1) * 100,
  taxa_de_informalidade_faixa_educ2 = ((n_de_informal_faixa_educ2) / n_de_ocupado_faixa_educ2) * 100,
  taxa_de_informalidade_faixa_educ3 = ((n_de_informal_faixa_educ3) / n_de_ocupado_faixa_educ3) * 100,
  taxa_de_informalidade_faixa_educ4 = ((n_de_informal_faixa_educ4) / n_de_ocupado_faixa_educ4) * 100,
  taxa_de_informalidade_faixa_educ5 = ((n_de_informal_faixa_educ5) / n_de_ocupado_faixa_educ5) * 100,
  taxa_de_informalidade_faixa_etaria2 = ((n_de_informal_faixa_etaria2) / n_de_ocupado_faixa_etaria2) * 100,
  taxa_de_informalidade_faixa_etaria3 = ((n_de_informal_faixa_etaria3) / n_de_ocupado_faixa_etaria3) * 100,
  taxa_de_informalidade_faixa_etaria4 = ((n_de_informal_faixa_etaria4) / n_de_ocupado_faixa_etaria4) * 100,
  taxa_de_informalidade_faixa_etaria5 = ((n_de_informal_faixa_etaria5) / n_de_ocupado_faixa_etaria5) * 100,
  taxa_de_informalidade_faixa_etaria6 = ((n_de_informal_faixa_etaria6) / n_de_ocupado_faixa_etaria6) * 100,
  taxa_de_informalidade_faixa_etaria7 = ((n_de_informal_faixa_etaria7) / n_de_ocupado_faixa_etaria7) * 100,
  taxa_de_desalento_faixa_genero1 = ((n_de_desa_faixa_genero1) / n_faixa_genero1) * 100,
  taxa_de_desalento_faixa_genero2 = ((n_de_desa_faixa_genero2) / n_faixa_genero2) * 100,
  taxa_de_desalento_faixa_educ1 = ((n_de_desa_faixa_educ1) / n_faixa_educ1) * 100,
  taxa_de_desalento_faixa_educ2 = ((n_de_desa_faixa_educ2) / n_faixa_educ2) * 100,
  taxa_de_desalento_faixa_educ3 = ((n_de_desa_faixa_educ3) / n_faixa_educ3) * 100,
  taxa_de_desalento_faixa_educ4 = ((n_de_desa_faixa_educ4) / n_faixa_educ4) * 100,
  taxa_de_desalento_faixa_educ5 = ((n_de_desa_faixa_educ5) / n_faixa_educ5) * 100,
  taxa_de_desalento_faixa_etaria2 = ((n_de_desa_faixa_etaria2) / n_faixa_etaria2) * 100,
  taxa_de_desalento_faixa_etaria3 = ((n_de_desa_faixa_etaria3) / n_faixa_etaria3) * 100,
  taxa_de_desalento_faixa_etaria4 = ((n_de_desa_faixa_etaria4) / n_faixa_etaria4) * 100,
  taxa_de_desalento_faixa_etaria5 = ((n_de_desa_faixa_etaria5) / n_faixa_etaria5) * 100,
  taxa_de_desalento_faixa_etaria6 = ((n_de_desa_faixa_etaria6) / n_faixa_etaria6) * 100,
  taxa_de_desalento_faixa_etaria7 = ((n_de_desa_faixa_etaria7) / n_faixa_etaria7) * 100,
  taxa_de_nemnem_faixa_genero1 = ((n_de_nemnem_faixa_genero1) / n_faixa_genero1) * 100,
  taxa_de_nemnem_faixa_genero2 = ((n_de_nemnem_faixa_genero2) / n_faixa_genero2) * 100,
  taxa_de_nemnem_faixa_educ1 = ((n_de_nemnem_faixa_educ1) / n_faixa_educ1) * 100,
  taxa_de_nemnem_faixa_educ2 = ((n_de_nemnem_faixa_educ2) / n_faixa_educ2) * 100,
  taxa_de_nemnem_faixa_educ3 = ((n_de_nemnem_faixa_educ3) / n_faixa_educ3) * 100,
  taxa_de_nemnem_faixa_educ4 = ((n_de_nemnem_faixa_educ4) / n_faixa_educ4) * 100,
  taxa_de_nemnem_faixa_educ5 = ((n_de_nemnem_faixa_educ5) / n_faixa_educ5) * 100,
  taxa_de_nemnem_faixa_etaria2 = ((n_de_nemnem_faixa_etaria2) / n_faixa_etaria2) * 100,
  taxa_de_nemnem_faixa_etaria3 = ((n_de_nemnem_faixa_etaria3) / n_faixa_etaria3) * 100,
  taxa_de_nemnem_faixa_etaria4 = ((n_de_nemnem_faixa_etaria4) / n_faixa_etaria4) * 100,
  taxa_de_nemnem_faixa_etaria5 = ((n_de_nemnem_faixa_etaria5) / n_faixa_etaria5) * 100,
  taxa_de_nemnem_faixa_etaria6 = ((n_de_nemnem_faixa_etaria6) / n_faixa_etaria6) * 100,
  taxa_de_nemnem_faixa_etaria7 = ((n_de_nemnem_faixa_etaria7) / n_faixa_etaria7) * 100
)

# convert every data set from wide to long format and then merge altogether
taxa_de_desemprego_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("taxa_de_desemprego_"),
  names_to = "composicao",
  names_prefix = "taxa_de_desemprego_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    taxa_de_desemprego = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

taxa_de_ocupacao_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("taxa_de_ocupacao_"),
  names_to = "composicao",
  names_prefix = "taxa_de_ocupacao_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    taxa_de_ocupacao = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

taxa_de_informalidade_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("taxa_de_informalidade_"),
  names_to = "composicao",
  names_prefix = "taxa_de_informalidade_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    taxa_de_informalidade = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

taxa_de_participacao_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("taxa_de_participacao_"),
  names_to = "composicao",
  names_prefix = "taxa_de_participacao_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    taxa_de_participacao = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

taxa_de_nemnem_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("taxa_de_nemnem_"),
  names_to = "composicao",
  names_prefix = "taxa_de_nemnem_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    taxa_de_nemnem = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

taxa_de_desalento_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("taxa_de_desalento_"),
  names_to = "composicao",
  names_prefix = "taxa_de_desalento_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    taxa_de_desalento = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

# merge data altogether
mycolnames <- c("time", "id", "composicao_demografica")
merge_datasets <- right_join(taxa_de_desemprego_por_faixa, taxa_de_informalidade_por_faixa, by = mycolnames)
merge_datasets <- right_join(merge_datasets, taxa_de_ocupacao_por_faixa, by = mycolnames)
merge_datasets <- right_join(merge_datasets, taxa_de_participacao_por_faixa, by = mycolnames)
merge_datasets <- right_join(merge_datasets, taxa_de_desalento_por_faixa, by = mycolnames)
merge_datasets <- right_join(merge_datasets, taxa_de_nemnem_por_faixa, by = mycolnames)

new_data <- bind_rows(temp, merge_datasets) %>%
  select(
    id,
    composicao_demografica,
    time,
    taxa_de_informalidade,
    taxa_de_participacao,
    taxa_de_ocupacao,
    taxa_de_desemprego,
    taxa_de_desalento,
    taxa_de_nemnem
  ) %>%
  group_by(id, composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

# recover
temp <- new_data

# groups at the level:
temp$group <- temp$id

# edit names in data
temp$composicao_demografica[temp$composicao_demografica == "faixa_educ1"] <- "Nível escolar 0 anos de estudo (sem instrução)"
temp$composicao_demografica[temp$composicao_demografica == "faixa_educ2"] <- "Nível escolar 1 a 7 anos de estudo"
temp$composicao_demografica[temp$composicao_demografica == "faixa_educ3"] <- "Nível escolar 8 a 11 anos de estudo"
temp$composicao_demografica[temp$composicao_demografica == "faixa_educ4"] <- "Nível escolar 9 a 14 anos de estudo"
temp$composicao_demografica[temp$composicao_demografica == "faixa_educ5"] <- "Nível escolar mais de 15 anos de estudo"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria2"] <- "Faixa étaria entre 18 e 24 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria3"] <- "Faixa étaria entre 25 e 29 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria4"] <- "Faixa étaria entre 30 e 39 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria5"] <- "Faixa étaria entre 40 e 49 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria6"] <- "Faixa étaria entre 50 e 59 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria7"] <- "Faixa étaria maior que 60 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_genero2"] <- "Sexo feminino"
temp$composicao_demografica[temp$composicao_demografica == "faixa_genero1"] <- "Sexo masculino"

# limiting decimal places
temp <- temp %>%
  mutate(across(where(is.numeric), ~ as.numeric(formatC(., digits = 2, format = "f")))) %>%
  group_by(id, composicao_demografica) %>%
  arrange(id, composicao_demografica, time)


# save at rds format
saveRDS(temp,
  file = "./data/ibge_pnadc_trabalho.rds"
)

#####################
# Build Dictionary
#####################

# call data
temp <- readRDS("./data/ibge_pnadc_trabalho.rds")

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
  categoria = "Economia",
  subcategoria = "Mercado de Trabalho"
)

# label variables
temp_param_table$label[temp_param_table$var == "id"] <- "Recorte regional"
temp_param_table$label[temp_param_table$var == "time"] <- "Ano-Trimestre"
temp_param_table$label[temp_param_table$var == "group"] <- "Recorte regional"
temp_param_table$label[temp_param_table$var == "composicao_demografica"] <- "Composição demográfica"
temp_param_table$label[temp_param_table$var == "taxa_de_desemprego"] <- "Taxa de desemprego (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_ocupacao"] <- "Taxa de ocupação (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_participacao"] <- "Taxa de participação (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_informalidade"] <- "Taxa de informalidade (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_desalento"] <- "Taxa de desalentados (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_nemnem"] <- "Taxa de Nem-Nem (%)"

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "id"] <- FALSE
temp_param_table$y[temp_param_table$var == "composicao_demografica"] <- FALSE
temp_param_table$y[temp_param_table$var == "time"] <- FALSE
temp_param_table$y[temp_param_table$var == "group"] <- FALSE

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_trabalho_dic.csv", fileEncoding = "UTF-8")

##############################
# Build Dictionary in English
#############################

# call data
temp <- readRDS("./data/ibge_pnadc_trabalho.rds")

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
    categoria = "Economia",
    subcategoria = "Mercado de Trabalho"
)

# label variables
temp_param_table$label[temp_param_table$var == "id"] <- "Region"
temp_param_table$label[temp_param_table$var == "time"] <- "Quarter-year"
temp_param_table$label[temp_param_table$var == "group"] <- "Region"
temp_param_table$label[temp_param_table$var == "composicao_demografica"] <- "Demographic composition"
temp_param_table$label[temp_param_table$var == "taxa_de_desemprego"] <- "Unemployment rate (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_ocupacao"] <- "Employment rate (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_participacao"] <- " Labor participation rate (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_informalidade"] <- "Informality rate (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_desalento"] <- "Rate of discouragement (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_nemnem"] <- "Neither-Nor rate (%)"

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "id"] <- FALSE
temp_param_table$y[temp_param_table$var == "composicao_demografica"] <- FALSE
temp_param_table$y[temp_param_table$var == "time"] <- FALSE
temp_param_table$y[temp_param_table$var == "group"] <- FALSE

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_trabalho_dic_en.csv", fileEncoding = "UTF-8")

#################################################
## Inserção no Mercado de Trabalho na Amazônia Legal
## Input data from:
## github: https://github.com/FranciscoCavalcanti/Amazonia_Mercado_Trabalho
#################################################

# set path to raw data
user_folder_path <- "C:\\Users\\Acer\\Documents\\GitHub\\" # set actual user data path
github_folder_path <- "Amazonia_Mercado_Trabalho/build/output/" # set github structure path

# call raw data
base1 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_amazonia_legal.dta"))
base1 <- base1 %>% mutate(id = "Amazônia Legal", composicao_demografica = "Todas as pessoas (PIA)")

base2 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_resto_brasil.dta"))
base2 <- base2 %>% mutate(id = "Restante do Brasil", composicao_demografica = "Todas as pessoas (PIA)")

base3 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_rondonia.dta"))
base3 <- base3 %>% mutate(id = "Rondônia", composicao_demografica = "Todas as pessoas (PIA)")

base4 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_acre.dta"))
base4 <- base4 %>% mutate(id = "Acre", composicao_demografica = "Todas as pessoas (PIA)")

base5 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_amazonas.dta"))
base5 <- base5 %>% mutate(id = "Amazonas", composicao_demografica = "Todas as pessoas (PIA)")

base6 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_roraima.dta"))
base6 <- base6 %>% mutate(id = "Roraima", composicao_demografica = "Todas as pessoas (PIA)")

base7 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_para.dta"))
base7 <- base7 %>% mutate(id = "Pará", composicao_demografica = "Todas as pessoas (PIA)")

base8 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_amapa.dta"))
base8 <- base8 %>% mutate(id = "Amapá", composicao_demografica = "Todas as pessoas (PIA)")

base9 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_tocantins.dta"))
base9 <- base9 %>% mutate(id = "Tocantins", composicao_demografica = "Todas as pessoas (PIA)")

base10 <- read_dta(paste0(user_folder_path, github_folder_path, "_estrutura_emprego_matogrosso.dta"))
base10 <- base10 %>% mutate(id = "Mato Grosso", composicao_demografica = "Todas as pessoas (PIA)")

# append all data
temp <- rbind(base1, base2)
temp <- rbind(temp, base2)
temp <- rbind(temp, base3)
temp <- rbind(temp, base4)
temp <- rbind(temp, base5)
temp <- rbind(temp, base6)
temp <- rbind(temp, base7)
temp <- rbind(temp, base8)
temp <- rbind(temp, base9)
temp <- rbind(temp, base10)

# convert time data to quarterly
temp <- temp %>%
  mutate(time = paste0(temp$Ano, "-", temp$Trimestre))

temp$time <- as.Date(as.yearqtr(temp$time))
temp$Trimestre <- NULL
temp$Ano <- NULL

# generate variables for each demographic composition
temp1 <- temp %>% mutate(
  taxa_de_informalidade_faixa_genero1 = ((n_de_informal_faixa_genero1) / n_de_ocupado_faixa_genero1) * 100,
  taxa_de_informalidade_faixa_genero2 = ((n_de_informal_faixa_genero2) / n_de_ocupado_faixa_genero2) * 100,
  taxa_de_informalidade_faixa_educ1 = ((n_de_informal_faixa_educ1) / n_de_ocupado_faixa_educ1) * 100,
  taxa_de_informalidade_faixa_educ2 = ((n_de_informal_faixa_educ2) / n_de_ocupado_faixa_educ2) * 100,
  taxa_de_informalidade_faixa_educ3 = ((n_de_informal_faixa_educ3) / n_de_ocupado_faixa_educ3) * 100,
  taxa_de_informalidade_faixa_educ4 = ((n_de_informal_faixa_educ4) / n_de_ocupado_faixa_educ4) * 100,
  taxa_de_informalidade_faixa_educ5 = ((n_de_informal_faixa_educ5) / n_de_ocupado_faixa_educ5) * 100,
  taxa_de_informalidade_faixa_etaria2 = ((n_de_informal_faixa_etaria2) / n_de_ocupado_faixa_etaria2) * 100,
  taxa_de_informalidade_faixa_etaria3 = ((n_de_informal_faixa_etaria3) / n_de_ocupado_faixa_etaria3) * 100,
  taxa_de_informalidade_faixa_etaria4 = ((n_de_informal_faixa_etaria4) / n_de_ocupado_faixa_etaria4) * 100,
  taxa_de_informalidade_faixa_etaria5 = ((n_de_informal_faixa_etaria5) / n_de_ocupado_faixa_etaria5) * 100,
  taxa_de_informalidade_faixa_etaria6 = ((n_de_informal_faixa_etaria6) / n_de_ocupado_faixa_etaria6) * 100,
  taxa_de_informalidade_faixa_etaria7 = ((n_de_informal_faixa_etaria7) / n_de_ocupado_faixa_etaria7) * 100,
  prop_empregadoCC_faixa_genero1 = ((n_de_empregadoCC_faixa_genero1) / n_de_ocupado_faixa_genero1) * 100,
  prop_empregadoCC_faixa_genero2 = ((n_de_empregadoCC_faixa_genero2) / n_de_ocupado_faixa_genero2) * 100,
  prop_empregadoCC_faixa_educ1 = ((n_de_empregadoCC_faixa_educ1) / n_de_ocupado_faixa_educ1) * 100,
  prop_empregadoCC_faixa_educ2 = ((n_de_empregadoCC_faixa_educ2) / n_de_ocupado_faixa_educ2) * 100,
  prop_empregadoCC_faixa_educ3 = ((n_de_empregadoCC_faixa_educ3) / n_de_ocupado_faixa_educ3) * 100,
  prop_empregadoCC_faixa_educ4 = ((n_de_empregadoCC_faixa_educ4) / n_de_ocupado_faixa_educ4) * 100,
  prop_empregadoCC_faixa_educ5 = ((n_de_empregadoCC_faixa_educ5) / n_de_ocupado_faixa_educ5) * 100,
  prop_empregadoCC_faixa_etaria2 = ((n_de_empregadoCC_faixa_etaria2) / n_de_ocupado_faixa_etaria2) * 100,
  prop_empregadoCC_faixa_etaria3 = ((n_de_empregadoCC_faixa_etaria3) / n_de_ocupado_faixa_etaria3) * 100,
  prop_empregadoCC_faixa_etaria4 = ((n_de_empregadoCC_faixa_etaria4) / n_de_ocupado_faixa_etaria4) * 100,
  prop_empregadoCC_faixa_etaria5 = ((n_de_empregadoCC_faixa_etaria5) / n_de_ocupado_faixa_etaria5) * 100,
  prop_empregadoCC_faixa_etaria6 = ((n_de_empregadoCC_faixa_etaria6) / n_de_ocupado_faixa_etaria6) * 100,
  prop_empregadoCC_faixa_etaria7 = ((n_de_empregadoCC_faixa_etaria7) / n_de_ocupado_faixa_etaria7) * 100,
  prop_empregadoSC_faixa_genero1 = ((n_de_empregadoSC_faixa_genero1) / n_de_ocupado_faixa_genero1) * 100,
  prop_empregadoSC_faixa_genero2 = ((n_de_empregadoSC_faixa_genero2) / n_de_ocupado_faixa_genero2) * 100,
  prop_empregadoSC_faixa_educ1 = ((n_de_empregadoSC_faixa_educ1) / n_de_ocupado_faixa_educ1) * 100,
  prop_empregadoSC_faixa_educ2 = ((n_de_empregadoSC_faixa_educ2) / n_de_ocupado_faixa_educ2) * 100,
  prop_empregadoSC_faixa_educ3 = ((n_de_empregadoSC_faixa_educ3) / n_de_ocupado_faixa_educ3) * 100,
  prop_empregadoSC_faixa_educ4 = ((n_de_empregadoSC_faixa_educ4) / n_de_ocupado_faixa_educ4) * 100,
  prop_empregadoSC_faixa_educ5 = ((n_de_empregadoSC_faixa_educ5) / n_de_ocupado_faixa_educ5) * 100,
  prop_empregadoSC_faixa_etaria2 = ((n_de_empregadoSC_faixa_etaria2) / n_de_ocupado_faixa_etaria2) * 100,
  prop_empregadoSC_faixa_etaria3 = ((n_de_empregadoSC_faixa_etaria3) / n_de_ocupado_faixa_etaria3) * 100,
  prop_empregadoSC_faixa_etaria4 = ((n_de_empregadoSC_faixa_etaria4) / n_de_ocupado_faixa_etaria4) * 100,
  prop_empregadoSC_faixa_etaria5 = ((n_de_empregadoSC_faixa_etaria5) / n_de_ocupado_faixa_etaria5) * 100,
  prop_empregadoSC_faixa_etaria6 = ((n_de_empregadoSC_faixa_etaria6) / n_de_ocupado_faixa_etaria6) * 100,
  prop_empregadoSC_faixa_etaria7 = ((n_de_empregadoSC_faixa_etaria7) / n_de_ocupado_faixa_etaria7) * 100,
  prop_empregador_faixa_genero1 = ((n_de_empregador_faixa_genero1) / n_de_ocupado_faixa_genero1) * 100,
  prop_empregador_faixa_genero2 = ((n_de_empregador_faixa_genero2) / n_de_ocupado_faixa_genero2) * 100,
  prop_empregador_faixa_educ1 = ((n_de_empregador_faixa_educ1) / n_de_ocupado_faixa_educ1) * 100,
  prop_empregador_faixa_educ2 = ((n_de_empregador_faixa_educ2) / n_de_ocupado_faixa_educ2) * 100,
  prop_empregador_faixa_educ3 = ((n_de_empregador_faixa_educ3) / n_de_ocupado_faixa_educ3) * 100,
  prop_empregador_faixa_educ4 = ((n_de_empregador_faixa_educ4) / n_de_ocupado_faixa_educ4) * 100,
  prop_empregador_faixa_educ5 = ((n_de_empregador_faixa_educ5) / n_de_ocupado_faixa_educ5) * 100,
  prop_empregador_faixa_etaria2 = ((n_de_empregador_faixa_etaria2) / n_de_ocupado_faixa_etaria2) * 100,
  prop_empregador_faixa_etaria3 = ((n_de_empregador_faixa_etaria3) / n_de_ocupado_faixa_etaria3) * 100,
  prop_empregador_faixa_etaria4 = ((n_de_empregador_faixa_etaria4) / n_de_ocupado_faixa_etaria4) * 100,
  prop_empregador_faixa_etaria5 = ((n_de_empregador_faixa_etaria5) / n_de_ocupado_faixa_etaria5) * 100,
  prop_empregador_faixa_etaria6 = ((n_de_empregador_faixa_etaria6) / n_de_ocupado_faixa_etaria6) * 100,
  prop_empregador_faixa_etaria7 = ((n_de_empregador_faixa_etaria7) / n_de_ocupado_faixa_etaria7) * 100,
  prop_cpropriaC_faixa_genero1 = ((n_de_cpropriaC_faixa_genero1) / n_de_ocupado_faixa_genero1) * 100,
  prop_cpropriaC_faixa_genero2 = ((n_de_cpropriaC_faixa_genero2) / n_de_ocupado_faixa_genero2) * 100,
  prop_cpropriaC_faixa_educ1 = ((n_de_cpropriaC_faixa_educ1) / n_de_ocupado_faixa_educ1) * 100,
  prop_cpropriaC_faixa_educ2 = ((n_de_cpropriaC_faixa_educ2) / n_de_ocupado_faixa_educ2) * 100,
  prop_cpropriaC_faixa_educ3 = ((n_de_cpropriaC_faixa_educ3) / n_de_ocupado_faixa_educ3) * 100,
  prop_cpropriaC_faixa_educ4 = ((n_de_cpropriaC_faixa_educ4) / n_de_ocupado_faixa_educ4) * 100,
  prop_cpropriaC_faixa_educ5 = ((n_de_cpropriaC_faixa_educ5) / n_de_ocupado_faixa_educ5) * 100,
  prop_cpropriaC_faixa_etaria2 = ((n_de_cpropriaC_faixa_etaria2) / n_de_ocupado_faixa_etaria2) * 100,
  prop_cpropriaC_faixa_etaria3 = ((n_de_cpropriaC_faixa_etaria3) / n_de_ocupado_faixa_etaria3) * 100,
  prop_cpropriaC_faixa_etaria4 = ((n_de_cpropriaC_faixa_etaria4) / n_de_ocupado_faixa_etaria4) * 100,
  prop_cpropriaC_faixa_etaria5 = ((n_de_cpropriaC_faixa_etaria5) / n_de_ocupado_faixa_etaria5) * 100,
  prop_cpropriaC_faixa_etaria6 = ((n_de_cpropriaC_faixa_etaria6) / n_de_ocupado_faixa_etaria6) * 100,
  prop_cpropriaC_faixa_etaria7 = ((n_de_cpropriaC_faixa_etaria7) / n_de_ocupado_faixa_etaria7) * 100,
  prop_cpropriaNc_faixa_genero1 = ((n_de_cpropriaNc_faixa_genero1) / n_de_ocupado_faixa_genero1) * 100,
  prop_cpropriaNc_faixa_genero2 = ((n_de_cpropriaNc_faixa_genero2) / n_de_ocupado_faixa_genero2) * 100,
  prop_cpropriaNc_faixa_educ1 = ((n_de_cpropriaNc_faixa_educ1) / n_de_ocupado_faixa_educ1) * 100,
  prop_cpropriaNc_faixa_educ2 = ((n_de_cpropriaNc_faixa_educ2) / n_de_ocupado_faixa_educ2) * 100,
  prop_cpropriaNc_faixa_educ3 = ((n_de_cpropriaNc_faixa_educ3) / n_de_ocupado_faixa_educ3) * 100,
  prop_cpropriaNc_faixa_educ4 = ((n_de_cpropriaNc_faixa_educ4) / n_de_ocupado_faixa_educ4) * 100,
  prop_cpropriaNc_faixa_educ5 = ((n_de_cpropriaNc_faixa_educ5) / n_de_ocupado_faixa_educ5) * 100,
  prop_cpropriaNc_faixa_etaria2 = ((n_de_cpropriaNc_faixa_etaria2) / n_de_ocupado_faixa_etaria2) * 100,
  prop_cpropriaNc_faixa_etaria3 = ((n_de_cpropriaNc_faixa_etaria3) / n_de_ocupado_faixa_etaria3) * 100,
  prop_cpropriaNc_faixa_etaria4 = ((n_de_cpropriaNc_faixa_etaria4) / n_de_ocupado_faixa_etaria4) * 100,
  prop_cpropriaNc_faixa_etaria5 = ((n_de_cpropriaNc_faixa_etaria5) / n_de_ocupado_faixa_etaria5) * 100,
  prop_cpropriaNc_faixa_etaria6 = ((n_de_cpropriaNc_faixa_etaria6) / n_de_ocupado_faixa_etaria6) * 100,
  prop_cpropriaNc_faixa_etaria7 = ((n_de_cpropriaNc_faixa_etaria7) / n_de_ocupado_faixa_etaria7) * 100,
  prop_militar_faixa_genero1 = ((n_de_militar_faixa_genero1) / n_de_ocupado_faixa_genero1) * 100,
  prop_militar_faixa_genero2 = ((n_de_militar_faixa_genero2) / n_de_ocupado_faixa_genero2) * 100,
  prop_militar_faixa_educ1 = ((n_de_militar_faixa_educ1) / n_de_ocupado_faixa_educ1) * 100,
  prop_militar_faixa_educ2 = ((n_de_militar_faixa_educ2) / n_de_ocupado_faixa_educ2) * 100,
  prop_militar_faixa_educ3 = ((n_de_militar_faixa_educ3) / n_de_ocupado_faixa_educ3) * 100,
  prop_militar_faixa_educ4 = ((n_de_militar_faixa_educ4) / n_de_ocupado_faixa_educ4) * 100,
  prop_militar_faixa_educ5 = ((n_de_militar_faixa_educ5) / n_de_ocupado_faixa_educ5) * 100,
  prop_militar_faixa_etaria2 = ((n_de_militar_faixa_etaria2) / n_de_ocupado_faixa_etaria2) * 100,
  prop_militar_faixa_etaria3 = ((n_de_militar_faixa_etaria3) / n_de_ocupado_faixa_etaria3) * 100,
  prop_militar_faixa_etaria4 = ((n_de_militar_faixa_etaria4) / n_de_ocupado_faixa_etaria4) * 100,
  prop_militar_faixa_etaria5 = ((n_de_militar_faixa_etaria5) / n_de_ocupado_faixa_etaria5) * 100,
  prop_militar_faixa_etaria6 = ((n_de_militar_faixa_etaria6) / n_de_ocupado_faixa_etaria6) * 100,
  prop_militar_faixa_etaria7 = ((n_de_militar_faixa_etaria7) / n_de_ocupado_faixa_etaria7) * 100
)

# convert every data set from wide to long format and then merge altogether
taxa_de_informalidade_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("taxa_de_informalidade_"),
  names_to = "composicao",
  names_prefix = "taxa_de_informalidade_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    taxa_de_informalidade = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

prop_empregadoCC_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("prop_empregadoCC_"),
  names_to = "composicao",
  names_prefix = "prop_empregadoCC_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    prop_empregadoCC = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

prop_empregadoSC_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("prop_empregadoSC_"),
  names_to = "composicao",
  names_prefix = "prop_empregadoSC_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    prop_empregadoSC = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

prop_empregador_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("prop_empregador_"),
  names_to = "composicao",
  names_prefix = "prop_empregador_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    prop_empregador = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

prop_cpropriaC_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("prop_cpropriaC_"),
  names_to = "composicao",
  names_prefix = "prop_cpropriaC_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    prop_cpropriaC = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

prop_cpropriaNc_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("prop_cpropriaNc_"),
  names_to = "composicao",
  names_prefix = "prop_cpropriaNc_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    prop_cpropriaNc = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

prop_militar_por_faixa <- tidyr::pivot_longer(temp1,
  cols = starts_with("prop_militar_"),
  names_to = "composicao",
  names_prefix = "prop_militar_",
  values_to = "xxx",
  names_repair = "minimal"
) %>%
  select("time", "id", "composicao", starts_with("xx")) %>%
  rename(
    prop_militar = xxx,
    composicao_demografica = composicao
  ) %>%
  group_by(composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

# merge data altogether
mycolnames <- c("time", "id", "composicao_demografica")
merge_datasets <- right_join(prop_empregadoCC_por_faixa, prop_empregadoSC_por_faixa, by = mycolnames)
merge_datasets <- right_join(merge_datasets, prop_empregador_por_faixa, by = mycolnames)
merge_datasets <- right_join(merge_datasets, prop_cpropriaC_por_faixa, by = mycolnames)
merge_datasets <- right_join(merge_datasets, prop_cpropriaNc_por_faixa, by = mycolnames)
merge_datasets <- right_join(merge_datasets, prop_militar_por_faixa, by = mycolnames)
merge_datasets <- right_join(merge_datasets, taxa_de_informalidade_por_faixa, by = mycolnames)

new_data <- bind_rows(temp, merge_datasets) %>%
  select(
    id,
    composicao_demografica,
    time,
    prop_empregadoCC,
    prop_empregadoSC,
    prop_empregador,
    prop_cpropriaC,
    prop_cpropriaNc,
    prop_militar,
    taxa_de_informalidade
  ) %>%
  group_by(id, composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

# recover
temp <- new_data

# groups at the level:
temp$group <- temp$id

# edit names in data
temp$composicao_demografica[temp$composicao_demografica == "faixa_educ1"] <- "Nível escolar 0 anos de estudo (sem instrução)"
temp$composicao_demografica[temp$composicao_demografica == "faixa_educ2"] <- "Nível escolar 1 a 7 anos de estudo"
temp$composicao_demografica[temp$composicao_demografica == "faixa_educ3"] <- "Nível escolar 8 a 11 anos de estudo"
temp$composicao_demografica[temp$composicao_demografica == "faixa_educ4"] <- "Nível escolar 9 a 14 anos de estudo"
temp$composicao_demografica[temp$composicao_demografica == "faixa_educ5"] <- "Nível escolar mais de 15 anos de estudo"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria2"] <- "Faixa étaria entre 18 e 24 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria3"] <- "Faixa étaria entre 25 e 29 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria4"] <- "Faixa étaria entre 30 e 39 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria5"] <- "Faixa étaria entre 40 e 49 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria6"] <- "Faixa étaria entre 50 e 59 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_etaria7"] <- "Faixa étaria maior que 60 anos"
temp$composicao_demografica[temp$composicao_demografica == "faixa_genero2"] <- "Sexo feminino"
temp$composicao_demografica[temp$composicao_demografica == "faixa_genero1"] <- "Sexo masculino"

# limiting decimal places
temp <- temp %>%
  mutate(across(where(is.numeric), ~ as.numeric(formatC(., digits = 2, format = "f")))) %>%
  group_by(id, composicao_demografica) %>%
  arrange(id, composicao_demografica, time)

# save at rds format
saveRDS(temp,
  file = "./data/ibge_pnadc_trabalho_insercao.rds"
)

#####################
# Build Dictionary
#####################

# call data
temp <- readRDS("./data/ibge_pnadc_trabalho_insercao.rds")

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
  categoria = "Economia",
  subcategoria = "Inserção no Trabalho"
)

# label variables
temp_param_table$label[temp_param_table$var == "id"] <- "Recorte regional"
temp_param_table$label[temp_param_table$var == "time"] <- "Ano-Trimestre"
temp_param_table$label[temp_param_table$var == "group"] <- "Recorte regional"
temp_param_table$label[temp_param_table$var == "composicao_demografica"] <- "Composição demográfica"
temp_param_table$label[temp_param_table$var == "prop_empregadoCC"] <- "Proporção de com carteira em relação aos ocupados (%)"
temp_param_table$label[temp_param_table$var == "prop_empregadoSC"] <- "Proporção de sem carteira em relação aos ocupados (%)"
temp_param_table$label[temp_param_table$var == "prop_empregador"] <- "Proporção de empregadores em relação aos ocupados (%)"
temp_param_table$label[temp_param_table$var == "prop_cpropriaC"] <- "Proporção de conta própria que contribui em relação aos ocupados (%)"
temp_param_table$label[temp_param_table$var == "prop_cpropriaNc"] <- "Proporção de conta própria que não contribui em relação aos ocupados (%)"
temp_param_table$label[temp_param_table$var == "prop_militar"] <- "Proporção servidores públicos e militares em relação aos ocupados (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_informalidade"] <- "Taxa de informalidade (%)"

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "id"] <- FALSE
temp_param_table$y[temp_param_table$var == "composicao_demografica"] <- FALSE
temp_param_table$y[temp_param_table$var == "time"] <- FALSE
temp_param_table$y[temp_param_table$var == "group"] <- FALSE

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_trabalho_insercao_dic.csv", fileEncoding = "UTF-8")

#############################
# Build Dictionary in English
#############################

# call data
temp <- readRDS("./data/ibge_pnadc_trabalho_insercao.rds")

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
    categoria = "Economia",
    subcategoria = "Inserção no Trabalho"
)

# relabel variables
temp_param_table$label[temp_param_table$var == "id"] <- "Region"
temp_param_table$label[temp_param_table$var == "time"] <- "Quarter-year"
temp_param_table$label[temp_param_table$var == "group"] <- "Region"
temp_param_table$label[temp_param_table$var == "composicao_demografica"] <- "Demographic composition"
temp_param_table$label[temp_param_table$var == "prop_empregadoCC"] <- "Proportion of people with a formal contract in relation to employed persons (%)"
temp_param_table$label[temp_param_table$var == "prop_empregadoSC"] <- "Proportion of people without a formal contract in relation to employed persons (%)"
temp_param_table$label[temp_param_table$var == "prop_empregador"] <- "Proportion of employers in relation to the employed persons (%)"
temp_param_table$label[temp_param_table$var == "prop_cpropriaC"] <- "Proportion of self-employed people who contribute in relation to employed persons (%)"
temp_param_table$label[temp_param_table$var == "prop_cpropriaNc"] <- "Proportion of self-employed people who do not contribute in relation to employed persons (%)"
temp_param_table$label[temp_param_table$var == "prop_militar"] <- "Proportion of civil servants and military in relation to employed persons (%)"
temp_param_table$label[temp_param_table$var == "taxa_de_informalidade"] <- "Informality rate(%)"

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "id"] <- FALSE
temp_param_table$y[temp_param_table$var == "composicao_demografica"] <- FALSE
temp_param_table$y[temp_param_table$var == "time"] <- FALSE
temp_param_table$y[temp_param_table$var == "group"] <- FALSE

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_trabalho_insercao_dic_en.csv", fileEncoding = "UTF-8")

#################################################
## Atividade Econômica na Amazônia Legal
## Ouput data from:
## Dinamismo Economico na Amazonia
## github: https://github.com/FranciscoCavalcanti/Amazonia_Dinamismo_Economico
#################################################

# set path to raw data
user_folder_path <- "C:\\Users\\Acer\\Documents\\GitHub\\" # set actual user data path
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
temp <- rbind(base1, base2, base3, base4, base5, base6, base7, base8, base9)

# remove rows with missing data
temp <- na.omit(temp)

temp <- temp %>%
  filter(titulo != "")

# convert time data to quarterly
temp <- temp %>%
  mutate(time = paste0(temp$Ano, "-", temp$Trimestre))
temp$time <- as.Date(as.yearqtr(temp$time))
temp$Trimestre <- NULL
temp$Ano <- NULL

# groups at the level: Estado e Atividade Economica
temp$group <- paste0(temp$UF, " - ", temp$titulo)

# change column order
temp <- temp %>%
  relocate(group, time)

# save data at rds format
saveRDS(temp,
  file = "./data/ibge_pnadc_cnae.rds"
)

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
  size = TRUE,
  slider = FALSE,
  label = columns,
  desc = columns,
  var_group = "IBGE - PNAD Contínua",
  tipo = 1,
  categoria = "Economia",
  subcategoria = "Mercado de trabalho"
)

# label variables
temp_param_table$label[1] <- "Atividade econômica"
temp_param_table$label[2] <- "Trimestre-Ano"
temp_param_table$label[3] <- "Atividade econômica"
temp_param_table$label[4] <- "Número de ocupados"
temp_param_table$label[5] <- "Número de ocupados no setor formal"
temp_param_table$label[6] <- "Número de ocupados no setor informal"
temp_param_table$label[7] <- "Número de ocupados no setor público"
temp_param_table$label[8] <- "Número de ocupados no setor privado"
temp_param_table$label[9] <- "Rendimento mensal médio"
temp_param_table$label[10] <- "Rendimento mensal médio no setor formal"
temp_param_table$label[11] <- "Rendimento mensal médio no setor informal"
temp_param_table$label[12] <- "Massa salarial"
temp_param_table$label[13] <- "Estado"


# block variables in graphs y-axis
temp_param_table$y[1] <- FALSE # Recorte regional
temp_param_table$y[2] <- FALSE # Ano-Trimestre
temp_param_table$y[3] <- FALSE # "Atividade econômica"
temp_param_table$y[13] <- FALSE # Estado

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_cnae_dic.csv", fileEncoding = "UTF-8")

#############################
# Build Dictionary in English
############################

# extract variables from data
columns <- colnames(temp)

# generate dictionary
temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = TRUE,
    size = TRUE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "IBGE - PNAD Contínua",
    tipo = 1,
    categoria = "Economia",
    subcategoria = "Mercado de trabalho"
)

# relabel in english

temp_param_table$label[1] <- "Economic Activity"
temp_param_table$label[2] <- "Quarter-year"
temp_param_table$label[3] <- "Economic Activity"
temp_param_table$label[4] <- "Employed persons"
temp_param_table$label[5] <- "Employed persons in the formal sector"
temp_param_table$label[6] <- "Employed persons in the informal sector"
temp_param_table$label[7] <- "Employed persons in the public sector"
temp_param_table$label[8] <- "Employed persons in the private sector"
temp_param_table$label[9] <- "Mean monthly income"
temp_param_table$label[10] <- "Mean monthly income in the formal sector"
temp_param_table$label[11] <- "Mean monthly income in the informal sector"
temp_param_table$label[12] <- " Total wage"
temp_param_table$label[13] <- "State"



# block variables in graphs y-axis
temp_param_table$y[1] <- FALSE # Recorte regional
temp_param_table$y[2] <- FALSE # Ano-Trimestre
temp_param_table$y[3] <- FALSE # "Atividade econômica"
temp_param_table$y[13] <- FALSE # Estado

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_cnae_dic_en.csv", fileEncoding = "UTF-8")



#################################################
## Ocupações na Amazônia Legal
## Ouput data from:
## Dinamismo Economico na Amazonia
## github: https://github.com/FranciscoCavalcanti/Amazonia_Dinamismo_Economico
#################################################

# set path to raw data
user_folder_path <- "C:\\Users\\Acer\\Documents\\GitHub\\" # set actual user data path
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
temp <- rbind(base1, base2, base3, base4, base5, base6, base7, base8, base9)

# remove rows with missing data
temp <- na.omit(temp)
temp <- temp %>%
  filter(titulo != "")

# convert time data to quarterly
temp <- temp %>%
  mutate(time = paste0(temp$Ano, "-", temp$Trimestre))
temp$time <- as.Date(as.yearqtr(temp$time))
temp$Trimestre <- NULL
temp$Ano <- NULL

# groups at the level: Estado e Ocupações
temp$group <- paste0(temp$UF, " - ", temp$titulo)

# change column order
temp <- temp %>%
  relocate(group, time)

# save data at rds format
saveRDS(temp,
  file = "./data/ibge_pnadc_cod.rds"
)

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
  categoria = "Economia",
  subcategoria = "Trabalho"
)

# label variables
temp_param_table$label[1] <- "Ocupação"
temp_param_table$label[2] <- "Trimestre-Ano"
temp_param_table$label[3] <- "Ocupação"
temp_param_table$label[4] <- "Número de ocupados"
temp_param_table$label[5] <- "Número de ocupados no setor formal"
temp_param_table$label[6] <- "Número de ocupados no setor informal"
temp_param_table$label[7] <- "Número de ocupados no setor público"
temp_param_table$label[8] <- "Número de ocupados no setor privado"
temp_param_table$label[9] <- "Rendimento mensal médio"
temp_param_table$label[10] <- "Rendimento mensal médio no setor formal"
temp_param_table$label[11] <- "Rendimento mensal médio no setor informal"
temp_param_table$label[12] <- "Massa salarial"
temp_param_table$label[13] <- "Estado"

# block variables in graphs y-axis
temp_param_table$y[1] <- FALSE # Ocupação
temp_param_table$y[2] <- FALSE # Ano-Trimestre
temp_param_table$y[3] <- FALSE # Ocupação
temp_param_table$y[13] <- FALSE # Estado

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_cod_dic.csv", fileEncoding = "UTF-8")

#############################
# Build Dictionary in English
############################

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
    categoria = "Economia",
    subcategoria = "Trabalho"
)

# label variables
temp_param_table$label[1] <- "Occupation"
temp_param_table$label[2] <-  "Quarter-year"
temp_param_table$label[3] <- "Ocupação"
temp_param_table$label[4] <- "Employed persons"
temp_param_table$label[5] <- "Employed persons in the formal sector"
temp_param_table$label[6] <- "Employed persons in the informal sector"
temp_param_table$label[7] <- "Employed persons in the public sector"
temp_param_table$label[8] <- "Employed persons in the private sector"
temp_param_table$label[9] <- "Mean monthly income"
temp_param_table$label[10] <- "Mean monthly income in the formal sector"
temp_param_table$label[11] <- "Mean monthly income in the informal sector"
temp_param_table$label[12] <- "Total wage"
temp_param_table$label[13] <- "State"

# block variables in graphs y-axis
temp_param_table$y[1] <- FALSE # Ocupação
temp_param_table$y[2] <- FALSE # Ano-Trimestre
temp_param_table$y[3] <- FALSE # Ocupação
temp_param_table$y[13] <- FALSE # Estado

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ibge_pnadc_cod_dic_en.csv", fileEncoding = "UTF-8")

