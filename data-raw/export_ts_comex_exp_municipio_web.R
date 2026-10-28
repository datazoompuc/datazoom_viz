############################################################
# Export static JSON for the JS rebuild of app_ts_comex_exp_municipio
#
# Reads ONE source: data/comex_exp_munic_base.rds, the long-format COMEX
# base built by data-raw/comex.R (see data-raw/README_data.md). One row per
# ano x SH4 x municipio x pais de destino, carrying valor_fob (US$ FOB
# nominal) and kg_liquido, with the PT/EN labels for product, chapter,
# section and country already joined in.
#
# This replaces the previous arrangement, where this script read several
# pre-aggregated wide matrices (comex_exp_munic_sec.rds,
# comex_exp_munic_sh2.rds, ...) plus four dictionary CSVs, and a second
# script read comex_exp_sh4_munic.rds for the product ranking. Every one of
# those outputs is a different group_by over this single base, so they are
# all derived here in one pass. See data-raw/ARQUITETURA_dados_web.md for
# why the split is by dependency rather than by visualisation — the map
# export stays separate because it needs `sf`.
#
# The one thing the base does NOT carry is the municipality NAME: it has
# cod_municipio (IBGE code) and uf, while every other dimension (pais, SH4,
# SH2, sec) ships its own PT/EN label. The app keys municipalities by the
# "Nome - UF" string, so the name is joined from
# data/auxiliar_cod_municipais.rds. That file is marked for deletion on the
# comex-deflator-limpeza branch; if it goes away, the base needs a
# municipio name column instead (one column, consistent with how pais_pt
# and sh4_pt already work).
#
# Run from repo root: Rscript data-raw/export_ts_comex_exp_municipio_web.R
############################################################

library(dplyr)
library(tidyr)
library(jsonlite)

out_dir <- "web/ts_comex_exp_municipio/data"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

base <- readRDS("data/comex_exp_munic_base.rds")

# ---- Municipality names ----
# Joined, not derived: datazoom.amazonia::municipalities carries only
# accent-stripped names ("Acailandia"), which would silently rename 212 of
# the 450 municipalities and break every saved URL that names one.
municipios_aux <- readRDS("data/auxiliar_cod_municipais.rds") %>%
  transmute(cod_municipio = as.character(codigo), municipio = nome)

base <- base %>%
  mutate(cod_municipio = as.character(cod_municipio)) %>%
  left_join(municipios_aux, by = "cod_municipio")

faltando <- sum(is.na(base$municipio))
if (faltando > 0) {
  stop(sprintf("%d linhas sem nome de municipio — auxiliar_cod_municipais.rds desatualizado?", faltando))
}

# The measure every output below is built on. kg_liquido is already in the
# base and the whole pipeline is written against this one name, so adding a
# quantity version later is a parameter change here, not a rewrite.
MEDIDA <- "valor_fob"
base$valor <- base[[MEDIDA]]

# ---- Year range and partial years ----
# The base can end on an incomplete year (2026 has 9 months). Shipping that
# without saying so makes every chart show a drop that is an artefact of the
# calendar, not of trade: 2026 at 9 months is 14% BELOW 2025, while the same
# 9 months annualised are 14% ABOVE it. The app needs enough metadata to
# label the partial year and to open on the last complete one. Nothing is
# annualised or extrapolated here — that would be inventing data.
anos_meta <- base %>%
  distinct(ano, n_meses, ano_parcial) %>%
  arrange(ano)

year_inicio <- min(anos_meta$ano)
year_final <- max(anos_meta$ano)
completos <- anos_meta$ano[!anos_meta$ano_parcial]
year_final_completo <- if (length(completos)) max(completos) else year_final

parciais <- anos_meta %>% filter(ano_parcial)
anos_parciais <- if (nrow(parciais)) {
  setNames(as.list(as.integer(parciais$n_meses)), as.character(parciais$ano))
} else {
  setNames(list(), character(0))
}

