############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(readxl)

devtools::install_github("https://github.com/datazoompuc/datazoom.amazonia/tree/update_mapbiomas")

dat <- load_mapbiomas(dataset= "mapbiomas_cover", geo_level   = "municipality", cover_level = "none")

saveRDS(dat, file = "data/mapbiomas_cobertura_munic_raw.rds")


# Data for level_4
data1 <- dat
data1$territory_id <- NULL
data1$level_0 <- NULL
data1$level_1 <- NULL
data1$level_2 <- NULL
data1$level_3 <- NULL
data1$color <- NULL
data1$feature_id <- NULL
data1$index <- NULL
data1$class_id <- NULL
data1$municipality_code <- NULL
data1$group <- paste(data1$municipality, " - ",data1$state)
data1$municipality <- NULL
data1$state <- NULL

colnames(data1) <- c("time", "aggregation", "area","group")

#tentando resolver problema do aggregate
data1$area <- as.numeric(data1$area)

data1 <- aggregate(area ~ time + group + aggregation, data1, sum)


# Data for level_3
data2 <- dat
data2$territory_id <- NULL
data2$level_0 <- NULL
data2$level_1 <- NULL
data2$level_2 <- NULL
data2$level_4 <- NULL

data2$color <- NULL
data2$feature_id <- NULL
data2$index <- NULL
data2$class_id <- NULL
data2$municipality_code <- NULL
data2$group <- paste(data2$municipality, " - ",data2$state)
data2$municipality <- NULL
data2$state <- NULL

colnames(data2) <- c("time", "aggregation", "area","group")

#tentando resolver problema do aggregate
data2$area <- as.numeric(data2$area)

data2 <- aggregate(area ~ time + group + aggregation, data2, sum)

# Data for level_2
data3 <- dat
data3$territory_id <- NULL
data3$level_0 <- NULL
data3$level_1 <- NULL
data3$level_3 <- NULL
data3$level_4 <- NULL

data3$color <- NULL
data3$feature_id <- NULL
data3$index <- NULL
data3$class_id <- NULL
data3$municipality_code <- NULL
data3$group <- paste(data3$municipality, " - ",data3$state)
data3$municipality <- NULL
data3$state <- NULL

colnames(data3) <- c("time", "aggregation", "area","group")

#tentando resolver problema do aggregate
data3$area <- as.numeric(data3$area)

data3 <- aggregate(area ~ time + group + aggregation, data3, sum)


# Data for level_1
data4 <- dat
data4$territory_id <- NULL
data4$level_0 <- NULL
data4$level_2 <- NULL
data4$level_3 <- NULL
data4$level_4 <- NULL

data4$color <- NULL
data4$feature_id <- NULL
data4$index <- NULL
data4$class_id <- NULL
data4$municipality_code <- NULL
data4$group <- paste(data4$municipality, " - ",data4$state)
data4$municipality <- NULL
data4$state <- NULL

colnames(data4) <- c("time", "aggregation", "area","group")

#tentando resolver problema do aggregate
data4$area <- as.numeric(data4$area)

data4 <- aggregate(area ~ time + group + aggregation, data4, sum)



# Data for level_0
data5 <- dat
data5$territory_id <- NULL
data5$level_1 <- NULL
data5$level_2 <- NULL
data5$level_3 <- NULL
data5$level_4 <- NULL

data5$color <- NULL
data5$feature_id <- NULL
data5$index <- NULL
data5$class_id <- NULL
data5$municipality_code <- NULL
data5$group <- paste(data5$municipality, " - ",data5$state)
data5$municipality <- NULL
data5$state <- NULL

colnames(data5) <- c("time", "aggregation", "area","group")

#tentando resolver problema do aggregate
data5$area <- as.numeric(data5$area)

data5 <- aggregate(area ~ time + group + aggregation, data5, sum)


data <- rbind(data1, data2, data3, data4, data5)

#problema parou aqui
#sinto que muita coisa foi deletada aqui
#num de colunas = quantidade de municipio
# num de linhas= anos*agregação, ou seja, moda a area de cada agregação para cada ano
# acho que os warnings ocorrem pq deve aparecer a mesma agregação em mais de uma dataX

datafinal <- reshape(data, idvar = c("aggregation", "time"), timevar = "group", direction = "wide")
labl <- colnames(datafinal)
labl <- labl[-c(1,2)]
labl <- substr(labl, 6, 100)
sublabl <- labl[23:27]
sublabl <- substr(sublabl, 5, 100)
labl[23:27] <- sublabl

#a ordem está certa mesmo?
translated_labl <- c("Mosaico de Cultivos", "Soja", "Pastagem", "Infraestrutura Urbana", "Formação de Floresta",
                     "Pradaria", "Rios, Lagos ou Oceanos", "Não Observado", "Formação de Savana",
                     "Outras áreas não vegetadas", "Plantação de Floresta", "Mineiração", "Cana-de-açúcar",
                     "Mangue", "Salar", "Praia e Dunas", "Pântano", "Cultivos perenes",
                     "Mosaico de Agricultura e Pastagem", "Cultivos temporários", "Agricultura",
                     "Floresta Natural", "Floresta", "Formação Natural sem ser Floresta",
                     "Fazenda", "Área não Vegetada", "Água", "Formação Antrópica", "Formação Natural",
                     "Não Identificado")
colnames(datafinal) <- c("time", "group", translated_labl)
datafinal[is.na(datafinal)] <- 0
saveRDS(datafinal, "data/mapbiomas_cobertura_munic.rds")

datafinal <- readRDS("data/mapbiomas_cobertura_munic.rds")

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

# tentando resolver a questão de terem várias linhas NA 
temp_param_table <-temp_param_table %>%
     drop_na()

temp_param_table$label[1] <- "Ano"
temp_param_table$label[2] <- "Município"
temp_param_table$desc[1] <- "Ano"
temp_param_table$desc[2] <- "Município"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 30))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 30))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, 30))
temp_param_table$size <- c(FALSE, TRUE, rep(FALSE, 30))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 30))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_munic_dic.csv", fileEncoding = "UTF-8")


##############################
# Build Dictionary in English
##############################

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

temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Municipality"
temp_param_table$desc[1] <- "Year"
temp_param_table$desc[2] <- "Municipality"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 30))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 30))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, 30))
temp_param_table$size <- c(FALSE, TRUE, rep(FALSE, 30))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 30))
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
temp_param_table$label[temp_param_table$var=="Cultivos perenes"] <- "Perennial Crops"
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

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_munic_dic_en.csv", fileEncoding = "UTF-8")

