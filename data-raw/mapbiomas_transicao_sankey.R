################################################################################
# MapBiomas - Transição de Cobertura e Uso da Terra (Amazônia Legal) — SANKEY
# Gera est e munic de transição (de/para entre classes) para o app
# sankey_mapbiomas_transicao, AMBOS com janelas ANUAIS.
#
# IMPORTANTE (memória): NÃO usar raw_data = FALSE. Nessa opção o pacote derrete a
# base para formato longo e traduz em memória (Brasil inteiro), estourando a RAM
# (std::bad_alloc). Puxamos a base CRUA (larga, ~311 Mb) e reduzimos nós mesmos.
#
# Diferenças em relação ao data-raw da SÉRIE TEMPORAL (mapbiomas_transicao_ts.R):
#   - MUNICÍPIO tambem ANUAL: no ts o município é quinquenal porque a série
#     plota ~772 grupos de uma vez; no sankey só uma unidade aparece por vez,
#     então a grade anual cabe e deixa os dois níveis do toggle simétricos;
#   - EXCLUI from == to: o sankey nunca mostra persistência (ela responde por
#     quase toda a área e achataria as transições reais), então filtrar aqui
#     derruba o tamanho do arquivo em vez de carregar peso morto para o app.
# NÃO sobrescreve mapbiomas_transicao_{est,munic}.rds: aqueles são lidos pelo
# app ts_mapbiomas_transicao e têm outra grade temporal.
# Classes from/to em inglês (chave interna); rótulos PT/EN vêm de
# data/mapbiomas_legenda.csv.
################################################################################

################################################################################
# 1. SETUP
################################################################################

suppressPackageStartupMessages({
    library(datazoom.amazonia)
    library(data.table)
    library(readr)
})

# O schema do pacote já mudou de nome de coluna entre coleções: seleciona por
# candidatos e falha alto imprimindo o que existe, para o 1º run revelar o real
pick <- function(d, cands, what) {
    hit <- intersect(cands, names(d))
    if (!length(hit)) {
        stop("Coluna de ", what, " não encontrada. Candidatas: ",
             paste(cands, collapse = ", "),
             " | Disponíveis: ", paste(names(d), collapse = ", "))
    }
    hit[1]
}

################################################################################
# 2. CARGA CRUA (larga: 1 linha por município×from×to, janelas em colunas)
################################################################################

dat <- load_mapbiomas(
    dataset   = "mapbiomas_transition",
    raw_data  = TRUE,           # <- crua de propósito (ver cabeçalho)
    geo_level = "municipality"
)
setDT(dat)

from_col <- pick(dat, c("class_level_4_from", "from_level_4", "from"), "origem")
to_col   <- pick(dat, c("class_level_4_to",   "to_level_4",   "to"),   "destino")
geo_col  <- pick(dat, c("geocode", "municipality_code", "code_muni"),  "município")

# Janelas ANUAIS: "AAAA_AAAA" com diferença de exatamente 1 ano
tcols  <- grep("^[0-9]{4}_[0-9]{4}$", names(dat), value = TRUE)
annual <- tcols[vapply(strsplit(tcols, "_"), function(a)
    as.integer(a[2]) - as.integer(a[1]) == 1L, logical(1))]
if (!length(annual)) stop("Nenhuma janela anual encontrada em: ",
                          paste(tcols, collapse = ", "))

################################################################################
# 3. REDUÇÃO EM FORMATO LARGO (antes de derreter — mantém a memória baixa)
################################################################################

amz <- as.data.table(datazoom.amazonia::municipalities)[legal_amazon == 1,
                                                        .(geocode = code_muni)]

strip_prefix <- function(x) sub("^[0-9]+(\\.[0-9]+)*\\.?\\s*", "", as.character(x))

d <- dat[get(geo_col) %in% amz$geocode,
         c("state", "municipality", geo_col, from_col, to_col, annual), with = FALSE]
rm(dat); gc()

d[, from := strip_prefix(get(from_col))]
d[, to   := strip_prefix(get(to_col))]
d[, c(from_col, to_col) := NULL]

