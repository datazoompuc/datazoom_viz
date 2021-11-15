############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(magrittr)
library(tidyverse)
library(stringr)

dat <- load_br_trade(dataset="comex_export_mun", language = "pt", time_period = 1997:2021, raw_data = FALSE)

tipos <- c("RO", "AM", "PA", "RR", "MT", "MA", "AC", "AP", "TO")
`%notin%` <- Negate(`%in%`)
dat <- dat[!(dat$uf %notin% tipos),]

saveRDS(dat, file = "data/comex_munic_raw.rds")
dat <- readRDS(file = "data/comex_munic_raw.rds")

aux1 <- readRDS("data/auxiliar_cod_pais.rds")
aux2 <- readRDS("data/auxiliar_cod_sh4.rds")
aux3 <- readRDS("data/auxiliar_cod_municipais.rds")

#dat$cod_pais <- as.numeric(dat$cod_pais)
#aux1$SISCOMEX <- as.numeric(aux1$SISCOMEX)
#dat$cod_pais <- str_replace_all(dat$cod_pais, setNames(aux1$NO_POR_MIN, aux1$SISCOMEX))
#dat$cod_municipio <- str_replace_all(dat$cod_municipio, setNames(aux3$nome, aux3$codigo))

matriz <- dat



# exportação total da amazônia por tipo sh2
dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$uf <- NULL
dat$cod_municipio <- NULL
dat$cod_pais <- NULL

data_val_pais <- aggregate(valor_fob ~ ano + cod_sh4, dat, sum)

data_val_pais$cod_sh4 <- sprintf("%04d", as.numeric(data_val_pais$cod_sh4))
aux2$CO_SH4 <- sprintf("%04d", as.numeric(aux2$CO_SH4))
data_val_pais$cod_sh4 <- str_replace_all(data_val_pais$cod_sh4, setNames(aux2$NO_SH2_POR, aux2$CO_SH4))

colnames(data_val_pais) <- c("time", "group", "value")

data_val_pais$time <- as.numeric(data_val_pais$time)
data_val_pais <- aggregate(value ~ time + group, data_val_pais, sum)

#datafinal_val_pais <- reshape(data_val_pais, idvar = c("group"), timevar = "time", direction = "wide")
#labl <- colnames(datafinal_val_pais)
#labl <- labl[-c(1)]
#labl <- substr(labl, 7, 100)
#colnames(datafinal_val_pais) <- c("time", labl)
#group <- rep("Amazônia", 25)
#datafinal_val_pais <- cbind(group, datafinal_val_pais)

saveRDS(data_val_pais, "data/comex_exp_tot_sh2.rds")



# exportação municipal da amazônia por tipo sh2
dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$uf <- NULL
dat$cod_pais <- NULL

dat <- aggregate(valor_fob ~ ano + cod_sh4 + cod_municipio, dat, sum)

dat$cod_sh4 <- sprintf("%04d", as.numeric(dat$cod_sh4))
aux2$CO_SH4 <- sprintf("%04d", as.numeric(aux2$CO_SH4))
dat$cod_sh4 <- str_replace_all(dat$cod_sh4, setNames(aux2$NO_SH2_POR, aux2$CO_SH4))
dat$cod_municipio <- str_replace_all(dat$cod_municipio, setNames(aux3$nome, aux3$codigo))

data_val <- dat
colnames(data_val) <- c("time", "type", "group", "value")
data_val <- aggregate(value ~ time + type + group, data_val, sum)

datafinal_val_munic <- reshape(data_val, idvar = c("time", "type"), timevar = "group", direction = "wide")
datafinal_val_sh2 <- reshape(data_val, idvar = c("time", "group"), timevar = "type", direction = "wide")

labl <- colnames(datafinal_val_munic)
labl <- labl[-c(1,2)]
labl <- substr(labl, 7, 100)
colnames(datafinal_val_munic) <- c("time", "group", labl)

