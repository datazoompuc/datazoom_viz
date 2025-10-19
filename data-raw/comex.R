############################################################
#### Generate rds data in the folder ./data/ 
############################################################



library(datazoom.amazonia)
library(magrittr)
library(tidyverse)
library(stringr)

dat <- load_br_trade(dataset="comex_export_mun", language = "pt", time_period = 1997:2023, raw_data = FALSE)

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
  unidade = "US$",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[2] <- "Produ\u00e7\u00e3o sh4"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Produ\u00e7\u00e3o sh4"

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
  unidade = "US$",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[2] <- "Munic\u00edpio"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Munic\u00edpio"

temp_param_table$desc[1] <- "Ano"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 1103))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 1103))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 1103))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 1103))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 1103))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_sh4_munic_dic.csv", fileEncoding = "UTF-8")


# generate dictionary in English
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

temp_param_table$label[2] <- "Municipality"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[2] <- "Municipality"
temp_param_table$desc[1] <- "Year"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 1103))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 1103))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 1103))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 1103))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 1103))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_sh4_munic_dic_en.csv", fileEncoding = "UTF-8")

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
  unidade = "US$",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[2] <- "Produ\u00e7\u00e3o sh2"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Produ\u00e7\u00e3o sh2"

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
  unidade = "US$",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[2] <- "Munic\u00edpio"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Munic\u00edpio"

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
  unidade = "US$",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[2] <- "Produ\u00e7\u00e3o sec"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Produ\u00e7\u00e3o sec"

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
  unidade = "US$",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[2] <- "Munic\u00edpio"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Munic\u00edpio"
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
  unidade = "US$",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[2] <- "Regi\u00e3o"
temp_param_table$label[1] <- "Ano"
temp_param_table$label[3] <- "Valor"
temp_param_table$desc[2] <- "Regi\u00e3o"
temp_param_table$desc[1] <- "Ano"
temp_param_table$desc[3] <- "Valor"
temp_param_table$x <- c(FALSE, FALSE, TRUE)
temp_param_table$y <- c(FALSE, FALSE, TRUE)
temp_param_table$color <- c(FALSE, TRUE, FALSE)
temp_param_table$size <- c(FALSE, FALSE, TRUE)
temp_param_table$slider <- c(FALSE, FALSE, TRUE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_tot_sh2_dic.csv", fileEncoding = "UTF-8")

#############################
# Build dictionary in english
#############################

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
  unidade = "US$",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[2] <- "Pa\u00eds"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Pa\u00eds"
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
  unidade = "US$",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[2] <- "Pa\u00eds"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Pa\u00eds"
temp_param_table$desc[1] <- "Ano"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 22))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 22))

# translate
temp_param_table$label[3] <- "Live animals and products of the animal kingdom"
temp_param_table$label[4] <- "Weapons and ammunition; their parts and accessories"
temp_param_table$label[5] <- "Footwear, hats, and similar articles; umbrellas, parasols, walking sticks, whips"
temp_param_table$label[6] <- "Animal or vegetable fats and oils; products of their cleavage; edible fats"
temp_param_table$label[7] <- "Optical, photographic, cinematographic, measuring, control or precision instruments and apparatus"
temp_param_table$label[8] <- "Wood, charcoal, and wood articles; cork and articles of cork; basketware and wickerwork"
temp_param_table$label[9] <- "Machinery and mechanical appliances; electrical equipment; parts thereof; sound recorders and reproducers"
temp_param_table$label[10] <- "Transportation equipment"
temp_param_table$label[11] <- "Textiles and textile articles"
temp_param_table$label[12] <- "Miscellaneous manufactured articles"
temp_param_table$label[13] <- "Base metals and articles of base metal"
temp_param_table$label[14] <- "Works of art, collectors' pieces, and antiques"
temp_param_table$label[15] <- "Stone, plaster, cement, asbestos, mica, or similar materials; ceramic products"
temp_param_table$label[16] <- "Wood pulp or other fibrous cellulose material; recovered (waste and scrap) paper or paperboard"
temp_param_table$label[17] <- "Skins and other parts of birds, with their feathers or down; articles of leather or of composition leather"
temp_param_table$label[18] <- "Natural or cultured pearls, precious or semi-precious stones, precious metals"
temp_param_table$label[19] <- "Plastics and articles thereof; rubber and articles thereof"
temp_param_table$label[20] <- "Chemical or allied industries products"
temp_param_table$label[21] <- "Food industry products; beverages, spirits, and vinegar; tobacco"
temp_param_table$label[22] <- "Vegetable products"
temp_param_table$label[23] <- "Mineral products"
temp_param_table$label[24] <- "Special transactions"

temp_param_table$var[3] <- "Live animals and products of the animal kingdom"
temp_param_table$var[4] <- "Weapons and ammunition; their parts and accessories"
temp_param_table$var[5] <- "Footwear, hats, and similar articles; umbrellas, parasols, walking sticks, whips"
temp_param_table$var[6] <- "Animal or vegetable fats and oils; products of their cleavage; edible fats"
temp_param_table$var[7] <- "Optical, photographic, cinematographic, measuring, control or precision instruments and apparatus"
temp_param_table$var[8] <- "Wood, charcoal, and wood articles; cork and articles of cork; basketware and wickerwork"
temp_param_table$var[9] <- "Machinery and mechanical appliances; electrical equipment; parts thereof; sound recorders and reproducers"
temp_param_table$var[10] <- "Transportation equipment"
temp_param_table$var[11] <- "Textiles and textile articles"
temp_param_table$var[12] <- "Miscellaneous manufactured articles"
temp_param_table$var[13] <- "Base metals and articles of base metal"
temp_param_table$var[14] <- "Works of art, collectors' pieces, and antiques"
temp_param_table$var[15] <- "Stone, plaster, cement, asbestos, mica, or similar materials; ceramic products"
temp_param_table$var[16] <- "Wood pulp or other fibrous cellulose material; recovered (waste and scrap) paper or paperboard"
temp_param_table$var[17] <- "Skins and other parts of birds, with their feathers or down; articles of leather or of composition leather"
temp_param_table$var[18] <- "Natural or cultured pearls, precious or semi-precious stones, precious metals"
temp_param_table$var[19] <- "Plastics and articles thereof; rubber and articles thereof"
temp_param_table$var[20] <- "Chemical or allied industries products"
temp_param_table$var[21] <- "Food industry products; beverages, spirits, and vinegar; tobacco"
temp_param_table$var[22] <- "Vegetable products"
temp_param_table$var[23] <- "Mineral products"
temp_param_table$var[24] <- "Special transactions"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_pais_sec_dic_en.csv", fileEncoding = "UTF-8")



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
  unidade = "US$",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[2] <- "Pa\u00eds"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Pa\u00eds"
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
    categoria= "Economy", 
    subcategoria = "Trade"
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
write.csv(temp_param_table, file = "data/comex_exp_tot_pais_dic_en.csv", fileEncoding = "UTF-8")

### exportação municipal da amazônia por tipo sh2 inglês
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
    categoria= "Economy", 
    subcategoria = "Trade"
)

temp_param_table$label[2] <- "Sh2 production"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[2] <- "Sh2 production"
temp_param_table$desc[1] <- "Year"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 418))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 418))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_munic_sh2_en_dic.csv", fileEncoding = "UTF-8")




### exportação municipal da amazônia por tipo sh2 inglês
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
    categoria= "Economy", 
    subcategoria = "Trade"
)

