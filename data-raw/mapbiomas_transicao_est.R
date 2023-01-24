############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(readxl)

dat <- load_mapbiomas_transition(space_aggregation = "state", transition_interval = 5)

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



data1$group <- paste(data1$from_level_4, " para ",data1$to_level_4)
data1$to_level_4 <- NULL
data1$from_level_4 <- NULL

colnames(data1) <- c("state", "area", "time", "group")



datafinal <- reshape(data1, idvar = c("state", "time"), timevar = "group", direction = "wide")
labl <- colnames(datafinal)
labl <- labl[-c(1,2)]
labl <- substr(labl, 6, 100)
colnames(datafinal) <- c("group", "time", labl)
datafinal[is.na(datafinal)] <- 0
datafinal[,3:233] <- round(datafinal[,3:233], digits = 2)
saveRDS(datafinal, "data/mapbiomas_transicao_est.rds")

datafinal <- readRDS("data/mapbiomas_transicao_est.rds")

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
  unidade = "m^2",
  categoria= "Meio ambiente", 
  subcategoria = "Uso da terra"
)

temp_param_table$label[1] <- "Estado"
temp_param_table$label[2] <- "Intervalo de tempo"
temp_param_table$desc[1] <- "Estado"
temp_param_table$desc[2] <- "Intervalo de tempo"
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 231))
temp_param_table$color <- c(rep(TRUE, 1), rep(FALSE, 232))
temp_param_table$size <- c(rep(TRUE, 1), rep(FALSE, 232))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 231))

# remove multiple white spaces
temp_param_table$var <- stringr::str_squish(temp_param_table$var)


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_transicao_est_dic.csv", fileEncoding = "UTF-8")

#############################
# Build Dictionary in English
#############################

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
    unidade = "m^2",
    categoria= "Meio ambiente", 
    subcategoria = "Uso da terra"
)

temp_param_table$label[1] <- "State"
temp_param_table$label[2] <- "Time period"
temp_param_table$desc[1] <- "State"
temp_param_table$desc[2] <- "Time period"
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 231))
temp_param_table$color <- c(rep(TRUE, 1), rep(FALSE, 232))
temp_param_table$size <- c(rep(TRUE, 1), rep(FALSE, 232))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 231))

# remove multiple white spaces
temp_param_table$var <- stringr::str_squish(temp_param_table$var)

temp_param_table$label[temp_param_table$var=="Cana-de-açúcar para Cana-de-açúcar"] <- "Sugar Cane to Sugar Cane"
temp_param_table$label[temp_param_table$var=="Cana-de-açúcar para Formação de Floresta"] <- "Sugar Cane to Forest Formation"
temp_param_table$label[temp_param_table$var=="Cana-de-açúcar para Formação de Savana"] <- "Sugar Cane to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Cana-de-açúcar para Infraestrutura Urbana"] <- "Sugar Cane to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Cana-de-açúcar para Mineiração"] <- "Sugar Cane to Mining"
temp_param_table$label[temp_param_table$var=="Cana-de-açúcar para Mosaico de Cultivos"] <- "Sugar Cane to Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Cana-de-açúcar para Pastagem"] <- "Sugar Cane to Pasture"
temp_param_table$label[temp_param_table$var=="Cana-de-açúcar para Plantação de Floresta"] <- "Sugar Cane to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Cana-de-açúcar para Pradaria"] <- "Sugar Cane to Grassland"
temp_param_table$label[temp_param_table$var=="Cana-de-açúcar para Rios, Lagos ou Oceanos"] <- "Sugar Cane to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Cana-de-açúcar para Soja"] <- "Sugar Cane to Soy Beans"

temp_param_table$label[temp_param_table$var=="Formação de Floresta para Formação de Floresta"] <- "Forest Formation to Forest Formation"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Cana-de-açúcar"] <- "Forest Formation to Sugar Cane"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Formação de Savana"] <- "Forest Formation to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Infraestrutura Urbana"] <- "Forest Formation to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Mangue"] <- "Forest Formation to Magrove"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Mineiração"] <- "Forest Formation to Mining"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Mosaico de Cultivos "] <- "Forest Formation to Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Não Observado"] <- "Forest Formation to Non Observed"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Outras áreas não vegetadas"] <- "Forest Formation to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Pastagem"] <- "Forest Formation to Pasture"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Plantação de Floresta"] <- "Forest Formation to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Pradaria"] <- "Forest Formation to Grassland"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Praia e Dunas"] <- "Forest Formation to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Rios, Lagos ou Oceanos"] <- "Forest Formation to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Salar"] <- "Forest Formation to Salt flat"
temp_param_table$label[temp_param_table$var=="Formação de Floresta para Soja"] <- "Forest Formation to Soy Beans"


