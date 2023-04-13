##########
### Generate data -> IBGE - PPM
##########
## Agregation level - STATE

#livestock_inventory

##state
ppm_state_livestock_inventory= load_ppm(dataset = 'ppm_livestock_inventory', raw_data = FALSE, 'state', 1974:2021, language = "pt")
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

#transforma em numeric
ppm_state_livestock_inventory$num_v2670 <- as.numeric(ppm_state_livestock_inventory$num_v2670)
ppm_state_livestock_inventory$num_v2675 <- as.numeric(ppm_state_livestock_inventory$num_v2675)
ppm_state_livestock_inventory$num_v2672 <- as.numeric(ppm_state_livestock_inventory$num_v2672)
ppm_state_livestock_inventory$num_v32794 <- as.numeric(ppm_state_livestock_inventory$num_v32794)
ppm_state_livestock_inventory$num_v2681 <- as.numeric(ppm_state_livestock_inventory$num_v2681)
ppm_state_livestock_inventory$num_v2677 <- as.numeric(ppm_state_livestock_inventory$num_v2677)
ppm_state_livestock_inventory$num_v32796 <- as.numeric(ppm_state_livestock_inventory$num_v32796 )
ppm_state_livestock_inventory$num_v32793 <- as.numeric(ppm_state_livestock_inventory$num_v32793)
ppm_state_livestock_inventory$num_v2680 <- as.numeric(ppm_state_livestock_inventory$num_v2680)
ppm_state_livestock_inventory$num_v32795 <- as.numeric(ppm_state_livestock_inventory$num_v32795)

ppm_state_livestock_inventory[is.na(ppm_state_livestock_inventory)] = 0
#deixa os nomes de acordo com o dataframe antigo

ppm_state_livestock_inventory <- ppm_state_livestock_inventory %>%
    rename(
        "bovino_efetivo_dos_rebanhos" = "num_v2670",
 "bubalino_efetivo_dos_rebanhos" =  "num_v2675",  
 "equino_efetivo_dos_rebanhos" = "num_v2672",
 "suino_total_efetivo_dos_rebanhos"  = "num_v32794",           
 "ovino_efetivo_dos_rebanhos" = "num_v2677" ,
 "caprino_efetivo_dos_rebanhos"  = "num_v2681",
 "galinaceos_total_efetivo_dos_rebanhos"  = "num_v32796",      
 "galinaceos_galinhas_efetivo_dos_rebanhos"   = "num_v32793" , 
 "codornas_efetivo_dos_rebanhos"       = "num_v2680"     ,    
"suino_matrizes_de_suinos_efetivo_dos_rebanhos"= "num_v32795")



##saving
saveRDS(ppm_state_livestock_inventory,
        file = "./data/ppm_state_livestock_inventory.rds"
) #f
saveRDS(ppm_municipality_livestock_inventory,
        file = "./data/ppm_municipality_livestock_inventory.rds"
)

#sheep_farming 

##state
ppm_state_sheep_farming= load_ppm(dataset = 'ppm_sheep_farming', raw_data = FALSE, 'state', 1974:2021, language = "pt")
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

ppm_state_sheep_farming$num_v108 <- as.numeric(ppm_state_sheep_farming$num_v108)


ppm_state_sheep_farming[is.na(ppm_state_sheep_farming)] = 0

ppm_state_sheep_farming <- ppm_state_sheep_farming %>%
    rename(
        "ovinos_tosquiados_nos_estabelecimentos_agropecuarios" = "num_v108")

##saving f
saveRDS(ppm_state_sheep_farming,
        file = "./data/ppm_state_sheep_farming.rds"
)

#animal_origin_production 

##state
ppm_state_animal_origin_production= load_ppm(dataset = 'ppm_animal_origin_production', raw_data = FALSE, 'state', 1974:2021, language = "pt")
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


ppm_state_animal_origin_production$valor_v0 <- as.numeric(ppm_state_animal_origin_production$valor_v0)
ppm_state_animal_origin_production$quant_v2682 <- as.numeric(ppm_state_animal_origin_production$quant_v2682)
ppm_state_animal_origin_production$valor_v2682 <- as.numeric(ppm_state_animal_origin_production$valor_v2682)
ppm_state_animal_origin_production$quant_v2683 <- as.numeric(ppm_state_animal_origin_production$quant_v2683)
ppm_state_animal_origin_production$valor_v2683 <- as.numeric(ppm_state_animal_origin_production$valor_v2683)
ppm_state_animal_origin_production$quant_v2684 <- as.numeric(ppm_state_animal_origin_production$quant_v2684)
ppm_state_animal_origin_production$valor_v2684 <- as.numeric(ppm_state_animal_origin_production$valor_v2684)
ppm_state_animal_origin_production$quant_v2685 <- as.numeric(ppm_state_animal_origin_production$quant_v2685)
ppm_state_animal_origin_production$valor_v2685 <- as.numeric(ppm_state_animal_origin_production$valor_v2685)
ppm_state_animal_origin_production$quant_v2686 <- as.numeric(ppm_state_animal_origin_production$quant_v2686)
ppm_state_animal_origin_production$valor_v2686 <- as.numeric(ppm_state_animal_origin_production$valor_v2686)
ppm_state_animal_origin_production$quant_v2687 <- as.numeric(ppm_state_animal_origin_production$quant_v2687)
ppm_state_animal_origin_production$valor_v2687 <- as.numeric(ppm_state_animal_origin_production$valor_v2687)



