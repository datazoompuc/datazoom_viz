############################################################
# Export static JSON and GeoJSON for the JS rebuild of app_ts_comex_exp_municipio
#
# Reads ONE source for trade data: data/comex_exp_munic_base.rds, the long-format COMEX
# base built by data-raw/comex.R (see data-raw/README_comex_data.md). One row per
# ano x SH4 x municipio x pais de destino, carrying valor_fob (US$ FOB
# nominal) and kg_liquido, with the PT/EN labels for product, chapter,
# section and country already joined in.
#
# Geometry for the map view comes from global/*.rds shapefiles (munic_shapefile.rds,
# states_boundary.rds, legal_amazon_boundary.rds) and municipality metadata from
# datazoom.amazonia::municipalities.
#
# All views (Ranking, Composição, Tendências, Explorar, Variação e Mapa) are derived
# here in one pass directly from the single long base.
#
# Run from repo root: Rscript web/_export/export_comex_exp_municipio.R
############################################################

library(dplyr)
library(tidyr)
library(jsonlite)
library(sf)

out_dir <- "web/comex_exp_municipio/data"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

base <- readRDS("data/comex_exp_munic_base.rds")

# A base traz o nome do município desde o merge de nov/2026, então não há
# mais join com auxiliar nenhum. Falha alto se a coluna sumir, em vez de
# exportar JSON com null.
if (!"municipio" %in% names(base)) {
  stop("a base nao tem a coluna `municipio` — o export depende dela para as chaves do app")
}
faltando <- sum(is.na(base$municipio))
if (faltando > 0) {
  stop(sprintf("%d linhas sem nome de municipio na base", faltando))
}

# As duas medidas, com os nomes curtos que os JSON usam.
base <- base %>% mutate(valor = valor_fob, kg = kg_liquido)

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
    summarise(valor = sum(valor), kg = sum(kg), .groups = "drop") %>%
    filter(valor > 0 | kg > 0)

  # Region-wide composition: one more collapse, over municipality.
  composition <- por_municipio %>%
    group_by(produto, ano) %>%
    summarise(valor = round(sum(valor)), kg = round(sum(kg)), .groups = "drop") %>%
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
        valor = round(valor),
        kg = round(kg)
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

# ---- Destination country ----
#
# Same three outputs as a SEC/SH2 aggregation, with the destination country
# in the categorical slot instead of a product category. Kept as its own
# block (rather than a third export_aggregation call) only because the
# column names and output filenames differ; the shape is identical, which
# is what lets the app treat "pais" as just another level.
#
# Lazily fetched by the app: the municipio x pais x ano grid is 2.7% dense,
# so the sparse format matters even more here than for SH2.

por_pais_municipio <- base %>%
  group_by(municipio, pais = pais_pt, ano) %>%
  summarise(valor = sum(valor), kg = sum(kg), .groups = "drop") %>%
  filter(valor > 0 | kg > 0)

composition_pais <- por_pais_municipio %>%
  group_by(pais, ano) %>%
  summarise(valor = round(sum(valor)), kg = round(sum(kg)), .groups = "drop") %>%
  arrange(pais, ano)

write_json(composition_pais, file.path(out_dir, "composition_pais.json"),
           dataframe = "rows", auto_unbox = TRUE)

paises_idx <- sort(unique(por_pais_municipio$pais))
municipios_pais_idx <- sort(unique(por_pais_municipio$municipio))

muni_pais <- list(
  municipios = municipios_pais_idx,
  paises = paises_idx,
  cells = por_pais_municipio %>%
    transmute(
      municipio_idx = match(municipio, municipios_pais_idx) - 1L,
      pais_idx = match(pais, paises_idx) - 1L,
      ano = as.integer(ano),
      valor = round(valor),
      kg = round(kg)
    ) %>%
    as.matrix() %>%
    unname()
)
write_json(muni_pais, file.path(out_dir, "municipality_composition_pais.json"),
           auto_unbox = TRUE)

dic_pais <- base %>%
  distinct(var = pais_pt, label_en = pais_en) %>%
  filter(var %in% paises_idx) %>%
  arrange(var)

