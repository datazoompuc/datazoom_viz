##########
### Generate data -> SEEG 
##########
## Agregation level - MUNICIPALITY

#seeg_farming

seeg_municipality_farming= load_seeg(dataset = 'seeg_farming', geo_level = 'municipality', raw_data = FALSE, language = 'pt')
seeg_municipality_farming= seeg_municipality_farming%>%
  dplyr::rename(time= .data$Ano, group= .data$municipio)%>%
  dplyr::select(-territorio,-ibge)
##saving f
saveRDS(seeg_municipality_farming,
        'data/seeg_municipality_farming.rds'
)

#seeg_industry
seeg_municipality_industry= load_seeg(dataset = "seeg_industry", geo_level = 'municipality', raw_data = FALSE, language = 'pt')
seeg_municipality_industry= seeg_municipality_industry%>%
  dplyr::rename(time= .data$Ano, group= .data$estado)

##saving
saveRDS(seeg_municipality_industry,
        'data/seeg_municipality_industry.rds'
)

#seeg_energy
seeg_municipality_energy= load_seeg(dataset = "seeg_energy", geo_level = 'municipality', raw_data = FALSE, language = 'pt')
seeg_municipality_energy= seeg_municipality_energy%>%
  dplyr::rename(time= .data$Ano, group= .data$municipio)%>%
  dplyr::select(-territorio,-ibge)

##saving f
saveRDS(seeg_municipality_energy,
        'data/seeg_municipality_energy.rds'
)

#seeg_land
seeg_municipality_land= load_seeg(dataset = "seeg_land", geo_level = 'municipality', raw_data = FALSE, language = 'pt')
seeg_municipality_land= seeg_municipality_land%>%
  dplyr::rename(time= .data$Ano, group= .data$municipio)%>%
  dplyr::select(-territorio,-ibge)

##saving f
saveRDS(seeg_municipality_land,
        'data/seeg_municipality_land.rds'
)

#seeg_residuals
seeg_municipality_residuals= load_seeg(dataset = "seeg_residuals", geo_level = 'municipality', raw_data = FALSE, language = 'pt')
seeg_municipality_residuals= seeg_municipality_residuals%>%
  dplyr::rename(time= .data$Ano, group= .data$municipio)%>%
  dplyr::select(-territorio,-ibge)

##saving f
saveRDS(seeg_municipality_residuals,
        'data/seeg_municipality_residuals.rds'
)

#########
### Creating metadatabase -> SEEG
#########


#seeg_farming
seeg_municipality_farming= readRDS('data/seeg_municipality_farming.rds')
farming_var= colnames(seeg_municipality_farming)

metadata_seeg_municipality_farming= tibble::tibble(
  var = farming_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = c('Ano da Pesquisa', 'Identificador Geográfico', 'Setor Econômico', 'Processo de Geração das Emissões', 'Fonte de Emissões', 'Emissores', 'Gás Emitido', 'Atividade Econômica', 'Produto', 'Valor', 'Emissores Diretos/Indiretos', 'Tipo de Emissão', 'Emissão/Remoção'),
  source = "SEEG - Observatório do Clima",
  tipo = 1,
  unidade = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,'Toneladas',NA,NA,NA),
  categoria= c("Unidade de Tempo","Localizaçao", rep('Meio Ambiente', 11)), 
  subcategoria = c('Ano da Pesquisa', 'Identificador Geografico', rep('Emissão de Gases de Efeito Estufa', 11))
)

#saving f
write.csv(metadata_seeg_municipality_farming, file = "./data/seeg_municipality_farming_dic.csv", fileEncoding = "UTF-8")


#seeg_industry
seeg_municipality_industry= readRDS('data/seeg_municipality_industry.rds')
industry_var= colnames(seeg_state_industry)

metadata_seeg_municipality_industry= tibble::tibble(
  var = farming_var ,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_animal,
  source = "SEEG - Observatório do Clima",
  tipo = 1,
  unidade = ,
  categoria= , 
  subcategoria =
)
#saving 
write.csv(metadata_seeg_municipality_industry, file = "./data/seeg_municipality_industry_dic.csv", fileEncoding = "UTF-8")

#seeg_energy
seeg_municipality_energy= readRDS('data/seeg_municipality_energy.rds')
energy_var= colnames(seeg_municipality_energy)

metadata_seeg_municipality_energy= tibble::tibble(
  var = energy_var ,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = c('Ano da Pesquisa', 'Identificador Geogr?fico', 'Setor Econ?mico','Tipo de Emiss?o',  'Processo de Gera??o das Emiss?es', 'Atividade Econ?mica', 'Fonte de Emiss?es', 'Emissores', 'Emiss?o/Remo??o Bunker', 'G?s Emitido',  'Produto', 'Valor'),
  source = "SEEG - Observat?rio do Clima",
  tipo = 1,
  unidade = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,'Toneladas'),
  categoria= c("Unidade de Tempo","Localiza?ao", rep('Meio Ambiente', 10)), 
  subcategoria = c('Ano da Pesquisa', 'Identificador Geografico', rep('Emiss?o de Gases de Efeito Estufa', 10))
)
#saving f
write.csv(metadata_seeg_municipality_energy, file = "./data/seeg_municipality_energy_dic.csv", fileEncoding = "UTF-8")

#seeg_land
seeg_municipality_land= readRDS('data/seeg_municipality_land.rds')
land_var= colnames(seeg_municipality_land)

metadata_seeg_municipality_land= tibble::tibble(
  var = land_var ,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = c('Ano da Pesquisa', 'Identificador Geográfico', 'Setor', 'Processo de Geração das Emissões', 'Atividade Econômica', 'Bioma', 'Área Bioma', 'Local da Atividade Geradora','Atividade Geradora','Emissão/Remoção', 'Gás Emitido', 'Valor'),
  source = "SEEG - Observatório do Clima",
  tipo = 1,
  unidade = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,'Toneladas'),
  categoria= c("Unidade de Tempo","Localizaçao", rep('Meio Ambiente', 10)), 
  subcategoria = c('Ano da Pesquisa', 'Identificador Geografico', rep('Emissão de Gases de Efeito Estufa', 10))
)
#saving f
write.csv(metadata_seeg_municipality_land, file = "./data/seeg_municipality_land_dic.csv", fileEncoding = "UTF-8")

#seeg_residuals
seeg_municipality_residuals= readRDS('data/seeg_municipality_residuals.rds')
residuals_var= colnames(seeg_municipality_residuals)

metadata_seeg_municipality_residuals= tibble::tibble(
  var = residuals_var ,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = c('Ano da Pesquisa', 'Identificador Geográfico', 'Setor','Categoria de Emissão', 'Processo de Geração das Emissões','Atividade Geradora','Categoria dos Processos Geradores', 'Atividade Econômica', 'Produto', 'Valor','Emissão/Remoção Bunker', 'Gás Emitido'),
  source = "SEEG - Observatório do Clima",
  tipo = 1,
  unidade = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,'Toneladas',NA,NA),
  categoria= c("Unidade de Tempo","Localizaçao", rep('Meio Ambiente', 10)), 
  subcategoria = c('Ano da Pesquisa', 'Identificador Geografico', rep('Emissão de Gases de Efeito Estufa', 10))
)
#saving f
write.csv(metadata_seeg_municipality_residuals, file = "./data/seeg_municipality_residuals_dic.csv", fileEncoding = "UTF-8")
