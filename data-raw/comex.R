############################################################
#### COMEX: exportações municipais da Amazônia Legal (MDIC)
#### Gera todos os .rds e dicionários .csv da COMEX em ./data/
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
####   2. Auxiliares (países, SH4, municípios)
####   3. Base central (longo, com valor e quantidade)
####   4. Bases largas/transpostas (município, país × SH4/SH2/seção)
####   5. Dicionários das bases da seção 4
####   6. Mapa: principal produto por município (comex_exp_munic_sh4_sel)
####   7. Participação nas exportações mundiais (comex_exp_perc_sh4_sel)
############################################################

library(datazoom.amazonia)
library(magrittr)
library(tidyverse)
library(stringr)
library(httr)
library(jsonlite)
library(sf)

# Parâmetro
ano_inicial <- 1997
baixar      <- TRUE   # FALSE = pula o download e usa data/comex_munic_raw.rds já existente

# Os caminhos abaixo são relativos à raiz do repositório (datazoom_viz).
# Confere antes de baixar qualquer coisa, para não perder os downloads.
if (!dir.exists("data")) {
    stop("Pasta 'data/' não encontrada em ", getwd(),
         ". Rode setwd() para a raiz do repositório e tente de novo.")
}

# Os arquivos anuais do MDIC têm ~50 MB; o timeout padrão do R (60 s) é curto
options(timeout = max(1200, getOption("timeout")))

