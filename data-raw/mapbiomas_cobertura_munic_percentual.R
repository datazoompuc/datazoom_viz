library(readxl)
library(tidyverse)
library(stringr)

dat <- readRDS("data/mapbiomas_cobertura_munic_raw.rds")

url1 <- "https://geoftp.ibge.gov.br/organizacao_do_territorio/estrutura_territorial/areas_territoriais/2020/AR_BR_RG_UF_RGINT_RGIM_MES_MIC_MUN_2020.xls"
p1f <- tempfile()
download.file(url1, p1f, mode="wb")

aux <- read_excel(path = p1f, sheet = 1)

aux <- rbind(subset(aux, CD_GCUF<=21), subset(aux, CD_GCUF==51))
aux$ID <- NULL
aux$CD_GCUF <- NULL
aux$NM_UF <- NULL
aux$NM_UF_SIGLA <- NULL
aux$NM_MUN_2020 <- NULL
saveRDS(aux, "data/auxiliar_areas_municipais.rds")

aux$CD_GCMUN <- as.character(aux$CD_GCMUN)
aux$AR_MUN_2020 <- as.character(aux$AR_MUN_2020)
dat$territory_id <- str_replace_all(dat$territory_id, setNames(aux$AR_MUN_2020, aux$CD_GCMUN))
dat$territory_id <- as.numeric(dat$territory_id) * 100 # From km2 to ha
dat$Area <-dat$Area/dat$territory_id


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

data3$group <- paste(data3$municipality, " - ",data3$state)
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

data4$group <- paste(data4$municipality, " - ",data4$state)
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

data5$group <- paste(data5$municipality, " - ",data5$state)
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
saveRDS(datafinal, "data/mapbiomas_cobertura_munic_percentual.rds")
