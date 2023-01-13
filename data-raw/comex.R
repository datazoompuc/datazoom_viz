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



# exportação municipal da amazônia por tipo sh4
dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$cod_pais <- NULL

dat <- aggregate(valor_fob ~ ano + cod_sh4 + cod_municipio + uf, dat, sum)

dat$cod_sh4 <- sprintf("%04d", as.numeric(dat$cod_sh4))
aux2$CO_SH4 <- sprintf("%04d", as.numeric(aux2$CO_SH4))
dat$cod_sh4 <- str_replace_all(dat$cod_sh4, setNames(aux2$NO_SH4_POR, aux2$CO_SH4))
dat$cod_municipio <- str_replace_all(dat$cod_municipio, setNames(aux3$nome, aux3$codigo))
dat$cod_municipio <- paste(dat$cod_municipio, " - ",dat$uf)
dat$uf <- NULL

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

datafinal_val_munic[is.na(datafinal_val_munic)] <- 0
datafinal_val_sh2[is.na(datafinal_val_sh2)] <- 0

datafinal_val_munic <- datafinal_val_munic[order(datafinal_val_munic$group, datafinal_val_munic$time),]
datafinal_val_sh2 <- datafinal_val_sh2[order(datafinal_val_sh2$group, datafinal_val_sh2$time),]

saveRDS(datafinal_val_munic, "data/comex_exp_munic_sh4.rds")
saveRDS(datafinal_val_sh2, "data/comex_exp_sh4_munic.rds")



# exportação municipal da amazônia por tipo sh2
dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$cod_pais <- NULL

dat <- aggregate(valor_fob ~ ano + cod_sh4 + cod_municipio + uf, dat, sum)

dat$cod_sh4 <- sprintf("%04d", as.numeric(dat$cod_sh4))
aux2$CO_SH4 <- sprintf("%04d", as.numeric(aux2$CO_SH4))
dat$cod_sh4 <- str_replace_all(dat$cod_sh4, setNames(aux2$NO_SH2_POR, aux2$CO_SH4))
dat$cod_municipio <- str_replace_all(dat$cod_municipio, setNames(aux3$nome, aux3$codigo))
dat$cod_municipio <- paste(dat$cod_municipio, " - ",dat$uf)
dat$uf <- NULL

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

datafinal_val_munic[is.na(datafinal_val_munic)] <- 0
datafinal_val_sh2[is.na(datafinal_val_sh2)] <- 0

datafinal_val_munic <- datafinal_val_munic[order(datafinal_val_munic$group, datafinal_val_munic$time),]
datafinal_val_sh2 <- datafinal_val_sh2[order(datafinal_val_sh2$group, datafinal_val_sh2$time),]

saveRDS(datafinal_val_munic, "data/comex_exp_munic_sh2.rds")
saveRDS(datafinal_val_sh2, "data/comex_exp_sh2_munic.rds")



# exportação total da amazônia por tipo sec
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
data_val_pais$cod_sh4 <- str_replace_all(data_val_pais$cod_sh4, setNames(aux2$NO_SEC_POR, aux2$CO_SH4))

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

saveRDS(data_val_pais, "data/comex_exp_tot_sec.rds")



# exportação municipal da amazônia por tipo sec
dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$cod_pais <- NULL

dat <- aggregate(valor_fob ~ ano + cod_sh4 + cod_municipio + uf, dat, sum)

dat$cod_sh4 <- sprintf("%04d", as.numeric(dat$cod_sh4))
aux2$CO_SH4 <- sprintf("%04d", as.numeric(aux2$CO_SH4))
dat$cod_sh4 <- str_replace_all(dat$cod_sh4, setNames(aux2$NO_SH2_POR, aux2$CO_SH4))
dat$cod_municipio <- str_replace_all(dat$cod_municipio, setNames(aux3$nome, aux3$codigo))
dat$cod_municipio <- paste(dat$cod_municipio, " - ",dat$uf)
dat$uf <- NULL

data_val <- dat
colnames(data_val) <- c("time", "type", "group", "value")
data_val <- aggregate(value ~ time + type + group, data_val, sum)

