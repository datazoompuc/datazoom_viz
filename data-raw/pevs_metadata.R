### Creating metadatabase -> IBGE - PEVS

#silviculture
pevs_state_silviculture= readRDS('data\\pevs_state_silviculture.rds')

dic_pevs_silviculture= load_dictionary(dataset = 'pevs_silviculture')%>%
  arrange(var_code)

met_silviculture= NULL
met_silviculture= c(met_silviculture, rep(dic_pevs_silviculture$var_pt[1],1)) 
for(j in 11:22){
  met_silviculture= c(met_silviculture, rep(dic_pevs_silviculture$var_pt[j],2))
}
for(k in 2:10){
  met_silviculture= c(met_silviculture, rep(dic_pevs_silviculture$var_pt[k],2))
}
met_silviculture= c("Identificador Geografico", "Ano da Pesquisa",met_silviculture)
vec_silviculture= c('','', 'Valor ', rep(c('Quantidade ', 'Valor '),21))
label_silviculture= paste0(vec_silviculture,met_silviculture)

unidade_silviculture= c('','','1K BRL', rep(c('Metros Cubicos','1K BRL'),21))
for(i in c(4,6,8,28,38,40,42,44)){
  unidade_silviculture[i]= 'Toneladas'
}

silviculture_var= colnames(pevs_state_silviculture)
metadata_pevs_silviculture= tibble::tibble(
  var = silviculture_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_silviculture,
  source = "IBGE",
  tipo = 1,
  unidade = unidade_silviculture,
  categoria= c('Localizacao','Unidade de Tempo',rep("Agricultura",43)), 
  subcategoria = c('Identificador Geografico','Anual',rep("Especies - Extrativismo Vegetal",43))
)
#saving f
write.csv(metadata_pevs_silviculture, file = "./data/metadata_pevs_silviculture.csv", fileEncoding = "UTF-8")

#forest_crops
pevs_state_forest_crops= readRDS('data\\pevs_state_forest_crops.rds')

dic_pevs_forest_crops= load_dictionary(dataset = 'pevs_forest_crops')%>%
  arrange(var_code)

met_forest= NULL
met_forest= c(met_forest, rep(dic_pevs_forest_crops$var_pt[1],1)) 
for(j in c(54,51)){
  met_forest= c(met_forest, rep(dic_pevs_forest_crops$var_pt[j],2))
}
for(k in 2:50){
  met_forest= c(met_forest, rep(dic_pevs_forest_crops$var_pt[k],2))
}
for(k in 52:53){
  met_forest= c(met_forest, rep(dic_pevs_forest_crops$var_pt[k],2))
}
met_forest= c("Identificador Geografico", "Ano da Pesquisa",met_forest)
met_forest= met_forest[-95]
met_forest= met_forest[-96]
vec_forest= c('','', 'Valor ', rep(c('Quantidade ', 'Valor '),53))
vec_forest= vec_forest[-95]
vec_forest= vec_forest[-96]
label_forest= paste0(vec_forest,met_forest)

unidade_forest= c('','','1K BRL', rep(c('Toneladas','1K BRL'),52))
for(i in c(70,72,92,95)){
  unidade_forest[i]= 'Metros Cubicos'
}
unidade_forest[94]= 'Mil Arvores'


forest_var= colnames(pevs_state_forest_crops)
metadata_pevs_forest_crops= tibble::tibble(
  var = forest_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_forest,
  source = "IBGE",
  tipo = 1,
  unidade = unidade_forest,
  categoria= c('Localizacao','Unidade de Tempo',rep("Agricultura",105)), 
  subcategoria = c('Identificador Geografico','Anual',rep("Especies - Cultivo Florestal",105))
)
#saving f
write.csv(metadata_pevs_forest_crops, file = "./data/metadata_pevs_forest_crops.csv", fileEncoding = "UTF-8")


#silviculture_area
pevs_state_silviculture_area= readRDS('data\\pevs_state_silviculture_area.rds')


dic_pevs_silviculture_area= load_dictionary(dataset = 'pevs_silviculture_area')

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
  categoria= "Agropecu???ria", 
  subcategoria = "???rea de Extrativismo Vegetal"
) %>%
  rbind(ano)%>%
  rbind(geo_id)
#saving
write.csv(metadata_pevs_silviculture_area, file = "./data/metadata_pevs_silviculture_area.csv", fileEncoding = "UTF-8")
