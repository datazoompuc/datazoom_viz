##########
### Generate data -> SEEG 
##########
## Agregation level - STATE


# load packages ---------------------------------------------------------------------
library(datazoom.amazonia)

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

##saving f
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

seeg_state_farming_dic= tibble::tibble(
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

#saving f
write.csv(seeg_state_farming_dic, file = "./data/seeg_state_farming_dic.csv", fileEncoding = "UTF-8")


#seeg_industry
seeg_state_industry= readRDS('data/seeg_state_industry.rds')
industry_var= colnames(seeg_state_industry)

seeg_state_industry_dic= tibble::tibble(
    var = industry_var ,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = c('Ano da Pesquisa', 'Identificador Geográfico', 'Setor Econômico', 'Processo de Geração das Emissões','Produção Geradora das Emissões','Emissores', 'Gás Emitido', 'Atividade Econômica', 'Produto', 'Valor','Emissão Bunker'),
    source = "SEEG - Observatório do Clima",
    tipo = 1,
    unidade = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,'Toneladas',NA),
    categoria= c("Unidade de Tempo","Localizaçao", rep('Meio Ambiente', 9)), 
    subcategoria = c('Ano da Pesquisa', 'Identificador Geografico', rep('Emissão de Gases de Efeito Estufa', 9))
)
#saving F
write.csv(seeg_state_industry_dic, file = "./data/seeg_state_industry_dic.csv", fileEncoding = "UTF-8")

#seeg_energy
seeg_state_energy_og= readRDS('data/seeg_state_energy.rds')
energy_var= colnames(seeg_state_energy)

seeg_state_energy_dic= tibble::tibble(
    var = energy_var ,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = c('Ano da Pesquisa', 'Identificador Geográfico', 'Setor Econômico','Tipo de Emissão',  'Processo de Geração das Emissões', 'Atividade Econômica', 'Fonte de Emissões', 'Emissores', 'Emissão/Remoção Bunker', 'Gás Emitido',  'Produto', 'Valor'),
    source = "SEEG - Observatório do Clima",
    tipo = 1,
    unidade = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,'Toneladas'),
    categoria= c("Unidade de Tempo","Localizaçao", rep('Meio Ambiente', 10)), 
    subcategoria = c('Ano da Pesquisa', 'Identificador Geografico', rep('Emissão de Gases de Efeito Estufa', 10))
)
#saving f
write.csv(seeg_state_energy_dic, file = "./data/seeg_state_energy_dic.csv", fileEncoding = "UTF-8")

#seeg_land
seeg_state_land= readRDS('data/seeg_state_land.rds')
land_var= colnames(seeg_state_land)

seeg_state_land_dic= tibble::tibble(
    var = land_var ,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = c('Ano da Pesquisa', 'Identificador Geográfico', 'Setor', 'Processo de Geração das Emissões', 'Atividade Econômica', 'Bioma', 'Área Bioma', 'Local da Atividade Geradora','Atividade Geradora','Emissão/Remoção Bunker', 'Gás Emitido', 'Valor'),
    source = "SEEG - Observatório do Clima",
    tipo = 1,
    unidade = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,'Toneladas'),
    categoria= c("Unidade de Tempo","Localizaçao", rep('Meio Ambiente', 10)), 
    subcategoria = c('Ano da Pesquisa', 'Identificador Geografico', rep('Emissão de Gases de Efeito Estufa', 10))
)
#saving f
write.csv(seeg_state_land_dic, file = "./data/seeg_state_land_dic.csv", fileEncoding = "UTF-8")

#seeg_residuals
seeg_state_residuals= readRDS('data/seeg_state_residuals.rds')
residuals_var= colnames(seeg_state_residuals)

seeg_state_residuals_dic= tibble::tibble(
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
write.csv(seeg_state_residuals_dic, file = "./data/seeg_state_residuals_dic.csv", fileEncoding = "UTF-8")

#########
### Creating metadatabase in english -> SEEG
#########


#seeg_farming
seeg_state_farming= readRDS('data/seeg_state_farming.rds')
farming_var= colnames(seeg_state_farming)

seeg_state_farming_dic= tibble::tibble(
    var = farming_var,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = c('Research Year', 'Geographic Identifier', 'Economic Sector',
              'Emissions Generation Process','Source of Emissions','Emitters', 'Emitted Gas',
              'Economic Activity' ,'Product', 'Value','Direct/Indirect Emitters','Emission Type', 'Bunker Emission/Removal'
    ),
    source = "SEEG - Observatório do Clima",
    tipo = 1,
    unidade = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,'Toneladas',NA,NA,NA),
    categoria= c("Unidade de Tempo","Localizaçao", rep('Meio Ambiente', 11)), 
    subcategoria = c('Ano da Pesquisa', 'Identificador Geografico', rep('Emissão de Gases de Efeito Estufa', 11))
)

#saving f
write.csv(seeg_state_farming_dic, file = "./data/seeg_state_farming_dic_en.csv", fileEncoding = "UTF-8")



#seeg_energy
seeg_state_energy <- readRDS("~/GitHub/datazoom_viz/data/seeg_state_energy.rds")
energy_var= colnames(seeg_state_energy)

seeg_state_energy_dic= tibble::tibble(
    var = energy_var ,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = c('Research Year', 'Geographic Identifier', 'Economic Sector',
              'Emission Type',  'Emissions Generation Process', 'Economic Activity',
              'Source of Emissions', 'Emitters', 'Bunker Emission/Removal', 'Emitted Gas',
              'Product', 'Value'),
    source = "SEEG - Observatório do Clima",
    tipo = 1,
    unidade = c(NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,'Toneladas'),
    categoria= c("Unidade de Tempo","Localizaçao", rep('Meio Ambiente', 10)), 
    subcategoria = c('Ano da Pesquisa', 'Identificador Geografico', rep('Emissão de Gases de Efeito Estufa', 10))
)
#saving f
write.csv(seeg_state_energy_dic, file = "./data/seeg_state_energy_dic_en.csv", fileEncoding = "UTF-8")
