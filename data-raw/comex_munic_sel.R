
# packages ----------------------------------------------------------------
library(tidyverse)
library(sf)
library(sp)


# load data ---------------------------------------------------------------
dat <- readRDS(file = "data/comex_munic_raw.rds")
aux <- readRDS("data/auxiliar_cod_sh4.rds")

shapefile <- st_read("data/shapefiles/municipalities_legal_amazon.shp") %>% 
  sf::st_simplify(dTolerance = 400) %>% 
  sf::st_make_valid() %>% 
  mutate(cod_ibge = as.numeric(cod_ibge))

shapefile <- shapefile[!st_is_empty(shapefile), , drop=FALSE]


# get all municipalities --------------------------------------------------
munis <- tibble(cod_ibge = shapefile$cod_ibge)


# aggregate ---------------------------------------------------------------
agg_dat <- dat %>% 
  group_by(ano, cod_municipio, nome_sh4) %>% 
  summarise(value = sum(valor_fob)) %>% 
  filter(nome_sh4 %in% c("Peixes vivos",
                         "Peixes frescos ou refrigerados, exceto os files de peixes e outra carne de peixes da posicao 03.04",
                         "Peixes congelados, exceto os files de peixes e outra carne de peixes da posicao 03.04",
                         "Files de peixes e outra carne de peixes (mesmo picada), frescos, refrigerados ou congelados",
                         "Peixes secos, salgados ou em salmoura; peixes defumados, mesmo cozidos antes ou durante a defumacao; farinhas, pos e pellets, de peixe, proprios para alimentacao humana",
                         "Crustaceos, mesmo sem casca, vivos, frescos, refrigerados, congelados, secos, salgados ou em salmoura; crustaceos com casca, cozidos em agua ou vapor, mesmo refrigerados, congelados, secos, salgados ou em salmoura; farinhas, po e pellets de crustaceos, pr",
                         "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados",
                         "Frutas, nao cozidas ou cozidas em agua ou vapor, congeladas, mesmo adicionadas de acucar ou de outros edulcorantes",
                         "Pimenta (do genero Piper); pimentos dos generos Capsicum ou Pimenta, secos ou triturados ou em po",
                         "Outras sementes e frutos oleaginosos, mesmo triturados",
                         "Goma-laca; gomas, resinas, gomas-resinas e oleorresinas (balsamos por exemplo), naturais",
                         "Oleo de palma e respectivas fraccoes, mesmo refinados, mas nao quimicamente modificados",
                         "Outras gorduras e oleos vegetais (incluido o oleo de jojoba) e respectivas fraccoes, fixos, mesmo refinados, mas nao quimicamente modificados",
                         "Cacau inteiro ou partido, em bruto ou torrado",
                         "Frutas e outras partes comestiveis de plantas, preparadas ou conservadas de outro modo, com ou sem adicao de acucar ou de outros edulcorantes ou de alcool, nao especificadas nem compreendidas noutras posicoes",
                         "Sumos de frutas (incluidos os mostos de uvas) ou de produtos horticolas, nao fermentados, sem adicao de alcool, com ou sem adicao de acucar ou de outros edulcorantes")) %>% 
  ungroup() %>% 
  rename(time = ano, cod_ibge = cod_municipio, group = nome_sh4) %>% 
  right_join(munis) %>% 
  complete(time, cod_ibge, group) %>% 
  replace_na(list(value = 0)) %>% 
  filter(!is.na(group), !is.na(time), !is.na(cod_ibge)) %>% 
  pivot_wider(names_from = group, values_from = value) %>% 
  rowwise() %>%
  mutate(maximo_produto = max(c_across(`Cacau inteiro ou partido, em bruto ou torrado`:`Sumos de frutas (incluidos os mostos de uvas) ou de produtos horticolas, nao fermentados, sem adicao de alcool, com ou sem adicao de acucar ou de outros edulcorantes`)))

agg_dat$produto_principal <- 
  agg_dat %>% 
  select(`Cacau inteiro ou partido, em bruto ou torrado`:`Sumos de frutas (incluidos os mostos de uvas) ou de produtos horticolas, nao fermentados, sem adicao de alcool, com ou sem adicao de acucar ou de outros edulcorantes`) %>% 
  {names(.)[max.col(.)]}

agg_dat <- agg_dat %>% 
  mutate(produto_principal = ifelse(maximo_produto == 0, NA, produto_principal)) %>% 
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
  mutate(maximo_produto_todos = max(c_across(`<<Tecidos turcos>>, exceto os artefactos da posicao 5806; tecidos tufados, exceto os artefactos da posicao 5703`:`Zinco em formas brutas`)))

agg_dat_all$produto_principal_todos <- 
  agg_dat_all %>% 
  select(`<<Tecidos turcos>>, exceto os artefactos da posicao 5806; tecidos tufados, exceto os artefactos da posicao 5703`:`Zinco em formas brutas`) %>% 
  {names(.)[max.col(.)]}

agg_dat_all <- agg_dat_all %>% 
  mutate(produto_principal_todos = ifelse(maximo_produto_todos == 0, NA, produto_principal_todos)) %>% 
  mutate(lab_todos = produto_principal_todos,
         produto_principal_todos = ifelse(nchar(produto_principal_todos) >= 40,
                                    paste0(substr(produto_principal_todos, 1, 40), "..."),
                                           produto_principal_todos))


# join tables -------------------------------------------------------------
agg_dat_selcolumns <- agg_dat %>% 
  select(time, cod_ibge, maximo_produto, produto_principal, lab) %>% 
  mutate(floresta = TRUE)

