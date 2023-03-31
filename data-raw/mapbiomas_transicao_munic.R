############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(readxl)

dat <- load_mapbiomas(dataset = "mapbiomas_transition", geo_level = "municipality")

saveRDS(dat, file = "data/mapbiomas_transicao_munic_raw.rds")
dat <- readRDS(file = "data/mapbiomas_transicao_munic_raw.rds")

dat_filtered <- dat

munic_amaz_legal <- datazoom.amazonia::municipalities %>% 
    filter(legal_amazon == 1)

dat_filtered$municipality <- dat_filtered$municipality %>%
                    str_to_lower()

dat_filtered <- dat_filtered %>% 
    filter(territory_id %in% munic_amaz_legal$code_muni)


data1 <- dat_filtered
data1$territory_id <- NULL
data1$to <- NULL
data1$to_level_0 <- NULL
data1$to_level_1 <- NULL
data1$to_level_2 <- NULL
data1$to_level_3 <- NULL
data1$from <- NULL
data1$from_level_0 <- NULL
data1$from_level_1 <- NULL
data1$from_level_2 <- NULL
data1$from_level_3 <- NULL
data1 <- data1  %>%
    rename(to = to_level_4,
           from = from_level_4,
           group = municipality)

datafinal <- data1 %>%
    pivot_longer(-c("group","state","from","to"), names_to = "time_span", values_to = "value") %>%
    mutate(time_span = str_replace(time_span,"_to_", "-")) %>% #replacing "_to_" by "_"
    mutate(time_span = str_replace(time_span, "x", "")) %>% #removing the x on the start of the time span
    mutate(ano_inicial = str_split_i(time_span, "-",i = 1), #create inicial year variable
           ano_final = str_split_i(time_span, "-", i = 2)) %>% #create final year variable
    relocate(ano_final, ano_inicial) %>% # reorganize columns order
    filter(as.numeric(ano_final) - as.numeric(ano_inicial) == 5) %>% #filtering for 5 year span
    select(-c("ano_final", "ano_inicial")) #removing created columns

#reestabelecendo letra maiuscula
datafinal$group <- str_to_title(datafinal$group)

#reestabelecendo letra maiuscula em casos especificos
datafinal <- mutate(datafinal, group = case_when(str_detect(group, pattern = "D'o") ~ str_replace(group,pattern = "D'o", replacement = "D'O"),
                                                 str_detect(group, pattern = "D'a") ~ str_replace(group,pattern = "D'a", replacement = "D'A"),
                                                 TRUE ~ group))

########################################## from_level_4 ##########################################
datafinal$from[datafinal$from == "Non Observed"] <- "Não Observado"
datafinal$from[datafinal$from == "Forest Formation"] <- "Formação de Floresta"
datafinal$from[datafinal$from == "Grassland"] <- "Pradaria"
datafinal$from[datafinal$from == "Pasture"] <- "Pastagem"
datafinal$from[datafinal$from == "Urban Infrastructure"] <- "Infraestrutura Urbana"
datafinal$from[datafinal$from == "River, Lake and Ocean"] <- "Rios, Lagos ou Oceanos"
datafinal$from[datafinal$from == "Other Non Vegetated Area"] <- "Outras áreas não vegetadas"
datafinal$from[datafinal$from == "Magrove"] <- "Mangue"
datafinal$from[datafinal$from == "Forest Plantation"] <- "Plantação de Floresta"
datafinal$from[datafinal$from == "Mining"] <- "Mineiração"
datafinal$from[datafinal$from == "Mosaic of Crops"] <- "Mosaico de Cultivos"
datafinal$from[datafinal$from == "Soy Beans"] <- "Soja"
datafinal$from[datafinal$from == "Sugar Cane"] <- "Cana-de-açúcar"
datafinal$from[datafinal$from == "Savanna Formation"] <- "Formação de Savana"
datafinal$from[datafinal$from == "Beach and Dune"] <- "Praia e Dunas"
datafinal$from[datafinal$from == "Salt flat"] <- "Salar"
datafinal$from[datafinal$from == "Wetland"] <- "Pântano"
datafinal$from[datafinal$from == "Mosaic of Agriculture and Pasture"] <- "Mosaico de Agricultura e Pastagem"
datafinal$from[datafinal$from == "Aquaculture"] <- "Aquacultura"
datafinal$from[datafinal$from == "Other Perennial Crops"] <- "Outros Cultivos Perenes"
datafinal$from[datafinal$from == "Wooded Restinga"] <- "Restinga Arborizada"
datafinal$from[datafinal$from == "Restinga Herbacea/Arbustiva"] <- "Restinga Herbácea/Arbustiva"
datafinal$from[datafinal$from == "Rocky outcrop"] <- "Afloramento Rochoso"
datafinal$from[datafinal$from == "Coffe"] <- "Café"
datafinal$from[datafinal$from == "Cotton"] <- "Algodão"
datafinal$from[datafinal$from == "Other Temporary Crops"] <- "Outros Cultivos Temporários"
datafinal$from[datafinal$from == "Citrus"] <- "Cultivos Cítricos"
datafinal$from[datafinal$from == "Rice"] <- "Arroz"
datafinal$from[datafinal$from == "Other Non Forest Natural Formation"] <- "Outras Formações Não Florestais Naturais"

