### Creating metadatabase -> IBGE - PAM

#pam_all_crops f
pam_state_all_crops= readRDS('data/pam_state_all_crops.rds')


dic_pam_all_crops= load_dictionary(dataset= 'pam_all_crops')%>%
  arrange(var_code)
met_all_crops= NULL
met_all_crops=
  for(i in 1:1){
    met_all_crops= c(met_all_crops, rep(dic_pam_all_crops$var_pt[i],5))
  }
for(j in 2:67){
  met_all_crops= c(met_all_crops, rep(dic_pam_all_crops$var_pt[j],5))
}
for(k in 68:71){
  met_all_crops= c(met_all_crops, rep(dic_pam_all_crops$var_pt[k],4))
}
for(h in 72:72){
  met_all_crops= c(met_all_crops, rep(dic_pam_all_crops$var_pt[h],5))
}
met_all_crops= c("Identificador Geografico", "Ano da Pesquisa", "Total", "Total", "Total",met_all_crops)
vec_all= c(c('Area Colhida ', 'Area Plantada ou Destinada a Colheita ','Valor '),rep(c('Area Colhida ', 'Area Plantada ou Destinada a Colheita ', 'Quantidade ', 'Rendimento Medio ','Valor '),66), rep(c('Area Colhida ', 'Quantidade ', 'Rendimento Medio','Valor '),4), c('Area Colhida ', 'Area Plantada ou Destinada a Colheita ', 'Quantidade ', 'Rendimento Medio ','Valor '))
vec_all= c('','',vec_all)
label_all_crops= paste0(vec_all,met_all_crops)

