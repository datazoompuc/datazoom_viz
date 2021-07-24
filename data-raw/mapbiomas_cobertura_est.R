dat <- load_mapbiomas_covering(space_aggregation = "state")
colnames(dat)[colnames(dat) == "Leval_zero"] <- "level_0"


# Data for level_4
data1 <- dat
data1$level_0 <- NULL
data1$level_1 <- NULL
data1$level_2 <- NULL
data1$level_3 <- NULL

data1$group <- paste(data1$biome, " - ",data1$state, " - ", data1$level_4)
data1$biome <- NULL
data1$state <- NULL
data1$level_4 <- NULL

colnames(data1) <- c("area", "year", "group")

################################################################################################################



# Data for level_3
data2 <- dat
data2$level_0 <- NULL
data2$level_1 <- NULL
data2$level_2 <- NULL
data2$level_4 <- NULL

data2$group <- paste(data2$biome, " - ",data2$state, " - ", data2$level_3)
data2$biome <- NULL
data2$state <- NULL
data2$level_3 <- NULL

colnames(data2) <- c("area", "year", "group")
data2 <- aggregate(area ~ year + group, data2, sum)

################################################################################################################



# Data for level_2
data3 <- dat
data3$level_0 <- NULL
data3$level_1 <- NULL
data3$level_3 <- NULL
data3$level_4 <- NULL

data3$group <- paste(data3$biome, " - ",data3$state, " - ", data3$level_2)
data3$biome <- NULL
data3$state <- NULL
data3$level_2 <- NULL

colnames(data3) <- c("area", "year", "group")
data3 <- aggregate(area ~ year + group, data3, sum)

################################################################################################################



# Data for level_1
data4 <- dat
data4$level_0 <- NULL
data4$level_2 <- NULL
data4$level_3 <- NULL
data4$level_4 <- NULL

data4$group <- paste(data4$biome, " - ",data4$state, " - ", data4$level_1)
data4$biome <- NULL
data4$state <- NULL
data4$level_1 <- NULL

colnames(data4) <- c("area", "year", "group")
data4 <- aggregate(area ~ year + group, data4, sum)

################################################################################################################



# Data for level_0
data5 <- dat
data5$level_1 <- NULL
data5$level_2 <- NULL
data5$level_3 <- NULL
data5$level_4 <- NULL

data5$group <- paste(data5$biome, " - ",data5$state, " - ", data5$level_0)
data5$biome <- NULL
data5$state <- NULL
data5$level_0 <- NULL

colnames(data5) <- c("area", "year", "group")
data5 <- aggregate(area ~ year + group, data5, sum)

################################################################################################################



data <- rbind(data1, data2, data3, data4, data5)
saveRDS(data, "data/cobertura_est.rds")