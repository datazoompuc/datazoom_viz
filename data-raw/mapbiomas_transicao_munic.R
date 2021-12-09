############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(readxl)

dat <- load_mapbiomas_transition(space_aggregation = "municipality", transition_interval = 5)

saveRDS(dat, file = "data/mapbiomas_transicao_munic_raw.rds")
dat <- readRDS(file = "data/mapbiomas_transicao_munic_raw.rds")

filter_year_diff <- function(dat, year_diff){
  vec_col <- c()
  for(i in 16:ncol(dat)){
    nome <- colnames(dat)[i]
    anoi <- as.numeric(substring(nome,2,5))
    anof <- as.numeric(substring(nome,10,14))
    if(anof - anoi != year_diff){
      vec_col <- c(vec_col, -i)
    }
  }
  dat_filtered <- dat[, vec_col]
  return(dat_filtered)
}
dat <- filter_year_diff(dat, 5)

# Data for level_4
data1 <- dat
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
data1$from_level_4[data1$from_level_4 == "Perennial Crops"] <- "Cultivos temporários"
data1$from_level_4[data1$from_level_4 == "Rocky outcrop"] <- "Afloramento rochoso"
data1$from_level_4[data1$from_level_4 == "Aquaculture"] <- "Aquacultura"
data1$from_level_4[data1$from_level_4 == "Other Non Forest Natural Formation"] <- "Outras Formações Naturais não Florestais"
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
data1$to_level_4[data1$to_level_4 == "Perennial Crops"] <- "Cultivos temporários"
data1$to_level_4[data1$to_level_4 == "Rocky outcrop"] <- "Afloramento rochoso"
data1$to_level_4[data1$to_level_4 == "Aquaculture"] <- "Aquacultura"
data1$to_level_4[data1$to_level_4 == "Other Non Forest Natural Formation"] <- "Outras Formações Naturais não Florestais"


data1$group <- paste(data1$from_level_4, " para ",data1$to_level_4)
data1$to_level_4 <- NULL
data1$from_level_4 <- NULL
data1$munic <- paste(data1$municipality, " - ",data1$state)
data1$municipality <- NULL
data1$state <- NULL

to_long <- function(data1){
  aux3 <- data.frame()
  for(j in 1:(ncol(data1)-2)){
    aux1 <- data1 %>% select(group, munic)
    nome <- colnames(data1)[j]
    anoi <- as.numeric(substring(nome,2,5))
    anof <- as.numeric(substring(nome,10,14))
    year <- paste("Entre ", anoi, " e ", anof)
    vect <- rep(year, nrow(data1))
    aux2 <- cbind(data1[,j], aux1, vect)
    colnames(aux2) <- c("area", "group", "municipality", "time")
    aux3 <- rbind(aux3, aux2)
  }
  return(aux3)
}
data1 <- to_long(data1)

datafinal <- reshape(data1, idvar = c("municipality", "time"), timevar = "group", direction = "wide")
labl <- colnames(datafinal)
labl <- labl[-c(1,2)]
labl <- substr(labl, 6, 100)
colnames(datafinal) <- c("group", "time", labl)
datafinal[is.na(datafinal)] <- 0
datafinal <- datafinal[order(datafinal$group, datafinal$time),]
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
  unidade = "hectar",
  categoria= "Meio ambiente", 
  subcategoria = "Uso da terra"
)

temp_param_table$label[1] <- "Município"
temp_param_table$label[2] <- "Intervalo"
temp_param_table$desc[1] <- "Município"
temp_param_table$desc[2] <- "Intervalo"
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 460))
temp_param_table$color <- c(rep(FALSE, 2), rep(TRUE, 460))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 460))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 460))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_transicao_munic_dic.csv", fileEncoding = "UTF-8")
