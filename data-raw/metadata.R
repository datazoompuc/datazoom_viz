#creating and saving metadata for all the databases from the datazoom.amazonia R package

### Creating metadatabase -> IBGE - PEVS
geo_id= c('geo_id', TRUE, TRUE, FALSE, FALSE, FALSE, 'Identificador Geográfico', 'IBGE', 1, NA, NA, 'Localização', 'Identificador Geográfico')
ano= c('ano', TRUE, TRUE, FALSE, FALSE, FALSE, 'Ano da Pesquisa', 'IBGE', 1, NA, NA, 'Unidade de Tempo', 'Anual')
geo_id.= c('geo_id', TRUE, TRUE, FALSE, FALSE, FALSE, 'Identificador Geográfico', 'IBGE', 1, NA, NA, NA, 'Localização', 'Identificador Geográfico')
ano.= c('ano', TRUE, TRUE, FALSE, FALSE, FALSE, 'Ano da Pesquisa', 'IBGE', 1, NA, NA, NA, 'Unidade de Tempo', 'Anual')

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

#animal_origin_production
metadata_ppm_animal_origin_production= tibble::tibble(
  var = dic_ppm_animal_origin_production$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_ppm_animal_origin_production$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_ppm_animal_origin_production$unit_quantity,
  unidade_valor= dic_ppm_animal_origin_production$unit_value,
  categoria= "Pecuária", 
  subcategoria = "Produtos Pecuários"
) %>%
  rbind(ano)%>%
  rbind(geo_id)

#sheep_farming 
metadata_ppm_sheep_farming= tibble::tibble(
  var = dic_ppm_sheep_farming$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_ppm_sheep_farming$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_ppm_sheep_farming$unit_quantity,
  unidade_valor= dic_ppm_sheep_farming$unit_value,
  categoria= "Pecuária", 
  subcategoria = "Atividade Pecuária"
) %>%
  rbind(ano)%>%
  rbind(geo_id)

#ppm_cow_farming 
metadata_ppm_cow_farming= tibble::tibble(
  var = dic_ppm_cow_farming$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_ppm_cow_farming$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_ppm_cow_farming$unit_quantity,
  unidade_valor= dic_ppm_cow_farming$unit_value,
  categoria= "Pecuária", 
  subcategoria = "Atividade Pecuária"
) %>%
  rbind(ano)%>%
  rbind(geo_id)

#ppm_aquaculture
metadata_ppm_aquaculture= tibble::tibble(
  var = dic_ppm_aquaculture$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_ppm_aquaculture$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_ppm_aquaculture$unit_quantity,
  unidade_valor= dic_ppm_aquaculture$unit_value,
  categoria= "Pecuária", 
  subcategoria = "Espécies - Aquicultura"
) %>%
  rbind(ano)%>%
  rbind(geo_id)

### Creating metadatabase -> IBGE - PAM

#pam_all_crops
metadata_pam_all_crops= tibble::tibble(
  var = dic_pam_all_crops$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_pam_all_crops$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_pam_all_crops$unit_quantity,
  unidade_valor= dic_pam_all_crops$unit_value,
  categoria= "Agricultura", 
  subcategoria = "Espécies - Cultivo"
) %>%
  rbind(ano)%>%
  rbind(geo_id)

#pam_permanent_crops
metadata_pam_permanent_crops= tibble::tibble(
  var = dic_pam_permanent_crops$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_pam_permanent_crops$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_pam_permanent_crops$unit_quantity,
  unidade_valor= dic_pam_permanent_crops$unit_value,
  categoria= "Agricultura", 
  subcategoria = "Espécies - Cultivo "
) %>%
  rbind(ano)%>%
  rbind(geo_id)

#pam_temporary_crops
metadata_pam_temporary_crops= tibble::tibble(
  var = dic_pam_temporary_crops$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_pam_temporary_crops$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_pam_temporary_crops$unit_quantity,
  unidade_valor= dic_pam_temporary_crops$unit_value,
  categoria= "Agricultura", 
  subcategoria = "Espécies - Cultivo "
) %>%
  rbind(ano)%>%
  rbind(geo_id)

#pam_beans
metadata_pam_beans= tibble::tibble(
  var = dic_pam_beans$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_pam_beans$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_pam_beans$unit_quantity,
  unidade_valor= dic_pam_beans$unit_value,
  unidade_area= dic_pam_beans$unit_area,
  categoria= "Agricultura", 
  subcategoria = "Espécies - Cultivo "
) %>%
  rbind(ano.)%>%
  rbind(geo_id.)

#pam_corn
metadata_pam_corn= tibble::tibble(
  var = dic_pam_corn$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_pam_corn$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_pam_corn$unit_quantity,
  unidade_valor= dic_pam_corn$unit_value,
  unidade_area= dic_pam_corn$unit_area,
  categoria= "Agricultura", 
  subcategoria = "Espécies - Cultivo "
) %>%
  rbind(ano.)%>%
  rbind(geo_id.)

#pam_potato
metadata_pam_potato= tibble::tibble(
  var = dic_pam_potato$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_pam_potato$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_pam_potato$unit_quantity,
  unidade_valor= dic_pam_potato$unit_value,
  unidade_area= dic_pam_potato$unit_area,
  categoria= "Agricultura", 
  subcategoria = "Espécies - Cultivo "
) %>%
  rbind(ano.)%>%
  rbind(geo_id.)

#pam_peanut
metadata_pam_peanut= tibble::tibble(
  var = dic_pam_peanut$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_pam_peanut$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_pam_peanut$unit_quantity,
  unidade_valor= dic_pam_peanut$unit_value,
  unidade_area= dic_pam_peanut$unit_area,
  categoria= "Agricultura", 
  subcategoria = "Espécies - Cultivo "
) %>%
  rbind(ano.)%>%
  rbind(geo_id.)
