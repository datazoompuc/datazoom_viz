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

# O CEMPRE do IBGE publica "Salarios e outras remuneracoes" em MIL REAIS, mas o
# dicionario (data/dz_munic_dic.csv) rotula a variavel como "R$", e o app mostra
# o numero cru seguido desse rotulo. Resultado: o mapa subestimava a massa
# salarial em mil vezes, no tooltip e na legenda.
#
# Nem o pacote nem o dicionario declaram a unidade, entao a evidencia e
# aritmetica. Dividindo pelo numero de assalariados:
#
#   Manaus 2020      471.815 assalariados, 19.404.748 -> R$ 41 por pessoa por ANO
#                                                     ou R$ 3.427 por MES em R$ mil
#   Porto Velho 2020 127.711 assalariados,  5.636.631 -> R$ 44/ano ou R$ 3.678/mes
#   mediana dos municipios: 1,7 a 2,1 salarios minimos, estavel de 2006 a 2020
#
# Converter aqui, e nao trocar o rotulo, mantem UMA unidade (R$) em tudo que o
# app toca, inclusive no `pib` convertido logo abaixo. Sem isso, per capita e
# % do PIB sairiam mil vezes errados.
#
# O mesmo dicionario alimenta apps Shiny antigos, que seguem com o rotulo errado.
df_attrs <- readRDS("data/cempre_municipality_dza.rds") %>%
  mutate(
    cod_ibge = as.character(cod_ibge),
    cempre_salarios_remuneracoes = cempre_salarios_remuneracoes * 1000
  )

year_inicio <- 2006
year_final <- 2020
all_years <- year_inicio:year_final

complete_grid <- tidyr::expand_grid(cod_ibge = munic_geo$cod_ibge, ano = all_years)

# Denominadores para as medidas derivadas (per capita, % do PIB).
#
# Vao os DENOMINADORES, nao as medidas prontas: per capita e % do PIB sao
# divisoes, e o app calcula em tempo de render. Guardar as derivadas seria
# 4 variaveis x 2 normalizacoes = 8 colunas a mais por linha, todas
# recalculaveis. Mesma razao pela qual o COMEX nao guarda valor unitario.
#
# O PIB do IBGE vem em R$ mil correntes; aqui vira R$ para o app nao precisar
# saber disso. Os salarios do CEMPRE ja estao em R$.
#
# Mojui dos Campos (PA) fica sem denominador de 2006 a 2011 (populacao) e ate
# 2012 (PIB): o municipio foi criado em 2012, desmembrado de Santarem, entao
# nao existia. Sao 6 e 7 linhas de 11.580, e ficar NA ali e o certo.
pop_munic <- readRDS("data/population.rds") %>%
  filter(nivel == "municipio", !is.na(populacao)) %>%
  transmute(cod_ibge = as.character(cod_ibge), ano, populacao)

pib_munic <- readRDS("data/pibmunic.rds") %>%
  filter(nivel == "municipio", !is.na(pib)) %>%
  transmute(cod_ibge = as.character(cod_ibge), ano, pib = pib * 1000)

attrs <- complete_grid %>%
  left_join(df_attrs, by = c("cod_ibge", "ano")) %>%
  left_join(munic_meta, by = "cod_ibge") %>%
  left_join(pop_munic, by = c("cod_ibge", "ano")) %>%
  left_join(pib_munic, by = c("cod_ibge", "ano")) %>%
  select(cod_ibge, ano, nm_municip, estado,
         cempre_n_empresas_organizacoes, cempre_n_ocupados,
         cempre_n_ocupados_assalariados, cempre_salarios_remuneracoes,
         populacao, pib)

# Os joins nao podem ter multiplicado linhas nem perdido o que ja existia.
stopifnot(nrow(attrs) == nrow(complete_grid))
cobertura <- attrs %>%
  summarise(
    sem_pop = sum(is.na(populacao)),
    sem_pib = sum(is.na(pib))
  )
if (cobertura$sem_pop > 20 || cobertura$sem_pib > 20) {
  stop(sprintf(
    "Denominador faltando em linhas demais (%d sem populacao, %d sem PIB). Esperado: so Mojui dos Campos, ate 13 linhas.",
    cobertura$sem_pop, cobertura$sem_pib))
}
message(sprintf("  denominadores: %d linhas sem populacao, %d sem PIB (de %d)",
                cobertura$sem_pop, cobertura$sem_pib, nrow(attrs)))

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
