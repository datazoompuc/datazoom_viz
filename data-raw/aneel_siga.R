#######################
##Geração Distribuída
#######################

#SIGA - Sistema de Informações de Geração da Aneel
#fonte: Agencia Nacional de Energia Elétrica
#https://app.powerbi.com/view?r=eyJrIjoiNjc4OGYyYjQtYWM2ZC00YjllLWJlYmEtYzdkNTQ1MTc1NjM2IiwidCI6IjQwZDZmOWI4LWVjYTctNDZhMi05MmQ0LWVhNGU5YzAxNzBlMSIsImMiOjR9

############
#libraries
library(readr)
library(tidyverse)
library(readxl)
library(lubridate)
############

db_siga = readxl::read_xlsx(path = ".\\data-raw\\bases viz energia CPI\\geracao_distribuida_BD_SIGA.xlsx", skip = 1, col_names = TRUE)