##########
### Generate data -> IBGE - PPM
##########
## Agregation level - MUNICIPALITY


#### Packages
library(tidyverse)
library(datazoom.amazonia)

#livestock_inventory

##municipality 
## Provided time period that is supporter, otherwise there is error
### split the data base 
ppm_municipality_livestock_inventory1= load_ppm(dataset = 'ppm_livestock_inventory', 
                                                raw_data = FALSE, 
                                                'municipality', 
                                                1974:1980, 
                                                language = "pt")

ppm_municipality_livestock_inventory2= load_ppm(dataset = 'ppm_livestock_inventory', 
                                                raw_data = FALSE, 
                                                'municipality', 
                                                1981:1990, 
                                                language = "pt")

ppm_municipality_livestock_inventory3= load_ppm(dataset = 'ppm_livestock_inventory', 
                                                raw_data = FALSE, 
                                                'municipality', 
                                                1991:2000, 
                                                language = "pt")

ppm_municipality_livestock_inventory4= load_ppm(dataset = 'ppm_livestock_inventory', 
                                                raw_data = FALSE, 
                                                'municipality', 
                                                2001:2010, 
                                                language = "pt")

ppm_municipality_livestock_inventory5= load_ppm(dataset = 'ppm_livestock_inventory', 
                                                raw_data = FALSE, 
                                                'municipality', 
                                                2011:2020, 
                                                language = "pt")

ppm_municipality_livestock_inventory6= load_ppm(dataset = 'ppm_livestock_inventory', 
                                                raw_data = FALSE, 
                                                'municipality', 
                                                2021, 
                                                language = "pt")
##append datasets
ppm_municipality_livestock_inventory <- rbind(ppm_municipality_livestock_inventory1,
                                              ppm_municipality_livestock_inventory2,
                                              ppm_municipality_livestock_inventory3,
                                              ppm_municipality_livestock_inventory4,
                                              ppm_municipality_livestock_inventory5,
                                              ppm_municipality_livestock_inventory6)
##making data usable for datazoom viz
ppm_municipality_livestock_inventory = lapply(ppm_municipality_livestock_inventory, as.numeric)
ppm_municipality_livestock_inventory1[is.na(ppm_municipality_livestock_inventory)] <- 0

ppm_municipality_livestock_inventory= dplyr::rename(ppm_municipality_livestock_inventory , 
  time=.data$ano, 
  group=.data$geo_id)


##saving f
saveRDS(ppm_municipality_livestock_inventory,
        file = "./data/ppm_municipality_livestock_inventory.rds"
)

#sheep_farming 

