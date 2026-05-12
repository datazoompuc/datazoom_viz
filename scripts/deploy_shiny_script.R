deploy_shiny_script <- function(
        app_id,
        manifest = "config/app_manifest.csv",
        account = "datazoom",
        server = "shinyapps.io",
        extra = c("global", "apps/www"),
        forceUpdate = TRUE
) {
    man <- read.csv(manifest, stringsAsFactors = FALSE)
    
    row <- man[man$app_id == app_id, , drop = FALSE]
    
    if (nrow(row) == 0) {
        stop("App não encontrado no manifest: ", app_id)
    }
    
    if (nrow(row) > 1) {
        stop("Mais de uma linha encontrada no manifest para: ", app_id)
    }
    
    split_field <- function(x) {
        if (is.na(x) || x == "") return(character(0))
        trimws(unlist(strsplit(x, ";", fixed = TRUE)))
    }
    
    app_files <- unique(c(
        row$app_script,
        row$ui_script,
        row$server_script,
        row$param_script,
        row$css_file,
        split_field(row$dictionary_files),
        row$db_file,
        split_field(row$extra_files),
        extra
    ))
    
    app_files <- app_files[nzchar(app_files)]
    
    missing <- app_files[!file.exists(app_files)]
    if (length(missing) > 0) {
        stop(
            "Arquivos ausentes para o app ", app_id, ":\n",
            paste(missing, collapse = "\n")
        )
    }
    
    td <- tempfile(paste0("deploy_", app_id, "_"))
    dir.create(td, recursive = TRUE, showWarnings = FALSE)
    
    copy_one <- function(src) {
        dest <- file.path(td, if (dir.exists(src)) basename(src) else src)

        if (dir.exists(src)) {
            dir.create(dest, recursive = TRUE, showWarnings = FALSE)
            files <- list.files(src, all.files = TRUE, full.names = TRUE, recursive = TRUE)
            if (length(files) > 0) {
                file.copy(files, file.path(td, src), overwrite = TRUE, recursive = TRUE)
            }
        } else {
            dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
            ok <- file.copy(src, dest, overwrite = TRUE)
            if (!ok) stop("Falha ao copiar: ", src)
        }
    }
    
    invisible(lapply(app_files[app_files != row$app_script], copy_one))
    
    # Copia o app principal para a raiz do staging como app.R
    app_lines <- readLines(row$app_script, warn = FALSE, encoding = "UTF-8")
    
    # Reescreve paths relativos ao repo
    app_lines <- gsub("([\"'])\\.\\./scripts/", "\\1scripts/", app_lines, perl = TRUE)
    app_lines <- gsub("([\"'])\\.\\./data/",    "\\1data/",    app_lines, perl = TRUE)
    app_lines <- gsub("([\"'])\\.\\./global/",  "\\1global/",  app_lines, perl = TRUE)
    app_lines <- gsub("([\"'])\\.\\./www/",     "\\1www/",     app_lines, perl = TRUE)
    
    writeLines(app_lines, file.path(td, "app.R"), useBytes = TRUE)
    
    rsconnect::deployApp(
        appDir = td,
        appName = sub("\\.[Rr]$", "", basename(row$app_script)),
        account = account,
        server = server,
        forceUpdate = forceUpdate
    )
}


# deploy_shiny_script("app_id") # ex. "rk_comex_exp_munic_produtosamz"


# ver log de erro
# rsconnect::showLogs(appName = "app_app_id", account = "datazoom")
