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

producao = load_producao %>%
  select(-c("State\n")) %>%
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
  filter(estado == c("Acre","Alagoas","Amapá","Amazonas","Bahia","Ceará","Distrito Federal","Espírito Santo","Distrito Federal","Goiás","Maranhão","Mato Grosso","Mato G. do Sul","Minas Gerais","Pará","Paraíba","Paraná","Pernambuco","Piauí","Rio de Janeiro", "Rio G. do Norte", "Rio G. do Sul", "Rondônia", "Roraima", "Santa Catarina", "São Paulo", "Sergipe", "Tocantins"))