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
#dat$uf <- NULL
dat$cod_municipio <- NULL
dat$cod_pais <- NULL

data_val_pais <- aggregate(valor_fob ~ ano + uf + cod_sh4, dat, sum)

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
        valor_fob = valor_fob / valor_total,   # share
        floresta  = cod_sh4 %in% sh4_floresta
    ) %>%
    dplyr::filter(!is.na(valor_total), valor_total > 0) %>%
    dplyr::left_join(aux, by = "cod_sh4") %>%   
    dplyr::rename(group = nome_sh4) %>%
    dplyr::select(
        time    = ano,
        group,
        value   = valor_fob,
        uf,
        floresta
    )



data= data%>%
  mutate(group= case_when(
          group == "Acucares de cana ou de beterraba e sacarose quimicamente pura, no estado solido" ~ "Açúcares no estado sólido",
          group == "Alfarroba, algas, beterraba sacarina e cana-de-acucar, frescas, refrigeradas, congeladas ou secas, mesmo em po; carocos e amendoas de frutos e outros produtos vegetais (incluidas as raizes de chicoria nao torradas, da variedade Cichorium intybus sativum) " ~ "Alfarroba, algas, beterraba sacarina e cana-de-açúcar, frescas, refrigeradas, congeladas ou secas, mesmo em pó; caroços e amêndoas de frutos e outros produtos vegetais (incluídas as raízes de chicória não torradas, da variedade Cichorium intybus sativum)",
          group == "Ambar-cinzento, castoreo, algalia e almiscar; bilis, mesmo seca; glandulas e outras substancias de origem animal utilizadas na preparacao de produtos farmaceuticos, frescas, refrigeradas, congeladas ou provisoriamente conservadas de outro modo" ~ "Âmbar, castóreo e outras substâncias de origem animal utilizadas na preparação de produtos farmacêuticos",
          group == "Amendoins nao torrados nem de outro modo cozidos, mesmo descascados ou triturados" ~ "Amendoins não torrados",
          group == "Animais vivos da especie bovina" ~ "Animais vivos da espécie bovina",
          group == "Cacau inteiro ou partido, em bruto ou torrado" ~ "Cacau bruto ou torrado",
          group == "Cafe, mesmo torrado ou descafeinado; cascas e peliculas de cafe; sucedaneos do cafe contendo cafe em qualquer proporcao" ~ "Café torrado, cascas e sucedâneos",
          group == "Carnes de animais da especie bovina, congeladas" ~ "Carnes de animais da espécie bovina, congeladas",
          group == "Carnes de animais da especie bovina, frescas ou refrigeradas" ~ "Carnes de animais da espécie bovina, frescas ou refrigeradas",
          group == "Carnes de animais da especie suina, frescas, refrigeradas ou congeladas" ~ "Carnes suínas, frescas, refrigeradas ou congeladas",
          group == "Carnes e miudezas comestiveis, frescas, refrigeradas ou congeladas, das aves da posicao 0105" ~ "Carnes e comestíveis de aves domésticas",
          group == "Carnes e miudezas, comestiveis, salgadas ou em salmoura, secas ou defumadas; farinhas e pos, comestiveis, de carnes ou de miudezas" ~ "Carnes e comestíveis salgadas ou secas",
          group == "Chocolate e outras preparacoes alimenticias contendo cacau" ~ "Chocolate e outras preparações alimentícias contendo cacau",
          group == "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados" ~ "Cocos e castanhas do Brasil e de caju",
          group == "Cravo-da-india (frutos, flores e pedunculos)" ~ "Cravo-da-índia",
          group == "Crustaceos, mesmo sem casca, vivos, frescos, refrigerados, congelados, secos, salgados ou em salmoura; crustaceos com casca, cozidos em agua ou vapor, mesmo refrigerados, congelados, secos, salgados ou em salmoura; farinhas, po e pellets de crustaceos, pr" ~ "Crustáceos vivos ou não, para alimento",
          group == "Enchidos e produtos semelhantes, de carne, de miudezas ou de sangue; preparacoes alimenticias a base de tais produtos" ~ "Enchidos e produtos semelhantes, de carne, de miudezas ou de sangue; preparações alimenticias a base de tais produtos",
          group == "Extractos de malte; preparacoes alimenticias de farinhas, grumos, semolas, amidos, feculas ou extractos de malte, nao contendo cacau ou contendo-o numa proporcao inferior a 40 %, em peso, nao especificadas nem compreendidas noutras posicoes; preparacoes a" ~ "Extractos de malte",
          group == "Farinhas, semolas e pos, de legumes de vagem secos da posicao 0713, de sagu ou das raizes ou tuberculos da posicao 0714 e dos produtos do Capitulo 8" ~ "Farinhas, semolas, pós de legumes",
          group == "Files de peixes e outra carne de peixes (mesmo picada), frescos, refrigerados ou congelados" ~ "Filés de peixe e outras carnes",
          group == "Frutas e outras partes comestiveis de plantas, preparadas ou conservadas de outro modo, com ou sem adicao de acucar ou de outros edulcorantes ou de alcool, nao especificadas nem compreendidas noutras posicoes" ~ "Frutas e outros comestíveis de planta",
          group == "Frutas secas, exceto das posicoes 0801 a 0806; misturas de frutas secas ou de frutas de casca rija, do presente capitulo" ~ "Frutas secas ou de casca rija",
          group == "Frutas, nao cozidas ou cozidas em agua ou vapor, congeladas, mesmo adicionadas de acucar ou de outros edulcorantes" ~ "Frutas cozidas ou não, misturadas ou não",
          group == "Glicerol em bruto; aguas e lixivias, glicericas" ~ "Glicerol, lixívias, glicéricas",
          group == "Goma-laca; gomas, resinas, gomas-resinas e oleorresinas (balsamos por exemplo), naturais" ~ "Gomas e resinas naturais",
          group == "Gorduras de animais das especies bovina, ovina ou caprina, exceto as da posicao 1503" ~ "Gorduras animais bovino, ovino e caprino",
          group == "Legumes de vagem, secos, em grao, mesmo pelados ou partidos" ~ "Legumes de vagem em grão secos",
          group == "Leite e nata, concentrados ou adicionados de acucar ou de outros edulcorantes" ~ "Leite e nata",
          group == "Margarina; misturas ou preparacoes alimenticias de gorduras ou de oleos animais ou vegetais ou de fraccoes das diferentes gorduras ou oleos do presente capitulo, exceto as gorduras e oleos alimenticios, e respectivas fraccoes, da posicao 1516" ~ "Margarina",
          group == "Massas alimenticias, mesmo cozidas ou recheadas (de carne ou de outras substancias) ou preparadas de outro modo, tais como esparguete, macarrao, aletria, lasanha, nhoque, raviole e canelone; cuscuz, mesmo preparado" ~ "Massas alimentícias",
          group == "Miudezas comestiveis de animais das especies bovina, suina, ovina, caprina, cavalar, asinina e muar, frescas, refrigeradas ou congeladas" ~ "Miudezas comestíveis de animais das espécies bovina, suína, ovina, caprina, cavalar, asinina e muar",
          group == "Oleo de palma e respectivas fraccoes, mesmo refinados, mas nao quimicamente modificados" ~ "Óleo de palma não modificado",
          group == "Oleo de soja e respectivas fraccoes, mesmo refinados, mas nao quimicamente modificados" ~ "Óleo de soja não modificado",
          group == "Oleos de coco (oleo de copra), de palmiste ou de babacu e respectivas fraccoes, mesmo refinados, mas nao quimicamente modificados" ~ "Óleos de coco, palmiste ou babaçu",
          group == "Oleos de girassol, de cartamo ou de algodao e respectivas fraccoes, mesmo refinados, mas nao quimicamente modificados" ~ "Óleos de girassol, de cártamo ou de algodão",
          group == "Outras carnes e miudezas comestiveis, frescas, refrigeradas ou congeladas" ~ "Outras carnes e miudezas",
          group == "Outras gorduras e oleos vegetais (incluido o oleo de jojoba) e respectivas fraccoes, fixos, mesmo refinados, mas nao quimicamente modificados" ~ "Outras gorduras e óleos vegetais (incluido o óleo de jojoba)",
          group == "Outras preparacoes e conservas de carne, miudezas ou sangue" ~ "Outras preparações de carne e miudezas",
          group == "Ovos de aves, com casca, frescos, conservados ou cozidos" ~ "Ovos de aves",
          group == "Peixes congelados, exceto os files de peixes e outra carne de peixes da posicao 03.04" ~ "Peixes congelados, exceto filés",
          group == "Peixes frescos ou refrigerados, exceto os files de peixes e outra carne de peixes da posicao 03.04" ~ "Peixes frescos/refrigerados, exceto filés",
          group == "Peixes secos, salgados ou em salmoura; peixes defumados, mesmo cozidos antes ou durante a defumacao; farinhas, pos e pellets, de peixe, proprios para alimentacao humana" ~ "Peixes secos, salgados ou cozidos",
          group == "Pimenta (do genero Piper); pimentos dos generos Capsicum ou Pimenta, secos ou triturados ou em po" ~ "Pimentas secas ou trituradas",
          group == "Plantas, partes de plantas, sementes e frutos, das especies utilizadas principalmente em perfumaria, medicina ou como insecticidas, parasiticidas e semelhantes, frescos ou secos, mesmo cortados, triturados ou em po" ~ "Plantas para medicina, perfumaria ou inseticida",
          group == "Produtos de confeitaria sem cacau (incluido o chocolate branco)" ~ "Produtos de confeitaria sem cacau",
          group == "Produtos de origem animal, nao especificados nem compreendidos em outras posicoes; animais mortos dos Capitulos 1 ou 3, improprios para alimentacao humana" ~ "Produtos animais impróprios para alimentação",
          group == "Produtos de padaria, pastelaria ou da industria de bolachas e biscoitos, mesmo adicionados de cacau; hostias, capsulas vazias para medicamentos, obreias, pastas secas de farinha, amido ou fecula em folhas e produtos semelhantes" ~ "Produtos de padaria, pastelaria ou da indústria de bolachas e biscoitos",
          group == "Produtos horticolas conservados transitoriamente (por exemplo: com gas sulfuroso ou agua salgada, sulfurada ou adicionada de outras substancias destinadas a assegurar transitoriamente a sua conservacao), mas improprios para a alimentacao nesse estado" ~ "Produtos hortícolas conservados transitoriamente",
          group == "Produtos vegetais nao especificados nem compreendidos noutras posicoes" ~ "Produtos vegetais não especificados",
          group == "Sorgo de grao" ~ "Sorgo de grão",
          group == "Soro de leite, mesmo concentrado ou adicionado de acucar ou de outros edulcorantes; produtos constituidos por componentes naturais do leite, mesmo adicionados de acucar ou de outros edulcorantes, nao especificados nem compreendidos em outras posicoes" ~ "Soro de leite",
          group == "Sumos de frutas (incluidos os mostos de uvas) ou de produtos horticolas, nao fermentados, sem adicao de alcool, com ou sem adicao de acucar ou de outros edulcorantes" ~ "Sumos de frutas, com ou sem aditivos",
          group == "Tripas, bexigas e estomagos de animais, exceto peixes, inteiros ou em pedacos, frescos, refrigerados, congelados, salgados, secos ou defumados" ~ "Tripas, bexigas e estômagos de animais, exceto peixes, inteiros ou em pedaços, frescos, refrigerados, congelados, salgados, secos ou defumados",
          TRUE ~ group
  ))

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
temp_param_table$slider[temp_param_table$var == "time"] <- TRUE
temp_param_table$slider[temp_param_table$var == "value"] <- FALSE
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
