################################################################################
# MapBiomas - Cobertura e Uso da Terra (Amazônia Legal)
# Gera est e munic com schema consistente para os apps ts_mapbiomas_cobertura.
# Classes em inglês (chave interna); rótulos PT/EN nos dicionários.
# Requer a versão dev do pacote (Collection 9, até 2023):
#   devtools::install_github("datazoompuc/datazoom.amazonia")
# 2024 vem da Collection 10 na seção 2b. Não confundir com mapbiomas_cobertura.R (mapa).
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
    library(jsonlite)   # nomes de municípios acentuados (API do IBGE)
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
# 2b. 2024 (Collection 10) — replica o tratamento do load_mapbiomas() no arquivo
# de estatísticas da Col10 e empilha só 2024. (A Col10 reprocessou toda a série;
# p/ série 100% consistente, tirar o filter(year=="2024") e comentar a seção 2.)
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

# Nomes acentuados/Title Case (a carga e a tabela do pacote vêm em ASCII minúsculo):
# mapa fixo para os 9 estados e API do IBGE para os municípios.

estados_amz <- c(
    "acre"        = "Acre",
    "amapa"       = "Amapá",
    "amazonas"    = "Amazonas",
    "maranhao"    = "Maranhão",
    "mato grosso" = "Mato Grosso",
    "para"        = "Pará",
    "rondonia"    = "Rondônia",
    "roraima"     = "Roraima",
    "tocantins"   = "Tocantins"
)

municipios_amazonia <- datazoom.amazonia::municipalities %>%
    filter(legal_amazon == 1) %>%
    transmute(
        municipality_code = code_muni,
        uf = dplyr::recode(name_state, !!!estados_amz)
    )

# Nome dos municípios com acento e Title Case, via API de localidades do IBGE
# (a coluna 'municipality' da carga vem sem acento). 'id' do IBGE = municipality_code.
ibge_mun <- jsonlite::fromJSON(
    "https://servicodados.ibge.gov.br/api/v1/localidades/municipios"
)
muni_names <- tibble::tibble(
    municipality_code = as.numeric(ibge_mun$id),
    municipality      = ibge_mun$nome
)

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
# 7. LEGENDA (EN -> PT + NÍVEL HIERÁRQUICO)
# Nível: DINÂMICO — menor class_level onde cada classe aparece na carga (cobre
#   inclusive as classes novas da Coleção 10, ex.: Photovoltaic Project).
# Nomes PT: legenda OFICIAL do MapBiomas. O pacote não traduz os valores das
#   classes (só metadados), então o PT vem dos Códigos de Legenda - Coleção 10:
#   https://brasil.mapbiomas.org/wp-content/uploads/sites/4/2025/08/Legenda-Colecao-10-Legend-Code.pdf
# Salva como auxiliar em data/mapbiomas_legenda.csv.
################################################################################

legenda_file <- "data/mapbiomas_legenda.csv"

# nível hierárquico dinâmico: menor nível onde cada classe (EN) ocorre
niveis <- purrr::map_df(0:4, function(n) {
    tibble::tibble(nome_en = strip_prefix(as.character(dat[[paste0("class_level_", n)]])),
                   nivel   = n)
}) %>%
    dplyr::filter(!is.na(nome_en), nome_en != "") %>%
    dplyr::group_by(nome_en) %>%
    dplyr::summarise(nivel = min(nivel), .groups = "drop")

# nomes oficiais em PT (MapBiomas — Códigos de Legenda, Coleção 10)
nome_pt_oficial <- c(
    "Antropic"                       = "Antrópico",
    "Natural"                        = "Natural",
    "Natural/Antropic"               = "Natural/Antrópico",
    "Undefined"                      = "Não Aplicável",
    "Forest"                         = "Floresta",
    "Non Forest Natural Formation"   = "Formação Natural não Florestal",
    "Farming"                        = "Agropecuária",
    "Non vegetated area"             = "Área não Vegetada",
    "Water and Marine Environment"   = "Corpo D'água",
    "Not Observed"                   = "Não Observado",
    "Forest Formation"               = "Formação Florestal",
    "Savanna Formation"              = "Formação Savânica",
    "Mangrove"                       = "Mangue",
    "Floodable Forest"               = "Floresta Alagável",
    "Wooded Sandbank Vegetation"     = "Restinga Arbórea",
    "Wetland"                        = "Campo Alagado e Área Pantanosa",
    "Grassland"                      = "Formação Campestre",
    "Hypersaline Tidal Flat"         = "Apicum",
    "Rocky Outcrop"                  = "Afloramento Rochoso",
    "Herbaceous Sandbank Vegetation" = "Restinga Herbácea",
    "Other non Forest Formations"    = "Outras Formações não Florestais",
    "Pasture"                        = "Pastagem",
    "Agriculture"                    = "Agricultura",
    "Forest Plantation"              = "Silvicultura",
    "Mosaic of Uses"                 = "Mosaico de Usos",
    "Beach, Dune and Sand Spot"      = "Praia, Duna e Areal",
    "Urban Area"                     = "Área Urbana",
    "Mining"                         = "Mineração",
    "Other non Vegetated Areas"      = "Outras Áreas não Vegetadas",
    "River, Lake and Ocean"          = "Rio, Lago e Oceano",
    "Aquaculture"                    = "Aquicultura",
    "Photovoltaic Project"           = "Usina Fotovoltaica",
    "Temporary Crop"                 = "Lavoura Temporária",
    "Perennial Crop"                 = "Lavoura Perene",
    "Soybean"                        = "Soja",
    "Sugar cane"                     = "Cana",
    "Rice"                           = "Arroz",
    "Cotton"                         = "Algodão",
    "Other Temporary Crops"          = "Outras Lavouras Temporárias",
    "Coffee"                         = "Café",
    "Citrus"                         = "Citrus",
    "Palm Oil"                       = "Dendê",
    "Other Perennial Crops"          = "Outras Lavouras Perenes"
)

