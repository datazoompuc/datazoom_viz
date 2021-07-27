#creating and saving metadata for all the databases from the datazoom.amazonia R package

### Creating metadatabase -> IBGE - PEVS
geo_id= c('geo_id', TRUE, TRUE, FALSE, FALSE, FALSE, 'Identificador Geográfico', 'IBGE', 1, NA, NA, 'Localização', 'Identificador Geográfico')
ano= c('ano', TRUE, TRUE, FALSE, FALSE, FALSE, 'Ano da Pesquisa', 'IBGE', 1, NA, NA, 'Unidade de Tempo', 'Anual')

#silviculture

metadata_pevs_silviculture= tibble::tibble(
  var = dic_pevs_silviculture$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_pevs_silviculture$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_pevs_silviculture$unit_quantity,
  unidade_valor= dic_pevs_silviculture$unit_value,
  categoria= "Agropecuária", 
  subcategoria = "Espécies - Extrativismo Vegetal"
) %>%
  rbind(ano)%>%
  rbind(geo_id)

#forest_crops

metadata_pevs_forest_crops= tibble::tibble(
  var = dic_pevs_forest_crops$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_pevs_forest_crops$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_pevs_forest_crops$unit_quantity,
  unidade_valor= dic_pevs_forest_crops$unit_value,
  categoria= "Agropecuária", 
  subcategoria = "Espécies - Cultivo Florestal"
) %>%
  rbind(ano)%>%
  rbind(geo_id)


#silviculture_area
metadata_pevs_silviculture_area= tibble::tibble(
  var = dic_pevs_silviculture_area$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_pevs_silviculture_area$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_pevs_silviculture_area$unit_quantity,
  unidade_valor= dic_pevs_silviculture_area$unit_value,
  categoria= "Agropecuária", 
  subcategoria = "Área de Extrativismo Vegetal"
) %>%
  rbind(ano)%>%
  rbind(geo_id)

### Creating metadatabase -> IBGE - PPM

#livestock_inventory
metadata_ppm_livestock_inventory= tibble::tibble(
  var = dic_ppm_livestock_inventory$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_ppm_livestock_inventory$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_ppm_livestock_inventory$unit_quantity,
  unidade_valor= dic_ppm_livestock_inventory$unit_value,
  categoria= "Pecuária", 
  subcategoria = "Espécies - Criação"
) %>%
  rbind(ano)%>%
  rbind(geo_id)