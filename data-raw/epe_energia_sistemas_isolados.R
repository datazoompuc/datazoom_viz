#######################
## Sistemas Isolados

############
# libraries
library(readr)
library(tidyverse)
library(readxl)
library(deflateBR)
library(jsonlite)
############

# ============================================================
# EPE - Consumo Mensal de Energia Elétrica por Classe
# Fonte: Empresa de Pesquisa Energética
# https://www.epe.gov.br/pt/publicacoes-dados-abertos/publicacoes/consumo-de-energia-eletrica
# ============================================================

# download do arquivo XLSX da EPE -----------------------------------------
# O arquivo é atualizado mensalmente pela EPE com dados a partir de 2004.
# Anos com dados preliminares são marcados com "*" e excluídos automaticamente.

url_epe <- paste0(
  "https://www.epe.gov.br/sites-pt/publicacoes-dados-abertos/publicacoes/",
  "Documents/CONSUMO%20MENSAL%20DE%20ENERGIA%20EL%C3%89TRICA%20POR%20CLASSE.xlsx"
)
epe_file <- tempfile(fileext = ".xlsx")
download.file(url_epe, destfile = epe_file, mode = "wb", quiet = TRUE)

# Estrutura do XLSX:
#   Cada ano ocupa um bloco de ~16 linhas.
#   Dentro de cada bloco, "Sistemas isolados" está sempre 10 linhas abaixo
#   do cabeçalho do ano (que contém o ano em col 2, ex: "2025" ou "2026*").
#   Abas de consumo (14 colunas): col 2-13 = JAN-DEZ, col 14 = ANO (total anual).
#   Abas de consumidores (13 colunas): col 2-13 = JAN-DEZ (sem total anual;
#   usamos dezembro como referência de fim de ano).

# extrai total anual dos Sistemas Isolados (abas de consumo) ------------------
parse_consumo <- function(file, sheet) {
  df <- read_xlsx(file, sheet = sheet, col_names = FALSE)
  iso_rows <- which(df[[1]] == "Sistemas isolados")

  map_dfr(iso_rows, function(i) {
    year_raw <- as.character(df[[2]][i - 10])
    # ignora anos com dados preliminares (marcados com "*")
    if (is.na(year_raw) || grepl("\\*", year_raw)) return(NULL)
    tibble(
      Ano   = as.integer(year_raw),
      valor = as.numeric(df[[14]][i])   # col 14 = ANO (total anual em MWh)
    )
  })
}

# extrai valor de dezembro dos Sistemas Isolados (abas de consumidores) -------
# Número de consumidores é medida de estoque: usamos dezembro como referência anual.
parse_consumidores <- function(file, sheet) {
  df <- read_xlsx(file, sheet = sheet, col_names = FALSE)
  iso_rows <- which(df[[1]] == "Sistemas isolados")

  map_dfr(iso_rows, function(i) {
    year_raw <- as.character(df[[2]][i - 10])
    if (is.na(year_raw) || grepl("\\*", year_raw)) return(NULL)
    tibble(
      Ano   = as.integer(year_raw),
      valor = as.numeric(df[[13]][i])   # col 13 = DEZ
    )
  })
}

# dados de consumo (MWh → milhões de MWh) ------------------------------------
db_consumo <- bind_rows(
  parse_consumo(epe_file, "TOTAL")       %>% mutate(tipo = "CONSUMO TOTAL"),
  parse_consumo(epe_file, "RESIDENCIAL") %>% mutate(tipo = "CONSUMO RESIDENCIAL"),
  parse_consumo(epe_file, "INDUSTRIAL")  %>% mutate(tipo = "CONSUMO INDUSTRIAL"),
  parse_consumo(epe_file, "COMERCIAL")   %>% mutate(tipo = "CONSUMO COMERCIAL"),
  parse_consumo(epe_file, "OUTROS")      %>% mutate(tipo = "CONSUMO OUTROS")
) %>%
  mutate(valor = valor / 1e6)

# dados de consumidores (unidades → milhões de consumidores) ------------------
db_consumidores <- bind_rows(
  parse_consumidores(epe_file, "CONSUMIDORES TOTAIS")       %>% mutate(tipo = "CONSUMIDORES TOTAIS"),
  parse_consumidores(epe_file, "CONSUMIDORES RESIDENCIAIS") %>% mutate(tipo = "CONSUMIDORES RESIDENCIAIS")
) %>%
  mutate(valor = valor / 1e6)


