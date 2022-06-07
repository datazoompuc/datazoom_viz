library(datazoom.amazonia)
library(magrittr)
library(tidyverse)
library(stringr)


###SH4
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
                                          "Peixes frescos ou refrigerados, exceto os filés de peixes e outra carne de peixes da posição 03.04",
                                          "Peixes congelados, exceto os filés de peixes e outra carne de peixes da posição 03.04",
                                          "Filés de peixes e outra carne de peixes (mesmo picada), frescos, refrigerados ou congelados",
                                          "Peixes secos, salgados ou em salmoura; peixes defumados, mesmo cozidos antes ou durante a defumação; farinhas, pós e pellets, de peixe, próprios para alimentação humana",
                                          "Crustáceos, mesmo sem casca, vivos, frescos, refrigerados, congelados, secos, salgados ou em salmoura; crustáceos com casca, cozidos em água ou vapor, mesmo refrigerados, congelados, secos, salgados ou em salmoura; farinhas, pó e pellets de crustáceos, pr",
                                          "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados",
                                          "Frutas, não cozidas ou cozidas em água ou vapor, congeladas, mesmo adicionadas de açúcar ou de outros edulcorantes",
                                          'Pimenta (do género Piper); pimentos dos géneros Capsicum ou Pimenta, secos ou triturados ou em pó',
                                          "Outras sementes e frutos oleaginosos, mesmo triturados",
                                          "Goma-laca; gomas, resinas, gomas-resinas e oleorresinas (bálsamos por exemplo), naturais",
                                          "Óleo de palma e respectivas fracções, mesmo refinados, mas não quimicamente modificados",
                                          "Outras gorduras e óleos vegetais (incluído o óleo de jojoba) e respectivas fracções, fixos, mesmo refinados, mas não quimicamente modificados",
                                          "Cacau inteiro ou partido, em bruto ou torrado",
                                          "Frutas e outras partes comestíveis de plantas, preparadas ou conservadas de outro modo, com ou sem adição de açúcar ou de outros edulcorantes ou de álcool, não especificadas nem compreendidas noutras posições",
                                          "Sumos de frutas (incluídos os mostos de uvas) ou de produtos hortícolas, não fermentados, sem adição de álcool, com ou sem adição de açúcar ou de outros edulcorantes"),
                           TRUE, FALSE))


colnames(data) <- c("time", "group", "value", "floresta")

data= data%>%
  mutate(group= case_when(group == "Peixes vivos" ~ "Peixes vivos",
                        group == "Peixes frescos ou refrigerados, exceto os filés de peixes e outra carne de peixes da posição 03.04" ~ "Peixes frescos/refrigerados, exceto filés",
                        group == "Peixes congelados, exceto os filés de peixes e outra carne de peixes da posição 03.04" ~ "Peixes congelados, exceto filés",
                        group == "Filés de peixes e outra carne de peixes (mesmo picada), frescos, refrigerados ou congelados" ~ "Filés de peixe e outras carnes",
                        group == "Peixes secos, salgados ou em salmoura; peixes defumados, mesmo cozidos antes ou durante a defumação; farinhas, pós e pellets, de peixe, próprios para alimentação humana" ~ "Peixes secos, salgados ou cozidos",
                        group == "Crustáceos, mesmo sem casca, vivos, frescos, refrigerados, congelados, secos, salgados ou em salmoura; crustáceos com casca, cozidos em água ou vapor, mesmo refrigerados, congelados, secos, salgados ou em salmoura; farinhas, pó e pellets de crustáceos, pr" ~ "Crustaceos vivos ou não, para alimento",
                        group == "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados" ~ "Cocos e castanhas do Brasil e de caju",
                        group == "Frutas, não cozidas ou cozidas em água ou vapor, congeladas, mesmo adicionadas de açúcar ou de outros edulcorantes" ~ "Frutas cozidas ou não, misturadas ou não",
                        group == "Pimenta (do género Piper); pimentos dos géneros Capsicum ou Pimenta, secos ou triturados ou em pó" ~ "Pimentas secas ou trituradas",
                        group == "Outras sementes e frutos oleaginosos, mesmo triturados" ~ "Outras sementes e oleaginosos",
                        group == "Goma-laca; gomas, resinas, gomas-resinas e oleorresinas (bálsamos por exemplo), naturais" ~ "Gomas e resinas naturais",
                        group == "Óleo de palma e respectivas fracções, mesmo refinados, mas não quimicamente modificados" ~ "Óleo de palma não modificado",
                        group == "Outras gorduras e óleos vegetais (incluído o óleo de jojoba) e respectivas fracções, fixos, mesmo refinados, mas não quimicamente modificados" ~ "Outras gorduras e óleos vegetais",
                        group == "Cacau inteiro ou partido, em bruto ou torrado" ~ "Cacau bruto ou torrado",
                        group == "Frutas e outras partes comestíveis de plantas, preparadas ou conservadas de outro modo, com ou sem adição de açúcar ou de outros edulcorantes ou de álcool, não especificadas nem compreendidas noutras posições" ~ "Frutas e outros comestíveis de planta",
                        group == "Sumos de frutas (incluídos os mostos de uvas) ou de produtos hortícolas, não fermentados, sem adição de álcool, com ou sem adição de açúcar ou de outros edulcorantes" ~ "Sumos de frutas, com ou sem aditivos",
                        TRUE ~ group))

