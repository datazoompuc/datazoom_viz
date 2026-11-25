############################################################
#### PIB: estados e municípios do Brasil (IBGE / SIDRA, PIB dos Municípios)
#### Gera, em ./data/, a base pibmunic.rds: PIB, impostos e valor adicionado
#### bruto (VAB) de cada estado e de cada município, em todos os anos publicados.
####
#### Fonte: IBGE, PIB dos Municípios (tabela 5938 do SIDRA, referência 2010), via
#### datazoom.amazonia::load_pibmunic(). Valores NOMINAIS (preços correntes), em
#### R$ mil: o IBGE não publica PIB real por município. O nível estadual é o da
#### própria tabela 5938 (igual à soma dos municípios e ao PIB das Contas Regionais).
####
#### O que a tabela tem (nov/2026):
####   2002-2021  PIB, impostos líquidos, VAB total e por atividade
####   2022-2023  só o PIB (o IBGE suspendeu a abertura por atividade até a nova
####              série das Contas Nacionais, ano-base 2021); as colunas de VAB e
####              impostos ficam NA nesses anos.
#### O PIB de 2024 e 2025 foi adiado para 2027 (Nota técnica IBGE 01/2026), junto
#### com a série desde 2002 refeita na nova base. Pode sair na própria 5938 ou numa
#### tabela nova; a checagem abaixo avisa nos dois casos.
####
#### Checagem de atualização (feita antes do download municipal, que é o lento):
####   1. lê os anos disponíveis no available_time do manifest do pacote (use
####      ano_final_manual para forçar outro último ano);
####   2. baixa o nível estadual de todos os anos (rápido: uma consulta por ano);
####   3. compara com o nível estadual da base salva. Se for idêntico, não há ano
####      novo nem revisão, e o script para aí, sem tocar em data/pibmunic.rds.
####   Qualquer diferença (ano novo, valor revisado, coluna nova) refaz a base
####   inteira. Para refazer mesmo sem diferença, use forcar_atualizacao <- TRUE.
####
#### Para atualizar: rodar o script inteiro a partir da raiz do repositório.
####   setwd("~/datazoom_viz"); source("data-raw/pibmunic.R")
####
#### Requer o datazoom.amazonia de nov/2026 em diante (PR "Update pibmunic", #375:
#### consultas que não passam pela página do SIDRA bloqueada pelo Cloudflare).
####
#### Seções:
####   1. Checagem: o IBGE publicou algo novo?
####   2. Download municipal (só se houver novidade)
####   3. Checagens e gravação
############################################################

library(datazoom.amazonia)
library(dplyr)

# Parâmetros
ano_inicial        <- 2002     # primeiro ano da tabela 5938 (referência 2010)
ano_final_manual   <- NULL     # use só para forçar um ano final diferente do manifest
forcar_atualizacao <- FALSE    # TRUE refaz a base mesmo sem dado novo
arquivo_saida      <- "data/pibmunic.rds"

# Variáveis da tabela 5938 que entram na base (código do SIDRA). As outras 39
# variáveis da tabela são participações percentuais, que dá para recalcular.
variaveis_pib <- c(
  pib               = "37",    # Produto Interno Bruto a preços correntes
  impostos_liquidos = "543",   # impostos, líquidos de subsídios, sobre produtos
  vab_total         = "498",   # valor adicionado bruto total
  vab_agropecuaria  = "513",
  vab_industria     = "517",
  vab_servicos      = "6575",  # serviços, exceto administração pública
  vab_adm_publica   = "525"    # administração, defesa, educação e saúde públicas
)

# Os caminhos são relativos à raiz do repositório (datazoom_viz).
if (!dir.exists("data")) {
  stop("Pasta 'data/' não encontrada em ", getwd(),
       ". Rode setwd() para a raiz do repositório e tente de novo.")
}

# Versões do pacote anteriores ao PR #375 pedem a tabela com classific = "all",
# que passa pela página do SIDRA bloqueada pelo Cloudflare em algumas redes.
if (!exists("sidra_code_parts",
            envir = asNamespace("datazoom.amazonia"), inherits = FALSE)) {
  stop("O datazoom.amazonia instalado é anterior a nov/2026 (PR #375). ",
       "Atualize com remotes::install_github(\"datazoompuc/datazoom.amazonia\").",
       call. = FALSE)
}


# ================================================================
# FUNÇÕES AUXILIARES (mesmo esquema de data-raw/population.R)
# ================================================================

