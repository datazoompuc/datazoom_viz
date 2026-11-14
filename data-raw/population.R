############################################################
#### POPULAÇÃO: estados e municípios do Brasil (IBGE / SIDRA)
#### Gera, em ./data/, a base population.rds: a população residente de cada
#### estado e de cada município, em todos os anos que o IBGE publica.
####
#### Fonte: IBGE, via datazoom.amazonia::load_population(). A série junta quatro
#### tabelas do SIDRA, e o próprio pacote escolhe a tabela de cada ano:
####   6579  Estimativas de População (todos os anos, menos os três abaixo)
####   793   Contagem da População 2007
####   1378  Censo Demográfico 2010
####   4714  Censo Demográfico 2022
#### 2023 não existe em nenhuma tabela: o IBGE não publicou estimativa entre o
#### Censo 2022 e a estimativa de 2024.
####
#### Checagem de atualização (feita antes do download municipal, que é o lento):
####   1. pergunta ao SIDRA qual é o último ano publicado na tabela 6579;
####   2. baixa o nível estadual de todos os anos (rápido: uma consulta por ano);
####   3. compara com o nível estadual da base salva. Se for idêntico, não há ano
####      novo nem revisão, e o script para aí, sem tocar em data/population.rds.
####   Qualquer diferença (ano novo, valor revisado, coluna nova) refaz a base
####   inteira. Para refazer mesmo sem diferença, use forcar_atualizacao <- TRUE.
####
#### Para atualizar: rodar o script inteiro a partir da raiz do repositório.
####   setwd("~/datazoom_viz"); source("data-raw/population.R")
####
#### Requer o datazoom.amazonia com o PR update-population (tabela do Censo 2022 e
#### consultas que não passam pela página do SIDRA bloqueada pelo Cloudflare).
#### Enquanto o PR não for mergeado, antes de rodar:
####   devtools::load_all("~/datazoom.amazonia")   # na branch update-population
####
#### Seções:
####   1. Checagem: o IBGE publicou algo novo?
####   2. Download municipal (só se houver novidade)
####   3. Checagens e gravação
############################################################

library(datazoom.amazonia)
library(dplyr)

# Parâmetros
ano_inicial        <- 2001     # primeiro ano da tabela 6579
anos_sem_dado      <- 2023     # anos que nenhuma tabela do IBGE cobre
forcar_atualizacao <- FALSE    # TRUE refaz a base mesmo sem dado novo
arquivo_saida      <- "data/population.rds"

# Os caminhos são relativos à raiz do repositório (datazoom_viz).
if (!dir.exists("data")) {
  stop("Pasta 'data/' não encontrada em ", getwd(),
       ". Rode setwd() para a raiz do repositório e tente de novo.")
}

# Sem o PR update-population, load_population() não conhece a tabela do Censo
# 2022 (o ano 2022 falha) e ainda passa pela página bloqueada do SIDRA. A checagem
# usa um objeto interno que o PR criou; pode sair depois que todos atualizarem.
if (!exists("population_special_tables",
            envir = asNamespace("datazoom.amazonia"), inherits = FALSE)) {
  stop("O datazoom.amazonia instalado não tem o PR update-population: ",
       "load_population() não sabe baixar 2022 (Censo). Instale a versão ",
       "atualizada ou rode antes devtools::load_all() na branch update-population.",
       call. = FALSE)
}


# ================================================================
# FUNÇÕES AUXILIARES
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

# c(2001:2006, 2008) -> "2001-2006, 2008" (só para as mensagens).
faixa_de_anos <- function(anos) {
  anos <- sort(unique(as.integer(anos)))
  if (length(anos) == 0) return("nenhum")
  grupo <- cumsum(c(1, diff(anos) != 1))
  partes <- tapply(anos, grupo, function(g) {
    if (length(g) == 1) as.character(g) else paste0(g[1], "-", g[length(g)])
  })
  paste(partes, collapse = ", ")
}