write_json(list(pt = dic_pais %>% transmute(var, label = var),
                en = dic_pais %>% transmute(var, label = coalesce(label_en, var))),
           file.path(out_dir, "paises.json"),
           dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)

cat(sprintf(" - %d paises, %d celulas nao-zero (pais)\n",
            length(paises_idx), nrow(por_pais_municipio)))

# ---- Municipality and region totals (all products, all destinations) ----

munic_totals <- base %>%
  group_by(municipio, ano) %>%
  summarise(valor = round(sum(valor)), kg = round(sum(kg)), .groups = "drop") %>%
  arrange(municipio, ano)

write_json(munic_totals, file.path(out_dir, "municipality_totals.json"),
           dataframe = "rows", auto_unbox = TRUE)

region_totals <- base %>%
  group_by(ano) %>%
  summarise(valor = round(sum(valor)), kg = round(sum(kg)), .groups = "drop") %>%
  arrange(ano)

write_json(region_totals, file.path(out_dir, "region_totals.json"),
           dataframe = "rows", auto_unbox = TRUE)

# ---- SH4 product ranking ----
# Lazily fetched by the app (~1.7MB), so it stays its own file even though
# it is generated here: file splitting follows what the browser needs, which
# is a separate decision from how many scripts there are.

sh4_long <- base %>%
  group_by(municipio, produto_code = cod_sh4, ano) %>%
  summarise(valor = sum(valor), kg = sum(kg), .groups = "drop") %>%
  filter(valor > 0 | kg > 0)

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
      valor = round(valor),
      kg = round(kg)
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

# ---- Map view export (GeoJSON + map_data.json) ----
#
# Derived directly from `base` and global/*.rds geometry.
# Attributes represent each municipality's top exported product (overall and among
# forest-compatible products), its FOB value, net weight in kg, and its relative
# percentage against Legal Amazon's total exports of that product.
map_out_dir <- file.path(out_dir, "map")
dir.create(map_out_dir, recursive = TRUE, showWarnings = FALSE)

munic_geo <- readr::read_rds("global/munic_shapefile.rds") %>%
  filter(legal_amazon == 1) %>%
  st_make_valid() %>%
  transmute(cod_ibge = as.character(municipality_code), geometry = geom) %>%
  st_transform(crs = 4326)

sf::write_sf(munic_geo, file.path(map_out_dir, "municipalities.geojson"),
             driver = "GeoJSON", delete_dsn = TRUE)

states_boundary <- readr::read_rds("global/states_boundary.rds") %>%
  st_transform(crs = 4326)
sf::write_sf(states_boundary, file.path(map_out_dir, "states_boundary.geojson"),
             driver = "GeoJSON", delete_dsn = TRUE)

legal_amazon_boundary <- readr::read_rds("global/legal_amazon_boundary.rds") %>%
  st_transform(crs = 4326)
sf::write_sf(legal_amazon_boundary, file.path(map_out_dir, "legal_amazon_boundary.geojson"),
             driver = "GeoJSON", delete_dsn = TRUE)

municipios_idx <- munic_geo$cod_ibge

muni_dz <- datazoom.amazonia::municipalities %>%
  filter(legal_amazon == 1) %>%
  transmute(cod_ibge = as.character(code_muni),
            nome = toupper(name_muni),
            uf = abbrev_state)

municipio_meta <- data.frame(cod_ibge = municipios_idx) %>%
  left_join(muni_dz, by = "cod_ibge")

sh4_floresta <- c("0301", "0302", "0303", "0304", "0305", "0306",
                  "0801", "0811", "0904", "1207", "1301", "1511",
                  "1515", "1801", "2008", "2009")

tot_prod_ano <- base %>%
  group_by(ano, cod_sh4) %>%
  summarise(tot_fob_amazonia = sum(valor_fob), .groups = "drop")

mun_prod_ano <- base %>%
  group_by(ano, cod_ibge = as.character(cod_municipio), cod_sh4, sh4_pt, sh2_pt) %>%
  summarise(
    valor_fob_mun = sum(valor_fob),
    kg_mun = sum(kg_liquido),
    .groups = "drop"
  ) %>%
  left_join(tot_prod_ano, by = c("ano", "cod_sh4")) %>%
  mutate(pct = (valor_fob_mun / tot_fob_amazonia) * 100)

