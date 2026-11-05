############################################################
# Export static GeoJSON + JSON for the JS PoC of app_map_dz_munic_cempre
#
# Reuses the same join logic as scripts/map_dz_munic_cempre/server.R
# (geometry + datazoom.amazonia::municipalities + CEMPRE attributes),
# but writes static files instead of feeding a Shiny session. Output
# goes to web/map_dz_munic_cempre/data/, consumed by app.js.
#
# Run from repo root: Rscript web/_export/export_cempre_mapa.R
############################################################

library(dplyr)
library(sf)
library(jsonlite)

out_dir <- "web/map_dz_munic_cempre/data"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Geometry: Legal Amazon municipalities ----
#
# NOTE: not simplified for this PoC (rmapshaper needs the geojsonio
# package, not installed locally, and full resolution is already only
# ~1MB for 772 polygons). If this becomes the real template, revisit
# topology-aware simplification (rmapshaper::ms_simplify, after
# installing geojsonio) so shared municipal borders don't crack apart
# the way sf::st_simplify would produce independently per polygon.

munic_geo <- readr::read_rds("global/munic_shapefile.rds") %>%
  filter(legal_amazon == 1) %>%
  st_make_valid() %>%
  transmute(cod_ibge = as.character(municipality_code), geometry = geom) %>%
  st_transform(crs = 4326)

write_sf(munic_geo, file.path(out_dir, "municipalities.geojson"),
         driver = "GeoJSON", delete_dsn = TRUE)

# ---- Boundary overlays (state lines, Legal Amazon outline) ----

states_boundary <- readr::read_rds("global/states_boundary.rds") %>%
  st_transform(crs = 4326)
write_sf(states_boundary, file.path(out_dir, "states_boundary.geojson"),
         driver = "GeoJSON", delete_dsn = TRUE)

legal_amazon_boundary <- readr::read_rds("global/legal_amazon_boundary.rds") %>%
  st_transform(crs = 4326)
write_sf(legal_amazon_boundary, file.path(out_dir, "legal_amazon_boundary.geojson"),
         driver = "GeoJSON", delete_dsn = TRUE)

# ---- Attributes: municipality metadata + CEMPRE variables, all years ----

munic_meta <- datazoom.amazonia::municipalities %>%
  transmute(
    cod_ibge = as.character(code_muni),
    nm_municip = municipality_mapbiomas,
    estado = abbrev_state
  )

df_attrs <- readRDS("data/cempre_municipality_dza.rds") %>%
  mutate(cod_ibge = as.character(cod_ibge))

year_inicio <- 2006
year_final <- 2020
all_years <- year_inicio:year_final

complete_grid <- tidyr::expand_grid(cod_ibge = munic_geo$cod_ibge, ano = all_years)

attrs <- complete_grid %>%
  left_join(df_attrs, by = c("cod_ibge", "ano")) %>%
  left_join(munic_meta, by = "cod_ibge") %>%
  select(cod_ibge, ano, nm_municip, estado,
         cempre_n_empresas_organizacoes, cempre_n_ocupados,
         cempre_n_ocupados_assalariados, cempre_salarios_remuneracoes)

write_json(attrs, file.path(out_dir, "attributes.json"),
           dataframe = "rows", na = "null", auto_unbox = TRUE)

# ---- Variable dictionary (pt/en labels, units) for the 4 CEMPRE vars ----

dic_pt <- data.table::fread("data/dz_munic_dic.csv", encoding = "UTF-8") %>%
  filter(var_group == "IBGE - CEMPRE") %>%
  transmute(var, label, unidade)

dic_en <- data.table::fread("data/dz_munic_dic_en.csv", encoding = "UTF-8") %>%
  filter(var_group == "IBGE - CEMPRE") %>%
  transmute(var, label, unidade)

dictionary <- list(
  pt = dic_pt,
  en = dic_en,
  year_inicio = year_inicio,
  year_final = year_final
)

write_json(dictionary, file.path(out_dir, "dictionary.json"),
           dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)

cat("Exported:\n",
    " -", file.path(out_dir, "municipalities.geojson"), "\n",
    " -", file.path(out_dir, "states_boundary.geojson"), "\n",
    " -", file.path(out_dir, "legal_amazon_boundary.geojson"), "\n",
    " -", file.path(out_dir, "attributes.json"), "\n",
    " -", file.path(out_dir, "dictionary.json"), "\n")
