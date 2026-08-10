
suppressPackageStartupMessages({
    library(readr)
    library(dplyr)
    library(stringr)
    library(purrr)
    library(tidyr)
})

manifest_path <- "config/app_manifest.csv"
registry_path <- "config/dataset_registry.csv"
data_raw_dir  <- "data-raw"

#-----------------------------------
# utilitários
#-----------------------------------

trim_na <- function(x) {
    x <- trimws(x)
    x[x == ""] <- NA_character_
    x
}

normalize_path <- function(x) {
    x <- gsub("\\\\", "/", x)
    x <- gsub("^\\./", "", x)
    x
}

split_multivalue <- function(x) {
    if (is.na(x) || trimws(x) == "") return(character(0))
    parts <- unlist(strsplit(x, "\\s*[;,]\\s*"))
    parts <- trimws(parts)
    parts[parts != ""]
}

infer_dataset_id <- function(db_file) {
    tools::file_path_sans_ext(basename(db_file))
}

extract_datasets_from_manifest <- function(manifest) {
    if (!"db_file" %in% names(manifest)) {
        stop("A coluna 'db_file' não foi encontrada no app_manifest.csv.")
    }

    manifest %>%
        transmute(value = db_file) %>%
        mutate(value = trim_na(value)) %>%
        filter(!is.na(value)) %>%
        mutate(value = map(value, split_multivalue)) %>%
        unnest(value) %>%
        mutate(db_file = normalize_path(value)) %>%
        filter(str_detect(db_file, "\\.(rds|parquet)$")) %>%
        distinct(db_file) %>%
        arrange(db_file) %>%
        pull(db_file)
}

find_rds_in_script <- function(script_path, db_file) {
    lines <- tryCatch(
        readLines(script_path, warn = FALSE, encoding = "UTF-8"),
        error = function(e) character(0)
    )
    
    if (length(lines) == 0) return(FALSE)
    
    txt <- paste(lines, collapse = "\n")
    txt <- normalize_path(txt)
    
    db_file_norm <- normalize_path(db_file)
    db_base <- basename(db_file_norm)
    
    str_detect(txt, fixed(db_file_norm)) || str_detect(txt, fixed(db_base))
}

find_build_script <- function(db_file, scripts) {
    hits <- scripts[map_lgl(scripts, find_rds_in_script, db_file = db_file)]
    hits <- normalize_path(hits)
    
    if (length(hits) == 0) return(NA_character_)
    if (length(hits) == 1) return(hits)
    
    paste(hits, collapse = ";")
}

detect_source_package <- function(build_script) {
    if (is.na(build_script) || build_script == "") return(NA_character_)
    
    first_script <- strsplit(build_script, ";", fixed = TRUE)[[1]][1]
    
    lines <- tryCatch(
        readLines(first_script, warn = FALSE, encoding = "UTF-8"),
        error = function(e) character(0)
    )
    
    if (length(lines) == 0) return(NA_character_)
    
    txt <- paste(lines, collapse = "\n")
    
    pkgs <- character(0)
    
    lib_matches <- str_match_all(
        txt,
        "(?:library|require)\\s*\\(\\s*['\"]?([A-Za-z0-9._]+)['\"]?\\s*\\)"
    )[[1]]
    
    if (nrow(lib_matches) > 0) {
        pkgs <- c(pkgs, lib_matches[, 2])
    }
    
    ns_matches <- str_match_all(
        txt,
        "requireNamespace\\s*\\(\\s*['\"]([A-Za-z0-9._]+)['\"]"
    )[[1]]
    
    if (nrow(ns_matches) > 0) {
        pkgs <- c(pkgs, ns_matches[, 2])
    }
    
    colon_matches <- str_match_all(
        txt,
        "([A-Za-z0-9._]+)::[A-Za-z0-9._]+"
    )[[1]]
    
    if (nrow(colon_matches) > 0) {
        pkgs <- c(pkgs, colon_matches[, 2])
    }
    
    pkgs <- unique(pkgs)
    pkgs <- pkgs[pkgs %in% c("datazoom.amazonia", "datazoom.social")]
    
    if (length(pkgs) == 0) return(NA_character_)
    
    paste(pkgs, collapse = ";")
}

#-----------------------------------
# leitura
#-----------------------------------

manifest <- read_csv(manifest_path, show_col_types = FALSE)

scripts <- list.files(
    path = data_raw_dir,
    pattern = "\\.[Rr]$",
    full.names = TRUE,
    recursive = TRUE
)

if (length(scripts) == 0) {
    stop("Nenhum script R encontrado em data-raw/.")
}

manifest_datasets <- extract_datasets_from_manifest(manifest)

if (length(manifest_datasets) == 0) {
    stop("Nenhum dataset (.rds ou .parquet) encontrado na coluna db_file do app_manifest.csv.")
}

#-----------------------------------
# montagem do registry
#-----------------------------------

registry <- tibble(
    db_file = manifest_datasets
) %>%
    mutate(
        dataset_id = infer_dataset_id(db_file),
        build_script = map_chr(db_file, ~ find_build_script(.x, scripts)),
        source_package = map_chr(build_script, detect_source_package),
        notes = case_when(
            is.na(build_script) ~ "NOT_FOUND_IN_DATA_RAW",
            str_detect(build_script, fixed(";")) ~ "MULTIPLE_MATCHES",
            TRUE ~ NA_character_
        )
    ) %>%
    mutate(
        build_function = case_when(
            str_detect(build_script, regex("aneel", ignore_case = TRUE)) ~ "load_aneel()",
            str_detect(build_script, regex("comex", ignore_case = TRUE)) ~ "load_br_trade()",
            str_detect(build_script, regex("censoagro", ignore_case = TRUE)) ~ "load_censoagro()",
            str_detect(build_script, regex("mapbiomas", ignore_case = TRUE)) ~ "load_mapbiomas()",
            str_detect(build_script, regex("pam", ignore_case = TRUE)) ~ "load_pam()",
            str_detect(build_script, regex("seeg", ignore_case = TRUE)) ~ "load_seeg()",
            str_detect(build_script, regex("prodes", ignore_case = TRUE)) ~ "load_prodes()",
            str_detect(build_script, regex("pnadc", ignore_case = TRUE)) ~ "load_pnadc()",
            str_detect(build_script, regex("sigmine", ignore_case = TRUE)) ~ "load_sigmine()",
            TRUE ~ NA_character_
        )
    ) %>%
    select(
        dataset_id,
        db_file,
        build_script,
        build_function,
        source_package,
        notes
    ) %>%
    arrange(db_file)

#-----------------------------------
# salva
#-----------------------------------

write_csv(registry, registry_path, na = "")

message("dataset_registry.csv atualizado em: ", registry_path)
message("Total de linhas: ", nrow(registry))
message("Sem correspondência em data-raw: ", sum(is.na(registry$build_script)))
message("Com múltiplas correspondências: ", sum(registry$notes == "MULTIPLE_MATCHES", na.rm = TRUE))