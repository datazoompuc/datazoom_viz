# Carrega o pacote
library(datazoom.amazonia)

if (!dir.exists("data")) {
  stop("Pasta 'data/' não encontrada. Rode o script a partir da raiz do repositório (datazoom_viz).")
}

# Parâmetros de ano
ano_inicial <- 2007
ano_final_manual <- NULL

# Obtém os anos disponíveis dinamicamente
anos_disponiveis <- function(dataset) {
  anos_fonte <- datazoom.amazonia:::parse_years(
    datazoom.amazonia:::dataset_meta("prodes", dataset, "available_time")
  )
  if (length(anos_fonte) == 0) {
    stop("O manifest do pacote não traz o available_time de prodes/", dataset)
  }
  ultimo_ano <- if (is.null(ano_final_manual)) max(anos_fonte) else ano_final_manual
  anos_fonte[anos_fonte >= ano_inicial & anos_fonte <= ultimo_ano]
}

# 1. Base de desmatamento
prodes_deforestation <- load_prodes(
  dataset = "deforestation",
  time_period = anos_disponiveis("deforestation"),
  raw_data = FALSE,
  language = "pt"
)

stopifnot(
  nrow(prodes_deforestation) > 0,
  !anyDuplicated(prodes_deforestation[c("cod_ibge", "ano")]),
  !anyNA(prodes_deforestation$desmatamento_km2)
)
saveRDS(prodes_deforestation, file = "./data/prodes_deforestation.rds")

# 2. Base de desmatamento residual
prodes_residual_deforestation <- load_prodes(
  dataset = "residual_deforestation",
  time_period = anos_disponiveis("residual_deforestation"),
  raw_data = FALSE,
  language = "pt"
)

stopifnot(
  nrow(prodes_residual_deforestation) > 0,
  !anyDuplicated(prodes_residual_deforestation[c("cod_ibge", "ano")]),
  !anyNA(prodes_residual_deforestation$desmatamento_residual_km2)
)
saveRDS(prodes_residual_deforestation, file = "./data/prodes_residual_deforestation.rds")

# 3. Base de vegetação nativa
prodes_native_vegetation <- load_prodes(
  dataset = "native_vegetation",
  time_period = anos_disponiveis("native_vegetation"),
  raw_data = FALSE,
  language = "pt"
)

stopifnot(
  nrow(prodes_native_vegetation) > 0,
  !anyDuplicated(prodes_native_vegetation[c("cod_ibge", "ano")]),
  !anyNA(prodes_native_vegetation$vegetacao_nativa_km2)
)
saveRDS(prodes_native_vegetation, file = "./data/prodes_native_vegetation.rds")

# 4. Base de não-floresta
prodes_non_forest <- load_prodes(
  dataset = "non_forest",
  time_period = anos_disponiveis("non_forest"),
  raw_data = FALSE,
  language = "pt"
)

stopifnot(
  nrow(prodes_non_forest) > 0,
  !anyDuplicated(prodes_non_forest[c("cod_ibge", "ano")]),
  !anyNA(prodes_non_forest$nao_floresta_km2)
)
saveRDS(prodes_non_forest, file = "./data/prodes_non_forest.rds")
