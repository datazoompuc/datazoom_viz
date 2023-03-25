#################################################
#### Generate rds data in the folder ./data/ ####
#################################################

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
data1$to_color <- NULL
data1$class_id_from <- NULL
data1$from_color <- NULL
data1$from_class <- NULL
data1$to_class <- NULL

###############
# Translation #
###############

########################################## from_level_4 ##########################################
data1$from_level_4[data1$from_level_4 == "Non Observed"] <- "N\u00e3o Observado"
data1$from_level_4[data1$from_level_4 == "Forest Formation"] <- "Forma\u00e7\u00e3o de Floresta"
data1$from_level_4[data1$from_level_4 == "Grassland"] <- "Pradaria"
data1$from_level_4[data1$from_level_4 == "Pasture"] <- "Pastagem"
data1$from_level_4[data1$from_level_4 == "Urban Infrastructure"] <- "Infraestrutura Urbana"
data1$from_level_4[data1$from_level_4 == "River, Lake and Ocean"] <- "Rios, Lagos ou Oceanos"
data1$from_level_4[data1$from_level_4 == "Other Non Vegetated Area"] <- "Outras \u00e1reas n\u00e3o vegetadas"
data1$from_level_4[data1$from_level_4 == "Magrove"] <- "Mangue"
data1$from_level_4[data1$from_level_4 == "Forest Plantation"] <- "Planta\u00e7\u00e3o de Floresta"
data1$from_level_4[data1$from_level_4 == "Mining"] <- "Mineira\u00e7\u00e3o"
data1$from_level_4[data1$from_level_4 == "Mosaic of Crops"] <- "Mosaico de Cultivos"
data1$from_level_4[data1$from_level_4 == "Soy Beans"] <- "Soja"
data1$from_level_4[data1$from_level_4 == "Sugar Cane"] <- "Cana-de-a\u00e7\u00facar"
data1$from_level_4[data1$from_level_4 == "Savanna Formation"] <- "Forma\u00e7\u00e3o de Savana"
data1$from_level_4[data1$from_level_4 == "Beach and Dune"] <- "Praia e Dunas"
data1$from_level_4[data1$from_level_4 == "Salt flat"] <- "Salar"
data1$from_level_4[data1$from_level_4 == "Wetland"] <- "P\u00e2ntano"
data1$from_level_4[data1$from_level_4 == "Mosaic of Agriculture and Pasture"] <- "Mosaico de Agricultura e Pastagem"
data1$from_level_4[data1$from_level_4 == "Aquaculture"] <- "Aquacultura"
data1$from_level_4[data1$from_level_4 == "Salar"] <- "Salar"
data1$from_level_4[data1$from_level_4 == "Other Perennial Crops"] <- "Outros Cultivos Perenes"
data1$from_level_4[data1$from_level_4 == "Wooded Restinga"] <- "Restinga Arborizada"
data1$from_level_4[data1$from_level_4 == "Restinga Herbacea/Arbustiva"] <- "Restinga Herb\u00e1cea/Arbustiva"
data1$from_level_4[data1$from_level_4 == "Rocky outcrop"] <- "Afloramento Rochoso"
data1$from_level_4[data1$from_level_4 == "Coffe"] <- "Caf\u00e9"
data1$from_level_4[data1$from_level_4 == "Cotton"] <- "Algod\u00e3o"
data1$from_level_4[data1$from_level_4 == "Other Temporary Crops"] <- "Outros Cultivos Tempor\u00e1rios"
data1$from_level_4[data1$from_level_4 == "Citrus"] <- "Cultivos C\u00edtricos"
data1$from_level_4[data1$from_level_4 == "Rice"] <- "Arroz"
data1$from_level_4[data1$from_level_4 == "Other Non Forest Natural Formation"] <- "Outras Forma\u00e7\u00f5es N\u00e3o Florestais Naturais"
########################################## to_level_4 ##########################################
data1$to_level_4[data1$to_level_4 == "Non Observed"] <- "N\u00e3o Observado"
data1$to_level_4[data1$to_level_4 == "Forest Formation"] <- "Forma\u00e7\u00e3o de Floresta"
data1$to_level_4[data1$to_level_4 == "Grassland"] <- "Pradaria"
data1$to_level_4[data1$to_level_4 == "Pasture"] <- "Pastagem"
data1$to_level_4[data1$to_level_4 == "Urban Infrastructure"] <- "Infraestrutura Urbana"
data1$to_level_4[data1$to_level_4 == "River, Lake and Ocean"] <- "Rios, Lagos ou Oceanos"
data1$to_level_4[data1$to_level_4 == "Other Non Vegetated Area"] <- "Outras \u00e1reas n\u00e3o vegetadas"
data1$to_level_4[data1$to_level_4 == "Magrove"] <- "Mangue"
data1$to_level_4[data1$to_level_4 == "Forest Plantation"] <- "Planta\u00e7\u00e3o de Floresta"
data1$to_level_4[data1$to_level_4 == "Mining"] <- "Mineira\u00e7\u00e3o"
data1$to_level_4[data1$to_level_4 == "Mosaic of Crops"] <- "Mosaico de Cultivos"
data1$to_level_4[data1$to_level_4 == "Soy Beans"] <- "Soja"
data1$to_level_4[data1$to_level_4 == "Sugar Cane"] <- "Cana-de-a\u00e7\u00facar"
data1$to_level_4[data1$to_level_4 == "Savanna Formation"] <- "Forma\u00e7\u00e3o de Savana"
data1$to_level_4[data1$to_level_4 == "Beach and Dune"] <- "Praia e Dunas"
data1$to_level_4[data1$to_level_4 == "Salt flat"] <- "Salar"
data1$to_level_4[data1$to_level_4 == "Wetland"] <- "P\u00e2ntano"
data1$to_level_4[data1$to_level_4 == "Mosaic of Agriculture and Pasture"] <- "Mosaico de Agricultura e Pastagem"
data1$to_level_4[data1$to_level_4 == "Aquaculture"] <- "Aquacultura"
data1$to_level_4[data1$to_level_4 == "Salar"] <- "Salar"
data1$to_level_4[data1$to_level_4 == "Other Perennial Crops"] <- "Outros Cultivos Perenes"
data1$to_level_4[data1$to_level_4 == "Wooded Restinga"] <- "Restinga Arborizada"
data1$to_level_4[data1$to_level_4 == "Restinga Herbacea/Arbustiva"] <- "Restinga Herb\u00e1cea/Arbustiva"
data1$to_level_4[data1$to_level_4 == "Rocky outcrop"] <- "Afloramento Rochoso"
data1$to_level_4[data1$to_level_4 == "Coffe"] <- "Caf\u00e9"
data1$to_level_4[data1$to_level_4 == "Cotton"] <- "Algod\u00e3o"
data1$to_level_4[data1$to_level_4 == "Other Temporary Crops"] <- "Outros Cultivos Tempor\u00e1rios"
data1$to_level_4[data1$to_level_4 == "Citrus"] <- "Cultivos C\u00edtricos"
data1$to_level_4[data1$to_level_4 == "Rice"] <- "Arroz"
data1$to_level_4[data1$to_level_4 == "Other Non Forest Natural Formation"] <- "Outras Forma\u00e7\u00f5es N\u00e3o Florestais Naturais"


