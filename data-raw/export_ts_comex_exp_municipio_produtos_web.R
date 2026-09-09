############################################################
# Export static JSON for the "Por Produto" (product ranking) view of the
# JS rebuild of app_ts_comex_exp_municipio.
#
# Separate source from export_ts_comex_exp_municipio_web.R:
# comex_exp_sh4_munic.rds carries ~1,142 specific SH4-level product codes
# (vs. the 22 broad SEC categories used by the rest of this app) — the
# same data app_rk_comex_exp_munic_produtosamz uses to let a user pick one
# product and animate the top exporting municipalities over time. This
# reuses that idea as a 7th view here instead of keeping it a separate
# Shiny app; auxiliar_cod_sh4.rds supplies the code -> PT/EN name lookup
# (server.R for that app builds the same lookup at runtime rather than via
# comex_exp_sh4_munic_dic.csv, whose `var` values don't actually match
# comex_exp_sh4_munic.rds's column names).
#
# Run from repo root: Rscript data-raw/export_ts_comex_exp_municipio_produtos_web.R
############################################################

library(dplyr)
library(tidyr)
library(jsonlite)

out_dir <- "web/ts_comex_exp_municipio/data"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

munic_sh4 <- readRDS("data/comex_exp_sh4_munic.rds")
aux_sh4 <- readRDS("data/auxiliar_cod_sh4.rds")
aux_sh4$CO_SH4 <- sprintf("%04d", as.numeric(aux_sh4$CO_SH4))

prod_cols <- setdiff(colnames(munic_sh4), c("time", "group"))

# ---- Compact index-referencing export, same pattern as
# municipality_composition.json: the full municipio x produto x year grid
# is ~7.2M cells but 99% zero, so only nonzero cells (~70k) are shipped,
# referencing lookup tables instead of repeating names/codes per row. ----

long <- munic_sh4 %>%
  select(time, group, all_of(prod_cols)) %>%
  pivot_longer(all_of(prod_cols), names_to = "produto_code", values_to = "valor") %>%
  filter(valor > 0)

municipios_idx <- sort(unique(long$group))
produtos_present <- sort(unique(long$produto_code))

label_pt <- setNames(aux_sh4$NO_SH4_PT, aux_sh4$CO_SH4)
label_en <- setNames(aux_sh4$NO_SH4_EN, aux_sh4$CO_SH4)

produtos <- lapply(produtos_present, function(code) {
  list(code = code, label_pt = unname(label_pt[[code]]), label_en = unname(label_en[[code]]))
})

product_ranking <- list(
  municipios = municipios_idx,
  produtos = produtos,
  cells = long %>%
    transmute(
      produto_idx = match(produto_code, produtos_present) - 1L,
      municipio_idx = match(group, municipios_idx) - 1L,
      ano = as.integer(time),
      valor = round(valor)
    ) %>%
    as.matrix() %>%
    unname()
)

write_json(product_ranking, file.path(out_dir, "product_ranking.json"), auto_unbox = TRUE)

cat("Exported:\n -", file.path(out_dir, "product_ranking.json"), "\n")