# Só transições reais: o sankey nunca desenha persistência
d <- d[from != to]

################################################################################
# 4. DERRETE AS JANELAS ANUAIS (long enxuto; descarta zeros)
################################################################################

long <- melt(
    d,
    id.vars       = c("state", "municipality", geo_col, "from", "to"),
    measure.vars  = annual,
    variable.name = "time_raw",
    value.name    = "value"
)
rm(d); gc()

long <- long[!is.na(value) & value > 0]
long[, time := gsub("_", " - ", as.character(time_raw))]
long[, time_raw := NULL]

annual_times <- sort(gsub("_", " - ", annual))

################################################################################
# 5. DATASET MUNICIPAL (group = "Município - Estado") — anual
################################################################################

munic <- long[, .(value = round(sum(value, na.rm = TRUE), 2)),
              by = .(time, group = paste(municipality, "-", state), from, to)]
setorder(munic, from, to, group, time)
saveRDS(as.data.frame(munic), "data/mapbiomas_transicao_sankey_munic.rds")

################################################################################
# 6. DATASET ESTADUAL (group = estado; área somada por estado) — anual
################################################################################

est <- long[, .(value = round(sum(value, na.rm = TRUE), 2)),
            by = .(time, group = state, from, to)]
setorder(est, from, to, group, time)
saveRDS(as.data.frame(est), "data/mapbiomas_transicao_sankey_est.rds")

################################################################################
# 7. DICIONÁRIOS (PT / EN) — mínimos: time (x/slider), group (cor), value (y)
# As classes from/to NÃO entram no dicionário: o app pega as opções de
# unique(from)/unique(to) e traduz via data/mapbiomas_legenda.csv.
################################################################################

build_dics_sankey <- function(out_pt, out_en) {
    mk <- function(idioma) {
        data.table(
            var          = c("time", "group", "value"),
            x            = c(TRUE, FALSE, FALSE),
            y            = c(FALSE, FALSE, TRUE),    # value é a largura do fluxo
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

build_dics_sankey("data/mapbiomas_transicao_sankey_dic.csv",
                  "data/mapbiomas_transicao_sankey_dic_en.csv")

################################################################################
# 8. CHECAGENS RÁPIDAS (rode e cole a saída)
################################################################################

cat("Colunas ->", from_col, "|", to_col, "|", geo_col, "\n")
cat("Janelas anuais:", length(annual_times),
    "| de", annual_times[1], "a", annual_times[length(annual_times)], "\n")
cat("EST  -> pares from/to:", uniqueN(paste(est$from, est$to)),
    "| estados:", uniqueN(est$group), "| linhas:", nrow(est), "\n")
cat("MUNIC-> pares from/to:", uniqueN(paste(munic$from, munic$to)),
    "| municipios:", uniqueN(munic$group), "| linhas:", nrow(munic), "\n")
cat("Tamanho em disco (MB) -> est:",
    round(file.size("data/mapbiomas_transicao_sankey_est.rds") / 1024^2, 2),
    "| munic:",
    round(file.size("data/mapbiomas_transicao_sankey_munic.rds") / 1024^2, 2), "\n")
cat("Persistencia (from == to) remanescente:",
    sum(est$from == est$to) + sum(munic$from == munic$to), "(esperado: 0)\n")

# A grade tem que ser consecutiva e sem sobreposição: é o que autoriza o modo
# acumulado do app a somar janelas sem dupla contagem
anos <- do.call(rbind, lapply(strsplit(annual_times, " - "), as.integer))
cat("Grade consecutiva (sem buraco/sobreposicao):",
    all(anos[-1, 1] == anos[-nrow(anos), 2]), "\n")

if (file.exists("data/mapbiomas_legenda.csv")) {
    leg <- readr::read_csv("data/mapbiomas_legenda.csv", show_col_types = FALSE)
    classes <- union(unique(est$from), unique(est$to))
    faltam  <- setdiff(classes, leg$nome_en)
    cat("Classes from/to fora da legenda:",
        if (length(faltam)) paste(faltam, collapse = ", ") else "(nenhuma)", "\n")
}
