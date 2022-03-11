library(datazoom.amazonia)
library(magrittr)
library(tidyverse)
library(stringr)

dat <- readRDS(file = "data/comex_munic_raw.rds")

dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$uf <- NULL
dat$cod_municipio <- NULL
dat$cod_pais <- NULL

data_val_pais <- aggregate(valor_fob ~ ano + cod_sh4, dat, sum)

data_val_pais$cod_sh4 <- sprintf("%04d", as.numeric(data_val_pais$cod_sh4))

data <- data_val_pais
data <- data[data$ano=="2019",]
data <- data[data$cod_sh4<="2100",]
data <- data[data$valor_fob>=1000000,]

world_trade <- readRDS("data/auxiliar_exportacoes_totais_produtos_selecionados.rds")

data$valor_fob <- data$valor_fob/1000
data$valor_fob <- data$valor_fob/world_trade$total

aux <- readRDS("data/auxiliar_cod_sh4.rds")
aux$CO_SH4 <- sprintf("%04d", as.numeric(aux$CO_SH4))
data$cod_sh4 <- str_replace_all(data$cod_sh4, setNames(aux$NO_SH4_POR, aux$CO_SH4))

colnames(data) <- c("time", "group", "value")
saveRDS(data, "data/comex_exp_perc_sh4_sel.rds")


### exportação total da amazônia por tipo sh2
datafinal <- readRDS(file = "data/comex_exp_perc_sh4_sel.rds")

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
  unidade = "%",
  categoria= "Economia", 
  subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "Produto (SH4)"
temp_param_table$label[1] <- "Ano"
temp_param_table$label[3] <- "Valor"
temp_param_table$desc[2] <- "Produto (SH4)"
temp_param_table$desc[1] <- "Ano"
temp_param_table$desc[3] <- "Valor"
temp_param_table$x <- c(FALSE, FALSE, TRUE)
temp_param_table$y <- c(FALSE, FALSE, TRUE)
temp_param_table$color <- c(FALSE, TRUE, FALSE)
temp_param_table$size <- c(FALSE, FALSE, TRUE)
temp_param_table$slider <- c(FALSE, FALSE, TRUE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_perc_sh4_sel_dic.csv", fileEncoding = "UTF-8")
