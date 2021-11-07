##########
### Generate data -> SEEG 
##########
## Agregation level - STATE

#seeg_farming

seeg_state_farming= load_seeg(dataset = 'seeg_farming', geo_level = 'state', raw_data = FALSE, language = 'pt')
seeg_state_farming= seeg_state_farming%>%
  dplyr::rename(time= .data$Ano, group= .data$estado)
##saving
saveRDS(seeg_state_farming,
        'data/seeg_state_farming.rds'
)

#seeg_industry
seeg_state_industry= load_seeg(dataset = "seeg_industry", geo_level = 'state', raw_data = FALSE, language = 'pt')
seeg_state_industry= seeg_state_industry%>%
  dplyr::rename(time= .data$Ano, group= .data$estado)

##saving
saveRDS(seeg_state_industry,
        'data/seeg_state_industry.rds'
)

#seeg_energy
seeg_state_energy= load_seeg(dataset = "seeg_energy", geo_level = 'state', raw_data = FALSE, language = 'pt')
seeg_state_energy= seeg_state_energy%>%
  dplyr::rename(time= .data$Ano, group= .data$estado)

##saving
saveRDS(seeg_state_energy,
        'data/seeg_state_energy.rds'
)

#seeg_land
seeg_state_land= load_seeg(dataset = "seeg_land", geo_level = 'state', raw_data = FALSE, language = 'pt')
seeg_state_land= seeg_state_land%>%
  dplyr::rename(time= .data$Ano, group= .data$estado)

##saving
saveRDS(seeg_state_land,
        'data/seeg_state_land.rds'
)

#seeg_residuals
seeg_state_residuals= load_seeg(dataset = "seeg_residuals", geo_level = 'state', raw_data = FALSE, language = 'pt')
seeg_state_residuals= seeg_state_residuals%>%
  dplyr::rename(time= .data$Ano, group= .data$estado)

##saving
saveRDS(seeg_state_residuals,
        'data/seeg_state_residuals.rds'
)

#########
### Creating metadatabase -> SEEG
#########


#seeg_farming
seeg_state_farming= readRDS('data/seeg_state_farming.rds')
farming_var= colnames(seeg_state_farming)

metadata_seeg_state_farming= tibble::tibble(
  var = farming_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = c('Ano da Pesquisa', 'Identificador Geográfico', 'Setor Econômico', 'Processo de Geração das Emissões', 'Fonte de Emissões', 'Emissores', 'Gás Emitido', 'Atividade Econômica', 'Produto', 'Valor', 'Emissores Diretos/Indiretos', 'Tipo de Emissão', 'Emissão/Remoção Bunker'),
  source = "SEEG - Observatório do Clima",
  tipo = 1,
  unidade = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,'Toneladas',NA,NA,NA),
  categoria= c("Unidade de Tempo","Localizaçao", rep('Meio Ambiente', 11)), 
  subcategoria = c('Ano da Pesquisa', 'Identificador Geografico', rep('Emissão de Gases de Efeito Estufa', 11))
)

#saving 
write.csv(metadata_seeg_state_farming, file = "./data/seeg_state_farming_dic.csv", fileEncoding = "UTF-8")


#seeg_industry
seeg_state_industry= readRDS('data/seeg_state_industry.rds')
industry_var= colnames(seeg_state_industry)

metadata_seeg_state_industry= tibble::tibble(
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
write.csv(metadata_seeg_state_industry, file = "./data/seeg_state_industry_dic.csv", fileEncoding = "UTF-8")

#seeg_energy
seeg_state_energy= readRDS('data/seeg_state_energy.rds')
energy_var= colnames(seeg_state_energy)

metadata_seeg_state_energy= tibble::tibble(
  var = energy_var ,
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
write.csv(metadata_seeg_state_energy, file = "./data/seeg_state_energy_dic.csv", fileEncoding = "UTF-8")

#seeg_land
seeg_state_land= readRDS('data/seeg_state_land.rds')
land_var= colnames(seeg_state_farming)

metadata_seeg_state_land= tibble::tibble(
  var = land_var ,
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
write.csv(metadata_seeg_state_land, file = "./data/seeg_state_land_dic.csv", fileEncoding = "UTF-8")

#seeg_residuals
seeg_state_residuals= readRDS('data/seeg_state_residuals.rds')
residuals_var= colnames(seeg_state_residuals)

metadata_seeg_state_residuals= tibble::tibble(
  var = residuals_var ,
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
write.csv(metadata_seeg_state_residuals, file = "./data/seeg_state_residuals_dic.csv", fileEncoding = "UTF-8")
