################################################################################
# MapBiomas - Cobertura e Uso da Terra (Amazônia Legal)
# Gera UMA base longa (uma linha por ano x município x classe), com rótulos PT/EN
# e nível hierárquico dentro dela. Substitui mapbiomas_cobertura_ts_rk.R, que
# gerava mapbiomas_cobertura_munic.rds, _est.rds e os dicionários por nível.
# O nível estadual não é mais guardado: é a soma dos municípios
# (global/mapbiomas_cobertura_larga.R monta as tabelas largas dos apps).
#
# Saídas:
#   data/mapbiomas_cobertura_base.rds       base longa
#   data/mapbiomas_cobertura_base_dic.csv   dicionário dos apps (PT)
#   data/mapbiomas_cobertura_base_dic_en.csv  dicionário dos apps (EN)
#   data/mapbiomas_legenda.csv              legenda EN/PT/nível (usada também
#                                           pelos apps de transição)
#
# Fonte: MapBiomas Collection 10, série completa 1985-2024, via load_mapbiomas()
# (versão dev do pacote: devtools::install_github("datazoompuc/datazoom.amazonia")).
# Não confundir com mapbiomas_cobertura_map.R (mapa).
# Rodar da raiz do datazoom_viz.
#
# Unidades: area_ha em hectares; area_municipio_km2 em km2.
# Níveis (nivel 0 a 4) são cortes diferentes da MESMA área: não somar classes de
# níveis diferentes. Os níveis 3 e 4 (tipos de lavoura) cobrem só uma parte.
################################################################################

################################################################################
# 1. SETUP
################################################################################

stopifnot(basename(getwd()) == "datazoom_viz")

