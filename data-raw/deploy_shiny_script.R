deploy_shiny_script <- function(
    script,                 # ex: "app_rk_comex_exp_munic_produtosamz.R"
    account = "datazoom",
    server  = "shinyapps.io",
    extra = c("global", "www"), # pastas/arquivos extras
    forceUpdate = TRUE
) {
  stopifnot(file.exists(script))
  
  # appName = nome do script sem extensão
  appName <- sub("\\.[Rr]$", "", basename(script))
  
  # pasta do app = appName sem prefixo "app_"
  app_folder <- sub("_en$", "", sub("^app_", "", appName))
  
  td <- tempfile(paste0("deploy_", appName, "_"))
  dir.create(td, recursive = TRUE, showWarnings = FALSE)
  
  # 1) Copia o script como app.R, entrypoint padrão do Shiny
  file.copy(script, file.path(td, "app.R"), overwrite = TRUE)
  
  # inclui pasta específica do app + extras
  include <- c(app_folder, extra)
  
  # 2) Copia o resto (pastas/arquivos) que o app usa
  copy_any <- function(p) {
    if (!file.exists(p)) stop("Não achei: ", p)
    dest <- file.path(td, p)
    
    if (dir.exists(p)) {
      dir.create(dest, recursive = TRUE, showWarnings = FALSE)
      files <- list.files(p, all.files = TRUE, full.names = TRUE, recursive = TRUE)
      ok <- file.copy(files, file.path(td, p), overwrite = TRUE, recursive = TRUE)
      if (!all(ok)) warning("Falha ao copiar alguns arquivos de: ", p)
    } else {
      ok <- file.copy(p, dest, overwrite = TRUE)
      if (!ok) warning("Falha ao copiar: ", p)
    }
  }
  
  
  invisible(lapply(include, copy_any))
  
  # 3) Deploy do staging dir
  rsconnect::deployApp(
    appDir = td,
    appName = appName,
    account = account,
    server  = server,
    forceUpdate = forceUpdate
  )
}


deploy_shiny_script("app_SEU_APP.R") # Se o app precisar de algum arquivo extra, passe da seguinte forma: extra = c("global", "www", "nome_arquivo.csv")


# ver log de erro
# rsconnect::showLogs(appName = "app_SEU_APP", account = "datazoom")