# Roda f() até dar certo, com uma pausa crescente entre as tentativas: o SIDRA
# às vezes recusa ou corta uma consulta, e uma falha isolada não deve parar tudo.
com_tentativas <- function(f, rotulo, tentativas = 3) {
  for (i in seq_len(tentativas)) {
    resultado <- tryCatch(f(), error = function(e) {
      message(rotulo, ": tentativa ", i, " de ", tentativas, " falhou: ",
              conditionMessage(e))
      NULL
    })
    if (!is.null(resultado)) return(resultado)
    if (i < tentativas) Sys.sleep(10 * i)
  }
  stop(rotulo, ": não deu certo depois de ", tentativas, " tentativas.",
       call. = FALSE)
}

# c(2002:2006, 2008) -> "2002-2006, 2008" (só para as mensagens).
faixa_de_anos <- function(anos) {
  anos <- sort(unique(as.integer(anos)))
  if (length(anos) == 0) return("nenhum")
  grupo <- cumsum(c(1, diff(anos) != 1))
  partes <- tapply(anos, grupo, function(g) {
    if (length(g) == 1) as.character(g) else paste0(g[1], "-", g[length(g)])
  })
  paste(partes, collapse = ", ")
}

# Anos disponíveis na fonte: vêm do manifest do pacote (available_time da linha
# do dataset), que o pacote mantém atualizado.
anos_do_manifest <- function(fonte, dataset) {
  anos <- datazoom.amazonia:::parse_years(
    datazoom.amazonia:::dataset_meta(fonte, dataset, "available_time")
  )
  if (length(anos) == 0) {
    stop("O manifest do pacote não traz o available_time de ", fonte, "/", dataset,
         ". Defina ano_final_manual no topo do script.", call. = FALSE)
  }
  sort(unique(as.integer(anos)))
}

# A coluna de uma variável do SIDRA na saída do load_pibmunic(), achada pelo
# código da variável no fim do nome ("..._v37"). O "_v" antes do número evita
# confundir 571 com 6571, ou 37 com qualquer código que termine em 37.
coluna_da_variavel <- function(d, codigo) {
  nome <- grep(paste0("_v", codigo, "$"), names(d), value = TRUE)
  if (length(nome) > 1) {
    stop("Mais de uma coluna para a variável ", codigo, ": ",
         paste(nome, collapse = ", "), call. = FALSE)
  }
  if (length(nome) == 0) return(rep(NA_real_, nrow(d)))
  as.numeric(d[[nome]])  # as.numeric() também tira o rótulo que o pacote põe
}

# Saída do load_pibmunic() -> cod_ibge, ano e uma coluna por variável de
# variaveis_pib. Sem o PIB (variável 37) a linha não serve e sai.
padronizar <- function(d) {
  if (!any(grepl("_v37$", names(d)))) {
    stop("A saída do load_pibmunic() não tem a coluna do PIB (variável 37).",
         call. = FALSE)
  }
  colunas <- lapply(variaveis_pib, function(codigo) coluna_da_variavel(d, codigo))
  tibble::tibble(
    cod_ibge = as.character(d$geo_id),
    ano      = as.integer(d$ano),
    !!!colunas
  ) %>%
    filter(!is.na(pib))
}

