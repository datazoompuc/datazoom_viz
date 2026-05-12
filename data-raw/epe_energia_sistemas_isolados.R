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


#######################

#Despesas na Conta de Desenvolvimento Estratégico (CDE)
#fonte: Agencia Nacional de Energia Elétrica
#https://portalrelatorios.aneel.gov.br/luznatarifa/contadesenvolvimento

db_orcamento_cde <- read_csv(file = "data-raw/bases viz energia CPI/sistemas_isolados_despesas_estimadas_no_orcamento_da_cde.csv", skip = 0) %>%
  select(c("Ano", "Valor")) %>%
  rename("valor" = "Valor") %>%
  filter(Ano != 2022) %>%
  mutate(valor = valor / 1e9,
         tipo = "DESPESAS ESTIMADAS CCC (Nominal)",
         nominal_dates = as.Date(paste0(Ano, "-01-01")),
         `DESPESAS ESTIMADAS CCC (Real, R$ 2021)` = ipca(valor, nominal_dates, "01/2021")) %>%
  select(Ano, `DESPESAS ESTIMADAS CCC (Nominal)` = valor, 
         `DESPESAS ESTIMADAS CCC (Real, R$ 2021)`)

db_orcamento_cde_particip <- read_csv(file = "data-raw/bases viz energia CPI/sistemas_isolados_despesas_estimadas_no_orcamento_da_cde_particip.csv", skip = 0) %>%
  select(c("Ano", participacao = "Participação")) %>%
  filter(Ano != 2022) %>%
  mutate(participacao = str_remove_all(participacao, "[%]"),
         participacao = str_replace_all(participacao, "[,]", "."),
         participacao = as.numeric(participacao))
  
db_orcamento_total = read_csv(file = "data-raw/bases viz energia CPI/sistemas_isolados_despesas_estimadas_no_orçamento_da_CDE.csv") %>%
  select("Ano", "Valor") %>%
  rename("valor" = "Valor") %>%
  filter(Ano != 2022) %>%
  mutate(valor = valor/1e9) %>%
  group_by(Ano) %>%
  summarise("DESPESAS ESTIMADAS NO ORÇAMENTO DA CDE (Nominal)" = sum(`valor`)) %>%
  mutate(nominal_dates = as.Date(paste0(Ano, "-01-01")),
         `DESPESAS ESTIMADAS NO ORÇAMENTO DA CDE (Real, R$ 2021)` = ipca(`DESPESAS ESTIMADAS NO ORÇAMENTO DA CDE (Nominal)`, nominal_dates, "01/2021")) %>%
  select(Ano, `DESPESAS ESTIMADAS NO ORÇAMENTO DA CDE (Nominal)`, 
         `DESPESAS ESTIMADAS NO ORÇAMENTO DA CDE (Real, R$ 2021)`)
  
#tudo junto ---------------------------------------------------------------
db_completa = full_join(db_consumo, db_consumidores)
db_sistemas_isolados_p1 = full_join(db_completa, db_orcamento_cde)
db_sistemas_isolados_p2 = full_join(db_sistemas_isolados_p1, db_orcamento_cde_particip)
db_sistemas_isolados_p3 = full_join(db_sistemas_isolados_p2, db_orcamento_total)

# pivot table -----------------------------------------------------------------------
db_sistemas_isolados <- db_sistemas_isolados_p3 %>%
  pivot_wider(names_from = tipo, values_from = valor)

colnames(db_sistemas_isolados) <- str_to_title(colnames(db_sistemas_isolados))

db_sistemas_isolados <- db_sistemas_isolados %>%
  rename(`Despesas Estimadas CCC (Nominal)` = `Despesas Estimadas Ccc (Nominal)`,
         `Despesas Estimadas CCC (Real, R$ 2021)` = `Despesas Estimadas Ccc (Real, R$ 2021)`,
         `Participação da CCC no Orçamento Total da CDE` = Participacao,
         `Despesas Estimadas no Orçamento da CDE (Nominal)` = `Despesas Estimadas No Orçamento Da Cde (Nominal)`,
         `Despesas Estimadas no Orçamento da CDE (Real, R$ 2021)` = `Despesas Estimadas No Orçamento Da Cde (Real, R$ 2021)`)
        

