#downloading and saving databases using datazoom packages

devtools::install_github(datazoompuc/datazoomamazonia)

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
##saving f
saveRDS(ppm_state_aquaculture,
        file = "./data/ppm_state_aquaculture.rds"
)

### Generate data -> IBGE - PEVS

  #silviculture  

##state
pevs_state_silviculture= load_pevs(dataset = 'pevs_silviculture', raw_data = FALSE, 'state', 1986:2019, language = "pt")
##municipality (ainda nao salvo)
pevs_municipality_silviculture= load_pevs(dataset = 'pevs_silviculture', raw_data = FALSE, 'municipality', 1986:2019, language = "pt")
##dictionary
dic_pevs_silviculture= load_dictionary(dataset = 'pevs_silviculture')
##saving
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
##saving
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
##saving
saveRDS(pevs_state_silviculture_area,
        file = "./data/pevs_state_silviculture_area.rds"
)




### Generate data -> IBGE - PAM

  #all_crops

##state
pam_state_all_crops= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality (ainda nao salvo)
pam_municipality_all_crops= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_pam_all_crops= load_dictionary(dataset= 'pam_all_crops')
#making data usable for datazoom viz f
pam_state_all_crops[is.na(pam_state_all_crops)] = 0
  pam_state_all_crops= dplyr::rename(pam_state_all_crops, time=.data$ano)%>%
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

##saving f
saveRDS(pam_state_all_crops,
          file = "./data/pam_state_all_crops.rds"
  )
  
  #permanent_crops

##state
pam_state_permanent_crops= load_pam(dataset = 'pam_permanent_crops', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality (ainda nao salvo)
pam_municipality_permanent_crops= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
ret= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'municipality', 1974:1983, language = "pt")
ret2= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'municipality', 1984:1993, language = "pt")
ret3= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'municipality', 1994:2003, language = "pt")
ret4= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'municipality', 2004:2019, language = "pt")

ret3= data.frame()
for(i in 1986:1988){
  data= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'municipality', i, language = "pt")
  ret3= bind_rows(ret3,data)
}
ret4= data.frame()
for(j in 1998:2009){
  data= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'municipality', j, language = "pt")
  ret4= bind_rows(ret4,data)
}
ret5= data.frame()
for(h in 2010:2019){
  data= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'municipality', h, language = "pt")
  ret5= bind_rows(ret5,data)
}
##dictionary
dic_pam_permanent_crops= load_dictionary(dataset= 'pam_permanent_crops')
#making data usable for datazoom viz
pam_state_permanent_crops = lapply(pam_state_permanent_crops, as.numeric)
pam_state_permanent_crops <- as.data.frame(pam_state_permanent_crops)
pam_state_permanent_crops[is.na(pam_state_permanent_crops)] <- 0
pam_state_permanent_crops=pam_state_permanent_crops%>%
dplyr::rename(time=.data$ano)%>%
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
##saving f
saveRDS(pam_state_permanent_crops,
        file = "./data/pam_state_permanent_crops.rds"
)

  #temporary_crops

