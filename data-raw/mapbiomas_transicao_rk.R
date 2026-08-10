################################################################################
# MapBiomas - Transição de Cobertura e Uso da Terra (Amazônia Legal) — RANKING
# Gera est e munic de transição (de/para entre classes) para o app unificado
# rk_mapbiomas_transicao.
#
# IMPORTANTE (memória): NÃO usar raw_data = FALSE. Nessa opção o pacote derrete a
# base para formato longo e traduz em memória (Brasil inteiro), estourando a RAM
# (std::bad_alloc). Puxamos a base CRUA (larga, ~311 Mb) e reduzimos nós mesmos:
# filtra Amazônia por geocode, dropa from==to e derrete só as janelas de interesse.
#
# GRANULARIDADE (decisão de produto):
#   - MUNICÍPIO: quinquenal na grade de 1985 (1985-1990 ... 2015-2020). Com ~772
#     municípios, o ranking anual gerava traces demais no plotly (um por município
#     × 38 quadros) e ficava lento. 7 janelas resolvem: menos quadros e menos
#     municípios diferentes passando pelo top 10.
#   - ESTADO: anual (só 9 UFs, renderiza rápido mesmo com 38 quadros).
# A grade quinquenal para em 2020: não há 2020-2025 (Coleção 9 vai a 2023) e a
# única janela de 5 anos além disso (2018-2023) sobrepõe 2015-2020 — fora da grade.
#
# Outras decisões: remove from==to (é ranking de transição); classes from/to em
# inglês (chave interna, rótulos PT/EN vêm de data/mapbiomas_legenda.csv);
# pré-seleção top 10 por par + grade completa (0 nos anos sem transição) para os
# rótulos ficarem estáveis na animação e o acumulado (cumsum) ser contínuo.
################################################################################

################################################################################
# 1. SETUP
################################################################################

suppressPackageStartupMessages({
    library(datazoom.amazonia)
    library(data.table)   # transformação memória-segura (in-place)
    library(readr)
})

TOP_N <- 10   # grupos mantidos por par (from,to) — bate com o top_n do app

################################################################################
# 2. CARGA CRUA (larga: 1 linha por município×from×to, janelas em colunas)
################################################################################

dat <- load_mapbiomas(
    dataset   = "mapbiomas_transition",
    raw_data  = TRUE,           # <- crua de propósito (ver cabeçalho)
    geo_level = "municipality"
)
setDT(dat)

# Janelas ANUAIS: nome "AAAA_AAAA" com diferença de 1 ano (para o estado).
tcols  <- grep("^[0-9]{4}_[0-9]{4}$", names(dat), value = TRUE)
annual <- tcols[vapply(strsplit(tcols, "_"), function(a)
    as.integer(a[2]) - as.integer(a[1]) == 1L, logical(1))]

# Janelas QUINQUENAIS na grade de 1985 (para o município). Só as que existem.
quinq <- intersect(
    c("1985_1990", "1990_1995", "1995_2000", "2000_2005",
      "2005_2010", "2010_2015", "2015_2020"),
    names(dat)
)

################################################################################
# 3. REDUÇÃO EM FORMATO LARGO (antes de derreter — mantém a memória baixa)
################################################################################

# municípios da Amazônia Legal (código IBGE)
amz <- as.data.table(datazoom.amazonia::municipalities)[legal_amazon == 1,
                                                        .(geocode = code_muni)]

# remove prefixo numérico ("3.3. Forest Plantation" -> "Forest Plantation")
strip_prefix <- function(x) sub("^[0-9]+(\\.[0-9]+)*\\.?\\s*", "", as.character(x))

# só Amazônia + só as colunas necessárias (geo, classes nível 4, janelas usadas)
use_cols <- union(annual, quinq)
d <- dat[geocode %in% amz$geocode,
         c("state", "municipality", "geocode",
           "class_level_4_from", "class_level_4_to", use_cols), with = FALSE]
rm(dat); gc()

# classes em inglês, sem prefixo
d[, from := strip_prefix(class_level_4_from)]
d[, to   := strip_prefix(class_level_4_to)]
d[, c("class_level_4_from", "class_level_4_to") := NULL]

# (2) só transições reais
d <- d[from != to]

################################################################################
# 4. DERRETE (long enxuto; descarta zeros da matriz esparsa)
################################################################################

long <- melt(
    d,
    id.vars       = c("state", "municipality", "geocode", "from", "to"),
    measure.vars  = use_cols,
    variable.name = "time_raw",
    value.name    = "value"
)
rm(d); gc()

long <- long[!is.na(value) & value > 0]
long[, time := gsub("_", " - ", as.character(time_raw))]   # "1985_1986" -> "1985 - 1986"
long[, time_raw := NULL]

# rótulos de tempo por granularidade (para filtrar e completar a grade)
annual_times <- sort(gsub("_", " - ", annual))
quinq_times  <- sort(gsub("_", " - ", quinq))

################################################################################
# 5. PRÉ-SELEÇÃO TOP 10 (por par from,to) + GRADE COMPLETA
# O app tem dois rankings: por janela (área daquela janela) e ACUMULADO (soma
# corrente). Um grupo pode nunca ser top N numa janela isolada mas entrar no top
# N acumulado (transições constantes e moderadas somam). Se guardássemos só o top
# por janela, o ranking acumulado sairia incompleto. Então:
#   - completa a grade sobre TODOS os grupos do par (temporário, só p/ ranquear);
#   - calcula rank por janela (value) E rank acumulado (cumsum) em cada janela;
#   - mantém quem entra no top N em ALGUMA janela por QUALQUER um dos dois;
#   - devolve a grade completa (0 nas janelas sem transição) desses grupos, o que
#     mantém os `id`s estáveis na animação e o cumsum contínuo no app.
################################################################################

