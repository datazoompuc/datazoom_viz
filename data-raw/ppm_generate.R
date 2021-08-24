### Generate data -> IBGE - PPM

#livestock_inventory

##state
ppm_state_livestock_inventory= load_ppm(dataset = 'ppm_livestock_inventory', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality (ainda nao salvo)
ppm_municipality_livestock_inventory= load_ppm(dataset = 'ppm_livestock_inventory', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_livestock_inventory= load_dictionary(dataset = 'ppm_livestock_inventory')
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
##municipality (ainda nao salvo)
ppm_municipality_sheep_farming= load_ppm(dataset = 'ppm_sheep_farming', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_sheep_farming= load_dictionary(dataset = 'ppm_sheep_farming')
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
##municipality (ainda nao salvo)
ppm_municipality_animal_orig_production= load_ppm(dataset = 'ppm_animal_origin_production', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_animal_origin_production= load_dictionary(dataset = 'ppm_animal_origin_production')
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
##municipality (ainda nao salvo)
ppm_municipality_cow_farming= load_ppm(dataset = 'ppm_cow_farming', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_cow_farming= load_dictionary(dataset = 'ppm_cow_farming')
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
##municipality (ainda nao salvo)
ppm_municipality_aquaculture= load_ppm(dataset = 'ppm_aquaculture', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_aquaculture= load_dictionary(dataset = 'ppm_aquaculture')
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