# Último ano com valor publicado numa tabela do SIDRA, perguntado direto à API de
# dados (uma consulta, nível Brasil). Não usa o available_time do manifest do
# pacote de propósito: ele é atualizado por uma rotina do pacote que hoje não
# consegue falar com a API de metadados do IBGE a partir do GitHub Actions, e
# pode ficar para trás. Um ano novo publicado pelo IBGE aparece aqui no mesmo dia.
ultimo_ano_publicado <- function(tabela, variavel) {
  resposta <- com_tentativas(function() {
    suppressMessages(sidrar::get_sidra(
      api = paste0("/t/", tabela, "/n1/all/v/", variavel, "/p/all/f/a/h/y/d/s")
    ))
  }, rotulo = paste("SIDRA, tabela", tabela))

  resposta <- janitor::clean_names(resposta)
  if (!all(c("ano_codigo", "valor") %in% names(resposta))) {
    stop("A resposta do SIDRA para a tabela ", tabela, " não tem as colunas ",
         "esperadas (veio: ", paste(names(resposta), collapse = ", "), ").",
         call. = FALSE)
  }

  # "..." (não disponível) e "-" viram NA em valor: só conta ano com número.
  anos <- suppressWarnings(as.integer(resposta$ano_codigo[!is.na(resposta$valor)]))
  anos <- anos[!is.na(anos)]
  if (length(anos) == 0) {
    stop("A tabela ", tabela, " não tem nenhum ano com valor no SIDRA.", call. = FALSE)
  }
  max(anos)
}

# A coluna de uma variável do SIDRA na saída do load_population(), achada pelo
# código da variável no fim do nome ("..._v9324"). O "_v" antes do número evita
# confundir 93 com 9324 ou com qualquer outro código que termine em 93.
coluna_da_variavel <- function(d, codigo) {
  nome <- grep(paste0("_v", codigo, "$"), names(d), value = TRUE)
  if (length(nome) > 1) {
    stop("Mais de uma coluna para a variável ", codigo, ": ",
         paste(nome, collapse = ", "), call. = FALSE)
  }
  if (length(nome) == 0) return(rep(NA_real_, nrow(d)))
  as.numeric(d[[nome]])
}

# Saída do load_population() -> cod_ibge, ano, populacao, fonte.
# O pacote devolve a população em duas colunas, conforme a tabela de origem:
#   *_v93   população residente (Contagem 2007, Censos 2010 e 2022)
#   *_v9324 população residente estimada (todos os outros anos)
# Elas nunca se sobrepõem (cada ano vem de uma tabela só) e viram uma coluna.
padronizar <- function(d) {
  censo      <- coluna_da_variavel(d, "93")
  estimativa <- coluna_da_variavel(d, "9324")

  if (any(!is.na(censo) & !is.na(estimativa))) {
    stop("Há linhas com população do censo e estimada ao mesmo tempo: ",
         "o pacote mudou a forma de juntar as tabelas.", call. = FALSE)
  }

  ignoradas <- setdiff(names(d), c("ano", "geo_id",
                                   grep("_v(93|9324)$", names(d), value = TRUE)))
  if (length(ignoradas) > 0) {
    message("Colunas ignoradas (variável nova no IBGE?): ",
            paste(ignoradas, collapse = ", "))
  }

  ano <- as.integer(d$ano)
  tibble::tibble(
    cod_ibge  = as.character(d$geo_id),
    ano       = ano,
    populacao = dplyr::coalesce(censo, estimativa),
    fonte     = dplyr::case_when(
      !is.na(estimativa) ~ "estimativa",
      ano == 2007        ~ "contagem",   # Contagem da População 2007 (tabela 793)
      !is.na(censo)      ~ "censo"       # Censos 2010 (1378) e 2022 (4714)
    )
  ) %>%
    filter(!is.na(populacao))
}