top_n_grid <- function(DT, all_times) {
    # grade completa sobre TODOS os grupos do par (só para ranquear corretamente)
    allg <- unique(DT[, .(from, to, group)])
    full <- allg[, .(time = all_times), by = .(from, to, group)]
    full <- DT[full, on = .(from, to, group, time)]     # traz value (NA onde falta)
    full[is.na(value), value := 0]
    setorder(full, from, to, group, time)

    full[, cum    := cumsum(value),                  by = .(from, to, group)]
    full[, rk_win := frank(-value, ties.method = "min"), by = .(from, to, time)]
    full[, rk_cum := frank(-cum,   ties.method = "min"), by = .(from, to, time)]

    # top N por janela OU por acumulado
    S <- unique(full[rk_win <= TOP_N | rk_cum <= TOP_N, .(from, to, group)])

    out <- full[S, on = .(from, to, group), .(time, group, from, to, value)]
    setcolorder(out, c("time", "group", "from", "to", "value"))
    out[]
}

################################################################################
# 6. DATASET MUNICIPAL — QUINQUENAL (group = "Município - Estado")
################################################################################

munic <- long[time %in% quinq_times,
              .(value = sum(value, na.rm = TRUE)),
              by = .(time, group = paste(municipality, "-", state), from, to)]
munic <- top_n_grid(munic, quinq_times)
munic[, value := round(value, 2)]

################################################################################
# 7. DATASET ESTADUAL — ANUAL (group = estado; área somada por estado)
################################################################################

est <- long[time %in% annual_times,
            .(value = sum(value, na.rm = TRUE)),
            by = .(time, group = state, from, to)]
est <- top_n_grid(est, annual_times)
est[, value := round(value, 2)]

################################################################################
# 7b. INTERSEÇÃO DE PARES (item 3): mantém só os pares (from,to) presentes nos
# DOIS níveis, para o toggle Estado↔Município nunca abrir vazio. Preserva a
# granularidade (est anual, munic quinquenal); só descarta pares que uma das
# granularidades não enxerga.
################################################################################

pares_comuns <- merge(unique(est[, .(from, to)]),
                      unique(munic[, .(from, to)]),
                      by = c("from", "to"))

est   <- est[  pares_comuns, on = .(from, to), nomatch = NULL]
munic <- munic[pares_comuns, on = .(from, to), nomatch = NULL]

setorder(munic, from, to, group, time)
setorder(est,   from, to, group, time)

saveRDS(as.data.frame(munic), "data/mapbiomas_transicao_rk_munic.rds")
saveRDS(as.data.frame(est),   "data/mapbiomas_transicao_rk_est.rds")

################################################################################
# 8. DICIONÁRIOS (PT / EN) — mínimos: time (slider), group (cor), value (x/rank)
# As classes from/to NÃO entram no dicionário: o app pega as opções de
# unique(from)/unique(to) e traduz via data/mapbiomas_legenda.csv.
################################################################################

build_dics_rk <- function(out_pt, out_en) {
    mk <- function(idioma) {
        data.table(
            var          = c("time", "group", "value"),
            x            = c(FALSE, FALSE, TRUE),   # value é o eixo do ranking
            y            = c(FALSE, FALSE, FALSE),
            color        = c(FALSE, TRUE, FALSE),
            size         = c(FALSE, FALSE, FALSE),
            slider       = c(TRUE, FALSE, FALSE),
            label        = if (idioma == "pt") c("Ano", "Grupo", "Área transicionada")
                           else                c("Year", "Group", "Transitioned area"),
            desc         = if (idioma == "pt") c("Ano", "Grupo", "Área transicionada")
                           else                c("Year", "Group", "Transitioned area"),
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

build_dics_rk("data/mapbiomas_transicao_rk_dic.csv",
              "data/mapbiomas_transicao_rk_dic_en.csv")

################################################################################
# 9. CHECAGENS RÁPIDAS (rode e cole a saída)
################################################################################

cat("Janelas -> EST (anual):", length(annual_times),
    "| MUNIC (quinquenal):", length(quinq_times), "\n")
cat("Quinquenal:", paste(quinq_times, collapse = " ; "), "\n")
cat("Pares comuns aos dois níveis (item 3):", nrow(pares_comuns),
    "| iguais em est e munic?",
    uniqueN(paste(est$from, est$to)) == uniqueN(paste(munic$from, munic$to)), "\n")
cat("EST  -> pares from/to:", uniqueN(paste(est$from, est$to)),
    "| estados:", uniqueN(est$group), "| linhas:", nrow(est), "\n")
cat("MUNIC-> pares from/to:", uniqueN(paste(munic$from, munic$to)),
    "| municipios:", uniqueN(munic$group), "| linhas:", nrow(munic), "\n")
cat("Grupos por par (munic) - resumo (nº de municípios plotados por par):\n")
print(summary(munic[, uniqueN(group), by = .(from, to)]$V1))

# classes from/to sem correspondência na legenda oficial (traduziriam via fallback)
if (file.exists("data/mapbiomas_legenda.csv")) {
    leg <- readr::read_csv("data/mapbiomas_legenda.csv", show_col_types = FALSE)
    classes <- union(unique(est$from), unique(est$to))
    faltam  <- setdiff(classes, leg$nome_en)
    cat("Classes from/to fora da legenda:",
        if (length(faltam)) paste(faltam, collapse = ", ") else "(nenhuma)", "\n")
}
