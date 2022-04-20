# packages ----------------------------------------------------------------
library(tidyverse)
library(sf)
library(sp)


# load data ---------------------------------------------------------------
df <- read_csv("data/ext_data/saude/Dados A Saude na Amazonia Legal/dados_mun/df_mun.csv") %>% 
  select(ano, cod_ibge = cod_mun, contains("adj"))

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
  var_group = "Saúde - DATASUS",
  tipo = 1,
  unidade = "Mortalidade ajustada por idade por 100 mil habitantes",
  categoria= "Social", 
  subcategoria = "Saúde"
)

temp_param_table$label <- temp_param_table$var
temp_param_table$label[1] <- "Ano"
temp_param_table$label[2] <- "Municipio"
temp_param_table$label[3] <- "Mortalidade total"
temp_param_table$label[4] <- "Mortalidade por causas comunicáveis"
temp_param_table$label[5] <- "Mortalidade por causas externas"
temp_param_table$label[6] <- "Mortalidade por causas não comunicáveis"
temp_param_table$label[7] <- "Mortalidade por doenças cardiovasculares"
temp_param_table$label[8] <- "Mortalidade por diabetes"
temp_param_table$label[9] <- "Mortalidade por neoplasias"
temp_param_table$label[10] <- "Mortalidade por violência"
temp_param_table$label[11] <- "Mortalidade por acidentes de trânsito"
temp_param_table$label[12] <- "Mortalidade por acidentes não intencionais"
temp_param_table$label[13] <- "Mortalidade por acidentes envolvendo moto"
temp_param_table$label[14] <- "Mortalidade por acidentes não envolvendo moto"
temp_param_table$label[15] <- "Mortalidade por malária"
temp_param_table$label[16] <- "Mortalidade por AIDS"
temp_param_table$label[17] <- "Mortalidade por doenças de veiculação hídrica"
temp_param_table$label[18] <- "Mortalidade por doenças respiratórias"

temp_param_table$x <- c(FALSE, FALSE, rep(TRUE, 16))
temp_param_table$y <- c(FALSE, FALSE, rep(TRUE, 16))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, 16))
temp_param_table$size <- c(FALSE, TRUE, rep(FALSE, 16))
temp_param_table$slider <- c(TRUE, FALSE, rep(FALSE, 16))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/saude_mortalidade_dic.csv", fileEncoding = "UTF-8")

