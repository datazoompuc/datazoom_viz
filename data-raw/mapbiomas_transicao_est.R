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

data1$group <- paste("From ", data1$from_level_4, " to ",data1$to_level_4)
data1$to_level_4 <- NULL
data1$from_level_4 <- NULL

colnames(data1) <- c("state", "area", "time", "group")



datafinal <- reshape(data1, idvar = c("state", "time"), timevar = "group", direction = "wide")
labl <- colnames(datafinal)
labl <- labl[-c(1,2)]
labl <- substr(labl, 6, 100)
colnames(datafinal) <- c("group", "time", labl)
datafinal[is.na(datafinal)] <- 0
saveRDS(datafinal, "data/mapbiomas_transicao_est.rds")



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
temp_param_table$label[2] <- "Intervalo"
temp_param_table$desc[1] <- "Estado"
temp_param_table$desc[2] <- "Intervalo"
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 231))
temp_param_table$color <- c(rep(FALSE, 2), rep(TRUE, 231))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 231))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 231))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_transicao_est_dic.csv", fileEncoding = "UTF-8")