temp_param_table$label[98] <- "Guns and ammunition; their parts and accessories"
temp_param_table$label[97] <- "Wool, thin or thick fur; threads and hair fabrics"
temp_param_table$label[96] <- "Non-continuous synthetic or artificial fibers"
temp_param_table$label[95] <- "Cork and its works"
temp_param_table$label[94] <- "Lead and its works"
temp_param_table$label[93] <- "Zinc and its works"
temp_param_table$label[92] <- "Knitwear fabrics"
temp_param_table$label[91] <- "Carpets and other textile floor coverings"
temp_param_table$label[90] <- "Gunpowder and explosives; fireworks; matches; pyrophoric alloys; flammable materials"
temp_param_table$label[89] <- "Feathers and prepared plumage and their works; artificial flowers; hair works"
temp_param_table$label[88] <- "Furred pelts and theis crafts; pelt with artificial fur"
temp_param_table$label[87] <- "Musical instruments; their parts and accessories"
temp_param_table$label[86] <- "Umbrellas, parasols, sunshades, canes, seat canes, whips, walking sticks"
temp_param_table$label[85] <- "Watch articles"
temp_param_table$label[84] <- "Nickel and its works"
temp_param_table$label[83] <- "Impregnated, coated, covered or laminated fabrics; technical use articles"
temp_param_table$label[82] <- "Inorganic chemicals; precious metals organic or inorganic compunds"
temp_param_table$label[81] <- "Tin and its works"
temp_param_table$label[80] <- "Aircrafts and special devices; and their parts"
temp_param_table$label[79] <- "Glass and its works"
temp_param_table$label[78] <- "Knitwear clothing and its accessories"
temp_param_table$label[77] <- "Special fabrics; tufted fabrics; laces; tapestries; trimmings; embroideries"
temp_param_table$label[76] <- "Tobbaco and its manufactured substitutes"
temp_param_table$label[75] <- "Products for photography and cinematography"
temp_param_table$label[74] <- "Pharmaceutical products"
temp_param_table$label[73] <- "Cereal based, flours, starches, starches products or milk preparations; pastry products"
temp_param_table$label[72] <- "Live plants and floriculture products"
temp_param_table$label[71] <- "Pelt, except furred pelt, and leathers"
temp_param_table$label[70] <- "Other common metals; cermets; these matters works"
temp_param_table$label[69] <- "Other vegetal textile fibers; paper threads and paper threads fabrics"
temp_param_table$label[68] <- "Various works of common metals"
temp_param_table$label[67] <- "Sparto or basketry works"
temp_param_table$label[66] <- "Materials for plaiting and other vegetable products, not specified nor contained in other Chapters"
temp_param_table$label[65] <- "Books, newspapers, engravings and other graphic industry products; handwritten texts"
temp_param_table$label[64] <- "Synthetic or natural filaments"
temp_param_table$label[63] <- "Tanning and dyeing extracts; tannins and their derivatives; pigments and other colouring matter"
temp_param_table$label[62] <- "Boats and floating structures"
temp_param_table$label[61] <- "Mineral fuels, mineram oils and products of their destiltion; bitunimous substances; wax"
temp_param_table$label[60] <- "Cooper and its works"
temp_param_table$label[59] <- "Hats and similar purpose artifacts, and their parts"
temp_param_table$label[58] <- "Aluminum and its works"
temp_param_table$label[57] <- "Fertilizers"
temp_param_table$label[56] <- "Footwear, gaiters and similar artifacts; their parts"
temp_param_table$label[55] <- "Organic chemicals"
temp_param_table$label[54] <- "Cotton"
temp_param_table$label[53] <- "Automobiles, tractors, mopeds and other terrestrial vehicles, and their parts and accessories"
temp_param_table$label[52] <- "Fish and crustaceans, mollusks and other aquatic invertebrates"
temp_param_table$label[51] <- "Essential oils and resinoids; perfumery or toilet preparations products"
temp_param_table$label[50] <- "Various works"
temp_param_table$label[49] <- "Stone, plaster, cement, asbestos, mica and similar elements works"
temp_param_table$label[48] <- "Optic, photography or cinematography, measuring, control or precision instruments or devices"
temp_param_table$label[47] <- "Cocoa and its preparations"
temp_param_table$label[46] <- "Toys, games, articles for fun or sports; their parts and accessories"
temp_param_table$label[45] <- "Rubber and its works"
temp_param_table$label[44] <- "Meat, fish or crustaceans, mollusks and other aquatic invertebrates preparations"
temp_param_table$label[43] <- "Various food related preparations"
temp_param_table$label[42] <- "Milk and derivatives; bird's eggs; natural honey; edible products of animal origin, not"
temp_param_table$label[41] <- "Vehicles and material for railroads and resemblants, and their parts; mechanical devices (including)"
temp_param_table$label[40] <- "Salt; sulfur; dirt and stones; plaster, lime and cement"
temp_param_table$label[39] <- "Natural or cultured pearls, precious or semiprecious stones and resemblants, precious metals"
temp_param_table$label[38] <- "Beverages, alcoholic liquids and vinegars"
temp_param_table$label[37] <- "Paper and card; paper or card cellulose paste works"
temp_param_table$label[36] <- "Albuminoids raw material; modified starch or flour-based products, glues and enzymes"
temp_param_table$label[35] <- "Machines, devices, electric material and their parts; Recording and playing devices"
temp_param_table$label[34] <- "Other animal origin products, not specified nor contained in other Chapters"
temp_param_table$label[33] <- "Cast iron, iron or steel"
temp_param_table$label[32] <- "Edible meat and offal"
temp_param_table$label[31] <- "Coffee, tea, mate and spices"
temp_param_table$label[30] <- "Sugar and confectionary products"
temp_param_table$label[29] <- "Clothing and its accessories, except knitwear"
temp_param_table$label[28] <- "Special transactions"
temp_param_table$label[27] <- "Oilseeds and oilseed fruits; grains, seeds and various fruits; industrial or medical plants"
temp_param_table$label[26] <- "Soaps, surface-active organic agents, washing prepartions, lubricating preparations"
temp_param_table$label[25] <- "Food industry waste and residuals; food made for animals"
temp_param_table$label[24] <- "Nuclear reactors, boilers, mechanical instruments and devices and their parts"
temp_param_table$label[23] <- "Edible horticultural products, plants, roots, and tubers"
temp_param_table$label[22] <- "Various products from the chemical industry"
temp_param_table$label[21] <- "Grinding industry products; malt; starches and flours; inulin; wheat gluten"
temp_param_table$label[20] <- "Pottery products"
temp_param_table$label[19] <- "Horticultural products, fruit and other plant parts preparation"
temp_param_table$label[18] <- "Plastic and its works"
temp_param_table$label[17] <- "Wood or other celullose fiber materials pastes; Paper or card for recycling"
temp_param_table$label[16] <- "Batt, felt and fake cloth; Special; Special threads; Twines, ropes and cables; Articles of"
temp_param_table$label[15] <- "Other manufactured textile artifacts; Sorted itens; textile raw materials artifacts, footwear"
temp_param_table$label[14] <- "Cast iron, iron or steel"
temp_param_table$label[13] <- "Leather works; Trapecial straps or saddles; Travel articles, purses and similar artifacts"
temp_param_table$label[12] <- "Art and collection objects and antiques"
temp_param_table$label[11] <- "Furniture; Medic surgery furniture, matresses, pillows and resemblants; Lighten devices"
temp_param_table$label[10] <- "Minerals, slag and ashes"
temp_param_table$label[9] <- "Wood, charcoal and woodcraft"
temp_param_table$label[8] <- "Fats and vegetable or animal oils; their dissociation products; processed food fats"
temp_param_table$label[7] <- "Gum, resins and other vegetable juices and extracts"
temp_param_table$label[6] <- "Fruit; Citrus fruits and melon peel"
temp_param_table$label[5] <- "Tools, cutlery artifacts and silverware and their made of metal parts"
temp_param_table$label[4] <- "Cereals"
temp_param_table$label[3] <- "Live animals"
temp_param_table$label[2] <- "Municipality"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[98] <- "Guns and ammunition; their parts and accessories"
temp_param_table$desc[97] <- "Wool, thin or thick fur; threads and hair fabrics"
temp_param_table$desc[96] <- "Non-continuous synthetic or artificial fibers"
temp_param_table$desc[95] <- "Cork and its works"
temp_param_table$desc[94] <- "Lead and its works"
temp_param_table$desc[93] <- "Zinc and its works"
temp_param_table$desc[92] <- "Knitwear fabrics"
temp_param_table$desc[91] <- "Carpets and other textile floor coverings"
temp_param_table$desc[90] <- "Gunpowder and explosives; fireworks; matches; pyrophoric alloys; flammable materials"
temp_param_table$desc[89] <- "Feathers and prepared plumage and their works; artificial flowers; hair works"
temp_param_table$desc[88] <- "Furred pelts and theis crafts; pelt with artificial fur"
temp_param_table$desc[87] <- "Musical instruments; their parts and accessories"
temp_param_table$desc[86] <- "Umbrellas, parasols, sunshades, canes, seat canes, whips, walking sticks"
temp_param_table$desc[85] <- "Watch articles"
temp_param_table$desc[84] <- "Nickel and its works"
temp_param_table$desc[83] <- "Impregnated, coated, covered or laminated fabrics; technical use articles"
temp_param_table$desc[82] <- "Inorganic chemicals; precious metals organic or inorganic compunds"
temp_param_table$desc[81] <- "Tin and its works"
temp_param_table$desc[80] <- "Aircrafts and special devices; and their parts"
temp_param_table$desc[79] <- "Glass and its works"
temp_param_table$desc[78] <- "Knitwear clothing and its accessories"
temp_param_table$desc[77] <- "Special fabrics; tufted fabrics; laces; tapestries; trimmings; embroideries"
temp_param_table$desc[76] <- "Tobbaco and its manufactured substitutes"
temp_param_table$desc[75] <- "Products for photography and cinematography"
temp_param_table$desc[74] <- "Pharmaceutical products"
temp_param_table$desc[73] <- "Cereal based, flours, starches, starches products or milk preparations; pastry products"
temp_param_table$desc[72] <- "Live plants and floriculture products"
temp_param_table$desc[71] <- "Pelt, except furred pelt, and leathers"
temp_param_table$desc[70] <- "Other common metals; cermets; these matters works"
temp_param_table$desc[69] <- "Other vegetal textile fibers; paper threads and paper threads fabrics"
temp_param_table$desc[68] <- "Various works of common metals"
temp_param_table$desc[67] <- "Sparto or basketry works"
temp_param_table$desc[66] <- "Materials for plaiting and other vegetable products, not specified nor contained in other Chapters"
temp_param_table$desc[65] <- "Books, newspapers, engravings and other graphic industry products; handwritten texts"
temp_param_table$desc[64] <- "Synthetic or natural filaments"
temp_param_table$desc[63] <- "Tanning and dyeing extracts; tannins and their derivatives; pigments and other colouring matter"
temp_param_table$desc[62] <- "Boats and floating structures"
temp_param_table$desc[61] <- "Mineral fuels, mineram oils and products of their destiltion; bitunimous substances; wax"
temp_param_table$desc[60] <- "Cooper and its works"
temp_param_table$desc[59] <- "Hats and similar purpose artifacts, and their parts"
temp_param_table$desc[58] <- "Aluminum and its works"
temp_param_table$desc[57] <- "Fertilizers"
temp_param_table$desc[56] <- "Footwear, gaiters and similar artifacts; their parts"
temp_param_table$desc[55] <- "Organic chemicals"
temp_param_table$desc[54] <- "Cotton"
temp_param_table$desc[53] <- "Automobiles, tractors, mopeds and other terrestrial vehicles, and their parts and accessories"
temp_param_table$desc[52] <- "Fish and crustaceans, mollusks and other aquatic invertebrates"
temp_param_table$desc[51] <- "Essential oils and resinoids; perfumery or toilet preparations products"
temp_param_table$desc[50] <- "Various works"
temp_param_table$desc[49] <- "Stone, plaster, cement, asbestos, mica and similar elements works"
temp_param_table$desc[48] <- "Optic, photography or cinematography, measuring, control or precision instruments or devices"
temp_param_table$desc[47] <- "Cocoa and its preparations"
temp_param_table$desc[46] <- "Toys, games, articles for fun or sports; their parts and accessories"
temp_param_table$desc[45] <- "Rubber and its works"
temp_param_table$desc[44] <- "Meat, fish or crustaceans, mollusks and other aquatic invertebrates preparations"
temp_param_table$desc[43] <- "Various food related preparations"
temp_param_table$desc[42] <- "Milk and derivatives; bird's eggs; natural honey; edible products of animal origin, not"
temp_param_table$desc[41] <- "Vehicles and material for railroads and resemblants, and their parts; mechanical devices (including)"
temp_param_table$desc[40] <- "Salt; sulfur; dirt and stones; plaster, lime and cement"
temp_param_table$desc[39] <- "Natural or cultured pearls, precious or semiprecious stones and resemblants, precious metals"
temp_param_table$desc[38] <- "Beverages, alcoholic liquids and vinegars"
temp_param_table$desc[37] <- "Paper and card; paper or card cellulose paste works"
temp_param_table$desc[36] <- "Albuminoids raw material; modified starch or flour-based products, glues and enzymes"
temp_param_table$desc[35] <- "Machines, devices, electric material and their parts; Recording and playing devices"
temp_param_table$desc[34] <- "Other animal origin products, not speficied nor contained in other Chapters"
temp_param_table$desc[33] <- "Cast iron, iron or steel"
temp_param_table$desc[32] <- "Edible meat and offal"
temp_param_table$desc[31] <- "Coffee, tea, mate and spices"
temp_param_table$desc[30] <- "Sugar and confectionary products"
temp_param_table$desc[29] <- "Clothing and its accessories, except knitwear"
temp_param_table$desc[28] <- "Special transactions"
temp_param_table$desc[27] <- "Oilseeds and oilseed fruits; grains, seeds and various fruits; industrial or medical plants"
temp_param_table$desc[26] <- "Soaps, surface-active organic agents, washing prepartions, lubricating preparations"
temp_param_table$desc[25] <- "Food industry waste and residuals; food made for animals"
temp_param_table$desc[24] <- "Nuclear reactors, boilers, mechanical instruments and devices and their parts"
temp_param_table$desc[23] <- "Edible horticultural products, plants, roots, and tubers"
temp_param_table$desc[22] <- "Various products from the chemical industry"
temp_param_table$desc[21] <- "Grinding industry products; malt; starches and flours; inulin; wheat gluten"
temp_param_table$desc[20] <- "Pottery products"
temp_param_table$desc[19] <- "Horticultural products, fruit and other plant parts preparation"
temp_param_table$desc[18] <- "Plastic and its works"
temp_param_table$desc[17] <-  "Wood or other celullose fiber materials pastes; Paper or card for recycling"
temp_param_table$desc[16] <- "Batt, felt and fake cloth; Special; Special threads; Twines, ropes and cables; Articles of"
temp_param_table$desc[15] <- "Other manufactured textile artifacts; Sorted itens; textile raw materials artifacts, footwear"
temp_param_table$desc[14] <- "Cast iron, iron or steel"
temp_param_table$desc[13] <- "Leather works; Trapecial straps or saddles; Travel articles, purses and similar artifacts"
temp_param_table$desc[12] <- "Art and collection objects and antiques"
temp_param_table$desc[11] <- "Furniture; Medic surgery furniture, matresses, pillows and resemblants; Lighten devices"
temp_param_table$desc[10] <- "Minerals, slag and ashes"
temp_param_table$desc[9] <- "Wood, charcoal and woodcraft"
temp_param_table$desc[8] <-"Fats and vegetable or animal oils; their dissociation products; processed food fats"
temp_param_table$desc[7] <- "Gum, resins and other vegetable juices and extracts"
temp_param_table$desc[6] <- "Fruit; Citrus fruits and melon peel"
temp_param_table$desc[5] <- "Tools, cutlery artifacts and silverware and their made of metal parts"
temp_param_table$desc[4] <- "Cereals"
temp_param_table$desc[3] <- "Live animals"
temp_param_table$desc[2] <- "Municipality"
temp_param_table$desc[1] <- "Year"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 96))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 96))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_sh2_munic_en_dic.csv", fileEncoding = "UTF-8")




