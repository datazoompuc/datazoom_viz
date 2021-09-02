### Generate data -> IBGE - PEVS

#silviculture  

##state
pevs_state_silviculture= load_pevs(dataset = 'pevs_silviculture', raw_data = FALSE, 'state', 1986:2019, language = "pt")
##municipality (ainda nao salvo)
pevs_municipality_silviculture= load_pevs(dataset = 'pevs_silviculture', raw_data = FALSE, 'municipality', 1986:2019, language = "pt")
##dictionary
dic_pevs_silviculture= load_dictionary(dataset = 'pevs_silviculture')

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
##municipality (ainda nao salvo)
pevs_municipality_forest_crops= load_pevs(dataset = 'pevs_forest_crops', raw_data = FALSE, 'municipality', 1986:2019, language = "pt")
##dictionary
dic_pevs_forest_crops= load_dictionary(dataset = 'pevs_forest_crops')
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
##municipality (ainda nao salvo)
pevs_municipality_silviculture_area= load_pevs(dataset = 'pevs_silviculture_area', raw_data = FALSE, 'municipality', 1986:2019, language = "pt")
##dictionary
dic_pevs_silviculture_area= load_dictionary(dataset = 'pevs_silviculture_area')
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