# remove years before 2013 ----------------------------------------------------------
db_sistemas_isolados <- db_sistemas_isolados %>%
  filter(Ano >= 2013)


# export ------------------------------------------------------------------
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

temp_param_table$var_group[2:6] <- "Orçamento CDE (Conta de Desenvolvimento Energético) - ANEEL"
temp_param_table$var_group[7:11] <- "Consumo de Eletricidade - EPE"
temp_param_table$var_group[12:13] <- "Média de Consumidores - EPE"

temp_param_table$unidade[2:3] <- "Bilhões de R$"
temp_param_table$unidade[4] <- "% do Orçamento da CDE"
temp_param_table$unidade[5:6] <- "Bilhões de R$"
temp_param_table$unidade[7:11] <- "Milhões de MWh"
temp_param_table$unidade[12:13] <- "Milhões de Consumidores"


temp_param_table$x <- c(TRUE, rep(FALSE, 12))
temp_param_table$y <- c(FALSE, rep(TRUE, 12))


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/energia_sistemas_isolados_dic.csv", fileEncoding = "UTF-8")


# translate to english --------------------------------------------------------------
temp_param_table$label[temp_param_table$var == "Ano"] <- "Year"
temp_param_table$label[temp_param_table$var == "Despesas Estimadas CCC (Nominal)"] <- "Estimated Expenses CCC (Nominal)"
temp_param_table$label[temp_param_table$var == "Despesas Estimadas CCC (Real, R$ 2021)"] <- "Estimated Expenses CCC (Real, R$ 2021)"
temp_param_table$label[temp_param_table$var == "Participação da CCC no Orçamento Total da CDE"] <- "CCC Participation in the Total Energy Development Account Budget"
temp_param_table$label[temp_param_table$var == "Despesas Estimadas no Orçamento da CDE (Nominal)"] <- "Estimated Expenses in the Energy Development Account Budget (Nominal)"
temp_param_table$label[temp_param_table$var == "Despesas Estimadas no Orçamento da CDE (Real, R$ 2021)"] <- "Estimated Expenses in the Energy Development Account Budget (Real, R$ 2021)"
temp_param_table$label[temp_param_table$var == "Consumo Total"] <- "Total Consumption"
temp_param_table$label[temp_param_table$var == "Consumo Residencial"] <- "Residential Consumption"
temp_param_table$label[temp_param_table$var == "Consumo Industrial"] <- "Industrial Consumption"
temp_param_table$label[temp_param_table$var == "Consumo Comercial"] <- "Comercial Consumption"
temp_param_table$label[temp_param_table$var == "Consumo Outros"] <- "Other Consumption"
temp_param_table$label[temp_param_table$var == "Consumidores Totais"] <- "Total Consumers"
temp_param_table$label[temp_param_table$var == "Consumidores Residenciais"] <- "Residential Consumers"

temp_param_table$var_group[2:6] <- "CDE Budget - ANEEL"
temp_param_table$var_group[7:11] <- "Eletricity Consumption - EPE"
temp_param_table$var_group[12:13] <- "Average of Consumers - EPE"

temp_param_table$unidade[2:3] <- "R$ Billions"
temp_param_table$unidade[4] <- "% of the Energy Development Account Budget"
temp_param_table$unidade[5:6] <- "R$ Billions"
temp_param_table$unidade[7:11] <- "MWh Millions"
temp_param_table$unidade[12:13] <- "Millions of Consumers"


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/energia_sistemas_isolados_dic_en.csv", fileEncoding = "UTF-8")
