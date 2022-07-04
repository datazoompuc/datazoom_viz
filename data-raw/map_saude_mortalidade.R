# packages ----------------------------------------------------------------
library(tidyverse)
library(sf)
library(sp)


# load data ---------------------------------------------------------------
df <- read_rds("data/dz_munic_saude.rds") %>% 
  select(ano, cod_ibge, starts_with("t_"), starts_with("n_"))

shapefile <- st_read("data/shapefiles/municipalities_legal_amazon.shp") %>% 
  sf::st_simplify(dTolerance = 400) %>% 
  sf::st_make_valid()

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
temp_param_table <- read_csv("data/dz_munic_saude_dic.csv")

columns <- colnames(df)

temp_param_table <- temp_param_table %>%
  filter(var %in% columns) %>%
  mutate(unidade = case_when(
    stringr::str_detect(var, "t_") ~ "Mortalidade por 100 mil habitantes",
    stringr::str_detect(var, "n_") ~ "Leitos por 100 mil habitantes",
    TRUE ~ unidade
  ))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/saude_mortalidade_dic.csv", fileEncoding = "UTF-8")