### exportação municipal da amazônia por tipo sec inglês
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
    categoria= "Economy", 
    subcategoria = "Trade"
)

temp_param_table$label[2] <- "Sec production"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[2] <- "Sec production"
temp_param_table$desc[1] <- "Year"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 418))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 418))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 418))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_munic_sec_en_dic.csv", fileEncoding = "UTF-8")




### exportação municipal da amazônia por tipo sec inglês
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
    categoria= "Economy", 
    subcategoria = "Trade"
)

temp_param_table$label[98] <- "Guns and ammunition; their parts and accessories"
temp_param_table$label[97] <- "Wool, thin or thick fur; threads and hair fabrics"
temp_param_table$label[96] <- "Non-continuous synthetic or artificial fibers"
temp_param_table$label[95] <- "Cork and its works"
temp_param_table$label[94] <- "Lead and its works"
temp_param_table$label[93] <- "Zinc and its works"
temp_param_table$label[92] <- "Knitwear fabrics"
temp_param_table$label[91] <- "Carpets and other textile floor coverings"
temp_param_table$label[90] <- "Gunpowder and explosives; fireworks; matches; pyrophoric alloys; flammable materials"
temp_param_table$label[89] <- "Feathers and prepared plumage and their works; artificial flowers; hair works"
temp_param_table$label[88] <- "Furred pelts and theis crafts; pelt with artificial fur"
temp_param_table$label[87] <- "Musical instruments; their parts and accessories"
temp_param_table$label[86] <- "Umbrellas, parasols, sunshades, canes, seat canes, whips, walking sticks"
temp_param_table$label[85] <- "Watch articles"
temp_param_table$label[84] <- "Nickel and its works"
temp_param_table$label[83] <- "Impregnated, coated, covered or laminated fabrics; technical use articles"
temp_param_table$label[82] <- "Inorganic chemicals; precious metals organic or inorganic compunds"
temp_param_table$label[81] <- "Tin and its works"
temp_param_table$label[80] <- "Aircrafts and special devices; and their parts"
temp_param_table$label[79] <- "Glass and its works"
temp_param_table$label[78] <- "Knitwear clothing and its accessories"
temp_param_table$label[77] <- "Special fabrics; tufted fabrics; laces; tapestries; trimmings; embroideries"
temp_param_table$label[76] <- "Tobbaco and its manufactured substitutes"
temp_param_table$label[75] <- "Products for photography and cinematography"
temp_param_table$label[74] <- "Pharmaceutical products"
temp_param_table$label[73] <- "Cereal based, flours, starches, starches products or milk preparations; pastry products"
temp_param_table$label[72] <- "Live plants and floriculture products"
temp_param_table$label[71] <- "Pelt, except furred pelt, and leathers"
temp_param_table$label[70] <- "Other common metals; cermets; these matters works"
temp_param_table$label[69] <- "Other vegetal textile fibers; paper threads and paper threads fabrics"
temp_param_table$label[68] <- "Various works of common metals"
temp_param_table$label[67] <- "Sparto or basketry works"
temp_param_table$label[66] <- "Materials for plaiting and other vegetable products, not specified nor contained in other Chapters"
temp_param_table$label[65] <- "Books, newspapers, engravings and other graphic industry products; handwritten texts"
temp_param_table$label[64] <- "Synthetic or natural filaments"
temp_param_table$label[63] <- "Tanning and dyeing extracts; tannins and their derivatives; pigments and other colouring matter"
temp_param_table$label[62] <- "Boats and floating structures"
temp_param_table$label[61] <- "Mineral fuels, mineram oils and products of their destiltion; bitunimous substances; wax"
temp_param_table$label[60] <- "Cooper and its works"
temp_param_table$label[59] <- "Hats and similar purpose artifacts, and their parts"
temp_param_table$label[58] <- "Aluminum and its works"
temp_param_table$label[57] <- "Fertilizers"
temp_param_table$label[56] <- "Footwear, gaiters and similar artifacts; their parts"
temp_param_table$label[55] <- "Organic chemicals"
temp_param_table$label[54] <- "Cotton"
temp_param_table$label[53] <- "Automobiles, tractors, mopeds and other terrestrial vehicles, and their parts and accessories"
temp_param_table$label[52] <- "Fish and crustaceans, mollusks and other aquatic invertebrates"
temp_param_table$label[51] <- "Essential oils and resinoids; perfumery or toilet preparations products"
temp_param_table$label[50] <- "Various works"
temp_param_table$label[49] <- "Stone, plaster, cement, asbestos, mica and similar elements works"
temp_param_table$label[48] <- "Optic, photography or cinematography, measuring, control or precision instruments or devices"
temp_param_table$label[47] <- "Cocoa and its preparations"
temp_param_table$label[46] <- "Toys, games, articles for fun or sports; their parts and accessories"
temp_param_table$label[45] <- "Rubber and its works"
temp_param_table$label[44] <- "Meat, fish or crustaceans, mollusks and other aquatic invertebrates preparations"
temp_param_table$label[43] <- "Various food related preparations"
temp_param_table$label[42] <- "Milk and derivatives; bird's eggs; natural honey; edible products of animal origin, not"
temp_param_table$label[41] <- "Vehicles and material for railroads and resemblants, and their parts; mechanical devices (including)"
temp_param_table$label[40] <- "Salt; sulfur; dirt and stones; plaster, lime and cement"
temp_param_table$label[39] <- "Natural or cultured pearls, precious or semiprecious stones and resemblants, precious metals"
temp_param_table$label[38] <- "Beverages, alcoholic liquids and vinegars"
temp_param_table$label[37] <- "Paper and card; paper or card cellulose paste works"
temp_param_table$label[36] <- "Albuminoids raw material; modified starch or flour-based products, glues and enzymes"
temp_param_table$label[35] <- "Machines, devices, electric material and their parts; Recording and playing devices"
temp_param_table$label[34] <- "Other animal origin products, not specified nor contained in other Chapters"
temp_param_table$label[33] <- "Cast iron, iron or steel"
temp_param_table$label[32] <- "Edible meat and offal"
temp_param_table$label[31] <- "Coffee, tea, mate and spices"
temp_param_table$label[30] <- "Sugar and confectionary products"
temp_param_table$label[29] <- "Clothing and its accessories, except knitwear"
temp_param_table$label[28] <- "Special transactions"
temp_param_table$label[27] <- "Oilseeds and oilseed fruits; grains, seeds and various fruits; industrial or medical plants"
temp_param_table$label[26] <- "Soaps, surface-active organic agents, washing prepartions, lubricating preparations"
temp_param_table$label[25] <- "Food industry waste and residuals; food made for animals"
temp_param_table$label[24] <- "Nuclear reactors, boilers, mechanical instruments and devices and their parts"
temp_param_table$label[23] <- "Edible horticultural products, plants, roots, and tubers"
temp_param_table$label[22] <- "Various products from the chemical industry"
temp_param_table$label[21] <- "Grinding industry products; malt; starches and flours; inulin; wheat gluten"
temp_param_table$label[20] <- "Pottery products"
temp_param_table$label[19] <- "Horticultural products, fruit and other plant parts preparation"
temp_param_table$label[18] <- "Plastic and its works"
temp_param_table$label[17] <- "Wood or other celullose fiber materials pastes; Paper or card for recycling"
temp_param_table$label[16] <- "Batt, felt and fake cloth; Special; Special threads; Twines, ropes and cables; Articles of"
temp_param_table$label[15] <- "Other manufactured textile artifacts; Sorted itens; textile raw materials artifacts, footwear"
temp_param_table$label[14] <- "Cast iron, iron or steel"
temp_param_table$label[13] <- "Leather works; Trapecial straps or saddles; Travel articles, purses and similar artifacts"
temp_param_table$label[12] <- "Art and collection objects and antiques"
temp_param_table$label[11] <- "Furniture; Medic surgery furniture, matresses, pillows and resemblants; Lighten devices"
temp_param_table$label[10] <- "Minerals, slag and ashes"
temp_param_table$label[9] <- "Wood, charcoal and woodcraft"
temp_param_table$label[8] <- "Fats and vegetable or animal oils; their dissociation products; processed food fats"
temp_param_table$label[7] <- "Gum, resins and other vegetable juices and extracts"
temp_param_table$label[6] <- "Fruit; Citrus fruits and melon peel"
temp_param_table$label[5] <- "Tools, cutlery artifacts and silverware and their made of metal parts"
temp_param_table$label[4] <- "Cereals"
temp_param_table$label[3] <- "Live animals"
temp_param_table$label[2] <- "Municipality"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[98] <- "Guns and ammunition; their parts and accessories"
temp_param_table$desc[97] <- "Wool, thin or thick fur; threads and hair fabrics"
temp_param_table$desc[96] <- "Non-continuous synthetic or artificial fibers"
temp_param_table$desc[95] <- "Cork and its works"
temp_param_table$desc[94] <- "Lead and its works"
temp_param_table$desc[93] <- "Zinc and its works"
temp_param_table$desc[92] <- "Knitwear fabrics"
temp_param_table$desc[91] <- "Carpets and other textile floor coverings"
temp_param_table$desc[90] <- "Gunpowder and explosives; fireworks; matches; pyrophoric alloys; flammable materials"
temp_param_table$desc[89] <- "Feathers and prepared plumage and their works; artificial flowers; hair works"
temp_param_table$desc[88] <- "Furred pelts and theis crafts; pelt with artificial fur"
temp_param_table$desc[87] <- "Musical instruments; their parts and accessories"
temp_param_table$desc[86] <- "Umbrellas, parasols, sunshades, canes, seat canes, whips, walking sticks"
temp_param_table$desc[85] <- "Watch articles"
temp_param_table$desc[84] <- "Nickel and its works"
temp_param_table$desc[83] <- "Impregnated, coated, covered or laminated fabrics; technical use articles"
temp_param_table$desc[82] <- "Inorganic chemicals; precious metals organic or inorganic compunds"
temp_param_table$desc[81] <- "Tin and its works"
temp_param_table$desc[80] <- "Aircrafts and special devices; and their parts"
temp_param_table$desc[79] <- "Glass and its works"
temp_param_table$desc[78] <- "Knitwear clothing and its accessories"
temp_param_table$desc[77] <- "Special fabrics; tufted fabrics; laces; tapestries; trimmings; embroideries"
temp_param_table$desc[76] <- "Tobbaco and its manufactured substitutes"
temp_param_table$desc[75] <- "Products for photography and cinematography"
temp_param_table$desc[74] <- "Pharmaceutical products"
temp_param_table$desc[73] <- "Cereal based, flours, starches, starches products or milk preparations; pastry products"
temp_param_table$desc[72] <- "Live plants and floriculture products"
temp_param_table$desc[71] <- "Pelt, except furred pelt, and leathers"
temp_param_table$desc[70] <- "Other common metals; cermets; these matters works"
temp_param_table$desc[69] <- "Other vegetal textile fibers; paper threads and paper threads fabrics"
temp_param_table$desc[68] <- "Various works of common metals"
temp_param_table$desc[67] <- "Sparto or basketry works"
temp_param_table$desc[66] <- "Materials for plaiting and other vegetable products, not specified nor contained in other Chapters"
temp_param_table$desc[65] <- "Books, newspapers, engravings and other graphic industry products; handwritten texts"
temp_param_table$desc[64] <- "Synthetic or natural filaments"
temp_param_table$desc[63] <- "Tanning and dyeing extracts; tannins and their derivatives; pigments and other colouring matter"
temp_param_table$desc[62] <- "Boats and floating structures"
temp_param_table$desc[61] <- "Mineral fuels, mineram oils and products of their destiltion; bitunimous substances; wax"
temp_param_table$desc[60] <- "Cooper and its works"
temp_param_table$desc[59] <- "Hats and similar purpose artifacts, and their parts"
temp_param_table$desc[58] <- "Aluminum and its works"
temp_param_table$desc[57] <- "Fertilizers"
temp_param_table$desc[56] <- "Footwear, gaiters and similar artifacts; their parts"
temp_param_table$desc[55] <- "Organic chemicals"
temp_param_table$desc[54] <- "Cotton"
temp_param_table$desc[53] <- "Automobiles, tractors, mopeds and other terrestrial vehicles, and their parts and accessories"
temp_param_table$desc[52] <- "Fish and crustaceans, mollusks and other aquatic invertebrates"
temp_param_table$desc[51] <- "Essential oils and resinoids; perfumery or toilet preparations products"
temp_param_table$desc[50] <- "Various works"
temp_param_table$desc[49] <- "Stone, plaster, cement, asbestos, mica and similar elements works"
temp_param_table$desc[48] <- "Optic, photography or cinematography, measuring, control or precision instruments or devices"
temp_param_table$desc[47] <- "Cocoa and its preparations"
temp_param_table$desc[46] <- "Toys, games, articles for fun or sports; their parts and accessories"
temp_param_table$desc[45] <- "Rubber and its works"
temp_param_table$desc[44] <- "Meat, fish or crustaceans, mollusks and other aquatic invertebrates preparations"
temp_param_table$desc[43] <- "Various food related preparations"
temp_param_table$desc[42] <- "Milk and derivatives; bird's eggs; natural honey; edible products of animal origin, not"
temp_param_table$desc[41] <- "Vehicles and material for railroads and resemblants, and their parts; mechanical devices (including)"
temp_param_table$desc[40] <- "Salt; sulfur; dirt and stones; plaster, lime and cement"
temp_param_table$desc[39] <- "Natural or cultured pearls, precious or semiprecious stones and resemblants, precious metals"
temp_param_table$desc[38] <- "Beverages, alcoholic liquids and vinegars"
temp_param_table$desc[37] <- "Paper and card; paper or card cellulose paste works"
temp_param_table$desc[36] <- "Albuminoids raw material; modified starch or flour-based products, glues and enzymes"
temp_param_table$desc[35] <- "Machines, devices, electric material and their parts; Recording and playing devices"
temp_param_table$desc[34] <- "Other animal origin products, not speficied nor contained in other Chapters"
temp_param_table$desc[33] <- "Cast iron, iron or steel"
temp_param_table$desc[32] <- "Edible meat and offal"
temp_param_table$desc[31] <- "Coffee, tea, mate and spices"
temp_param_table$desc[30] <- "Sugar and confectionary products"
temp_param_table$desc[29] <- "Clothing and its accessories, except knitwear"
temp_param_table$desc[28] <- "Special transactions"
temp_param_table$desc[27] <- "Oilseeds and oilseed fruits; grains, seeds and various fruits; industrial or medical plants"
temp_param_table$desc[26] <- "Soaps, surface-active organic agents, washing prepartions, lubricating preparations"
temp_param_table$desc[25] <- "Food industry waste and residuals; food made for animals"
temp_param_table$desc[24] <- "Nuclear reactors, boilers, mechanical instruments and devices and their parts"
temp_param_table$desc[23] <- "Edible horticultural products, plants, roots, and tubers"
temp_param_table$desc[22] <- "Various products from the chemical industry"
temp_param_table$desc[21] <- "Grinding industry products; malt; starches and flours; inulin; wheat gluten"
temp_param_table$desc[20] <- "Pottery products"
temp_param_table$desc[19] <- "Horticultural products, fruit and other plant parts preparation"
temp_param_table$desc[18] <- "Plastic and its works"
temp_param_table$desc[17] <-  "Wood or other celullose fiber materials pastes; Paper or card for recycling"
temp_param_table$desc[16] <- "Batt, felt and fake cloth; Special; Special threads; Twines, ropes and cables; Articles of"
temp_param_table$desc[15] <- "Other manufactured textile artifacts; Sorted itens; textile raw materials artifacts, footwear"
temp_param_table$desc[14] <- "Cast iron, iron or steel"
temp_param_table$desc[13] <- "Leather works; Trapecial straps or saddles; Travel articles, purses and similar artifacts"
temp_param_table$desc[12] <- "Art and collection objects and antiques"
temp_param_table$desc[11] <- "Furniture; Medic surgery furniture, matresses, pillows and resemblants; Lighten devices"
temp_param_table$desc[10] <- "Minerals, slag and ashes"
temp_param_table$desc[9] <- "Wood, charcoal and woodcraft"
temp_param_table$desc[8] <-"Fats and vegetable or animal oils; their dissociation products; processed food fats"
temp_param_table$desc[7] <- "Gum, resins and other vegetable juices and extracts"
temp_param_table$desc[6] <- "Fruit; Citrus fruits and melon peel"
temp_param_table$desc[5] <- "Tools, cutlery artifacts and silverware and their made of metal parts"
temp_param_table$desc[4] <- "Cereals"
temp_param_table$desc[3] <- "Live animals"
temp_param_table$desc[2] <- "Municipality"
temp_param_table$desc[1] <- "Year"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 96))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 96))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 96))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_sec_munic_en_dic.csv", fileEncoding = "UTF-8")