# Último ano disponível na fonte: confere (sem baixar o arquivo) se o CSV anual
# do MDIC existe, do ano atual para trás.
ultimo_ano_fonte <- function(ano_inicial) {
    for (a in as.integer(format(Sys.Date(), "%Y")):ano_inicial) {
        url <- sprintf("https://balanca.economia.gov.br/balanca/bd/comexstat-bd/mun/EXP_%d_MUN.csv", a)
        # Erro de conexão (site fora do ar, certificado inválido, sem internet) é
        # diferente de "ano ainda não publicado": para na hora, com o motivo,
        # em vez de varrer todos os anos e dizer que nenhum existe.
        r <- tryCatch(httr::HEAD(url, httr::timeout(60)),
                      error = function(e) {
                          stop("Não consegui conectar ao site do MDIC (", url, "): ",
                               conditionMessage(e),
                               "\nNão é problema do script: confira a internet ou se o site está com ",
                               "erro (por exemplo, certificado vencido) e tente de novo mais tarde.",
                               call. = FALSE)
                      })
        if (httr::status_code(r) == 200) {
            tipo <- httr::headers(r)[["content-type"]]
            tam  <- suppressWarnings(as.numeric(httr::headers(r)[["content-length"]]))
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

if (baixar) {
    ano_final <- ultimo_ano_fonte(ano_inicial)
    message("COMEX: ", ano_inicial, " a ", ano_final)
    
    dat <- load_br_trade(dataset = "export_mun", language = "pt",
                         time_period = ano_inicial:ano_final, raw_data = FALSE)
    
    dat <- inner_join(
        dat,
        datazoom.amazonia::municipalities[, c("code_muni", "legal_amazon")],
        by = c("cod_municipio" = "code_muni")
    ) %>% filter(legal_amazon == 1) %>%
        select(-legal_amazon)
    
    saveRDS(dat, file = "data/comex_munic_raw.rds")
} else {
    message("baixar = FALSE: usando o data/comex_munic_raw.rds que já existe (sem acessar o site do MDIC)")
}
dat <- readRDS(file = "data/comex_munic_raw.rds")

# ================================================================
# AUXILIARES
# ================================================================

if (baixar) {
    
    # --- Países (aux1) ---
    # API MDIC: nomes em PT e EN para o mapa de tradução e para o dataset tot_pais/pais_sec/sec_pais
    url <- "https://api-comexstat.mdic.gov.br/general/filters/country?language=pt"
    resp <- GET(url)
    stop_for_status(resp)
    
    txt <- content(resp, as = "text", encoding = "UTF-8")
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
    resp_en <- GET("https://api-comexstat.mdic.gov.br/general/filters/country?language=en")
    stop_for_status(resp_en)
    d_en <- fromJSON(content(resp_en, as = "text", encoding = "UTF-8"), simplifyDataFrame = TRUE)$data
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
        "https://balanca.economia.gov.br/balanca/bd/tabelas/NCM_SH.csv",
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
    
    
    
    # --- Municípios (aux3) ---
    url <- "https://api-comexstat.mdic.gov.br/cities/filters/city?language=pt"
    resp <- GET(url)
    stop_for_status(resp)
    
    txt <- content(resp, as = "text", encoding = "UTF-8")
    obj <- fromJSON(txt, simplifyDataFrame = TRUE)
    
    d <- obj$data
    if (is.list(d) && length(d) == 1 && is.data.frame(d[[1]])) d <- d[[1]]
    
    aux3 <- as_tibble(d) %>%
        transmute(
            codigo = str_pad(as.character(id), 7, pad = "0"),  # município costuma ser 7 dígitos (IBGE)
            nome   = text
        ) %>%
        distinct(codigo, .keep_all = TRUE)
    
    saveRDS(aux3, "data/auxiliar_cod_municipais.rds")
    
} else {
    # sem acesso à fonte: usa as auxiliares já salvas em data/
    aux1 <- readRDS("data/auxiliar_cod_pais.rds")
    aux2 <- readRDS("data/auxiliar_cod_sh4.rds")
    aux3 <- readRDS("data/auxiliar_cod_municipais.rds")
}


# --- Mapas PT → EN e helper de tradução ---
# Usados pelos blocos de dicionário EN abaixo para traduzir labels direto da fonte.
map_sec  <- aux2 %>% distinct(NO_SEC_PT, NO_SEC_EN); map_sec  <- setNames(map_sec$NO_SEC_EN, map_sec$NO_SEC_PT)
map_sh2  <- aux2 %>% distinct(NO_SH2_PT, NO_SH2_EN); map_sh2  <- setNames(map_sh2$NO_SH2_EN, map_sh2$NO_SH2_PT)
map_sh4  <- aux2 %>% distinct(NO_SH4_PT, NO_SH4_EN); map_sh4  <- setNames(map_sh4$NO_SH4_EN, map_sh4$NO_SH4_PT)
map_pais <- setNames(aux1$NO_EN, aux1$NO_PT)

# traduz um vetor de nomes PT usando um mapa; mantém o original se não encontrar
tr <- function(x, map) { out <- unname(map[x]); ifelse(is.na(out), x, out) }


matriz <- dat
aux1 <- readRDS("data/auxiliar_cod_pais.rds")
aux2 <- readRDS("data/auxiliar_cod_sh4.rds")
aux3 <- readRDS("data/auxiliar_cod_municipais.rds")



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


# ================================================================
# DATASETS
# ================================================================

# ----------------------------------------------------------------
# [1] Município × SH4
# Saída: comex_exp_munic_sh4.rds  (wide: time, group=posição SH4, cols=municípios)
#        comex_exp_sh4_munic.rds  (transposta: time, group=município, cols=posições SH4)
# ----------------------------------------------------------------

dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$cod_pais <- NULL

dat <- aggregate(valor_fob ~ ano + cod_sh4 + cod_municipio + uf, dat, sum)

dat$cod_sh4 <- sprintf("%04d", as.numeric(dat$cod_sh4))
aux2$CO_SH4 <- sprintf("%04d", as.numeric(aux2$CO_SH4))
# dat$cod_sh4 <- str_replace_all(dat$cod_sh4, setNames(aux2$NO_SH4_PT, aux2$CO_SH4))
dat$cod_municipio <- str_replace_all(dat$cod_municipio, setNames(aux3$nome, aux3$codigo))
# dat$cod_municipio <- paste(dat$cod_municipio, " - ",dat$uf)
dat$uf <- NULL

data_val <- dat
colnames(data_val) <- c("time", "type", "group", "value")
data_val <- aggregate(value ~ time + type + group, data_val, sum)

datafinal_val_munic <- reshape(data_val, idvar = c("time", "type"), timevar = "group", direction = "wide")
datafinal_val_sh2 <- reshape(data_val, idvar = c("time", "group"), timevar = "type", direction = "wide")

labl <- colnames(datafinal_val_munic)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo sem truncar
colnames(datafinal_val_munic) <- c("time", "group", labl)

labl <- colnames(datafinal_val_sh2)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo sem truncar
colnames(datafinal_val_sh2) <- c("time", "group", labl)

datafinal_val_munic[is.na(datafinal_val_munic)] <- 0
datafinal_val_sh2[is.na(datafinal_val_sh2)] <- 0

datafinal_val_munic <- datafinal_val_munic[order(datafinal_val_munic$group, datafinal_val_munic$time),]
datafinal_val_sh2 <- datafinal_val_sh2[order(datafinal_val_sh2$group, datafinal_val_sh2$time),]

stopifnot(!anyDuplicated(names(datafinal_val_sh2)))
stopifnot(!anyDuplicated(names(datafinal_val_munic)))

saveRDS(datafinal_val_munic, "data/comex_exp_munic_sh4.rds")
saveRDS(datafinal_val_sh2, "data/comex_exp_sh4_munic.rds")


# ----------------------------------------------------------------
# [2] Município × SH2
# Saída: comex_exp_munic_sh2.rds  (wide: time, group=capítulo SH2, cols=municípios)
#        comex_exp_sh2_munic.rds  (transposta: time, group=município, cols=capítulos SH2)
# ----------------------------------------------------------------

dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$cod_pais <- NULL

dat <- aggregate(valor_fob ~ ano + cod_sh4 + cod_municipio + uf, dat, sum)

dat$cod_sh4 <- sprintf("%04d", as.numeric(dat$cod_sh4))
aux2$CO_SH4 <- sprintf("%04d", as.numeric(aux2$CO_SH4))
dat$cod_sh4 <- str_replace_all(dat$cod_sh4, setNames(aux2$NO_SH2_PT, aux2$CO_SH4))
dat$cod_municipio <- str_replace_all(dat$cod_municipio, setNames(aux3$nome, aux3$codigo))
dat$uf <- NULL

data_val <- dat
colnames(data_val) <- c("time", "type", "group", "value")
data_val <- aggregate(value ~ time + type + group, data_val, sum)

datafinal_val_munic <- reshape(data_val, idvar = c("time", "type"), timevar = "group", direction = "wide")
datafinal_val_sh2 <- reshape(data_val, idvar = c("time", "group"), timevar = "type", direction = "wide")

labl <- colnames(datafinal_val_munic)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
colnames(datafinal_val_munic) <- c("time", "group", labl)

labl <- colnames(datafinal_val_sh2)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
colnames(datafinal_val_sh2) <- c("time", "group", labl)

datafinal_val_munic[is.na(datafinal_val_munic)] <- 0
datafinal_val_sh2[is.na(datafinal_val_sh2)] <- 0

datafinal_val_munic <- datafinal_val_munic[order(datafinal_val_munic$group, datafinal_val_munic$time),]
datafinal_val_sh2 <- datafinal_val_sh2[order(datafinal_val_sh2$group, datafinal_val_sh2$time),]

# Totais "Amazônia Legal" = soma de todos os municípios por ano.
sh2_cols <- setdiff(names(datafinal_val_sh2), c("time", "group"))
amazonia_legal <- aggregate(
    datafinal_val_sh2[, sh2_cols],
    by = list(time = datafinal_val_sh2$time),
    FUN = sum, na.rm = TRUE
)
amazonia_legal$group <- "Amazônia Legal"
amazonia_legal <- amazonia_legal[, c("time", "group", sh2_cols)]
datafinal_val_sh2 <- rbind(amazonia_legal, datafinal_val_sh2)

munic_cols <- setdiff(names(datafinal_val_munic), c("time", "group"))
datafinal_val_munic$`Amazônia Legal` <- rowSums(datafinal_val_munic[, munic_cols], na.rm = TRUE)

saveRDS(datafinal_val_munic, "data/comex_exp_munic_sh2.rds")
saveRDS(datafinal_val_sh2, "data/comex_exp_sh2_munic.rds")




# ----------------------------------------------------------------
# [4] Município × SEC
# Saída: comex_exp_munic_sec.rds  (wide: time, group=seção SEC, cols=municípios)
#        comex_exp_sec_munic.rds  (transposta: time, group=município, cols=seções SEC)
# ----------------------------------------------------------------

dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$cod_pais <- NULL

dat <- aggregate(valor_fob ~ ano + cod_sh4 + cod_municipio + uf, dat, sum)

dat$cod_sh4 <- sprintf("%04d", as.numeric(dat$cod_sh4))
aux2$CO_SH4 <- sprintf("%04d", as.numeric(aux2$CO_SH4))
dat$cod_sh4 <- str_replace_all(dat$cod_sh4, setNames(aux2$NO_SEC_PT, aux2$CO_SH4))
dat$cod_municipio <- str_replace_all(dat$cod_municipio, setNames(aux3$nome, aux3$codigo))
dat$uf <- NULL

data_val <- dat
colnames(data_val) <- c("time", "type", "group", "value")
data_val <- aggregate(value ~ time + type + group, data_val, sum)

datafinal_val_munic <- reshape(data_val, idvar = c("time", "type"), timevar = "group", direction = "wide")
datafinal_val_sec <- reshape(data_val, idvar = c("time", "group"), timevar = "type", direction = "wide")

labl <- colnames(datafinal_val_munic)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
colnames(datafinal_val_munic) <- c("time", "group", labl)

labl <- colnames(datafinal_val_sec)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
colnames(datafinal_val_sec) <- c("time", "group", labl)

datafinal_val_munic[is.na(datafinal_val_munic)] <- 0
datafinal_val_sec[is.na(datafinal_val_sec)] <- 0

datafinal_val_munic <- datafinal_val_munic[order(datafinal_val_munic$group, datafinal_val_munic$time),]
datafinal_val_sec <- datafinal_val_sec[order(datafinal_val_sec$group, datafinal_val_sec$time),]

# Totais "Amazônia Legal" = soma de todos os municípios por ano (espelha a seção [2]).
sec_cols <- setdiff(names(datafinal_val_sec), c("time", "group"))
amazonia_legal <- aggregate(
    datafinal_val_sec[, sec_cols],
    by = list(time = datafinal_val_sec$time),
    FUN = sum, na.rm = TRUE
)
amazonia_legal$group <- "Amazônia Legal"
amazonia_legal <- amazonia_legal[, c("time", "group", sec_cols)]
datafinal_val_sec <- rbind(amazonia_legal, datafinal_val_sec)

munic_cols <- setdiff(names(datafinal_val_munic), c("time", "group"))
datafinal_val_munic$`Amazônia Legal` <- rowSums(datafinal_val_munic[, munic_cols], na.rm = TRUE)

saveRDS(datafinal_val_munic, "data/comex_exp_munic_sec.rds")
saveRDS(datafinal_val_sec, "data/comex_exp_sec_munic.rds")


# ----------------------------------------------------------------
# [5] País × SEC
# Saída: comex_exp_tot_pais.rds   (long: time, group=país, value)
#        comex_exp_sec_pais.rds   (wide: time, group=seção SEC, cols=países)
#        comex_exp_pais_sec.rds   (transposta: time, group=país, cols=seções SEC)
# ----------------------------------------------------------------

dat <- matriz
dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$uf <- NULL
dat$cod_municipio <- NULL

data_val_pais <- aggregate(valor_fob ~ ano + cod_pais, dat, sum)
data_val_pais_sec <- aggregate(valor_fob ~ ano + cod_pais + cod_sh4, dat, sum)

aux2$CO_SH4 <- sprintf("%04d", as.numeric(aux2$CO_SH4))

data_val_pais$cod_pais <- sprintf("%03d", as.numeric(data_val_pais$cod_pais))
aux1$SISCOMEX <- sprintf("%03d", as.numeric(aux1$SISCOMEX))


data_val_pais_sec$cod_sh4 <- sprintf("%04d", as.numeric(data_val_pais_sec$cod_sh4))
data_val_pais_sec$cod_sh4 <- str_replace_all(data_val_pais_sec$cod_sh4, setNames(aux2$NO_SEC_PT, aux2$CO_SH4))
data_val_pais_sec$cod_pais <- sprintf("%03d", as.numeric(data_val_pais_sec$cod_pais))
data_val_pais_sec$cod_pais <- str_replace_all(data_val_pais_sec$cod_pais, setNames(aux1$NO_PT, aux1$SISCOMEX))

data_val_pais <- data_val_pais[!(data_val_pais$cod_pais %in% c("042", "105", "388", "790", "990", "998", "994", "995", "100")),]
data_val_pais_sec <- data_val_pais_sec[!(data_val_pais_sec$cod_pais %in% c("015", "042", "150", "388", "489", "693", "790", "990")),]

data_val_pais$cod_pais <- str_replace_all(data_val_pais$cod_pais, setNames(aux1$NO_PT, aux1$SISCOMEX))

colnames(data_val_pais) <- c("time", "group", "value")
colnames(data_val_pais_sec) <- c("time", "group", "type", "value")

data_val_pais_sec <- aggregate(value ~ time + group + type, data_val_pais_sec, sum)

data_val_pais <- data_val_pais[order(data_val_pais$group, data_val_pais$time),]
saveRDS(data_val_pais, "data/comex_exp_tot_pais.rds")

datafinal_val_pais_sec <- reshape(data_val_pais_sec, idvar = c("time", "type"), timevar = "group", direction = "wide")
datafinal_val_pais_munic <- reshape(data_val_pais_sec, idvar = c("time", "group"), timevar = "type", direction = "wide")

labl <- colnames(datafinal_val_pais_sec)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
colnames(datafinal_val_pais_sec) <- c("time", "group", labl)

labl <- colnames(datafinal_val_pais_munic)
labl <- labl[-c(1,2)]
labl <- sub("^value\\.", "", labl)   # remove prefixo do reshape sem truncar
colnames(datafinal_val_pais_munic) <- c("time", "group", labl)

# Ordena por (group, time)
datafinal_val_pais_sec <- datafinal_val_pais_sec[order(datafinal_val_pais_sec$group, datafinal_val_pais_sec$time), ]
datafinal_val_pais_munic <- datafinal_val_pais_munic[order(datafinal_val_pais_munic$group, datafinal_val_pais_munic$time), ]

saveRDS(datafinal_val_pais_sec, "data/comex_exp_sec_pais.rds")
saveRDS(datafinal_val_pais_munic, "data/comex_exp_pais_sec.rds")


# ================================================================
# DICIONÁRIOS
#
# Convenção `var`: sempre em PT, igual aos nomes de coluna do .rds.
# Só `label`/`desc` são traduzidos nos dicts EN.
# ================================================================


# ----------------------------------------------------------------
# [1] Total Amazônia por País
# ----------------------------------------------------------------

### PT: comex_exp_tot_pais_dic.csv
datafinal <- readRDS(file = "data/comex_exp_tot_pais.rds")
columns <- colnames(datafinal)

temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economia",
    subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "País"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "País"
temp_param_table$desc[1] <- "Ano"
temp_param_table$label[3] <- "Valor"
temp_param_table$desc[3] <- "Valor"

temp_param_table$x <- c(rep(FALSE, 2), TRUE)
temp_param_table$y <- c(rep(FALSE, 2), TRUE)
temp_param_table$color <- c(FALSE, rep(TRUE, 1), FALSE)
temp_param_table$size <- c(rep(FALSE, 2), TRUE)
temp_param_table$slider <- c(rep(FALSE, 2), TRUE)

write.csv(temp_param_table, file = "data/comex_exp_tot_pais_dic.csv", fileEncoding = "UTF-8")


### EN: comex_exp_tot_pais_dic_en.csv  (usado pelo app tot_pais)
temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economy",
    subcategoria = "Trade"
)

temp_param_table$label[2] <- "Country"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[2] <- "Country"
temp_param_table$desc[1] <- "Year"
temp_param_table$label[3] <- "Value"
temp_param_table$desc[3] <- "Value"

temp_param_table$x <- c(rep(FALSE, 2), TRUE)
temp_param_table$y <- c(rep(FALSE, 2), TRUE)
temp_param_table$color <- c(FALSE, rep(TRUE, 1), FALSE)
temp_param_table$size <- c(rep(FALSE, 2), TRUE)
temp_param_table$slider <- c(rep(FALSE, 2), TRUE)

write.csv(temp_param_table, file = "data/comex_exp_tot_pais_dic_en.csv", fileEncoding = "UTF-8")


# ----------------------------------------------------------------
# [2] País × SEC
# Transpostas: sec_pais (eixo y = seção, linhas = países)
#              pais_sec (eixo y = país,  linhas = seções)
# ----------------------------------------------------------------

### PT: comex_exp_sec_pais_dic.csv
datafinal <- readRDS(file = "data/comex_exp_sec_pais.rds")
columns <- colnames(datafinal)

temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economia",
    subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "País"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "País"
temp_param_table$desc[1] <- "Ano"
n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_sec_pais_dic.csv", fileEncoding = "UTF-8")


### EN: comex_exp_sec_pais_en_dic.csv
datafinal <- readRDS(file = "data/comex_exp_sec_pais.rds")
columns <- colnames(datafinal)

temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economy",
    subcategoria = "Trade"
)
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Section"
temp_param_table$label[-(1:2)] <- tr(temp_param_table$var[-(1:2)], map_pais)
temp_param_table$desc <- temp_param_table$label

n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_sec_pais_en_dic.csv", fileEncoding = "UTF-8")


### EN: comex_exp_pais_sec_dic_en.csv  (transposta: var=país PT, label=seção EN)
datafinal <- readRDS(file = "data/comex_exp_pais_sec.rds")
columns <- colnames(datafinal)

temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economy",
    subcategoria = "Trade"
)
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Country"
temp_param_table$label[-(1:2)] <- tr(temp_param_table$var[-(1:2)], map_sec)
temp_param_table$desc <- temp_param_table$label

