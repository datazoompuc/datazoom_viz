############################################################
#### COMEX: exportações municipais da Amazônia Legal (MDIC)
#### Gera, em ./data/, a base longa comex_exp_munic_base.rds, já com os
#### nomes de município, país e produto (SH4/SH2/seção, em PT e EN). Não gera arquivos auxiliares.
####
#### Fonte: Comex Stat / MDIC, via datazoom.amazonia::load_br_trade
#### (dataset "export_mun"). Valores em US$ FOB (nominais, sem deflator)
#### e quantidade em kg líquido.
####
#### Para atualizar: rodar o script inteiro a partir da raiz do repositório.
#### O ano final é o último ano do available_time do manifest do pacote
#### (use ano_final_manual para forçar outro).
#### O ano mais recente pode ser parcial: a base central traz as colunas
#### n_meses e ano_parcial para marcar isso.
####
#### Requer o datazoom.amazonia com o dicionário do COMEX baixado por
#### download.file() (branch comex-dicionario-download-file, ou o master
#### depois do merge). Se ainda não estiver instalado, antes de rodar:
####   devtools::load_all("~/datazoom.amazonia")
####
#### Seções:
####   1. Download e dado bruto
####   2. Nomes de países e de produtos (só em memória, para juntar à base)
####   3. Base central (longo, com valor e quantidade)
############################################################

library(datazoom.amazonia)
library(magrittr)
library(tidyverse)
library(stringr)
library(jsonlite)
library(sf)

# Parâmetros
ano_inicial      <- 1997
ano_final_manual <- NULL   # use só para forçar um ano final diferente do manifest

# Os caminhos abaixo são relativos à raiz do repositório (datazoom_viz).
# Confere antes de baixar qualquer coisa, para não perder os downloads.
if (!dir.exists("data")) {
  stop("Pasta 'data/' não encontrada em ", getwd(),
       ". Rode setwd() para a raiz do repositório e tente de novo.")
}

# Os arquivos anuais do MDIC têm ~50 MB; o timeout padrão do R (60 s) é curto
options(timeout = max(1200, getOption("timeout")))

# ----------------------------------------------------------------
# Download dos arquivos do MDIC
# ----------------------------------------------------------------
# O servidor do MDIC (balanca.mdic.gov.br) derruba conexões ao acaso em arquivos
# grandes. Estas opções fazem o curl do sistema retomar o download de onde caiu
# e repetir em caso de erro. O certificado do servidor é verificado normalmente:
# o MDIC corrigiu a cadeia de certificado, então não é mais preciso ignorá-lo.
opcoes_mdic <- list(
  download.file.method = "curl",
  download.file.extra  = "-L -C - --retry 30 --retry-all-errors --retry-delay 3 --speed-limit 5000 --speed-time 60"
)

# Último ano disponível na fonte: vem do manifest do pacote (available_time das
# linhas do COMEX), que o pacote mantém atualizado.
ano_final <- ano_final_manual
if (is.null(ano_final)) {
  anos_fonte <- datazoom.amazonia:::parse_years(
    datazoom.amazonia:::dataset_meta("comex", "export_mun", "available_time")
  )
  if (length(anos_fonte) == 0) {
    stop("O manifest do pacote não traz o available_time do COMEX. ",
         "Defina ano_final_manual no topo do script.")
  }
  ano_final <- max(anos_fonte)
}
message("COMEX: ", ano_inicial, " a ", ano_final)

municipios_amz <- datazoom.amazonia::municipalities[, c("code_muni", "legal_amazon")]

# O download é feito ano a ano, com repetição automática, e cada ano concluído
# fica guardado numa pasta temporária: se algo falhar, rodar de novo retoma de
# onde parou (na mesma sessão do R).
pasta_cache <- file.path(tempdir(), "comex_anos")
dir.create(pasta_cache, showWarnings = FALSE)

baixar_ano <- function(a, tentativas = 5) {
  arq <- file.path(pasta_cache, paste0("ano_", a, ".rds"))
  if (file.exists(arq)) return(readRDS(arq))
  for (i in seq_len(tentativas)) {
    d <- tryCatch(
      withr::with_options(
        opcoes_mdic,
        load_br_trade(dataset = "export_mun", language = "pt",
                      time_period = a, raw_data = FALSE)
      ),
      error = function(e) {
        message(a, ": tentativa ", i, " de ", tentativas, " falhou: ",
                substr(paste(rlang::cnd_message(e), collapse = " "), 1, 400))
        NULL
      })
    if (!is.null(d)) {
      d <- inner_join(d, municipios_amz, by = c("cod_municipio" = "code_muni")) %>%
        filter(legal_amazon == 1) %>%
        select(-legal_amazon)
      saveRDS(d, arq)
      message(a, ": ok")
      return(d)
    }
    Sys.sleep(5 * i)
  }
  stop("Não consegui baixar ", a, " depois de ", tentativas, " tentativas. ",
       "Rode o script de novo (os anos já baixados são reaproveitados).", call. = FALSE)
}

