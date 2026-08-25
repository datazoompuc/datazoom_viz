############################################################
#### INVESTIGAÇÃO — Reconstrução do pipeline sigmine_munic
####
#### Contexto: o script original (sigmine.R) chamava
#### load_sigmine(space_aggregation = "municipality", ...),
#### mas essa versão da função não existe mais na versão
#### atual do pacote datazoom.amazonia (CRAN 1.2.0).
####
#### A função hoje retorna geometria (polígono) por processo
#### de mineração individual, sem agregação municipal pronta.
#### Este script reconstrói essa agregação manualmente via
#### cruzamento espacial (spatial join) com o shapefile de
#### municípios já usado por outros apps do repositório
#### (global/munic_shapefile.rds).
####
#### Resultado salvo como sigmine_munic_v2_TESTE.rds (não
#### sobrescreve o .rds em produção) para comparação e
#### validação antes de substituir o arquivo original.
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(sf)
library(stringi)

############################################################
#### 1. Carrega dados brutos do SIGMINE
############################################################

# A função atual (v1.2.0) retorna geometria por processo de
# mineração individual (não agrega por município nem estado).
# Colunas: processo, numero, ano, area_m2, id, fase,
# ultimo_evento, empresa, mineral, uso, uf, ds_processo, geometry
dat <- load_sigmine(dataset = "sigmine_active", language = "pt")

############################################################
#### 2. Limpeza de geometria
############################################################

# O dado vem com dimensão Z/M extra (incomum para dado 2D),
# o que quebra operações espaciais subsequentes.
dat_zm <- st_zm(dat, drop = TRUE, what = "ZM")

# Corrige geometrias inválidas (vértices duplicados,
# auto-interseção) encontradas no dado bruto da ANM.
# É necessário desligar o motor de geometria esférica (s2)
# do pacote sf: mesmo depois de st_make_valid(), o s2 (mais
# rígido) ainda falhava em alguns polígonos específicos.
# Para áreas pequenas (processos de mineração, municípios),
# a aproximação planar é aceitável.
sf::sf_use_s2(FALSE)
dat_valid <- st_make_valid(dat_zm)

############################################################
#### 3. Cruzamento espacial com shapefile de municípios
############################################################

# Usamos o CENTROIDE de cada polígono de mina, não o polígono
# inteiro, para evitar contagem duplicada quando uma mina toca
# a fronteira entre dois municípios (isso de fato acontecia:
# ~9.600 duplicatas ao usar o polígono inteiro).
dat_centroid <- st_centroid(dat_valid)

munic_shp <- readRDS("global/munic_shapefile.rds")
# Colunas: municipality_code, legal_amazon (1/0), geom

dat_munic <- st_join(dat_centroid, munic_shp, join = st_intersects)

sf::sf_use_s2(TRUE)  # reativa o motor padrão para o resto da sessão

############################################################
#### 4. Remove duplicatas remanescentes
############################################################

# O dado bruto da ANM já contém processos duplicados
# (mesmo número de processo, múltiplas linhas) — confirmado:
# sum(duplicated(dat$processo)) == 9587, praticamente idêntico
# ao número de duplicatas remanescentes após o join espacial.
# Isso não é introduzido pelo cruzamento; é uma característica
# dos dados de origem. Mantemos apenas a primeira ocorrência.
dat_munic <- dat_munic %>%
  distinct(processo, .keep_all = TRUE)

############################################################
#### 5. Filtra Amazônia Legal e junta nome/UF do município
############################################################

# municipality_code do shapefile não vem com nome/UF —
# usamos datazoom.amazonia::municipalities para isso.
dat_amz <- dat_munic %>%
  filter(legal_amazon == 1) %>%
  st_drop_geometry() %>%
  left_join(
    municipalities %>% select(code_muni, name_muni, abbrev_state),
    by = c("municipality_code" = "code_muni")
  ) %>%
  mutate(group = paste(str_to_title(name_muni), "-", abbrev_state))

############################################################
#### 6. Agregação por ano + mineral + grupo, formato wide
############################################################

dat_agg <- dat_amz %>%
  mutate(mineral = str_to_sentence(mineral, locale = "br"))

dat_agg <- aggregate(area_m2 ~ ano + mineral + group, dat_agg, sum)

datafinal_novo <- reshape(
  dat_agg,
  idvar = c("group", "ano"),
  timevar = "mineral",
  direction = "wide"
)

# Remove prefixo "area_m2." dos nomes de coluna gerado pelo reshape
labl <- colnames(datafinal_novo)
labl <- labl[-c(1, 2)]
labl <- substr(labl, 9, 100)
colnames(datafinal_novo) <- c("ano", "group", labl)

datafinal_novo[is.na(datafinal_novo)] <- 0
datafinal_novo$TOTAL <- rowSums(datafinal_novo[, 3:ncol(datafinal_novo)])
datafinal_novo <- datafinal_novo[order(datafinal_novo$group, datafinal_novo$ano), ]

############################################################
#### 7. Validação contra o .rds antigo (data/sigmine_munic.rds)
############################################################

antigo <- readRDS("data/sigmine_munic.rds")

# Comparação de escopo geográfico (nomes de município batem
# ~97% após remover acentuação — a tabela municipalities do
# pacote retorna nomes sem acento, o .rds antigo tem acento).
novo_sem_acento  <- stri_trans_general(datafinal_novo$group, "Latin-ASCII")
antigo_sem_acento <- stri_trans_general(antigo$group, "Latin-ASCII")

comuns <- intersect(unique(novo_sem_acento), unique(antigo_sem_acento))

cat("Municípios no novo dataset:", length(unique(novo_sem_acento)), "\n")
cat("Municípios em comum com o antigo:", length(comuns), "\n")

# Resultado observado (2026-08-18):
# - 719 municípios no novo (só Amazônia Legal) vs 5.311 no
#   antigo (Brasil inteiro, sem filtro geográfico — bug
#   identificado e reportado)
# - 698 de 719 batem após remover acentuação (~97%)
# - Comparando área de Areia SÓ nos municípios em comum:
#     novo:   5.736.928.800 m²
#     antigo: 4.484.733.737 m²  (~28% menor)
#   Hipótese: o pipeline antigo (função load_sigmine
#   descontinuada) provavelmente não tratava as duplicatas
#   de processo que identificamos no dado bruto da ANM,
#   inflando artificialmente a área agregada. Não foi possível
#   confirmar com certeza pois a função antiga não está mais
#   disponível para reexecução.

############################################################
#### 8. Salva resultado para comparação (NÃO sobrescreve o .rds em produção)
############################################################

saveRDS(datafinal_novo, "data/sigmine_munic_v2_TESTE.rds")
