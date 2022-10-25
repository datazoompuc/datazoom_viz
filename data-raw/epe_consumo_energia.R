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
colnames(db_consumo_total) = c("Sistema", 1:12, "Total")

db_limpa_consumo_total = db_consumo_total[db_consumo_total$Sistema == "Sistemas Isolados",] %>%  drop_na() %>%
  slice(-1) %>% #remove ano corrente, para o qual dados sao parciais
  mutate(Ano = 2021:2004) %>%
  mutate(Ano = as.numeric(Ano)) %>%
  select(Ano, Total) #tira "Sistema" que e igual a "Sistemas Isolados" em todas as observacoes
  


#Consumo por residencial, industrial, comercial e outros
db_consumo_residencial = readxl::read_xls(path = ".//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = 2)
colnames(db_consumo_residencial) = c("Sistema", 1:12, "Total")

db_limpa_consumo_residencial = db_consumo_residencial[db_consumo_residencial$Sistema == "Sistemas Isolados",] %>%  drop_na() %>%
  slice(-1) %>% #remove ano corrente, para o qual dados sao parciais
  mutate(Ano = 2021:2004) %>%
  mutate(Ano = as.numeric(Ano)) %>%
  select(Ano, Total) #tira "Sistema" que e igual a "Sistemas Isolados" em todas as observacoes


db_consumo_industrial = readxl::read_xls(path = ".//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = 3)
colnames(db_consumo_industrial) = c("Sistema", 1:12, "Total")

db_limpa_consumo_industrial = db_consumo_industrial[db_consumo_industrial$Sistema == "Sistemas Isolados",] %>%  drop_na() %>%
  slice(-1) %>% #remove ano corrente, para o qual dados sao parciais
  mutate(Ano = 2021:2004) %>%
  mutate(Ano = as.numeric(Ano)) %>%
  select(Ano, Total) #tira "Sistema" que e igual a "Sistemas Isolados" em todas as observacoes


db_consumo_comercial = readxl::read_xls(path = ".//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = 4)
colnames(db_consumo_comercial) = c("Sistema", 1:12, "Total")

db_limpa_consumo_comercial = db_consumo_comercial[db_consumo_comercial$Sistema == "Sistemas Isolados",] %>%  drop_na() %>%
  slice(-1) %>% #remove ano corrente, para o qual dados sao parciais
  mutate(Ano = 2021:2004) %>%
  mutate(Ano = as.numeric(Ano)) %>%
  select(Ano, Total) #tira "Sistema" que e igual a "Sistemas Isolados" em todas as observacoes


db_consumo_outros = readxl::read_xls(path = ".//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = 5)
colnames(db_consumo_outros) = c("Sistema", 1:12, "Total")

db_limpa_consumo_outros = db_consumo_outros[db_consumo_outros$Sistema == "Sistemas Isolados",] %>%  drop_na() %>%
  slice(-1) %>% #remove ano corrente, para o qual dados sao parciais
  mutate(Ano = 2021:2004) %>%
  mutate(Ano = as.numeric(Ano)) %>%
  select(Ano, Total) #tira "Sistema" que e igual a "Sistemas Isolados" em todas as observacoes


#############

#Consumidores
#############

#Consumidores totais
db_consumidores_totais = readxl::read_xls(path = ".//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = "CONSUMIDORES TOTAIS", skip = 2)
colnames(db_consumidores_totais) = c("Sistema", 1:12)

db_limpa_consumidores_totais = db_consumidores_totais %>%
  filter(Sistema == "Sistemas Isolados") %>%
  slice(-1) %>% #remove ano corrente, para o qual dados sao parciais
  mutate(Ano = 2021:2004) %>%
  pivot_longer(cols = c(2:13), names_to = "Mes", values_to = "Quantidade") %>%
  mutate(Mes = as.numeric(Mes), Ano = as.numeric(Ano)) %>%
  group_by(Ano) %>%
  arrange(desc(Mes)) %>%
  arrange(desc(Ano)) %>%
  select("Ano", "Mes", "Quantidade") #tira a coluna "Sistema", que tinha apenas valores iguais ("Sistemas Isolados")


#Consumidores por classe
db_consumidores_residencial = readxl::read_xls(path = ".//data-raw//bases viz energia CPI//sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls", sheet = "CONSUMIDORES RESIDENCIAIS")

#############

