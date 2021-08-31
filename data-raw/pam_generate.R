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