datafinal <- data1 %>% 
    mutate_all(~replace_na(., 0))  %>%
    relocate(.before = c("year", "state"))

datafinal[,"value"] <- round(datafinal[,"value"], digits = 2)

#filtrando para apenas intervalos de 5 anos
datafinal <- datafinal %>%
    mutate(ano_inicial = str_split_i(year, "_",i = 1), #create inicial year variable
           ano_final = str_split_i(year, "_", i = 2)) %>% #create final year variable
    relocate(ano_final, ano_inicial) %>% # reorganize columns order
    filter(as.numeric(ano_final) - as.numeric(ano_inicial) == 5) %>% #filtering for 5 year span
    select(-c("ano_final", "ano_inicial")) %>% #removing created columns
    rename(time = year, group = state, from = from_level_4, to = to_level_4) #renaming columns

#replace "_" for "-" in the database
datafinal$time <- datafinal$time %>%
    str_replace(pattern = "_", replacement = " - ")

saveRDS(datafinal, "data/mapbiomas_transicao_est.rds")

datafinal <- readRDS("data/mapbiomas_transicao_est.rds")

####################
# Build Dictionary #
####################

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
  unidade = "m<sup>2",
  categoria= "Meio ambiente", 
  subcategoria = "Uso da terra"
)

temp_param_table$label[temp_param_table$var == "year"] <- "Ano"
temp_param_table$label[temp_param_table$var == "time"]  <- "Intervalo de tempo"
temp_param_table$label[temp_param_table$var == "group"]  <- "Estado"
temp_param_table$label[temp_param_table$var == "to"]  <- "Transição de"
temp_param_table$label[temp_param_table$var == "from"]  <- "Transição para"

temp_param_table$desc[temp_param_table$var == "year"]  <- "Ano"
temp_param_table$desc[temp_param_table$var == "time"]  <- "Intervalo de tempo"
temp_param_table$desc[temp_param_table$var == "group"]  <- "Estado"
temp_param_table$desc[temp_param_table$var == "to"]  <- "Transição de"
temp_param_table$desc[temp_param_table$var == "from"]  <- "Transição para"