n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, rep(TRUE, 1), rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_pais_sec_dic_en.csv", fileEncoding = "UTF-8")


### EN: comex_exp_pais_sec_en_dic.csv  (nome alternativo, mantido por compatibilidade)
write.csv(temp_param_table, file = "data/comex_exp_pais_sec_en_dic.csv", fileEncoding = "UTF-8")


# ----------------------------------------------------------------
# [3] Município × SH4
# ----------------------------------------------------------------

### PT: comex_exp_munic_sh4_dic.csv  (eixo y = município, cols = posições SH4)
datafinal <- readRDS(file = "data/comex_exp_munic_sh4.rds")
columns <- colnames(datafinal)

temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economia",
    subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "Produção sh4"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Produção sh4"
temp_param_table$desc[1] <- "Ano"

n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_munic_sh4_dic.csv", fileEncoding = "UTF-8")


### PT: comex_exp_sh4_munic_dic.csv  (transposta: eixo y = posição SH4, cols = municípios)
datafinal <- readRDS(file = "data/comex_exp_sh4_munic.rds")
columns <- colnames(datafinal)

temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economia",
    subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "Município"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Município"
temp_param_table$desc[1] <- "Ano"

n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_sh4_munic_dic.csv", fileEncoding = "UTF-8")