# ============================================================
# ANEEL - Despesas na Conta de Desenvolvimento Energético (CDE)
# Fonte: Agência Nacional de Energia Elétrica
# https://portalrelatorios.aneel.gov.br/luznatarifa/contadesenvolvimento
#
# ATUALIZAÇÃO MANUAL — os dados da ANEEL não têm download direto.
# O portal usa um dashboard interativo (Power BI). Para exportar:
#
#   Arquivo 1 — despesas da CCC:
#     1. Acesse https://portalrelatorios.aneel.gov.br/luznatarifa/contadesenvolvimento
#     2. Em "Tipos de Despesas", selecione apenas "CCC"
#     3. Passe o mouse sobre a tabela "Despesas no Orçamento da CDE"
#     4. Clique em "..." (canto superior direito) > "Exportar dados" > "Dados resumidos"
#     5. Salve como: data/bases viz energia CPI/sistemas_isolados_despesas_estimadas_no_orcamento_da_cde.csv
#     Colunas esperadas: Ano, Valor
#
#   Arquivo 2 — participação da CCC no orçamento total:
#     (mesmo painel, coluna "Participação" já exportada junto)
#     Salve como: data/bases viz energia CPI/sistemas_isolados_despesas_estimadas_no_orcamento_da_cde_particip.csv
#     Colunas esperadas: Ano, Participação (formato "28,63%")
#
#   Arquivo 3 — orçamento total da CDE (todas as despesas):
#     1. No mesmo portal, remova o filtro de "Tipos de Despesas"
#     2. Exporte da mesma forma
#     3. Salve como: data/bases viz energia CPI/sistemas_isolados_despesas_estimadas_no_orçamento_da_cde_total.csv
#     Colunas esperadas: Ano, Valor
#
# Se algum arquivo não existir, o script roda normalmente sem as variáveis CDE.
# ============================================================

path_cde      <- "data/bases viz energia CPI/sistemas_isolados_despesas_estimadas_no_orcamento_da_cde.csv"
path_particip <- "data/bases viz energia CPI/sistemas_isolados_despesas_estimadas_no_orcamento_da_cde_particip.csv"
path_total    <- "data/bases viz energia CPI/sistemas_isolados_despesas_estimadas_no_orçamento_da_cde_total.csv"

db_orcamento_cde        <- NULL
db_orcamento_cde_particip <- NULL
db_orcamento_total      <- NULL

ano_atual <- as.integer(format(Sys.Date(), "%Y"))

if (file.exists(path_cde)) {
  db_orcamento_cde <- read_csv(path_cde, show_col_types = FALSE) %>%
    select(Ano, valor = Valor) %>%
    filter(Ano < ano_atual) %>%
    mutate(valor = valor / 1e9)   # R$ → bilhões de R$
}

if (file.exists(path_particip)) {
  db_orcamento_cde_particip <- read_csv(path_particip, show_col_types = FALSE) %>%
    select(Ano, participacao = `Participação_desp`) %>%
    filter(Ano < ano_atual) %>%
    mutate(participacao = participacao %>%
             str_remove_all("%") %>%
             str_replace_all(",", ".") %>%
             as.numeric())
}

if (file.exists(path_total)) {
  db_orcamento_total <- read_csv(path_total, show_col_types = FALSE) %>%
    select(Ano, valor = Valor) %>%
    filter(Ano < ano_atual) %>%
    mutate(valor = valor / 1e9) %>%  # R$ → bilhões de R$
    group_by(Ano) %>%
    summarise(`DESPESAS ESTIMADAS NO ORÇAMENTO DA CDE (Nominal)` = sum(valor))
}
  
# ============================================================
# Referência para deflação IPCA
# Consulta automaticamente o mês mais recente disponível via API do IBGE.
# ============================================================

get_ref_ipca <- function() {
  url <- paste0(
    "https://servicodados.ibge.gov.br/api/v3/agregados/1737/",
    "periodos/last%201/variaveis/2266?localidades=N1[all]"
  )
  resp <- tryCatch(fromJSON(url), error = function(e) NULL)
  if (!is.null(resp)) {
    periodo <- names(resp$resultados[[1]]$series[[1]]$serie)  # formato "YYYYMM"
    return(format(as.Date(paste0(periodo, "01"), "%Y%m%d"), "%m/%Y"))
  }
  # fallback: dois meses atrás (garante que o IPCA já foi divulgado)
  format(floor_date(Sys.Date() - months(2), "month"), "%m/%Y")
}

