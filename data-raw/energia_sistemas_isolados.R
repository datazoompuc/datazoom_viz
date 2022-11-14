#######################
##Sistemas Isolados

############
#libraries
library(readr)
library(tidyverse)
library(readxl)
library(deflateBR)
############

#######################

#Consumo Mensal de Energia Elétrica por Classe (regiões e subsistemas)
#fonte: Empresa de Pesquisa Energética
#https://www.epe.gov.br/pt/publicacoes-dados-abertos/publicacoes/consumo-de-energia-eletrica

# dados de consumo -------------------------------------------------------------
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
    mutate(Ano = 2021:2004) %>%  mutate(Ano = as.numeric(Ano)) %>%
    select(Ano, Total) %>%
    mutate(tipo = paste0("CONSUMO ", sheet_name)) %>% # adiciona coluna para tipo de consumo
    rename("valor" = "Total") %>%
    mutate(valor = as.numeric(valor) / 1e6)
  
  return(clean_df)
  
}


# roda funcao -----------------------------------------------------------------------
# consumo total
db_consumo_total <- limpa_consumo("TOTAL")

# consumo por residencial, industrial, comercial e outros
db_consumo_residencial <- limpa_consumo("RESIDENCIAL")
db_consumo_industrial <- limpa_consumo("INDUSTRIAL")
db_consumo_comercial <- limpa_consumo("COMERCIAL")
db_consumo_outros <- limpa_consumo("OUTROS")

# bind all
db_consumo <- bind_rows(list(db_consumo_total, db_consumo_residencial, 
                             db_consumo_industrial, db_consumo_comercial, 
                             db_consumo_outros))

# dados de consumidores -------------------------------------------------------------
# funcao para limpar dados de consumo -----------------------------------------------
limpa_consumidores <- function(sheet_name) {
  
  # le dados de consumidores
  raw_df <- readxl::read_xls(path = "data-raw/bases viz energia CPI/sistemas_isolados_consumo_mensal_de_energia_eletrica_por_classe.xls",
                             sheet = sheet_name)
  
  # troca nome das colunas
  colnames(raw_df) <- c("Sistema", 1:12)
  
  # limpa
  clean_df <- raw_df %>%
    filter(Sistema == "Sistemas Isolados") %>%
    slice(-1) %>% #remove ano corrente, para o qual dados sao parciais
    mutate(Ano = 2021:2004)  %>%
    pivot_longer(cols = c(2:13), names_to = "Mes", values_to = "Quantidade") %>%
    select(Ano, Quantidade) %>% #tira a coluna "Sistema", que tinha apenas valores iguais ("Sistemas Isolados") e "Mes"
    mutate(Ano = as.numeric(Ano), Quantidade = as.numeric(Quantidade)) %>%
    group_by(Ano) %>%
    dplyr::summarise(valor = mean(Quantidade) / 1e6) %>%
    mutate(tipo = sheet_name) # adiciona coluna para tipo de consumidor
  
  return(clean_df)
  
}

# roda funcao -----------------------------------------------------------------------
# consumidores total
db_consumidores_total <- limpa_consumidores("CONSUMIDORES TOTAIS")

# consumidores por residencial, industrial, comercial e outros
db_consumidores_residencial <- limpa_consumidores("CONSUMIDORES RESIDENCIAIS")

# bind all
db_consumidores <- bind_rows(list(db_consumidores_total, db_consumidores_residencial))


#######################

#Despesas na Conta de Desenvolvimento Estratégico (CDE)
#fonte: Agencia Nacional de Energia Elétrica
#https://portalrelatorios.aneel.gov.br/luznatarifa/contadesenvolvimento

db_orcamento_cde <- read_csv(file = "data-raw/bases viz energia CPI/sistemas_isolados_despesas_estimadas_no_orcamento_da_cde.csv", skip = 0) %>%
  select(c("Ano", "Valor")) %>%
  rename("valor" = "Valor") %>%
  filter(Ano != 2022) %>%
  mutate(valor = valor / 1e9,
         tipo = "DESPESAS ESTIMADAS CCC (Nominal)",
         nominal_dates = as.Date(paste0(Ano, "-01-01")),
         `DESPESAS ESTIMADAS CCC (Real, R$ 2021)` = ipca(valor, nominal_dates, "01/2021")) %>%
  select(Ano, `DESPESAS ESTIMADAS CCC (Nominal)` = valor, 
         `DESPESAS ESTIMADAS CCC (Real, R$ 2021)`)

db_orcamento_cde_particip <- read_csv(file = "data-raw/bases viz energia CPI/sistemas_isolados_despesas_estimadas_no_orcamento_da_cde_particip.csv", skip = 0) %>%
  select(c("Ano", participacao = "Participação")) %>%
  filter(Ano != 2022) %>%
  mutate(participacao = str_remove_all(participacao, "[%]"),
         participacao = str_replace_all(participacao, "[,]", "."),
         participacao = as.numeric(participacao))
  
  
#tudo junto ---------------------------------------------------------------
db_completa = full_join(db_consumo, db_consumidores)
db_sistemas_isolados_p1 = full_join(db_completa, db_orcamento_cde)
db_sistemas_isolados_p2 = full_join(db_sistemas_isolados_p1, db_orcamento_cde_particip)


# pivot table -----------------------------------------------------------------------
db_sistemas_isolados <- db_sistemas_isolados_p2 %>%
  pivot_wider(names_from = tipo, values_from = valor)

colnames(db_sistemas_isolados) <- str_to_title(colnames(db_sistemas_isolados))

db_sistemas_isolados <- db_sistemas_isolados %>%
  rename(`Despesas Estimadas CCC (Nominal)` = `Despesas Estimadas Ccc (Nominal)`,
         `Despesas Estimadas CCC (Real, R$ 2021)` = `Despesas Estimadas Ccc (Real, R$ 2021)`,
         `Participação da CCC no Orçamento Total da CDE` = Participacao)


# export ------------------------------------------------------------------
saveRDS(db_sistemas_isolados, "data/energia_sistemas_isolados.rds")


# dictionary --------------------------------------------------------------

# extract variables from data
columns_db_sistemas_isolados <- colnames(db_sistemas_isolados)

# generate dictionary
temp_param_table <- tibble(
  var = columns_db_sistemas_isolados,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns_db_sistemas_isolados,
  desc = columns_db_sistemas_isolados,
  var_group = "Energia - EPE", #ATENCAO colunas de despesas tem fonte ANEEL
  tipo = 1,
  unidade = "",
  categoria= "Economia", 
  subcategoria = "Energia"
)

temp_param_table$label <- temp_param_table$var

temp_param_table$var_group[2:4] <- "Orçamento CCC - ANEEL"
temp_param_table$var_group[5:9] <- "Consumo de Eletricidade - EPE"
temp_param_table$var_group[10:11] <- "Média de Consumidores - EPE"

temp_param_table$unidade[2:3] <- "Bilhões de R$"
temp_param_table$unidade[4] <- "% do Orçamento da Conta de Desenvolvimento Energético"
temp_param_table$unidade[5:9] <- "Milhões de MWh"
temp_param_table$unidade[10:11] <- "Milhões de Consumidores"


temp_param_table$x <- c(TRUE, rep(FALSE, 10))
temp_param_table$y <- c(FALSE, rep(TRUE, 10))


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/energia_sistemas_isolados_dic.csv", fileEncoding = "UTF-8")