########################################## to_level_4 ##########################################
datafinal$to[datafinal$to == "Non Observed"] <- "Não Observado"
datafinal$to[datafinal$to == "Forest Formation"] <- "Formação de Floresta"
datafinal$to[datafinal$to == "Grassland"] <- "Pradaria"
datafinal$to[datafinal$to == "Pasture"] <- "Pastagem"
datafinal$to[datafinal$to == "Urban Infrastructure"] <- "Infraestrutura Urbana"
datafinal$to[datafinal$to == "River, Lake and Ocean"] <- "Rios, Lagos ou Oceanos"
datafinal$to[datafinal$to == "Other Non Vegetated Area"] <- "Outras áreas não vegetadas"
datafinal$to[datafinal$to == "Magrove"] <- "Mangue"
datafinal$to[datafinal$to == "Forest Plantation"] <- "Plantação de Floresta"
datafinal$to[datafinal$to == "Mining"] <- "Mineiração"
datafinal$to[datafinal$to == "Mosaic of Crops"] <- "Mosaico de Cultivos"
datafinal$to[datafinal$to == "Soy Beans"] <- "Soja"
datafinal$to[datafinal$to == "Sugar Cane"] <- "Cana-de-açúcar"
datafinal$to[datafinal$to == "Savanna Formation"] <- "Formação de Savana"
datafinal$to[datafinal$to == "Beach and Dune"] <- "Praia e Dunas"
datafinal$to[datafinal$to == "Salt flat"] <- "Salar"
datafinal$to[datafinal$to == "Wetland"] <- "Pântano"
datafinal$to[datafinal$to == "Mosaic of Agriculture and Pasture"] <- "Mosaico de Agricultura e Pastagem"
datafinal$to[datafinal$to == "Aquaculture"] <- "Aquacultura"
datafinal$to[datafinal$to == "Salar"] <- "Salar"
datafinal$to[datafinal$to == "Other Perennial Crops"] <- "Outros Cultivos Perenes"
datafinal$to[datafinal$to == "Wooded Restinga"] <- "Restinga Arborizada"
datafinal$to[datafinal$to == "Restinga Herbacea/Arbustiva"] <- "Restinga Herbácea/Arbustiva"
datafinal$to[datafinal$to == "Rocky outcrop"] <- "Afloramento Rochoso"
datafinal$to[datafinal$to == "Coffe"] <- "Café"
datafinal$to[datafinal$to == "Cotton"] <- "Algodão"
datafinal$to[datafinal$to == "Other Temporary Crops"] <- "Outros Cultivos Temporários"
datafinal$to[datafinal$to == "Citrus"] <- "Cultivos Cítricos"
datafinal$to[datafinal$to == "Rice"] <- "Arroz"
datafinal$to[datafinal$to == "Other Non Forest Natural Formation"] <- "Outras Formações Não Florestais Naturais"

datafinal$group <- paste(datafinal$group, "-",datafinal$state, sep = " ")
datafinal$state <- NULL

datafinal$value[is.na(datafinal$value)] <- 0
datafinal <- datafinal[order(datafinal$group, datafinal$time_span),]
datafinal$value <- round(datafinal$value, digits = 2)
saveRDS(datafinal, "data/mapbiomas_transicao_munic_5.rds")



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
  var_group = "Mapbiomas",
  tipo = 1,
  unidade = "hectare",
  categoria= "Meio ambiente", 
  subcategoria = "Uso da terra"
)

temp_param_table$label[temp_param_table$var == "group"] <- "Município"
temp_param_table$label[temp_param_table$var == "time_span"] <- "Intervalo de Tempo"
temp_param_table$desc[temp_param_table$var == "group"] <- "Município"
temp_param_table$desc[temp_param_table$var == "time_span"] <- "Intervalo"
temp_param_table$y <- c(rep(FALSE, 4), rep(TRUE, 1))
temp_param_table$x <- c(rep(TRUE, 1),rep(FALSE, 3), rep(TRUE, 1))
temp_param_table$color <- c(rep(FALSE, 3), rep(TRUE, 2))
temp_param_table$size <- c(rep(FALSE, 3), rep(TRUE, 2))
temp_param_table$slider <- c(rep(FALSE, 3), rep(TRUE, 2))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_transicao_munic_dic.csv", fileEncoding = "UTF-8")
