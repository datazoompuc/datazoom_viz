############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(magrittr)
library(tidyverse)
library(stringr)
library(httr)
library(jsonlite)

dat <- load_br_trade(dataset="comex_export_mun", language = "pt", time_period = 1997:2024, raw_data = FALSE)

dat <- inner_join(
    dat,
    datazoom.amazonia::municipalities[, c("code_muni", "legal_amazon")],
    by = c("cod_municipio" = "code_muni")
) %>% filter(legal_amazon == 1) %>%
    select(-legal_amazon)


saveRDS(dat, file = "data/comex_munic_raw.rds")
dat <- readRDS(file = "data/comex_munic_raw.rds")

# -------------------------------
# AUXILIARES
# -------------------------------

# gera auxiliar de código de país
url <- "https://api-comexstat.mdic.gov.br/general/filters/country?language=pt"
resp <- GET(url)
stop_for_status(resp)

txt <- content(resp, as = "text", encoding = "UTF-8")
obj <- fromJSON(txt, simplifyDataFrame = TRUE)

d <- obj$data
# a doc mostra que às vezes vem aninhado; isso deixa robusto:
if (is.list(d) && length(d) == 1 && is.data.frame(d[[1]])) d <- d[[1]]

aux1 <- as_tibble(d) %>%
    transmute(
        SISCOMEX  = str_pad(id, 3, pad = "0"),
        NO_PT = text
    ) %>%
    distinct(SISCOMEX, .keep_all = TRUE)

# nomes de país em inglês (mesma API, language=en) para gerar os dicionários EN
resp_en <- GET("https://api-comexstat.mdic.gov.br/general/filters/country?language=en")
stop_for_status(resp_en)
d_en <- fromJSON(content(resp_en, as = "text", encoding = "UTF-8"), simplifyDataFrame = TRUE)$data
if (is.list(d_en) && length(d_en) == 1 && is.data.frame(d_en[[1]])) d_en <- d_en[[1]]

aux1_en <- as_tibble(d_en) %>%
    transmute(
        SISCOMEX = str_pad(id, 3, pad = "0"),
        NO_EN    = text
    ) %>%
    distinct(SISCOMEX, .keep_all = TRUE)

aux1 <- left_join(aux1, aux1_en, by = "SISCOMEX")
saveRDS(aux1, "data/auxiliar_cod_pais.rds")
aux1 <- readRDS("data/auxiliar_cod_pais.rds")


# gera auxiliar de cod sh4 (com capítulo SH2 e seção SEC)
#
# Fonte: tabela de referência NCM_SH do MDIC, que traz a hierarquia completa
#
# Os blocos abaixo usam aux2$NO_SH2_PT (nome do capítulo) e aux2$NO_SEC_PT (nome da seção)
# para agregar os produtos; por isso este auxiliar PRECISA dessas colunas. As colunas *_EN
# (inglês) ficam disponíveis para gerar os dicionários EN diretamente, sem traduções manuais.
ncm_sh <- readr::read_csv2(
    "https://balanca.economia.gov.br/balanca/bd/tabelas/NCM_SH.csv",
    locale = readr::locale(encoding = "latin1"),
    show_col_types = FALSE
)

aux2 <- ncm_sh %>%
    transmute(
        CO_SH4    = str_pad(as.character(CO_SH4), 4, pad = "0"),
        NO_SH4_PT = str_trim(NO_SH4_POR),   # nome da posição (SH4) em PT
        NO_SH2_PT = str_trim(NO_SH2_POR),   # nome do capítulo (SH2) em PT
        NO_SEC_PT = str_trim(NO_SEC_POR),   # nome da seção (SEC) em PT
        NO_SH4_EN = str_trim(NO_SH4_ING),   # versões em inglês (para dicionários EN)
        NO_SH2_EN = str_trim(NO_SH2_ING),
        NO_SEC_EN = str_trim(NO_SEC_ING)
    ) %>%
    distinct(CO_SH4, .keep_all = TRUE)
saveRDS(aux2, "data/auxiliar_cod_sh4.rds")


aux2 <- readRDS("data/auxiliar_cod_sh4.rds")

# gera auxiliar de código de município
url <- "https://api-comexstat.mdic.gov.br/cities/filters/city?language=pt"
resp <- GET(url)
stop_for_status(resp)

txt <- content(resp, as = "text", encoding = "UTF-8")
obj <- fromJSON(txt, simplifyDataFrame = TRUE)

