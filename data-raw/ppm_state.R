##########
### Generate data -> IBGE - PPM
##########
## Agregation level - STATE

#livestock_inventory

##state
ppm_state_livestock_inventory= load_ppm(dataset = 'ppm_livestock_inventory', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##making data usable for datazoom viz
ppm_state_livestock_inventory= dplyr::rename(ppm_state_livestock_inventory, time=.data$ano)%>%
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
ppm_state_livestock_inventory[is.na(ppm_state_livestock_inventory)] = 0

##saving
saveRDS(ppm_state_livestock_inventory,
        file = "./data/ppm_state_livestock_inventory.rds"
) #f
saveRDS(ppm_municipality_livestock_inventory,
        file = "./data/ppm_municipality_livestock_inventory.rds"
)

#sheep_farming 

##state
ppm_state_sheep_farming= load_ppm(dataset = 'ppm_sheep_farming', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##making data usable for datazoom viz
ppm_state_sheep_farming= dplyr::rename(ppm_state_sheep_farming, time=.data$ano)%>%
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
ppm_state_sheep_farming[is.na(ppm_state_sheep_farming)] = 0
##saving f
saveRDS(ppm_state_sheep_farming,
        file = "./data/ppm_state_sheep_farming.rds"
)

#animal_origin_production 

##state
ppm_state_animal_origin_production= load_ppm(dataset = 'ppm_animal_origin_production', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##making data usable for datazoom viz
ppm_state_animal_origin_production= dplyr::rename(ppm_state_animal_origin_production, time=.data$ano)%>%
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
ppm_state_animal_origin_production[is.na(ppm_state_animal_origin_production)] = 0

##saving f
saveRDS(ppm_state_animal_origin_production,
        file = "./data/ppm_state_animal_origin_production.rds"
)

#ppm_cow_farming 

##state
ppm_state_cow_farming= load_ppm(dataset = 'ppm_cow_farming', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##making data usable for datazoom viz
ppm_state_cow_farming = dplyr::rename(ppm_state_cow_farming , time=.data$ano)%>%
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
ppm_state_cow_farming[is.na(ppm_state_cow_farming )] = 0
##saving f
saveRDS(ppm_state_cow_farming,
        file = "./data/ppm_state_cow_farming.rds"
)

#ppm_aquaculture

##state
ppm_state_aquaculture= load_ppm(dataset = 'ppm_aquaculture', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##making data usable for datazoom viz
ppm_state_aquaculture = dplyr::rename(ppm_state_aquaculture , time=.data$ano)%>%
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
ppm_state_aquaculture[is.na(ppm_state_aquaculture)] = 0
ppm_state_aquaculture= ppm_state_aquaculture[,order(colnames(ppm_state_aquaculture))]
ppm_state_aquaculture <- ppm_state_aquaculture %>%
  dplyr::select(time, everything())
ppm_state_aquaculture <- ppm_state_aquaculture %>%
  dplyr::select(group, everything())
##saving f
saveRDS(ppm_state_aquaculture,
        file = "./data/ppm_state_aquaculture.rds"
)

#########
### Creating metadatabase -> IBGE - PPM
#########

#livestock_inventory
ppm_state_livestock_inventory= readRDS('data/ppm_state_livestock_inventory.rds')

dic_ppm_livestock_inventory= load_dictionary(dataset = 'ppm_livestock_inventory')
aux= c('','', rep('Efetivo dos Rebanhos ',10))
livestock_var= colnames(ppm_state_livestock_inventory)
label_livestock= paste0(aux,c("Identificador Geografico", "Ano da Pesquisa", dic_ppm_livestock_inventory$var_pt[1:10]))
metadata_ppm_livestock_inventory= tibble::tibble(
  var = livestock_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_livestock,
  source = "IBGE",
  tipo = 1,
  unidade = c(NA, NA, rep('Cabecas',10)),
  categoria= c("Localizacao","Unidade de Tempo",rep("Pecuaria",10)), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',rep("Especies - Criacao",10))
) 
#saving f
write.csv(metadata_ppm_livestock_inventory, file = "./data/ppm_state_livestock_inventory_dic.csv", fileEncoding = "UTF-8")


#animal_origin_production
ppm_state_animal_origin_production= readRDS('data/ppm_state_animal_origin_production.rds')


dic_ppm_animal_origin_production= load_dictionary(dataset = 'ppm_animal_origin_production')%>%
  arrange(var_code)
animal_var= colnames(ppm_state_animal_origin_production)
vec= NULL
for(i in 2:7){
  vec= c(vec, rep(dic_ppm_animal_origin_production$var_pt[i],2))
} 
vec= c('','','',vec)
aux= c("Identificador Geografico", "Ano da Pesquisa", 'Valor Total', rep(c('Quantidade ', 'Valor '),6))
label_animal= paste0(aux,vec)
metadata_ppm_animal_origin_production= tibble::tibble(
  var = animal_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_animal,
  source = "IBGE",
  tipo = 1,
  unidade = c(NA, NA, '1K BRL', '1K Liters', '1K BRL', 'Kg', '1K BRL', 'Kg', '1K BRL', '1K Dozens', '1K BRL', '1K Dozens', '1K BRL', 'Kg', '1K BRL'),
  categoria= c("Localizaçao","Unidade de Tempo",rep("Pecuaria",13)), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',rep("Produtos Pecuarios",13))
)
#saving f
write.csv(metadata_ppm_animal_origin_production, file = "./data/ppm_state_animal_origin_production_dic.csv", fileEncoding = "UTF-8")


#sheep_farming 
ppm_state_sheep_farming= readRDS('data/ppm_state_sheep_farming.rds')

dic_ppm_sheep_farming= load_dictionary(dataset = 'ppm_sheep_farming')
sheep_var= colnames(ppm_state_sheep_farming)
metadata_ppm_sheep_farming= tibble::tibble(
  var = sheep_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = c("Identificador Geografico", "Ano da Pesquisa",'Ovinos Tosquiados nos Estabelecimentos Agropecuarios'),
  source = "IBGE",
  tipo = 1,
  unidade = c(NA, NA, 'Cabecas'),
  categoria= c("Localizaçao","Unidade de Tempo","Pecuaria"), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',"Atividade Pecuaria")
) 
#saving f
write.csv(metadata_ppm_sheep_farming, file = "./data/ppm_state_sheep_farming_dic.csv", fileEncoding = "UTF-8")


#ppm_cow_farming 
ppm_state_cow_farming= readRDS('data/ppm_state_cow_farming.rds')


dic_ppm_cow_farming= load_dictionary(dataset = 'ppm_cow_farming')
cow_var= colnames(ppm_state_cow_farming)
metadata_ppm_cow_farming= tibble::tibble(
  var = cow_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = c("Identificador Geografico", "Ano da Pesquisa",'Vacas Ordenhadas'),
  source = "IBGE",
  tipo = 1,
  unidade = c(NA, NA, 'Cabecas'),
  categoria= c("Localizaçao","Unidade de Tempo","Pecuaria"), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',"Atividade Pecuaria")
) 

#saving f
write.csv(metadata_ppm_cow_farming, file = "./data/ppm_state_cow_farming_dic.csv", fileEncoding = "UTF-8")


#ppm_aquaculture
ppm_state_aquaculture= readRDS('data/ppm_state_aquaculture.rds')

dic_ppm_aquaculture= load_dictionary(dataset = 'ppm_aquaculture')%>%
  dplyr::arrange(var_pt)
vec= NULL
for(i in 1:25){
  vec= c(vec, rep(dic_ppm_aquaculture$var_pt[i],2))
}
vec= c('','',vec)
aux= c("Identificador Geografico", "Ano da Pesquisa",rep(c('Producao da Aquicultura ', 'Valor da Producao '),25))
label_aqua= paste0(aux,vec)
label_aqua= label_aqua[-25]
aqua_var= colnames(ppm_state_aquaculture)
label_aqua= label_aqua[-44]

unidade_aqua= c('','',rep(c('Kg','1K BRL'),25))
unidade_aqua= unidade_aqua[-25]
unidade_aqua= unidade_aqua[-44]
unidade_aqua[17]= '1K'
unidade_aqua[36]= '1K'

metadata_ppm_aquaculture= tibble::tibble(
  var = aqua_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_aqua,
  source = "IBGE",
  tipo = 1,
  unidade = unidade_aqua,
  categoria= c("Localizaçao","Unidade de Tempo" ,rep("Pecuaria",48)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa" ,rep("Especies - Aquicultura",48))
)
#saving f
write.csv(metadata_ppm_aquaculture, file = "./data/ppm_state_aquaculture_dic.csv", fileEncoding = "UTF-8")