### EN: comex_exp_sh4_munic_dic_en.csv  (var = município PT, label = posição SH4 EN)
temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economy",
    subcategoria = "Trade"
)
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Municipality"
temp_param_table$label[-(1:2)] <- tr(temp_param_table$var[-(1:2)], map_sh4)
temp_param_table$desc <- temp_param_table$label

n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_sh4_munic_dic_en.csv", fileEncoding = "UTF-8")


# ----------------------------------------------------------------
# [4] Município × SH2
# ----------------------------------------------------------------

### PT: comex_exp_munic_sh2_dic.csv  (eixo y = município, cols = capítulos SH2)
datafinal <- readRDS(file = "data/comex_exp_munic_sh2.rds")
columns <- colnames(datafinal)

temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economia",
    subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "Produção sh2"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Produção sh2"

temp_param_table$desc[1] <- "Ano"
n_vars <- length(columns) - 2

temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_munic_sh2_dic.csv", fileEncoding = "UTF-8")


### EN: comex_exp_munic_sh2_en_dic.csv
datafinal <- readRDS(file = "data/comex_exp_munic_sh2.rds")
columns <- colnames(datafinal)

temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economy",
    subcategoria = "Trade"
)

temp_param_table$label[2] <- "Sh2 production"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[2] <- "Sh2 production"
temp_param_table$desc[1] <- "Year"

