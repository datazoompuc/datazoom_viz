library(datazoom.amazonia)
library(magrittr)
library(tidyverse)
library(stringr)


###SH4
dat <- readRDS(file = "data/comex_munic_raw.rds")

aux <- dat %>%
    distinct(cod_sh4, nome_sh4) %>%
    mutate(cod_sh4 = sprintf("%04d", as.numeric(cod_sh4)))

sh4_floresta <- c(
    "0301", # Peixes vivos
    "0302", # Peixes frescos/refrigerados, exceto filés
    "0303", # Peixes congelados, exceto filés
    "0304", # Filés de peixe e outras carnes
    "0305", # Peixes secos, salgados, em salmoura ou defumados
    "0306", # Crustáceos vivos, frescos, congelados, etc.
    "0801", # Cocos, castanha do Brasil e castanha de caju
    "0811", # Frutas, não cozidas ou cozidas em água/vapor, congeladas
    "0904", # Pimenta (Piper) e pimentos secos/triturados (Capsicum/Pimenta)
    "1207", # Outras sementes e frutos oleaginosos
    "1301", # Goma-laca, gomas, resinas, gomas-resinas, oleorresinas
    "1511", # Óleo de palma e respectivas fracções
    "1515", # Outras gorduras e óleos vegetais não modificados
    "1801", # Cacau em bruto ou torrado
    "2008", # Frutas e outras partes comestíveis de plantas, preparadas/conservadas
    "2009"  # Sumos de frutas e hortícolas
)


dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$uf <- NULL
dat$cod_municipio <- NULL
dat$cod_pais <- NULL

data_val_pais <- aggregate(valor_fob ~ ano + cod_sh4, dat, sum)

data_val_pais$cod_sh4 <- sprintf("%04d", as.numeric(data_val_pais$cod_sh4))


#this data from world trade was generated in data-raw/baci.R
world_trade <- readRDS("data/auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci.rds")


# junta por ano + sh4, garantindo alinhamento correto
data <- data_val_pais %>%
    dplyr::filter(
        cod_sh4 <= "2100",        
        valor_fob >= 1000000      
    ) %>%
    dplyr::mutate(
        valor_fob = valor_fob / 1000  # COMEX em mil USD para casar com BACI
    ) %>%
    dplyr::left_join(world_trade, by = c("ano", "cod_sh4")) %>%
    dplyr::mutate(
        valor_fob = ifelse(valor_total > 0, valor_fob / valor_total, NA_real_), # share
        floresta  = cod_sh4 %in% sh4_floresta
    ) %>%
    dplyr::left_join(aux, by = "cod_sh4") %>%   
    dplyr::rename(group = nome_sh4) %>%
    dplyr::select(
        time    = ano,
        group,
        value   = valor_fob,
        floresta
    )



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

# dictionary --------------------------------------------------------------
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

# relabel in english ----------------------------------------------------------------
temp_param_table$unidade <- "% of world exports"
temp_param_table$categoria <- "Economy"
temp_param_table$subcategoria <- "Foreign trade"

temp_param_table$label[temp_param_table$var == "group"] <- "Product (SH4)"
temp_param_table$label[temp_param_table$var == "time"] <- "Year"
temp_param_table$label[temp_param_table$var == "value"] <- "Value"
temp_param_table$label[temp_param_table$var == "floresta"] <- "Forest"

temp_param_table$desc[temp_param_table$var == "group"] <- "Product (SH4)"
temp_param_table$desc[temp_param_table$var == "time"] <- "Year"
temp_param_table$desc[temp_param_table$var == "value"] <- "Value"
temp_param_table$desc[temp_param_table$var == "floresta"] <- "Forest Compatible Products"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_perc_sh4_sel_dic_en.csv", fileEncoding = "UTF-8")