temp_param_table$y <- c(rep(FALSE, 5), rep(TRUE, 1))
temp_param_table$color <- c(rep(FALSE, 1),c(rep(TRUE, 1), rep(FALSE, 4)))
temp_param_table$size <- c(rep(TRUE, 1), rep(FALSE, (ncol(datafinal) - 1)))
temp_param_table$slider <- c(rep(TRUE, 1), rep(FALSE, (ncol(datafinal) - 1)))

# remove multiple white spaces
temp_param_table$label <- stringr::str_squish(temp_param_table$label)


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_transicao_est_dic.csv", fileEncoding = "UTF-8")

###############################
# Build Dictionary in English #
###############################

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


temp_param_table$label[temp_param_table$var == "year"] <- "Year"
temp_param_table$label[temp_param_table$var == "time"]  <- "Time Span"
temp_param_table$label[temp_param_table$var == "group"]  <- "State"
temp_param_table$label[temp_param_table$var == "to"]  <- "Transition from"
temp_param_table$label[temp_param_table$var == "from"]  <- "Transition to"

temp_param_table$desc[temp_param_table$var == "year"]  <- "Year"
temp_param_table$desc[temp_param_table$var == "time"]  <- "Time Span"
temp_param_table$desc[temp_param_table$var == "group"]  <- "State"
temp_param_table$desc[temp_param_table$var == "to"]  <- "Transition from"
temp_param_table$desc[temp_param_table$var == "from"]  <- "Transition to"

temp_param_table$y <- c(rep(FALSE, 5), rep(TRUE, 1))
temp_param_table$color <- c(rep(FALSE, 1),c(rep(TRUE, 1), rep(FALSE, 4)))
temp_param_table$size <- c(rep(TRUE, 1), rep(FALSE, (ncol(datafinal) - 1)))
temp_param_table$slider <- c(rep(TRUE, 1), rep(FALSE, (ncol(datafinal) - 1)))

# remove multiple white spaces
temp_param_table$label <- stringr::str_squish(temp_param_table$label)

temp_param_table$label <- temp_param_table$label %>% str_replace_all(c(" para " = " to ",
                                                                    "Aquacultura" = "Aquaculture",
                                                                    "Mosaico de Agricultura e Pastagem" = "Mosaic of Agriculture and Pasture",
                                                                    "Outros Cultivos Perenes" = "Other Perennial Crops",
                                                                    "Outros Cultivos Perenes" = "Othere Perennial Crops",
                                                                    "Restinga Arborizada" = "Wooded Restinga",
                                                                    "Outras \u00e1reas n\u00e3o vegetadas" = "Other Non Vegetated Area",
                                                                    "Restinga Herb\u00e1cea/Arbustiva" = "Restinga Herbacea/Arbustiva",
                                                                    "Afloramento Rochoso" = "Rocky Outcrop",
                                                                    "Outros Cultivos Tempor\u00e1rios" = "Other Temporary Crops",
                                                                    "Outras Forma\u00e7\u00f5es N\u00e3o Florestais Naturais" = "Other Non Forest Natural Formation",
                                                                    "Rios, Lagos ou Oceanos" = "River, Lake and Ocean",
                                                                    "Outros Cultivos Tempor\u00e1rios" = "Othere Temporary Crops",
                                                                    "Planta\u00e7\u00e3o de Floresta" = "Forest Plantation",
                                                                    "N\u00e3o Observado" = "Non Observed",
                                                                    "Forma\u00e7\u00e3o de Floresta" = "Forest Formation",
                                                                    "Forma\u00e7\u00e3o de Savana" = "Savanna Formation",
                                                                    "P\u00e2ntano" = "Wetland",
                                                                    "Pradaria" = "Grassland",
                                                                    "Infraestrutura Urbana" = "Urban Infrastructure",
                                                                    "Soja" = "Soy Beans",
                                                                    "Mangue" = "Magrove",
                                                                    "Mineira\u00e7\u00e3o" = "Mining",
                                                                    "Praia e Dunas" = "Beaches and Dunes",
                                                                    "Caf\u00e9" = "Coffee",
                                                                    "Cultivos C\u00edtricos" = "Citrus",
                                                                    "Arroz" = "Rice",
                                                                    "Algod\u00e3o" = "Cotton",
                                                                    "Cana-de-a\u00e7\u00facar" = "Sugar Cane",
                                                                    "Pastagem" = "Pasture"))


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_transicao_est_dic_en.csv", fileEncoding = "UTF-8")
