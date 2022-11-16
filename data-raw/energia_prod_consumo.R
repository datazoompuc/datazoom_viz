#######################
##Amazônia exporta energia
#######################

#fonte: Empresa de Pesquisa Energética

#producao de energia
#https://www.epe.gov.br/sites-pt/publicacoes-dados-abertos/publicacoes/PublicacoesArquivos/publicacao-145/topico-515/Cap%C3%ADtulo%208%20-%20(Dados%20Estaduais).xls

#consumo de energia
#https://www.epe.gov.br/pt/publicacoes-dados-abertos/publicacoes/anuario-estatistico-de-energia-eletrica

############
#libraries
library(readr)
library(tidyverse)
library(readxl)
library(lubridate)
############

load_producao = readxl::read_excel(".\\bases\\Cap 8 - (Dados Estaduais).xls", sheet = "8.1 part 3", skip = 2)
#atencao ao nome das colunas de load_producao

producao = load_producao %>%
  select(-c("State\n")) %>% #tira o nome dos estados em ingles
  rename("uf" = "Estado\n", 
         "total" = "Geração total\nTotal Generation", 
         "hidro" = "Hidro\nHydro",
         "eolica" = "Eólica \nWind",
         "solar" = "Solar \nSolar",
         "nuclear" = "Nuclear \nNuclear",
         "termo" = "Termo\nThermal",
         "cana" = "Bagaço de cana    \nSugar Cane Bagasse",
         "lenha" = "Lenha\nFirewood",
         "lixivia" = "Lixívia\nBlack Liquor",
         "outras fontes renovaveis" = "Out. Fontes renováveis\nOther Renewable Sources",
         "carvao vapor" = "Carvão vapor\nSteam Coal",
         "gas de coqueira" = "Gás de coqueria\nCoke Oven Gas",
         "gas natural" = "Gás natural\nNatural Gas", 
         "combustivel" = "Óleo combustível\nFuel Oil",
         "diesel" = "Óleo diesel\nDiesel Oil",
         "outras fontes nao renovaveis" = "Out. Fontes não renováveis\nOther Non-Renewable Sources") %>%
  drop_na(total) %>% #tira cabecalhos das tabelas empilhadas
  filter(eolica != "Eólica \nWind") %>% #tira header das tabelas empilhadas
  filter(str_detect(uf, '[:lower:]')) %>% #tira dados a nivel de pais e de macroregiao
  mutate(ano = rep(2021:2011, times = 1, each = 27)) %>% #insere a informacao de ano
  mutate(amz_legal = case_when(uf == "Amapá" ~1,
                               uf == "Acre"~1,
                               uf == "Amazonas" ~1,
                               uf == "Mato Grosso" ~1,
                               uf == "Tocantins" ~1,
                               uf == "Maranhão" ~1,
                               uf == "Rondônia" ~1,
                               uf == "Roraima" ~1,
                               uf == "Pará" ~1,
                              TRUE ~ 0)) %>%
  rename("amz legal" = "amz_legal")


