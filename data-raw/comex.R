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

dat$cod_pais <- as.numeric(dat$cod_pais)
aux1$SISCOMEX <- as.numeric(aux1$SISCOMEX)

dat$cod_pais <- str_replace_all(dat$cod_pais, setNames(aux1$NO_POR_MIN, aux1$SISCOMEX))
dat$cod_municipio <- str_replace_all(dat$cod_municipio, setNames(aux$AR_MUN_2020, aux$CD_GCMUN))

dat$mes <- NULL
dat$cod_sh4 <- NULL

data_kg <- aggregate(kg_liquido ~ ano + cod_pais + uf + cod_municipio + nome_sh4, dat, sum)
data_val <- aggregate(valor_fob ~ ano + cod_pais + uf + cod_municipio + nome_sh4, dat, sum)

datafinal_kg <- reshape(data_kg, idvar = c("ano", "uf", "cod_municipio", "cod_pais"), timevar = "nome_sh4", direction = "wide")
datafinal_val <- reshape(data, idvar = c("state", "time"), timevar = "group", direction = "wide")


# Trocar países e municípios de código para nome

saveRDS(datafinal, "data/comex_munic.rds")



#####################
# Build Dictionary 
#####################

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
  unidade = "m^2",
  categoria= "Meio ambiente", 
  subcategoria = "Uso da terra"
)

temp_param_table$label[1] <- "UF"
temp_param_table$label[2] <- "Ano"
temp_param_table$desc[1] <- "UF"
temp_param_table$desc[2] <- "Ano"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 29))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 29))
temp_param_table$color <- c(rep(TRUE, 1), rep(FALSE, 30))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 29))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 29))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_est_dic.csv", fileEncoding = "UTF-8")
