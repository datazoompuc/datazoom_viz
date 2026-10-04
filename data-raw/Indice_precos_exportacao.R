# Índice de preços de exportação (MDIC) -> data/indice_precos_anual.csv
# Usado pelos apps de série/ranking do COMEX para deflacionar valores em US$ (base 1998 = 100).
#
# Fonte: https://balanca.economia.gov.br/balanca/IPQ/totais_mes.html
# ("Baixar: Dados brutos (.csv)"). A série começa em 1998, por isso a base 100 é 1998.
#
# Como atualizar:
#   1. Rode este script a partir da raiz do repositório (setwd("~/datazoom_viz")).
#   2. Se `url_ipq` estiver preenchida, o arquivo é baixado automaticamente.
#      Se estiver NULL, baixe o CSV na página acima e salve em data/Dados_totais_mensal.csv.

library(tidyverse)

# Cole aqui o endereço do botão "Baixar: Dados brutos (.csv)" (botão direito -> copiar endereço do link)
url_ipq <- NULL

arquivo_bruto <- "data/Dados_totais_mensal.csv"

if (!dir.exists("data")) {
  stop("Pasta 'data/' não encontrada em ", getwd(), ". Rode setwd() para a raiz do repositório.")
}

if (!is.null(url_ipq)) {
  options(timeout = max(300, getOption("timeout")))
  download.file(url_ipq, arquivo_bruto, mode = "wb")
} else if (!file.exists(arquivo_bruto)) {
  stop("Arquivo ", arquivo_bruto, " não encontrado. Baixe o CSV em ",
       "https://balanca.economia.gov.br/balanca/IPQ/totais_mes.html e salve nesse caminho.")
}

indice_precos_quantum <- read_csv2(
  arquivo_bruto,
  col_names = TRUE,
  col_types = cols(
    TIPO = col_character(),
    TIPO_INDICE = col_character(),
    CO_ANO = col_number(),
    CO_MES = col_number(),
    NO_CLASSIFICACAO = col_character(),
    INDICE = col_double()
  )
)

indice_precos <- indice_precos_quantum %>%
  filter(TIPO == "EXP" & TIPO_INDICE == "PRECO") %>%
  select(CO_ANO, CO_MES, INDICE)

stopifnot(nrow(indice_precos) > 0)

ult <- indice_precos %>% arrange(desc(CO_ANO), desc(CO_MES)) %>% slice(1)
message("Índice de preços de exportação: último dado = ", ult$CO_ANO, "-", sprintf("%02d", ult$CO_MES))

# Valor anual = média dos meses disponíveis (o último ano pode ser parcial)
indice_precos_anual <- aggregate(INDICE ~ CO_ANO, indice_precos, mean)
indice_precos_anual <- indice_precos_anual[order(indice_precos_anual$CO_ANO), ]

# Reescala para base 100 em 1998
indice_ref <- indice_precos_anual$INDICE[indice_precos_anual$CO_ANO == 1998]
stopifnot(length(indice_ref) == 1)
indice_precos_anual$indice_anual_base1998 <- indice_precos_anual$INDICE / indice_ref * 100
rownames(indice_precos_anual) <- NULL

write.csv(indice_precos_anual, file = "data/indice_precos_anual.csv", row.names = TRUE)
