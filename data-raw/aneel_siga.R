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
library(datazoom.amazonia)


# load data -------------------------------------------------------------------------
db_siga <- datazoom.amazonia::load_aneel(dataset = "energy_generation", raw_data = FALSE, language = "pt") %>%
    filter(fase == "em_operacao", !is.na(entrada_em_operacao)) %>%
    mutate(estado = str_extract(str_split_i(municipios, " - ", 2), "^.{2}"))

munic_amz_legal <- datazoom.amazonia::municipalities %>%
    filter(legal_amazon == 1)


# filter by municipality ------------------------------------------------------------
df_MA <- db_siga %>%
    filter(estado == "MA") %>%
    filter(str_detect(municipios, paste(c("Sao Luis", "Balsas", "Pindare Mirim", "Imperatriz", 
                                          "Miranda do Norte", "Codo", "Santo Antonio dos Lopes", 
                                          "Acailandia", "Cururupu", "Sao Jose de Ribamar"), collapse = "|")))
df_rest <- db_siga %>%
    filter(estado != "MA") %>%
    filter(estado %in% munic_amz_legal$abbrev_state)

df <- rbind(df_MA, df_rest)

df$fonte <- df$fonte %>%
    str_replace_all(pattern = "_", replacement = " ") %>%
    str_to_title(locale = "br") %>%
    str_replace_all(c("Termoeletrica" = "Termoelétrica", 
                      "Eolica" = "Eólica",
                      "Pequena Central Hidreletrica" = "Pequena Central Hidrelétrica",
                      "Central Geradora Hidreletrica" = "Central Geradora Hidrelétrica",
                      "Usina Hidreletrica" = "Usina Hidrelétrica"))
df$origem <- df$origem %>%
    str_replace_all(pattern = "_", replacement = " ") %>%
    str_to_title(locale = "br") %>%
    str_replace_all(c("Fossil" = "Fóssil",
                      "Eolica" = "Eólica",
                      "Hidrica" = "Hídrica"))

df$tipo <- df$tipo %>%
    str_replace_all(pattern = "_", replacement = " ") %>%
    str_to_title(locale = "br") %>%
    str_replace_all(c("Carvao Mineral" = "Carvão Mineral",
                      "Petroleo" = "Petróleo",
                      "Radiacao Solar" = "Radiação Solar",
                      "Gas Natural" = "Gás Natural",
                      "Cinetica Do Vento" = "Cinética Do Vento",
                      "Potencial Hidraulico" = "Potencial Hidráulico",
                      "Biocombustiveis Liquidos" = "Biocombustíveis Líquidos",
                      "Residuos Animais" = "Resíduos Animais",
                      "Outros Fosseis" = "Outros Fósseis",
                      "Residuos Solidos Urbanos" = "Resíduos Solidos Urbanos",
                      "Uranio" = "Urânio"
                      ))

df$combustivel_final <- df$combustivel_final %>%
    str_replace_all(pattern = "_", replacement = " ") %>%
    str_to_title(locale = "br") %>%
    str_replace_all(c("Carvao Mineral" = "Carvão Mineral",
                      "Oleo Diesel" = "Óleo Diesel",
                      "Gas De Alto Forno Biomassa" = "Gás De Alto Forno - Biomassa",
                      "Gas De Alto Forno" = "Gás De Alto Forno - CM",
                      "Radiacao Solar" = "Radiação Solar",
                      "Oleo Combustivel" = "Óleo Combustivel",
                      "Gas Natural" = "Gás Natural",
                      "Cinetica Do Vento" = "Cinética Do Vento",
                      "Calor De Processo Gn" = "Calor De Processo - GN",
                      "Carvao Vegetal" = "Carvão Vegetal",
                      "Potencial Hidraulico" = "Potencial Hidráulico",
                      "Residuos Florestais" = "Resíduos Florestais",
                      "Bagaco De Cana" = "Bagaço De Cana",
                      "Oleos Vegetais" = "Óleos Vegetais",
                      "Biogas Residuo Animal" = "Biogás Resíduo Animal",
                      "Calor De Processo Of" = "Calor De Processo - OF",
                      "Carvao Ru" = "Carvão - RU",
                      "Biogas Agroindustriais" = "Biogás - Agroindustriais",
                      "Uranio" = "Urânio",
                      "Biogas Residuos Urbanos" = "Biogás - Resíduos Urbanos",
                      "Residuos Solidos Urbanos" = "Resíduos Sólidos Urbanos",
                      "Outros Energeticos de Petroleo" = "Outros Energéticos de Petróleo",
                      "Gas De Refinaria" = "Gás De Refinaria",
                      "Calor De Processo Cm" = "Calor De Processo - CM",
                      "Biogas Floresta" = "Biogas - Floresta",
                      "Gas De Alto Forno Pe" = "Gás De Alto Forno - PE"
                      ))


# create panel ----------------------------------------------------------------------
create_panel <- function(df_row) {
    
    years_op <- (df_row$entrada_em_operacao):2022
    panel <- cbind(tibble(ano = years_op), df_row)
    
}

df_panel <- df %>% 
    mutate(entrada_em_operacao = as.Date(entrada_em_operacao, "%d/%m/%Y")) %>%
    select(entrada_em_operacao, municipios, estado, 
           fonte, origem, tipo, combustivel_final, 
           potencia_outorgada_kw) %>%
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
df_final <- read_rds("./data/aneel_siga_geracao_distribuida.rds")

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


temp_param_table$label[temp_param_table$var == "ano"] <- "Ano"
temp_param_table$label[temp_param_table$var == "estado"] <- "Estado"
temp_param_table$label[temp_param_table$var == "fonte"] <- "Fonte"
temp_param_table$label[temp_param_table$var == "origem"] <- "Origem"
temp_param_table$label[temp_param_table$var == "tipo"] <- "Tipo"
temp_param_table$label[temp_param_table$var == "municipios"] <- "Municípios"
temp_param_table$label[temp_param_table$var == "combustivel_final"] <- "Combustível Final"
temp_param_table$label[temp_param_table$var == "potencia_outorgada_kw"] <- "Potência Outorgada (kW)"


temp_param_table$x <- c(TRUE, rep(FALSE, 7))
temp_param_table$y <- c(rep(FALSE, 7), TRUE)
temp_param_table$color <- c(FALSE, rep(TRUE, 6), FALSE)
temp_param_table$slider <- c(TRUE, rep(FALSE, 7))


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/aneel_siga_geracao_distribuida_dic.csv", 
          fileEncoding = "UTF-8")


# translate to english -------------------------------------------
temp_param_table$var_group = "Energy - ANEEL"
temp_param_table$categoria = "Economy"
temp_param_table$subcategoria = "Energy"

temp_param_table$label[temp_param_table$var == "ano"] <- "Year"
temp_param_table$label[temp_param_table$var == "municipio"] <- "Municipality name"
temp_param_table$label[temp_param_table$var == "estado"] <- "State"
temp_param_table$label[temp_param_table$var == "fonte"] <- "Source"
temp_param_table$label[temp_param_table$var == "origem"] <- "Origin"
temp_param_table$label[temp_param_table$var == "tipo"] <- "Type"
temp_param_table$label[temp_param_table$var == "combustivel_final"] <- "Final Fuel"
temp_param_table$label[temp_param_table$var == "potencia_outorgada_kw"] <- "Granted Power (kW)"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/aneel_siga_geracao_distribuida_dic_en.csv", 
          fileEncoding = "UTF-8")