ppm_state_animal_origin_production[is.na(ppm_state_animal_origin_production)] = 0



##saving f
saveRDS(ppm_state_animal_origin_production,
        file = "./data/ppm_state_animal_origin_production.rds"
)

#ppm_cow_farming 

##state
ppm_state_cow_farming= load_ppm(dataset = 'ppm_cow_farming', raw_data = FALSE, 'state', 1974:2021, language = "pt")
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

ppm_state_cow_farming$num_v107 <- as.numeric(ppm_state_cow_farming$num_v107)


ppm_state_cow_farming[is.na(ppm_state_cow_farming )] = 0

ppm_state_cow_farming <- ppm_state_cow_farming %>%
    rename("vacas_ordenhadas" = "num_v107")


##saving f
saveRDS(ppm_state_cow_farming,
        file = "./data/ppm_state_cow_farming.rds"
)

#ppm_aquaculture

##state
ppm_state_aquaculture= load_ppm(dataset = 'ppm_aquaculture', raw_data = FALSE, 'state', 2013:2021, language = "pt")
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



# Definindo vetor com os nomes das colunas
cols <- c( "quant_v32865", "quant_v32867" ,"quant_v32868" ,"quant_v32870", "quant_v32871",
 "quant_v32872" ,"quant_v32873", "quant_v32874", "quant_v32875", "quant_v32876" ,"quant_v32877", "quant_v32880",
 "quant_v32886" ,"valor_v0"     ,"valor_v32865", "valor_v32867" ,"valor_v32868", "valor_v32870", "valor_v32871",
 "valor_v32872", "valor_v32873", "valor_v32874", "valor_v32875", "valor_v32876", "valor_v32877", "valor_v32880",
"valor_v32886", "quant_v32869" ,"quant_v32878" ,"quant_v32881" ,"valor_v32869" ,"valor_v32878", "valor_v32881",
 "quant_v32861" ,"quant_v32887", "quant_v32889", "quant_v32890" ,"valor_v32861", "valor_v32887", "valor_v32889",
 "valor_v32890", "quant_v32888", "valor_v32888", "valor_v32891" ,"quant_v32879" ,"valor_v32879", "quant_v32866",
 "valor_v32866")

# Loop para aplicar a função as.numeric() em cada coluna
for (col in cols) {
    ppm_state_aquaculture[[col]] <- as.numeric(ppm_state_aquaculture[[col]])
}


ppm_state_aquaculture[is.na(ppm_state_aquaculture)] = 0

ppm_state_aquaculture<-ppm_state_aquaculture%>%
    rename(
        alevinos_producao_da_aquicultura = "quant_v32886",
        alevinos_valor_da_producao = "valor_v32886",
        camarao_producao_da_aquicultura = "quant_v32887",
        camarao_valor_da_producao = "valor_v32887",
        carpa_producao_da_aquicultura = "quant_v32861",
        carpa_valor_da_producao = "valor_v32861",
        curimata_curimbata_producao_da_aquicultura = "quant_v32865",
        curimata_curimbata_valor_da_producao = "valor_v32865",
        dourado_producao_da_aquicultura = "quant_v32866",
        dourado_valor_da_producao = "valor_v32866",
        jatuarana_piabanha_e_piracanjuba_producao_da_aquicultura = "quant_v32867",
        jatuarana_piabanha_e_piracanjuba_valor_da_producao = "valor_v32867",
        lambari_producao_da_aquicultura = "quant_v32868",
        lambari_valor_da_producao = "valor_v32868",
        larvas_e_pos_larvas_de_camarao_producao_da_aquicultura = "quant_v32888",
        larvas_e_pos_larvas_de_camarao_valor_da_producao = "valor_v32888",
        matrinxa_producao_da_aquicultura = "quant_v32869",
        matrinxa_valor_da_producao = "valor_v32869",
        ostras_vieiras_e_mexilhoes_producao_da_aquicultura = "quant_v32889",
        ostras_vieiras_e_mexilhoes_valor_da_producao = "valor_v32889",
        outros_peixes_producao_da_aquicultura = "quant_v32881",
        outros_peixes_valor_da_producao = "valor_v32881",
        outros_produtos_ra_jacare_siri_caranguejo_lagosta_etc_valor_da_producao = "valor_v32891",
        pacu_e_patinga_producao_da_aquicultura = "quant_v32870",
        pacu_e_patinga_valor_da_producao = "valor_v32870",
        piau_piapara_piaucu_piava_producao_da_aquicultura = "quant_v32871",
        piau_piapara_piaucu_piava_valor_da_producao = "valor_v32871",
        pintado_cachara_cachapira_e_pintachara_surubim_producao_da_aquicultura = "quant_v32872",
        pintado_cachara_cachapira_e_pintachara_surubim_valor_da_producao = "valor_v32872",
        pirapitinga_producao_da_aquicultura = "quant_v32873",
        pirapitinga_valor_da_producao = "valor_v32873",
        pirarucu_producao_da_aquicultura = "quant_v32874",
        pirarucu_valor_da_producao = "valor_v32874",
        sementes_de_moluscos_producao_da_aquicultura = "quant_v32890",
        sementes_de_moluscos_valor_da_producao = "valor_v32890",
        tambacu_tambatinga_producao_da_aquicultura = "quant_v32875",
        tambacu_tambatinga_valor_da_producao = "valor_v32875",
        tambaqui_producao_da_aquicultura = "quant_v32876",
        tambaqui_valor_da_producao = "valor_v32876",
        tilapia_producao_da_aquicultura = "quant_v32877",
        tilapia_valor_da_producao = "valor_v32877",
        total_valor_da_producao = "valor_v0",
        traira_e_trairao_producao_da_aquicultura = "quant_v32878",
        traira_e_trairao_valor_da_producao = "valor_v32878",
        truta_producao_da_aquicultura = "quant_v32879",
        truta_valor_da_producao = "valor_v32879",
        tucunare_producao_da_aquicultura = "quant_v32880",
        tucunare_valor_da_producao = "valor_v32880"
    )




