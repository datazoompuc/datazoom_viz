############################################################
#### Generate global/munic_shapefile.rds
############################################################

library(tidyverse)
library(sf)
library(rmapshaper)
library(datazoom.amazonia)

# Geometria municipal simplificada (topology-aware — ver troubleshooting.md,
# seção "Espaços em branco entre municípios vizinhos": nunca usar
# sf::st_simplify() aqui, só rmapshaper::ms_simplify(), senão reintroduz
# frestas entre municípios vizinhos). Usada por vários apps de mapa
# municipal (map_mapbiomas_cover, map_dz_munic_prodes, map_dz_munic_ppm,
# map_dz_munic_cempre) — por isso vive em global/, não em data/. Extraído de
# data-raw/mapbiomas_cobertura_map.R, onde vivia como efeito colateral do
# pipeline de dados do MapBiomas sem nenhuma relação real com ele.
shapefile <- datazoom.amazonia:::external_download("geo_municipalities", source = "internal") |>
    left_join(datazoom.amazonia::municipalities, by = "code_muni") |>
    select(municipality_code = code_muni, geom, legal_amazon) |>
    st_make_valid() |>
    rmapshaper::ms_simplify()

saveRDS(shapefile, "global/munic_shapefile.rds")
