# scripts/check_pnadc_updates.R

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(purrr)
  library(stringr)
  library(httr)
  library(tibble)
})

registry_path <- "config/dataset_registry.csv"
output_path   <- "reports/pnadc_update_status.csv"

normalize_path <- function(x) {
  x <- gsub("\\\\", "/", x)
  x <- gsub("^\\./", "", x)
  x
}

# -----------------------------
# 1) último ano-trimestre local
# -----------------------------
get_local_last_yq <- function(path) {
  path <- normalize_path(path)
  
  if (!file.exists(path)) {
    return(tibble(
      local_year = NA_integer_,
      local_quarter = NA_integer_,
      local_yq = NA_character_,
      local_status = "RDS_MISSING",
      local_message = "Arquivo não encontrado"
    ))
  }
  
  obj <- tryCatch(readr::read_rds(path), error = function(e) e)
  
  if (inherits(obj, "error")) {
    return(tibble(
      local_year = NA_integer_,
      local_quarter = NA_integer_,
      local_yq = NA_character_,
      local_status = "READ_ERROR",
      local_message = conditionMessage(obj)
    ))
  }
  
  if (!is.data.frame(obj)) {
    return(tibble(
      local_year = NA_integer_,
      local_quarter = NA_integer_,
      local_yq = NA_character_,
      local_status = "NOT_A_DATAFRAME",
      local_message = "O .rds não contém data.frame/tibble"
    ))
  }
  
  if (!all(c("Ano", "Trimestre") %in% names(obj))) {
    return(tibble(
      local_year = NA_integer_,
      local_quarter = NA_integer_,
      local_yq = NA_character_,
      local_status = "MISSING_TIME_COLUMNS",
      local_message = "Colunas Ano e/ou Trimestre ausentes"
    ))
  }
  
  yq <- obj %>%
    transmute(
      Ano = suppressWarnings(as.integer(Ano)),
      Trimestre = suppressWarnings(as.integer(Trimestre))
    ) %>%
    filter(!is.na(Ano), !is.na(Trimestre), Trimestre %in% 1:4) %>%
    distinct() %>%
    arrange(desc(Ano), desc(Trimestre))
  
  if (nrow(yq) == 0) {
    return(tibble(
      local_year = NA_integer_,
      local_quarter = NA_integer_,
      local_yq = NA_character_,
      local_status = "NO_VALID_YQ",
      local_message = "Sem valores válidos de Ano/Trimestre"
    ))
  }
  
  last <- yq[1, ]
  
  tibble(
    local_year = last$Ano[[1]],
    local_quarter = last$Trimestre[[1]],
    local_yq = paste0(last$Ano[[1]], "-", last$Trimestre[[1]]),
    local_status = "OK",
    local_message = NA_character_
  )
}

# -----------------------------------------
# 2) último ano-trimestre remoto no IBGE
# -----------------------------------------
file_exists_remote <- function(year, quarter, timeout_sec = 60) {
  url <- sprintf(
    paste0(
      "https://ftp.ibge.gov.br/Trabalho_e_Rendimento/",
      "Pesquisa_Nacional_por_Amostra_de_Domicilios_continua/",
      "Trimestral/Microdados/%d/PNADC_0%d%d.zip"
    ),
    year, quarter, year
  )
  
  resp <- tryCatch(
    httr::GET(
      url,
      httr::timeout(timeout_sec),
      httr::add_headers(Range = "bytes=0-0")
    ),
    error = function(e) NULL
  )
  
  if (is.null(resp)) return(FALSE)
  
  httr::status_code(resp) %in% c(200, 206)
}

get_remote_latest_yq <- function(start_year = as.integer(format(Sys.Date(), "%Y")),
                                 min_year = 2012L) {
  for (yy in seq(start_year, min_year, by = -1)) {
    for (qq in 4:1) {
      if (file_exists_remote(yy, qq)) {
        return(tibble(
          remote_year = yy,
          remote_quarter = qq,
          remote_yq = paste0(yy, "-", qq),
          remote_status = "OK",
          remote_message = NA_character_
        ))
      }
    }
  }
  
  tibble(
    remote_year = NA_integer_,
    remote_quarter = NA_integer_,
    remote_yq = NA_character_,
    remote_status = "REMOTE_NOT_FOUND",
    remote_message = "Não encontrei nenhum trimestre remoto"
  )
}

# -----------------------------
# 3) ler registry
# -----------------------------
registry <- readr::read_csv(registry_path, show_col_types = FALSE)

pnadc_registry <- registry %>%
  filter(stringr::str_detect(coalesce(build_function, ""), "load_pnadc")) %>%
  transmute(
    dataset_id = coalesce(dataset_id, basename(db_file)),
    db_file = normalize_path(db_file)
  ) %>%
  distinct()

if (nrow(pnadc_registry) == 0) {
  stop("Nenhuma linha com build_function contendo 'load_pnadc' encontrada no dataset_registry.csv.")
}

# -----------------------------
# 4) checagem local
# -----------------------------
local_report <- pnadc_registry %>%
  mutate(info = map(db_file, get_local_last_yq)) %>%
  tidyr::unnest(info)

# -----------------------------
# 5) checagem remota
# -----------------------------
remote_info <- get_remote_latest_yq()

# -----------------------------
# 6) comparação final
# -----------------------------
final_report <- local_report %>%
  mutate(
    remote_year = remote_info$remote_year[[1]],
    remote_quarter = remote_info$remote_quarter[[1]],
    remote_yq = remote_info$remote_yq[[1]],
    update_status = case_when(
      local_status != "OK" ~ local_status,
      remote_info$remote_status[[1]] != "OK" ~ remote_info$remote_status[[1]],
      remote_year > local_year ~ "OUTDATED",
      remote_year == local_year & remote_quarter > local_quarter ~ "OUTDATED",
      remote_year == local_year & remote_quarter == local_quarter ~ "UP_TO_DATE",
      remote_year < local_year |
        (remote_year == local_year & remote_quarter < local_quarter) ~ "LOCAL_AHEAD_OF_REMOTE",
      TRUE ~ "CHECK_FAILED"
    ),
    message = case_when(
      local_status != "OK" ~ local_message,
      remote_info$remote_status[[1]] != "OK" ~ remote_info$remote_message[[1]],
      TRUE ~ NA_character_
    )
  ) %>%
  select(
    dataset_id,
    db_file,
    local_yq,
    remote_yq,
    update_status,
    message
  ) %>%
  arrange(dataset_id)

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
readr::write_csv(final_report, output_path, na = "")

message("Relatório salvo em: ", output_path)
print(final_report)