d <- obj$data
if (is.list(d) && length(d) == 1 && is.data.frame(d[[1]])) d <- d[[1]]

aux3 <- as_tibble(d) %>%
    transmute(
        codigo = str_pad(as.character(id), 7, pad = "0"),  # município costuma ser 7 dígitos (IBGE)
        nome   = text
    ) %>%
    distinct(codigo, .keep_all = TRUE)

saveRDS(aux3, "data/auxiliar_cod_municipais.rds")

aux3 <- readRDS("data/auxiliar_cod_municipais.rds")

# -------------------------------
# MAPAS PT -> EN (para dicionários EN, direto da fonte; sem traduções manuais)
# -------------------------------
# Construídos a partir das colunas *_EN dos auxiliares. 
map_sec  <- aux2 %>% distinct(NO_SEC_PT, NO_SEC_EN); map_sec  <- setNames(map_sec$NO_SEC_EN, map_sec$NO_SEC_PT)
map_sh2  <- aux2 %>% distinct(NO_SH2_PT, NO_SH2_EN); map_sh2  <- setNames(map_sh2$NO_SH2_EN, map_sh2$NO_SH2_PT)
map_sh4  <- aux2 %>% distinct(NO_SH4_PT, NO_SH4_EN); map_sh4  <- setNames(map_sh4$NO_SH4_EN, map_sh4$NO_SH4_PT)
map_pais <- setNames(aux1$NO_EN, aux1$NO_PT)

# traduz um vetor de nomes PT usando um mapa; mantém o original se não encontrar
tr <- function(x, map) { out <- unname(map[x]); ifelse(is.na(out), x, out) }

#dat$cod_pais <- as.numeric(dat$cod_pais)
#aux1$SISCOMEX <- as.numeric(aux1$SISCOMEX)
#dat$cod_pais <- str_replace_all(dat$cod_pais, setNames(aux1$NO_PT, aux1$SISCOMEX))
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
data_val_pais$cod_sh4 <- str_replace_all(data_val_pais$cod_sh4, setNames(aux2$NO_SH2_PT, aux2$CO_SH4))

colnames(data_val_pais) <- c("time", "group", "value")

data_val_pais$time <- as.numeric(data_val_pais$time)
data_val_pais <- aggregate(value ~ time + group, data_val_pais, sum)

#datafinal_val_pais <- reshape(data_val_pais, idvar = c("group"), timevar = "time", direction = "wide")
#labl <- colnames(datafinal_val_pais)
#labl <- labl[-c(1)]
#labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
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
# dat$cod_sh4 <- str_replace_all(dat$cod_sh4, setNames(aux2$NO_SH4_PT, aux2$CO_SH4))
dat$cod_municipio <- str_replace_all(dat$cod_municipio, setNames(aux3$nome, aux3$codigo))
# dat$cod_municipio <- paste(dat$cod_municipio, " - ",dat$uf)
dat$uf <- NULL

data_val <- dat
colnames(data_val) <- c("time", "type", "group", "value")
data_val <- aggregate(value ~ time + type + group, data_val, sum)

datafinal_val_munic <- reshape(data_val, idvar = c("time", "type"), timevar = "group", direction = "wide")
datafinal_val_sh2 <- reshape(data_val, idvar = c("time", "group"), timevar = "type", direction = "wide")

labl <- colnames(datafinal_val_munic)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo sem truncar
colnames(datafinal_val_munic) <- c("time", "group", labl)

labl <- colnames(datafinal_val_sh2)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo sem truncar
colnames(datafinal_val_sh2) <- c("time", "group", labl)

datafinal_val_munic[is.na(datafinal_val_munic)] <- 0
datafinal_val_sh2[is.na(datafinal_val_sh2)] <- 0

datafinal_val_munic <- datafinal_val_munic[order(datafinal_val_munic$group, datafinal_val_munic$time),]
datafinal_val_sh2 <- datafinal_val_sh2[order(datafinal_val_sh2$group, datafinal_val_sh2$time),]

stopifnot(!anyDuplicated(names(datafinal_val_sh2)))
stopifnot(!anyDuplicated(names(datafinal_val_munic)))

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
dat$cod_sh4 <- str_replace_all(dat$cod_sh4, setNames(aux2$NO_SH2_PT, aux2$CO_SH4))
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
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
colnames(datafinal_val_munic) <- c("time", "group", labl)

