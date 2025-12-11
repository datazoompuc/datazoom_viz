pkgs <- c("tidyverse","openxlsx","data.table","lubridate","magrittr","stringr")

aux <- rownames(installed.packages())

for (pkg in pkgs) {
  print(pkg)
  
  if (pkg %in% aux) {
    library(pkg, character.only = TRUE)
    print(paste("pacote", pkg, "loaded"))
  } else{
    install.packages(pkg)
    library(pkg, character.only = TRUE)
    print(paste("pacote", pkg, "installed and loaded"))
  }
}

# Raw data from https://balanca.economia.gov.br/balanca/IPQ/totais_mes.html#:~:text=%C3%8Dndices%20de%20Pre%C3%A7os%20e%20Quantum%20%2D%20Total%20Mensal
# downloaded from "Baixar: Dados brutos (.csv)" button
# Those contain price index for exports. Note, however, that it starts from 1998, so we are not able to fix
# the base 100 in 1997.
indice_precos_quantum <- read_csv2("data/Dados_totais_mensal.csv",col_names = TRUE,col_types = cols(
  TIPO = col_character(),
  TIPO_INDICE = col_character(),
  CO_ANO = col_number(),
  CO_MES = col_number(),
  NO_CLASSIFICACAO = col_character(),
  INDICE = col_double()))
indice_precos <- indice_precos_quantum %>%
  filter(TIPO=="EXP"&TIPO_INDICE=="PRECO")
indice_precos$NO_CLASSIFICACAO <- NULL
indice_precos$TIPO <- NULL
indice_precos$TIPO_INDICE <- NULL

indice_precos$date <- as.Date(paste(indice_precos$CO_ANO, indice_precos$CO_MES, "01", sep = "-"))

# Proceeded as in the original source: took the annual average to determine annual value of the index
# and rescaled index to have base 100 in 1998
indice_precos_anual <- aggregate(INDICE ~ CO_ANO, indice_precos, mean)
indice_ref <- indice_precos_anual$INDICE[1]
indice_precos_anual$indice_anual_base1998 <- indice_precos_anual$INDICE/indice_ref*100

write.csv(
  indice_precos_anual, 
  file.path(
    "data/indice_precos_anual.csv"
  ), 
  row.names = TRUE
)

