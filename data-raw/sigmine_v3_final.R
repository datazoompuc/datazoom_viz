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
library(tibble)
library(zoo)
library(readxl)
library(stringi)

# geo_level = "municipality" já retorna o dado com cruzamento espacial e
# nomes de município feitos dentro do pacote (usa o centroide de cada
# processo de mineração para evitar dupla contagem quando um polígono
# cruza fronteira municipal -- ver R/sigmine.R em datazoom.amazonia).
dat <- load_sigmine(dataset = "sigmine_active", geo_level = "municipality", language = "pt")

saveRDS(dat, file = "data/sigmine_munic_raw.rds")

############################################################
#### Filtra Amazônia Legal
############################################################

munic_amz <- datazoom.amazonia::municipalities %>%
  dplyr::filter(legal_amazon == 1) %>%
  dplyr::select(cod_municipio = code_muni)

dat <- dat %>%
  dplyr::inner_join(munic_amz, by = "cod_municipio")

############################################################
#### Trata dados e monta base final
############################################################

data <- dat
data$id <- NULL
data$processo <- NULL
data$fase <- NULL
data$empresa <- NULL
data$uso <- NULL
data$ds_processo <- NULL
data$numero <- NULL
data$ultimo_evento <- NULL
data$cod_uf <- NULL
data$nome_uf <- NULL
data$cod_regiao <- NULL
data$nome_regiao <- NULL

data$group <- paste(data$municipio, "-", data$uf)
data$municipio <- NULL
data$uf <- NULL
data$cod_municipio <- NULL

colnames(data) <- c("time", "area", "mineral", "group")

data <- aggregate(area ~ time + mineral + group, data, sum)

datafinal <- reshape(data, idvar = c("group", "time"), timevar = "mineral", direction = "wide")
labl <- colnames(datafinal)
labl <- labl[-c(1, 2)]
labl <- substr(labl, 6, 100)
# Padroniza capitalização (a nova load_sigmine() retorna mineral em
# maiúsculas; o dicionário existente usa capitalização tipo sentença)
labl <- stringr::str_to_sentence(labl, locale = "br")
colnames(datafinal) <- c("time", "group", labl)
datafinal[is.na(datafinal)] <- 0
datafinal$TOTAL <- rowSums(as.data.frame(datafinal[, 3:ncol(datafinal)]))
datafinal <- datafinal[order(datafinal$group, datafinal$time), ]

datafinal <- datafinal %>%
  tidyr::complete(time, group)

datafinal[is.na(datafinal)] <- 0

############################################################
#### Validação (comparação com a versão anterior)
############################################################

# Resultado observado (2026-08-27):
# - 773 municípios no novo (Amazônia Legal) vs 5.311 no antigo
#   (Brasil inteiro -- bug identificado e já reportado)
# - 697 de 773 batem após normalizar acentuação
# - Diferença de ~24-28% nos totais de área (ex.: Areia), na mesma faixa
#   observada na investigação manual anterior. Hipótese em aberto,
#   discutida com Antonio: possível tratamento diferente de duplicatas de
#   processo no pipeline antigo (função já descontinuada, não é mais
#   possível reexecutá-la para confirmar).

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