# Para de propósito se a soma dos municípios de alguma UF não bater com o total
# da UF. É o que pega um download municipal incompleto: quando uma consulta por
# UF falha de vez, o pacote devolve o ano sem aqueles municípios, sem erro.
conferir_soma <- function(municipios, estados, variavel, tolerancia = 1e-3) {
  soma <- municipios %>%
    mutate(cod_uf = substr(cod_ibge, 1, 2)) %>%
    group_by(cod_uf) %>%
    summarise(soma = sum(.data[[variavel]], na.rm = TRUE), .groups = "drop")

  comparacao <- estados %>%
    transmute(cod_uf = cod_ibge, total = .data[[variavel]]) %>%
    left_join(soma, by = "cod_uf") %>%
    mutate(soma = coalesce(soma, 0),
           diferenca = abs(soma - total) / total)

  ruins <- filter(comparacao, diferenca > tolerancia)
  if (nrow(ruins) > 0) {
    stop("a soma dos municípios não bate com o total de ", nrow(ruins),
         " UF(s): ", paste0(ruins$cod_uf, " (", round(100 * ruins$diferenca, 2),
                            "%)", collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

# Nomes e Amazônia Legal ------------------------------------------------------

ufs <- tibble::tribble(
  ~cod_ibge, ~uf,  ~nome,
  "11",      "RO", "Rondônia",
  "12",      "AC", "Acre",
  "13",      "AM", "Amazonas",
  "14",      "RR", "Roraima",
  "15",      "PA", "Pará",
  "16",      "AP", "Amapá",
  "17",      "TO", "Tocantins",
  "21",      "MA", "Maranhão",
  "22",      "PI", "Piauí",
  "23",      "CE", "Ceará",
  "24",      "RN", "Rio Grande do Norte",
  "25",      "PB", "Paraíba",
  "26",      "PE", "Pernambuco",
  "27",      "AL", "Alagoas",
  "28",      "SE", "Sergipe",
  "29",      "BA", "Bahia",
  "31",      "MG", "Minas Gerais",
  "32",      "ES", "Espírito Santo",
  "33",      "RJ", "Rio de Janeiro",
  "35",      "SP", "São Paulo",
  "41",      "PR", "Paraná",
  "42",      "SC", "Santa Catarina",
  "43",      "RS", "Rio Grande do Sul",
  "50",      "MS", "Mato Grosso do Sul",
  "51",      "MT", "Mato Grosso",
  "52",      "GO", "Goiás",
  "53",      "DF", "Distrito Federal"
)

# Os 9 estados da Amazônia Legal; o Maranhão só em parte (a oeste do 44º W).
ufs_amazonia_legal   <- c("AC", "AM", "AP", "MA", "MT", "PA", "RO", "RR", "TO")
ufs_amazonia_inteira <- setdiff(ufs_amazonia_legal, "MA")

# "fernando de noronha" -> "Fernando de Noronha": maiúscula em cada palavra,
# menos nas preposições.
nome_proprio <- function(x) {
  vapply(strsplit(x, " ", fixed = TRUE), function(p) {
    maiuscula <- !(p %in% c("de", "da", "do", "das", "dos", "e"))
    p[maiuscula] <- paste0(toupper(substr(p[maiuscula], 1, 1)), substring(p[maiuscula], 2))
    paste(p, collapse = " ")
  }, character(1))
}

# Nome no formato das outras bases do repositório ("Alta Floresta D'Oeste - RO",
# como o antigo gdp.rds), da tabela municipalities do pacote. Fernando de Noronha
# não tem municipality_mapbiomas; cai no name_muni (minúsculo, sem acento).
nomes_municipios <- datazoom.amazonia::municipalities %>%
  transmute(
    cod_ibge = as.character(code_muni),
    nome = paste0(coalesce(municipality_mapbiomas, nome_proprio(name_muni)),
                  " - ", abbrev_state),
    amazonia_legal_tabela = as.integer(legal_amazon)
  )

# cod_ibge, ano, variáveis -> a base final de um nível (estado ou município).
montar_bloco <- function(d, nivel) {
  if (nivel == "estado") {
    d <- d %>%
      left_join(ufs, by = "cod_ibge") %>%
      mutate(amazonia_legal = as.integer(uf %in% ufs_amazonia_legal))
  } else {
    # Município criado depois da tabela municipalities do pacote fica sem nome, mas
    # não é perdido; a UF sai do próprio código e a Amazônia Legal, da UF quando o
    # estado está inteiro nela.
    d <- d %>%
      left_join(nomes_municipios, by = "cod_ibge") %>%
      mutate(
        uf = ufs$uf[match(substr(cod_ibge, 1, 2), ufs$cod_ibge)],
        amazonia_legal = case_when(
          !is.na(amazonia_legal_tabela) ~ amazonia_legal_tabela,
          uf %in% ufs_amazonia_inteira  ~ 1L,
          uf %in% ufs_amazonia_legal    ~ NA_integer_,
          TRUE                          ~ 0L
        )
      )
  }

  d %>%
    mutate(nivel = nivel) %>%
    select(nivel, cod_ibge, nome, uf, amazonia_legal, ano, all_of(names(variaveis_pib))) %>%
    arrange(cod_ibge, ano)
}

# Compara um nível da base nova com o mesmo nível da base salva, linha a linha.
# Devolve list(iguais = TRUE/FALSE, resumo = texto para a mensagem).
comparar_com_salva <- function(novo, salvo) {
  if (is.null(salvo)) {
    return(list(iguais = FALSE, resumo = "não há base salva ainda"))
  }
  salvo <- filter(salvo, nivel %in% unique(novo$nivel))

  if (!setequal(names(novo), names(salvo))) {
    return(list(iguais = FALSE, resumo = paste0(
      "as colunas mudaram (salva: ", paste(names(salvo), collapse = ", "),
      " | nova: ", paste(names(novo), collapse = ", "), ")")))
  }

  chaves  <- c("nivel", "cod_ibge", "ano")
  valores <- setdiff(names(novo), chaves)
  juntas  <- full_join(novo, salvo[names(novo)], by = chaves,
                       suffix = c("_novo", "_salvo"))

  # Igual = os dois NA, ou os dois com o mesmo valor. Uma linha que só existe
  # de um lado tem NA do outro e conta como diferente.
  mesmo_valor <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
  diferente <- Reduce(`|`, lapply(valores, function(v) {
    !mesmo_valor(juntas[[paste0(v, "_novo")]], juntas[[paste0(v, "_salvo")]])
  }))

  anos_comuns <- intersect(novo$ano, salvo$ano)
  resumo <- paste0(
    "base salva: ", faixa_de_anos(salvo$ano),
    " | SIDRA: ", faixa_de_anos(novo$ano),
    " | anos novos: ", faixa_de_anos(setdiff(novo$ano, salvo$ano)),
    " | anos que sumiram: ", faixa_de_anos(setdiff(salvo$ano, novo$ano)),
    " | anos com valor revisado: ",
    faixa_de_anos(juntas$ano[diferente & juntas$ano %in% anos_comuns])
  )
  list(iguais = !any(diferente), resumo = resumo)
}

# Downloads -------------------------------------------------------------------

baixar_estados <- function(ano) {
  com_tentativas(function() {
    d <- suppressMessages(load_pibmunic(
      dataset = "pibmunic", raw_data = FALSE, geo_level = "state",
      time_period = ano, language = "pt"
    ))
    d <- padronizar(d)
    if (nrow(d) != 27) stop("vieram ", nrow(d), " estados em vez de 27")
    d
  }, rotulo = paste("Estados,", ano))
}

# Cada ano municipal concluído fica guardado numa pasta temporária: se o script
# parar no meio, rodar de novo na mesma sessão do R retoma de onde parou.
pasta_cache <- file.path(tempdir(), "pibmunic_municipios")
dir.create(pasta_cache, showWarnings = FALSE)

baixar_municipios <- function(ano, estados_do_ano) {
  arquivo_cache <- file.path(pasta_cache, paste0(ano, ".rds"))
  com_tentativas(function() {
    bruto <- if (file.exists(arquivo_cache)) {
      readRDS(arquivo_cache)
    } else {
      suppressMessages(load_pibmunic(
        dataset = "pibmunic", raw_data = FALSE, geo_level = "municipality",
        time_period = ano, language = "pt"
      ))
    }
    d <- padronizar(bruto)
    # Se a soma não bater, apaga o cache para a próxima tentativa baixar de novo.
    tryCatch(conferir_soma(d, estados_do_ano, "pib"),
             error = function(e) { unlink(arquivo_cache); stop(e) })
    saveRDS(bruto, arquivo_cache)
    d
  }, rotulo = paste("Municípios,", ano))
}

# Checagens da base final, antes de gravar.
checar_base <- function(base, anos) {
  if (anyDuplicated(base[c("nivel", "cod_ibge", "ano")])) {
    stop("Há chave duplicada (nivel, cod_ibge, ano).", call. = FALSE)
  }

  contagem <- count(base, nivel, ano)
  for (nv in c("estado", "municipio")) {
    faltam <- setdiff(anos, contagem$ano[contagem$nivel == nv])
    if (length(faltam) > 0) {
      stop("Faltam anos no nível ", nv, ": ", faixa_de_anos(faltam), call. = FALSE)
    }
  }
  if (any(contagem$n[contagem$nivel == "estado"] != 27)) {
    stop("Algum ano não tem as 27 UFs.", call. = FALSE)
  }
  poucos <- filter(contagem, nivel == "municipio", n < 5500)
  if (nrow(poucos) > 0) {
    stop("Anos com menos de 5.500 municípios: ", faixa_de_anos(poucos$ano),
         call. = FALSE)
  }

  # PIB negativo existe de verdade: Guamaré (RN) tem -19.046 (R$ mil) em 2012 na
  # própria tabela 5938 do IBGE. Por isso só PIB vazio ou zero para o script; o
  # negativo é avisado e fica na base.
  if (any(is.na(base$pib)) || any(base$pib == 0)) {
    stop("Há PIB vazio ou igual a zero.", call. = FALSE)
  }
  negativos <- filter(base, pib < 0)
  if (nrow(negativos) > 0) {
    message("PIB negativo (valor publicado pelo IBGE, mantido): ",
            paste0(negativos$nome, " ", negativos$ano, " = ", negativos$pib,
                   collapse = "; "), ".")
  }
  if (any(is.na(base$uf))) {
    stop("Há linhas sem UF.", call. = FALSE)
  }

  sem_nome <- unique(base$cod_ibge[is.na(base$nome)])
  if (length(sem_nome) > 0) {
    message("Municípios sem nome na tabela municipalities do pacote (criados ",
            "depois dela?): ", paste(sem_nome, collapse = ", "),
            ". Ficam na base com nome NA.")
  }

  invisible(TRUE)
}


# ================================================================
# 1. CHECAGEM: O IBGE PUBLICOU ALGO NOVO?
# ================================================================

anos_fonte <- anos_do_manifest("pibmunic", "pibmunic")
ultimo_ano <- if (is.null(ano_final_manual)) max(anos_fonte) else ano_final_manual

# O PIB de um ano costuma sair uns dois anos depois (2023 saiu em dez/2025).
# Mais de três anos de atraso quer dizer que a 5938 parou ou que o manifest do
# pacote ficou para trás: o IBGE prometeu para 2027 o PIB de 2024-2025 e a série
# refeita na nova base (ano-base 2021), que pode vir numa tabela nova do SIDRA.
# Nesse caso, apontar o pacote e o script para ela.
ano_corrente <- as.integer(format(Sys.Date(), "%Y"))
if (ano_corrente - ultimo_ano > 3) {
  warning("O manifest do pacote não tem PIB municipal novo desde ", ultimo_ano,
          ". Conferir se o IBGE publicou a nova série do PIB dos Municípios ",
          "(ano-base 2021) em outra tabela do SIDRA, ou se o available_time do ",
          "pacote está desatualizado.", call. = FALSE)
}

anos <- anos_fonte[anos_fonte >= ano_inicial & anos_fonte <= ultimo_ano]
message("PIB municipal: anos ", faixa_de_anos(anos),
        " (available_time do manifest: ", faixa_de_anos(anos_fonte), ")")

message("Baixando o nível estadual para comparar com a base salva...")
estados <- bind_rows(lapply(anos, baixar_estados)) %>%
  montar_bloco("estado")

base_salva <- if (file.exists(arquivo_saida)) readRDS(arquivo_saida) else NULL
comparacao <- comparar_com_salva(estados, base_salva)
message("PIB municipal - ", comparacao$resumo)

# Uma base nova com menos anos que a publicada quase sempre é falha (do SIDRA ou
# do download), não decisão: para aqui, antes do download municipal, a não ser
# com forcar_atualizacao.
sumiram <- if (is.null(base_salva)) integer(0) else setdiff(base_salva$ano, estados$ano)
if (length(sumiram) > 0 && !forcar_atualizacao) {
  stop("A nova base perderia anos que a salva tem (", faixa_de_anos(sumiram),
       "). Se for de propósito, rode com forcar_atualizacao <- TRUE.", call. = FALSE)
}

if (comparacao$iguais && !forcar_atualizacao) {
  message("Nenhum dado novo no SIDRA: ", arquivo_saida, " continua atualizado. ",
          "O nível municipal não foi baixado.")
} else {

  # ==============================================================
  # 2. DOWNLOAD MUNICIPAL
  # ==============================================================
  # Uma consulta por UF e por ano (27 x número de anos), com as 46 variáveis da
  # tabela em cada uma: leva bem mais tempo que a população.
  municipios <- bind_rows(lapply(anos, function(a) {
    message("Municípios, ", a, "...")
    baixar_municipios(a, filter(estados, ano == a))
  })) %>%
    montar_bloco("municipio")

  # ==============================================================
  # 3. CHECAGENS E GRAVAÇÃO
  # ==============================================================
  base <- bind_rows(estados, municipios)
  checar_base(base, anos)

  # Até que ano há abertura por atividade (VAB): só para registro no log.
  ultimo_vab <- suppressWarnings(max(base$ano[!is.na(base$vab_total)]))
  message("VAB e impostos até ", ultimo_vab, "; PIB até ", max(base$ano), ".")

  saveRDS(base, arquivo_saida)
  message("Base salva em ", arquivo_saida, ": ", nrow(base), " linhas, anos ",
          faixa_de_anos(base$ano), ".")
}
