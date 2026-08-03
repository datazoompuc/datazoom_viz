############################################################
#### Gera ./data/dz_munic_ppm_mapbiomas.rds e os dicionários PT/EN
####
#### Indicador: cabeças de bovino por hectare de pastagem, por município e ano.
####   numerador   = PPM/IBGE, efetivo do rebanho bovino (var num_v2670)
####   denominador = MapBiomas, área da classe "Pasture" (ha)
####
#### Sobre a coleção do MapBiomas: o load_mapbiomas() do datazoom.amazonia ainda
#### lê a aba COVERAGE_9 (série até 2023). Como o PPM já tem 2024, aqui lemos a
#### planilha oficial da Coleção 10 direto do bucket público. Quando o pacote
#### subir para a Coleção 10, dá para voltar a usar load_mapbiomas().
####
#### Uma base só (sem versão _en): as colunas de recorte geográfico guardam
#### chaves neutras (UF, código de região, dummy de Amazônia Legal) e os rótulos
#### PT/EN vivem no param$i18n do app.
############################################################

#### Packages
library(dplyr)
library(tidyr)
library(readxl)
library(janitor)
library(stringi)
library(datazoom.amazonia)

# O schema das duas fontes já mudou de nome de coluna mais de uma vez, então
# nada aqui depende de nome fixo: descobrimos a coluna e falhamos alto se sumir.
pick <- function(d, cands, what) {
  hit <- intersect(cands, names(d))
  if (!length(hit)) {
    stop("Coluna de ", what, " não encontrada. Disponíveis: ",
         paste(names(d), collapse = ", "))
  }
  hit[1]
}

######################################################################
# 1) MAPBIOMAS - área de pastagem por município (Coleção 10)
######################################################################

mapbiomas_url <- paste0(
  "https://storage.googleapis.com/mapbiomas-public/initiatives/brasil/",
  "collection_10/lulc/statistics/",
  "MAPBIOMAS_BRAZIL-COL.10-BIOME_STATE_MUNICIPALITY.xlsx"
)

# ~78 MB: baixa uma vez por sessão de R e reaproveita nas rodadas seguintes
mapbiomas_file <- file.path(tempdir(), "mapbiomas_col10_municipality.xlsx")
if (!file.exists(mapbiomas_file)) {
  options(timeout = max(1800, getOption("timeout")))
  utils::download.file(mapbiomas_url, mapbiomas_file, mode = "wb", method = "curl")
}

# A aba de cobertura muda de nome a cada coleção (COVERAGE_9, COVERAGE_10, ...)
abas <- readxl::excel_sheets(mapbiomas_file)
sheet_cover <- grep("^COVERAGE", abas, value = TRUE)[1]
if (is.na(sheet_cover)) {
  stop("Aba de cobertura não encontrada. Abas disponíveis: ", paste(abas, collapse = ", "))
}
message("Lendo aba: ", sheet_cover, " (isso demora alguns minutos)")

cover_raw <- readxl::read_xlsx(mapbiomas_file, sheet = sheet_cover) %>%
  janitor::clean_names()

col_geo  <- pick(cover_raw,
                 c("geocode", "municipality_code", "city_code", "cod_municipio"),
                 "código do município (MapBiomas)")
col_lvls <- grep("level_\\d+$", names(cover_raw), value = TRUE)
col_year <- grep("^x(19|20)\\d{2}$", names(cover_raw), value = TRUE)

if (!length(col_lvls)) stop("Nenhuma coluna level_* encontrada: ", paste(names(cover_raw), collapse = ", "))
if (!length(col_year)) stop("Nenhuma coluna de ano (x1985...) encontrada: ", paste(names(cover_raw), collapse = ", "))

# Os rótulos vêm numerados e acentuados ("3.1. Pasture") - normaliza igual ao pacote
clean_class <- function(x) {
  x <- stringi::stri_trans_general(as.character(x), "Latin-ASCII")
  trimws(sub("^\\s*\\d+(?:\\.\\d+)*\\.?\\s*", "", x))
}
cover_raw[col_lvls] <- lapply(cover_raw[col_lvls], clean_class)

# Em qual nível hierárquico está "Pasture" (é o 2 na Col 9/10, mas não fixamos).
# Como os níveis mais profundos repetem o rótulo quando a classe não se subdivide,
# filtrar pelo nível mais raso seleciona exatamente as mesmas linhas-folha.
tem_pasture <- vapply(col_lvls,
                      function(v) any(cover_raw[[v]] == "Pasture", na.rm = TRUE),
                      logical(1))
if (!any(tem_pasture)) {
  stop("Classe 'Pasture' não encontrada em nenhum level_*. Classes do último nível: ",
       paste(sort(unique(cover_raw[[tail(col_lvls, 1)]])), collapse = " | "))
}
col_pasture <- col_lvls[which(tem_pasture)[1]]