# ----------------------------------------------------------------
# Checagem de atualizacao do COMEX via datazoom.amazonia
# ----------------------------------------------------------------
# Baixa o ano mais recente via load_br_trade e compara o ultimo mes/ano
# retornado com a base local ja salva em data/comex_exp_munic_base.rds.
# - Se nao houver dado novo (mesmo ano e mes): encerra o script sem reprocessar.
# - Se houver dado novo ou base inexistente: prossegue com a atualizacao.
arquivo_base_destino <- "data/comex_exp_munic_base.rds"
if (file.exists(arquivo_base_destino)) {
  message("Verificando se ha novos dados do COMEX para o ano ", ano_final, "...")
  amostra_ano_recente <- baixar_ano(ano_final)

  max_ano_novo <- as.integer(max(amostra_ano_recente[["ano"]], na.rm = TRUE))
  max_mes_novo <- as.integer(max(amostra_ano_recente[["mes"]][amostra_ano_recente[["ano"]] == max_ano_novo], na.rm = TRUE))

  base_salva <- readRDS(arquivo_base_destino)
  max_ano_salvo <- as.integer(max(base_salva[["ano"]], na.rm = TRUE))
  max_mes_salvo <- if ("n_meses" %in% names(base_salva)) {
    as.integer(max(base_salva[["n_meses"]][base_salva[["ano"]] == max_ano_salvo], na.rm = TRUE))
  } else if ("mes" %in% names(base_salva)) {
    as.integer(max(base_salva[["mes"]][base_salva[["ano"]] == max_ano_salvo], na.rm = TRUE))
  } else {
    NA_integer_
  }

  message(sprintf("COMEX - Base salva: %02d/%d | Dado baixado: %02d/%d",
                  max_mes_salvo, max_ano_salvo, max_mes_novo, max_ano_novo))

  if (!is.na(max_mes_salvo) &&
      identical(max_ano_novo, max_ano_salvo) &&
      identical(max_mes_novo, max_mes_salvo)) {
    message("Nenhum dado novo encontrado na COMEX. Encerrando o script.")
    quit(save = "no", status = 0)
  }

  message("Novo periodo disponivel na COMEX. Prosseguindo com o processamento da base...")
}

dat <- dplyr::bind_rows(lapply(ano_inicial:ano_final, baixar_ano))


# ================================================================
# AUXILIARES
# ================================================================


# --- Países (aux1) ---
# PAIS.csv: tabela de países do MDIC (código SISCOMEX e nome em português e em inglês).
# Fica na mesma pasta do NCM_SH.csv; a URL vem do manifest do pacote, trocando
# só o nome do arquivo.
arq_pais <- tempfile(fileext = ".csv")
withr::with_options(
  opcoes_mdic,
  utils::download.file(
    sub("NCM_SH\\.csv$", "PAIS.csv",
        datazoom.amazonia:::dataset_url("comex_dic", "hs_codes")),
    arq_pais, mode = "wb", quiet = TRUE
  )
)
aux1 <- readr::read_csv2(
  arq_pais,
  locale = readr::locale(encoding = "latin1"),
  col_types = readr::cols(.default = "c")
) %>%
  transmute(
    SISCOMEX = str_pad(str_trim(CO_PAIS), 3, pad = "0"),
    NO_PT    = str_trim(NO_PAIS),
    NO_EN    = str_trim(NO_PAIS_ING)
  ) %>%
  distinct(SISCOMEX, .keep_all = TRUE)
stopifnot(nrow(aux1) > 200)


# --- Hierarquia de produto (aux2) ---
# Fonte: NCM_SH.csv do MDIC — hierarquia completa SH4 → SH2 → SEC em PT e EN.
# Os blocos de dados usam NO_SH2_PT e NO_SEC_PT para agregar; as colunas *_EN
# servem para gerar os dicionários EN direto da fonte, sem traduções manuais.
# A URL vem do manifest do pacote (a mesma que o load_br_trade() usa).
arq_hs <- tempfile(fileext = ".csv")
withr::with_options(
  opcoes_mdic,
  utils::download.file(
    datazoom.amazonia:::dataset_url("comex_dic", "hs_codes"),
    arq_hs, mode = "wb", quiet = TRUE
  )
)
ncm_sh <- readr::read_csv2(
  arq_hs,
  locale = readr::locale(encoding = "latin1"),
  show_col_types = FALSE
)

aux2 <- ncm_sh %>%
  transmute(
    CO_SH4    = str_pad(as.character(CO_SH4), 4, pad = "0"),
    NO_SH4_PT = str_trim(NO_SH4_POR),   # posição (SH4) em PT
    NO_SH2_PT = str_trim(NO_SH2_POR),   # capítulo (SH2) em PT
    NO_SEC_PT = str_trim(NO_SEC_POR),   # seção (SEC) em PT
    NO_SH4_EN = str_trim(NO_SH4_ING),   # versões em inglês
    NO_SH2_EN = str_trim(NO_SH2_ING),
    NO_SEC_EN = str_trim(NO_SEC_ING)
  ) %>%
  distinct(CO_SH4, .keep_all = TRUE)


