### Creating metadatabase -> IBGE - PPM

#livestock_inventory
ppm_state_livestock_inventory= readRDS('data/ppm_state_livestock_inventory.rds')

dic_ppm_livestock_inventory= load_dictionary(dataset = 'ppm_livestock_inventory')
aux= c('','', rep('Efetivo dos Rebanhos ',10))
livestock_var= colnames(ppm_state_livestock_inventory)
label_livestock= paste0(aux,c("Identificador Geografico", "Ano da Pesquisa", dic_ppm_livestock_inventory$var_pt[1:10]))
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
  categoria= c("Localização","Unidade de Tempo",rep("Pecuaria",10)), 
  subcategoria = c('Identificador Geográfico','Ano da Pesquisa',rep("Especies - Criacao",10))
) 
#saving f
write.csv(metadata_ppm_livestock_inventory, file = "./data/metadata_ppm_livestock_inventory.csv", fileEncoding = "UTF-8")


#animal_origin_production
ppm_state_animal_origin_production= readRDS('data/ppm_state_animal_origin_production.rds')


dic_ppm_animal_origin_production= load_dictionary(dataset = 'ppm_animal_origin_production')%>%
  arrange(var_code)
animal_var= colnames(ppm_state_animal_origin_production)
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
  categoria= c("Localização","Unidade de Tempo",rep("Pecuaria",13)), 
  subcategoria = c('Identificador Geográfico','Ano da Pesquisa',rep("Produtos Pecuarios",13))
)
#saving f
write.csv(metadata_ppm_animal_origin_production, file = "./data/metadata_ppm_animal_origin_production.csv", fileEncoding = "UTF-8")


#sheep_farming 
ppm_state_sheep_farming= readRDS('data/ppm_state_sheep_farming.rds')

dic_ppm_sheep_farming= load_dictionary(dataset = 'ppm_sheep_farming')
sheep_var= colnames(ppm_state_sheep_farming)
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
  categoria= c("Localização","Unidade de Tempo","Pecuaria"), 
  subcategoria = c('Identificador Geográfico','Ano da Pesquisa',"Atividade Pecuaria")
) 
#saving f
write.csv(metadata_ppm_sheep_farming, file = "./data/metadata_ppm_sheep_farming.csv", fileEncoding = "UTF-8")


#ppm_cow_farming 
ppm_state_cow_farming= readRDS('data/ppm_state_cow_farming.rds')


dic_ppm_cow_farming= load_dictionary(dataset = 'ppm_cow_farming')
cow_var= colnames(ppm_state_cow_farming)
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
  categoria= c("Localização","Unidade de Tempo","Pecuaria"), 
  subcategoria = c('Identificador Geográfico','Ano da Pesquisa',"Atividade Pecuaria")
) 

#saving f
write.csv(metadata_ppm_cow_farming, file = "./data/metadata_ppm_cow_farming.csv", fileEncoding = "UTF-8")


#ppm_aquaculture
ppm_state_aquaculture= readRDS('data/ppm_state_aquaculture.rds')

dic_ppm_aquaculture= load_dictionary(dataset = 'ppm_aquaculture')%>%
  dplyr::arrange(var_pt)
vec= NULL
for(i in 1:25){
  vec= c(vec, rep(dic_ppm_aquaculture$var_pt[i],2))
}
vec= c('','',vec)
aux= c("Identificador Geografico", "Ano da Pesquisa",rep(c('Producao da Aquicultura ', 'Valor da Producao '),25))
label_aqua= paste0(aux,vec)
label_aqua= label_aqua[-25]
aqua_var= colnames(ppm_state_aquaculture)
label_aqua= label_aqua[-44]

unidade_aqua= c('','',rep(c('Kg','1K BRL'),25))
unidade_aqua= unidade_aqua[-25]
unidade_aqua= unidade_aqua[-44]
unidade_aqua[17]= '1K'
unidade_aqua[36]= '1K'

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
  categoria= c("Localização","Unidade de Tempo" ,rep("Pecuaria",48)), 
  subcategoria = c("Localização","Unidade de Tempo" ,rep("Especies - Aquicultura",48))
)
#saving f
write.csv(metadata_ppm_aquaculture, file = "./data/metadata_ppm_aquaculture.csv", fileEncoding = "UTF-8")