# aviso: classes sem PT oficial (caem no fallback = nome em inglês)
faltam_pt <- setdiff(niveis$nome_en, names(nome_pt_oficial))
if (length(faltam_pt) > 0) {
    message("Classes sem PT oficial (usando EN): ", paste(faltam_pt, collapse = " | "))
}

legenda <- niveis %>%
    dplyr::mutate(nome_pt = dplyr::coalesce(unname(nome_pt_oficial[nome_en]), nome_en))

readr::write_csv(legenda, legenda_file)

################################################################################
# 7b. DICIONÁRIOS (PT / EN)
# Rótulos vêm da legenda oficial; var_group = nível hierárquico (vira optgroup no
# app); linhas ordenadas por nível e depois alfabeticamente pelo rótulo do idioma.
################################################################################

grupo_nivel_pt <- c("0" = "Nível 0 — Categorias amplas",
                    "1" = "Nível 1 — Grandes classes",
                    "2" = "Nível 2 — Subclasses",
                    "3" = "Nível 3 — Detalhamento",
                    "4" = "Nível 4 — Classes específicas")
grupo_nivel_en <- c("0" = "Level 0 — Broad categories",
                    "1" = "Level 1 — Main classes",
                    "2" = "Level 2 — Subclasses",
                    "3" = "Level 3 — Detail",
                    "4" = "Level 4 — Specific classes")

# Constrói e grava o par de dicionários (PT + EN) para um dataset.
build_dics <- function(df, out_pt, out_en) {
    cols     <- setdiff(colnames(df), "municipality_code")   # chave técnica fora do dic
    is_class <- !(cols %in% c("group", "time", "area_km2"))

    base <- tibble::tibble(var = cols, is_class = is_class) %>%
        dplyr::left_join(legenda, by = c("var" = "nome_en"))

    make_dic <- function(idioma) {
        grupo_map <- if (idioma == "pt") grupo_nivel_pt else grupo_nivel_en
        base %>%
            dplyr::mutate(
                x = is_class, y = is_class,
                color = var == "group", size = is_class, slider = is_class,
                label = dplyr::case_when(
                    var == "area_km2" & idioma == "pt" ~ "Área do município (km2)",
                    var == "area_km2"                  ~ "Municipal area (km2)",
                    !is_class                          ~ var,
                    idioma == "pt"                     ~ dplyr::coalesce(nome_pt, var),
                    TRUE                               ~ var
                ),
                desc = label,
                var_group = dplyr::if_else(
                    is_class,
                    dplyr::coalesce(unname(grupo_map[as.character(nivel)]),
                                    if (idioma == "pt") "Outras" else "Other"),
                    "Mapbiomas"
                ),
                tipo = 1L,
                unidade = dplyr::if_else(var == "area_km2", "km2", "ha"),
                categoria    = if (idioma == "pt") "Meio ambiente" else "Environment",
                subcategoria = if (idioma == "pt") "Uso da terra"  else "Land use"
            ) %>%
            # nível, depois alfabético. dplyr::arrange() ordena strings em locale
            # "C" (byte order) independente do Sys.setlocale, o que joga acentuadas
            # (Área, Áreas...) para o fim em vez do lugar certo -- por isso usamos
            # stringi::stri_rank() com locale explícito como chave de ordenação.
            dplyr::arrange(!is_class, nivel,
                           stringi::stri_rank(label, opts_collator = stringi::stri_opts_collator(
                               locale = if (idioma == "pt") "pt_BR" else "en_US"
                           ))) %>%
            dplyr::select(var, x, y, color, size, slider, label, desc,
                          var_group, tipo, unidade, categoria, subcategoria)
    }

    faltando <- base$var[base$is_class & is.na(base$nome_pt)]
    if (length(faltando) > 0) {
        message("Classes sem correspondência na legenda oficial: ",
                paste(faltando, collapse = " | "))
    }

    readr::write_csv(make_dic("pt"), out_pt)
    readr::write_csv(make_dic("en"), out_en)
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