# A planilha quebra o município por bioma, então as partes precisam ser somadas
pastagem <- cover_raw %>%
  filter(.data[[col_pasture]] == "Pasture") %>%
  select(cod_ibge = all_of(col_geo), all_of(col_year)) %>%
  pivot_longer(all_of(col_year),
               names_to = "ano", values_to = "area_pastagem",
               names_prefix = "x") %>%
  mutate(cod_ibge      = as.integer(cod_ibge),
         ano           = as.integer(ano),
         area_pastagem = as.numeric(area_pastagem)) %>%
  group_by(cod_ibge, ano) %>%
  summarise(area_pastagem = sum(area_pastagem, na.rm = TRUE), .groups = "drop")

rm(cover_raw); gc()

######################################################################
# 2) PPM/IBGE - efetivo do rebanho bovino por município
######################################################################

# Base intermediária gerada por data-raw/ppm_municipality.R
ppm <- readRDS("./data/ppm_municipality_livestock_inventory.rds")

col_ppm_geo <- pick(ppm, c("geo_id", "cod_municipio", "municipality_code"),
                    "código do município (PPM)")
col_ppm_ano <- pick(ppm, c("ano", "time", "year"), "ano (PPM)")
col_ppm_bov <- pick(ppm, "num_v2670", "efetivo de bovinos (PPM, rebanho 2670)")

bovinos <- ppm %>%
  transmute(cod_ibge  = as.integer(.data[[col_ppm_geo]]),
            ano       = as.integer(.data[[col_ppm_ano]]),
            n_bovinos = as.numeric(.data[[col_ppm_bov]]))

######################################################################
# 3) Indicador: bovinos por hectare de pastagem
######################################################################

df <- bovinos %>%
  inner_join(pastagem, by = c("cod_ibge", "ano")) %>%
  # o ppm_municipality.R zera os NA, então pastagem 0 vira razão indefinida
  # (antes isso virava Inf e poluía o histograma)
  mutate(n_bovino_por_area_pastagem = ifelse(area_pastagem > 0,
                                             round(n_bovinos / area_pastagem, 2),
                                             NA_real_)) %>%
  filter(ano >= 1985, !is.na(n_bovino_por_area_pastagem))

# Município sem classe Pasture no MapBiomas cai fora do inner_join. Na Amazônia
# Legal isso hoje atinge só Santa Cruz do Arari/PA (1506401), campo alagado do
# Marajó, então a base fecha com 771 dos 772 - a checagem no fim lista quem faltou.

######################################################################
# 4) Recortes geográficos (chaves neutras, rótulos ficam no app)
######################################################################

# UF e região saem do próprio código do IBGE - não dependem de pacote externo
uf_por_codigo <- c(
  "11" = "RO", "12" = "AC", "13" = "AM", "14" = "RR", "15" = "PA", "16" = "AP",
  "17" = "TO", "21" = "MA", "22" = "PI", "23" = "CE", "24" = "RN", "25" = "PB",
  "26" = "PE", "27" = "AL", "28" = "SE", "29" = "BA", "31" = "MG", "32" = "ES",
  "33" = "RJ", "35" = "SP", "41" = "PR", "42" = "SC", "43" = "RS", "50" = "MS",
  "51" = "MT", "52" = "GO", "53" = "DF"
)
# prefixo R_ para a chave de região não colidir com sigla de UF (SE = Sergipe)
regiao_por_digito <- c("1" = "R_N", "2" = "R_NE", "3" = "R_SE", "4" = "R_S", "5" = "R_CO")

# Amazônia Legal: fonte canônica do repo
munic_legal <- datazoom.amazonia::municipalities %>%
  filter(legal_amazon == 1) %>%
  pull(code_muni) %>%
  as.integer()

cod_uf <- substr(as.character(df$cod_ibge), 1, 2)

df <- df %>%
  mutate(
    uf           = factor(unname(uf_por_codigo[cod_uf]), levels = sort(uf_por_codigo)),
    regiao       = factor(unname(regiao_por_digito[substr(cod_uf, 1, 1)]),
                          levels = c("R_N", "R_NE", "R_CO", "R_SE", "R_S")),
    legal_amazon = cod_ibge %in% munic_legal
  ) %>%
  filter(!is.na(uf)) %>%
  select(cod_ibge, ano, uf, regiao, legal_amazon, n_bovino_por_area_pastagem) %>%
  arrange(cod_ibge, ano)

# Uma linha por município-ano. A base antiga repetia cada município 3x (estado,
# região e Amazônia Legal empilhados na coluna "uf"), o que fazia o .rds passar
# de 40 MB e travar o carregamento do app; agora os grupos são montados no server.
df <- distinct(df, cod_ibge, ano, .keep_all = TRUE)

