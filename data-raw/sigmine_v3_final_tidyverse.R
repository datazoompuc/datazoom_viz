############################################################
#### Generate rds data in the folder ./data/
####
#### Requer datazoom.amazonia >= 1.2.0.9000 (branch sigmine-geo-level),
#### instalado via:
####   devtools::install_github("datazoompuc/datazoom.amazonia",
####                             ref = "sigmine-geo-level")
####
#### Contexto: a função load_sigmine() do pacote perdeu o parâmetro de
#### agregação geográfica em 2021 (antes de uma submissão ao CRAN) e nunca
#### foi restaurado. Isso fazia esse script chamar um parâmetro que não
#### existia mais, retornando dados de todo o Brasil sem agregação
#### municipal -- o que também causava estouro de memória no deploy do
#### app (dataset de ~1.2GB sem filtro geográfico). geo_level foi
#### restaurado no pacote (branch sigmine-geo-level); este script foi
#### atualizado para usá-lo e para aplicar o filtro de Amazônia Legal,
#### que fica aqui (no datazoom_viz), não dentro da função genérica do
#### pacote.
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(stringi)

# geo_level = "municipality" já retorna o dado com cruzamento espacial e
# nomes de município feitos dentro do pacote (usa o centroide de cada
# processo de mineração, reprojetado para CRS planar brasileiro antes do
# cálculo, para evitar tanto a distorção geodésica quanto a dupla contagem
# quando um polígono cruza fronteira municipal -- ver R/sigmine.R).
dat <- load_sigmine(dataset = "sigmine_active", geo_level = "municipality", language = "pt")

############################################################
#### Filtra Amazônia Legal
############################################################

munic_amz <- datazoom.amazonia::municipalities %>%
  filter(legal_amazon == 1) %>%
  select(cod_municipio = code_muni)

dat_amz <- dat %>%
  inner_join(munic_amz, by = "cod_municipio")

############################################################
#### Trata dados e monta base final
############################################################

dat_tratado <- dat_amz %>%
  select(ano, area_m2, mineral, municipio, uf) %>%
  mutate(
    mineral = str_to_sentence(mineral, locale = "br"),
    group = paste(municipio, "-", uf)
  ) %>%
  select(-municipio, -uf)

# Agrega área por ano + mineral + grupo (município-estado)
dat_agg <- dat_tratado %>%
  group_by(ano, mineral, group) %>%
  summarise(area_m2 = sum(area_m2, na.rm = TRUE), .groups = "drop")

# Reshape para formato wide (uma coluna por mineral)
datafinal <- dat_agg %>%
  pivot_wider(
    id_cols = c(group, ano),
    names_from = mineral,
    values_from = area_m2,
    names_prefix = "",
    values_fill = 0
  ) %>%
  rename(time = ano) %>%
  mutate(
    TOTAL = rowSums(across(-c(time, group)))
  ) %>%
  arrange(group, time)

# Preenche combinações ano x município ausentes (sem mineração naquele ano)
datafinal <- datafinal %>%
  complete(time, group) %>%
  mutate(across(where(is.numeric), ~ replace_na(., 0)))

############################################################
#### Validação (comparação com a versão anterior)
############################################################

# Resultado observado (2026-08-27, atualizado 2026-09-02 após correção do
# centroide):
# - Municípios da Amazônia Legal apenas (bug de escopo do .rds antigo,
#   que incluía o Brasil inteiro, já identificado e reportado)
# - Correção do cálculo de centroide (reprojeção para CRS planar brasileiro
#   em vez de desligar sf_use_s2()) eliminou completamente as duplicatas de
#   processo remanescentes do cruzamento espacial (~9600 antes -> 0 agora)
# - Diferença de totais de área frente ao .rds antigo ainda em investigação
#   com o Antonio (ver comunicação anterior)

############################################################
#### Salva resultado (NÃO sobrescreve o .rds em produção até aprovação)
############################################################

saveRDS(datafinal, "data/sigmine_munic_v3_TESTE.rds")

#####################
# Build Dictionary
#####################
# Sem mudanças nesta seção -- o dicionário PT/EN já existe e foi revisado
# manualmente (25 termos de tradução corrigidos). Ver:
#   data/sigmine_munic_dic.csv
#   data/sigmine_munic_en_dic.csv
# Não regenerar a partir daqui, ou essas correções serão perdidas.