n_vars <- length(columns) - 2

temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_munic_sh2_en_dic.csv", fileEncoding = "UTF-8")


### PT: comex_exp_sh2_munic_dic.csv  (transposta: eixo y = capítulo SH2, cols = municípios)
datafinal <- readRDS(file = "data/comex_exp_sh2_munic.rds")
columns <- colnames(datafinal)

temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economia",
    subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "Município"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Município"
temp_param_table$desc[1] <- "Ano"

n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_sh2_munic_dic.csv", fileEncoding = "UTF-8")


### EN: comex_exp_sh2_munic_en_dic.csv  (var = município PT, label = capítulo SH2 EN)
temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economy",
    subcategoria = "Trade"
)
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Municipality"
temp_param_table$label[-(1:2)] <- tr(temp_param_table$var[-(1:2)], map_sh2)
temp_param_table$desc <- temp_param_table$label

n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_sh2_munic_en_dic.csv", fileEncoding = "UTF-8")


# ----------------------------------------------------------------
# [5] Município × SEC
# ----------------------------------------------------------------

### PT: comex_exp_munic_sec_dic.csv
datafinal <- readRDS(file = "data/comex_exp_munic_sec.rds")
columns <- colnames(datafinal)

temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economia",
    subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "Produção sec"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Produção sec"
temp_param_table$desc[1] <- "Ano"

n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_munic_sec_dic.csv", fileEncoding = "UTF-8")


### EN: comex_exp_munic_sec_en_dic.csv
temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economy",
    subcategoria = "Trade"
)

temp_param_table$label[2] <- "Sec production"
temp_param_table$label[1] <- "Year"
temp_param_table$desc[2] <- "Sec production"
temp_param_table$desc[1] <- "Year"

n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_munic_sec_en_dic.csv", fileEncoding = "UTF-8")


### PT: comex_exp_sec_munic_dic.csv  (transposta: eixo y = seção SEC, cols = municípios)
datafinal <- readRDS(file = "data/comex_exp_sec_munic.rds")
columns <- colnames(datafinal)

temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economia",
    subcategoria = "Comércio exterior"
)

temp_param_table$label[2] <- "Município"
temp_param_table$label[1] <- "Ano"
temp_param_table$desc[2] <- "Município"
temp_param_table$desc[1] <- "Ano"

n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_sec_munic_dic.csv", fileEncoding = "UTF-8")


### EN: comex_exp_sec_munic_en_dic.csv  (var = seção SEC em PT, label = seção SEC em EN)
temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "US$",
    categoria= "Economy",
    subcategoria = "Trade"
)
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Municipality"
temp_param_table$label[-(1:2)] <- tr(temp_param_table$var[-(1:2)], map_sec)
temp_param_table$desc <- temp_param_table$label

n_vars <- length(columns) - 2
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, n_vars))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, n_vars))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, n_vars))

write.csv(temp_param_table, file = "data/comex_exp_sec_munic_en_dic.csv", fileEncoding = "UTF-8")


# ================================================================
# [6] MAPA: principal produto exportado por município
# Saída: comex_exp_munic_sh4_sel.rds (sf) + dicionários PT/EN
# Requer o pacote rmapshaper (install.packages("rmapshaper"))
# ================================================================

# Lista única de SH4 compatíveis com a floresta. Usada nesta seção (mapa) e na [7].
# Para mudar a classificação "floresta", edite só aqui e rode de novo.
sh4_floresta <- c(
    "0301", # Peixes vivos
    "0302", # Peixes frescos/refrigerados, exceto filés
    "0303", # Peixes congelados, exceto filés
    "0304", # Filés de peixe e outras carnes
    "0305", # Peixes secos, salgados, em salmoura ou defumados
    "0306", # Crustáceos vivos, frescos, congelados, etc.
    "0801", # Cocos, castanha do Brasil e castanha de caju
    "0811", # Frutas, não cozidas ou cozidas em água/vapor, congeladas
    "0904", # Pimenta (Piper) e pimentos secos/triturados (Capsicum/Pimenta)
    "1207", # Outras sementes e frutos oleaginosos
    "1301", # Goma-laca, gomas, resinas, gomas-resinas, oleorresinas
    "1511", # Óleo de palma e respectivas fracções
    "1515", # Outras gorduras e óleos vegetais não modificados
    "1801", # Cacau em bruto ou torrado
    "2008", # Frutas e outras partes comestíveis de plantas, preparadas/conservadas
    "2009"  # Sumos de frutas e hortícolas
)

sf::sf_use_s2(FALSE)

dat <- readRDS(file = "data/comex_munic_raw.rds")
aux <- readRDS("data/auxiliar_cod_sh4.rds")

shapefile <- readRDS("global/munic_shapefile.rds") %>%
    filter(legal_amazon == 1) %>%
    rename(cod_ibge = municipality_code) %>%
    sf::st_make_valid()