labl <- colnames(datafinal_val_sh2)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
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
data_val_pais$cod_sh4 <- str_replace_all(data_val_pais$cod_sh4, setNames(aux2$NO_SEC_PT, aux2$CO_SH4))

colnames(data_val_pais) <- c("time", "group", "value")

data_val_pais$time <- as.numeric(data_val_pais$time)
data_val_pais <- aggregate(value ~ time + group, data_val_pais, sum)

#datafinal_val_pais <- reshape(data_val_pais, idvar = c("group"), timevar = "time", direction = "wide")
#labl <- colnames(datafinal_val_pais)
#labl <- labl[-c(1)]
#labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
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
dat$cod_sh4 <- str_replace_all(dat$cod_sh4, setNames(aux2$NO_SH2_PT, aux2$CO_SH4))
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
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
colnames(datafinal_val_munic) <- c("time", "group", labl)

labl <- colnames(datafinal_val_sec)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
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


data_val_pais_sec$cod_sh4 <- sprintf("%04d", as.numeric(data_val_pais_sec$cod_sh4))
data_val_pais_sec$cod_sh4 <- str_replace_all(data_val_pais_sec$cod_sh4, setNames(aux2$NO_SEC_PT, aux2$CO_SH4))
data_val_pais_sec$cod_pais <- sprintf("%03d", as.numeric(data_val_pais_sec$cod_pais))
data_val_pais_sec$cod_pais <- str_replace_all(data_val_pais_sec$cod_pais, setNames(aux1$NO_PT, aux1$SISCOMEX))

data_val_pais <- data_val_pais[!(data_val_pais$cod_pais %in% c("042", "105", "388", "790", "990", "998", "994", "995", "100")),]
data_val_pais_sec <- data_val_pais_sec[!(data_val_pais_sec$cod_pais %in% c("015", "042", "150", "388", "489", "693", "790", "990")),]

data_val_pais$cod_pais <- str_replace_all(data_val_pais$cod_pais, setNames(aux1$NO_PT, aux1$SISCOMEX))

colnames(data_val_pais) <- c("time", "group", "value")
colnames(data_val_pais_sec) <- c("time", "group", "type", "value")

data_val_pais <- data_val_pais[order(data_val_pais$group, data_val_pais$time),]
saveRDS(data_val_pais, "data/comex_exp_tot_pais.rds")

datafinal_val_pais_sec <- reshape(data_val_pais_sec, idvar = c("time", "type"), timevar = "group", direction = "wide")
datafinal_val_pais_munic <- reshape(data_val_pais_sec, idvar = c("time", "group"), timevar = "type", direction = "wide")

labl <- colnames(datafinal_val_pais_sec)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
colnames(datafinal_val_pais_sec) <- c("time", "group", labl)

labl <- colnames(datafinal_val_pais_munic)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
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
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Municipality"
temp_param_table$label[-(1:2)] <- tr(temp_param_table$var[-(1:2)], map_sh4)
temp_param_table$desc <- temp_param_table$label


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
  categoria= "Economy",
  subcategoria = "Trade"
)
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Country"
temp_param_table$label[-(1:2)] <- tr(temp_param_table$var[-(1:2)], map_sec)
temp_param_table$desc <- temp_param_table$label


temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, 22))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 22))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 22))

# translate

# IMPORTANTE: `var` permanece em PT (igual às colunas do .rds e ao dict PT). Só `label`/`desc`
# são traduzidos. Isso é exigido pelo lang toggle do app ts_comex_exp_pais (a seleção usa `var`
# como chave para as colunas do .rds, que estão em PT).

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
    unidade = "US$",
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
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Municipality"
temp_param_table$label[-(1:2)] <- tr(temp_param_table$var[-(1:2)], map_sh2)
temp_param_table$desc <- temp_param_table$label


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
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Municipality"
temp_param_table$label[-(1:2)] <- tr(temp_param_table$var[-(1:2)], map_sh2)
temp_param_table$desc <- temp_param_table$label


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
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Section"
temp_param_table$label[-(1:2)] <- tr(temp_param_table$var[-(1:2)], map_pais)
temp_param_table$desc <- temp_param_table$label


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
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Country"
temp_param_table$label[-(1:2)] <- tr(temp_param_table$var[-(1:2)], map_sec)
temp_param_table$desc <- temp_param_table$label


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