datafinal_val_munic <- reshape(data_val, idvar = c("time", "type"), timevar = "group", direction = "wide")
datafinal_val_sec <- reshape(data_val, idvar = c("time", "group"), timevar = "type", direction = "wide")

labl <- colnames(datafinal_val_munic)
labl <- labl[-c(1,2)]
labl <- substr(labl, 7, 100)
colnames(datafinal_val_munic) <- c("time", "group", labl)

labl <- colnames(datafinal_val_sec)
labl <- labl[-c(1,2)]
labl <- substr(labl, 7, 100)
colnames(datafinal_val_sec) <- c("time", "group", labl)

datafinal_val_munic[is.na(datafinal_val_munic)] <- 0
datafinal_val_sec[is.na(datafinal_val_sec)] <- 0

datafinal_val_munic <- datafinal_val_munic[order(datafinal_val_munic$group, datafinal_val_munic$time),]
datafinal_val_sec <- datafinal_val_sec[order(datafinal_val_sec$time, datafinal_val_sec$group),]

saveRDS(datafinal_val_munic, "data/comex_exp_munic_sec.rds")
saveRDS(datafinal_val_sec, "data/comex_exp_sec_munic.rds")


# exportação total da amazônia por pais
dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$uf <- NULL
dat$cod_municipio <- NULL

data_val_pais <- aggregate(valor_fob ~ ano + cod_pais, dat, sum)
data_val_pais_sec <- aggregate(valor_fob ~ ano + cod_pais + cod_sh4, dat, sum)

aux2$CO_SH4 <- sprintf("%04d", as.numeric(aux2$CO_SH4))
data_val_pais$cod_pais <- sprintf("%03d", as.numeric(data_val_pais$cod_pais))
aux1$SISCOMEX <- sprintf("%03d", as.numeric(aux1$SISCOMEX))
data_val_pais$cod_pais <- str_replace_all(data_val_pais$cod_pais, setNames(aux1$NO_POR_MIN, aux1$SISCOMEX))

data_val_pais_sec$cod_sh4 <- sprintf("%04d", as.numeric(data_val_pais_sec$cod_sh4))
data_val_pais_sec$cod_sh4 <- str_replace_all(data_val_pais_sec$cod_sh4, setNames(aux2$NO_SEC_POR, aux2$CO_SH4))
data_val_pais_sec$cod_pais <- sprintf("%03d", as.numeric(data_val_pais_sec$cod_pais))
data_val_pais_sec$cod_pais <- str_replace_all(data_val_pais_sec$cod_pais, setNames(aux1$NO_POR_MIN, aux1$SISCOMEX))

data_val_pais <- data_val_pais[!(data_val_pais$cod_pais %in% c("015", "042", "150", "388", "489", "693", "790", "990")),]
data_val_pais_sec <- data_val_pais_sec[!(data_val_pais_sec$cod_pais %in% c("015", "042", "150", "388", "489", "693", "790", "990")),]

colnames(data_val_pais) <- c("time", "group", "value")
colnames(data_val_pais_sec) <- c("time", "group", "type", "value")

data_val_pais <- data_val_pais[order(data_val_pais$group, data_val_pais$time),]
saveRDS(data_val_pais, "data/comex_exp_tot_pais.rds")

datafinal_val_pais_sec <- reshape(data_val_pais_sec, idvar = c("time", "type"), timevar = "group", direction = "wide")
datafinal_val_pais_munic <- reshape(data_val_pais_sec, idvar = c("time", "group"), timevar = "type", direction = "wide")

labl <- colnames(datafinal_val_pais_sec)
labl <- labl[-c(1,2)]
labl <- substr(labl, 7, 100)
colnames(datafinal_val_pais_sec) <- c("time", "group", labl)

labl <- colnames(datafinal_val_pais_munic)
labl <- labl[-c(1,2)]
labl <- substr(labl, 7, 100)
colnames(datafinal_val_pais_munic) <- c("time", "group", labl)

saveRDS(datafinal_val_pais_sec, "data/comex_exp_sec_pais.rds")
saveRDS(datafinal_val_pais_munic, "data/comex_exp_pais_sec.rds")



#####################
# Build Dictionary 
#####################

### exportação municipal da amazônia por tipo sh4
datafinal <- readRDS(file = "data/comex_exp_munic_sh4.rds")

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