##municipality 
ppm_municipality_sheep_farming= load_ppm(dataset = 'ppm_sheep_farming', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")

##making data usable for datazoom viz
ppm_municipality_sheep_farming = lapply(ppm_municipality_sheep_farming, as.numeric)
ppm_municipality_sheep_farming <- as.data.frame(ppm_municipality_sheep_farming)
ppm_municipality_sheep_farming[is.na(ppm_municipality_sheep_farming)] <- 0

munics= readxl::read_xls("data\\RELATORIO_DTB_BRASIL_MUNICIPIO.xls")%>%
  dplyr::select('C?digo Munic?pio Completo', 'Nome_Munic?pio')
ppm_municipality_sheep_farming$geo_id= plyr::mapvalues(ppm_municipality_sheep_farming$geo_id, from = munics$`C?digo Munic?pio Completo`, to = munics$Nome_Munic?pio)
ppm_municipality_sheep_farming= dplyr::rename(ppm_municipality_sheep_farming , time=.data$ano, group=.data$geo_id)

##saving f
saveRDS(ppm_municipality_sheep_farming,
        file = "./data/ppm_municipality_sheep_farming.rds"
)

#animal_origin_production 

##municipality (ainda nao salvo)
ppm_municipality_animal_origin_production= load_ppm(dataset = 'ppm_animal_origin_production', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")

##making data usable for datazoom viz
ppm_municipality_animal_origin_production = lapply(ppm_municipality_animal_origin_production, as.numeric)
ppm_municipality_animal_origin_production <- as.data.frame(ppm_municipality_animal_origin_production)
ppm_municipality_animal_origin_production[is.na(ppm_municipality_animal_origin_production)] <- 0

munics= readxl::read_xls("data\\RELATORIO_DTB_BRASIL_MUNICIPIO.xls")%>%
  dplyr::select('C?digo Munic?pio Completo', 'Nome_Munic?pio')
ppm_municipality_animal_origin_production$geo_id= plyr::mapvalues(ppm_municipality_animal_origin_production$geo_id, from = munics$`C?digo Munic?pio Completo`, to = munics$Nome_Munic?pio)
ppm_municipality_animal_origin_production= dplyr::rename(ppm_municipality_animal_origin_production , time=.data$ano, group=.data$geo_id)

##saving f
saveRDS(ppm_municipality_animal_origin_production,
        file = "./data/ppm_municipality_animal_origin_production.rds"
)

#ppm_cow_farming 

##municipality (ainda nao salvo)
ppm_municipality_cow_farming= load_ppm(dataset = 'ppm_cow_farming', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##making data usable for datazoom viz
ppm_municipality_cow_farming = lapply(ppm_municipality_cow_farming, as.numeric)
ppm_municipality_cow_farming <- as.data.frame(ppm_municipality_cow_farming)
ppm_municipality_cow_farming[is.na(ppm_municipality_cow_farming)] <- 0

munics= readxl::read_xls("data\\RELATORIO_DTB_BRASIL_MUNICIPIO.xls")%>%
  dplyr::select('C?digo Munic?pio Completo', 'Nome_Munic?pio')
ppm_municipality_cow_farming$geo_id= plyr::mapvalues(ppm_municipality_cow_farming$geo_id, from = munics$`C?digo Munic?pio Completo`, to = munics$Nome_Munic?pio)
ppm_municipality_cow_farming= dplyr::rename(ppm_municipality_cow_farming , time=.data$ano, group=.data$geo_id)

##saving f
saveRDS(ppm_municipality_cow_farming,
        file = "./data/ppm_municipality_cow_farming.rds"
)

#ppm_aquaculture

##municipality (ainda nao salvo)
ppm_municipality_aquaculture= load_ppm(dataset = 'ppm_aquaculture', raw_data = FALSE, 'municipality', 2013:2019, language = "pt")
##making data usable for datazoom viz
label_aqua= Hmisc::label(ppm_municipality_aquaculture) # for generating metadata

ppm_municipality_aquaculture = lapply(ppm_municipality_aquaculture, as.numeric)
ppm_municipality_aquaculture <- as.data.frame(ppm_municipality_aquaculture)
ppm_municipality_aquaculture[is.na(ppm_municipality_aquaculture)] <- 0

munics= readxl::read_xls("data\\RELATORIO_DTB_BRASIL_MUNICIPIO.xls")%>%
  dplyr::select('C?digo Munic?pio Completo', 'Nome_Munic?pio')
ppm_municipality_aquaculture$geo_id= plyr::mapvalues(ppm_municipality_aquaculture$geo_id, from = munics$`C?digo Munic?pio Completo`, to = munics$Nome_Munic?pio)
ppm_municipality_aquaculture= dplyr::rename(ppm_municipality_aquaculture , time=.data$ano, group=.data$geo_id)

##saving f
saveRDS(ppm_municipality_aquaculture,
        file = "./data/ppm_municipality_aquaculture.rds"
)
### aggregating all datasets
ppm_municipality= ppm_municipality_livestock_inventory%>%
  dplyr::left_join(ppm_municipality_animal_origin_production, by= c('group','time'))%>%
  dplyr::left_join(ppm_municipality_sheep_farming, by= c('group','time'))%>%
  dplyr::left_join(ppm_municipality_cow_farming, by= c('group','time'))%>%
  dplyr::left_join(ppm_municipality_aquaculture, by= c('group','time'))
##saving f
saveRDS(ppm_municipality,
        file = "./data/ppm_municipality.rds"
)

##############
### Creating metadatabase -> IBGE - PPM
##############

#livestock_inventory
ppm_municipality_livestock_inventory= readRDS('data/ppm_municipality_livestock_inventory.rds')

dic_ppm_livestock_inventory= load_dictionary(dataset = 'ppm_livestock_inventory')%>%
  arrange(var_code)
aux= c('','', rep('Efetivo dos Rebanhos ',10))
livestock_var= colnames(ppm_municipality_livestock_inventory)
livestock_var= livestock_var[-1]
livestock_var= livestock_var[-1]
livestock_var= sort(livestock_var)

livestock_var= c('group', 'time', livestock_var)
label_livestock= paste0(aux,c("Identificador Geografico", "Ano da Pesquisa", dic_ppm_livestock_inventory$var_pt[2:11]))
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
  categoria= c("Localiza?ao","Unidade de Tempo",rep("Pecuaria",10)), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',rep("Especies - Criacao",10))
) 
#saving f
write.csv(metadata_ppm_livestock_inventory, file = "./data/ppm_municipality_livestock_inventory_dic.csv", fileEncoding = "UTF-8")


#animal_origin_production
ppm_municipality_animal_origin_production= readRDS('data/ppm_municipality_animal_origin_production.rds')


dic_ppm_animal_origin_production= load_dictionary(dataset = 'ppm_animal_origin_production')%>%
  arrange(var_code)
animal_var= colnames(ppm_municipality_animal_origin_production)
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
  categoria= c("Localiza?ao","Unidade de Tempo",rep("Pecuaria",13)), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',rep("Produtos Pecuarios",13))
)
#saving f
write.csv(metadata_ppm_animal_origin_production, file = "./data/ppm_municipality_animal_origin_production_dic.csv", fileEncoding = "UTF-8")


#sheep_farming 
ppm_municipality_sheep_farming= readRDS('data/ppm_municipality_sheep_farming.rds')

dic_ppm_sheep_farming= load_dictionary(dataset = 'ppm_sheep_farming')
sheep_var= colnames(ppm_municipality_sheep_farming)
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
  categoria= c("Localiza?ao","Unidade de Tempo","Pecuaria"), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',"Atividade Pecuaria")
) 
#saving f
write.csv(metadata_ppm_sheep_farming, file = "./data/ppm_municipality_sheep_farming_dic.csv", fileEncoding = "UTF-8")


