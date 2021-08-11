############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(readxl)

dat <- load_sigmine(space_aggregation = "municipality", language = "pt")

saveRDS(dat, file = "data/sigmine_munic_raw.rds")
dat <- readRDS(file = "data/sigmine_munic_raw.rds")


data <- dat
data$id <- NULL
data$processo <- NULL
data$fase <- NULL
data$empresa <- NULL
data$uso <- NULL
data$DSProcesso <- NULL
data$code_muni <- NULL

data$group <- paste(data$municipio, "-",data$estado)
data$municipio <- NULL
data$estado <- NULL

colnames(data) <- c("time", "mineral", "area", "group")

datafinal <- reshape(data, idvar = c("group", "time"), timevar = "mineral", direction = "wide")
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
