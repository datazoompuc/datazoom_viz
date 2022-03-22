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

world_trade <- readRDS("data/auxiliar_exportacoes_totais_produtos_selecionados.rds")

data$valor_fob <- data$valor_fob/1000
data$valor_fob <- data$valor_fob/world_trade$total

aux <- readRDS("data/auxiliar_cod_sh4.rds")
aux$CO_SH4 <- sprintf("%04d", as.numeric(aux$CO_SH4))
data$cod_sh4 <- str_replace_all(data$cod_sh4, setNames(aux$NO_SH4_POR, aux$CO_SH4))

data <- data %>% 
  mutate(floresta = ifelse(cod_sh4 %in% c("Peixes vivos",
                                          "Peixes frescos ou refrigerados, exceto os filés de peixes e outra carne de peixes da posição 03.04",
                                          "Peixes congelados, exceto os filés de peixes e outra carne de peixes da posição 03.04",
                                          "Filés de peixes e outra carne de peixes (mesmo picada), frescos, refrigerados ou congelados",
                                          "Peixes secos, salgados ou em salmoura; peixes defumados, mesmo cozidos antes ou durante a defumação; farinhas, pós e pellets, de peixe, próprios para alimentação humana",
                                          "Crustáceos, mesmo sem casca, vivos, frescos, refrigerados, congelados, secos, salgados ou em salmoura; crustáceos com casca, cozidos em água ou vapor, mesmo refrigerados, congelados, secos, salgados ou em salmoura; farinhas, pó e pellets de crustáceos, pr",
                                          "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados",
                                          "Frutas, não cozidas ou cozidas em água ou vapor, congeladas, mesmo adicionadas de açúcar ou de outros edulcorantes",
                                          "Pimenta (do género Piper); pimentos dos géneros Capsicum ou Pimenta, secos ou triturados ou em pó",
                                          "Outras sementes e frutos oleaginosos, mesmo triturados",
                                          "Goma-laca; gomas, resinas, gomas-resinas e oleorresinas (bálsamos por exemplo), naturais",
                                          "Óleo de palma e respectivas fracções, mesmo refinados, mas não quimicamente modificados",
                                          "Outras gorduras e óleos vegetais (incluído o óleo de jojoba) e respectivas fracções, fixos, mesmo refinados, mas não quimicamente modificados",
                                          "Cacau inteiro ou partido, em bruto ou torrado",
                                          "Frutas e outras partes comestíveis de plantas, preparadas ou conservadas de outro modo, com ou sem adição de açúcar ou de outros edulcorantes ou de álcool, não especificadas nem compreendidas noutras posições",
                                          "Sumos de frutas (incluídos os mostos de uvas) ou de produtos hortícolas, não fermentados, sem adição de álcool, com ou sem adição de açúcar ou de outros edulcorantes"),
                           TRUE, FALSE))

colnames(data) <- c("time", "group", "value", "floresta")
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
  unidade = "% das exportações mundiais",
  categoria= "Economia", 
  subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "Produto (SH4)"
temp_param_table$label[1] <- "Ano"
temp_param_table$label[3] <- "Valor"
temp_param_table$label[4] <- "Floresta"
temp_param_table$desc[2] <- "Produto (SH4)"
temp_param_table$desc[1] <- "Ano"
temp_param_table$desc[3] <- "Valor"
temp_param_table$desc[4] <- "Produtos Compatíveis com a Floresta"
temp_param_table$x <- c(FALSE, FALSE, TRUE, FALSE)
temp_param_table$y <- c(FALSE, FALSE, TRUE, FALSE)
temp_param_table$color <- c(FALSE, TRUE, FALSE, FALSE)
temp_param_table$size <- c(FALSE, FALSE, TRUE, FALSE)
temp_param_table$slider <- c(FALSE, FALSE, TRUE, FALSE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_perc_sh4_sel_dic.csv", fileEncoding = "UTF-8")
