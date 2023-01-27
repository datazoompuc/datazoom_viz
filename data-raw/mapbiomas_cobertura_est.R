############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(readxl)

dat<- datazoom.amazonia::load_mapbiomas(dataset = "mapbiomas_cover", raw_data = FALSE, geo_level = "state", language = "eng", cover_level = 4)
#dat <- load_mapbiomas_covering(space_aggregation = "state")
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
translated_labl <- c("Pastagem", "Forma\u00e7\u00e3o de Floresta", "Pradaria", "N\u00e3o Observado",
                     "Outras \u00c1reas n\u00e3o Vegetadas", "Infraestrutura Urbana", "Rios, Lagos ou Oceanos",
                     "Mosaico de Cultivos", "Soja", "Planta\u00e7\u00e3o de Floresta", "Mangue", "Mineira\u00e7\u00e3o",
                     "Cana-de-a\u00e7\u00facar", "Forma\u00e7\u00e3o de Savana", "Salar", "Praia e Dunas",
                     "Mosaico de Agricultura e Pastagem", "P\u00e2ntano", "Cultivos tempor\u00e1rios",
                     "Agricultura", "Floresta Natural", "Floresta", "Forma\u00e7\u00e3o Natural sem ser Floresta",
                     "Fazenda", "\u00c1rea n\u00e3o Vegetada", "\u00c1gua", "Forma\u00e7\u00e3o Antrópica", "Forma\u00e7\u00e3o Natural",
                     "N\u00e3o Identificado")
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

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_est_dic_en.csv", fileEncoding = "UTF-8")