temp_param_table$label[temp_param_table$var=="Formação de Savana para Formação de Floresta"] <- "Savanna Formation to Forest Formation"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Cana-de-açúcar"] <- "Savanna Formation to Sugar Cane"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Formação de Savana"] <- "Savanna Formation to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Infraestrutura Urbana"] <- "Savanna Formation to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Mangue"] <- "Savanna Formation to Magrove"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Mineiração"] <- "Savanna Formation to Mining"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Mosaico de Cultivos "] <- "Savanna Formation to Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Não Observado"] <- "Savanna Formation to Non Observed"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Outras áreas não vegetadas"] <- "Savanna Formation to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Pastagem"] <- "Savanna Formation to Pasture"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Plantação de Floresta"] <- "Savanna Formation to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Pradaria"] <- "Savanna Formation to Grassland"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Praia e Dunas"] <- "Savanna Formation to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Rios, Lagos ou Oceanos"] <- "Savanna Formation to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Salar"] <- "Savanna Formation to Salt flat"
temp_param_table$label[temp_param_table$var=="Formação de Savana para Soja"] <- "Savanna Formation to Soy Beans"

temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Formação de Floresta"] <- "Urban Infrastructure to Forest Formation"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Formação de Savana"] <- "Urban Infrastructure to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Infraestrutura Urbana"] <- "Urban Infrastructure to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Mangue"] <- "Urban Infrastructure to Magrove"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Mineiração"] <- "Urban Infrastructure to Mining"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Mosaico de Cultivos "] <- "Urban Infrastructure to Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Não Observado"] <- "Urban Infrastructure to Non Observed"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Outras áreas não vegetadas"] <- "Urban Infrastructure to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Pastagem"] <- "Urban Infrastructure to Pasture"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Pradaria"] <- "Urban Infrastructure to Grassland"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Praia e Dunas"] <- "Urban Infrastructure to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Rios, Lagos ou Oceanos"] <- "Urban Infrastructure to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Salar"] <- "Urban Infrastructure to Salt flat"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana para Soja"] <- "Urban Infrastructure to Soy Beans"

temp_param_table$label[temp_param_table$var=="Mangue para Formação de Floresta"] <- "Magrove to Forest Formation"
temp_param_table$label[temp_param_table$var=="Mangue para Formação de Savana"] <- "Magrove to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Mangue para Infraestrutura Urbana"] <- "Magrove to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Mangue para Mangue"] <- "Magrove to Magrove"
temp_param_table$label[temp_param_table$var=="Mangue para Mineiração"] <- "Magrove to Mining"
temp_param_table$label[temp_param_table$var=="Mangue para Mosaico de Cultivos "] <- "Magrove to Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Mangue para Não Observado"] <- "Magrove to Non Observed"
temp_param_table$label[temp_param_table$var=="Mangue para Outras áreas não vegetadas"] <- "Magrove to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Mangue para Pastagem"] <- "Magrove to Pasture"
temp_param_table$label[temp_param_table$var=="Mangue para Plantação de Floresta"] <- "Magrove to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Mangue para Pradaria"] <- "Magrove to Grassland"
temp_param_table$label[temp_param_table$var=="Mangue para Praia e Dunas"] <- "Magrove to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Mangue para Rios, Lagos ou Oceanos"] <- "Magrove to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Mangue para Salar"] <- "Magrove to Salt flat"

temp_param_table$label[temp_param_table$var=="Mineiração para Formação de Floresta"] <- "Mining to Forest Formation"
temp_param_table$label[temp_param_table$var=="Mineiração para Cana-de-açúcar"] <- "Mining to Sugar Cane"
temp_param_table$label[temp_param_table$var=="Mineiração para Formação de Savana"] <- "Mining to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Mineiração para Infraestrutura Urbana"] <- "Mining to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Mineiração para Mineiração"] <- "Mining to Mining"
temp_param_table$label[temp_param_table$var=="Mineiração para Mosaico de Cultivos "] <- "Mining to Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Mineiração para Não Observado"] <- "Mining to Non Observed"
temp_param_table$label[temp_param_table$var=="Mineiração para Outras áreas não vegetadas"] <- "Mining to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Mineiração para Pastagem"] <- "Mining to Pasture"
temp_param_table$label[temp_param_table$var=="Mineiração para Plantação de Floresta"] <- "Mining to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Mineiração para Pradaria"] <- "Mining to Grassland"
temp_param_table$label[temp_param_table$var=="Mineiração para Rios, Lagos ou Oceanos"] <- "Mining to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Mineiração para Salar"] <- "Mining to Salt flat"
temp_param_table$label[temp_param_table$var=="Mineiração para Soja"] <- "Mining to Soy Beans"


