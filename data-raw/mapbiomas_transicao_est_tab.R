############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(readxl)

dat <- load_mapbiomas(dataset = "mapbiomas_transition", geo_level = "state")

saveRDS(dat, file = "data/mapbiomas_transicao_est_raw.rds")
dat <- readRDS("data/mapbiomas_transicao_est_raw.rds")


# Data for level_4
data1 <- dat
data1$biome <- NULL
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

# Translation
data1$from_level_4[data1$from_level_4 == "Non Observed"] <- "Não Observado"
data1$from_level_4[data1$from_level_4 == "Forest Formation"] <- "Formação de Floresta"
data1$from_level_4[data1$from_level_4 == "Grassland"] <- "Pradaria"
data1$from_level_4[data1$from_level_4 == "Pasture"] <- "Pastagem"
data1$from_level_4[data1$from_level_4 == "Urban Infrastructure"] <- "Infraestrutura Urbana"
data1$from_level_4[data1$from_level_4 == "River, Lake and Ocean"] <- "Rios, Lagos ou Oceanos"
data1$from_level_4[data1$from_level_4 == "Other Non Vegetated Area"] <- "Outras áreas não vegetadas"
data1$from_level_4[data1$from_level_4 == "Magrove"] <- "Mangue"
data1$from_level_4[data1$from_level_4 == "Forest Plantation"] <- "Plantação de Floresta"
data1$from_level_4[data1$from_level_4 == "Mining"] <- "Mineiração"
data1$from_level_4[data1$from_level_4 == "Mosaic of Crops"] <- "Mosaico de Cultivos"
data1$from_level_4[data1$from_level_4 == "Soy Beans"] <- "Soja"
data1$from_level_4[data1$from_level_4 == "Sugar Cane"] <- "Cana-de-açúcar"
data1$from_level_4[data1$from_level_4 == "Savanna Formation"] <- "Formação de Savana"
data1$from_level_4[data1$from_level_4 == "Beach and Dune"] <- "Praia e Dunas"
data1$from_level_4[data1$from_level_4 == "Salt flat"] <- "Salar"
data1$from_level_4[data1$from_level_4 == "Wetland"] <- "Pântano"
data1$from_level_4[data1$from_level_4 == "Mosaic of Agriculture and Pasture"] <- "Mosaico de Agricultura e Pastagem"
data1$to_level_4[data1$to_level_4 == "Non Observed"] <- "Não Observado"
data1$to_level_4[data1$to_level_4 == "Forest Formation"] <- "Formação de Floresta"
data1$to_level_4[data1$to_level_4 == "Grassland"] <- "Pradaria"
data1$to_level_4[data1$to_level_4 == "Pasture"] <- "Pastagem"
data1$to_level_4[data1$to_level_4 == "Urban Infrastructure"] <- "Infraestrutura Urbana"
data1$to_level_4[data1$to_level_4 == "River, Lake and Ocean"] <- "Rios, Lagos ou Oceanos"
data1$to_level_4[data1$to_level_4 == "Other Non Vegetated Area"] <- "Outras áreas não vegetadas"
data1$to_level_4[data1$to_level_4 == "Magrove"] <- "Mangue"
data1$to_level_4[data1$to_level_4 == "Forest Plantation"] <- "Plantação de Floresta"
data1$to_level_4[data1$to_level_4 == "Mining"] <- "Mineiração"
data1$to_level_4[data1$to_level_4 == "Mosaic of Crops"] <- "Mosaico de Cultivos"
data1$to_level_4[data1$to_level_4 == "Soy Beans"] <- "Soja"
data1$to_level_4[data1$to_level_4 == "Sugar Cane"] <- "Cana-de-açúcar"
data1$to_level_4[data1$to_level_4 == "Savanna Formation"] <- "Formação de Savana"
data1$to_level_4[data1$to_level_4 == "Beach and Dune"] <- "Praia e Dunas"
data1$to_level_4[data1$to_level_4 == "Salt flat"] <- "Salar"
data1$to_level_4[data1$to_level_4 == "Wetland"] <- "Pântano"
data1$to_level_4[data1$to_level_4 == "Mosaic of Agriculture and Pasture"] <- "Mosaico de Agricultura e Pastagem"

colnames(data1) <- c("group", "from", "to", "area", "time")

data1 <- data1 %>% 
  filter(from != "Não Observado") %>% 
  filter(to != "Não Observado") %>% 
  mutate(time = stringr::str_replace_all(time, "to", "a"))

saveRDS(data1, "data/mapbiomas_transicao_est_tab.rds")


#####################
# Build Dictionary 
#####################

# extract variables from data
columns <- colnames(data1)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = c(TRUE, rep(FALSE, 4)),
  y = c(rep(FALSE, 4), TRUE),
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = columns,
  desc = columns,
  var_group = "Mapbiomas",
  tipo = 1,
  unidade = "m^2",
  categoria= "Meio ambiente", 
  subcategoria = "Uso da terra"
)

temp_param_table$label[1] <- "Estado"
temp_param_table$label[5] <- "Intervalo de tempo"
temp_param_table$desc[1] <- "Estado"
temp_param_table$desc[5] <- "Intervalo de tempo"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_transicao_est_tab_dic.csv", fileEncoding = "UTF-8")
