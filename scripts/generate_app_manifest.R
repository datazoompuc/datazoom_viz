generate_app_manifest <- function(
    app_dir = ".",
    output_csv = "config/app_manifest.csv"
) {
  app_files <- list.files(
    path = file.path(app_dir, "apps"),
    pattern = "^app_.*\\.[Rr]$",
    full.names = TRUE
  )
  
  extract_assignments <- function(lines) {
    pattern <- 'files\\$([A-Za-z0-9_]+)\\s*<-\\s*["\\\']([^"\\\']+)["\\\']'
    hits <- regexec(pattern, lines, perl = TRUE)
    matches <- regmatches(lines, hits)
    
    out <- list()
    for (m in matches) {
      if (length(m) == 3) {
        field <- m[2]
        value <- m[3]
        
        if (is.null(out[[field]])) {
          out[[field]] <- value
        } else {
          out[[field]] <- unique(c(out[[field]], value))
        }
      }
    }
    out
  }
  
  collapse_values <- function(x) {
    if (is.null(x)) return("")
    x <- unique(unlist(x))
    x <- x[!is.na(x) & nzchar(x)]
    if (length(x) == 0) return("")
    paste(x, collapse = ";")
  }
  
  normalize_manifest_path <- function(path) {
    if (is.null(path) || length(path) == 0 || is.na(path) || path == "") {
      return("")
    }
    path <- gsub("\\\\", "/", path)
    sub("^(\\.\\./)+", "", path)
  }
  
  normalize_manifest_field <- function(x) {
    if (is.null(x) || length(x) == 0 || is.na(x) || x == "") {
      return("")
    }
    
    vals <- trimws(unlist(strsplit(x, ";", fixed = TRUE)))
    vals <- vals[nzchar(vals)]
    vals <- vapply(vals, normalize_manifest_path, character(1))
    vals <- unique(vals[nzchar(vals)])
    
    paste(vals, collapse = ";")
  }
  
  detect_language_mode <- function(app_name, fields) {
    has_pt <- !is.null(fields$param_file_pt)
    has_en <- !is.null(fields$param_file_en)
    
    if (has_pt && has_en) return("both")
    if (grepl("_en$", app_name)) return("en")
    return("pt")
  }
  
  rows <- lapply(app_files, function(app_path) {
    lines <- readLines(app_path, warn = FALSE, encoding = "UTF-8")
    fields <- extract_assignments(lines)
    
    app_name <- sub("\\.[Rr]$", "", basename(app_path))
    app_id <- sub("^app_", "", app_name)
    
    dictionary_values <- unique(c(
      if (!is.null(fields$param_file)) fields$param_file else NULL,
      if (!is.null(fields$param_file_pt)) fields$param_file_pt else NULL,
      if (!is.null(fields$param_file_en)) fields$param_file_en else NULL
    ))
    
    known_fields <- c(
      "ui_script",
      "server_script",
      "param_script",
      "CSS_script",
      "param_file",
      "param_file_pt",
      "param_file_en",
      "db_file"
    )

    # Qualquer variavel files$db_file* (ex.: db_file_sh2_munic) e tratada como
    # dataset e vai para a coluna db_file
    db_file_fields <- grep("^db_file", names(fields), value = TRUE)
    db_file_values <- unique(unlist(fields[db_file_fields]))

    extra_candidates <- setdiff(names(fields), c(known_fields, db_file_fields))
    extra_values <- unname(unlist(fields[extra_candidates]))
    extra_values <- unique(extra_values[!is.na(extra_values) & nzchar(extra_values)])
    
    data.frame(
      app_id = app_id,
      language_mode = detect_language_mode(app_id, fields),
      app_script = file.path("apps", basename(app_path)),
      ui_script = normalize_manifest_field(collapse_values(fields$ui_script)),
      server_script = normalize_manifest_field(collapse_values(fields$server_script)),
      param_script = normalize_manifest_field(collapse_values(fields$param_script)),
      css_file = normalize_manifest_field(collapse_values(fields$CSS_script)),
      dictionary_files = normalize_manifest_field(collapse_values(dictionary_values)),
      db_file = normalize_manifest_field(collapse_values(db_file_values)),
      extra_files = normalize_manifest_field(collapse_values(extra_values)),
      stringsAsFactors = FALSE
    )
  })
  
  manifest <- do.call(rbind, rows)
  
  dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
  write.csv(manifest, output_csv, row.names = FALSE, na = "")
  
  message("Manifesto salvo em: ", normalizePath(output_csv))
  manifest
}
  
generate_app_manifest()
