#######################
## Amazônia exporta energia
#######################

# fonte: Empresa de Pesquisa Energética (EPE)
#
# producao de energia: BEN - Séries Históricas, Capítulo 8 (Dados Estaduais)
#   https://www.epe.gov.br/pt/publicacoes-dados-abertos/publicacoes/BEN-Series-Historicas-Completas
#
# consumo de energia: Anuário Estatístico de Energia Elétrica - Workbook
#   https://www.epe.gov.br/pt/publicacoes-dados-abertos/publicacoes/anuario-estatistico-de-energia-eletrica
#
# Ambas as URLs não têm ano no nome — EPE atualiza os arquivos no mesmo
# endereço a cada nova edição, bastando rodar o script para obter dados atualizados.

############
# libraries
############
library(readr)
library(tidyverse)
library(readxl)
library(lubridate)
library(stringi)

############
# constantes
############
amz_legal_estados <- c("Amapá", "Acre", "Amazonas", "Mato Grosso",
                        "Tocantins", "Maranhão", "Rondônia", "Roraima", "Pará")

estados_brasileiros <- c(
  "Acre", "Alagoas", "Amapá", "Amazonas", "Bahia", "Ceará",
  "Distrito Federal", "Espírito Santo", "Goiás", "Maranhão",
  "Mato Grosso", "Mato Grosso do Sul", "Minas Gerais", "Paraná",
  "Piauí", "Paraíba", "Pará", "Pernambuco", "Rio de Janeiro",
  "Rio Grande do Norte", "Rio Grande do Sul", "Roraima", "Rondônia",
  "Santa Catarina", "São Paulo", "Sergipe", "Tocantins"
)

uf_map <- c(
  "Amapá" = "AP", "Acre" = "AC", "Amazonas" = "AM", "Mato Grosso" = "MT",
  "Tocantins" = "TO", "Maranhão" = "MA", "Rondônia" = "RO", "Roraima" = "RR",
  "Pará" = "PA", "Alagoas" = "AL", "Bahia" = "BA", "Ceará" = "CE",
  "Distrito Federal" = "DF", "Espírito Santo" = "ES", "Goiás" = "GO",
  "Mato Grosso do Sul" = "MS", "Minas Gerais" = "MG", "Paraíba" = "PB",
  "Paraná" = "PR", "Pernambuco" = "PE", "Rio de Janeiro" = "RJ",
  "Rio Grande do Sul" = "RS", "Santa Catarina" = "SC", "São Paulo" = "SP",
  "Sergipe" = "SE", "Piauí" = "PI", "Rio Grande do Norte" = "RN"
)

############
# producao de energia (Cap 8 - BEN)
############

url_cap8 <- "https://www.epe.gov.br/sites-pt/publicacoes-dados-abertos/publicacoes/PublicacoesArquivos/publicacao-145/topico-515/Cap%C3%ADtulo%208%20(Dados%20Estaduais).xlsx"
temp_cap8 <- tempfile(fileext = ".xlsx")
download.file(url_cap8, destfile = temp_cap8, mode = "wb", quiet = TRUE)

raw_cap8 <- read_excel(temp_cap8, sheet = "8.1 part 3", col_names = FALSE)

# Cada bloco de ano começa com uma linha "ANO BASE XXXX"
# O ano é extraído diretamente do arquivo — sem contagem de linhas hardcoded
ano_rows <- which(grepl("ANO BASE", as.character(raw_cap8[[1]]), ignore.case = TRUE))
anos_cap8 <- as.integer(str_extract(as.character(raw_cap8[[1]][ano_rows]), "\\d{4}"))
raw_cap8$ano_tag <- NA_integer_
for (i in seq_along(ano_rows)) {
  end_row <- if (i < length(ano_rows)) ano_rows[i + 1] - 1 else nrow(raw_cap8)
  raw_cap8$ano_tag[ano_rows[i]:end_row] <- anos_cap8[i]
}

# Colunas selecionadas por posição (evita dependência nos nomes bilíngues do arquivo)
# Atenção: no arquivo atual do BEN, col 13 = Gás natural e col 14 = Gás de coqueria
producao <- raw_cap8 %>%
  filter(!is.na(ano_tag)) %>%
  filter(!is.na(suppressWarnings(as.numeric(as.character(.[[2]]))))) %>%  # remove cabeçalhos e linhas em branco
  filter(str_detect(as.character(.[[1]]), "[:lower:]")) %>%               # remove BRASIL e macrorregiões
  select(
    uf                             = 1,
    `total produzido`              = 2,
    hidro                          = 3,
    eolica                         = 4,
    solar                          = 5,
    nuclear                        = 6,
    termo                          = 7,
    cana                           = 8,
    lenha                          = 9,
    lixivia                        = 10,
    `outras fontes renovaveis`     = 11,
    `carvao vapor`                 = 12,
    `gas natural`                  = 13,
    `gas de coqueira`              = 14,
    combustivel                    = 15,
    diesel                         = 16,
    `outras fontes nao renovaveis` = 17,
    ano                            = ano_tag
  ) %>%
  mutate(
    uf = case_when(
      uf == "Mato G. do Sul"  ~ "Mato Grosso do Sul",
      uf == "Rio G. do Sul"   ~ "Rio Grande do Sul",
      uf == "Rio G. do Norte" ~ "Rio Grande do Norte",
      TRUE ~ uf
    ),
    amz_legal = if_else(uf %in% amz_legal_estados, 1L, 0L)
  ) %>%
  mutate(across(-c(uf, amz_legal), as.numeric))