ref_ipca     <- get_ref_ipca()                     # ex: "04/2026"
ano_ref_ipca <- str_extract(ref_ipca, "\\d{4}")   # ex: "2026"

# tudo junto ---------------------------------------------------------------
# pivot da EPE para formato wide, depois une com dados da ANEEL disponíveis
db_sistemas_isolados <- bind_rows(db_consumo, db_consumidores) %>%
  pivot_wider(names_from = tipo, values_from = valor)

for (df_aneel in list(db_orcamento_cde, db_orcamento_cde_particip, db_orcamento_total)) {
  if (!is.null(df_aneel)) {
    db_sistemas_isolados <- full_join(db_sistemas_isolados, df_aneel, by = "Ano")
  }
}

# padroniza nomes de colunas -----------------------------------------------
colnames(db_sistemas_isolados) <- str_to_title(colnames(db_sistemas_isolados))

# corrige siglas distorcidas pelo str_to_title (ex: "Ccc" → "CCC")
# cada rename só roda se a coluna existir, pois os dados da ANEEL são opcionais
if ("Despesas Estimadas Ccc (Nominal)" %in% colnames(db_sistemas_isolados))
  db_sistemas_isolados <- db_sistemas_isolados %>%
    rename(`Despesas Estimadas CCC (Nominal)` = `Despesas Estimadas Ccc (Nominal)`)

if ("Participacao" %in% colnames(db_sistemas_isolados))
  db_sistemas_isolados <- db_sistemas_isolados %>%
    rename(`Participação da CCC no Orçamento Total da CDE` = Participacao)

if ("Despesas Estimadas No Orçamento Da Cde (Nominal)" %in% colnames(db_sistemas_isolados))
  db_sistemas_isolados <- db_sistemas_isolados %>%
    rename(`Despesas Estimadas no Orçamento da CDE (Nominal)` = `Despesas Estimadas No Orçamento Da Cde (Nominal)`)

# deflação: cria colunas reais com referência dinâmica ---------------------
nominal_dates <- as.Date(paste0(db_sistemas_isolados$Ano, "-01-01"))

if ("Despesas Estimadas CCC (Nominal)" %in% colnames(db_sistemas_isolados)) {
  col_real_ccc <- paste0("Despesas Estimadas CCC (Real, R$ ", ano_ref_ipca, ")")
  db_sistemas_isolados[[col_real_ccc]] <- ipca(
    db_sistemas_isolados$`Despesas Estimadas CCC (Nominal)`, nominal_dates, ref_ipca
  )
}

if ("Despesas Estimadas no Orçamento da CDE (Nominal)" %in% colnames(db_sistemas_isolados)) {
  col_real_cde <- paste0("Despesas Estimadas no Orçamento da CDE (Real, R$ ", ano_ref_ipca, ")")
  db_sistemas_isolados[[col_real_cde]] <- ipca(
    db_sistemas_isolados$`Despesas Estimadas no Orçamento da CDE (Nominal)`, nominal_dates, ref_ipca
  )
}

# remove anos anteriores a 2013 e ordena -----------------------------------
db_sistemas_isolados <- db_sistemas_isolados %>%
  filter(Ano >= 2013) %>%
  arrange(Ano)

# export -------------------------------------------------------------------
saveRDS(db_sistemas_isolados, "data/energia_sistemas_isolados.rds")


# dictionary --------------------------------------------------------------
db_sistemas_isolados <- read_rds("data/energia_sistemas_isolados.rds")

# extract variables from data
columns_db_sistemas_isolados <- colnames(db_sistemas_isolados)

# generate dictionary
temp_param_table <- tibble(
  var = columns_db_sistemas_isolados,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns_db_sistemas_isolados,
  desc = columns_db_sistemas_isolados,
  var_group = "Energia - EPE", #ATENCAO colunas de despesas tem fonte ANEEL
  tipo = 1,
  unidade = "",
  categoria= "Economia",
  subcategoria = "Energia"
)

temp_param_table$label <- temp_param_table$var

cols_aneel_budget <- c(
  "Despesas Estimadas CCC (Nominal)",
  paste0("Despesas Estimadas CCC (Real, R$ ", ano_ref_ipca, ")"),
  "Participação da CCC no Orçamento Total da CDE",
  "Despesas Estimadas no Orçamento da CDE (Nominal)",
  paste0("Despesas Estimadas no Orçamento da CDE (Real, R$ ", ano_ref_ipca, ")")
)

