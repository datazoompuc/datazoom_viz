################################################################################
# MapBiomas - Cobertura e Uso da Terra (Amazônia Legal)
# PIPELINE UNIFICADO para os apps ts_mapbiomas_cobertura (Fase 0 do merge est+munic)
#
# Substitui os scripts antigos:
#   data-raw/mapbiomas_cobertura_est.R
#   data-raw/mapbiomas_cobertura_munic.R
# (que geravam schemas divergentes: est com colunas em inglês, munic com _pt/_en).
#
# NÃO confundir com data-raw/mapbiomas_cobertura.R (builder do app de MAPA).
#
# Gera, de UMA única carga do datazoom.amazonia, os dois datasets com SCHEMA
# CONSISTENTE:
#   data/mapbiomas_cobertura_est.rds     -> nível estadual  (group = estado)
#   data/mapbiomas_cobertura_munic.rds   -> nível municipal (group = "Município - Estado")
#
# Convenção (igual ao padrão ts_aneel):
#   - COLUNAS DE CLASSE sempre em INGLÊS (chave interna neutra).
#   - RÓTULOS PT/EN vivem nos dicionários (est/munic _dic.csv PT e _dic_en.csv EN).
#
# OBS. COLEÇÃO: usar a versão de DESENVOLVIMENTO do pacote (Collection 9, série
# até 2023, schema com class_level_0..4):
#   devtools::install_github("datazoompuc/datazoom.amazonia")
# (A versão do CRAN entrega Collection 8, só até 2022, e com outro schema.)
# O ano de 2024 NÃO vem do pacote — é adicionado na seção 2b, baixando o arquivo
# de estatísticas da Collection 10 direto do MapBiomas e replicando o mesmo
# tratamento do load_mapbiomas(). Resultado final: série 1985-2024.
################################################################################

################################################################################
# 1. SETUP
################################################################################

suppressPackageStartupMessages({
    library(datazoom.amazonia)
    library(dplyr)
    library(tidyr)
    library(readr)
    library(purrr)
    library(tibble)
    library(readxl)     # ler o .xlsx de estatísticas da Coleção 10
    library(janitor)    # clean_names(), igual ao pipeline do pacote
    library(stringi)    # transliteração Latin-ASCII, igual ao pacote
})

################################################################################
# 2. CARGA (uma vez só, nível municipal, classes em inglês)
################################################################################

dat <- load_mapbiomas(
    dataset   = "mapbiomas_cover",
    raw_data  = FALSE,
    geo_level = "municipality",
    language  = "eng"
)

################################################################################
# 2b. ADENDO 2024 (Collection 10) — replica o pipeline do datazoom.amazonia
#
# O pacote entrega só a Collection 9 (até 2023). Aqui baixamos o arquivo de
# ESTATÍSTICAS da Collection 10 direto do storage do MapBiomas e aplicamos
# EXATAMENTE o mesmo tratamento que o load_mapbiomas() faz internamente
# (clean_names -> Latin-ASCII -> drop colunas "id" -> pivot dos anos "xYYYY" ->
#  remove vars auxiliares -> rename eng -> tira prefixo numérico das classes),
# ficando apenas com 2024 e empilhando na base do pacote.
#
# ATENÇÃO metodológica: a Collection 10 reprocessou TODA a série 1985-2024.
# Enxertar só 2024 (Col10) sobre 1985-2023 (Col9) mistura duas metodologias na
# mesma série. Se preferir série 100% consistente, use a Col10 para todos os anos:
# remova o `filter(year == "2024")` abaixo e comente a carga da seção 2.
#
# OBS: a URL abaixo segue o mesmo padrão da Col9. Se o MapBiomas mudar o caminho,
# pegue o link atual do arquivo de estatísticas em
# https://brasil.mapbiomas.org/en/downloads/ e ajuste `col10_url`.
################################################################################

col10_url <- paste0(
    "https://storage.googleapis.com/mapbiomas-public/initiatives/brasil/",
    "collection_10/lulc/statistics/MAPBIOMAS_BRAZIL-COL.10-BIOME_STATE_MUNICIPALITY.xlsx"
)

tmp10 <- tempfile(fileext = ".xlsx")
utils::download.file(col10_url, tmp10, mode = "wb", method = "curl")

# planilha de cobertura: detecta pela que contém "cover"/"cobert"; senão, a 1ª
sheets10 <- readxl::excel_sheets(tmp10)
sheet10  <- sheets10[grepl("cover|cobert", sheets10, ignore.case = TRUE)][1]
if (is.na(sheet10)) sheet10 <- sheets10[1]
message("Collection 10 - planilhas: ", paste(sheets10, collapse = ", "),
        " | usando: ", sheet10)

