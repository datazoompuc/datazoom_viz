# packages ----------------------------------------------------------------
library(tidyverse)
library(sf)
library(sp)


# load data ---------------------------------------------------------------
df <- read_csv("data/ext_data/saude/Dados A Saude na Amazonia Legal/dados_mun/df_mun.csv") %>% 
  select(ano, cod_ibge = cod_mun, t_mortalidade:`t_ncommunicable_adj.N`)

shapefile <- st_read("data/shapefiles/municipalities_legal_amazon.shp") %>% 
  sf::st_simplify(dTolerance = 400) %>% 
  sf::st_make_valid() %>% 
  mutate(cod_ibge = as.numeric(substr(cod_ibge, 1, 6)))

shapefile <- shapefile[!st_is_empty(shapefile), , drop=FALSE]


# merge with shape --------------------------------------------------------
data <- sp::merge(shapefile, data.frame(df)) %>% 
  select(-fid, -cd_geocmu)

st_geometry(data) <- data$geometry


# export ------------------------------------------------------------------
# save simplified sf for faster maps
cols <- colnames(data)
data <- rmapshaper::ms_simplify(data, 
                                keep_shapes = TRUE, 
                                keep = 0.01)

colnames(data) <- cols

saveRDS(data, "data/saude_mortalidade.rds")


# dictionary --------------------------------------------------------------
# extract variables from data
columns <- colnames(df)

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
  var_group = "Saude",
  tipo = 1,
  unidade = "Mortalidade por 100 mil habitantes",
  categoria= "Social", 
  subcategoria = "Saude"
)

temp_param_table$label <- temp_param_table$var
temp_param_table$label[1] <- "Ano"
temp_param_table$label[2] <- "Municipio"
temp_param_table$label[3] <- "Mortalidade bruta por 100 mil habitantes"
temp_param_table$label[4] <- "Mortalidade ajustada por idade por 100 mil habitantes"
temp_param_table$label[5] <- "Mortalidade por causas não comunicáveis por 100 mil habitantes"
temp_param_table$label[6] <- "Mortalidade ajustada por causas comunicáveis por 100 mil habitantes"
temp_param_table$label[7] <- "Mortalidade por causas externas por 100 mil habitantes"
temp_param_table$label[8] <- "Mortalidade ajustada por causas externas por 100 mil habitantes"
temp_param_table$label[9] <- "Mortalidade por causas comunicáveis por 100 mil habitantes"
temp_param_table$label[10] <- "Mortalidade ajustada por causas não comunicáveis por 100 mil habitantes"

temp_param_table$x <- c(FALSE, FALSE, rep(TRUE, 8))
temp_param_table$y <- c(FALSE, FALSE, rep(TRUE, 8))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, 8))
temp_param_table$size <- c(FALSE, TRUE, rep(FALSE, 8))
temp_param_table$slider <- c(TRUE, FALSE, rep(FALSE, 8))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/saude_mortalidade_dic.csv", fileEncoding = "UTF-8")