temp_param_table$var_group[temp_param_table$var %in% cols_aneel_budget]                                  <- "Orçamento CDE (Conta de Desenvolvimento Energético) - ANEEL"
temp_param_table$var_group[temp_param_table$var %in% c("Consumo Total", "Consumo Residencial", "Consumo Industrial", "Consumo Comercial", "Consumo Outros")] <- "Consumo de Eletricidade - EPE"
temp_param_table$var_group[temp_param_table$var %in% c("Consumidores Totais", "Consumidores Residenciais")]  <- "Média de Consumidores - EPE"

temp_param_table$unidade[temp_param_table$var %in% cols_aneel_budget[c(1, 2)]] <- "Bilhões de R$"
temp_param_table$unidade[temp_param_table$var == cols_aneel_budget[3]]          <- "% do Orçamento da CDE"
temp_param_table$unidade[temp_param_table$var %in% cols_aneel_budget[c(4, 5)]] <- "Bilhões de R$"
temp_param_table$unidade[temp_param_table$var %in% c("Consumo Total", "Consumo Residencial", "Consumo Industrial", "Consumo Comercial", "Consumo Outros")] <- "Milhões de MWh"
temp_param_table$unidade[temp_param_table$var %in% c("Consumidores Totais", "Consumidores Residenciais")]  <- "Milhões de Consumidores"

temp_param_table$x <- temp_param_table$var == "Ano"
temp_param_table$y <- temp_param_table$var != "Ano"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/energia_sistemas_isolados_dic.csv", fileEncoding = "UTF-8")


# translate to english --------------------------------------------------------------
temp_param_table$label[temp_param_table$var == "Ano"] <- "Year"
temp_param_table$label[temp_param_table$var == "Despesas Estimadas CCC (Nominal)"] <- "Estimated Expenses CCC (Nominal)"
temp_param_table$label[temp_param_table$var == cols_aneel_budget[2]] <- paste0("Estimated Expenses CCC (Real, R$ ", ano_ref_ipca, ")")
temp_param_table$label[temp_param_table$var == "Participação da CCC no Orçamento Total da CDE"] <- "CCC Participation in the Total Energy Development Account Budget"
temp_param_table$label[temp_param_table$var == "Despesas Estimadas no Orçamento da CDE (Nominal)"] <- "Estimated Expenses in the Energy Development Account Budget (Nominal)"
temp_param_table$label[temp_param_table$var == cols_aneel_budget[5]] <- paste0("Estimated Expenses in the Energy Development Account Budget (Real, R$ ", ano_ref_ipca, ")")
temp_param_table$label[temp_param_table$var == "Consumo Total"] <- "Total Consumption"
temp_param_table$label[temp_param_table$var == "Consumo Residencial"] <- "Residential Consumption"
temp_param_table$label[temp_param_table$var == "Consumo Industrial"] <- "Industrial Consumption"
temp_param_table$label[temp_param_table$var == "Consumo Comercial"] <- "Comercial Consumption"
temp_param_table$label[temp_param_table$var == "Consumo Outros"] <- "Other Consumption"
temp_param_table$label[temp_param_table$var == "Consumidores Totais"] <- "Total Consumers"
temp_param_table$label[temp_param_table$var == "Consumidores Residenciais"] <- "Residential Consumers"

temp_param_table$var_group[temp_param_table$var %in% cols_aneel_budget]                                  <- "CDE Budget - ANEEL"
temp_param_table$var_group[temp_param_table$var %in% c("Consumo Total", "Consumo Residencial", "Consumo Industrial", "Consumo Comercial", "Consumo Outros")] <- "Electricity Consumption - EPE"
temp_param_table$var_group[temp_param_table$var %in% c("Consumidores Totais", "Consumidores Residenciais")]  <- "Average of Consumers - EPE"

temp_param_table$unidade[temp_param_table$var %in% cols_aneel_budget[c(1, 2)]] <- "R$ Billions"
temp_param_table$unidade[temp_param_table$var == cols_aneel_budget[3]]          <- "% of the Energy Development Account Budget"
temp_param_table$unidade[temp_param_table$var %in% cols_aneel_budget[c(4, 5)]] <- "R$ Billions"
temp_param_table$unidade[temp_param_table$var %in% c("Consumo Total", "Consumo Residencial", "Consumo Industrial", "Consumo Comercial", "Consumo Outros")] <- "MWh Millions"
temp_param_table$unidade[temp_param_table$var %in% c("Consumidores Totais", "Consumidores Residenciais")]  <- "Millions of Consumers"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/energia_sistemas_isolados_dic_en.csv", fileEncoding = "UTF-8")
