################################################################################
# MapBiomas - Transição de Cobertura e Uso da Terra (Amazônia Legal) — SÉRIE TEMPORAL
# Gera est e munic de transição (de/para entre classes) para o app unificado
# ts_mapbiomas_transicao (linhas de área transicionada ao longo do tempo).
#
# IMPORTANTE (memória): NÃO usar raw_data = FALSE. Nessa opção o pacote derrete a
# base para formato longo e traduz em memória (Brasil inteiro), estourando a RAM
# (std::bad_alloc). Puxamos a base CRUA (larga, ~311 Mb) e reduzimos nós mesmos.
#
# Diferenças em relação ao data-raw do RANKING (mapbiomas_transicao_rk.R):
#   - SEM pré-seleção top 10: a série temporal precisa de TODOS os grupos (o
#     usuário escolhe quais municípios/estados plotar como linhas);
#   - MANTÉM from == to: no ts faz sentido ver a persistência de uma classe ao
#     longo do tempo (o default histórico do app é "Afloramento -> Afloramento");
#   - est e munic ambos QUINQUENAIS (grade de 1985): série temporal com eixo
#     regular nos dois níveis (o toggle geográfico não muda a granularidade).
# Classes from/to em inglês (chave interna); rótulos PT/EN vêm de
# data/mapbiomas_legenda.csv. Espelha data-raw/mapbiomas_transicao_rk.R.
################################################################################

################################################################################
# 1. SETUP
################################################################################

suppressPackageStartupMessages({
    library(datazoom.amazonia)
    library(data.table)
    library(readr)
})

################################################################################
# 2. CARGA CRUA (larga: 1 linha por município×from×to, janelas em colunas)
################################################################################

dat <- load_mapbiomas(
    dataset   = "mapbiomas_transition",
    raw_data  = TRUE,           # <- crua de propósito (ver cabeçalho)
    geo_level = "municipality"
)
setDT(dat)

# Janelas QUINQUENAIS na grade de 1985. A grade limpa para em 2020 (não há
# 2020-2025 na Coleção 9; a única janela de 5 anos além disso, 2018-2023,
# sobrepõe 2015-2020 e fica fora da grade regular).
quinq <- intersect(
    c("1985_1990", "1990_1995", "1995_2000", "2000_2005",
      "2005_2010", "2010_2015", "2015_2020"),
    names(dat)
)

################################################################################
# 3. REDUÇÃO EM FORMATO LARGO (antes de derreter — mantém a memória baixa)
################################################################################

amz <- as.data.table(datazoom.amazonia::municipalities)[legal_amazon == 1,
                                                        .(geocode = code_muni)]

strip_prefix <- function(x) sub("^[0-9]+(\\.[0-9]+)*\\.?\\s*", "", as.character(x))

d <- dat[geocode %in% amz$geocode,
         c("state", "municipality", "geocode",
           "class_level_4_from", "class_level_4_to", quinq), with = FALSE]
rm(dat); gc()

d[, from := strip_prefix(class_level_4_from)]
d[, to   := strip_prefix(class_level_4_to)]
d[, c("class_level_4_from", "class_level_4_to") := NULL]
# ts MANTÉM from == to (persistência) — não filtra transições reais como o rk

################################################################################
# 4. DERRETE AS JANELAS QUINQUENAIS (long enxuto; descarta zeros)
################################################################################

long <- melt(
    d,
    id.vars       = c("state", "municipality", "geocode", "from", "to"),
    measure.vars  = quinq,
    variable.name = "time_raw",
    value.name    = "value"
)
rm(d); gc()

long <- long[!is.na(value) & value > 0]
long[, time := gsub("_", " - ", as.character(time_raw))]
long[, time_raw := NULL]

################################################################################
# 5. DATASET MUNICIPAL (group = "Município - Estado") — todos os grupos
################################################################################

munic <- long[, .(value = round(sum(value, na.rm = TRUE), 2)),
              by = .(time, group = paste(municipality, "-", state), from, to)]
setorder(munic, from, to, group, time)
saveRDS(as.data.frame(munic), "data/mapbiomas_transicao_munic.rds")

################################################################################
# 6. DATASET ESTADUAL (group = estado; área somada por estado)
################################################################################

est <- long[, .(value = round(sum(value, na.rm = TRUE), 2)),
            by = .(time, group = state, from, to)]
setorder(est, from, to, group, time)
saveRDS(as.data.frame(est), "data/mapbiomas_transicao_est.rds")

################################################################################
# 7. DICIONÁRIOS (PT / EN) — mínimos: time (x/slider), group (cor), value (y)
# As classes from/to NÃO entram no dicionário: o app pega as opções de
# unique(from)/unique(to) e traduz via data/mapbiomas_legenda.csv.
################################################################################

build_dics_ts <- function(out_pt, out_en) {
    mk <- function(idioma) {
        data.table(
            var          = c("time", "group", "value"),
            x            = c(TRUE, FALSE, FALSE),
            y            = c(FALSE, FALSE, TRUE),    # value é o eixo Y (série)
            color        = c(FALSE, TRUE, FALSE),
            size         = c(FALSE, FALSE, FALSE),
            slider       = c(TRUE, FALSE, FALSE),
            label        = if (idioma == "pt") c("Intervalo", "Grupo", "Área transicionada")
                           else                c("Interval", "Group", "Transitioned area"),
            desc         = if (idioma == "pt") c("Intervalo", "Grupo", "Área transicionada")
                           else                c("Interval", "Group", "Transitioned area"),
            var_group    = "Mapbiomas",
            tipo         = 1L,
            unidade      = "ha",
            categoria    = if (idioma == "pt") "Meio ambiente" else "Environment",
            subcategoria = if (idioma == "pt") "Uso da terra"  else "Land use"
        )
    }
    readr::write_csv(mk("pt"), out_pt)
    readr::write_csv(mk("en"), out_en)
}

build_dics_ts("data/mapbiomas_transicao_est_dic.csv",
              "data/mapbiomas_transicao_est_dic_en.csv")
build_dics_ts("data/mapbiomas_transicao_munic_dic.csv",
              "data/mapbiomas_transicao_munic_dic_en.csv")

################################################################################
# 8. CHECAGENS RÁPIDAS (rode e cole a saída)
################################################################################

cat("Janelas quinquenais:", length(quinq), "->",
    paste(gsub("_", "-", quinq), collapse = " ; "), "\n")
cat("EST  -> pares from/to:", uniqueN(paste(est$from, est$to)),
    "| estados:", uniqueN(est$group), "| linhas:", nrow(est), "\n")
cat("MUNIC-> pares from/to:", uniqueN(paste(munic$from, munic$to)),
    "| municipios:", uniqueN(munic$group), "| linhas:", nrow(munic), "\n")

if (file.exists("data/mapbiomas_legenda.csv")) {
    leg <- readr::read_csv("data/mapbiomas_legenda.csv", show_col_types = FALSE)
    classes <- union(unique(est$from), unique(est$to))
    faltam  <- setdiff(classes, leg$nome_en)
    cat("Classes from/to fora da legenda:",
        if (length(faltam)) paste(faltam, collapse = ", ") else "(nenhuma)", "\n")
}
