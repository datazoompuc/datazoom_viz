# Carrega os pacotes
library(tidyverse)
library(data.table)
library(datazoom.amazonia)

if (!dir.exists("data")) {
  stop("Pasta 'data/' não encontrada. Rode o script a partir da raiz do repositório (datazoom_viz).")
}

# Parâmetros de ano
ano_inicial <- 1995
ano_final_manual <- NULL

# Obtém os anos disponíveis dinamicamente do manifest
anos_fonte <- datazoom.amazonia:::parse_years(
  datazoom.amazonia:::dataset_meta("baci", "HS92", "available_time")
)
if (length(anos_fonte) == 0) {
  stop("O manifest do pacote não traz o available_time de baci/HS92.")
}
ultimo_ano <- if (is.null(ano_final_manual)) max(anos_fonte) else ano_final_manual
anos <- anos_fonte[anos_fonte >= ano_inicial & anos_fonte <= ultimo_ano]

# Baixa os dados brutos do BACI (HS92)
# raw_data = TRUE retorna lista de data.frames (um por ano) com colunas: t, i, j, k, v, q
raw <- load_baci(
  dataset     = "HS92",
  raw_data    = TRUE,
  time_period = anos
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
    ano     = as.integer(ano),
    cod_sh4 = substr(stringr::str_pad(as.character(k), 6, pad = "0"), 1, 4)
  ) |>
  dplyr::group_by(ano, cod_sh4) |>
  dplyr::summarise(valor_total = sum(valor, na.rm = TRUE), .groups = "drop")

# Conferências antes de gravar
stopifnot(
  nrow(world_trade_sh4) > 0,
  !anyDuplicated(world_trade_sh4[c("ano", "cod_sh4")]),
  !anyNA(world_trade_sh4$cod_sh4),
  !anyNA(world_trade_sh4$valor_total),
  all(anos %in% world_trade_sh4$ano)
)

# Salva o RDS final
saveRDS(
  world_trade_sh4,
  "data/auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci.rds"
)