shapefile <- shapefile[!st_is_empty(shapefile), , drop = FALSE]

# todos os municípios
munis <- tibble(cod_ibge = shapefile$cod_ibge)

# correspondência nome_sh4 / cod_sh4
sh4 <- dat %>%
    select(lab = nome_sh4, cod_sh4) %>%
    unique()

agg_dat <- dat %>%
    filter(cod_sh4 %in% sh4_floresta) %>%
    group_by(ano, cod_municipio, nome_sh4) %>%
    summarise(value = sum(valor_fob)) %>%
    ungroup() %>% 
    rename(time = ano, cod_ibge = cod_municipio, group = nome_sh4) %>% 
    right_join(munis) %>% 
    complete(time, cod_ibge, group) %>% 
    replace_na(list(value = 0)) %>% 
    filter(!is.na(group), !is.na(time), !is.na(cod_ibge)) %>% 
    pivot_wider(names_from = group, values_from = value) %>% 
    rowwise() %>%
    mutate(maximo_produto = max(c_across(-c(time, cod_ibge)), na.rm = TRUE))

agg_dat$produto_principal <- as.character({
    mat <- agg_dat %>% ungroup() %>% select(-time, -cod_ibge, -maximo_produto)
    names(mat)[max.col(mat, ties.method = "first")]
})

agg_dat <- agg_dat %>%
    mutate(produto_principal = ifelse(maximo_produto == 0, NA_character_, produto_principal)) %>%
    mutate(lab = produto_principal,
           produto_principal = ifelse(nchar(produto_principal) >= 40,
                                      paste0(substr(produto_principal, 1, 40), "..."),
                                      produto_principal))


# aggregate with all products ---------------------------------------------
agg_dat_all <- dat %>% 
    group_by(ano, cod_municipio, nome_sh4) %>% 
    summarise(value = sum(valor_fob)) %>% 
    ungroup() %>% 
    rename(time = ano, cod_ibge = cod_municipio, group = nome_sh4) %>% 
    right_join(munis) %>% 
    complete(time, cod_ibge, group) %>% 
    replace_na(list(value = 0)) %>% 
    filter(!is.na(group), !is.na(time), !is.na(cod_ibge)) %>% 
    pivot_wider(names_from = group, values_from = value) %>% 
    rowwise() %>%
    mutate(maximo_produto_todos = max(c_across(-c(time, cod_ibge)), na.rm = TRUE))

agg_dat_all$produto_principal_todos <- as.character({
    mat <- agg_dat_all %>% ungroup() %>% select(-time, -cod_ibge, -maximo_produto_todos)
    names(mat)[max.col(mat, ties.method = "first")]
})

agg_dat_all <- agg_dat_all %>%
    mutate(produto_principal_todos = ifelse(maximo_produto_todos == 0, NA_character_, produto_principal_todos)) %>%
    mutate(lab_todos = produto_principal_todos,
           produto_principal_todos = ifelse(nchar(produto_principal_todos) >= 40,
                                            paste0(substr(produto_principal_todos, 1, 40), "..."),
                                            produto_principal_todos))


# join tables -------------------------------------------------------------
agg_dat_selcolumns <- agg_dat %>%
    ungroup() %>%
    select(time, cod_ibge, maximo_produto, produto_principal, lab) %>%
    mutate(floresta = TRUE, lab = as.character(lab))

agg_dat_all_selcolumns <- agg_dat_all %>%
    ungroup() %>%
    select(time, cod_ibge,
           maximo_produto = maximo_produto_todos,
           produto_principal = produto_principal_todos,
           lab = lab_todos) %>%
    mutate(floresta = FALSE, lab = as.character(lab))

df_final <- rbind(agg_dat_selcolumns, agg_dat_all_selcolumns) %>% 
    data.frame() %>% 
    tibble()


#add sh4 code -------------------------------------------------------------
df_final <- df_final %>%
    left_join(sh4)

# Substitui lab (nome_sh4 bruto sem acento) por NO_SH4_PT do NCM_SH.csv,
# com acento e grafia correta. Truncado a 60 chars para labels do mapa.
aux_sh4_names <- aux %>% distinct(CO_SH4, NO_SH4_PT)
df_final <- df_final %>%
    left_join(aux_sh4_names, by = c("cod_sh4" = "CO_SH4")) %>%
    mutate(lab = ifelse(!is.na(NO_SH4_PT),
                        ifelse(nchar(NO_SH4_PT) > 60,
                               paste0(substr(NO_SH4_PT, 1, 59), "…"),
                               NO_SH4_PT),
                        lab)) %>%
    select(-NO_SH4_PT)


# value as relative -------------------------------------------------------
# chaveado por cod_sh4 (estavel): lab passou a ser o nome oficial do NCM_SH.csv,
# entao filtrar total_value_amz por nome nao casaria mais.
total_value_amz <- dat %>%
    group_by(ano, cod_sh4) %>%
    summarise(value = sum(valor_fob))

change_to_relative_value <- function(valor, ano_produto, produto_cod) {
    
    valor_total <- total_value_amz %>%
        filter(cod_sh4 == produto_cod, ano == ano_produto) %>%
        pull(value)
    
    return((valor/valor_total) * 100)
    
}

df_final <- df_final %>%
    rowwise() %>%
    mutate(maximo_produto = ifelse(maximo_produto != 0,
                                   change_to_relative_value(maximo_produto, time, cod_sh4),
                                   0))

###sh2 code and sh2 name columns
df_final$cod_sh2 <- as.numeric(substr(df_final$cod_sh4, 1, 2))

# Mapa SH2 code -> nome PT, derivado do auxiliar (CO_SH4 + NO_SH2_PT)
map_sh2_nome <- aux %>%
    mutate(CO_SH2 = as.numeric(substr(CO_SH4, 1, 2))) %>%
    distinct(CO_SH2, NO_SH2_PT)