# --- Municípios (aux3) ---
# UF_MUN.csv: tabela de municípios do MDIC (código IBGE de 7 dígitos, nome e UF).
# Fica na mesma pasta do NCM_SH.csv e do PAIS.csv; a URL vem do manifest do
# pacote, trocando só o nome do arquivo. NO_MUN_MIN é o nome com acento; o rótulo
# fica como "Abadiânia - GO" (nome e UF), o mesmo formato que a base já tinha.
arq_mun <- tempfile(fileext = ".csv")
withr::with_options(
  opcoes_mdic,
  utils::download.file(
    sub("NCM_SH\\.csv$", "UF_MUN.csv",
        datazoom.amazonia:::dataset_url("comex_dic", "hs_codes")),
    arq_mun, mode = "wb", quiet = TRUE
  )
)
aux3 <- readr::read_csv2(
  arq_mun,
  locale = readr::locale(encoding = "latin1"),
  col_types = readr::cols(.default = "c")
) %>%
  transmute(
    cod_municipio = as.numeric(CO_MUN_GEO),
    municipio     = paste0(str_trim(NO_MUN_MIN), " - ", str_trim(SG_UF))
  ) %>%
  distinct(cod_municipio, .keep_all = TRUE)
stopifnot(nrow(aux3) > 5000)



# ================================================================
# BASE CENTRAL
# ================================================================
# Formato longo: ano × SH4 × município × UF × país de destino. Sem deflator (decisão do
# Antonio, out/2026): valor nominal em US$ FOB mais a quantidade em kg,
# que serve de base para qualquer cálculo de valor real depois.
#
# n_meses / ano_parcial: o ano mais recente costuma ter menos de 12 meses
# publicados (em 2026, só parte do ano). Mantido na base e marcado.
meses_por_ano <- dat %>%
  group_by(ano) %>%
  summarise(n_meses = n_distinct(mes), .groups = "drop") %>%
  mutate(ano_parcial = n_meses < 12)

base <- dat %>%
  mutate(cod_sh4  = sprintf("%04d", as.numeric(cod_sh4)),
         cod_pais = str_pad(as.character(cod_pais), 3, pad = "0")) %>%
  group_by(ano, cod_sh4, cod_municipio, uf, cod_pais) %>%
  summarise(valor_fob = sum(valor_fob, na.rm = TRUE),
            kg_liquido = sum(kg_liquido, na.rm = TRUE),
            .groups = "drop") %>%
  left_join(meses_por_ano, by = "ano") %>%
  left_join(
    transmute(aux1, cod_pais = SISCOMEX, pais_pt = NO_PT, pais_en = NO_EN),
    by = "cod_pais"
  ) %>%
  left_join(
    transmute(aux2, cod_sh4 = CO_SH4,
              sh4_pt = NO_SH4_PT, sh4_en = NO_SH4_EN,
              sh2_pt = NO_SH2_PT, sh2_en = NO_SH2_EN,
              sec_pt = NO_SEC_PT, sec_en = NO_SEC_EN),
    by = "cod_sh4"
  ) %>%
  mutate(cod_sh2 = substr(cod_sh4, 1, 2), .after = cod_sh4) %>%
  left_join(aux3, by = "cod_municipio") %>%
  relocate(municipio, .after = cod_municipio)

if (any(base$ano_parcial)) {
  message("Ano(s) parcial(is): ",
          paste(unique(base$ano[base$ano_parcial]), collapse = ", "))
}

# Checagens
stopifnot(!anyDuplicated(base[, c("ano", "cod_sh4", "cod_municipio", "cod_pais")]))
stopifnot(isTRUE(all.equal(sum(base$valor_fob), sum(dat$valor_fob, na.rm = TRUE))))
stopifnot(isTRUE(all.equal(sum(base$kg_liquido), sum(dat$kg_liquido, na.rm = TRUE))))
stopifnot("kg_liquido" %in% names(base))

# Nenhum nome pode ficar vazio depois das juncoes
rotulos <- c("municipio", "pais_pt", "pais_en", "sh4_pt", "sh4_en",
             "sh2_pt", "sh2_en", "sec_pt", "sec_en")
sem_rotulo <- vapply(rotulos, function(v) sum(is.na(base[[v]])), numeric(1))
if (any(sem_rotulo > 0)) {
  print(sem_rotulo[sem_rotulo > 0])
  print(base %>%
          filter(if_any(all_of(rotulos), is.na)) %>%
          distinct(cod_pais, cod_sh4) %>%
          head(30))
  stop("Há linhas sem nome de país ou de produto (códigos acima).", call. = FALSE)
}

saveRDS(base, "data/comex_exp_munic_base.rds")