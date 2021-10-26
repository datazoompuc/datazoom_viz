##########
### Generate data -> INPE - DEGRAD
##########

#degrad
degrad= load_degrad(dataset = 'degrad', raw_data = FALSE, time_period = 2007:2016, language = 'pt')

##making data usable for datazoom viz
munics= readxl::read_xls("data\\RELATORIO_DTB_BRASIL_MUNICIPIO.xls")%>%
  dplyr::select('Código Município Completo', 'Nome_Município')
degrad$cod_municipio= plyr::mapvalues(degrad$cod_municipio, from = munics$`Código Município Completo`, to = munics$Nome_Município)
degrad= dplyr::rename(degrad, municipio= .data$cod_municipio, uf= .data$cod_uf)%>%
  dplyr::mutate(uf = dplyr::case_when(.data$uf == '12' ~ 'AC',
                                      .data$uf == '27' ~ 'AL',
                                      .data$uf == '16' ~ 'AP',
                                      .data$uf == '13' ~ 'AM',
                                      .data$uf == '29' ~ 'BA',
                                      .data$uf == '23' ~ 'CE',
                                      .data$uf == '53' ~ 'DF',
                                      .data$uf == '32' ~ 'ES',
                                      .data$uf == '52' ~ 'GO',
                                      .data$uf == '21' ~ 'MA',
                                      .data$uf == '51' ~ 'MT',
                                      .data$uf == '50' ~ 'MS',
                                      .data$uf == '31' ~ 'MG',
                                      .data$uf == '15' ~ 'PA',
                                      .data$uf == '25' ~ 'PB',
                                      .data$uf == '41' ~ 'PR',
                                      .data$uf == '26' ~ 'PE',
                                      .data$uf == '22' ~ 'PI',
                                      .data$uf == '24' ~ 'RN',
                                      .data$uf == '43' ~ 'RS',
                                      .data$uf == '33' ~ 'RJ',
                                      .data$uf == '11' ~ 'RO',
                                      .data$uf == '14' ~ 'RR',
                                      .data$uf == '42' ~ 'SC',
                                      .data$uf == '35' ~ 'SP',
                                      .data$uf == '28' ~ 'SE',
                                      .data$uf == '17' ~ 'TO'))


#saving f
saveRDS(degrad,
        file = "./data/degrad.rds"
)

#########
### Creating metadatabase -> INPE - DEGRAD
#########

#degrad

#saving