limpa_workbook = function(sheet_number, tipo_dado) {

load_cativo_livre = read_excel(".\\bases\\Energia Elétrica 2022 - Workbook.xlsx", sheet = sheet_number, skip = 8)

parc = load_cativo_livre %>%
  select(-c(12,13,14)) %>%
  rename("uf" = 1) %>%
  filter(uf == "Acre"|uf =="Amazonas"|uf == "Amapá"|uf == "Alagoas"|uf == "Bahia"|uf == "Ceará"|uf == "Distrito Federal"|uf == "Espírito Santo"|uf == "Goiás"|uf == "Maranhão"|uf == "Mato Grosso"| uf == "Mato Grosso do Sul"|uf == "Minas Gerais"|uf == "Paraná"|uf == "Piauí"| uf == "Paraíba"| uf == "Pará"| uf =="Pernambuco"| uf == "Rio de Janeiro"|uf == "Rio Grande do Norte"| uf == "Rio Grande do Sul"| uf == "Roraima"| uf == "Rondônia"|uf == "Santa Catarina"| uf == "São Paulo"| uf == "Sergipe"| uf == "Tocantins") %>%
  pivot_longer(cols = 2:11, names_to = "ano", values_to = "valor") %>%
  mutate(tipo = tipo_dado) %>%
  mutate(ano = as.integer(ano)) %>%
  mutate(amz_legal = case_when(uf == "Amapá" ~1,
                               uf == "Acre"~1,
                               uf == "Amazonas" ~1,
                               uf == "Mato Grosso" ~1,
                               uf == "Tocantins" ~1,
                               uf == "Maranhão" ~1,
                               uf == "Rondônia" ~1,
                               uf == "Roraima" ~1,
                               uf == "Pará" ~1,
                               TRUE ~ 0)) %>%
  rename("amz legal" = "amz_legal") %>%

return(parc)
}

consumo_cativo = limpa_workbook("Tabela 3.13", "consumo cativo")
consumo_livre = limpa_workbook("Tabela 3.14", "consumo livre")
consumo_cativo_livre = rbind(consumo_cativo,consumo_livre) %>%
  pivot_wider(names_from = tipo, values_from = valor) 

consumidores_cativos = limpa_workbook("Tabela 3.42", "consumidores cativos")
consumidores_livres = limpa_workbook("Tabela 3.43", "consumidores livres")
consumidores_cativos_livres = rbind(consumidores_cativos,consumidores_livres) %>%
  pivot_wider(names_from = tipo, values_from = valor) 

consumo_residencial = limpa_workbook("Tabela 3.15", "consumo residencial")
consumo_industrial = limpa_workbook("Tabela 3.16", "consumo industrial")
consumo_comercial = limpa_workbook("Tabela 3.17", "consumo comercial")
consumo_rural = limpa_workbook("Tabela 3.18", "consumo rural")
consumo_pod_pub  = limpa_workbook("Tabela 3.19", "consumo poder publico")
consumo_iluminacao_pub = limpa_workbook("Tabela 3.20", "consumo iluminacao publica")
consumo_serv_pub  = limpa_workbook("Tabela 3.21", "consumo servico publico")
consumo_proprio = limpa_workbook("Tabela 3.22", "consumo proprio")
consumo_classe = rbind(consumo_residencial, consumo_industrial, consumo_comercial, consumo_rural, consumo_pod_pub, consumo_iluminacao_pub, consumo_serv_pub, consumo_proprio) %>%
  pivot_wider(names_from = tipo, values_from = valor)

consumidores_residencial = limpa_workbook("Tabela 3.44", "consumidores residencial")
consumidores_industrial = limpa_workbook("Tabela 3.45", "consumidores industrial")
consumidores_comercial = limpa_workbook("Tabela 3.46", "consumidores comercial")
consumidores_rural = limpa_workbook("Tabela 3.47", "consumidores rural")
consumidores_pod_pub  = limpa_workbook("Tabela 3.48", "consumidores poder publico")
consumidores_iluminacao_pub = limpa_workbook("Tabela 3.49", "consumidores iluminacao publica")
consumidores_serv_pub  = limpa_workbook("Tabela 3.50", "consumidores servico publico")
consumidores_proprio = limpa_workbook("Tabela 3.51", "consumidores proprio")
consumidores_classe = rbind(consumidores_residencial, consumidores_industrial, consumidores_comercial, consumidores_rural, consumidores_pod_pub, consumidores_iluminacao_pub, consumidores_serv_pub, consumidores_proprio) %>%
  pivot_wider(names_from = tipo, values_from = valor)

db_bind1 = left_join(producao,consumo_cativo_livre)
db_bind2 = left_join(db_bind1,consumo_classe)
db_bind3 = left_join(db_bind2,consumidores_cativos_livres)
db_bind4 = left_join(db_bind3,consumidores_classe)