suppressPackageStartupMessages({
    library(datazoom.amazonia)
    library(dplyr)
    library(tidyr)
    library(readr)
    library(purrr)
    library(tibble)
    library(stringi)    # ordenação com locale (dicionários)
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
# 2b. CONFERÊNCIA DA CARGA
# O load_mapbiomas() atual já devolve a série completa da Collection 10
# (1985-2024), então não é mais preciso baixar 2024 à parte. A Col10 reprocessou
# toda a série: os valores de 1985-2023 podem diferir dos arquivos gerados antes
# com a Collection 9.
################################################################################

stopifnot("2024" %in% dat$year, "1985" %in% dat$year)
message("Carga: anos ", paste(range(dat$year), collapse = "-"), " | linhas: ", nrow(dat))

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

long_by_level <- purrr::map_df(class_levels, function(lv) {
    dat %>%
        transmute(
            time              = as.integer(year),
            municipality_code = as.numeric(municipality_code),   # o pacote devolve texto
            aggregation       = strip_prefix(.data[[lv]]),
            area              = as.numeric(value)
        ) %>%
        filter(!is.na(aggregation), aggregation != "") %>%
        inner_join(municipios_amazonia, by = "municipality_code") %>%   # traz uf + filtra Amazônia Legal
        reframe(area = sum(area, na.rm = TRUE),                          # soma DENTRO do nível
                .by = c(time, municipality_code, uf, aggregation))
})

# Valida a suposição antes de colapsar: repetições entre níveis devem ter a
# MESMA área (mesmas linhas de origem, só reetiquetadas). Se alguma
# combinação (time, municipality_code, aggregation) aparecer em mais de um
# nível com áreas que DIVERGEM de verdade (não só ruído de ponto flutuante),
# um distinct() silencioso esconderia essa divergência escolhendo uma
# arbitrariamente -- por isso paramos e avisamos em vez de seguir escondendo.
divergent <- long_by_level %>%
    reframe(n = dplyr::n(), area_range = max(area) - min(area),
            .by = c(time, municipality_code, uf, aggregation)) %>%
    filter(n > 1, area_range > 1e-6)

if (nrow(divergent) > 0) {
    warning(
        nrow(divergent), " combinações (time, municipality_code, aggregation) repetem entre ",
        "níveis com áreas DIFERENTES (não é só ruído de ponto flutuante) -- verifique o ",
        "objeto 'divergent' antes de confiar no dataset final. Amostra:\n",
        paste(utils::capture.output(print(utils::head(divergent, 10))), collapse = "\n")
    )
}

long <- long_by_level %>%
    distinct(time, municipality_code, uf, aggregation, .keep_all = TRUE) # colapsa repetições entre níveis (não soma)

################################################################################
# 5. LEGENDA (EN -> PT + NÍVEL HIERÁRQUICO)
# Nível: DINÂMICO — menor class_level onde cada classe aparece na carga (cobre
#   inclusive as classes novas da Coleção 10, ex.: Photovoltaic Project).
# Nomes PT: legenda OFICIAL do MapBiomas. O pacote não traduz os valores das
#   classes (só metadados), então o PT vem dos Códigos de Legenda - Coleção 10:
#   https://brasil.mapbiomas.org/wp-content/uploads/sites/4/2025/08/Legenda-Colecao-10-Legend-Code.pdf
# Salva como auxiliar em data/mapbiomas_legenda.csv (os apps de transição leem).
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
# 6. BASE LONGA: uma linha por ano x município x classe
# Rótulos PT/EN de toda dimensão que aparece como texto e nível da classe.
# Não guarda linhas de área zero: a ausência vale zero
# (cobertura_larga() preenche com zero ao montar as tabelas largas).
################################################################################

base <- long %>%
    left_join(muni_names, by = "municipality_code") %>%
    left_join(areas_mun,  by = "municipality_code") %>%
    left_join(dplyr::rename(legenda, classe_en = nome_en, classe_pt = nome_pt),
              by = c("aggregation" = "classe_en")) %>%
    transmute(
        ano                = time,
        cod_municipio      = municipality_code,
        municipio          = municipality,
        uf,
        classe_en          = aggregation,
        classe_pt,
        nivel,
        area_ha            = area,
        area_municipio_km2 = area_km2
    ) %>%
    filter(area_ha > 0) %>%
    arrange(cod_municipio, ano, nivel, classe_en)

# falha alto se algum rótulo ou chave não fechou, em vez de gravar NA
stopifnot(
    !anyNA(base$municipio),
    !anyNA(base$classe_pt),
    !anyNA(base$nivel),
    !anyNA(base$area_municipio_km2),
    !anyDuplicated(base[c("ano", "cod_municipio", "classe_en")])
)

saveRDS(base, "data/mapbiomas_cobertura_base.rds")

cat("BASE -> linhas:", nrow(base),
    "| anos:", min(base$ano), "a", max(base$ano),
    "| municípios:", dplyr::n_distinct(base$cod_municipio),
    "| classes:", dplyr::n_distinct(base$classe_en), "\n")

################################################################################
# 7. DICIONÁRIO DOS APPS (PT / EN)
# Rótulos vêm da legenda oficial; var_group = nível hierárquico (vira optgroup no
# app); linhas ordenadas por nível e depois alfabeticamente pelo rótulo do idioma.
# Um par só: estado e município têm as mesmas classes.
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

# Constrói e grava o par de dicionários (PT + EN).
build_dics <- function(cols, out_pt, out_en) {
    is_class <- !(cols %in% c("group", "time", "area_km2"))

    base_dic <- tibble::tibble(var = cols, is_class = is_class) %>%
        dplyr::left_join(legenda, by = c("var" = "nome_en"))

    make_dic <- function(idioma) {
        grupo_map <- if (idioma == "pt") grupo_nivel_pt else grupo_nivel_en
        base_dic %>%
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

    readr::write_csv(make_dic("pt"), out_pt)
    readr::write_csv(make_dic("en"), out_en)
}

build_dics(c("group", "time", sort(unique(base$classe_en)), "area_km2"),
           "data/mapbiomas_cobertura_base_dic.csv",
           "data/mapbiomas_cobertura_base_dic_en.csv")

################################################################################
# 8. CONFERÊNCIA
# (a) ida e volta: as tabelas largas montadas a partir da base (cobertura_larga)
#     têm de ser idênticas às montadas direto da tabela longa, com o método antigo
#     (pivot_wider em munic e est). Isto prova que a base não perdeu nada.
# (b) contra os arquivos antigos (Collection 9 + 2024 da Col10): 2024 tem de
#     ser igual; 1985-2023 são só informativos, porque a Col10 reprocessou a série.
################################################################################

source("global/mapbiomas_cobertura_larga.R")

comparar <- function(novo, velho, chaves, rotulo) {
    novo  <- as.data.frame(dplyr::ungroup(novo))
    velho <- as.data.frame(dplyr::ungroup(velho))
    if (!setequal(names(novo), names(velho))) {
        cat(rotulo, ": colunas diferentes.\n  só no novo :",
            paste(setdiff(names(novo), names(velho)), collapse = " | "),
            "\n  só no velho:", paste(setdiff(names(velho), names(novo)), collapse = " | "), "\n")
        return(FALSE)
    }
    cn    <- sort(names(velho))
    novo  <- novo[do.call(order, novo[chaves]), cn]
    velho <- velho[do.call(order, velho[chaves]), cn]
    rownames(novo) <- rownames(velho) <- NULL
    r <- all.equal(novo, velho, check.attributes = FALSE)
    cat(rotulo, ":", if (isTRUE(r)) "IGUAL" else "DIFERENTE", "\n")
    if (!isTRUE(r)) print(utils::head(r, 10))
    isTRUE(r)
}

# (a) método antigo, direto da tabela longa
munic_ref <- long %>%
    filter(area > 0) %>%     # a base não guarda zeros
    left_join(muni_names, by = "municipality_code") %>%
    mutate(group = paste(municipality, "-", uf)) %>%
    pivot_wider(id_cols = c(time, municipality_code, group),
                names_from = aggregation, values_from = area, values_fill = 0) %>%
    left_join(areas_mun, by = "municipality_code") %>%
    arrange(group, time)

areas_state <- areas_mun %>%
    inner_join(municipios_amazonia, by = "municipality_code") %>%
    group_by(uf) %>%
    summarise(area_km2 = sum(area_km2, na.rm = TRUE), .groups = "drop")

est_ref <- long %>%
    filter(area > 0) %>%
    group_by(time, uf, aggregation) %>%
    summarise(area = sum(area, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(id_cols = c(time, uf), names_from = aggregation,
                values_from = area, values_fill = 0) %>%
    rename(group = uf) %>%
    left_join(areas_state, by = c("group" = "uf")) %>%
    arrange(group, time)

cat("\n== (a) ida e volta, base -> tabelas largas\n")
ok_munic <- comparar(cobertura_larga(base, "munic"), munic_ref, c("municipality_code", "time"), "munic")
ok_est   <- comparar(cobertura_larga(base, "est"),   est_ref,   c("group", "time"), "est")

# (b) contra os arquivos antigos. Só roda se eles ainda existirem: depois da
# limpeza ficam apenas no histórico do Git, e esta parte é pulada.
arquivos_antigos <- c("data/mapbiomas_cobertura_munic.rds", "data/mapbiomas_cobertura_est.rds",
                      "data/mapbiomas_cobertura_est_dic.csv",
                      "data/mapbiomas_cobertura_munic_pt.rds", "data/mapbiomas_cobertura_munic_en.rds")
if (!all(file.exists(arquivos_antigos))) {
cat("\n== (b) pulado: os arquivos antigos já foram removidos do repositório.\n")
} else {
cat("\n== (b) contra os .rds antigos\n")
velho_m <- readRDS("data/mapbiomas_cobertura_munic.rds")
velho_e <- readRDS("data/mapbiomas_cobertura_est.rds")
novo_m  <- cobertura_larga(base, "munic")
novo_e  <- cobertura_larga(base, "est")

ok_2024_m <- comparar(dplyr::filter(novo_m, time == 2024), dplyr::filter(velho_m, time == 2024),
                      c("municipality_code", "time"), "munic, só 2024")
ok_2024_e <- comparar(dplyr::filter(novo_e, time == 2024), dplyr::filter(velho_e, time == 2024),
                      c("group", "time"), "est, só 2024")

cat("\nmunic: anos novo", paste(range(novo_m$time), collapse = "-"),
    "| velho", paste(range(velho_m$time), collapse = "-"),
    "| municípios novo", dplyr::n_distinct(novo_m$municipality_code),
    "| velho", dplyr::n_distinct(velho_m$municipality_code), "\n")

# diferença relativa por ano, em Floresta e Pastagem (informativo)
dif <- dplyr::inner_join(
    dplyr::select(novo_m,  time, municipality_code, Forest, Pasture),
    dplyr::select(velho_m, time, municipality_code, Forest, Pasture),
    by = c("time", "municipality_code"), suffix = c("_novo", "_velho")) %>%
    dplyr::summarise(
        forest_novo  = sum(Forest_novo),  forest_velho  = sum(Forest_velho),
        pasture_novo = sum(Pasture_novo), pasture_velho = sum(Pasture_velho),
        .by = time) %>%
    dplyr::mutate(dif_forest_pct  = round(100 * (forest_novo  / forest_velho  - 1), 3),
                  dif_pasture_pct = round(100 * (pasture_novo / pasture_velho - 1), 3)) %>%
    dplyr::arrange(time)
cat("Diferença da soma (novo vs velho), anos selecionados:\n")
print(dif[dif$time %in% c(1985, 1995, 2005, 2015, 2022, 2023, 2024),
          c("time", "dif_forest_pct", "dif_pasture_pct")])

dic_antigo_pt <- utils::read.csv("data/mapbiomas_cobertura_est_dic.csv", fileEncoding = "UTF-8")
dic_novo_pt   <- utils::read.csv("data/mapbiomas_cobertura_base_dic.csv", fileEncoding = "UTF-8")
cat("\ndicionário PT novo x antigo:", if (isTRUE(all.equal(dic_novo_pt, dic_antigo_pt))) "IGUAL" else "DIFERENTE",
    "| classes só no novo:", paste(setdiff(dic_novo_pt$var, dic_antigo_pt$var), collapse = " | "),
    "| só no antigo:", paste(setdiff(dic_antigo_pt$var, dic_novo_pt$var), collapse = " | "), "\n")

cat("\nTamanho da base:", format(file.size("data/mapbiomas_cobertura_base.rds") / 1e6, digits = 3), "MB\n")
cat("Arquivos que ela substitui (MB):\n")
antigos <- c("data/mapbiomas_cobertura_munic.rds", "data/mapbiomas_cobertura_est.rds",
             "data/mapbiomas_cobertura_munic_pt.rds", "data/mapbiomas_cobertura_munic_en.rds")
print(round(file.size(antigos) / 1e6, 2))
}

stopifnot(ok_munic, ok_est)
cat("\nIda e volta OK.\n")