all_crops_var= colnames(pam_state_all_crops)
metadata_pam_all_crops= tibble::tibble(
  var = all_crops_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_all_crops,
  source = "IBGE",
  tipo = 1,
  unidade = c(NA, NA, c('Hectares', 'Hectares', '1K BRL'), rep(c('Hectares', 'Hectares', 'Tons', 'Kg/Hectares','1K BRL'),66), rep(c('Hectares','Tons','Kg/Hectares','1K BRL'),4), c('Hectares', 'Hectares', 'Tons', 'Kg/Hectares','1K BRL')),
  categoria= c("Localização","Unidade de Tempo" , rep("Agricultura",354)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa",rep("Especies - Cultivo",354))
)

#saving f
write.csv(metadata_pam_all_crops, file = "./data/metadata_pam_all_crops.csv", fileEncoding = "UTF-8")


#pam_permanent_crops
pam_state_permanent_crops= readRDS('data/pam_state_permanent_crops.rds')


dic_pam_permanent_crops= load_dictionary(dataset= 'pam_permanent_crops')
permanent_crops_var= colnames(pam_state_permanent_crops)
metadata_pam_permanent_crops= tibble::tibble(
  var = dic_pam_permanent_crops$var_code,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = dic_pam_permanent_crops$var_pt,
  source = "IBGE",
  tipo = 1,
  unidade = dic_pam_permanent_crops$unit_quantity,
  unidade_valor= dic_pam_permanent_crops$unit_value,
  categoria= "Agricultura", 
  subcategoria = "Especies - Cultivo "
)
#saving
write.csv(metadata_pam_permanent_crops, file = "./data/metadata_pam_permanent_crops.csv", fileEncoding = "UTF-8")


#pam_temporary_crops f
pam_state_temporary_crops= readRDS('data/pam_state_temporary_crops.rds')


dic_pam_temporary_crops= load_dictionary(dataset= 'pam_temporary_crops')%>%
  arrange(var_code)
met_temporary_crops= NULL
met_temporary_crops=
  for(i in 1:1){
    met_temporary_crops= c(met_temporary_crops, rep(dic_pam_temporary_crops$var_pt[i],3))  
  }
for(j in 33:34){
  met_temporary_crops= c(met_temporary_crops, rep(dic_pam_temporary_crops$var_pt[j],5))
}
for(k in 2:30){
  met_temporary_crops= c(met_temporary_crops, rep(dic_pam_temporary_crops$var_pt[k],5))
}
for(h in 31:32){
  met_temporary_crops= c(met_temporary_crops, rep(dic_pam_temporary_crops$var_pt[h],4))
}
met_temporary_crops= c("Identificador Geografico", "Ano da Pesquisa", "Total", "Total", "Total",met_temporary_crops)
vec_temporary= c(c('Area Colhida ', 'Area Plantada ','Valor '),rep(c('Area Colhida ', 'Area Plantada ', 'Quantidade ', 'Rendimento Medio ','Valor '),31), rep(c('Area Colhida ', 'Quantidade ', 'Rendimento Medio ','Valor'),2))
vec_temporary= c('','',vec_temporary)
label_temporary_crops= paste0(vec_temporary,met_temporary_crops)

temporary_crops_var= colnames(pam_state_temporary_crops)
metadata_pam_temporary_crops= tibble::tibble(
  var = temporary_crops_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_temporary_crops,
  source = "IBGE",
  tipo = 1,
  unidade = c(NA, NA, 'Hectares', 'Hectares', '1K BRL', rep(c('Hectares', 'Hectares', 'Tons', 'Kg/Hectares', '1K BRL'),31), rep(c('Hectares', 'Tons', 'Kg/Hectares','1K BRL'),2)),
  categoria= c('Localizacao','Unidade de Tempo',rep("Agricultura",166)), 
  subcategoria = c('Identificador Geografico','Anual',rep("Especies - Cultivo",166))
)
#saving f
write.csv(metadata_pam_temporary_crops, file = "./data/metadata_pam_temporary_crops.csv", fileEncoding = "UTF-8")

dic_pam_corn= load_dictionary(dataset= 'pam_corn')
dic_pam_potato= load_dictionary(dataset= 'pam_potato')
dic_pam_peanut= load_dictionary(dataset= 'pam_peanut')
dic_pam_beans= load_dictionary(dataset= 'pam_beans')

#pam_beans
pam_state_beans= readRDS('data/pam_state_beans.rds')


vec= rep(c('Area Colhida ', 'Area Plantada ', 'Quantidade ', 'Rendimento Medio '),4)
vec= c('','',vec)
met_beans= c("Identificador Geografico", "Ano da Pesquisa", rep("Feijao em Grao (Primeira Safra)",4), rep("Feijao em Grao (Segunda Safra)",4), rep("Feijao em Grao (Terceira Safra)",4), rep("Feijao em Grao (Total)",4))
label_beans= paste0(vec,met_beans)
beans_var= colnames(pam_state_beans)

metadata_pam_beans= tibble::tibble(
  var = beans_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_beans,
  source = "IBGE",
  tipo = 1,
  unidade = c(NA, NA, rep(c("Hectares","Hectares","Tons","Kg/Hectares"),4)),
  categoria= c("Localização","Unidade de Tempo" , rep("Agricultura",16)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa",rep("Especies - Cultivo",16))
)

#saving f
write.csv(metadata_pam_beans, file = "./data/metadata_pam_beans.csv", fileEncoding = "UTF-8")

#pam_corn
pam_state_corn= readRDS('data/pam_state_corn.rds')


vec2= rep(c('Area Colhida ', 'Area Plantada ', 'Quantidade ', 'Rendimento Medio '),3)
vec2= c('','',vec2)
met_corn=c("Identificador Geografico", "Ano da Pesquisa", rep("Milho em Grao (Primeira Safra)",4), rep("Milho em Grao (Segunda Safra)",4), rep("Feijao em Grao (Total)",4))
label_corn= paste0(vec2,met_corn)
corn_var= colnames(pam_state_corn)

metadata_pam_corn= tibble::tibble(
  var = corn_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_corn,
  source = "IBGE",
  tipo = 1,
  unidade = c(NA, NA, rep(c("Hectares","Hectares","Tons","Kg/Hectares"),3)),
  categoria= c("Localização","Unidade de Tempo" , rep("Agricultura",12)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa",rep("Especies - Cultivo",12))
)
#saving f
write.csv(metadata_pam_corn, file = "./data/metadata_pam_corn.csv", fileEncoding = "UTF-8")


#pam_potato
pam_state_potato= readRDS('data/pam_state_potato.rds')


vec= rep(c('Area Colhida ', 'Area Plantada ', 'Quantidade ', 'Rendimento Medio '),4)
vec= c('','',vec)
met_potato= c("Identificador Geografico", "Ano da Pesquisa", rep("Batata Inglesa (Primeira Safra)",4), rep("Batata Inglesa (Segunda Safra)",4), rep("Batata Inglesa (Terceira Safra)",4), rep("Batata Inglesa (Total)",4))
label_potato= paste0(vec,met_potato)
potato_var= colnames(pam_state_potato)

metadata_pam_potato= tibble::tibble(
  var = potato_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_potato,
  source = "IBGE",
  tipo = 1,
  unidade = c(NA, NA, rep(c("Hectares","Hectares","Tons","Kg/Hectares"),4)),
  categoria= c("Localização","Unidade de Tempo" , rep("Agricultura",16)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa",rep("Especies - Cultivo",16))
)
#saving f
write.csv(metadata_pam_potato, file = "./data/metadata_pam_potato.csv", fileEncoding = "UTF-8")


#pam_peanut
pam_state_peanut= readRDS('data/pam_state_peanut.rds')


vec2= rep(c('Area Colhida ', 'Area Plantada ', 'Quantidade ', 'Rendimento Medio '),3)
vec2= c('','',vec2)
met_peanut= c("Identificador Geografico", "Ano da Pesquisa", rep("Amendoim em Casca (Primeira Safra)",4), rep("Amendoim em Casca (Segunda Safra)",4), rep("Amendoim em Casca (Total)",4))
label_peanut= paste0(vec2,met_peanut)
peanut_var= colnames(pam_state_peanut)

metadata_pam_peanut= tibble::tibble(
  var = peanut_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_peanut,
  source = "IBGE",
  tipo = 1,
  unidade = c(NA, NA, rep(c("Hectares","Hectares","Tons","Kg/Hectares"),3)),
  categoria= c("Localização","Unidade de Tempo" , rep("Agricultura",12)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa",rep("Especies - Cultivo",12))
)
#saving f
write.csv(metadata_pam_peanut, file = "./data/metadata_pam_peanut.csv", fileEncoding = "UTF-8")