readr::write_rds(df, "./data/dz_munic_ppm_mapbiomas.rds", compress = "xz")

######################################################################
# 5) Dicionários (PT / EN)
######################################################################

build_dic <- function(labels) {
  vars <- names(labels)
  tibble::tibble(
    var          = vars,
    x            = vars %in% c("ano", "n_bovino_por_area_pastagem"),
    y            = vars %in% c("ano", "n_bovino_por_area_pastagem"),
    color        = vars %in% c("uf", "regiao"),
    size         = FALSE,
    slider       = vars == "ano",
    label        = unname(labels),
    desc         = unname(labels),
    var_group    = "IBGE - PPM e MAPBIOMAS",
    tipo         = 1,
    unidade      = "",
    categoria    = "",
    subcategoria = ""
  )
}

dic_pt <- build_dic(c(
  cod_ibge                   = "Código do município",
  ano                        = "Ano",
  uf                         = "Estado",
  regiao                     = "Região",
  legal_amazon               = "Amazônia Legal",
  n_bovino_por_area_pastagem = "Rebanho por área de pasto"
)) %>%
  mutate(
    unidade      = ifelse(var == "n_bovino_por_area_pastagem",
                          "Cabeças por hectare de pastagem",
                          ifelse(var == "ano", "Ano", "")),
    categoria    = ifelse(var == "ano", "Unidade de tempo",
                          ifelse(var == "n_bovino_por_area_pastagem",
                                 "Produção Econômica", "Localização")),
    subcategoria = ifelse(var == "ano", "Ano",
                          ifelse(var == "n_bovino_por_area_pastagem",
                                 "Pecuária", "Identificador Geográfico"))
  )

dic_en <- build_dic(c(
  cod_ibge                   = "Municipality Code",
  ano                        = "Year",
  uf                         = "State",
  regiao                     = "Region",
  legal_amazon               = "Legal Amazon",
  n_bovino_por_area_pastagem = "Cattle herd by pasture area"
)) %>%
  mutate(
    var_group    = "IBGE - PPM and MAPBIOMAS",
    unidade      = ifelse(var == "n_bovino_por_area_pastagem",
                          "Heads per hectare of pasture",
                          ifelse(var == "ano", "Year", "")),
    categoria    = ifelse(var == "ano", "Unit of time",
                          ifelse(var == "n_bovino_por_area_pastagem",
                                 "Economic Production", "Location")),
    subcategoria = ifelse(var == "ano", "Year",
                          ifelse(var == "n_bovino_por_area_pastagem",
                                 "Livestock", "Geographic Identifier"))
  )

write.csv(dic_pt, "./data/dz_munic_ppm_mapbiomas_dic.csv",
          fileEncoding = "UTF-8", row.names = FALSE)
write.csv(dic_en, "./data/dz_munic_ppm_mapbiomas_dic_en.csv",
          fileEncoding = "UTF-8", row.names = FALSE)

######################################################################
# 6) Checagens
######################################################################

cat("\n---------------- CHECAGENS ----------------\n")
cat("Aba MapBiomas lida .....:", sheet_cover, "\n")
cat("Nivel da classe Pasture :", col_pasture, "\n")
cat("Colunas PPM usadas .....:", col_ppm_geo, "/", col_ppm_ano, "/", col_ppm_bov, "\n")
cat("Anos MapBiomas .........:", min(pastagem$ano), "-", max(pastagem$ano), "\n")
cat("Anos PPM ...............:", min(bovinos$ano), "-", max(bovinos$ano), "\n")
cat("Anos na base final .....:", min(df$ano), "-", max(df$ano), "\n")
cat("Linhas .................:", nrow(df), "\n")
cat("Municipios .............:", dplyr::n_distinct(df$cod_ibge), "\n")
cat("Municipios Amaz. Legal .:", dplyr::n_distinct(df$cod_ibge[df$legal_amazon]),
    "de", length(munic_legal), "\n")
faltantes <- setdiff(munic_legal, unique(df$cod_ibge))
cat("Amaz. Legal sem dado ...:",
    if (length(faltantes)) paste(faltantes, collapse = ", ") else "nenhum", "\n")
cat("UFs ....................:", nlevels(droplevels(df$uf)), "(esperado 27)\n")
cat("Tamanho do .rds (MB) ...:",
    round(file.size("./data/dz_munic_ppm_mapbiomas.rds") / 1024^2, 1), "\n")
cat("Distribuicao do indicador:\n")
print(summary(df$n_bovino_por_area_pastagem))
cat("Anos sem observacao ....:",
    paste(setdiff(min(df$ano):max(df$ano), unique(df$ano)), collapse = ", "), "\n")
cat("-------------------------------------------\n")