ppm_state_aquaculture= ppm_state_aquaculture[,order(colnames(ppm_state_aquaculture))]
ppm_state_aquaculture <- ppm_state_aquaculture %>%
  dplyr::select(time, everything())
ppm_state_aquaculture <- ppm_state_aquaculture %>%
  dplyr::select(group, everything())
##saving f
saveRDS(ppm_state_aquaculture,
        file = "./data/ppm_state_aquaculture.rds"
)

### aggregating all datasets
ppm_state= ppm_state_livestock_inventory%>%
  dplyr::left_join(ppm_state_animal_origin_production, by= c('group','time'))%>%
  dplyr::left_join(ppm_state_sheep_farming, by= c('group','time'))%>%
  dplyr::left_join(ppm_state_cow_farming, by= c('group','time'))%>%
  dplyr::left_join(ppm_state_aquaculture, by= c('group','time'))
##saving f
saveRDS(ppm_state,
        file = "./data/ppm_state.rds"
)

#########
### Creating metadatabase -> IBGE - PPM
#########

#livestock_inventory
ppm_state_livestock_inventory= readRDS('data/ppm_state_livestock_inventory.rds')

dic_ppm_livestock_inventory= load_dictionary(dataset = 'ppm_livestock_inventory')%>%
  arrange(var_pt)
aux= c('','', rep('Efetivo dos Rebanhos ',10))
livestock_var= colnames(ppm_state_livestock_inventory)
livestock_var= livestock_var[-1]
livestock_var= livestock_var[-1]
livestock_var= sort(livestock_var)
livestock_var= c('group', 'time', livestock_var)
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
  categoria= c("Localiza?ao","Unidade de Tempo",rep("Pecuaria",10)), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',rep("Especies - Criacao",10))
) 
#saving f
write.csv(metadata_ppm_livestock_inventory, file = "./data/ppm_state_livestock_inventory_dic.csv", fileEncoding = "UTF-8")


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
  categoria= c("Localiza?ao","Unidade de Tempo",rep("Pecuaria",13)), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',rep("Produtos Pecuarios",13))
)
#saving f
write.csv(metadata_ppm_animal_origin_production, file = "./data/ppm_state_animal_origin_production_dic.csv", fileEncoding = "UTF-8")


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
  categoria= c("Localiza?ao","Unidade de Tempo","Pecuaria"), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',"Atividade Pecuaria")
) 
#saving f
write.csv(metadata_ppm_sheep_farming, file = "./data/ppm_state_sheep_farming_dic.csv", fileEncoding = "UTF-8")


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
  categoria= c("Localiza?ao","Unidade de Tempo","Pecuaria"), 
  subcategoria = c('Identificador Geografico','Ano da Pesquisa',"Atividade Pecuaria")
) 

#saving f
write.csv(metadata_ppm_cow_farming, file = "./data/ppm_state_cow_farming_dic.csv", fileEncoding = "UTF-8")


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
  categoria= c("Localiza?ao","Unidade de Tempo" ,rep("Pecuaria",48)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa" ,rep("Especies - Aquicultura",48))
)
#saving f
write.csv(metadata_ppm_aquaculture, file = "./data/ppm_state_aquaculture_dic.csv", fileEncoding = "UTF-8")

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
write.csv(metadata_ppm, file = "./data/ppm_state_dic.csv", fileEncoding = "UTF-8")