# Para de propósito se a soma dos municípios de alguma UF não bater com o total
# da UF. É o que pega um download municipal incompleto: quando uma consulta por
# UF falha de vez, o pacote devolve o ano sem aqueles municípios, sem erro (a UF
# some inteira: diferença de 100%).
# A tolerância é de 1%, não de 0,1%: o próprio IBGE publica 2004, 2008 e 2012 (os
# anos em que o número de municípios aumenta) com a soma dos municípios até 0,32%
# acima do total da UF. Conferido direto na tabela 6579 do SIDRA; não é falha.
conferir_soma <- function(municipios, estados, variavel, tolerancia = 1e-2) {
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

# cod_ibge, ano, populacao, fonte -> a base final de um nível (estado ou município).
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
    select(nivel, cod_ibge, nome, uf, amazonia_legal, ano, populacao, fonte) %>%
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
    d <- suppressMessages(load_population(
      dataset = "population", raw_data = FALSE, geo_level = "state",
      time_period = ano, language = "pt"
    ))
    d <- padronizar(d)
    if (nrow(d) != 27) stop("vieram ", nrow(d), " estados em vez de 27")
    d
  }, rotulo = paste("Estados,", ano))
}

# Cada ano municipal concluído fica guardado numa pasta temporária: se o script
# parar no meio, rodar de novo na mesma sessão do R retoma de onde parou.
pasta_cache <- file.path(tempdir(), "population_municipios")
dir.create(pasta_cache, showWarnings = FALSE)

baixar_municipios <- function(ano, estados_do_ano) {
  arquivo_cache <- file.path(pasta_cache, paste0(ano, ".rds"))
  com_tentativas(function() {
    bruto <- if (file.exists(arquivo_cache)) {
      readRDS(arquivo_cache)
    } else {
      suppressMessages(load_population(
        dataset = "population", raw_data = FALSE, geo_level = "municipality",
        time_period = ano, language = "pt"
      ))
    }
    d <- padronizar(bruto)
    # Se a soma não bater, apaga o cache para a próxima tentativa baixar de novo.
    tryCatch(conferir_soma(d, estados_do_ano, "populacao"),
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

  if (any(is.na(base$populacao)) || any(base$populacao <= 0)) {
    stop("Há população vazia ou não positiva.", call. = FALSE)
  }
  if (any(is.na(base$uf)) || any(is.na(base$fonte))) {
    stop("Há linhas sem UF ou sem fonte.", call. = FALSE)
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

ultimo_ano <- ultimo_ano_publicado(tabela = 6579, variavel = 9324)

# A estimativa de um ano sai por volta de agosto do mesmo ano. Mais de dois anos
# sem estimativa nova é sinal de que o IBGE mudou de tabela.
ano_corrente <- as.integer(format(Sys.Date(), "%Y"))
if (ano_corrente - ultimo_ano > 2) {
  warning("A tabela 6579 não tem estimativa nova desde ", ultimo_ano,
          ". Conferir se o IBGE passou a publicar em outra tabela.", call. = FALSE)
}

anos <- setdiff(ano_inicial:ultimo_ano, anos_sem_dado)
message("População: anos ", faixa_de_anos(anos),
        " (último publicado na tabela 6579: ", ultimo_ano, ")")

message("Baixando o nível estadual para comparar com a base salva...")
estados <- bind_rows(lapply(anos, baixar_estados)) %>%
  montar_bloco("estado")

base_salva <- if (file.exists(arquivo_saida)) readRDS(arquivo_saida) else NULL
comparacao <- comparar_com_salva(estados, base_salva)
message("População - ", comparacao$resumo)

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
  # Uma consulta por UF e por ano (27 x número de anos): leva vários minutos.
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

  saveRDS(base, arquivo_saida)
  message("Base salva em ", arquivo_saida, ": ", nrow(base), " linhas, anos ",
          faixa_de_anos(base$ano), ".")
}