saveRDS(data, "data/comex_exp_perc_sh4_sel.rds")


### exportação total da amazônia por tipo sh4
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
  unidade = "% das exporta\u00e7\u00f5es mundiais",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[temp_param_table$var == "group"] <- "Produto (SH4)"
temp_param_table$label[temp_param_table$var == "time"] <- "Ano"
temp_param_table$label[temp_param_table$var == "value"] <- "Valor"
temp_param_table$label[temp_param_table$var == "floresta"] <- "Floresta"

temp_param_table$desc[temp_param_table$var == "group"] <- "Produto (SH4)"
temp_param_table$desc[temp_param_table$var == "time"] <- "Ano"
temp_param_table$desc[temp_param_table$var == "value"] <- "Valor"
temp_param_table$desc[temp_param_table$var == "floresta"] <- "Produtos Compat\u00edveis com a Floresta"

temp_param_table$x[temp_param_table$var == "group"] <- FALSE
temp_param_table$x[temp_param_table$var == "time"] <- FALSE
temp_param_table$x[temp_param_table$var == "value"] <- TRUE
temp_param_table$x[temp_param_table$var == "floresta"] <- FALSE

temp_param_table$y[temp_param_table$var == "group"] <- FALSE
temp_param_table$y[temp_param_table$var == "time"] <- FALSE
temp_param_table$y[temp_param_table$var == "value"] <- TRUE
temp_param_table$y[temp_param_table$var == "floresta"] <- FALSE

temp_param_table$color[temp_param_table$var == "group"] <- TRUE
temp_param_table$color[temp_param_table$var == "time"] <- FALSE
temp_param_table$color[temp_param_table$var == "value"] <- FALSE
temp_param_table$color[temp_param_table$var == "floresta"] <- FALSE

temp_param_table$size[temp_param_table$var == "group"] <- FALSE
temp_param_table$size[temp_param_table$var == "time"] <- FALSE
temp_param_table$size[temp_param_table$var == "value"] <- TRUE
temp_param_table$size[temp_param_table$var == "floresta"] <- FALSE

temp_param_table$slider[temp_param_table$var == "group"] <- FALSE
temp_param_table$slider[temp_param_table$var == "time"] <- FALSE
temp_param_table$slider[temp_param_table$var == "value"] <- TRUE
temp_param_table$slider[temp_param_table$var == "floresta"] <- FALSE

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_perc_sh4_sel_dic.csv", fileEncoding = "UTF-8")
