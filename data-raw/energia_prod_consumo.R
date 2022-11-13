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
  rename("estado" = "Estado\n", 
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
         "gas natural" = "Gás de coqueria\nCoke Oven Gas",
         "combustivel" = "Óleo combustível\nFuel Oil",
         "diesel" = "Óleo diesel\nDiesel Oil",
         "outras fontes nao renovaveis" = "Out. Fontes não renováveis\nOther Non-Renewable Sources") %>%
  drop_na(total) %>% #tira cabecalhos das tabelas empilhadas
  filter(eolica != "Eólica \nWind") %>% #tira header das tabelas empilhadas
  filter(str_detect(estado, '[:lower:]')) %>% #tira dados a nivel de pais e de macroregiao
  mutate(ano = rep(2021:2011, times = 1, each = 27)) %>% #insere a informacao de ano
  mutate(amz_legal = case_when(estado == "Amapá" ~1,
                               estado == "Acre"~1,
                               estado == "Amazonas" ~1,
                               estado == "Mato Grosso" ~1,
                               estado == "Tocantins" ~1,
                               estado == "Maranhão" ~1,
                               estado == "Rondônia" ~1,
                               estado == "Roraima" ~1,
                               estado == "Pará" ~1,
                              TRUE ~ 0)) %>%
  rename("amz legal" = "amz_legal") %>%
  mutate(tipo = "producao")