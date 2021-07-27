############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(readxl)

dat <- load_mapbiomas_covering(space_aggregation = "municipality")

saveRDS(dat, file = "data/mapbiomas_cobertura_munic_raw.rds")


# Data for level_4
data1 <- dat
data1$territory_id <- NULL
data1$level_0 <- NULL
data1$level_1 <- NULL
data1$level_2 <- NULL
data1$level_3 <- NULL

data1$group <- paste(data1$municipality, " - ",data1$state)
data1$municipality <- NULL
data1$state <- NULL

colnames(data1) <- c("group", "area", "time", "municipality")



# Data for level_3
data2 <- dat
data2$territory_id <- NULL
data2$level_0 <- NULL
data2$level_1 <- NULL
data2$level_2 <- NULL
data2$level_4 <- NULL

data2$group <- paste(data2$municipality, " - ",data2$state)
data2$municipality <- NULL
data2$state <- NULL

colnames(data2) <- c("group", "area", "time", "municipality")
data2 <- aggregate(area ~ time + group + municipality, data2, sum)



# Data for level_2
data3 <- dat
data3$territory_id <- NULL
data3$level_0 <- NULL
data3$level_1 <- NULL
data3$level_3 <- NULL
data3$level_4 <- NULL

data3$group <- paste(data3$municipality, " - ",data3$state, " - ", data3$level_2)
data3$municipality <- NULL
data3$state <- NULL

colnames(data3) <- c("group", "area", "time", "municipality")
data3 <- aggregate(area ~ time + group + municipality, data3, sum)



# Data for level_1
data4 <- dat
data4$territory_id <- NULL
data4$level_0 <- NULL
data4$level_2 <- NULL
data4$level_3 <- NULL
data4$level_4 <- NULL

data4$group <- paste(data4$municipality, " - ",data4$state, " - ", data4$level_1)
data4$municipality <- NULL
data4$state <- NULL

colnames(data4) <- c("group", "area", "time", "municipality")
data4 <- aggregate(area ~ time + group + municipality, data4, sum)



# Data for level_0
data5 <- dat
data5$territory_id <- NULL
data5$level_1 <- NULL
data5$level_2 <- NULL
data5$level_3 <- NULL
data5$level_4 <- NULL

data5$group <- paste(data5$municipality, " - ",data5$state, " - ", data5$level_0)
data5$municipality <- NULL
data5$state <- NULL

colnames(data5) <- c("group", "area", "time", "municipality")
data5 <- aggregate(area ~ time + group + municipality, data5, sum)



data <- rbind(data1, data2, data3, data4, data5)
datafinal <- reshape(data, idvar = c("municipality", "time"), timevar = "group", direction = "wide")
labl <- colnames(datafinal)
labl <- labl[-c(1,2)]
labl <- substr(labl, 6, 100)
sublabl <- labl[23:27]
sublabl <- substr(sublabl, 5, 100)
labl[23:27] <- sublabl
colnames(datafinal) <- c("time", "group", labl)
datafinal[is.na(datafinal)] <- 0
saveRDS(datafinal, "data/mapbiomas_cobertura_munic.rds")



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

temp_param_table$label[1] <- "Municipio"
temp_param_table$label[2] <- "Ano"
temp_param_table$desc[1] <- "Municipio"
temp_param_table$desc[2] <- "Ano"
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 30))
temp_param_table$color <- c(rep(FALSE, 2), rep(TRUE, 30))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 30))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 30))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_munic_dic.csv", fileEncoding = "UTF-8")