### exportação total da amazônia por tipo sh2 inglês
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
    categoria= "Economy", 
    subcategoria = "Trade"
)

temp_param_table$label[2] <- "Region"
temp_param_table$label[1] <- "Year"
temp_param_table$label[3] <- "Value"
temp_param_table$desc[2] <- "Region"
temp_param_table$desc[1] <- "Year"
temp_param_table$desc[3] <- "Value"
temp_param_table$x <- c(FALSE, FALSE, TRUE)
temp_param_table$y <- c(FALSE, FALSE, TRUE)
temp_param_table$color <- c(FALSE, TRUE, FALSE)
temp_param_table$size <- c(FALSE, FALSE, TRUE)
temp_param_table$slider <- c(FALSE, FALSE, TRUE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_tot_sh2_en_dic.csv", fileEncoding = "UTF-8")







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
    categoria= "Economy", 
    subcategoria = "Trade"
)

temp_param_table$label[3] <- "Afghanistan"
temp_param_table$label[4] <- "South Africa"
temp_param_table$label[5] <- "Albania"
temp_param_table$label[6] <- "Germany"
temp_param_table$label[7] <- "Angola"
temp_param_table$label[8] <- "Antigua and Barbuda"
temp_param_table$label[9] <- "Netherlands Antilles"
temp_param_table$label[10] <- "Saudi Arabia"
temp_param_table$label[11] <- "Algeria"
temp_param_table$label[12] <- "Argentina"
temp_param_table$label[13] <- "Armenia"
temp_param_table$label[14] <- "Aruba"
temp_param_table$label[15] <- "Australia"
temp_param_table$label[16] <- "Austria"
temp_param_table$label[17] <- "Azerbaijan"
temp_param_table$label[18] <- "Bahamas"
temp_param_table$label[19] <- "Bahrain"
temp_param_table$label[20] <- "Bangladesh"
temp_param_table$label[21] <- "Barbados"
temp_param_table$label[22] <- "Belgium"
temp_param_table$label[23] <- "Belize"
temp_param_table$label[24] <- "Bermuda"
temp_param_table$label[25] <- "Bolivia"
temp_param_table$label[26] <- "Bonaire, Saint Eustatius and Saba"
temp_param_table$label[27] <- "Bosnia and Herzegovina"
temp_param_table$label[28] <- "Botswana"
temp_param_table$label[29] <- "Brazil"
temp_param_table$label[30] <- "Brunei"
temp_param_table$label[31] <- "Bulgaria"
temp_param_table$label[32] <- "Burkina Faso"
temp_param_table$label[33] <- "Cape Verde"
temp_param_table$label[34] <- "Cameroon"
temp_param_table$label[35] <- "Cambodia"
temp_param_table$label[36] <- "Canada"
temp_param_table$label[37] <- "Canary Islands"
temp_param_table$label[38] <- "Qatar"
temp_param_table$label[39] <- "Cayman Islands"
temp_param_table$label[40] <- "Kazakhstan"
temp_param_table$label[41] <- "Chile"
temp_param_table$label[42] <- "China"
temp_param_table$label[43] <- "Cyprus"
temp_param_table$label[44] <- "Singapore"
temp_param_table$label[45] <- "Colombia"
temp_param_table$label[46] <- "Comoros"
temp_param_table$label[47] <- "Congo"
temp_param_table$label[48] <- "North Korea"
temp_param_table$label[49] <- "South Korea"
temp_param_table$label[50] <- "Ivory Coast"
temp_param_table$label[51] <- "Costa Rica"
temp_param_table$label[52] <- "Croatia"
temp_param_table$label[53] <- "Cuba"
temp_param_table$label[54] <- "Curaçao"
temp_param_table$label[55] <- "Denmark"
temp_param_table$label[56] <- "Djibouti"
temp_param_table$label[57] <- "Egypt"
temp_param_table$label[58] <- "United Arab Emirates"
temp_param_table$label[59] <- "Ecuador"
temp_param_table$label[60] <- "Slovenia"
temp_param_table$label[61] <- "Spain"
temp_param_table$label[62] <- "United States"
temp_param_table$label[63] <- "Estonia"
temp_param_table$label[64] <- "Falkland Islands"
temp_param_table$label[65] <- "Faroe Islands"
temp_param_table$label[66] <- "Philippines"
temp_param_table$label[67] <- "Finland"
temp_param_table$label[68] <- "France"
temp_param_table$label[69] <- "Gabon"
temp_param_table$label[70] <- "Gambia"
temp_param_table$label[71] <- "Ghana"
temp_param_table$label[72] <- "Georgia"
temp_param_table$label[73] <- "Gibraltar"
temp_param_table$label[74] <- "Granada"
temp_param_table$label[75] <- "Greece"
temp_param_table$label[76] <- "Guadeloupe"
temp_param_table$label[77] <- "Guyana"
temp_param_table$label[78] <- "French Guiana"
temp_param_table$label[79] <- "Guinea"
temp_param_table$label[80] <- "Equatorial Guinea"
temp_param_table$label[81] <- "Haiti"
temp_param_table$label[82] <- "Honduras"
temp_param_table$label[83] <- "Hong Kong"
temp_param_table$label[84] <- "Hungary"
temp_param_table$label[85] <- "Yemen"
temp_param_table$label[86] <- "India"
temp_param_table$label[87] <- "Indonesia"
temp_param_table$label[88] <- "Iran"
temp_param_table$label[89] <- "Iraq"
temp_param_table$label[90] <- "Ireland"
temp_param_table$label[91] <- "Iceland"
temp_param_table$label[92] <- "Israel"
temp_param_table$label[93] <- "Italy"
temp_param_table$label[94] <- "Jamaica"
temp_param_table$label[95] <- "Japan"
temp_param_table$label[96] <- "Jordan"
temp_param_table$label[97] <- "Kuwait"
temp_param_table$label[98] <- "Laos"
temp_param_table$label[99] <- "Latvia"
temp_param_table$label[100] <- "Lebanon"
temp_param_table$label[101] <- "Liberia"
temp_param_table$label[102] <- "Libya"
temp_param_table$label[103] <- "Lithuania"
temp_param_table$label[104] <- "Luxembourg"
temp_param_table$label[105] <- "Macau"
temp_param_table$label[106] <- "North Macedonia"
temp_param_table$label[107] <- "Madagascar"
temp_param_table$label[108] <- "Malaysia"
temp_param_table$label[109] <- "Maldives"
temp_param_table$label[110] <- "Mali"
temp_param_table$label[111] <- "Malta"
temp_param_table$label[112] <- "Isle of Man"
temp_param_table$label[113] <- "Morocco"
temp_param_table$label[114] <- "Marshall Islands"
temp_param_table$label[115] <- "Martinique"
temp_param_table$label[116] <- "Mauritius"
temp_param_table$label[117] <- "Mauritania"
temp_param_table$label[118] <- "Mexico"
temp_param_table$label[119] <- "Myanmar"
temp_param_table$label[120] <- "Mozambique"
temp_param_table$label[121] <- "Moldova"
temp_param_table$label[122] <- "Monaco"
temp_param_table$label[123] <- "Mongolia"
temp_param_table$label[124] <- "Montenegro"
temp_param_table$label[125] <- "Namibia"
temp_param_table$label[126] <- "Niger"
temp_param_table$label[127] <- "Norway"
temp_param_table$label[128] <- "New Zealand"
temp_param_table$label[129] <- "Oman"
temp_param_table$label[130] <- "Pacific Islands (USA)"
temp_param_table$label[131] <- "Netherlands"
temp_param_table$label[132] <- "Palestine"
temp_param_table$label[133] <- "Panama"
temp_param_table$label[134] <- "Pakistan"
temp_param_table$label[135] <- "Paraguay"
temp_param_table$label[136] <- "Peru"
temp_param_table$label[137] <- "Poland"
temp_param_table$label[138] <- "Puerto Rico"
temp_param_table$label[139] <- "Portugal"
temp_param_table$label[140] <- "Kyrgyzstan"
temp_param_table$label[141] <- "United Kingdom"
temp_param_table$label[142] <- "Central African Republic"
temp_param_table$label[143] <- "Democratic Republic of Congo"
temp_param_table$label[144] <- "Dominican Republic"
temp_param_table$label[145] <- "Czech Republic"
temp_param_table$label[146] <- "Reunion"
temp_param_table$label[147] <- "Romania"
temp_param_table$label[148] <- "Russia"
temp_param_table$label[149] <- "Western Sahara"
temp_param_table$label[150] <- "Solomon Islands"
temp_param_table$label[151] <- "San Marino"
temp_param_table$label[152] <- "Saint Martin (French part)"
temp_param_table$label[153] <- "Saint Martin (Dutch part)"
temp_param_table$label[154] <- "São Tomé and Príncipe"
temp_param_table$label[155] <- "Saint Vincent and the Grenadines"
temp_param_table$label[156] <- "Senegal"
temp_param_table$label[157] <- "Sierra Leone"
temp_param_table$label[158] <- "Serbia"
temp_param_table$label[159] <- "Seychelles"
temp_param_table$label[160] <- "Syria"
temp_param_table$label[161] <- "Sri Lanka"
temp_param_table$label[162] <- "Sweden"
temp_param_table$label[163] <- "Switzerland"
temp_param_table$label[164] <- "Suriname"
temp_param_table$label[165] <- "Thailand"
temp_param_table$label[166] <- "Taiwan (Formosa)"
temp_param_table$label[167] <- "Tanzania"
temp_param_table$label[168] <- "Togo"
temp_param_table$label[169] <- "Tonga"
temp_param_table$label[170] <- "Trinidad and Tobago"
temp_param_table$label[171] <- "Tunisia"
temp_param_table$label[172] <- "Turkmenistan"
temp_param_table$label[173] <- "Turkey"
temp_param_table$label[174] <- "Ukraine"
temp_param_table$label[175] <- "Uruguay"
temp_param_table$label[176] <- "Uzbekistan"
temp_param_table$label[177] <- "Vanuatu"
temp_param_table$label[178] <- "Venezuela"
temp_param_table$label[179] <- "Vietnam"
temp_param_table$label[180] <- "British Virgin Islands"
temp_param_table$label[181] <- "Zimbabwe"
temp_param_table$label[182] <- "El Salvador"
temp_param_table$label[183] <- "Guatemala"
temp_param_table$label[184] <- "Papua New Guinea"
temp_param_table$label[185] <- "Belarus"
temp_param_table$label[186] <- "Benin"
temp_param_table$label[187] <- "Dominica"
temp_param_table$label[188] <- "Nicaragua"
temp_param_table$label[189] <- "Kenya"
temp_param_table$label[190] <- "Saint Helena"
temp_param_table$label[191] <- "Saint Kitts and Nevis"
temp_param_table$label[192] <- "Slovakia"
temp_param_table$label[193] <- "Andorra"
temp_param_table$label[194] <- "Anguilla"
temp_param_table$label[195] <- "Eswatini (formerly Swaziland)"
temp_param_table$label[196] <- "Ethiopia"
temp_param_table$label[197] <- "Fiji"
temp_param_table$label[198] <- "Liechtenstein"
temp_param_table$label[199] <- "Nigeria"
temp_param_table$label[200] <- "Norfolk Island"
temp_param_table$label[201] <- "New Caledonia"
temp_param_table$label[202] <- "French Polynesia"
temp_param_table$label[203] <- "Saint Lucia"
temp_param_table$label[204] <- "Somalia"
temp_param_table$label[205] <- "British Indian Ocean Territory"
temp_param_table$label[206] <- "Turks and Caicos Islands"
temp_param_table$label[207] <- "Uganda"
temp_param_table$label[208] <- "United States Virgin Islands"
temp_param_table$label[209] <- "Zambia"
temp_param_table$label[210] <- "Chad"
temp_param_table$label[211] <- "Malawi"
temp_param_table$label[212] <- "Nepal"
temp_param_table$label[213] <- "Rwanda"
temp_param_table$label[214] <- "Sudan"
temp_param_table$label[215] <- "Tuvalu"
temp_param_table$label[216] <- "Cook Islands"
temp_param_table$label[217] <- "Guinea-Bissau"
temp_param_table$label[218] <- "Lesotho"
temp_param_table$label[219] <- "Palau"
temp_param_table$label[220] <- "Midway Islands"
temp_param_table$label[221] <- "Bouvet Island"
temp_param_table$label[222] <- "Madeira Island"
temp_param_table$label[223] <- "Wallis and Futuna Islands"
temp_param_table$label[2] <- "Country"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[3] <- "Afghanistan"
temp_param_table$desc[4] <- "South Africa"
temp_param_table$desc[5] <- "Albania"
temp_param_table$desc[6] <- "Germany"
temp_param_table$desc[7] <- "Angola"
temp_param_table$desc[8] <- "Antigua and Barbuda"
temp_param_table$desc[9] <- "Netherlands Antilles"
temp_param_table$desc[10] <- "Saudi Arabia"
temp_param_table$desc[11] <- "Algeria"
temp_param_table$desc[12] <- "Argentina"
temp_param_table$desc[13] <- "Armenia"
temp_param_table$desc[14] <- "Aruba"
temp_param_table$desc[15] <- "Australia"
temp_param_table$desc[16] <- "Austria"
temp_param_table$desc[17] <- "Azerbaijan"
temp_param_table$desc[18] <- "Bahamas"
temp_param_table$desc[19] <- "Bahrain"
temp_param_table$desc[20] <- "Bangladesh"
temp_param_table$desc[21] <- "Barbados"
temp_param_table$desc[22] <- "Belgium"
temp_param_table$desc[23] <- "Belize"
temp_param_table$desc[24] <- "Bermuda"
temp_param_table$desc[25] <- "Bolivia"
temp_param_table$desc[26] <- "Bonaire, Saint Eustatius and Saba"
temp_param_table$desc[27] <- "Bosnia and Herzegovina"
temp_param_table$desc[28] <- "Botswana"
temp_param_table$desc[29] <- "Brazil"
temp_param_table$desc[30] <- "Brunei"
temp_param_table$desc[31] <- "Bulgaria"
temp_param_table$desc[32] <- "Burkina Faso"
temp_param_table$desc[33] <- "Cape Verde"
temp_param_table$desc[34] <- "Cameroon"
temp_param_table$desc[35] <- "Cambodia"
temp_param_table$desc[36] <- "Canada"
temp_param_table$desc[37] <- "Canary Islands"
temp_param_table$desc[38] <- "Qatar"
temp_param_table$desc[39] <- "Cayman Islands"
temp_param_table$desc[40] <- "Kazakhstan"
temp_param_table$desc[41] <- "Chile"
temp_param_table$desc[42] <- "China"
temp_param_table$desc[43] <- "Cyprus"
temp_param_table$desc[44] <- "Singapore"
temp_param_table$desc[45] <- "Colombia"
temp_param_table$desc[46] <- "Comoros"
temp_param_table$desc[47] <- "Congo"
temp_param_table$desc[48] <- "North Korea"
temp_param_table$desc[49] <- "South Korea"
temp_param_table$desc[50] <- "Ivory Coast"
temp_param_table$desc[51] <- "Costa Rica"
temp_param_table$desc[52] <- "Croatia"
temp_param_table$desc[53] <- "Cuba"
temp_param_table$desc[54] <- "Curaçao"
temp_param_table$desc[55] <- "Denmark"
temp_param_table$desc[56] <- "Djibouti"
temp_param_table$desc[57] <- "Egypt"
temp_param_table$desc[58] <- "United Arab Emirates"
temp_param_table$desc[59] <- "Ecuador"
temp_param_table$desc[60] <- "Slovenia"
temp_param_table$desc[61] <- "Spain"
temp_param_table$desc[62] <- "United States"
temp_param_table$desc[63] <- "Estonia"
temp_param_table$desc[64] <- "Falkland Islands"
temp_param_table$desc[65] <- "Faroe Islands"
temp_param_table$desc[66] <- "Philippines"
temp_param_table$desc[67] <- "Finland"
temp_param_table$desc[68] <- "France"
temp_param_table$desc[69] <- "Gabon"
temp_param_table$desc[70] <- "Gambia"
temp_param_table$desc[71] <- "Ghana"
temp_param_table$desc[72] <- "Georgia"
temp_param_table$desc[73] <- "Gibraltar"
temp_param_table$desc[74] <- "Granada"
temp_param_table$desc[75] <- "Greece"
temp_param_table$desc[76] <- "Guadeloupe"
temp_param_table$desc[77] <- "Guyana"
temp_param_table$desc[78] <- "French Guiana"
temp_param_table$desc[79] <- "Guinea"
temp_param_table$desc[80] <- "Equatorial Guinea"
temp_param_table$desc[81] <- "Haiti"
temp_param_table$desc[82] <- "Honduras"
temp_param_table$desc[83] <- "Hong Kong"
temp_param_table$desc[84] <- "Hungary"
temp_param_table$desc[85] <- "Yemen"
temp_param_table$desc[86] <- "India"
temp_param_table$desc[87] <- "Indonesia"
temp_param_table$desc[88] <- "Iran"
temp_param_table$desc[89] <- "Iraq"
temp_param_table$desc[90] <- "Ireland"
temp_param_table$desc[91] <- "Iceland"
temp_param_table$desc[92] <- "Israel"
temp_param_table$desc[93] <- "Italy"
temp_param_table$desc[94] <- "Jamaica"
temp_param_table$desc[95] <- "Japan"
temp_param_table$desc[96] <- "Jordan"
temp_param_table$desc[97] <- "Kuwait"
temp_param_table$desc[98] <- "Laos"
temp_param_table$desc[99] <- "Latvia"
temp_param_table$desc[100] <- "Lebanon"
temp_param_table$desc[101] <- "Liberia"
temp_param_table$desc[102] <- "Libya"
temp_param_table$desc[103] <- "Lithuania"
temp_param_table$desc[104] <- "Luxembourg"
temp_param_table$desc[105] <- "Macau"
temp_param_table$desc[106] <- "North Macedonia"
temp_param_table$desc[107] <- "Madagascar"
temp_param_table$desc[108] <- "Malaysia"
temp_param_table$desc[109] <- "Maldives"
temp_param_table$desc[110] <- "Mali"
temp_param_table$desc[111] <- "Malta"
temp_param_table$desc[112] <- "Isle of Man"
temp_param_table$desc[113] <- "Morocco"
temp_param_table$desc[114] <- "Marshall Islands"
temp_param_table$desc[115] <- "Martinique"
temp_param_table$desc[116] <- "Mauritius"
temp_param_table$desc[117] <- "Mauritania"
temp_param_table$desc[118] <- "Mexico"
temp_param_table$desc[119] <- "Myanmar"
temp_param_table$desc[120] <- "Mozambique"
temp_param_table$desc[121] <- "Moldova"
temp_param_table$desc[122] <- "Monaco"
temp_param_table$desc[123] <- "Mongolia"
temp_param_table$desc[124] <- "Montenegro"
temp_param_table$desc[125] <- "Namibia"
temp_param_table$desc[126] <- "Niger"
temp_param_table$desc[127] <- "Norway"
temp_param_table$desc[128] <- "New Zealand"
temp_param_table$desc[129] <- "Oman"
temp_param_table$desc[130] <- "Pacific Islands (USA)"
temp_param_table$desc[131] <- "Netherlands"
temp_param_table$desc[132] <- "Palestine"
temp_param_table$desc[133] <- "Panama"
temp_param_table$desc[134] <- "Pakistan"
temp_param_table$desc[135] <- "Paraguay"
temp_param_table$desc[136] <- "Peru"
temp_param_table$desc[137] <- "Poland"
temp_param_table$desc[138] <- "Puerto Rico"
temp_param_table$desc[139] <- "Portugal"
temp_param_table$desc[140] <- "Kyrgyzstan"
temp_param_table$desc[141] <- "United Kingdom"
temp_param_table$desc[142] <- "Central African Republic"
temp_param_table$desc[143] <- "Democratic Republic of Congo"
temp_param_table$desc[144] <- "Dominican Republic"
temp_param_table$desc[145] <- "Czech Republic"
temp_param_table$desc[146] <- "Reunion"
temp_param_table$desc[147] <- "Romania"
temp_param_table$desc[148] <- "Russia"
temp_param_table$desc[149] <- "Western Sahara"
temp_param_table$desc[150] <- "Solomon Islands"
temp_param_table$desc[151] <- "San Marino"
temp_param_table$desc[152] <- "Saint Martin (French part)"
temp_param_table$desc[153] <- "Saint Martin (Dutch part)"
temp_param_table$desc[154] <- "São Tomé and Príncipe"
temp_param_table$desc[155] <- "Saint Vincent and the Grenadines"
temp_param_table$desc[156] <- "Senegal"
temp_param_table$desc[157] <- "Sierra Leone"
temp_param_table$desc[158] <- "Serbia"
temp_param_table$desc[159] <- "Seychelles"
temp_param_table$desc[160] <- "Syria"
temp_param_table$desc[161] <- "Sri Lanka"
temp_param_table$desc[162] <- "Sweden"
temp_param_table$desc[163] <- "Switzerland"
temp_param_table$desc[164] <- "Suriname"
temp_param_table$desc[165] <- "Thailand"
temp_param_table$desc[166] <- "Taiwan (Formosa)"
temp_param_table$desc[167] <- "Tanzania"
temp_param_table$desc[168] <- "Togo"
temp_param_table$desc[169] <- "Tonga"
temp_param_table$desc[170] <- "Trinidad and Tobago"
temp_param_table$desc[171] <- "Tunisia"
temp_param_table$desc[172] <- "Turkmenistan"
temp_param_table$desc[173] <- "Turkey"
temp_param_table$desc[174] <- "Ukraine"
temp_param_table$desc[175] <- "Uruguay"
temp_param_table$desc[176] <- "Uzbekistan"
temp_param_table$desc[177] <- "Vanuatu"
temp_param_table$desc[178] <- "Venezuela"
temp_param_table$desc[179] <- "Vietnam"
temp_param_table$desc[180] <- "British Virgin Islands"
temp_param_table$desc[181] <- "Zimbabwe"
temp_param_table$desc[182] <- "El Salvador"
temp_param_table$desc[183] <- "Guatemala"
temp_param_table$desc[184] <- "Papua New Guinea"
temp_param_table$desc[185] <- "Belarus"
temp_param_table$desc[186] <- "Benin"
temp_param_table$desc[187] <- "Dominica"
temp_param_table$desc[188] <- "Nicaragua"
temp_param_table$desc[189] <- "Kenya"
temp_param_table$desc[190] <- "Saint Helena"
temp_param_table$desc[191] <- "Saint Kitts and Nevis"
temp_param_table$desc[192] <- "Slovakia"
temp_param_table$desc[193] <- "Andorra"
temp_param_table$desc[194] <- "Anguilla"
temp_param_table$desc[195] <- "Eswatini (formerly Swaziland)"
temp_param_table$desc[196] <- "Ethiopia"
temp_param_table$desc[197] <- "Fiji"
temp_param_table$desc[198] <- "Liechtenstein"
temp_param_table$desc[199] <- "Nigeria"
temp_param_table$desc[200] <- "Norfolk Island"
temp_param_table$desc[201] <- "New Caledonia"
temp_param_table$desc[202] <- "French Polynesia"
temp_param_table$desc[203] <- "Saint Lucia"
temp_param_table$desc[204] <- "Somalia"
temp_param_table$desc[205] <- "British Indian Ocean Territory"
temp_param_table$desc[206] <- "Turks and Caicos Islands"
temp_param_table$desc[207] <- "Uganda"
temp_param_table$desc[208] <- "United States Virgin Islands"
temp_param_table$desc[209] <- "Zambia"
temp_param_table$desc[210] <- "Chad"
temp_param_table$desc[211] <- "Malawi"
temp_param_table$desc[212] <- "Nepal"
temp_param_table$desc[213] <- "Rwanda"
temp_param_table$desc[214] <- "Sudan"
temp_param_table$desc[215] <- "Tuvalu"
temp_param_table$desc[216] <- "Cook Islands"
temp_param_table$desc[217] <- "Guinea-Bissau"
temp_param_table$desc[218] <- "Lesotho"
temp_param_table$desc[219] <- "Palau"
temp_param_table$desc[220] <- "Midway Islands"
temp_param_table$desc[221] <- "Bouvet Island"
temp_param_table$desc[222] <- "Madeira Island"
temp_param_table$desc[223] <- "Wallis and Futuna Islands"
temp_param_table$desc[2] <- "Country"
temp_param_table$desc[1] <- "Year"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 221))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 221))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 221))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 221))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 221))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_sec_pais_en_dic.csv", fileEncoding = "UTF-8")





