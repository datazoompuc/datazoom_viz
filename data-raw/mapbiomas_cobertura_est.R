############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(readxl)

dat <- load_mapbiomas_covering(space_aggregation = "state")
colnames(dat)[colnames(dat) == "Leval_zero"] <- "level_0"

saveRDS(dat, file = "data/mapbiomas_cobertura_est_raw.rds")

# Data for level_4
data1 <- dat
data1$level_0 <- NULL
data1$level_1 <- NULL
data1$level_2 <- NULL
data1$level_3 <- NULL

data1$group <- data1$level_4
data1$biome <- NULL
data1$level_4 <- NULL

colnames(data1) <- c("state", "area", "time", "group")



# Data for level_3
data2 <- dat
data2$level_0 <- NULL
data2$level_1 <- NULL
data2$level_2 <- NULL
data2$level_4 <- NULL

data2$group <- data2$level_3
data2$biome <- NULL
data2$level_3 <- NULL

colnames(data2) <- c("state", "area", "time", "group")
data2 <- aggregate(area ~ time + state + group, data2, sum)



# Data for level_2
data3 <- dat
data3$level_0 <- NULL
data3$level_1 <- NULL
data3$level_3 <- NULL
data3$level_4 <- NULL

data3$group <- data3$level_2
data3$biome <- NULL
data3$level_2 <- NULL

colnames(data3) <- c("state", "area", "time", "group")
data3 <- aggregate(area ~ time + state + group, data3, sum)



# Data for level_1
data4 <- dat
data4$level_0 <- NULL
data4$level_2 <- NULL
data4$level_3 <- NULL
data4$level_4 <- NULL

data4$group <- data4$level_1
data4$biome <- NULL
data4$level_1 <- NULL

colnames(data4) <- c("state", "area", "time", "group")
data4 <- aggregate(area ~ time + state + group, data4, sum)



# Data for level_0
data5 <- dat
data5$level_1 <- NULL
data5$level_2 <- NULL
data5$level_3 <- NULL
data5$level_4 <- NULL

data5$group <- data5$level_0
data5$biome <- NULL
data5$level_0 <- NULL

colnames(data5) <- c("state", "area", "time", "group")
data5 <- aggregate(area ~ time + state + group, data5, sum)



data <- rbind(data1, data2, data3, data4, data5)
datafinal <- reshape(data, idvar = c("state", "time"), timevar = "group", direction = "wide")
labl <- colnames(datafinal)
labl <- labl[-c(1,2)]
labl <- substr(labl, 6, 100)
sublabl <- labl[22:26]
sublabl <- substr(sublabl, 5, 100)
labl[22:26] <- sublabl
translated_labl <- c("Pastagem", "Formação de Floresta", "Pradaria", "Não Observado",
                     "Outras áreas não vegetadas", "Infraestrutura Urbana", "Rios, Lagos ou Oceanos",
                     "Mosaico de Cultivos", "Soja", "Plantação de Floresta", "Mangue", "Mineiração",
                     "Cana-de-açúcar", "Formação de Savana", "Salar", "Praia e Dunas",
                     "Mosaico de Agricultura e Pastagem", "Pântano", "Cultivos temporários",
                     "Agricultura", "Floresta Natural", "Floresta", "Formação Natural sem ser Floresta",
                     "Fazenda", "Área não Vegetada", "Água", "Formação Antrópica", "Formação Natural",
                     "Não Identificado")
colnames(datafinal) <- c("group", "time", translated_labl)
datafinal[is.na(datafinal)] <- 0
saveRDS(datafinal, "data/mapbiomas_cobertura_est.rds")

datafinal <- readRDS("~/GitHub/datazoom_viz/data/mapbiomas_cobertura_est.rds")

##############################
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

temp_param_table$label[1] <- "UF"
temp_param_table$label[2] <- "Ano"
temp_param_table$desc[1] <- "UF"
temp_param_table$desc[2] <- "Ano"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 29))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 29))
temp_param_table$color <- c(rep(TRUE, 1), rep(FALSE, 30))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 29))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 29))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_est_dic.csv", fileEncoding = "UTF-8")


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
temp_param_table$label[2] <- "Year"
temp_param_table$desc[1] <- "State"
temp_param_table$desc[2] <- "Year"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 29))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 29))
temp_param_table$color <- c(rep(TRUE, 1), rep(FALSE, 30))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 29))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 29))
temp_param_table$label[temp_param_table$var=="Mosaico de Cultivos"] <- "Mosaic of Crops"
temp_param_table$label[temp_param_table$var=="Soja"] <- "Soy Beans"
temp_param_table$label[temp_param_table$var=="Pastagem"] <- "Pasture"
temp_param_table$label[temp_param_table$var=="Infraestrutura Urbana"] <- "Urban Infrastructure"
temp_param_table$label[temp_param_table$var=="Formação de Floresta"] <- "Forest Formation"
temp_param_table$label[temp_param_table$var=="Pradaria"] <- "Grassland"
temp_param_table$label[temp_param_table$var=="Rios, Lagos ou Oceanos"] <- "River, Lake and Ocean"
temp_param_table$label[temp_param_table$var=="Não Observado"] <- "Non Observed"
temp_param_table$label[temp_param_table$var=="Formação de Savana"] <- "Savanna Formation"
temp_param_table$label[temp_param_table$var=="Outras áreas não vegetadas"] <- "Other Non Vegetated Area"
temp_param_table$label[temp_param_table$var=="Plantação de Floresta"] <- "Forest Plantation"
temp_param_table$label[temp_param_table$var=="Mineiração"] <- "Mining"
temp_param_table$label[temp_param_table$var=="Cana-de-açúcar"] <- "Sugar Cane"
temp_param_table$label[temp_param_table$var=="Mangue"] <- "Magrove"
temp_param_table$label[temp_param_table$var=="Salar"] <- "Salt flat"
temp_param_table$label[temp_param_table$var=="Praia e Dunas"] <- "Beach and Dune"
temp_param_table$label[temp_param_table$var=="Pântano"] <- "Wetland"
temp_param_table$label[temp_param_table$var=="Mosaico de Agricultura e Pastagem"] <-"Mosaic of Agriculture and Pasture"
temp_param_table$label[temp_param_table$var=="Cultivos temporários"] <- "Temporary Crops"
temp_param_table$label[temp_param_table$var=="Agricultura"] <- " Agriculture"
temp_param_table$label[temp_param_table$var=="Floresta Natural"] <- "Natural Forest"
temp_param_table$label[temp_param_table$var=="Floresta"] <- "Forest"
temp_param_table$label[temp_param_table$var=="Formação Natural sem ser Floresta"] <- "Natural Formation without being Forest"
temp_param_table$label[temp_param_table$var=="Fazenda"] <- "Farm"
temp_param_table$label[temp_param_table$var=="Área não Vegetada"] <- "Non Vegetated Area"
temp_param_table$label[temp_param_table$var=="Água"] <- "Water"
temp_param_table$label[temp_param_table$var=="Formação Antrópica"] <- "Anthropic Formation"
temp_param_table$label[temp_param_table$var=="Formação Natural"] <- "Natural Formation"
temp_param_table$label[temp_param_table$var=="Não Identificado"] <- "Not identified"

View(temp_param_table)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_est_dic_en.csv", fileEncoding = "UTF-8")

