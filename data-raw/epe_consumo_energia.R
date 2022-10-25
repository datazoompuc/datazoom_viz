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


# funcao para limpar dados de consumo -----------------------------------------------
limpa_consumo <- function(sheet_name) {
   
  # le dados de consumo
  raw_df <- readxl::read_xls(path = "data-raw/bases viz energia CPI/sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls",
                             sheet = sheet_name)
  
  # troca nome das colunas
  colnames(raw_df) <- c("Sistema", 1:12, "Total")
  
  # limpa
  clean_df <- raw_df %>%
    filter(Sistema == "Sistemas Isolados") %>%  
    drop_na() %>%
    slice(-1) %>% # remove ano corrente, para o qual dados sao parciais
    mutate(Ano = 2021:2004) %>%
    mutate(Ano = as.numeric(Ano)) %>%
    select(Ano, Total) %>%
    mutate(tipo_consumo = sheet_name) # adiciona coluna para tipo de consumo
  
  return(clean_df)
  
}


# roda funcao -----------------------------------------------------------------------
# Consumo total
db_consumo_total <- limpa_consumo("TOTAL")

# Consumo por residencial, industrial, comercial e outros
db_consumo_residencial <- limpa_consumo("RESIDENCIAL")
db_consumo_industrial <- limpa_consumo("INDUSTRIAL")
db_consumo_comercial <- limpa_consumo("COMERCIAL")
db_consumo_outros <- limpa_consumo("OUTROS")


# dados de consumidores -------------------------------------------------------------
# Consumidores totais
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