#ppm_cow_farming 
ppm_municipality_cow_farming= readRDS('data/ppm_municipality_cow_farming.rds')


dic_ppm_cow_farming= load_dictionary(dataset = 'ppm_cow_farming')
cow_var= colnames(ppm_municipality_cow_farming)
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
  categoria= c("Localiza?ao","Unidade de Tempo","Pecuaria"), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',"Atividade Pecuaria")
) 

#saving f
write.csv(metadata_ppm_cow_farming, file = "./data/ppm_municipality_cow_farming_dic.csv", fileEncoding = "UTF-8")


#ppm_aquaculture
ppm_municipality_aquaculture= readRDS('data/ppm_municipality_aquaculture.rds')

#the label_aqua vector comes from the labels in the original data generated by datazoom.amazonia
#check #ppm_municipality in the data generation section above
label_aqua[1]= "Identificador Geografico"
label_aqua[2]= "Ano da Pesquisa"
label_aqua[4]= "Total"

aqua_var= colnames(ppm_municipality_aquaculture)

vec= rep('',50)
unidade_aqua= rep('', 50)
for(i in 1:50){
  quant= startsWith(aqua_var,'quant')
  valor= startsWith(aqua_var,'valor')
  if(quant[i]==TRUE){
    unidade_aqua[i]= 'Kg'
    vec[i]= 'Producao da Aquicultura '
  }
  else if(valor[i]==TRUE){
    unidade_aqua[i]= '1K BRL'
    vec[i]= 'Valor da Producao '
  }
}

label_aqua= paste0(vec,label_aqua)
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
  categoria= c("Localiza?ao","Unidade de Tempo" ,rep("Pecuaria",48)), 
  subcategoria = c("Localiza?ao","Unidade de Tempo" ,rep("Especies - Aquicultura",48))
)

#saving f
write.csv(metadata_ppm_aquaculture, file = "./data/ppm_municipality_aquaculture_dic.csv", fileEncoding = "UTF-8")

###aggregating all metadatas

metadata_ppm_animal_origin_production= metadata_ppm_animal_origin_production[-1,]
metadata_ppm_animal_origin_production= metadata_ppm_animal_origin_production[-1,]

metadata_ppm_sheep_farming= metadata_ppm_sheep_farming[-1,]
metadata_ppm_sheep_farming= metadata_ppm_sheep_farming[-1,]

metadata_ppm_cow_farming= metadata_ppm_cow_farming[-1,]
metadata_ppm_cow_farming= metadata_ppm_cow_farming[-1,]

metadata_ppm_aquaculture= metadata_ppm_aquaculture[-1,]
metadata_ppm_aquaculture= metadata_ppm_aquaculture[-1,]

metadata_ppm= metadata_ppm_livestock_inventory%>%
  dplyr::bind_rows(metadata_ppm_animal_origin_production)%>%
  dplyr::bind_rows(metadata_ppm_sheep_farming)%>%
  dplyr::bind_rows(metadata_ppm_cow_farming)%>%
  dplyr::bind_rows(metadata_ppm_aquaculture)

#saving f
write.csv(metadata_ppm, file = "./data/ppm_municipality_dic.csv", fileEncoding = "UTF-8")