##########
### Generate data -> IBGE - PAM
##########
## Agregation level - MUNICIPALITY

#install newer version of datazoom.amazonia
devtools::install_github("datazoompuc/datazoom.amazonia")

#libraries
library(tidyverse)
library(datazoom.amazonia)
library(labelled)
library(here)

##########################################
##   update-and-download-pam function   ##
##########################################

update_download_pam <- function(geo_level, dataset, time_period){
    
    #define empty vectors
    time_period <- time_period
    year_vector <- c()
    year_exists_vector <- c()
        
    #check for existing files (the whole file with all the years, not yearly files)
    if(file.exists(
            paste0("./data/pam_", geo_level, "_", dataset, ".rds")
            )[1]
        ){
        
        #reads existing file
        pam_old <- readRDS(paste0("./data/pam_", geo_level, "_",dataset,".rds")) %>%
            labelled::remove_labels() #remove variable labels (for binding)
        
        #makes all variables class numeric
        pam_old <- pam_old %>% mutate_all(~as.numeric(.))
        
        #get the names of the variables from the old dataset (we want the year variable)
        old_variables <- colnames(pam_old)
        
        #get the bigger year from the old dataset as a number
        year_max <- max(pam_old$ano) %>% 
            as.numeric()
        
        #download the next year of pam (notice the 'year_max + 1' in the time period argument)
        pam_update <- load_pam(dataset = dataset, raw_data = FALSE, geo_level = geo_level, time_period = year_max + 1, language = "pt") %>%
            labelled::remove_labels() #remove variable labels (for binding)
        
        #makes all variables class numeric
        pam_update <- pam_update %>% mutate_all(~as.numeric(.))
        
        #bind rows of new and old pam
        pam_new <- bind_rows(pam_update, pam_old) %>% 
            #select the variables that already were there
            select(contains(old_variables))
        
        #change numerical variables to class numeric
        pam_new$ano <- pam_new$ano %>% as.numeric()
        pam_new$geo_id <- pam_new$geo_id %>% as.numeric()
        
        saveRDS(pam_new, file = paste0("./data/pam_", geo_level,"_", dataset,".rds"))
        
    } else #if the file doesnt exist, proceed here
        { 
            #makes a loop to check it there is yearly files for the dataset and municipality
            #(if this part of the code doesn't make sense, keep reading and come back here later)
            for(year_h in time_period){
                
                #saves all the years that are not downloaded
                if((!file.exists("./data/pam_", geo_level, "_", dataset, year_h, ".rds"))[1]){
                    year_vector <- c(year_vector, year_h)
                   
                } else {
                    
                    #saves all the years that are already downloaded
                    year_exists_vector <- c(year_exists_vector, year_h)
                    
                }
            }
            
        #create a loop that saves each year as a file
        for(year_i in year_vector){
            
            #download one year of the pam dataset and geolevel requested
            pam_yearly = load_pam(dataset = dataset, raw_data = FALSE, geo_level = geo_level, time_period = year_i, language = "pt")
            
            #save the file for that year
            saveRDS(pam_yearly, file = paste0(file.path("data"),"/pam_", geo_level,"_", dataset, year_i, ".rds"))
            
        }
        
        #vector with all download years 
            #(year_exists_vector contains years download previously)
            #(year_vector contains years download now)
        year_vector_total <- c(year_exists_vector, year_vector)
        
        #define an empty data.frame
        pam_new <- data.frame()
        
        #bind yearly files to create new big file with all the years
        for(year_j in year_vector_total){
            
            #read an yearly file
            pam_df <- readRDS(file = paste0("./data/pam_", geo_level,"_", dataset, year_j, ".rds")) %>%  
                remove_labels()
            
            #makes all variables class numeric
            pam_df <- pam_df %>% mutate_all(~as.numeric(.))
            
            #bind the rows of this file with previously binded years
            pam_new <- bind_rows(pam_new, pam_df)
            
            #makes all variables class numeric
            pam_new <- pam_new %>% mutate_all(~as.numeric(.))
            
            #saves the final data.frame as a .rds file
            saveRDS(pam_new, file = paste0("./data/pam_", geo_level,"_", dataset,".rds"))
            
            #remove all yearly files
            for(year_k in year_vector_total){
                #Define file path
                file <- paste0("./data/pam_", geo_level,"_", dataset, year_k, ".rds")
                
                #Remove file
                file.remove(file)
        }
        }
    }
    return(pam_new)
}

##########################
##   use pam function   ##
##########################

#dataset all_crops
update_download_pam(dataset = "all_crops", geo_level = "municipality", time_period = 1974:2024)

#dataset permanent_crops
update_download_pam(dataset = "permanent_crops", geo_level = "municipality", time_period = 1974:2021)

#dataset temporary_crops
update_download_pam(dataset = "temporary_crops", geo_level = "municipality", time_period = 1974:2021)

#dataset corn
update_download_pam(dataset = "corn", geo_level = "municipality", time_period = 1974:2021)

#dataset potato
update_download_pam(dataset = "potato", geo_level = "municipality", time_period = 1974:2021)

#dataset peanut
update_download_pam(dataset = "peanut", geo_level = "municipality", time_period = 1974:2021)

#dataset beans
update_download_pam(dataset = "beans", geo_level = "municipality", time_period = 1974:2021)

#########
### Creating metadatabase -> IBGE - PAM
#########

#pam_all_crops 
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
  categoria= c("Localiza?ao","Unidade de Tempo" , rep("Agricultura",354)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa",rep("Especies - Cultivo",354))
)

