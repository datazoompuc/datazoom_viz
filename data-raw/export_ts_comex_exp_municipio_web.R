############################################################
# Export static JSON for the JS rebuild of app_ts_comex_exp_municipio
#
# Reuses the same source .rds the Shiny app reads (data/comex_exp_munic_sh2.rds,
# data/comex_exp_munic_sec.rds — built by data-raw/comex.R) rather than
# recomputing anything from the raw trade data. Writes static files instead
# of feeding a Shiny session. Output goes to web/ts_comex_exp_municipio/data/,
# consumed by app.js.
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

# ---- Municipality totals (all products combined), one row per
# municipality x year — drives the ranked bar chart, sparklines, and the
# dumbbell (year-over-year change) view. "Amazônia Legal" is the region-wide
# aggregate column already present in the source file; held out into its
# own small series (region_totals.json) rather than mixed into the
# municipality ranking, since it would trivially rank #1 every year. ----

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

# ---- Region-wide product composition over time (SEC level — 22 categories,
# a sane number of bands for a stacked area chart; SH2's 97 chapters would
# be unreadable as stacked bands). One row per product x year, "Amazônia
# Legal" column only (the region total by product, not broken out by
# municipality) — drives the composition/stacked-area view. ----

composition <- munic_sec %>%
  transmute(produto = group, ano = as.integer(time), valor = round(`Amazônia Legal`)) %>%
  arrange(produto, ano)

write_json(composition, file.path(out_dir, "composition.json"),
           dataframe = "rows", auto_unbox = TRUE)

# ---- Product dictionary (PT/EN labels for the 22 SEC categories) ----
# comex_exp_sec_munic_dic.csv has var=PT product name (matches `group` in
# the .rds above), label=PT label; the _en_dic.csv counterpart has the same
# var but label=EN translation.

dic_pt <- fread("data/comex_exp_sec_munic_dic.csv", encoding = "UTF-8") %>%
  filter(!var %in% c("time", "group")) %>%
  transmute(var, label)

dic_en <- fread("data/comex_exp_sec_munic_en_dic.csv", encoding = "UTF-8") %>%
  filter(!var %in% c("time", "group")) %>%
  transmute(var, label)

products <- list(pt = dic_pt, en = dic_en)

write_json(products, file.path(out_dir, "products.json"),
           dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)

# ---- Per-municipality product composition (which categories each
# municipality exports, not just the region-wide total) — drives the
# municipality composition view. Full municipio x produto x year grid is
# 446 x 22 x 29 = 284,548 cells but only ~7% are non-zero (this trade data
# is extremely sparse), so it's exported as a compact index-referencing
# array rather than one JSON object per cell: municipios/produtos give the
# lookup tables, cells is [municipio_idx, produto_idx, ano, valor] with
# zero-value cells dropped entirely. produtos uses the same PT category
# strings as `group`/products.json's `var` field, so productLabel() in
# app.js resolves them without a separate lookup. ----

munic_produto_long <- munic_sec %>%
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

write_json(muni_composition, file.path(out_dir, "municipality_composition.json"),
           auto_unbox = TRUE)

# ---- App metadata (year range) ----

dictionary <- list(year_inicio = year_inicio, year_final = year_final)

write_json(dictionary, file.path(out_dir, "dictionary.json"),
           auto_unbox = TRUE, pretty = TRUE)

cat("Exported:\n",
    " -", file.path(out_dir, "municipality_totals.json"), "\n",
    " -", file.path(out_dir, "region_totals.json"), "\n",
    " -", file.path(out_dir, "composition.json"), "\n",
    " -", file.path(out_dir, "municipality_composition.json"), "\n",
    " -", file.path(out_dir, "products.json"), "\n",
    " -", file.path(out_dir, "dictionary.json"), "\n")
