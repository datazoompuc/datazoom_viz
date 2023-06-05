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
    filter(fase == "Operação", !is.na(entrada_em_operacao))

# edit variable of municipalities
db_siga <- db_siga %>%
        separate(municipio_s, c("municipio_v1", "estado_v1"), sep = " - ") %>%
        separate(estado_v1, c("estado_v2", "municipio_v2"), sep = ",")  %>%
        mutate(municipio = municipio_v1,
               estado = estado_v2)

db_siga$municipio_v1 <- NULL
db_siga$municipio_v2 <- NULL
db_siga$estado_v2 <- NULL


# filter by municipality ------------------------------------------------------------
df_MA <- db_siga %>%
    filter(estado == "MA") %>%
    filter(municipio %in% c("São Luís", "Balsas", "Pindaré Mirim", "Imperatriz", 
                            "Miranda do Norte", "Codó", "Santo Antônio dos Lopes", 
                            "Açailândia", "Cururupu", "São José de Ribamar"))

df_rest <- db_siga %>%
    filter(estado %in% c("AC", "AM", "AP", "MT", "PA", "RO", "RR","TO"))

db_siga <- rbind(df_MA, df_rest) 
rm(df_MA, df_rest)

# create panel ----------------------------------------------------------------------
df_panel <- db_siga %>% 
    mutate(entrada_em_operacao = as.Date(entrada_em_operacao, "%d/%m/%Y")) %>%
    select(entrada_em_operacao, municipio, estado, 
           fonte, origem, tipo, combustivel_final, 
           potencia_outorgada_k_w) %>%
    mutate(entrada_em_operacao = year(entrada_em_operacao),
           uf_munic = paste0(estado, " - ", municipio)) %>%
    arrange(uf_munic, fonte, origem, tipo, combustivel_final, entrada_em_operacao)

df_panel_state_level <- df_panel %>% 
    group_by(estado, entrada_em_operacao, fonte, origem, tipo, combustivel_final) %>%
    summarise(potencia_outorgada_k_w = sum(potencia_outorgada_k_w)) %>%
    arrange(estado, fonte, origem, tipo, combustivel_final, entrada_em_operacao) %>%
    ungroup()
    
# give 0 to NA
df_panel_state_level$potencia_outorgada_k_w[is.na(df_panel_state_level$potencia_outorgada_k_w)] <- 0

# truncate variable from 2002
# but we should take into account potencia_outorgada before 2002 as well
df_panel_state_level_before_2002 <- df_panel_state_level %>%
    filter(entrada_em_operacao <=2002) %>%
    ungroup()

df_panel_state_level_after_2002 <- df_panel_state_level %>%
    filter(entrada_em_operacao > 2002) %>%
    ungroup()

df_panel_state_level_before_2002 <- df_panel_state_level_before_2002 %>%
    group_by(estado, fonte, origem, tipo, combustivel_final) %>%
    summarise(potencia_outorgada_k_w = sum(potencia_outorgada_k_w)) %>%
    ungroup()

df_panel_state_level_before_2002$entrada_em_operacao <- 2002 

base <- rbind(df_panel_state_level_before_2002, df_panel_state_level_after_2002) %>%
    arrange(estado, fonte, origem, tipo, combustivel_final, entrada_em_operacao)


# create panel function
create_panel <- function(df_row) {
    
    years_op <- (df_row$entrada_em_operacao):2022
    panel <- cbind(tibble(ano = years_op), df_row)
    
}

### run function
df_list <- list()
for(row in 1:nrow(base)) {
    
    df_list[[row]] <- create_panel(base[row, ])
    
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
    x = FALSE,
    y = FALSE,
    color = TRUE,
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

temp_param_table$label[temp_param_table$var == "ano"] <- "Ano"
temp_param_table$label[temp_param_table$var == "estado"] <- "Estado"
temp_param_table$label[temp_param_table$var == "fonte"] <- "Fonte"
temp_param_table$label[temp_param_table$var == "origem"] <- "Origem"
temp_param_table$label[temp_param_table$var == "tipo"] <- "Tipo"
temp_param_table$label[temp_param_table$var == "combustivel_final"] <- "Combustível Final"
temp_param_table$label[temp_param_table$var == "potencia_outorgada_k_w"] <- "Potência Outorgada (kW)"

temp_param_table$x[temp_param_table$var == "ano"] <- TRUE
temp_param_table$y[temp_param_table$var == "potencia_outorgada_k_w"] <- TRUE
temp_param_table$color[temp_param_table$var == "Ano"] <- FALSE
temp_param_table$color[temp_param_table$var == "potencia_outorgada_k_w"] <- FALSE
temp_param_table$slider[temp_param_table$var == "ano"] <- TRUE

# Unidade de medida
temp_param_table$unidade[str_detect(temp_param_table$var, regex("potencia_outorgada_k_w", ignore_case = TRUE))] <- "kilowatt"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/aneel_siga_geracao_distribuida_dic.csv", 
          fileEncoding = "UTF-8")


# translate to english --------------------------------------------------------------
temp_param_table$label[temp_param_table$var == "ano"] <- "Year"
temp_param_table$label[temp_param_table$var == "estado"] <- "State"
temp_param_table$label[temp_param_table$var == "fonte"] <- "Source"
temp_param_table$label[temp_param_table$var == "origem"] <- "Origin"
temp_param_table$label[temp_param_table$var == "tipo"] <- "Type"
temp_param_table$label[temp_param_table$var == "combustivel_final"] <- "Final Fuel"
temp_param_table$label[temp_param_table$var == "potencia_outorgada_k_w"] <- "Granted Power (kW)"

# save csv in utf-8 encoding
write.csv(temp_param_table,
          file = "data/aneel_siga_geracao_distribuida_dic_en.csv",
          fileEncoding = "UTF-8"
)