############
# consumo de energia (Anuário Estatístico - Workbook)
############

url_anuario <- "https://www.epe.gov.br/sites-pt/publicacoes-dados-abertos/publicacoes/PublicacoesArquivos/publicacao-160/topico-168/anuario-workbook.xlsx"
temp_anuario <- tempfile(fileext = ".xlsx")
download.file(url_anuario, destfile = temp_anuario, mode = "wb", quiet = TRUE)

# Estrutura do Workbook atual (após skip=8):
#   col 1: UF, cols 2-15: anos 2011-2024, cols 16-18: Δ%, Part.% e coluna vazia
limpa_workbook <- function(sheet_number, tipo_dado) {
  read_excel(temp_anuario, sheet = sheet_number, skip = 8) %>%
    select(1:15) %>%                              # uf + 14 anos (2011-2024)
    rename("uf" = 1) %>%
    filter(uf %in% estados_brasileiros) %>%
    pivot_longer(cols = 2:15, names_to = "ano", values_to = "valor") %>%
    mutate(tipo = tipo_dado, ano = as.integer(ano))
}

consumo_cativo <- limpa_workbook("Tabela 3.13", "consumo cativo")
consumo_livre   <- limpa_workbook("Tabela 3.14", "consumo livre")
consumo_cativo_livre <- rbind(consumo_cativo, consumo_livre) %>%
  pivot_wider(names_from = tipo, values_from = valor)

consumidores_cativos <- limpa_workbook("Tabela 3.42", "consumidores cativos")
consumidores_livres  <- limpa_workbook("Tabela 3.43", "consumidores livres")
consumidores_cativos_livres <- rbind(consumidores_cativos, consumidores_livres) %>%
  pivot_wider(names_from = tipo, values_from = valor)

consumo_residencial      <- limpa_workbook("Tabela 3.15", "consumo residencial")
consumo_industrial       <- limpa_workbook("Tabela 3.16", "consumo industrial")
consumo_comercial        <- limpa_workbook("Tabela 3.17", "consumo comercial")
consumo_rural            <- limpa_workbook("Tabela 3.18", "consumo rural")
consumo_pod_pub          <- limpa_workbook("Tabela 3.19", "consumo poder publico")
consumo_iluminacao_pub   <- limpa_workbook("Tabela 3.20", "consumo iluminacao publica")
consumo_serv_pub         <- limpa_workbook("Tabela 3.21", "consumo servico publico")
consumo_proprio          <- limpa_workbook("Tabela 3.22", "consumo proprio")
consumo_classe <- rbind(
  consumo_residencial, consumo_industrial, consumo_comercial, consumo_rural,
  consumo_pod_pub, consumo_iluminacao_pub, consumo_serv_pub, consumo_proprio
) %>%
  pivot_wider(names_from = tipo, values_from = valor)

consumidores_residencial    <- limpa_workbook("Tabela 3.44", "consumidores residencial")
consumidores_industrial     <- limpa_workbook("Tabela 3.45", "consumidores industrial")
consumidores_comercial      <- limpa_workbook("Tabela 3.46", "consumidores comercial")
consumidores_rural          <- limpa_workbook("Tabela 3.47", "consumidores rural")
consumidores_pod_pub        <- limpa_workbook("Tabela 3.48", "consumidores poder publico")
consumidores_iluminacao_pub <- limpa_workbook("Tabela 3.49", "consumidores iluminacao publica")
consumidores_serv_pub       <- limpa_workbook("Tabela 3.50", "consumidores servico publico")
consumidores_proprio        <- limpa_workbook("Tabela 3.51", "consumidores proprio")
consumidores_classe <- rbind(
  consumidores_residencial, consumidores_industrial, consumidores_comercial, consumidores_rural,
  consumidores_pod_pub, consumidores_iluminacao_pub, consumidores_serv_pub, consumidores_proprio
) %>%
  pivot_wider(names_from = tipo, values_from = valor)

############
# tudo junto
############

