#######################
##Geração Distribuída
#######################

#SIGA - Sistema de Informações de Geração da Aneel
#fonte: Agencia Nacional de Energia Elétrica
#https://app.powerbi.com/view?r=eyJrIjoiNjc4OGYyYjQtYWM2ZC00YjllLWJlYmEtYzdkNTQ1MTc1NjM2IiwidCI6IjQwZDZmOWI4LWVjYTctNDZhMi05MmQ0LWVhNGU5YzAxNzBlMSIsImMiOjR9


# packages --------------------------------------------------------------------------
library(tidyverse)
library(readxl)
library(lubridate)


# load data -------------------------------------------------------------------------
db_siga <- read_xlsx(file.path("data-raw/bases viz energia CPI", 
                               "geracao_distribuida_BD_SIGA.xlsx"), 
                     skip = 1, col_names = TRUE) %>%
  janitor::clean_names() %>%
  filter(fase == "Operação", !is.na(entrada_em_operacao)) %>%
  separate(municipio_s, c("municipio", "estado"), sep = " - ")

munic_amz_legal <- datazoom.amazonia::municipalities %>%
  filter(legal_amazon == 1)


# filter by municipality ------------------------------------------------------------
df_MA <- db_siga %>%
  filter(estado == "MA") %>%
  filter(municipio %in% c("São Luís", "Balsas", "Pindaré Mirim", "Imperatriz", 
                          "Miranda do Norte", "Codó", "Santo Antônio dos Lopes", 
                          "Açailândia", "Cururupu", "São José de Ribamar"))

df_rest <- db_siga %>%
  filter(estado != "MA") %>%
  filter(estado %in% munic_amz_legal$abbrev_state)

df <- rbind(df_MA, df_rest) 


# create panel ----------------------------------------------------------------------
create_panel <- function(df_row) {
  
  years_op <- (df_row$entrada_em_operacao):2022
  panel <- cbind(tibble(ano = years_op), df_row)
  
}

df_panel <- df %>% 
  mutate(entrada_em_operacao = as.Date(entrada_em_operacao, "%d/%m/%Y")) %>%
  select(entrada_em_operacao, municipio, estado, 
         fonte, origem, tipo, combustivel_final, 
         potencia_outorgada_k_w) %>%
  mutate(entrada_em_operacao = year(entrada_em_operacao))

### run function
df_list <- list()
for(row in 1:nrow(df_panel)) {
  
  df_list[[row]] <- create_panel(df_panel[row, ])
  
}

df_final <- bind_rows(df_list) %>%
  filter(ano >= 2002) %>%
  select(-entrada_em_operacao)


# export data -----------------------------------------------------------------------
write_rds(df_final, "data/aneel_siga_geracao_distribuida.rds")


# dictionary ------------------------------------------------------------------------
# extract variables from data
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
  var_group = "Energia - ANEEL",
  tipo = 1,
  unidade = "",
  categoria= "Economia", 
  subcategoria = "Energia"
)

temp_param_table$label <- temp_param_table$var
temp_param_table$label[1] <- "Ano"
temp_param_table$label[2] <- "Nome do municipio"
temp_param_table$label[3] <- "Estado"
temp_param_table$label[4] <- "Fonte"
temp_param_table$label[5] <- "Origem"
temp_param_table$label[6] <- "Tipo"
temp_param_table$label[7] <- "Combustível Final"
temp_param_table$label[8] <- "Potência Outorgada (kW)"

temp_param_table$x <- c(TRUE, rep(FALSE, 7))
temp_param_table$y <- c(rep(FALSE, 7), TRUE)
temp_param_table$color <- c(FALSE, rep(TRUE, 6), FALSE)
temp_param_table$slider <- c(TRUE, rep(FALSE, 7))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/aneel_siga_geracao_distribuida_dic.csv", 
          fileEncoding = "UTF-8")


