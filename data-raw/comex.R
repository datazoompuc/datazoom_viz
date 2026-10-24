############################################################
#### COMEX: exportações municipais da Amazônia Legal (MDIC)
#### Gera, em ./data/, a base longa comex_exp_munic_base.rds e as
#### auxiliares de código (países e hierarquia de produtos SH4/SH2/seção).
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
####   2. Auxiliares (países e hierarquia de produtos)
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
# O certificado de balanca.mdic.gov.br vem com a cadeia incompleta e, em alguns
# computadores (visto no macOS), o R não consegue verificá-lo. Por isso os
# downloads do MDIC usam o curl do sistema sem verificar o certificado
# (-k), só durante cada chamada e só para estes arquivos públicos (decisão
# combinada com o Antônio). As demais opções fazem o curl retomar o download de
# onde caiu, porque o servidor derruba conexões ao acaso em arquivos grandes.
opcoes_mdic <- list(
  download.file.method = "curl",
  download.file.extra  = "-k -L -C - --retry 30 --retry-all-errors --retry-delay 3 --speed-limit 5000 --speed-time 60"
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

dat <- dplyr::bind_rows(lapply(ano_inicial:ano_final, baixar_ano))


# ================================================================
# AUXILIARES
# ================================================================


# --- Países (aux1) ---
# API MDIC: nomes em PT e EN para o mapa de tradução e para o dataset tot_pais/pais_sec/sec_pais
paises_api <- function(idioma) {
  url <- paste0("https://api-comexstat.mdic.gov.br/general/filters/country?language=", idioma)
  d <- jsonlite::fromJSON(url, simplifyDataFrame = TRUE)$data
  # a doc mostra que às vezes vem aninhado; isso deixa robusto:
  if (is.list(d) && length(d) == 1 && is.data.frame(d[[1]])) d <- d[[1]]
  as_tibble(d) %>%
    transmute(SISCOMEX = str_pad(id, 3, pad = "0"), nome = text) %>%
    distinct(SISCOMEX, .keep_all = TRUE)
}

aux1 <- paises_api("pt") %>%
  rename(NO_PT = nome) %>%
  left_join(rename(paises_api("en"), NO_EN = nome), by = "SISCOMEX")
saveRDS(aux1, "data/auxiliar_cod_pais.rds")


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
saveRDS(aux2, "data/auxiliar_cod_sh4.rds")


# ================================================================
# BASE CENTRAL
# ================================================================
# Formato longo: ano × SH4 × município × UF. Sem deflator (decisão do
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
  mutate(cod_sh4 = sprintf("%04d", as.numeric(cod_sh4))) %>%
  group_by(ano, cod_sh4, cod_municipio, uf) %>%
  summarise(valor_fob = sum(valor_fob, na.rm = TRUE),
            kg_liquido = sum(kg_liquido, na.rm = TRUE),
            .groups = "drop") %>%
  left_join(meses_por_ano, by = "ano")

if (any(base$ano_parcial)) {
  message("Ano(s) parcial(is): ",
          paste(unique(base$ano[base$ano_parcial]), collapse = ", "))
}

# Checagens
stopifnot(!anyDuplicated(base[, c("ano", "cod_sh4", "cod_municipio")]))
stopifnot(isTRUE(all.equal(sum(base$valor_fob), sum(dat$valor_fob, na.rm = TRUE))))
stopifnot(isTRUE(all.equal(sum(base$kg_liquido), sum(dat$kg_liquido, na.rm = TRUE))))
stopifnot("kg_liquido" %in% names(base))

saveRDS(base, "data/comex_exp_munic_base.rds")