### exportação por pais da amazônia por tipo sec inglês
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
    categoria= "Economy", 
    subcategoria = "Trade"
)

temp_param_table$label[24] <- "Special transactions"
temp_param_table$label[23] <- "Mineral products"
temp_param_table$label[22] <- "Plant kingdom products"
temp_param_table$label[21] <- "Food industry products; Beverages, alcoholic liquids and vinegars; Tobacco and its juices"
temp_param_table$label[20] <- "Chemical or related industry products"
temp_param_table$label[19] <- "Plastic and its works; Rubber and its works"
temp_param_table$label[18] <- "Natural or cultured pearls, precious or semiprecious stones and resemblants, precious metals"
temp_param_table$label[17] <- "Pelt, leather, furred pelt and works from all these materials; Trapecial straps or saddles"
temp_param_table$label[16] <- "Wood or other celullose fiber materials folders; Paper or card for recycling"
temp_param_table$label[15] <- "Stone, plaster, cement, asbestos, mica and similar elements works; Pottery products;"
temp_param_table$label[14] <- "Art and collection objects and antiques"
temp_param_table$label[13] <- "Common metals and their works"
temp_param_table$label[12] <- "Goods and various products"
temp_param_table$label[11] <- "Textile raw materials and their works"
temp_param_table$label[10] <- "Transportation material"
temp_param_table$label[9] <- "Machines, devices, electric material and their parts; Recording and playing devices"
temp_param_table$label[8] <- "Wood, charcoal and woodcraft, cork and their works, esparto works or pottery"
temp_param_table$label[7] <- "Optic, photography or cinematography, measuring, control or precision instruments or devices"
temp_param_table$label[6] <- "Fats and vegetable or animal oils; their dissociation products; processed food fats"
temp_param_table$label[5] <- "Footwear, hats and similar purpose artifacts, umbrellas, sunshades, canes and whips"
temp_param_table$label[4] <- "Guns and ammunition: their parts and accessories"
temp_param_table$label[3] <- "Live animals and animal kingdom products"
temp_param_table$label[2] <- "Country"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[24] <- "Special transactions"
temp_param_table$desc[23] <- "Mineral products"
temp_param_table$desc[22] <- "Plant kingdom products"
temp_param_table$desc[21] <- "Food industry products; Beverages, alcoholic liquids and vinegars; Tobacco and its juices"
temp_param_table$desc[20] <- "Chemical or related industry products"
temp_param_table$desc[19] <- "Plastic and its works; Rubber and its works"
temp_param_table$desc[18] <- "Natural or cultured pearls, precious or semiprecious stones and resemblants, precious metals"
temp_param_table$desc[17] <- "Pelt, leather, furred pelt and works from all these materials; Trapecial straps or saddles"
temp_param_table$desc[16] <- "Wood or other celullose fiber materials folders; Paper or card for recycling"
temp_param_table$desc[15] <- "Stone, plaster, cement, asbestos, mica and similar elements works; Pottery products;"
temp_param_table$desc[14] <- "Art and collection objects and antiques"
temp_param_table$desc[13] <- "Common metals and their works"
temp_param_table$desc[12] <- "Goods and various products"
temp_param_table$desc[11] <- "Textile raw materials and their works"
temp_param_table$desc[10] <- "Transportation material"
temp_param_table$desc[9] <- "Machines, devices, electric material and their parts; Recording and playing devices"
temp_param_table$desc[8] <- "Wood, charcoal and woodcraft, cork and their works, esparto works or pottery"
temp_param_table$desc[7] <- "Optic, photography or cinematography, measuring, control or precision instruments or devices"
temp_param_table$desc[6]<- "Fats and vegetable or animal oils; their dissociation products; processed food fats"
temp_param_table$desc[5] <- "Footwear, hats and similar purpose artifacts, umbrellas, sunshades, canes and whips"
temp_param_table$desc[4] <- "Guns and ammunition: their parts and acessories"
temp_param_table$desc[3] <- "Live animals and animal kingdom products"
temp_param_table$desc[2] <- "Year"
temp_param_table$desc[1] <- "Country"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 22))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 22))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_pais_sec_en_dic.csv", fileEncoding = "UTF-8")




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
    categoria= "Economy", 
    subcategoria = "Trade"
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

