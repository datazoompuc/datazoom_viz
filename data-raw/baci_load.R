library(tidyverse)

#baci_dir <- "CAMINHO/ARQUIVO/AQUI"


# lista de arquivos BACI por ano
arquivos <- list.files(baci_dir, pattern = "BACI_HS92_Y.*csv", full.names = TRUE)

# função para processar UM ano
processa_ano <- function(arq) {
  
  mensagem <- paste("Processando:", basename(arq))
  message(mensagem)
  
  df <- read.csv(arq)
  
  # renomeia colunas para manter compatibilidade 
  df <- df %>%
    rename(
      ano = t,
      exportador = i,
      importador = j,
      co_sh6 = k,
      valor = v,
      quantidade = q
    ) %>%
    mutate(
      cod_sh4 = substr(co_sh6, 1, 4),
      valor = as.numeric(valor)
    ) %>%
    group_by(ano, cod_sh4) %>%
    summarise(valor_total = sum(valor, na.rm = TRUE), .groups = "drop")
  
  return(df)
}

# aplica aos anos
world_trade_sh4 <- purrr::map_dfr(arquivos, processa_ano)

# salva RDS final
saveRDS(
  world_trade_sh4,
  "data/auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci.rds"
)