db_bind <- left_join(producao, consumo_cativo_livre,      by = c("uf", "ano")) %>%
  left_join(consumo_classe,             by = c("uf", "ano")) %>%
  left_join(consumidores_cativos_livres, by = c("uf", "ano")) %>%
  left_join(consumidores_classe,         by = c("uf", "ano")) %>%
  mutate(across(-c(uf, amz_legal), as.numeric))

# Proporção em relação ao total nacional, por ano e variável
db_bind_pct <- db_bind %>%
  group_by(ano) %>%
  mutate(across(-c(uf, amz_legal), ~(.x / sum(.x, na.rm = TRUE)) * 100)) %>%
  ungroup() %>%
  rowwise() %>%
  mutate(
    `consumo total` = sum(c_across(`consumo cativo`:`consumo proprio`), na.rm = TRUE),
    consumidores    = sum(c_across(`consumidores cativos`:`consumidores proprio`), na.rm = TRUE)
  ) %>%
  ungroup()

amz_legal_df <- db_bind %>%
  filter(amz_legal == 1) %>%
  group_by(ano) %>%
  summarise(across(-c(uf, amz_legal), ~sum(.x, na.rm = TRUE))) %>%
  mutate(uf = "Amazônia Legal")

fora_amz_legal_df <- db_bind %>%
  filter(amz_legal == 0) %>%
  group_by(ano) %>%
  summarise(across(-c(uf, amz_legal), ~sum(.x, na.rm = TRUE))) %>%
  mutate(uf = "Fora da Amazônia Legal")

