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
data1$from_level_4[data1$from_level_4 == "Other Non Vegetated Area"] <- "Outras Áreas não vegetadas"
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
data1$to_level_4[data1$to_level_4 == "Other Non Vegetated Area"] <- "Outras Áreas não vegetadas"
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

datafinal <- readRDS("~/GitHub/datazoom_viz/data/mapbiomas_transicao_est.rds")

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


temp_param_table$label <- str_replace_all(temp_param_table$label, c(  "para" = "to",
                                            "Não Observado" = "Non Observed",
                                            "Formação de Floresta" = "Forest Formation",
                                            "Pradaria" = "Grassland",
                                            "Pastagem" = "Pasture",
                                            "Infraestrutura Urbana" = "Urban Infrastructure",
                                            "Rios, Lagos ou Oceanos" = "River, Lake and Ocean",
                                            "Outras Áreas não vegetadas" = "Other Non Vegetated Area",
                                            "Mangue" = "Magrove",
                                            "Plantação de Floresta" = "Forest Plantation",
                                            "Mineiração" = "Mining",
                                            "Mosaico de Cultivos" = "Mosaic of Crops",
                                            "Soja" = "Soy Beans",
                                            "Cana-de-açúcar" = "Sugar Cane",
                                            "Formação de Savana" = "Savanna Formation",
                                            "Praia e Dunas" = "Beach and Dune",
                                            "Salar" = "Salt flat",
                                            "Pântano" = "Wetland",
                                            "Mosaico de Agricultura e Pastagem" = "Mosaic of Agriculture and Pasture",
                                            "Mosaico de Agricultura e Pasture" = "Mosaic of Agriculture and Pasture"))



# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_transicao_est_dic_en.csv", fileEncoding = "UTF-8")