top_all <- mun_prod_ano %>%
  group_by(ano, cod_ibge) %>%
  slice_max(order_by = valor_fob_mun, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(floresta = FALSE)

top_flor <- mun_prod_ano %>%
  filter(cod_sh4 %in% sh4_floresta) %>%
  group_by(ano, cod_ibge) %>%
  slice_max(order_by = valor_fob_mun, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(floresta = TRUE)

top_comb <- bind_rows(top_all, top_flor) %>%
  mutate(
    lab = ifelse(nchar(sh4_pt) > 60, paste0(substr(sh4_pt, 1, 59), "…"), sh4_pt),
    nome_sh2 = ifelse(nchar(sh2_pt) > 50, paste0(substr(sh2_pt, 1, 49), "…"), sh2_pt)
  )

# As 8 categorias da legenda saem da FREQUENCIA com que a categoria e o produto
# principal de um municipio, nao do valor exportado.
#
# Por valor parece mais coerente, ja que o produto principal e escolhido por FOB,
# e foi assim por um tempo. Mas o mapa colore MUNICIPIOS, entao as 8 cores
# precisam cobrir o maior numero de municipios possivel, e valor otimiza outra
# coisa: minerio de ferro domina em dolares (US$ 199 bi) sendo principal em so 74
# municipio-anos, enquanto madeira serrada sao 1023 municipio-anos e US$ 3,1 bi.
# Por valor, o modo "compativel com a floresta" ia de 11% para 84% dos
# municipio-anos em cinza, que e o que sobra para quem fica fora das 8.
#
#   por valor       cobre 30% das celulas, 86% do valor
#   por frequencia  cobre 57% das celulas, 36% do valor
#
# Se um dia o mapa passar a codificar valor no visual (circulo por municipio,
# tamanho pelo FOB), a conta muda e vale reavaliar.
categoria_counts <- top_comb %>%
  filter(!is.na(nome_sh2)) %>%
  count(nome_sh2, sort = TRUE)
categorias_idx <- head(categoria_counts$nome_sh2, 8)

produtos_idx <- top_comb %>%
  filter(!is.na(lab)) %>%
  distinct(lab) %>%
  pull(lab) %>%
  sort()

cells <- top_comb %>%
  transmute(
    municipio_idx = match(cod_ibge, municipios_idx) - 1L,
    ano = as.integer(ano),
    floresta = as.integer(floresta),
    categoria_idx = ifelse(nome_sh2 %in% categorias_idx, match(nome_sh2, categorias_idx) - 1L, -1L),
    produto_idx = match(lab, produtos_idx) - 1L,
    valor = round(pct, 4),
    fob = round(valor_fob_mun),
    kg = round(kg_mun)
  )

map_data <- list(
  municipios = municipio_meta,
  categorias = categorias_idx,
  produtos = produtos_idx,
  cells = cells %>% as.matrix() %>% unname()
)

write_json(map_data, file.path(map_out_dir, "map_data.json"), auto_unbox = TRUE)

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
    " -", file.path(out_dir, "composition_pais.json"), "\n",
    " -", file.path(out_dir, "municipality_composition_pais.json"), "\n",
    " -", file.path(out_dir, "paises.json"), "\n",
    " -", file.path(out_dir, "dictionary.json"), "\n",
    " -", file.path(map_out_dir, "municipalities.geojson"), "\n",
    " -", file.path(map_out_dir, "states_boundary.geojson"), "\n",
    " -", file.path(map_out_dir, "legal_amazon_boundary.geojson"), "\n",
    " -", file.path(map_out_dir, "map_data.json"), "\n")
cat(sprintf("\nAnos: %d-%d (ultimo completo: %d)\n", year_inicio, year_final, year_final_completo))
if (length(anos_parciais)) {
  for (a in names(anos_parciais)) cat(sprintf(" - %s e parcial: %d meses\n", a, anos_parciais[[a]]))
}
