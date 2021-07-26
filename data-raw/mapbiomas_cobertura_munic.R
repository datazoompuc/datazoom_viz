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
data1$level_4 <- NULL

colnames(data1) <- c("area", "year", "group")

################################################################################################################



# Data for level_3
data2 <- dat
data2$territory_id <- NULL
data2$level_0 <- NULL
data2$level_1 <- NULL
data2$level_2 <- NULL
data2$level_4 <- NULL

data2$group <- paste(data2$municipality, " - ",data2$state, " - ", data2$level_3)
data2$municipality <- NULL
data2$state <- NULL
data2$level_3 <- NULL

colnames(data2) <- c("area", "year", "group")
data2 <- aggregate(area ~ year + group, data2, sum)

################################################################################################################



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
data3$level_2 <- NULL

colnames(data3) <- c("area", "year", "group")
data3 <- aggregate(area ~ year + group, data3, sum)

################################################################################################################



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
data4$level_1 <- NULL

colnames(data4) <- c("area", "year", "group")
data4 <- aggregate(area ~ year + group, data4, sum)

################################################################################################################



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
data5$level_0 <- NULL

colnames(data5) <- c("area", "year", "group")
data5 <- aggregate(area ~ year + group, data5, sum)

################################################################################################################



data <- rbind(data1, data2, data3, data4, data5)
saveRDS(data, "data/cobertura_munic.rds")
