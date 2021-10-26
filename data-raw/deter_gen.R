##########
### Generate data -> INPE - DETER
##########

#amazonia
deter_amz= load_deter(dataset = 'deter_amz', raw_data = FALSE, language = 'pt')
##making data usable for datazoom viz
munics= readxl::read_xls("data\\RELATORIO_DTB_BRASIL_MUNICIPIO.xls")%>%
  dplyr::select('Código Município Completo', 'Nome_Município')
deter_amz$cod_municipio= plyr::mapvalues(deter_amz$cod_municipio, from = munics$`Código Município Completo`, to = munics$Nome_Município)
deter_amz= dplyr::rename(deter_amz, municipio= .data$cod_municipio, uf= .data$cod_uf)%>%
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
saveRDS(deter_amz,
        file = "./data/deter_amazonia.rds"
)

#cerrado
deter_cerrado= load_deter(dataset = 'deter_cerrado', raw_data = FALSE, language = 'pt')
##making data usable for datazoom viz
munics= readxl::read_xls("data\\RELATORIO_DTB_BRASIL_MUNICIPIO.xls")%>%
  dplyr::select('Código Município Completo', 'Nome_Município')
deter_cerrado$cod_municipio= plyr::mapvalues(deter_cerrado$cod_municipio, from = munics$`Código Município Completo`, to = munics$Nome_Município)
deter_cerrado= dplyr::rename(deter_cerrado, municipio= .data$cod_municipio, uf= .data$cod_uf)%>%
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
saveRDS(deter_cerrado,
        file = "./data/deter_cerrado.rds"
)

#########
### Creating metadatabase -> INPE - DETER
#########

#amazonia
deter_amz= readRDS('/data/deter_amazonia.rds')
var_amz= colnames(deter_amz)
label_amz= c('Data')
metadata_deter_amz= tibble::tibble(
  var = var_amz,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = ,
  source = "INPE",
  tipo = 1,
  unidade = ,
  categoria= c('Unidade de Tempo', 'Localizaçao', 'Localizaçao',), 
  subcategoria = c('Data da Pesquisa', 'Identificador Geografico', 'Identificador Geografico',)
) 
#saving

#cerrado
deter_cerrado= readRDS('/data/deter_cerrado.rds')
var_cerrado= colnames(deter_cerrado)
#saving