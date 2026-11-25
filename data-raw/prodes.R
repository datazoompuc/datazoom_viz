# Get available years dynamically
anos_disponiveis <- function(dataset) {
  datazoom.amazonia:::parse_years(
    datazoom.amazonia:::dataset_meta("prodes", dataset, "available_time")
  )
}

# 1. Deforestation dataset
prodes_deforestation <- load_prodes(
  dataset = "deforestation",
  time_period = anos_disponiveis("deforestation"),
  raw_data = FALSE,
  language = "pt"
)

saveRDS(prodes_deforestation, file = "./data/prodes_deforestation.rds")

# 2. Residual deforestation dataset
prodes_residual_deforestation <- load_prodes(
  dataset = "residual_deforestation",
  time_period = anos_disponiveis("residual_deforestation"),
  raw_data = FALSE,
  language = "pt"
)

saveRDS(prodes_residual_deforestation, file = "./data/prodes_residual_deforestation.rds")

# 3. Native vegetation dataset
prodes_native_vegetation <- load_prodes(
  dataset = "native_vegetation",
  time_period = anos_disponiveis("native_vegetation"),
  raw_data = FALSE,
  language = "pt"
)

saveRDS(prodes_native_vegetation, file = "./data/prodes_native_vegetation.rds")

# 4. Non-forest dataset
prodes_non_forest <- load_prodes(
  dataset = "non_forest",
  time_period = anos_disponiveis("non_forest"),
  raw_data = FALSE,
  language = "pt"
)

saveRDS(prodes_non_forest, file = "./data/prodes_non_forest.rds")