dat_2024 <- readxl::read_xlsx(tmp10, sheet = sheet10) %>%
    janitor::clean_names() %>%
    dplyr::mutate_if(is.character, function(v) stringi::stri_trans_general(v, "Latin-ASCII")) %>%
    dplyr::select(-dplyr::contains("id")) %>%
    tidyr::pivot_longer(
        dplyr::starts_with("x"),
        names_to = "year", values_to = "value", names_prefix = "x"
    ) %>%
    tidyr::drop_na(value) %>%
    dplyr::select(-dplyr::any_of(c(
        "biome_municipality", "color", "category", "biome_state",
        "to_color", "from_color", "from_class", "to_class", "class_lulc", "group"
    ))) %>%
    dplyr::rename_with(~ dplyr::case_match(.,
        "city"          ~ "municipality",
        "geocode"       ~ "municipality_code",
        "state_acronym" ~ "state",
        .default = .
    )) %>%
    dplyr::mutate(dplyr::across(
        tidyselect::matches("^class_level_\\d+$"),
        ~ sub("^\\s*\\d+(?:\\.\\d+)*\\.?\\s*", "", as.character(.))
    )) %>%
    dplyr::filter(year == "2024") %>%
    # alinhar tipos com a base do pacote antes de empilhar
    dplyr::mutate(
        municipality_code = as.numeric(municipality_code),
        year              = as.character(year),
        value             = as.numeric(value)
    )

dat <- dplyr::bind_rows(dat, dat_2024)
message("2024 (Col10) adicionado: ", nrow(dat_2024), " linhas | anos agora: ",
        paste(range(dat$year), collapse = "-"))

################################################################################
# 3. REFERÊNCIAS: municípios da Amazônia Legal (nome do estado) e áreas
################################################################################

# nome COMPLETO do estado (a coluna 'state' da carga vem como sigla, ex. "RO")
municipios_amazonia <- datazoom.amazonia::municipalities %>%
    filter(legal_amazon == 1) %>%
    transmute(municipality_code = code_muni, uf = name_state)

# lookup do nome do município (a partir da própria carga)
muni_names <- dat %>%
    distinct(municipality_code, municipality)

# área municipal (km²) — mantida no repositório em global/
areas_mun <- readr::read_rds("global/area_municipios.rds")   # cols: municipality_code, area_km2

# área por estado (soma das áreas municipais da Amazônia Legal)
areas_state <- areas_mun %>%
    inner_join(municipios_amazonia, by = "municipality_code") %>%
    group_by(uf) %>%
    summarise(area_km2 = sum(area_km2, na.rm = TRUE), .groups = "drop")

################################################################################
# 4. TABELA LONGA (todos os níveis hierárquicos de classe: level_0..level_4)
#
# Agrupar por CADA level_0..4 e empilhar traz tanto classes amplas (Forest,
# Farming) quanto específicas (Forest Formation, Pasture). O level_1 vem com
# prefixo numérico ("1. Forest") — removido por strip_prefix().
################################################################################

class_levels <- paste0("class_level_", 0:4)

# remove eventual prefixo numérico ("1. Forest" -> "Forest"); no-op no schema dev atual
strip_prefix <- function(x) sub("^[0-9]+(\\.[0-9]+)*\\.?\\s*", "", x)

long <- purrr::map_df(class_levels, function(lv) {
    dat %>%
        transmute(
            time              = as.integer(year),
            municipality_code,
            aggregation       = strip_prefix(.data[[lv]]),
            area              = as.numeric(value)
        )
}) %>%
    filter(!is.na(aggregation), aggregation != "") %>%
    inner_join(municipios_amazonia, by = "municipality_code") %>%   # traz uf + filtra Amazônia Legal
    group_by(time, municipality_code, uf, aggregation) %>%
    summarise(area = sum(area, na.rm = TRUE), .groups = "drop")

################################################################################
# 5. DATASET MUNICIPAL (group = "Município - Estado", mantém municipality_code)
################################################################################

munic_wide <- long %>%
    left_join(muni_names, by = "municipality_code") %>%
    mutate(group = paste(municipality, "-", uf)) %>%
    pivot_wider(
        id_cols     = c(time, municipality_code, group),
        names_from  = aggregation,
        values_from = area,
        values_fill = 0
    ) %>%
    left_join(areas_mun, by = "municipality_code") %>%
    arrange(group, time)

saveRDS(munic_wide, "data/mapbiomas_cobertura_munic.rds")

################################################################################
# 6. DATASET ESTADUAL (group = estado; área somada por estado)
################################################################################