df_final <- rbind(amz_legal_df, fora_amz_legal_df) %>%
  rowwise() %>%
  mutate(
    `consumo total` = sum(c_across(`consumo cativo`:`consumo proprio`), na.rm = TRUE),
    consumidores    = sum(c_across(`consumidores cativos`:`consumidores proprio`), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  group_by(ano) %>%
  mutate(across(!uf, ~(.x / sum(.x, na.rm = TRUE)) * 100)) %>%
  ungroup() %>%
  rbind(db_bind_pct %>% select(-amz_legal)) %>%
  mutate(across(!uf, ~ifelse(.x < 0, 0, .x)))

df_final <- df_final %>%
  mutate_all(function(x) ifelse(is.nan(x), NA, x))

# dados de consumo do Anuário não disponíveis em 2011
df_final <- df_final %>%
  filter(ano >= 2012)

df_final$ano %>% unique

# converte UFs para siglas (Amazônia Legal e Fora da Amazônia Legal mantidos como estão)
df_final <- df_final %>%
  mutate(uf = ifelse(uf %in% names(uf_map), uf_map[uf], uf))

# export ------------------------------------------------------------------
saveRDS(df_final, "data/energia_amz_exporta.rds")

# dictionary --------------------------------------------------------------

df_final <- readRDS("./data/energia_amz_exporta.rds")
columns_db_amz_exporta <- colnames(df_final)

# Estrutura de colunas em df_final (40 colunas):
#  1:ano  2:total produzido  3-17:fontes de geração  18:consumo cativo  19:consumo livre
#  20-27:consumo por classe (8)  28:consumidores cativos  29:consumidores livres
#  30-37:consumidores por classe (8)  38:uf  39:consumo total  40:consumidores

temp_param_table <- tibble(
  var       = columns_db_amz_exporta,
  x         = TRUE,
  y         = TRUE,
  color     = FALSE,
  size      = FALSE,
  slider    = FALSE,
  geometry  = FALSE,
  label     = columns_db_amz_exporta,
  desc      = columns_db_amz_exporta,
  var_group = "Energia - EPE",
  tipo      = 1,
  unidade   = "",
  categoria    = "Economia",
  subcategoria = "Energia"
)

# labels em português
temp_param_table$label[1]  <- "Ano"
temp_param_table$label[2]  <- "Total de energia produzida"
temp_param_table$label[3]  <- "Energia produzida por hidro"
temp_param_table$label[4]  <- "Energia produzida por eólica"
temp_param_table$label[5]  <- "Energia produzida por solar"
temp_param_table$label[6]  <- "Energia produzida por nuclear"
temp_param_table$label[7]  <- "Energia produzida por termo"
temp_param_table$label[8]  <- "Energia produzida por cana"
temp_param_table$label[9]  <- "Energia produzida por lenha"
temp_param_table$label[10] <- "Energia produzida por lixívia"
temp_param_table$label[11] <- "Energia produzida por outras fontes renováveis"
temp_param_table$label[12] <- "Energia produzida por carvão vapor"
temp_param_table$label[13] <- "Energia produzida por gás natural"
temp_param_table$label[14] <- "Energia produzida por gás de coqueria"
temp_param_table$label[15] <- "Energia produzida por combustível"
temp_param_table$label[16] <- "Energia produzida por diesel"
temp_param_table$label[17] <- "Energia produzida por outras fontes não renováveis"
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
temp_param_table$label[39] <- "Consumo total"
temp_param_table$label[40] <- "Total de consumidores"

# unidades
temp_param_table$unidade[2:40] <- "% do total do Brasil"

# quais variáveis podem assumir cada papel no UI
temp_param_table$x      <- c(TRUE,  rep(FALSE, times = 39))
temp_param_table$y      <- c(FALSE, rep(TRUE,  times = 36), FALSE, TRUE, TRUE)
temp_param_table$color  <- c(rep(FALSE, times = 37), TRUE, FALSE, FALSE)
temp_param_table$size   <- rep(FALSE, times = 40)
temp_param_table$slider <- c(TRUE,  rep(FALSE, times = 39))

# grupos de variáveis no UI
temp_param_table$var_group[str_detect(temp_param_table$label, regex("consumo",      ignore_case = TRUE))] <- "CONSUMO DE ENERGIA - PROPORÇÃO EM RELAÇÃO AO BRASIL"
temp_param_table$var_group[str_detect(temp_param_table$label, regex("consumidores", ignore_case = TRUE))] <- "CONSUMIDORES DE ENERGIA - PROPORÇÃO EM RELAÇÃO AO BRASIL"
temp_param_table$var_group[str_detect(temp_param_table$label, regex("energia produzida", ignore_case = TRUE))] <- "ENERGIA PRODUZIDA - PROPORÇÃO EM RELAÇÃO AO BRASIL"

write.csv(temp_param_table, file = "data/energia_amz_exporta_dic.csv", fileEncoding = "UTF-8")

# translate to english ----------------------------------------------------
temp_param_table$label[1]  <- "Year"
temp_param_table$label[2]  <- "Total energy produced"
temp_param_table$label[3]  <- "Energy produced by hydro"
temp_param_table$label[4]  <- "Energy produced by wind"
temp_param_table$label[5]  <- "Energy produced by solar"
temp_param_table$label[6]  <- "Energy produced by nuclear"
temp_param_table$label[7]  <- "Energy produced by thermo"
temp_param_table$label[8]  <- "Energy produced by sugar cane"
temp_param_table$label[9]  <- "Energy produced by wood"
temp_param_table$label[10] <- "Energy produced by black liquor"
temp_param_table$label[11] <- "Energy produced by other renewable sources"
temp_param_table$label[12] <- "Energy produced by steam coal"
temp_param_table$label[13] <- "Energy produced by natural gas"
temp_param_table$label[14] <- "Energy produced by coke oven gas"
temp_param_table$label[15] <- "Energy produced by fuel"
temp_param_table$label[16] <- "Energy produced by diesel"
temp_param_table$label[17] <- "Energy produced by other non-renewable sources"
temp_param_table$label[18] <- "Captive consumption"
temp_param_table$label[19] <- "Free consumption"
temp_param_table$label[20] <- "Residential consumption"
temp_param_table$label[21] <- "Industrial consumption"
temp_param_table$label[22] <- "Commercial consumption"
temp_param_table$label[23] <- "Rural consumption"
temp_param_table$label[24] <- "Public authority consumption"
temp_param_table$label[25] <- "Public lighting consumption"
temp_param_table$label[26] <- "Public service consumption"
temp_param_table$label[27] <- "Personal consumption"
temp_param_table$label[28] <- "Captive consumers"
temp_param_table$label[29] <- "Free consumers"
temp_param_table$label[30] <- "Residential consumers"
temp_param_table$label[31] <- "Industrial consumers"
temp_param_table$label[32] <- "Commercial consumers"
temp_param_table$label[33] <- "Rural consumers"
temp_param_table$label[34] <- "Public authority consumers"
temp_param_table$label[35] <- "Public lighting consumers"
temp_param_table$label[36] <- "Public service consumers"
temp_param_table$label[37] <- "Personal consumers"
temp_param_table$label[38] <- "State"
temp_param_table$label[39] <- "Total consumption"
temp_param_table$label[40] <- "Total of consumers"

temp_param_table$unidade[2:40] <- "% of Brazil's total"

temp_param_table$var_group[str_detect(temp_param_table$label, regex("consumption", ignore_case = TRUE))] <- "ENERGY CONSUMPTION - PROPORTION IN RELATION TO BRAZIL"
temp_param_table$var_group[str_detect(temp_param_table$label, regex("consumers",   ignore_case = TRUE))] <- "ENERGY CONSUMERS - PROPORTION IN RELATION TO BRAZIL"
temp_param_table$var_group[str_detect(temp_param_table$label, regex("Energy produced", ignore_case = TRUE))] <- "ENERGY PRODUCED - PROPORTION IN RELATION TO BRAZIL"

write.csv(temp_param_table, file = "data/energia_amz_exporta_dic_en.csv", fileEncoding = "UTF-8")
