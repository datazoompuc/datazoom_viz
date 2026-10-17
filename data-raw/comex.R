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
#### O ano final é o último disponível na fonte (ver ultimo_ano_fonte).
#### O ano mais recente pode ser parcial: a base central traz as colunas
#### n_meses e ano_parcial para marcar isso.
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
library(httr2)
library(jsonlite)
library(sf)

# Parâmetros
ano_inicial      <- 1997
ano_final_manual <- NULL   # use só se o site do MDIC não deixar detectar o último ano (ex.: 2026)

# Os caminhos abaixo são relativos à raiz do repositório (datazoom_viz).
# Confere antes de baixar qualquer coisa, para não perder os downloads.
if (!dir.exists("data")) {
    stop("Pasta 'data/' não encontrada em ", getwd(),
         ". Rode setwd() para a raiz do repositório e tente de novo.")
}

# Os arquivos anuais do MDIC têm ~50 MB; o timeout padrão do R (60 s) é curto
options(timeout = max(1200, getOption("timeout")))

# ----------------------------------------------------------------
# Acesso ao site do MDIC
# ----------------------------------------------------------------
# O site balanca.economia.gov.br está com a cadeia de certificado incompleta
# (erro SSL 60) e a verificação sempre falha. Por isso as requisições vão
# direto, sem verificar o certificado. Vale só para estes arquivos públicos
# do MDIC (decisão combinada com o Antônio).
mdic_estado <- new.env()
mdic_estado$sem_verificacao <- TRUE

mdic_get <- function(url, metodo = "GET") {
    req <- httr2::request(url)
    req <- httr2::req_method(req, metodo)
    req <- httr2::req_timeout(req, 1200)
    req <- httr2::req_options(req, ssl_verifypeer = 0L)
    # o status HTTP é tratado por quem chama
    req <- httr2::req_error(req, is_error = function(resp) FALSE)
    tryCatch(
        httr2::req_perform(req),
        error = function(e) {
            stop("Não consegui conectar ao MDIC (", url, "): ", rlang::cnd_message(e),
                 "\nConfira a internet ou se o site está fora do ar e tente de novo mais tarde.",
                 call. = FALSE)
        }
    )
}

# Corpo da resposta como texto (APIs JSON do Comex Stat); erro se o status não for 2xx
mdic_texto <- function(url) {
    resp <- mdic_get(url)
    httr2::resp_check_status(resp)
    httr2::resp_body_string(resp, encoding = "UTF-8")
}

# Baixa um arquivo pequeno para uma pasta temporária e devolve o caminho
mdic_arquivo <- function(url, extensao = ".csv") {
    resp <- mdic_get(url)
    httr2::resp_check_status(resp)
    destino <- tempfile(fileext = extensao)
    writeBin(httr2::resp_body_raw(resp), destino)
    destino
}

# Último ano disponível na fonte: confere (sem baixar o arquivo) se o CSV anual
# do MDIC existe, do ano atual para trás.
ultimo_ano_fonte <- function(ano_inicial) {
    for (a in as.integer(format(Sys.Date(), "%Y")):ano_inicial) {
        url <- sprintf("https://balanca.economia.gov.br/balanca/bd/comexstat-bd/mun/EXP_%d_MUN.csv", a)
        r <- mdic_get(url, "HEAD")
        if (httr2::resp_status(r) == 200) {
            tipo <- httr2::resp_header(r, "content-type")
            tam  <- suppressWarnings(as.numeric(httr2::resp_header(r, "content-length")))
            if (length(tam) == 0) tam <- NA_real_
            # o servidor devolve 200 até para ano que não existe (página HTML);
            # só conta se for arquivo de dados
            if (!is.null(tipo) && !grepl("html", tipo, ignore.case = TRUE) &&
                (is.na(tam) || tam > 1e5)) return(a)
        }
        message(a, ": indisponível")
    }
    stop("Nenhum ano disponível na fonte a partir de ", ano_inicial)
}

