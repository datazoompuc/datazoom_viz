##########
### Generate data -> IBGE - PEVS
##########
## Agregation level - STATE

#silviculture  

##state
pevs_state_silviculture= load_pevs(dataset = 'pevs_silviculture', raw_data = FALSE, 'state', 1986:2019, language = "pt")
##making data usable for datazoom viz
pevs_state_silviculture = dplyr::rename(pevs_state_silviculture , time=.data$ano)%>%
  dplyr::mutate(group = dplyr::case_when(.data$geo_id == '12' ~ 'AC',
                                         .data$geo_id == '27' ~ 'AL',
                                         .data$geo_id == '16' ~ 'AP',
                                         .data$geo_id == '13' ~ 'AM',
                                         .data$geo_id == '29' ~ 'BA',
                                         .data$geo_id == '23' ~ 'CE',
                                         .data$geo_id == '53' ~ 'DF',
                                         .data$geo_id == '32' ~ 'ES',
                                         .data$geo_id == '52' ~ 'GO',
                                         .data$geo_id == '21' ~ 'MA',
                                         .data$geo_id == '51' ~ 'MT',
                                         .data$geo_id == '50' ~ 'MS',
                                         .data$geo_id == '31' ~ 'MG',
                                         .data$geo_id == '15' ~ 'PA',
                                         .data$geo_id == '25' ~ 'PB',
                                         .data$geo_id == '41' ~ 'PR',
                                         .data$geo_id == '26' ~ 'PE',
                                         .data$geo_id == '22' ~ 'PI',
                                         .data$geo_id == '24' ~ 'RN',
                                         .data$geo_id == '43' ~ 'RS',
                                         .data$geo_id == '33' ~ 'RJ',
                                         .data$geo_id == '11' ~ 'RO',
                                         .data$geo_id == '14' ~ 'RR',
                                         .data$geo_id == '42' ~ 'SC',
                                         .data$geo_id == '35' ~ 'SP',
                                         .data$geo_id == '28' ~ 'SE',
                                         .data$geo_id == '17' ~ 'TO'), .keep="unused", .before= time)
pevs_state_silviculture[is.na(pevs_state_silviculture)] = 0
##saving f
saveRDS(pevs_state_silviculture,
        file = "./data/pevs_state_silviculture.rds"
)


#forest_crops

##state
pevs_state_forest_crops= load_pevs(dataset = 'pevs_forest_crops', raw_data = FALSE, 'state', 1986:2019, language = "pt")
##making data usable for datazoom viz
pevs_state_forest_crops = dplyr::rename(pevs_state_forest_crops , time=.data$ano)%>%
  dplyr::mutate(group = dplyr::case_when(.data$geo_id == '12' ~ 'AC',
                                         .data$geo_id == '27' ~ 'AL',
                                         .data$geo_id == '16' ~ 'AP',
                                         .data$geo_id == '13' ~ 'AM',
                                         .data$geo_id == '29' ~ 'BA',
                                         .data$geo_id == '23' ~ 'CE',
                                         .data$geo_id == '53' ~ 'DF',
                                         .data$geo_id == '32' ~ 'ES',
                                         .data$geo_id == '52' ~ 'GO',
                                         .data$geo_id == '21' ~ 'MA',
                                         .data$geo_id == '51' ~ 'MT',
                                         .data$geo_id == '50' ~ 'MS',
                                         .data$geo_id == '31' ~ 'MG',
                                         .data$geo_id == '15' ~ 'PA',
                                         .data$geo_id == '25' ~ 'PB',
                                         .data$geo_id == '41' ~ 'PR',
                                         .data$geo_id == '26' ~ 'PE',
                                         .data$geo_id == '22' ~ 'PI',
                                         .data$geo_id == '24' ~ 'RN',
                                         .data$geo_id == '43' ~ 'RS',
                                         .data$geo_id == '33' ~ 'RJ',
                                         .data$geo_id == '11' ~ 'RO',
                                         .data$geo_id == '14' ~ 'RR',
                                         .data$geo_id == '42' ~ 'SC',
                                         .data$geo_id == '35' ~ 'SP',
                                         .data$geo_id == '28' ~ 'SE',
                                         .data$geo_id == '17' ~ 'TO'), .keep="unused", .before= time)
pevs_state_forest_crops[is.na(pevs_state_forest_crops)] = 0

##saving f
saveRDS(pevs_state_forest_crops,
        file = "./data/pevs_state_forest_crops.rds"
)

#silviculture_area