temp_param_table$label[temp_param_table$var=="Mosaico de Agricultura e Pastagem para Formação de Floresta"] <- "Mosaic of Agriculture and Pasture to Forest Formation"
temp_param_table$label[temp_param_table$var=="Mosaico de Agricultura e Pastagem para Cana-de-açúcar"] <- "Mosaic of Agriculture and Pasture to Sugar Cane"
temp_param_table$label[temp_param_table$var=="Mosaico de Agricultura e Pastagem para Mosaico de Agricultura e Pastagem"] <- "Mosaic of Agriculture and Pasture to Mosaic of Agriculture and Pasture"
temp_param_table$label[temp_param_table$var=="Mosaico de Agricultura e Pastagem para Pastagem"] <- "Mosaic of Agriculture and Pasture to Pasture"

temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Formação de Floresta"] <- "Mosaic of Crops to Forest Formation"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Cana-de-açúcar"] <- "Mosaic of Crops to Sugar Cane"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Formação de Savana"] <- "Mosaic of Crops to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Infraestrutura Urbana"] <- "Mosaic of Crops to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Mangue"] <- "Mosaic of Crops to Magrove"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Mineiração"] <- "Mosaic of Crops to Mining"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Mosaico de Cultivos "] <- "Mosaic of Crops to Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Não Observado"] <- "Mosaic of Crops to Non Observed"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Outras áreas não vegetadas"] <- "Mosaic of Crops to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Pastagem"] <- "Mosaic of Crops to Pasture"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Plantação de Floresta"] <- "Mosaic of Crops to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Pradaria"] <- "Mosaic of Crops to Grassland"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Praia e Dunas"] <- "Mosaic of Crops to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Rios, Lagos ou Oceanos"] <- "Mosaic of Crops to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Salar"] <- "Mosaic of Crops to Salt flat"
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos para Soja"] <- "Mosaic of Crops to Soy Beans"

temp_param_table$label[temp_param_table$var=="Não Observado para Formação de Floresta"] <- "Non Observed to Forest Formation"
temp_param_table$label[temp_param_table$var=="Não Observado para Formação de Savana"] <- "Non Observed to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Não Observado para Infraestrutura Urbana"] <- "Non Observed to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Não Observado para Mangue"] <- "Non Observed to Magrove"
temp_param_table$label[temp_param_table$var=="Não Observado para Mosaico de Cultivos "] <- "Non Observed to Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Não Observado para Não Observado"] <- "Non Observed to Non Observed"
temp_param_table$label[temp_param_table$var=="Não Observado para Outras áreas não vegetadas"] <- "Non Observed to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Não Observado para Pastagem"] <- "Non Observed to Pasture"
temp_param_table$label[temp_param_table$var=="Não Observado para Plantação de Floresta"] <- "Non Observed to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Não Observado para Pradaria"] <- "Non Observed to Grassland"
temp_param_table$label[temp_param_table$var=="Não Observado para Praia e Dunas"] <- "Non Observed to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Não Observado para Rios, Lagos ou Oceanos"] <- "Non Observed to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Não Observado para Salar"] <- "Non Observed to Salt flat"
temp_param_table$label[temp_param_table$var=="Não Observado para Soja"] <- "Non Observed to Soy Beans"

temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Formação de Floresta"] <- "Other Non Vegetated Areas to Forest Formation"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Formação de Savana"] <- "Other Non Vegetated Areas to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Infraestrutura Urbana"] <- "Other Non Vegetated Areas to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Mangue"] <- "Other Non Vegetated Areas to Magrove"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Mosaico de Cultivos "] <- "Other Non Vegetated Areas to Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Não Observado"] <- "Other Non Vegetated Areas to Non Observed"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Outras áreas não vegetadas"] <- "Other Non Vegetated Areas to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Pastagem"] <- "Other Non Vegetated Areas to Pasture"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Plantação de Floresta"] <- "Other Non Vegetated Areas to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Pradaria"] <- "Other Non Vegetated Areas to Grassland"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Rios, Lagos ou Oceanos"] <- "Other Non Vegetated Areas to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Salar"] <- "Other Non Vegetated Areas to Salt flat"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas para Soja"] <- "Other Non Vegetated Areas to Soy Beans"

temp_param_table$label[temp_param_table$var=="Pântano para Pântano"] <- "Wetland to Wetland"
temp_param_table$label[temp_param_table$var=="Pântano para Pradaria"] <- "Wetland to Grassland"

