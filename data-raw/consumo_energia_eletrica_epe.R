#######################
##Sistemas Isolados
#######################

#Consumo Mensal de Energia Elétrica por Classe (regiões e subsistemas)
#fonte: Empresa de Pesquisa Energética
#https://www.epe.gov.br/pt/publicacoes-dados-abertos/publicacoes/consumo-de-energia-eletrica

############
#libraries
library(readr)
library(tidyverse)
library(readxl)
############

#Consumo
############

#Consumo total
db_consumo_total = readxl::read_xls(path = ".//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls")

#Consumo por residencial, industrial, comercial e outros
db_consumo_residencial = readxl::read_xls(path = ".//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = 2)

db_consumo_industrial = readxl::read_xls(path = ".//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = 3)

db_consumo_comercial = readxl::read_xls(path = ".//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = 4)

db_consumo_outros = readxl::read_xls(path = ".//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = 5)


#############

#Consumidores
#############

#Consumidores totais
db_consumidores_totais = readxl::read_xls(path = "C://Users//laura//OneDrive//Laura//economia//pibic//datazoom_viz//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = "CONSUMIDORES TOTAIS")

#Consumidores por classe
db_consumidores_residencial = readxl::read_xls(path = "C://Users//laura//OneDrive//Laura//economia//pibic//datazoom_viz//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = "CONSUMIDORES RESIDENCIAIS")

#############
