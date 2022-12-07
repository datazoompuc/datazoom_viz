#######################
##Amazônia exporta energia
#######################

#fonte: Empresa de Pesquisa Energética

#producao de energia
#https://www.epe.gov.br/sites-pt/publicacoes-dados-abertos/publicacoes/PublicacoesArquivos/publicacao-145/topico-515/Cap%C3%ADtulo%208%20-%20(Dados%20Estaduais).xls

#consumo de energia
#https://www.epe.gov.br/sites-pt/publicacoes-dados-abertos/publicacoes/PublicacoesArquivos/publicacao-160/topico-168/Anu%C3%A1rio%20Estat%C3%ADstico%20de%20Energia%20El%C3%A9trica%202022%20-%20Workbook.xlsx

############
#libraries
library(readr)
library(tidyverse)
library(readxl)
library(lubridate)
############

load_producao = readxl::read_excel(".\\data-raw\\bases\\Cap 8 - (Dados Estaduais).xls", sheet = "8.1 part 3", skip = 2)
#atencao ao nome das colunas de load_producao

producao = load_producao %>%
  select(-c("State\n")) %>% #tira o nome dos estados em ingles
  rename("uf" = "Estado\n", 
         "total produzido" = "Geração total\nTotal Generation", 
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
  drop_na(`total produzido`) %>% #tira cabecalhos das tabelas empilhadas
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
  rename("amz legal" = "amz_legal") %>%
  mutate(uf = replace(uf, uf == "Mato G. do Sul", "Mato Grosso do Sul")) %>%
  mutate(uf = replace(uf, uf == "Rio G. do Sul", "Rio Grande do Sul")) %>%
  mutate(uf = replace(uf, uf == "Rio G. do Norte", "Rio Grande do Norte"))  %>%
  mutate(across(!uf, ~as.numeric(.x)))

limpa_workbook = function(sheet_number, tipo_dado) {

load_cativo_livre = read_excel(".\\data-raw\\bases\\Energia Elétrica 2022 - Workbook.xlsx", sheet = sheet_number, skip = 8)

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
  rename("amz legal" = "amz_legal")
 
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

#tudo junto ---------------------------------------------------------------
db_bind1 = left_join(producao,consumo_cativo_livre)
db_bind2 = left_join(db_bind1,consumo_classe)
db_bind3 = left_join(db_bind2,consumidores_cativos_livres)
db_bind4 = left_join(db_bind3,consumidores_classe) %>%
  rename("amz_legal" = "amz legal") %>%
  mutate(across(!uf & !amz_legal, as.numeric))
  
  
db_bind5 <- db_bind4 %>%  
  group_by(ano) %>%
  mutate(across(!uf & !amz_legal, ~(.x / sum(.x, na.rm = TRUE)) * 100)) %>%
  ungroup()

amz_legal_df = db_bind4 %>%
  filter(amz_legal == 1) %>%
  group_by(ano) %>%
  summarise(across(!uf & !amz_legal, ~sum(.x, na.rm = TRUE))) %>%
  mutate("uf" = "Amazônia Legal")

fora_amz_legal_df = db_bind4 %>%
  filter(amz_legal == 0) %>%
  group_by(ano) %>%
  summarise(across(!uf & !amz_legal, ~sum(.x, na.rm = TRUE))) %>%
  mutate("uf" = "Fora da Amazônia Legal")

df_final <- rbind(amz_legal_df, fora_amz_legal_df) %>%
  group_by(ano) %>%
  mutate(across(!uf, ~(.x / sum(.x, na.rm = TRUE)) * 100)) %>%
  ungroup() %>%
  rbind(db_bind5 %>% select(-amz_legal)) %>%
  mutate(across(!uf, ~ifelse(.x < 0, 0, .x)))

#atribui NA aos dados de consumo e consumidores em 2011
#esses dados nao estao disponiveis na fonte
df_final <- df_final %>% 
  mutate_all(function(x) ifelse(is.nan(x), NA, x))

#modifica `uf` para evitar problemas com acentos e dar match no UI 
df_final = df_final %>%
  mutate(uf = case_when(uf == "Amapá" ~ "AP",
                   uf == "Acre"~ "AC",
                   uf == "Amazonas" ~ "AM",
                   uf == "Mato Grosso" ~ "MT",
                   uf == "Tocantins" ~ "TO",
                   uf == "Maranhão" ~ "MA",
                   uf == "Rondônia" ~ "RO",
                   uf == "Roraima" ~ "RR",
                   uf == "Pará" ~ "PA",
                   uf == "Alagoas" ~ "AL",
                   uf == "Bahia" ~ "BA",
                   uf == "Ceará" ~ "CE",
                   uf == "Distrito Federal" ~ "DF",
                   uf == "Espírito Santo" ~ "ES",
                   uf == "Goiás" ~ "GO",
                   uf == "Mato Grosso do Sul" ~ "MS",
                   uf == "Minas Gerais" ~ "MG",
                   uf == "Paraíba" ~ "PB",
                   uf == "Paraná" ~ "PR",
                   uf == "Pernambuco" ~ "PE",
                   uf == "Rio de Janeiro" ~"RJ",
                   uf == "Rio Grande do Sul" ~"RS",
                   uf == "Santa Catarina" ~ "SC",
                   uf == "São Paulo" ~ "SP",
                   uf == "Sergipe" ~ "SE",
                   uf == "Piauí" ~ "PI",
                   uf == "Rio Grande do Norte" ~ "RN",
                   TRUE ~ as.character(uf)))


# export ------------------------------------------------------------------
saveRDS(df_final, "data/energia_amz_exporta.rds")

# dictionary --------------------------------------------------------------

# extract variables from data
columns_db_amz_exporta <- colnames(df_final)

# generate dictionary
temp_param_table <- tibble(
  var = columns_db_amz_exporta,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns_db_amz_exporta,
  desc = columns_db_amz_exporta,
  var_group = "Energia - EPE",
  tipo = 1,
  unidade = "",
  categoria= "Economia", 
  subcategoria = "Energia"
)


#o que e cada var
temp_param_table$label <- temp_param_table$var
temp_param_table$label[1] <- "Ano"
temp_param_table$label[2] <- "Total de energia produzida"
temp_param_table$label[3] <- "Energia produzida por hidro"
temp_param_table$label[4] <- "Energia produzida por eólica"
temp_param_table$label[5] <- "Energia produzida por solar"
temp_param_table$label[6] <- "Energia produzida por nuclear"
temp_param_table$label[7] <- "Energia produzida por termo"
temp_param_table$label[8] <- "Energia produzida por cana"
temp_param_table$label[9] <- "Energia produzida por lenha"
temp_param_table$label[10] <- "Energia produzida por lixívia"
temp_param_table$label[11] <- "Energia produzida por outras fontes renováveis"
temp_param_table$label[12] <- "Energia produzida por carvão vapor"
temp_param_table$label[13] <- "Energia produzida por gás natural"
temp_param_table$label[14] <- "Energia produzida por gás de coqueira"
temp_param_table$label[15] <- "Energia produzida por combustível"
temp_param_table$label[16] <- "Energia produzida por diesel"
temp_param_table$label[17] <- "Energia produzida outras fontes não renováveis"
temp_param_table$label[18] <- "Consumo cativo"
temp_param_table$label[19] <- "Consumo livre"
temp_param_table$label[20] <- "Consumo residencial"
temp_param_table$label[21] <- "Consumo industrial"
temp_param_table$label[22] <- "Consumo comercial"
temp_param_table$label[23] <- "Consumo rural"
temp_param_table$label[24] <- "Consumo do poder público"
temp_param_table$label[25] <- "Consumo de iluminação pública"
temp_param_table$label[26] <- "Consumo do serviço público"
temp_param_table$label[27] <- "Consumo próprio"
temp_param_table$label[28] <- "Consumidores cativos"
temp_param_table$label[29] <- "Consumidores livres"
temp_param_table$label[30] <- "Consumidores residenciais"
temp_param_table$label[31] <- "Consumidores industriais"
temp_param_table$label[32] <- "Consumidores comerciais"
temp_param_table$label[33] <- "Consumidores rurais"
temp_param_table$label[34] <- "Consumidores do poder público"
temp_param_table$label[35] <- "Consumidores de iluminação pública"
temp_param_table$label[36] <- "Consumidores do serviço público"
temp_param_table$label[37] <- "Consumidores próprios"
temp_param_table$label[38] <- "UF"

#unidades de cada var
temp_param_table$unidade[2:28] <- "% do total (Brasil)"
temp_param_table$unidade[29:38] <- "% do total (Brasil)"

#o que cada var pode assumir
temp_param_table$x <- c(TRUE, rep(FALSE, times = 37))
temp_param_table$y <- c(FALSE, rep(TRUE, times = 36), FALSE)
temp_param_table$color <- c(rep(FALSE, times = 37), TRUE)
temp_param_table$size <- c(rep(FALSE, times = 38))
temp_param_table$slider <- c(TRUE, rep(FALSE, times = 37))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/energia_amz_exporta_dic.csv", fileEncoding = "UTF-8")