temp_param_table$label[temp_param_table$var=="Pastagem para Formação de Floresta"] <- "Grassland to Forest Formation"
temp_param_table$label[temp_param_table$var=="Pastagem para Cana-de-açúcar"] <- "Grassland to Sugar Cane"
temp_param_table$label[temp_param_table$var=="Pastagem para Formação de Savana"] <- "Grassland to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Pastagem para Infraestrutura Urbana"] <- "Grassland to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Pastagem para Mangue"] <- "Grassland to Magrove"
temp_param_table$label[temp_param_table$var=="Pastagem para Mineiração"] <- "Grassland to Mining"
temp_param_table$label[temp_param_table$var=="Pastagem para Mosaico de Cultivos "] <- "Grasslandto Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Pastagem para Não Observado"] <- "Grassland to Non Observed"
temp_param_table$label[temp_param_table$var=="Pastagem para Outras áreas não vegetadas"] <- "Grassland to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Pastagem para Pastagem"] <- "Grassland to Pasture"
temp_param_table$label[temp_param_table$var=="Pastagem para Pântano"] <- "Grassland to Wetland"
temp_param_table$label[temp_param_table$var=="Pastagem para Plantação de Floresta"] <- "Grassland to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Pastagem para Pradaria"] <- "Grassland to Grassland"
temp_param_table$label[temp_param_table$var=="Pastagem para Praia e Dunas"] <- "Grassland to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Pastagem para Rios, Lagos ou Oceanos"] <- "Grassland to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Pastagem para Salar"] <- "Grassland to Salt flat"
temp_param_table$label[temp_param_table$var=="Pastagem para Soja"] <- "Grassland to Soy Beans"

temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Formação de Floresta"] <- "Forest Plantation to Forest Formation"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Cana-de-açúcar"] <- "Forest Plantation to Sugar Cane"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Formação de Savana"] <- "Forest Plantation to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Infraestrutura Urbana"] <- "Forest Plantation to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Mineiração"] <- "Forest Plantation to Mining"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Mosaico de Cultivos "] <- "Forest Plantation Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Não Observado"] <- "Forest Plantation to Non Observed"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Outras áreas não vegetadas"] <- "Forest Plantation to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Pastagem"] <- "Forest Plantation to Pasture"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Plantação de Floresta"] <- "Forest Plantation to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Pradaria"] <- "Forest Plantation to Grassland"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Rios, Lagos ou Oceanos"] <- "Forest Plantation to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta para Soja"] <- "Forest Plantation to Soy Beans"

temp_param_table$label[temp_param_table$var=="Pradaria para Formação de Floresta"] <- "Pasture to Forest Formation"
temp_param_table$label[temp_param_table$var=="Pradaria para Cana-de-açúcar"] <- "Pasture to Sugar Cane"
temp_param_table$label[temp_param_table$var=="Pradaria para Formação de Savana"] <- "Pasture to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Pradaria para Infraestrutura Urbana"] <- "Pasture to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Pradaria para Mangue"] <- "Pasture to Magrove"
temp_param_table$label[temp_param_table$var=="Pradaria para Mineiração"] <- "Pasture to Mining"
temp_param_table$label[temp_param_table$var=="Pradaria para Mosaico de Cultivos "] <- "Pasture Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Pradaria para Não Observado"] <- "Pasture to Non Observed"
temp_param_table$label[temp_param_table$var=="Pradaria para Outras áreas não vegetadas"] <- "Pasture to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Pradaria para Pastagem"] <- "Pasture to Pasture"
temp_param_table$label[temp_param_table$var=="Pradaria para Pântano"] <- "Pasture to Wetland"
temp_param_table$label[temp_param_table$var=="Pradaria para Plantação de Floresta"] <- "Pasture to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Pradaria para Pradaria"] <- "Pasture to Grassland"
temp_param_table$label[temp_param_table$var=="Pradaria para Praia e Dunas"] <- "Pasture to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Pradaria para Rios, Lagos ou Oceanos"] <- "Pasture to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Pradaria para Salar"] <- "Pasture to Salt flat"
temp_param_table$label[temp_param_table$var=="Pradaria para Soja"] <- "Pasture to Soy Beans"