labl <- colnames(datafinal_val_sh2)
labl <- labl[-c(1,2)]
labl <- substr(labl, 7, 100)
colnames(datafinal_val_sh2) <- c("time", "group", labl)

saveRDS(datafinal_val_munic, "data/comex_exp_munic_sh2.rds")
saveRDS(datafinal_val_sh2, "data/comex_exp_sh2_munic.rds")



# exportação total da amazônia por pais
dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$uf <- NULL
dat$cod_municipio <- NULL
dat$cod_sh4 <- NULL

dat$cod_pais <- as.numeric(dat$cod_pais)
aux1$SISCOMEX <- as.numeric(aux1$SISCOMEX)
dat$cod_pais <- str_replace_all(dat$cod_pais, setNames(aux1$NO_POR_MIN, aux1$SISCOMEX))

data_val_pais <- aggregate(valor_fob ~ ano + cod_pais, dat, sum)
colnames(data_val_pais) <- c("time", "type", "value")

datafinal_val_pais <- reshape(data_val_pais, idvar = c("time"), timevar = "type", direction = "wide")
labl <- colnames(datafinal_val_pais)
labl <- labl[-c(1)]
labl <- substr(labl, 8, 100)
colnames(datafinal_val_pais) <- c("time", labl)
datafinal_val_pais$group <- rep("Amazonia", 25)

saveRDS(datafinal_val_pais, "data/comex_exp_tot_pais.rds")



# exportação municipal da amazônia por pais
dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$uf <- NULL
dat$cod_sh4 <- NULL

dat$cod_pais <- as.numeric(dat$cod_pais)
aux1$SISCOMEX <- as.numeric(aux1$SISCOMEX)
dat$cod_pais <- str_replace_all(dat$cod_pais, setNames(aux1$NO_POR_MIN, aux1$SISCOMEX))
dat$cod_municipio <- str_replace_all(dat$cod_municipio, setNames(aux3$nome, aux3$codigo))

data_val_pais <- aggregate(valor_fob ~ ano + cod_pais + cod_municipio, dat, sum)
colnames(data_val_pais) <- c("time", "type", "group", "value")

datafinal_val_pais <- reshape(data_val_pais, idvar = c("time", "group"), timevar = "type", direction = "wide")
labl <- colnames(datafinal_val_pais)
labl <- labl[-c(1,2)]
labl <- substr(labl, 8, 100)
colnames(datafinal_val_pais) <- c("time", "group", labl)

saveRDS(datafinal_val_pais, "data/comex_exp_munic_pais.rds")



#####################
# Build Dictionary 
#####################

### exportação municipal da amazônia por tipo sh2
datafinal <- readRDS(file = "data/comex_exp_munic_sh2.rds")

# extract variables from data
columns <- colnames(datafinal)

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
  var_group = "Comex",
  tipo = 1,
  unidade = "R$",
  categoria= "Economia", 
  subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "Município"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Município"
temp_param_table$desc[1] <- "Ano"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 167))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 167))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 167))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 167))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 167))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_munic_sh2_dic.csv", fileEncoding = "UTF-8")


### exportação total da amazônia por tipo sh2
datafinal <- readRDS(file = "data/comex_exp_tot_sh2.rds")

# extract variables from data
columns <- colnames(datafinal)

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
  var_group = "Comex",
  tipo = 1,
  unidade = "R$",
  categoria= "Economia", 
  subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "Região"
temp_param_table$label[1] <- "Ano"
temp_param_table$label[3] <- "Valor"
temp_param_table$desc[2] <- "Região"
temp_param_table$desc[1] <- "Ano"
temp_param_table$desc[3] <- "Valor"
temp_param_table$x <- c(FALSE, FALSE, TRUE)
temp_param_table$y <- c(FALSE, FALSE, TRUE)
temp_param_table$color <- c(FALSE, TRUE, FALSE)
temp_param_table$size <- c(FALSE, FALSE, TRUE)
temp_param_table$slider <- c(FALSE, FALSE, TRUE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_tot_sh2_dic.csv", fileEncoding = "UTF-8")
