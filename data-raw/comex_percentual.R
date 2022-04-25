library(datazoom.amazonia)
library(magrittr)
library(tidyverse)
library(stringr)

dat <- readRDS(file = "data/comex_munic_raw.rds")

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

#this data from world trade was generated in data-raw/baci.R
world_trade <- readRDS("data/auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci19.rds")

data$valor_fob <- data$valor_fob/1000
data$valor_fob <- data$valor_fob/world_trade$valor_total

aux <- readRDS("data/auxiliar_cod_sh4.rds")
aux$CO_SH4 <- sprintf("%04d", as.numeric(aux$CO_SH4))
data$cod_sh4 <- str_replace_all(data$cod_sh4, setNames(aux$NO_SH4_POR, aux$CO_SH4))

data <- data %>% 
  mutate(floresta = ifelse(cod_sh4 %in% c("Peixes vivos",
                                          "Peixes frescos ou refrigerados, exceto os fil?s de peixes e outra carne de peixes da posi??o 03.04",
                                          "Peixes congelados, exceto os fil?s de peixes e outra carne de peixes da posi??o 03.04",
                                          "Fil?s de peixes e outra carne de peixes (mesmo picada), frescos, refrigerados ou congelados",
                                          "Peixes secos, salgados ou em salmoura; peixes defumados, mesmo cozidos antes ou durante a defuma??o; farinhas, p?s e pellets, de peixe, pr?prios para alimenta??o humana",
                                          "Crust?ceos, mesmo sem casca, vivos, frescos, refrigerados, congelados, secos, salgados ou em salmoura; crust?ceos com casca, cozidos em ?gua ou vapor, mesmo refrigerados, congelados, secos, salgados ou em salmoura; farinhas, p? e pellets de crust?ceos, pr",
                                          "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados",
                                          "Frutas, n?o cozidas ou cozidas em ?gua ou vapor, congeladas, mesmo adicionadas de a??car ou de outros edulcorantes",
                                          "Pimenta (do g?nero Piper); pimentos dos g?neros Capsicum ou Pimenta, secos ou triturados ou em p?",
                                          "Outras sementes e frutos oleaginosos, mesmo triturados",
                                          "Goma-laca; gomas, resinas, gomas-resinas e oleorresinas (b?lsamos por exemplo), naturais",
                                          "?leo de palma e respectivas frac??es, mesmo refinados, mas n?o quimicamente modificados",
                                          "Outras gorduras e ?leos vegetais (inclu?do o ?leo de jojoba) e respectivas frac??es, fixos, mesmo refinados, mas n?o quimicamente modificados",
                                          "Cacau inteiro ou partido, em bruto ou torrado",
                                          "Frutas e outras partes comest?veis de plantas, preparadas ou conservadas de outro modo, com ou sem adi??o de a??car ou de outros edulcorantes ou de ?lcool, n?o especificadas nem compreendidas noutras posi??es",
                                          "Sumos de frutas (inclu?dos os mostos de uvas) ou de produtos hort?colas, n?o fermentados, sem adi??o de ?lcool, com ou sem adi??o de a??car ou de outros edulcorantes"),
                           TRUE, FALSE))

colnames(data) <- c("time", "group", "value", "floresta")
saveRDS(data, "data/comex_exp_perc_sh4_sel.rds")


### exporta??o total da amaz?nia por tipo sh2
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
  unidade = "% das exporta??es mundiais",
  categoria= "Economia", 
  subcategoria = "Com?rcio exterior"
)

temp_param_table$label[2] <- "Produto (SH4)"
temp_param_table$label[1] <- "Ano"
temp_param_table$label[3] <- "Valor"
temp_param_table$label[4] <- "Floresta"
temp_param_table$desc[2] <- "Produto (SH4)"
temp_param_table$desc[1] <- "Ano"
temp_param_table$desc[3] <- "Valor"
temp_param_table$desc[4] <- "Produtos Compat?veis com a Floresta"
temp_param_table$x <- c(FALSE, FALSE, TRUE, FALSE)
temp_param_table$y <- c(FALSE, FALSE, TRUE, FALSE)
temp_param_table$color <- c(FALSE, TRUE, FALSE, FALSE)
temp_param_table$size <- c(FALSE, FALSE, TRUE, FALSE)
temp_param_table$slider <- c(FALSE, FALSE, TRUE, FALSE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_perc_sh4_sel_dic.csv", fileEncoding = "UTF-8")
