############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)

dat <- load_br_trade(dataset="comex_export_mun", language = "pt", time_period = 1997:2021, raw_data = FALSE)

saveRDS(dat, file = "data/comex_munic_raw.rds")

dat$mes <- NULL
dat$cod_sh4 <- NULL

dat <- filter(dat, uf %in% c("RO", "AM", "PA", "RR", "MT", "MA", "AC", "AP", "TO"))
data <- aggregate(kg_liquido + valor_fob ~ ano + cod_pais + uf + cod_municipio + nome_sh4, dat, sum)



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