##state
pevs_state_silviculture_area= load_pevs(dataset = 'pevs_silviculture_area', raw_data = FALSE, 'state', 1986:2019, language = "pt")
##making data usable for datazoom viz
pevs_state_silviculture_area = dplyr::rename(pevs_state_silviculture_area , time=.data$ano)%>%
  dplyr::mutate(group = dplyr::case_when(.data$geo_id == '12' ~ 'AC',
                                         .data$geo_id == '27' ~ 'AL',
                                         .data$geo_id == '16' ~ 'AP',
                                         .data$geo_id == '13' ~ 'AM',
                                         .data$geo_id == '29' ~ 'BA',
                                         .data$geo_id == '23' ~ 'CE',
                                         .data$geo_id == '53' ~ 'DF',
                                         .data$geo_id == '32' ~ 'ES',
                                         .data$geo_id == '52' ~ 'GO',
                                         .data$geo_id == '21' ~ 'MA',
                                         .data$geo_id == '51' ~ 'MT',
                                         .data$geo_id == '50' ~ 'MS',
                                         .data$geo_id == '31' ~ 'MG',
                                         .data$geo_id == '15' ~ 'PA',
                                         .data$geo_id == '25' ~ 'PB',
                                         .data$geo_id == '41' ~ 'PR',
                                         .data$geo_id == '26' ~ 'PE',
                                         .data$geo_id == '22' ~ 'PI',
                                         .data$geo_id == '24' ~ 'RN',
                                         .data$geo_id == '43' ~ 'RS',
                                         .data$geo_id == '33' ~ 'RJ',
                                         .data$geo_id == '11' ~ 'RO',
                                         .data$geo_id == '14' ~ 'RR',
                                         .data$geo_id == '42' ~ 'SC',
                                         .data$geo_id == '35' ~ 'SP',
                                         .data$geo_id == '28' ~ 'SE',
                                         .data$geo_id == '17' ~ 'TO'), .keep="unused", .before= time)
pevs_state_silviculture_area[is.na(pevs_state_silviculture_area)] = 0
##saving f
saveRDS(pevs_state_silviculture_area,
        file = "./data/pevs_state_silviculture_area.rds"
)

### aggregating all datasets
pevs_state= pevs_state_silviculture%>%
  dplyr::left_join(pevs_state_forest_crops, by= c('group','time'))%>%
  dplyr::left_join(pevs_state_silviculture_area, by= c('group','time'))
##saving f
saveRDS(pevs_state,
        file = "./data/pevs_state.rds"
)


#########
### Creating metadatabase -> IBGE - PEVS
#########

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
write.csv(metadata_pevs_silviculture, file = "./data/pevs_state_silviculture_dic.csv", fileEncoding = "UTF-8")

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
write.csv(metadata_pevs_forest_crops, file = "./data/pevs_state_forest_crops_dic.csv", fileEncoding = "UTF-8")


#silviculture_area
pevs_state_silviculture_area= readRDS('data\\pevs_state_silviculture_area.rds')


dic_pevs_silviculture_area= load_dictionary(dataset = 'pevs_silviculture_area')%>%
  arrange(var_code)

silviculture_area_var= colnames(pevs_state_silviculture_area)
label_silviculture_area= dic_pevs_silviculture_area$var_pt 
label_silviculture_area= c("Identificador Geografico", "Ano da Pesquisa",label_silviculture_area)

metadata_pevs_silviculture_area= tibble::tibble(
  var = silviculture_area_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_silviculture_area,
  source = "IBGE",
  tipo = 1,
  unidade = c('','', rep('Hectares',4)),
  categoria= c('Localizacao','Unidade de Tempo',rep("Agricultura",4)), 
  subcategoria =  c('Identificador Geografico','Anual',rep("Area de Extrativismo Vegetal",4))
) 
#saving f
write.csv(metadata_pevs_silviculture_area, file = "./data/pevs_state_silviculture_area_dic.csv", fileEncoding = "UTF-8")

###aggregating all metadatas
metadata_pevs_forest_crops= metadata_pevs_forest_crops[-1,]
metadata_pevs_forest_crops= metadata_pevs_forest_crops[-1,]

metadata_pevs_silviculture_area= metadata_pevs_silviculture_area[-1,]
metadata_pevs_silviculture_area= metadata_pevs_silviculture_area[-1,]

metadata_pevs= metadata_pevs_silviculture%>%
  dplyr::bind_rows(metadata_pevs_forest_crops)%>%
  dplyr::bind_rows(metadata_pevs_silviculture_area)
#saving f
write.csv(metadata_pevs, file = "./data/pevs_state_dic.csv", fileEncoding = "UTF-8")