# ---- Per-aggregation outputs (SEC and SH2) ----
#
# Both levels are the same three outputs over the same base, differing only
# in which column carries the category — hence one function called twice
# rather than duplicated blocks. The category KEY stays the Portuguese name
# (not the code), because that is what the app already keys on and what
# products_*.json maps to a translated label; switching to codes would be a
# gratuitous breaking change.
export_aggregation <- function(level, col_pt, col_en) {
  # Summing over cod_pais AND cod_sh4: the base is finer than this view
  # needs, so collapse to municipio x categoria x ano first.
  por_municipio <- base %>%
    group_by(municipio, produto = .data[[col_pt]], ano) %>%
    summarise(valor = sum(valor), .groups = "drop") %>%
    filter(valor > 0)

  # Region-wide composition: one more collapse, over municipality.
  composition <- por_municipio %>%
    group_by(produto, ano) %>%
    summarise(valor = round(sum(valor)), .groups = "drop") %>%
    arrange(produto, ano)

  write_json(composition, file.path(out_dir, sprintf("composition_%s.json", level)),
             dataframe = "rows", auto_unbox = TRUE)

  # Sparse index-referencing format: the municipio x categoria x ano grid is
  # 6.3% dense at SEC and 2.3% at SH2, so the full grid is mostly zeros and
  # repeating names per cell dominates the file. Lookup arrays plus
  # [municipio_idx, produto_idx, ano, valor] with zeros dropped is ~28x
  # smaller at SH2 than the same data as a nested object.
  municipios_idx <- sort(unique(por_municipio$municipio))
  produtos_idx <- sort(unique(por_municipio$produto))

  muni_composition <- list(
    municipios = municipios_idx,
    produtos = produtos_idx,
    cells = por_municipio %>%
      transmute(
        municipio_idx = match(municipio, municipios_idx) - 1L,
        produto_idx = match(produto, produtos_idx) - 1L,
        ano = as.integer(ano),
        valor = round(valor)
      ) %>%
      as.matrix() %>%
      unname()
  )
  write_json(muni_composition, file.path(out_dir, sprintf("municipality_composition_%s.json", level)),
             auto_unbox = TRUE)

  # PT/EN labels for every category actually present. Both come from the
  # base now; the four dictionary CSVs this used to read are gone.
  dic <- base %>%
    distinct(var = .data[[col_pt]], label_en = .data[[col_en]]) %>%
    filter(var %in% produtos_idx) %>%
    arrange(var)

  products <- list(
    pt = dic %>% transmute(var, label = var),
    en = dic %>% transmute(var, label = coalesce(label_en, var))
  )
  write_json(products, file.path(out_dir, sprintf("products_%s.json", level)),
             dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)

  cat(sprintf(" - %d categorias, %d celulas nao-zero (%s)\n",
              length(produtos_idx), nrow(por_municipio), level))
}

export_aggregation("sec", "sec_pt", "sec_en")
export_aggregation("sh2", "sh2_pt", "sh2_en")

# ---- Municipality and region totals (all products, all destinations) ----

munic_totals <- base %>%
  group_by(municipio, ano) %>%
  summarise(valor = round(sum(valor)), .groups = "drop") %>%
  arrange(municipio, ano)

write_json(munic_totals, file.path(out_dir, "municipality_totals.json"),
           dataframe = "rows", auto_unbox = TRUE)

region_totals <- base %>%
  group_by(ano) %>%
  summarise(valor = round(sum(valor)), .groups = "drop") %>%
  arrange(ano)

write_json(region_totals, file.path(out_dir, "region_totals.json"),
           dataframe = "rows", auto_unbox = TRUE)

# ---- SH4 product ranking ----
# Lazily fetched by the app (~1.7MB), so it stays its own file even though
# it is generated here: file splitting follows what the browser needs, which
# is a separate decision from how many scripts there are.

sh4_long <- base %>%
  group_by(municipio, produto_code = cod_sh4, ano) %>%
  summarise(valor = sum(valor), .groups = "drop") %>%
  filter(valor > 0)

sh4_municipios <- sort(unique(sh4_long$municipio))
sh4_codes <- sort(unique(sh4_long$produto_code))

sh4_labels <- base %>%
  distinct(code = cod_sh4, label_pt = sh4_pt, label_en = sh4_en) %>%
  filter(code %in% sh4_codes) %>%
  arrange(code)

produtos <- lapply(seq_len(nrow(sh4_labels)), function(i) {
  list(code = sh4_labels$code[i],
       label_pt = sh4_labels$label_pt[i],
       label_en = sh4_labels$label_en[i])
})

product_ranking <- list(
  municipios = sh4_municipios,
  produtos = produtos,
  cells = sh4_long %>%
    transmute(
      produto_idx = match(produto_code, sh4_codes) - 1L,
      municipio_idx = match(municipio, sh4_municipios) - 1L,
      ano = as.integer(ano),
      valor = round(valor)
    ) %>%
    as.matrix() %>%
    unname()
)

write_json(product_ranking, file.path(out_dir, "product_ranking.json"), auto_unbox = TRUE)

# ---- App metadata ----

dictionary <- list(
  year_inicio = year_inicio,
  year_final = year_final,
  # Last year with 12 months of data. The app opens here rather than on
  # year_final, so the default view is never a partial year.
  year_final_completo = year_final_completo,
  # ano -> meses publicados, for the years that are incomplete.
  anos_parciais = anos_parciais
)

write_json(dictionary, file.path(out_dir, "dictionary.json"),
           auto_unbox = TRUE, pretty = TRUE)

cat("Exported:\n",
    " -", file.path(out_dir, "municipality_totals.json"), "\n",
    " -", file.path(out_dir, "region_totals.json"), "\n",
    " -", file.path(out_dir, "composition_sec.json"), "\n",
    " -", file.path(out_dir, "composition_sh2.json"), "\n",
    " -", file.path(out_dir, "municipality_composition_sec.json"), "\n",
    " -", file.path(out_dir, "municipality_composition_sh2.json"), "\n",
    " -", file.path(out_dir, "products_sec.json"), "\n",
    " -", file.path(out_dir, "products_sh2.json"), "\n",
    " -", file.path(out_dir, "product_ranking.json"), "\n",
    " -", file.path(out_dir, "dictionary.json"), "\n")
cat(sprintf("\nAnos: %d-%d (ultimo completo: %d)\n", year_inicio, year_final, year_final_completo))
if (length(anos_parciais)) {
  for (a in names(anos_parciais)) cat(sprintf(" - %s e parcial: %d meses\n", a, anos_parciais[[a]]))
}