df_final$nome_sh2 <- map_sh2_nome$NO_SH2_PT[match(df_final$cod_sh2, map_sh2_nome$CO_SH2)]
# Trunca nome_sh2 longo para labels do mapa (NCM_SH.csv tem nomes completos)
df_final$nome_sh2 <- ifelse(
    nchar(df_final$nome_sh2) > 50,
    paste0(substr(df_final$nome_sh2, 1, 49), "…"),
    df_final$nome_sh2
)



# add municipio name and uf -----------------------------------------------
# fonte: datazoom.amazonia::municipalities (nome em caixa alta p/ compat. app)
munic_lookup <- datazoom.amazonia::municipalities %>%
    tibble::as_tibble() %>%
    dplyr::distinct(cod_ibge = code_muni,
                    nm_municip = name_muni,
                    uf = abbrev_state) %>%
    dplyr::mutate(nm_municip = toupper(nm_municip))

df_final <- df_final %>%
    left_join(munic_lookup, by = "cod_ibge")

# merge with shape --------------------------------------------------------
# left_join nativo do sf (one-to-many): geometria replicada por (time, floresta).
# sp::merge sobre sf com geometria chamada "geom" corrompia colunas logicas.
shapefile <- shapefile %>%
    rename(geometry = geom) %>%
    select(cod_ibge)                       # descarta legal_amazon

data <- shapefile %>%
    left_join(df_final, by = "cod_ibge")


# export ------------------------------------------------------------------
# usa o nome bom (lab = NO_SH4_PT do NCM_SH.csv) como produto exibido
data$produto_principal <- data$lab

# ms_simplify serializa via GeoJSON e perde colunas logicas (viram NA);
# converte floresta p/ character antes e restaura logical depois.
data$floresta <- as.character(data$floresta)

# save simplified sf for faster maps
data <- rmapshaper::ms_simplify(data,
                                keep_shapes = TRUE,
                                keep = 0.01)

data$floresta <- as.logical(data$floresta)

# ordem canonica das colunas (o dicionario usa vetores posicionais)
data <- data %>%
    select(cod_ibge, nm_municip, uf, time, maximo_produto, produto_principal,
           lab, floresta, cod_sh4, cod_sh2, nome_sh2, geometry)

saveRDS(data, "data/comex_exp_munic_sh4_sel.rds")


# dictionary --------------------------------------------------------------
# extract variables from data
df_final <- readRDS(file = "data/comex_exp_munic_sh4_sel.rds")
columns <- colnames(df_final)

# generate dictionary
temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    geometry = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "-",
    categoria= "Economia", 
    subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label <- temp_param_table$var

temp_param_table$label[temp_param_table$var == 'cod_ibge'] <- "C\u00f3digo IBGE"
temp_param_table$label[temp_param_table$var == 'time'] <- "Ano"
temp_param_table$label[temp_param_table$var == 'uf'] <- "Estado"
temp_param_table$label[temp_param_table$var == 'nm_municip'] <- "Munic\u00edpio"
temp_param_table$label[temp_param_table$var == 'maximo_produto'] <- "Valor relativo do principal produto exportado"
temp_param_table$label[temp_param_table$var == 'produto_principal'] <- "Principal produto exportado (sh2)"
temp_param_table$label[temp_param_table$var == 'floresta'] <- "Produtos Compat\u00edveis com a Floresta"
temp_param_table$label[temp_param_table$var == 'cod_sh4'] <- "C\u00f3digo no sistema unificado 4"
temp_param_table$label[temp_param_table$var == 'cod_sh2'] <- "C\u00f3digo no sistema unificado 2"
temp_param_table$label[temp_param_table$var == 'nome_sh2'] <- "Nome no sistema unificado 2"

temp_param_table$unidade[temp_param_table$var == 'maximo_produto'] <- "% das exporta\u00e7\u00f5es mundiais"

