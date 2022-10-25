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
