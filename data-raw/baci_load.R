library(tidyverse)
library(data.table)

library(datazoom.amazonia)

# Baixa os dados brutos do BACI (HS92, V202601 — cobrindo 1995-2024)
# raw_data = TRUE retorna lista de data.frames (um por ano) com colunas: t, i, j, k, v, q
raw <- load_baci(
  dataset    = "HS92",
  raw_data   = TRUE,
  time_period = 1995:2024
)

# Combina todos os anos e agrega por ano + código SH4
# Nota: a coluna 'k' (código SH6) é lida como integer pelo fread,
# por isso aplica-se zero-padding para 6 dígitos antes de extrair os 4 primeiros.
world_trade_sh4 <- data.table::rbindlist(raw) |>
  tibble::as_tibble() |>
  dplyr::rename(
    ano   = t,
    valor = v
  ) |>
  dplyr::mutate(
    cod_sh4 = substr(stringr::str_pad(as.character(k), 6, pad = "0"), 1, 4)
  ) |>
  dplyr::group_by(ano, cod_sh4) |>
  dplyr::summarise(valor_total = sum(valor, na.rm = TRUE), .groups = "drop")

# Salva o RDS final
saveRDS(
  world_trade_sh4,
  "data/auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci.rds"
)