ano_final <- if (!is.null(ano_final_manual)) {
    ano_final_manual
} else {
    tryCatch(ultimo_ano_fonte(ano_inicial), error = function(e) {
        stop(conditionMessage(e),
             "\nSe o problema for só detectar o último ano, defina ano_final_manual no topo do script.",
             call. = FALSE)
    })
}
message("COMEX: ", ano_inicial, " a ", ano_final)

# load_br_trade() baixa por dentro do pacote (utils::download.file). Se o MDIC
# estiver com o certificado incompleto, usa o curl do sistema sem verificação,
# só durante esta chamada.
opcoes_antigas <- options()[c("download.file.method", "download.file.extra")]
if (mdic_estado$sem_verificacao) {
    options(download.file.method = "curl", download.file.extra = "-k -L")
}
municipios_amz <- datazoom.amazonia::municipalities[, c("code_muni", "legal_amazon")]

# O servidor do MDIC derruba conexões ao acaso em downloads grandes. Por isso o
# download é feito ano a ano, com repetição automática, e cada ano concluído fica
# guardado numa pasta temporária: se algo falhar, rodar de novo retoma de onde parou.
pasta_cache <- file.path(tempdir(), "comex_anos")
dir.create(pasta_cache, showWarnings = FALSE)

baixar_ano <- function(a, tentativas = 5) {
    arq <- file.path(pasta_cache, paste0("ano_", a, ".rds"))
    if (file.exists(arq)) return(readRDS(arq))
    for (i in seq_len(tentativas)) {
        d <- tryCatch(
            load_br_trade(dataset = "export_mun", language = "pt",
                          time_period = a, raw_data = FALSE),
            error = function(e) {
                message(a, ": tentativa ", i, " de ", tentativas, " falhou")
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

dat <- tryCatch(
    dplyr::bind_rows(lapply(ano_inicial:ano_final, baixar_ano)),
    finally = options(opcoes_antigas)
)


# ================================================================
# AUXILIARES
# ================================================================


# --- Países (aux1) ---
# API MDIC: nomes em PT e EN para o mapa de tradução e para o dataset tot_pais/pais_sec/sec_pais
url <- "https://api-comexstat.mdic.gov.br/general/filters/country?language=pt"
txt <- mdic_texto(url)
obj <- fromJSON(txt, simplifyDataFrame = TRUE)

d <- obj$data
# a doc mostra que às vezes vem aninhado; isso deixa robusto:
if (is.list(d) && length(d) == 1 && is.data.frame(d[[1]])) d <- d[[1]]

aux1 <- as_tibble(d) %>%
    transmute(
        SISCOMEX  = str_pad(id, 3, pad = "0"),
        NO_PT = text
    ) %>%
    distinct(SISCOMEX, .keep_all = TRUE)

# nomes em inglês (mesma API, language=en) para gerar os dicionários EN sem tradução manual
d_en <- fromJSON(mdic_texto("https://api-comexstat.mdic.gov.br/general/filters/country?language=en"), simplifyDataFrame = TRUE)$data
if (is.list(d_en) && length(d_en) == 1 && is.data.frame(d_en[[1]])) d_en <- d_en[[1]]

aux1_en <- as_tibble(d_en) %>%
    transmute(
        SISCOMEX = str_pad(id, 3, pad = "0"),
        NO_EN    = text
    ) %>%
    distinct(SISCOMEX, .keep_all = TRUE)

aux1 <- left_join(aux1, aux1_en, by = "SISCOMEX")
saveRDS(aux1, "data/auxiliar_cod_pais.rds")



# --- Hierarquia de produto (aux2) ---
# Fonte: NCM_SH.csv do MDIC — hierarquia completa SH4 → SH2 → SEC em PT e EN.
# Os blocos de dados usam NO_SH2_PT e NO_SEC_PT para agregar; as colunas *_EN
# servem para gerar os dicionários EN direto da fonte, sem traduções manuais.
ncm_sh <- readr::read_csv2(
    mdic_arquivo("https://balanca.economia.gov.br/balanca/bd/tabelas/NCM_SH.csv"),
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
