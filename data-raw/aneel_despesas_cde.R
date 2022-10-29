#######################
##Sistemas Isolados
#######################

#Despesas na Conta de Desenvolvimento Estratégico (CDE)
#fonte: Agencia Nacional de Energia Elétrica
#https://portalrelatorios.aneel.gov.br/luznatarifa/contadesenvolvimento

############
#libraries
library(readr)
library(tidyverse)
library(readxl)
############

db_orcamento_cde = read_csv(file = ".\\data-raw\\bases viz energia CPI\\sistemas_isolados_despesas_estimadas_no_orcamento_da_cde.csv", skip = 0) %>%
  select(c("Ano", "Valor"))

# export ------------------------------------------------------------------
saveRDS(data, "data/orcamento_energia.rds")

# dictionary --------------------------------------------------------------

# extract variables from data
columns <- colnames(db_orcamento_cde)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns,
  desc = columns,
  var_group = "Energia - ANEEL",
  tipo = 1,
  unidade = "",
  categoria= "Economia", 
  subcategoria = "Energia"
)

temp_param_table$label <- temp_param_table$var
temp_param_table$label[1] <- "Ano"
temp_param_table$label[2] <- "Valor do orçamento (R$)"


temp_param_table$x <- c(TRUE, FALSE)
temp_param_table$y <- c(FALSE, TRUE)
temp_param_table$color <- c(FALSE, FALSE)
temp_param_table$size <- c(FALSE, FALSE)
temp_param_table$slider <- c(FALSE, FALSE)


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/orcamento_energia_dic.csv", fileEncoding = "UTF-8")