est_wide <- long %>%
    group_by(time, uf, aggregation) %>%
    summarise(area = sum(area, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(
        id_cols     = c(time, uf),
        names_from  = aggregation,
        values_from = area,
        values_fill = 0
    ) %>%
    rename(group = uf) %>%
    left_join(areas_state, by = c("group" = "uf")) %>%
    arrange(group, time)

saveRDS(est_wide, "data/mapbiomas_cobertura_est.rds")

################################################################################
# 7. DICIONÁRIOS (PT / EN) — fonte única de tradução EN -> PT
################################################################################

translate_en_to_pt <- c(
    "Aquaculture"                          = "Aquicultura",
    "Beach, Dune and Sand Spot"            = "Praia e Dunas",
    "Citrus"                               = "Cítricos",
    "Coffee"                               = "Café",
    "Cotton"                               = "Algodão",
    "Floodable Forest"                     = "Floresta Inundável",
    "Forest Formation"                     = "Formação de Floresta",
    "Forest Plantation"                    = "Plantação de Floresta",
    "Grassland"                            = "Pradaria",
    "Herbaceous Sandbank Vegetation"       = "Restinga Herbácea",
    "Hypersaline Tidal Flat"               = "Salar",
    "Mangrove"                             = "Mangue",
    "Mining"                               = "Mineração",
    "Mosaic of Uses"                       = "Mosaico de Uso da Terra",
    "Not Observed"                         = "Não observado",
    "Other Non Forest Natural Formation"   = "Outras formações naturais não florestais",
    "Other non Vegetated Areas"            = "Outras áreas não vegetadas",
    "Other Perennial Crops"                = "Outras Culturas Perenes",
    "Other Temporary Crops"                = "Outras Culturas Temporárias",
    "Palm Oil"                             = "Óleo de Palma",
    "Pasture"                              = "Pastagem",
    "Rice"                                 = "Arroz",
    "River, Lake and Ocean"                = "Rios, Lagos ou Oceanos",
    "Rocky Outcrop"                        = "Afloramento Rochoso",
    "Savanna Formation"                    = "Formação de Savana",
    "Soybean"                              = "Soja",
    "Sugar cane"                           = "Cana-de-açúcar",
    "Urban Area"                           = "Infraestrutura Urbana",
    "Wetland"                              = "Pântano",
    "Wooded Sandbank Vegetation"           = "Restinga Arborizada",
    "Perennial Crop"                       = "Culturas Perenes",
    "Temporary Crop"                       = "Culturas Temporárias",
    "Agriculture"                          = "Agricultura",
    "Farming"                              = "Fazenda",
    "Forest"                               = "Floresta",
    "Non Forest Natural Formation"         = "Formação Natural Não Florestal",
    "Non vegetated area"                   = "Áreas não vegetadas",
    "Water and Marine Environment"         = "Água",
    "Antropic"                             = "Antrópico",
    "Natural"                              = "Natural",
    "Natural/Antropic"                     = "Natural/Antrópico",
    "Undefined"                            = "Não aplicado"
)

# Constrói e grava o par de dicionários (PT + EN) para um dataset.
build_dics <- function(df, out_pt, out_en) {
    cols     <- setdiff(colnames(df), "municipality_code")   # chave técnica fora do dic
    is_class <- !(cols %in% c("group", "time", "area_km2"))

    base <- tibble(
        var          = cols,
        x            = is_class,
        y            = is_class,
        color        = cols == "group",
        size         = is_class,
        slider       = is_class,
        label        = cols,
        desc         = cols,
        var_group    = "Mapbiomas",
        tipo         = 1L,
        unidade      = "ha",
        categoria    = NA_character_,
        subcategoria = NA_character_
    )

    dic_en <- base %>%
        mutate(
            categoria    = "Environment",
            subcategoria = "Land use",
            unidade      = ifelse(var == "area_km2", "km2", unidade),
            label        = ifelse(var == "area_km2", "Municipal area (km2)", label),
            desc         = label
        )

    dic_pt <- base %>%
        mutate(
            categoria    = "Meio ambiente",
            subcategoria = "Uso da terra",
            unidade      = ifelse(var == "area_km2", "km2", unidade),
            label        = ifelse(var %in% names(translate_en_to_pt),
                                  translate_en_to_pt[var], var),
            label        = ifelse(var == "area_km2", "Área do município (km2)", label),
            desc         = label
        )

    faltando <- setdiff(cols[is_class], names(translate_en_to_pt))
    if (length(faltando) > 0) {
        message("Classes SEM tradução PT (revisar translate_en_to_pt): ",
                paste(faltando, collapse = " | "))
    }

    readr::write_csv(dic_pt, out_pt)
    readr::write_csv(dic_en, out_en)
}

build_dics(est_wide,
           "data/mapbiomas_cobertura_est_dic.csv",
           "data/mapbiomas_cobertura_est_dic_en.csv")

build_dics(munic_wide,
           "data/mapbiomas_cobertura_munic_dic.csv",
           "data/mapbiomas_cobertura_munic_dic_en.csv")

################################################################################
# 8. CHECAGENS RÁPIDAS (conferir antes da Fase 1)
################################################################################

cat("EST  -> anos:", min(est_wide$time), "a", max(est_wide$time),
    "| estados:", dplyr::n_distinct(est_wide$group),
    "| colunas:", ncol(est_wide), "\n")
cat("MUNIC-> anos:", min(munic_wide$time), "a", max(munic_wide$time),
    "| municipios:", dplyr::n_distinct(munic_wide$group),
    "| colunas:", ncol(munic_wide), "\n")

classes_est   <- setdiff(colnames(est_wide),   c("group", "time", "area_km2"))
classes_munic <- setdiff(colnames(munic_wide), c("group", "time", "municipality_code", "area_km2"))
cat("Classes so no EST  :", paste(setdiff(classes_est, classes_munic), collapse = ", "), "\n")
cat("Classes so no MUNIC:", paste(setdiff(classes_munic, classes_est), collapse = ", "), "\n")