temp_param_table$label[temp_param_table$var=="Praia e Dunas para Formação de Floresta"] <- "Beach and Dune to Forest Formation"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Formação de Savana"] <- "Beach and Dune to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Infraestrutura Urbana"] <- "Beach and Dune to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Mangue"] <- "Beach and Dune to Magrove"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Mosaico de Cultivos "] <- "Beach and Dune Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Não Observado"] <- "Beach and Dune to Non Observed"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Outras áreas não vegetadas"] <- "Beach and Dune to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Pastagem"] <- "Beach and Dune to Pasture"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Plantação de Floresta"] <- "Beach and Dune to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Pradaria"] <- "Beach and Dune to Grassland"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Praia e Dunas"] <- "Beach and Dune to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Rios, Lagos ou Oceanos"] <- "Beach and Dune to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Praia e Dunas para Salar"] <- "Beach and Dune to Salt flat"

temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Formação de Floresta"] <- "River, Lake and Ocean to Forest Formation"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Cana-de-açúcar"] <- "River, Lake and Ocean to Sugar Cane"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Formação de Savana"] <- "River, Lake and Ocean to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Infraestrutura Urbana"] <- "River, Lake and Ocean to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Mangue"] <- "River, Lake and Ocean to Magrove"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Mineiração"] <- "River, Lake and Ocean to Mining"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Mosaico de Cultivos "] <- "River, Lake and Ocean Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Não Observado"] <- "River, Lake and Ocean to Non Observed"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Outras áreas não vegetadas"] <- "River, Lake and Ocean to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Pastagem"] <- "River, Lake and Ocean to Pasture"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Plantação de Floresta"] <- "River, Lake and Ocean to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Pradaria"] <- "River, Lake and Ocean to Grassland"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Praia e Dunas"] <- "River, Lake and Ocean to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Rios, Lagos ou Oceanos"] <- "River, Lake and Ocean to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Salar"] <- "River, Lake and Ocean to Salt flat"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos para Soja"] <- "River, Lake and Ocean to Soy Beans"

temp_param_table$label[temp_param_table$var=="Salar para Formação de Floresta"] <- "Salt flat to Forest Formation"
temp_param_table$label[temp_param_table$var=="Salar para Formação de Savana"] <- "Salt flat to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Salar para Infraestrutura Urbana"] <- "Salt flat to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Salar para Mangue"] <- "Salt flat to Magrove"
temp_param_table$label[temp_param_table$var=="Salar para Mineiração"] <- "Salt flat to Mining"
temp_param_table$label[temp_param_table$var=="Salar para Mosaico de Cultivos "] <- "Salt flat Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Salar para Não Observado"] <- "Salt flat to Non Observed"
temp_param_table$label[temp_param_table$var=="Salar para Outras áreas não vegetadas"] <- "Salt flat to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Salar para Pastagem"] <- "Salt flat to Pasture"
temp_param_table$label[temp_param_table$var=="Salar para Plantação de Floresta"] <- "Salt flat to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Salar para Pradaria"] <- "Salt flat to Grassland"
temp_param_table$label[temp_param_table$var=="Salar para Praia e Dunas"] <- "Salt flat to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Salar para Rios, Lagos ou Oceanos"] <- "Salt flat to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Salar para Salar"] <- "Salt flat to Salt flat"

temp_param_table$label[temp_param_table$var=="Soja para Formação de Floresta"] <- "Soy Beans to Forest Formation"
temp_param_table$label[temp_param_table$var=="Soja para Cana-de-açúcar"] <- "Soy Beans to Sugar Cane"
temp_param_table$label[temp_param_table$var=="Soja para Formação de Savana"] <- "Soy Beans to Savanna Formation"
temp_param_table$label[temp_param_table$var=="Soja para Infraestrutura Urbana"] <- "Soy Beans to Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Soja para Mineiração"] <- "Soy Beans to Mining"
temp_param_table$label[temp_param_table$var=="Soja para Mosaico de Cultivos "] <- "Soy Beans Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Soja para Não Observado"] <- "Soy Beans to Non Observed"
temp_param_table$label[temp_param_table$var=="Soja para Outras áreas não vegetadas"] <- "Soy Beans to Other Non Vegetated Areas"
temp_param_table$label[temp_param_table$var=="Soja para Pastagem"] <- "Soy Beans to Pasture"
temp_param_table$label[temp_param_table$var=="Soja para Plantação de Floresta"] <- "Soy Beans to Forest Plantation"
temp_param_table$label[temp_param_table$var=="Soja para Pradaria"] <- "Soy Beans to Grassland"
temp_param_table$label[temp_param_table$var=="Soja para Praia e Dunas"] <- "Soy Beans to Beach and Dune"
temp_param_table$label[temp_param_table$var=="Soja para Rios, Lagos ou Oceanos"] <- "Soy Beans to River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Soja para Soja"] <- "Soy Beans to Soy Beans"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_transicao_est_dic_en.csv", fileEncoding = "UTF-8")

