############################################################
# Export static GeoJSON + JSON for a serverless JS/Leaflet rebuild of
# app_map_comex_exp_sh4_sel.
#
# Geometry export mirrors data-raw's app_map_dz_munic_cempre precedent
# exactly (same global/*.rds sources, same crs 4326 transform) — that map
# already covers the same 772-municipality Legal Amazon set keyed by the
# same cod_ibge, so this is proven, not new.
#
# Attributes come from data/comex_exp_munic_sh4_sel.rds (built by
# data-raw/comex_munic_sel.R), which already carries: cod_ibge, time,
# floresta (TRUE = top product computed among a curated 16-code
# "forest-compatible" list only, FALSE = top product among ALL products),
# produto_principal/lab (the top SH4 product's name), maximo_produto (NOT
# a dollar value — % of the Legal Amazon's total exports of that specific
# product that came from this municipality that year), and nome_sh2 (the
# HS2-level category of that top product, used for choropleth color).
#
# The "ratio" mode (forest-dominant vs. not) from the original Shiny app
# is computed client-side in app.js from the forest+all rows already
# loaded here, rather than exported as a third redundant dataset.
#
# Run from repo root: Rscript data-raw/export_map_comex_exp_sh4_sel_web.R
############################################################

library(dplyr)
library(sf)
library(jsonlite)

out_dir <- "web/map_comex_exp_sh4_sel/data"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Geometry: Legal Amazon municipalities + boundary overlays ----
# Same source + transform as app_map_dz_munic_cempre's export — see that
# app's data-raw/export_map_dz_munic_cempre_web.R for the original.

munic_geo <- readr::read_rds("global/munic_shapefile.rds") %>%
  filter(legal_amazon == 1) %>%
  st_make_valid() %>%
  transmute(cod_ibge = as.character(municipality_code), geometry = geom) %>%
  st_transform(crs = 4326)

write_sf(munic_geo, file.path(out_dir, "municipalities.geojson"),
         driver = "GeoJSON", delete_dsn = TRUE)

states_boundary <- readr::read_rds("global/states_boundary.rds") %>%
  st_transform(crs = 4326)
write_sf(states_boundary, file.path(out_dir, "states_boundary.geojson"),
         driver = "GeoJSON", delete_dsn = TRUE)

legal_amazon_boundary <- readr::read_rds("global/legal_amazon_boundary.rds") %>%
  st_transform(crs = 4326)
write_sf(legal_amazon_boundary, file.path(out_dir, "legal_amazon_boundary.geojson"),
         driver = "GeoJSON", delete_dsn = TRUE)

# ---- Attributes ----

sel <- readRDS("data/comex_exp_munic_sh4_sel.rds") %>% st_drop_geometry()

municipios_idx <- munic_geo$cod_ibge # fixed order matching the geojson's own feature order
municipio_meta <- sel %>%
  mutate(cod_ibge = as.character(cod_ibge)) %>%
  distinct(cod_ibge, nm_municip, uf) %>%
  filter(!is.na(nm_municip))

# Top-8 HS2 categories by frequency as the top product across all
# municipality-years; anything outside that set folds into "Outros" at
# render time (categoria_idx = -1) — same convention as every other
# categorical chart in this app family, and necessary here regardless:
# 71 distinct categories appear, nowhere near chart-safe.
categoria_counts <- sel %>%
  filter(!is.na(nome_sh2)) %>%
  count(nome_sh2, sort = TRUE)
categorias_idx <- head(categoria_counts$nome_sh2, 8)

# Distinct top-product labels (already truncated to 60 chars upstream, in
# comex_munic_sel.R) — referenced by index instead of repeating ~240
# distinct strings across every row.
produtos_idx <- sel %>% filter(!is.na(lab)) %>% distinct(lab) %>% pull(lab) %>% sort()

cells <- sel %>%
  filter(!is.na(produto_principal)) %>%
  mutate(cod_ibge = as.character(cod_ibge)) %>%
  transmute(
    municipio_idx = match(cod_ibge, municipios_idx) - 1L,
    ano = as.integer(time),
    floresta = as.integer(floresta),
    categoria_idx = ifelse(nome_sh2 %in% categorias_idx, match(nome_sh2, categorias_idx) - 1L, -1L),
    produto_idx = match(lab, produtos_idx) - 1L,
    valor = round(maximo_produto, 2)
  )

map_data <- list(
  municipios = municipio_meta %>%
    arrange(match(cod_ibge, municipios_idx)) %>%
    transmute(cod_ibge, nome = nm_municip, uf),
  categorias = categorias_idx,
  produtos = produtos_idx,
  cells = cells %>% as.matrix() %>% unname()
)

write_json(map_data, file.path(out_dir, "map_data.json"), auto_unbox = TRUE)

# ---- App metadata ----

dictionary <- list(
  year_inicio = min(sel$time, na.rm = TRUE),
  year_final = max(sel$time, na.rm = TRUE)
)
write_json(dictionary, file.path(out_dir, "dictionary.json"), auto_unbox = TRUE, pretty = TRUE)

cat("Exported:\n",
    " -", file.path(out_dir, "municipalities.geojson"), "\n",
    " -", file.path(out_dir, "states_boundary.geojson"), "\n",
    " -", file.path(out_dir, "legal_amazon_boundary.geojson"), "\n",
    " -", file.path(out_dir, "map_data.json"), "\n",
    " -", file.path(out_dir, "dictionary.json"), "\n")
