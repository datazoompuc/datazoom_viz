
# packages ----------------------------------------------------------------
library(tidyverse)
library(sf)
library(sp)

sf::sf_use_s2(FALSE)


# load data ---------------------------------------------------------------
dat <- readRDS(file = "data/comex_munic_raw.rds")
aux <- readRDS("data/auxiliar_cod_sh4.rds")

shapefile <- readRDS("global/munic_shapefile.rds") %>%
  filter(legal_amazon == 1) %>%
  rename(cod_ibge = municipality_code) %>%
  sf::st_make_valid()

shapefile <- shapefile[!st_is_empty(shapefile), , drop=FALSE]


# get all municipalities --------------------------------------------------
munis <- tibble(cod_ibge = shapefile$cod_ibge)


#keep nome_sh4 and cod_sh4 correspondence ---------------------------------
sh4= dat %>%
  select(lab = nome_sh4, cod_sh4) %>%
  unique()


# aggregate ---------------------------------------------------------------
cod_sh4_floresta <- c("0301", "0302", "0303", "0304", "0305", "0306",
                      "0801", "0811", "0904", "1207", "1301",
                      "1511", "1515", "1801", "2008", "2009")

agg_dat <- dat %>%
  filter(cod_sh4 %in% cod_sh4_floresta) %>%
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
map_sh2 <- aux %>%
    mutate(CO_SH2 = as.numeric(substr(CO_SH4, 1, 2))) %>%
    distinct(CO_SH2, NO_SH2_PT)
df_final$nome_sh2 <- map_sh2$NO_SH2_PT[match(df_final$cod_sh2, map_sh2$CO_SH2)]
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


