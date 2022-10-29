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
    mutate(tipo_consumo = paste0("CONSUMO ", sheet_name)) # adiciona coluna para tipo de consumo
  
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

# bind all
db_consumo <- bind_rows(list(db_consumo_total, db_consumo_residencial, 
                             db_consumo_industrial, db_consumo_comercial, 
                             db_consumo_outros))


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

# export ------------------------------------------------------------------
saveRDS(db_consumo, "data/consumo_energia.rds")


# dictionary --------------------------------------------------------------

# extract variables from data
columns_db_consumo <- colnames(db_consumo)

# generate dictionary
temp_param_table <- tibble(
  var = columns_db_consumo,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns_db_consumo,
  desc = columns_db_consumo,
  var_group = "Energia - EPE",
  tipo = 1,
  unidade = "",
  categoria= "Economia", 
  subcategoria = "Energia"
)

temp_param_table$label <- temp_param_table$var
temp_param_table$label[1] <- "Ano"
temp_param_table$label[2] <- "Consumo (MWh)"
temp_param_table$label[3] <- "Categoria"
  
temp_param_table$x <- c(TRUE, FALSE, FALSE)
temp_param_table$y <- c(FALSE, TRUE, FALSE)
temp_param_table$color <- c(FALSE, FALSE, TRUE)
temp_param_table$size <- c(FALSE, FALSE, TRUE)
temp_param_table$slider <- c(FALSE, FALSE, FALSE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/consumo_energia_dic.csv", fileEncoding = "UTF-8")