##state
pam_state_temporary_crops= load_pam(dataset = 'pam_temporary_crops', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality (ainda nao salvo)
pam_municipality_temporary_crops= load_pam(dataset = 'pam_temporary_crops', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_pam_temporary_crops= load_dictionary(dataset= 'pam_temporary_crops')
##making data usable for datazoom viz
pam_state_temporary_crops = lapply(pam_state_temporary_crops, as.numeric)
pam_state_temporary_crops <- as.data.frame(pam_state_temporary_crops)
pam_state_temporary_crops[is.na(pam_state_temporary_crops)] <- 0
pam_state_temporary_crops=pam_state_temporary_crops%>%
  dplyr::rename(time=.data$ano)%>%
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

pam_state_temporary_crops[is.na(pam_state_temporary_crops)] = 0
##saving f
saveRDS(pam_state_temporary_crops,
        file = "./data/pam_state_temporary_crops.rds"
)

  #pam_xx (xx= corn, potato, peanut, beans)

##state
pam_state_corn= load_pam(dataset = 'pam_corn', raw_data = FALSE, 'state', 2003:2019, language = "pt")
pam_state_potato= load_pam(dataset = 'pam_potato', raw_data = FALSE, 'state', 2003:2019, language = "pt")
pam_state_peanut= load_pam(dataset = 'pam_peanut', raw_data = FALSE, 'state', 2003:2019, language = "pt")
pam_state_beans= load_pam(dataset = 'pam_beans', raw_data = FALSE, 'state', 2003:2019, language = "pt")

##municipality (ainda nao salvo)
pam_municipality_corn= load_pam(dataset = 'pam_corn', raw_data = FALSE, 'municipality', 2003:2019, language = "pt")
pam_municipality_potato= load_pam(dataset = 'pam_potato', raw_data = FALSE, 'municipality', 2003:2019, language = "pt")
pam_municipality_peanut= load_pam(dataset = 'pam_peanut', raw_data = FALSE, 'municipality', 2003:2019, language = "pt")
pam_municipality_beans= load_pam(dataset = 'pam_beans', raw_data = FALSE, 'municipality', 2003:2019, language = "pt")

##dictionary
dic_pam_corn= load_dictionary(dataset= 'pam_corn')
dic_pam_potato= load_dictionary(dataset= 'pam_potato')
dic_pam_peanut= load_dictionary(dataset= 'pam_peanut')
dic_pam_beans= load_dictionary(dataset= 'pam_beans')

##making data usable for datazoom viz
pam_state_corn = lapply(pam_state_corn, as.numeric)
pam_state_corn <- as.data.frame(pam_state_corn)
pam_state_corn[is.na(pam_state_corn)] <- 0
pam_state_corn= pam_state_corn%>%
dplyr::rename(time=.data$ano)%>%
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


pam_state_potato = lapply(pam_state_potato, as.numeric)
pam_state_potato <- as.data.frame(pam_state_potato)
pam_state_potato[is.na(pam_state_potato)] <- 0
pam_state_potato= pam_state_potato%>%
dplyr::rename(time=.data$ano)%>%
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

pam_state_peanut = lapply(pam_state_peanut, as.numeric)
pam_state_peanut <- as.data.frame(pam_state_peanut)
pam_state_peanut[is.na(pam_state_peanut)] <- 0
pam_state_peanut= pam_state_peanut%>%
dplyr::rename(time=.data$ano)%>%
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

pam_state_beans = lapply(pam_state_beans, as.numeric)
pam_state_beans <- as.data.frame(pam_state_beans)
pam_state_beans[is.na(pam_state_beans)] <- 0
pam_state_beans= pam_state_beans%>%
dplyr::rename(time=.data$ano)%>%
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

##saving f
saveRDS(pam_state_corn,
        file = "./data/pam_state_corn.rds"
)
saveRDS(pam_state_potato,
        file = "./data/pam_state_potato.rds"
)
saveRDS(pam_state_peanut,
        file = "./data/pam_state_peanut.rds"
)
saveRDS(pam_state_beans,
        file = "./data/pam_state_beans.rds"
)

### Generate data -> SEEG
seeg_municipality= load_seeg(dataset = "seeg", raw_data = TRUE,geo_level = "municipality",language = "pt")
seeg_state= load_seeg(dataset = "seeg", raw_data = TRUE,geo_level = "state",language = "pt")
saveRDS(seeg_municipality,
        file = "./data/seeg_municipality.rds"
)
saveRDS(seeg_state,
        file = "./data/seeg_state.rds"
)

### Generate data -> CEMPRE - IBGE
cempre_municipality <- load_cempre(dataset = "cempre", raw_data = TRUE, time_period = 2006:2019)
cempre_state <- load_cempre(dataset = "cempre", geo_level = 'state', raw_data = TRUE, time_period = 2019)
saveRDS(cempre_municipality,
        file = "./data/cempre_municipality.rds"
)
saveRDS(cempre_state,
        file = "./data/cempre_state.rds"
)

### Generate data -> MAPBIOMAS 
 
  #cover
mapbiomas_cover_0= load_mapbiomas(dataset = "mapbiomas_cover" ,raw_data=FALSE,geo_level = 'state',time_period='all',language = 'pt',time_id = 'year',cover_level = 0)
mapbiomas_cover_1= load_mapbiomas(dataset = "mapbiomas_cover" ,raw_data=FALSE,geo_level = 'state',time_period='all',language = 'pt',time_id = 'year',cover_level = 1)
mapbiomas_cover_2= load_mapbiomas(dataset = "mapbiomas_cover" ,raw_data=FALSE,geo_level = 'state',time_period='all',language = 'pt',time_id = 'year',cover_level = 2)
mapbiomas_cover_3= load_mapbiomas(dataset = "mapbiomas_cover" ,raw_data=FALSE,geo_level = 'state',time_period='all',language = 'pt',time_id = 'year',cover_level = 3)
mapbiomas_cover_4= load_mapbiomas(dataset = "mapbiomas_cover" ,raw_data=FALSE,geo_level = 'state',time_period='all',language = 'pt',time_id = 'year',cover_level = 4)
#saving
saveRDS(mapbiomas_cover_0,
        file = "./data/mapbiomas_cover_0.rds"
)
saveRDS(mapbiomas_cover_1,
        file = "./data/mapbiomas_cover_1.rds"
)
saveRDS(mapbiomas_cover_2,
        file = "./data/mapbiomas_cover_2.rds"
)
saveRDS(mapbiomas_cover_3,
        file = "./data/mapbiomas_cover_3.rds"
)
saveRDS(mapbiomas_cover_4,
        file = "./data/mapbiomas_cover_4.rds"
)

  #transition
mapbiomas_transition= load_mapbiomas(dataset = "mapbiomas_transition" ,raw_data=FALSE,geo_level = 'state',time_period='all',language = 'pt',time_id = 'year',cover_level = 0)
#saving
saveRDS(mapbiomas_transition,
        file = "./data/mapbiomas_transition.rds"
)

  #deforestation_regeneration
mapbiomas_deforestation_regeneration= load_mapbiomas(dataset = "mapbiomas_deforestation_regeneration" ,raw_data=FALSE,geo_level = 'state',time_period='all',language = 'pt',time_id = 'year',cover_level = 0)
#saving
saveRDS(mapbiomas_deforestation_regeneration,
        file = "./data/mapbiomas_deforestation_regeneration.rds"
)
  #irrigation
mapbiomas_irrigation= load_mapbiomas(dataset = "mapbiomas_irrigation" ,raw_data=FALSE,geo_level = 'state',time_period='all',language = 'pt',time_id = 'year',cover_level = 0)
#saving
saveRDS(mapbiomas_irrigation,
        file = "./data/mapbiomas_irrigation.rds"
)
  #grazing_quality
mapbiomas_grazing_quality= load_mapbiomas(dataset = "mapbiomas_grazing_quality" ,raw_data=FALSE,geo_level = 'state',time_period='all',language = 'pt',time_id = 'year',cover_level = 0)
#saving
saveRDS(mapbiomas_grazing_quality,
        file = "./data/mapbiomas_grazing_quality.rds"
)