temp_param_table$x <- c(FALSE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
temp_param_table$y <- c(FALSE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
temp_param_table$color <- c(FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
temp_param_table$size <- c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
temp_param_table$slider <- c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_munic_sh4_sel_dic.csv", fileEncoding = "UTF-8")

# relabel in english ----------------------------------------------------------------
# atribuicao por nome da var (nao posicional) p/ evitar desalinhamento
temp_param_table$label[temp_param_table$var == 'cod_ibge'] <- "IBGE Code"
temp_param_table$label[temp_param_table$var == 'time'] <- "Year"
temp_param_table$label[temp_param_table$var == 'uf'] <- "State"
temp_param_table$label[temp_param_table$var == 'nm_municip'] <- "Municipality"
temp_param_table$label[temp_param_table$var == 'maximo_produto'] <- "Main exported product relative value"
temp_param_table$label[temp_param_table$var == 'produto_principal'] <- "Main exported product (sh2)"
temp_param_table$label[temp_param_table$var == 'floresta'] <- "Forest Compatible Products"
temp_param_table$label[temp_param_table$var == 'cod_sh4'] <- "Harmonized System code 4"
temp_param_table$label[temp_param_table$var == 'cod_sh2'] <- "Harmonized System code 2"
temp_param_table$label[temp_param_table$var == 'nome_sh2'] <- "Harmonized System name 2"

temp_param_table$unidade <- "-"
temp_param_table$unidade[temp_param_table$var == 'maximo_produto'] <- "% of world exports"
temp_param_table$categoria <- "Economy"
temp_param_table$subcategoria <- "Foreign Trade"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_munic_sh4_sel_dic_en.csv", fileEncoding = "UTF-8")





# ================================================================
# [7] PARTICIPAÇÃO NAS EXPORTAÇÕES MUNDIAIS (SH4 selecionados)
# Saída: comex_exp_perc_sh4_sel.rds + dicionários PT/EN
# Denominador: BACI (data-raw/baci.R), que hoje vai só até 2024.
# Por isso esta série para em 2024, mesmo com COMEX mais recente.
# ================================================================

dat <- readRDS(file = "data/comex_munic_raw.rds")
aux <- readRDS("data/auxiliar_cod_sh4.rds")

dat$mes <- NULL
dat$nome_sh4 <- NULL
dat$kg_liquido <- NULL
dat$cod_municipio <- NULL
dat$cod_pais <- NULL

data_val_pais <- aggregate(valor_fob ~ ano + uf + cod_sh4, dat, sum)
data_val_pais$cod_sh4 <- sprintf("%04d", as.numeric(data_val_pais$cod_sh4))

world_trade <- readRDS("data/auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci.rds")

# junta por ano + sh4, garantindo alinhamento correto
data <- data_val_pais %>%
    dplyr::filter(
        cod_sh4 <= "2100",        
        valor_fob >= 1000000      
    ) %>%
    dplyr::mutate(
        valor_fob = valor_fob / 1000  # COMEX em mil USD para casar com BACI
    ) %>%
    dplyr::left_join(world_trade, by = c("ano", "cod_sh4")) %>%
    dplyr::mutate(
        valor_fob = valor_fob / valor_total,   # share
        floresta  = cod_sh4 %in% sh4_floresta
    ) %>%
    dplyr::filter(!is.na(valor_total), valor_total > 0) %>%
    dplyr::left_join(aux, by = c("cod_sh4" = "CO_SH4")) %>%
    dplyr::rename(group = NO_SH4_PT, group_en = NO_SH4_EN) %>%
    dplyr::select(
        time    = ano,
        group,
        group_en,
        value   = valor_fob,
        uf,
        floresta
    )


saveRDS(data, "data/comex_exp_perc_sh4_sel.rds")

# dictionary --------------------------------------------------------------
### exportação total da amazônia por tipo sh4
datafinal <- readRDS(file = "data/comex_exp_perc_sh4_sel.rds")

# extract variables from data
columns <- colnames(datafinal)

# generate dictionary
temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Comex",
    tipo = 1,
    unidade = "% das exporta\u00e7\u00f5es mundiais",
    categoria= "Economia", 
    subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label[temp_param_table$var == "group"] <- "Produto (SH4)"
temp_param_table$label[temp_param_table$var == "time"] <- "Ano"
temp_param_table$label[temp_param_table$var == "value"] <- "Valor"
temp_param_table$label[temp_param_table$var == "floresta"] <- "Floresta"

temp_param_table$desc[temp_param_table$var == "group"] <- "Produto (SH4)"
temp_param_table$desc[temp_param_table$var == "time"] <- "Ano"
temp_param_table$desc[temp_param_table$var == "value"] <- "Valor"
temp_param_table$desc[temp_param_table$var == "floresta"] <- "Produtos Compat\u00edveis com a Floresta"

temp_param_table$x[temp_param_table$var == "group"] <- FALSE
temp_param_table$x[temp_param_table$var == "time"] <- FALSE
temp_param_table$x[temp_param_table$var == "value"] <- TRUE
temp_param_table$x[temp_param_table$var == "floresta"] <- FALSE

temp_param_table$y[temp_param_table$var == "group"] <- FALSE
temp_param_table$y[temp_param_table$var == "time"] <- FALSE
temp_param_table$y[temp_param_table$var == "value"] <- TRUE
temp_param_table$y[temp_param_table$var == "floresta"] <- FALSE

temp_param_table$color[temp_param_table$var == "group"] <- TRUE
temp_param_table$color[temp_param_table$var == "time"] <- FALSE
temp_param_table$color[temp_param_table$var == "value"] <- FALSE
temp_param_table$color[temp_param_table$var == "floresta"] <- FALSE

temp_param_table$size[temp_param_table$var == "group"] <- FALSE
temp_param_table$size[temp_param_table$var == "time"] <- FALSE
temp_param_table$size[temp_param_table$var == "value"] <- TRUE
temp_param_table$size[temp_param_table$var == "floresta"] <- FALSE

temp_param_table$slider[temp_param_table$var == "group"] <- FALSE
temp_param_table$slider[temp_param_table$var == "time"] <- TRUE
temp_param_table$slider[temp_param_table$var == "value"] <- FALSE
temp_param_table$slider[temp_param_table$var == "floresta"] <- FALSE

# group_en: coluna auxiliar de tradução — não exposta na UI
temp_param_table$x[temp_param_table$var == "group_en"]      <- FALSE
temp_param_table$y[temp_param_table$var == "group_en"]      <- FALSE
temp_param_table$color[temp_param_table$var == "group_en"]  <- FALSE
temp_param_table$size[temp_param_table$var == "group_en"]   <- FALSE
temp_param_table$slider[temp_param_table$var == "group_en"] <- FALSE
temp_param_table$label[temp_param_table$var == "group_en"]  <- "Produto EN (SH4)"
temp_param_table$desc[temp_param_table$var == "group_en"]   <- "Produto EN (SH4)"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_perc_sh4_sel_dic.csv", fileEncoding = "UTF-8")

# relabel in english ----------------------------------------------------------------
temp_param_table$unidade <- "% of world exports"
temp_param_table$categoria <- "Economy"
temp_param_table$subcategoria <- "Foreign trade"

temp_param_table$label[temp_param_table$var == "group"] <- "Product (SH4)"
temp_param_table$label[temp_param_table$var == "time"] <- "Year"
temp_param_table$label[temp_param_table$var == "value"] <- "Value"
temp_param_table$label[temp_param_table$var == "floresta"] <- "Forest"

temp_param_table$desc[temp_param_table$var == "group"] <- "Product (SH4)"
temp_param_table$desc[temp_param_table$var == "time"] <- "Year"
temp_param_table$desc[temp_param_table$var == "value"] <- "Value"
temp_param_table$desc[temp_param_table$var == "floresta"] <- "Forest Compatible Products"

temp_param_table$label[temp_param_table$var == "group_en"]  <- "Product (SH4)"
temp_param_table$desc[temp_param_table$var == "group_en"]   <- "Product (SH4)"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_perc_sh4_sel_dic_en.csv", fileEncoding = "UTF-8")