agg_dat_all_selcolumns <- agg_dat_all %>% 
  select(time, cod_ibge, 
         maximo_produto = maximo_produto_todos, 
         produto_principal = produto_principal_todos, 
         lab = lab_todos) %>% 
  mutate(floresta = FALSE)

df_final <- rbind(agg_dat_selcolumns, agg_dat_all_selcolumns) %>% 
  data.frame() %>% 
  tibble()
  

# value as relative -------------------------------------------------------
total_value_amz <- dat %>% 
  group_by(ano, nome_sh4) %>% 
  summarise(value = sum(valor_fob))

change_to_relative_value <- function(valor, ano_produto, produto) {
  
  valor_total <- total_value_amz %>% 
    filter(nome_sh4 == produto, ano == ano_produto) %>% 
    pull(value)
  
  return((valor/valor_total) * 100)
  
}

df_final <- df_final %>% 
  rowwise() %>% 
  mutate(maximo_produto = ifelse(maximo_produto != 0,
                                 change_to_relative_value(maximo_produto, time, lab),
                                 0))


# merge with shape --------------------------------------------------------
data <- sp::merge(shapefile, data.frame(df_final)) %>% 
  select(-fid, -cd_geocmu)

st_geometry(data) <- data$geometry


# export ------------------------------------------------------------------
# save simplified sf for faster maps
cols <- colnames(data)
data <- rmapshaper::ms_simplify(data, 
                                keep_shapes = TRUE, 
                                keep = 0.01)

#simplifying forest products names to fit the map
data= data%>%
  mutate(lab= case_when(lab == "Peixes vivos" ~ "Peixes vivos",
                        lab == "Peixes frescos ou refrigerados, exceto os files de peixes e outra carne de peixes da posicao 03.04" ~ "Peixes frescos/refrigerados, exceto filés",
                        lab == "Peixes congelados, exceto os files de peixes e outra carne de peixes da posicao 03.04" ~ "Peixes congelados, exceto filés",
                        lab == "Files de peixes e outra carne de peixes (mesmo picada), frescos, refrigerados ou congelados" ~ "Filés de peixe e outras carnes",
                        lab == "Peixes secos, salgados ou em salmoura; peixes defumados, mesmo cozidos antes ou durante a defumacao; farinhas, pos e pellets, de peixe, proprios para alimentacao humana" ~ "Peixes secos, salgados ou cozidos",
                        lab == "Crustaceos, mesmo sem casca, vivos, frescos, refrigerados, congelados, secos, salgados ou em salmoura; crustaceos com casca, cozidos em agua ou vapor, mesmo refrigerados, congelados, secos, salgados ou em salmoura; farinhas, po e pellets de crustaceos, pr" ~ "Crustaceos vivos ou não, para alimento",
                        lab == "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados" ~ "Cocos e castanhas do Brasil e de caju",
                        lab == "Frutas, nao cozidas ou cozidas em agua ou vapor, congeladas, mesmo adicionadas de acucar ou de outros edulcorantes" ~ "Frutas cozidas ou não, misturadas ou não",
                        lab == "Pimenta (do genero Piper); pimentos dos generos Capsicum ou Pimenta, secos ou triturados ou em po" ~ "Pimentas secas ou trituradas",
                        lab == "Outras sementes e frutos oleaginosos, mesmo triturados" ~ "Outras sementes e oleaginosos",
                        lab == "Goma-laca; gomas, resinas, gomas-resinas e oleorresinas (balsamos por exemplo), naturais" ~ "Gomas e resinas naturais",
                        lab == "Oleo de palma e respectivas fraccoes, mesmo refinados, mas nao quimicamente modificados" ~ "Óleo de palma não modificado",
                        lab == "Outras gorduras e oleos vegetais (incluido o oleo de jojoba) e respectivas fraccoes, fixos, mesmo refinados, mas nao quimicamente modificados" ~ "Outras gorduras e óleos vegetais",
                        lab == "Cacau inteiro ou partido, em bruto ou torrado" ~ "Cacau bruto ou torrado",
                        lab == "Frutas e outras partes comestiveis de plantas, preparadas ou conservadas de outro modo, com ou sem adicao de acucar ou de outros edulcorantes ou de alcool, nao especificadas nem compreendidas noutras posicoes" ~ "Frutas e outros comestíveis de planta",
                        lab == "Sumos de frutas (incluidos os mostos de uvas) ou de produtos horticolas, nao fermentados, sem adicao de alcool, com ou sem adicao de acucar ou de outros edulcorantes" ~ "Sumos de frutas, com ou sem aditivos",
                        TRUE ~ lab))

data$produto_principal = data$lab

colnames(data) <- cols

saveRDS(data, "data/comex_exp_munic_sh4_sel.rds")


# dictionary --------------------------------------------------------------
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
  var_group = "Comex",
  tipo = 1,
  unidade = "% das exportações da Amazônia no ano",
  categoria= "Economia", 
  subcategoria = "Comercio exterior"
)

temp_param_table$label <- temp_param_table$var
temp_param_table$label[1] <- "Ano"
temp_param_table$label[2] <- "Municipio"
temp_param_table$label[3] <- "Valor relativo do principal produto exportado"
temp_param_table$label[4] <- "Principal produto exportado"
temp_param_table$label[6] <- "Produtos Compatíveis com a Floresta"
temp_param_table$x <- c(FALSE, FALSE, TRUE, TRUE, FALSE, FALSE)
temp_param_table$y <- c(FALSE, FALSE, TRUE, TRUE, FALSE, FALSE)
temp_param_table$color <- c(FALSE, TRUE, FALSE, FALSE, FALSE, TRUE)
temp_param_table$size <- c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE)
temp_param_table$slider <- c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_munic_sh4_sel_dic.csv", fileEncoding = "UTF-8")