temp_param_table$label[2] <- "Produção sh4"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Produção sh4"
temp_param_table$desc[1] <- "Ano"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 418))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 418))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_munic_sh4_dic.csv", fileEncoding = "UTF-8")



### exportação municipal da amazônia por tipo sh4
datafinal <- readRDS(file = "data/comex_exp_sh4_munic.rds")

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
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 1103))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 1103))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 1103))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 1103))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 1103))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_sh4_munic_dic.csv", fileEncoding = "UTF-8")



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

temp_param_table$label[2] <- "Produção sh2"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Produção sh2"
temp_param_table$desc[1] <- "Ano"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 418))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 418))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_munic_sh2_dic.csv", fileEncoding = "UTF-8")



### exportação municipal da amazônia por tipo sh2
datafinal <- readRDS(file = "data/comex_exp_sh2_munic.rds")

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
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 96))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 96))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_sh2_munic_dic.csv", fileEncoding = "UTF-8")



### exportação municipal da amazônia por tipo sec
datafinal <- readRDS(file = "data/comex_exp_munic_sec.rds")

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

temp_param_table$label[2] <- "Produção sec"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Produção sec"
temp_param_table$desc[1] <- "Ano"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 418))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 418))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_munic_sec_dic.csv", fileEncoding = "UTF-8")



### exportação municipal da amazônia por tipo sec
datafinal <- readRDS(file = "data/comex_exp_sec_munic.rds")

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
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 96))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 96))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_sec_munic_dic.csv", fileEncoding = "UTF-8")




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



### exportação por pais da amazônia por tipo sec
datafinal <- readRDS(file = "data/comex_exp_sec_pais.rds")

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

temp_param_table$label[2] <- "País"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "País"
temp_param_table$desc[1] <- "Ano"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 221))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 221))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 221))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 221))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 221))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_sec_pais_dic.csv", fileEncoding = "UTF-8")



### exportação por pais da amazônia por tipo sec
datafinal <- readRDS(file = "data/comex_exp_pais_sec.rds")

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

temp_param_table$label[2] <- "País"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "País"
temp_param_table$desc[1] <- "Ano"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 22))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 22))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_pais_sec_dic.csv", fileEncoding = "UTF-8")



### exportação por pais da amazônia total
datafinal <- readRDS(file = "data/comex_exp_tot_pais.rds")

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

temp_param_table$label[2] <- "País"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "País"
temp_param_table$desc[1] <- "Ano"
temp_param_table$label[3] <- "Valor"
temp_param_table$desc[3] <- "Valor"

temp_param_table$x <- c(rep(FALSE, 2), TRUE)
temp_param_table$y <- c(rep(FALSE, 2), TRUE)
temp_param_table$color <- c(FALSE, rep(TRUE, 1), FALSE)
temp_param_table$size <- c(rep(FALSE, 2), TRUE)
temp_param_table$slider <- c(rep(FALSE, 2), TRUE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_tot_pais_dic.csv", fileEncoding = "UTF-8")





### exportação por pais da amazônia por tipo sec inglês
datafinal <- readRDS(file = "data/comex_exp_sec_pais.rds")

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

temp_param_table$label[2] <- "Country"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[2] <- "Country"
temp_param_table$desc[1] <- "Year"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 221))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 221))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 221))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 221))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 221))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_sec_pais_en_dic.csv", fileEncoding = "UTF-8")






### exportação por pais da amazônia total inglês
datafinal <- readRDS(file = "data/comex_exp_tot_pais.rds")

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

temp_param_table$label[2] <- "Country"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[2] <- "Country"
temp_param_table$desc[1] <- "Year"
temp_param_table$label[3] <- "Value"
temp_param_table$desc[3] <- "Value"

temp_param_table$x <- c(rep(FALSE, 2), TRUE)
temp_param_table$y <- c(rep(FALSE, 2), TRUE)
temp_param_table$color <- c(FALSE, rep(TRUE, 1), FALSE)
temp_param_table$size <- c(rep(FALSE, 2), TRUE)
temp_param_table$slider <- c(rep(FALSE, 2), TRUE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_tot_pais_en_dic.csv", fileEncoding = "UTF-8")