#saving 
write.csv(metadata_pam_all_crops, file = "./data/pam_municipality_all_crops_dic.csv", fileEncoding = "UTF-8")


#pam_permanent_crops
pam_state_permanent_crops= readRDS('data/pam_state_permanent_crops.rds')

dic_pam_permanent_crops= load_dictionary(dataset= 'pam_permanent_crops')%>%
  dplyr::arrange(var_code)  

met_permanent_crops= NULL
met_permanent_crops= c(met_permanent_crops, rep(dic_pam_permanent_crops$var_pt[1],3))  
for(j in 2:35){
  met_permanent_crops= c(met_permanent_crops, rep(dic_pam_permanent_crops$var_pt[j],5))
}
for(k in 36:37){
  met_permanent_crops= c(met_permanent_crops, rep(dic_pam_permanent_crops$var_pt[k],4))
}
for(h in 38:39){
  met_permanent_crops= c(met_permanent_crops, rep(dic_pam_permanent_crops$var_pt[h],5))
}
met_permanent_crops= c("Identificador Geografico", "Ano da Pesquisa",met_permanent_crops)
vec_permanent= c(c('Area Colhida ', 'Valor ', 'Area Destinada a Colheita '),rep(c('Area Colhida ', 'Quantidade ', 'Rendimento Medio ','Valor ',  'Area Destinada a Colheita '),34), rep(c('Area Colhida ', 'Quantidade ', 'Rendimento Medio ','Valor '),2),rep(c('Area Colhida ', 'Quantidade ', 'Rendimento Medio ','Valor ',  'Area Destinada a Colheita '),2))
vec_permanent= c('','', vec_permanent)
label_permanent_crops= paste0(vec_permanent,met_permanent_crops)


permanent_crops_var= colnames(pam_state_permanent_crops)
metadata_pam_permanent_crops= tibble::tibble(
  var = permanent_crops_var,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = label_permanent_crops,
  source = "IBGE",
  tipo = 1,
  unidade = c(NA, NA, 'Hectares', '1K BRL', 'Hectares', rep(c('Hectares', 'Tons', 'Kg/Hectares', '1K BRL', 'Hectares'),34), rep(c('Hectares', 'Tons', 'Kg/Hectares','1K BRL'),2), rep(c('Hectares', 'Tons', 'Kg/Hectares','1K BRL', 'Hectares'),2)),
  categoria= c('Localizacao','Unidade de Tempo',rep("Agricultura",191)), 
  subcategoria = c('Identificador Geografico','Anual',rep("Especies - Cultivo",191))
)
#saving 
write.csv(metadata_pam_permanent_crops, file = "./data/pam_municipality_permanent_crops_dic.csv", fileEncoding = "UTF-8")


#pam_temporary_crops 
pam_state_temporary_crops= readRDS('data/pam_state_temporary_crops.rds')


dic_pam_temporary_crops= load_dictionary(dataset= 'pam_temporary_crops')%>%
  dplyr::arrange(var_code)
met_temporary_crops= NULL
met_temporary_crops= c(met_temporary_crops, rep(dic_pam_temporary_crops$var_pt[1],3)) 
for(j in 33:34){
  met_temporary_crops= c(met_temporary_crops, rep(dic_pam_temporary_crops$var_pt[j],5))
}
for(k in 2:30){
  met_temporary_crops= c(met_temporary_crops, rep(dic_pam_temporary_crops$var_pt[k],5))
}
for(h in 31:32){
  met_temporary_crops= c(met_temporary_crops, rep(dic_pam_temporary_crops$var_pt[h],4))
}
met_temporary_crops= c("Identificador Geografico", "Ano da Pesquisa",met_temporary_crops)
vec_temporary= c(c('Area Colhida ', 'Area Plantada ','Valor '),rep(c('Area Colhida ', 'Area Plantada ', 'Quantidade ', 'Rendimento Medio ','Valor '),31), rep(c('Area Colhida ', 'Quantidade ', 'Rendimento Medio ','Valor '),2))
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
#saving 
write.csv(metadata_pam_temporary_crops, file = "./data/pam_municipality_temporary_crops_dic.csv", fileEncoding = "UTF-8")

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
  categoria= c("Localiza?ao","Unidade de Tempo" , rep("Agricultura",16)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa",rep("Especies - Cultivo",16))
)

#saving 
write.csv(metadata_pam_beans, file = "./data/pam_municipality_beans_dic.csv", fileEncoding = "UTF-8")

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
  categoria= c("Localiza?ao","Unidade de Tempo" , rep("Agricultura",12)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa",rep("Especies - Cultivo",12))
)
#saving 
write.csv(metadata_pam_corn, file = "./data/pam_municipality_corn_dic.csv", fileEncoding = "UTF-8")


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
  categoria= c("Localiza?ao","Unidade de Tempo" , rep("Agricultura",16)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa",rep("Especies - Cultivo",16))
)
#saving 
write.csv(metadata_pam_potato, file = "./data/pam_municipality_potato_dic.csv", fileEncoding = "UTF-8")


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
  categoria= c("Localiza?ao","Unidade de Tempo" , rep("Agricultura",12)), 
  subcategoria = c("Identificador Geografico","Ano da Pesquisa",rep("Especies - Cultivo",12))
)
#saving 
write.csv(metadata_pam_peanut, file = "./data/pam_municipality_peanut_dic.csv", fileEncoding = "UTF-8")
