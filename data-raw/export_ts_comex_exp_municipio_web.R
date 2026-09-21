############################################################
# Export static JSON for the JS rebuild of app_ts_comex_exp_municipio
#
# Reuses the same source .rds files the Shiny app read (data/comex_exp_munic_sh2.rds,
# data/comex_exp_munic_sec.rds — built by data-raw/comex.R) rather than
# recomputing anything from the raw trade data. Writes static files instead
# of feeding a Shiny session. Output goes to web/ts_comex_exp_municipio/data/,
# consumed by app.js.
#
# Two product-category aggregations, matching a toggle the original Shiny
# app offered (label_agg = "Selecione agregação do produto") that the first
# pass of this rebuild dropped: SEC (22 broad sections) and SH2 (97 more
# granular chapters). Every SEC-level output has an SH2-level counterpart
# with an _sh2 suffix, built by the same generic export_aggregation()
# function below rather than duplicated code — the two .rds files
# (comex_exp_munic_sec.rds / comex_exp_munic_sh2.rds) have an identical
# shape (time, group, <municipality columns>, "Amazônia Legal"), just a
# different `group` taxonomy.
#
# Run from repo root: Rscript data-raw/export_ts_comex_exp_municipio_web.R
############################################################

library(dplyr)
library(tidyr)
library(jsonlite)
library(data.table)

out_dir <- "web/ts_comex_exp_municipio/data"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

year_inicio <- 1997
year_final <- 2025

# ---- Product dictionary + composition + per-municipality composition for
# ONE aggregation level (SEC or SH2). Called once per level below. ----
#
# dic_file_prefix: the *transposed* dictionary ("sec_munic"/"sh2_munic", not
# "munic_sec"/"munic_sh2") — its `var` column holds the PT product/category
# name (matching `group` in the .rds) and `label` holds the translation,
# same convention the original Shiny app used for translating `group`.
# A handful of `group` values have no dictionary row (a stray escaped-quote
# variant of one long category name, and "Seda"/silk entirely) — rather
# than treat that as an error, those fall back to the raw PT name in both
# languages, same graceful-degradation the rest of this app already uses
# for any dictionary miss (see productLabel() in app.js).

export_aggregation <- function(level, rds_file, dic_file_prefix) {
  munic <- readRDS(rds_file)
  munic_cols <- setdiff(colnames(munic), c("time", "group", "Amazônia Legal"))

  # Region-wide composition ("Amazônia Legal" column only, produto x ano) —
  # drives Composição's region-wide scope.
  composition <- munic %>%
    transmute(produto = group, ano = as.integer(time), valor = round(`Amazônia Legal`)) %>%
    arrange(produto, ano)
  write_json(composition, file.path(out_dir, sprintf("composition_%s.json", level)),
             dataframe = "rows", auto_unbox = TRUE)

  # Per-municipality composition — full municipio x produto x year grid is
  # sparse (~7-11% non-zero for this trade data), so exported as a compact
  # index-referencing array rather than one JSON object per cell:
  # municipios/produtos give the lookup tables, cells is
  # [municipio_idx, produto_idx, ano, valor] with zero-value cells dropped.
  # Drives both Composição's per-municipality scope AND (inverted client-side
  # in app.js) Ranking/Tendências' category filters — same underlying data,
  # read by municipality in one case and by category in the other.
  munic_produto_long <- munic %>%
    select(time, group, all_of(munic_cols)) %>%
    pivot_longer(all_of(munic_cols), names_to = "municipio", values_to = "valor") %>%
    filter(valor > 0)

  municipios_idx <- sort(unique(munic_produto_long$municipio))
  produtos_idx <- sort(unique(munic_produto_long$group))

  muni_composition <- list(
    municipios = municipios_idx,
    produtos = produtos_idx,
    cells = munic_produto_long %>%
      transmute(
        municipio_idx = match(municipio, municipios_idx) - 1L,
        produto_idx = match(group, produtos_idx) - 1L,
        ano = as.integer(time),
        valor = round(valor)
      ) %>%
      as.matrix() %>%
      unname()
  )
  write_json(muni_composition, file.path(out_dir, sprintf("municipality_composition_%s.json", level)),
             auto_unbox = TRUE)

  # Product/category dictionary (PT/EN labels), covering every produto_idx
  # value actually present above — falls back to the raw PT name (both
  # languages) for the rare dictionary miss instead of dropping the category.
  read_dic <- function(path) {
    fread(path, encoding = "UTF-8") %>%
      filter(!var %in% c("time", "group")) %>%
      transmute(var, label)
  }
  dic_pt <- read_dic(sprintf("data/comex_exp_%s_dic.csv", dic_file_prefix))
  dic_en <- read_dic(sprintf("data/comex_exp_%s_en_dic.csv", dic_file_prefix))

  make_products <- function(dic) {
    tibble(var = produtos_idx) %>%
      left_join(dic, by = "var") %>%
      transmute(var, label = coalesce(label, var))
  }
  products <- list(pt = make_products(dic_pt), en = make_products(dic_en))
  write_json(products, file.path(out_dir, sprintf("products_%s.json", level)),
             dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)

  cat(sprintf(" - %d categories, %d nonzero municipio x categoria x ano cells (%s)\n",
              length(produtos_idx), nrow(munic_produto_long), level))
}

export_aggregation("sec", "data/comex_exp_munic_sec.rds", "sec_munic")
export_aggregation("sh2", "data/comex_exp_munic_sh2.rds", "sh2_munic")

# ---- Municipality totals (all products combined), one row per
# municipality x year — drives the ranked bar chart, sparklines, and the
# dumbbell (year-over-year change) view. Aggregation-independent (summing
# everything nets out the category split), so read once from the SEC file;
# "Amazônia Legal" is the region-wide aggregate column already present in
# the source file, held out into its own small series (region_totals.json)
# rather than mixed into the municipality ranking, since it would trivially
# rank #1 every year. ----

munic_sec <- readRDS("data/comex_exp_munic_sec.rds")
munic_cols <- setdiff(colnames(munic_sec), c("time", "group", "Amazônia Legal"))

munic_totals <- munic_sec %>%
  select(time, all_of(munic_cols)) %>%
  group_by(time) %>%
  summarise(across(all_of(munic_cols), sum), .groups = "drop") %>%
  pivot_longer(-time, names_to = "municipio", values_to = "valor") %>%
  transmute(municipio, ano = as.integer(time), valor = round(valor)) %>%
  arrange(municipio, ano)

write_json(munic_totals, file.path(out_dir, "municipality_totals.json"),
           dataframe = "rows", auto_unbox = TRUE)

region_totals <- munic_sec %>%
  group_by(time) %>%
  summarise(valor = round(sum(`Amazônia Legal`)), .groups = "drop") %>%
  transmute(ano = as.integer(time), valor)

write_json(region_totals, file.path(out_dir, "region_totals.json"),
           dataframe = "rows", auto_unbox = TRUE)

# ---- App metadata (year range) ----

dictionary <- list(year_inicio = year_inicio, year_final = year_final)

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
    " -", file.path(out_dir, "dictionary.json"), "\n")
