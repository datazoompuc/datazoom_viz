############################################################
#### Generate rds data in the folder ./data/ 
############################################################

#devtools::install_github("https://github.com/datazoompuc/datazoom.amazonia")


# packages --------------------------------------------------------------------------
library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(readxl)


# load data[ ------------------------------------------------------------------------
dat <- load_mapbiomas(dataset = "mapbiomas_cover", geo_level = "municipality", 
                      cover_level = "none")


#salva
saveRDS(dat, file = "data/mapbiomas_cobertura_munic_raw.rds")


# Data for level_4
data1 <- dat
data1$territory_id <- NULL
data1$level_0 <- NULL
data1$level_1 <- NULL
data1$level_2 <- NULL
data1$level_3 <- NULL
data1$color <- NULL
data1$class_id <- NULL
data1$group <- paste(data1$municipality, " - ",data1$state)
data1$municipality <- NULL
data1$state <- NULL

colnames(data1) <- c("time", "municipality_code", "aggregation", "area","group")

#tentando resolver problema do aggregate
data1$area <- as.numeric(data1$area)
data1 <- aggregate(area ~ time + municipality_code+ group + aggregation, data1, sum)


# Data for level_3
data2 <- dat
data2$territory_id <- NULL
data2$level_0 <- NULL
data2$level_1 <- NULL
data2$level_2 <- NULL
data2$level_4 <- NULL
data2$color <- NULL
data2$class_id <- NULL
data2$group <- paste(data2$municipality, " - ",data2$state)
data2$municipality <- NULL
data2$state <- NULL

colnames(data2) <- c("time","municipality_code", "aggregation", "area","group")

#tentando resolver problema do aggregate
data2$area <- as.numeric(data2$area)
data2 <- aggregate(area ~ time +  municipality_code+ group + aggregation, data2, sum)

# Data for level_2
data3 <- dat
data3$territory_id <- NULL
data3$level_0 <- NULL
data3$level_1 <- NULL
data3$level_3 <- NULL
data3$level_4 <- NULL
data3$color <- NULL
data3$class_id <- NULL
data3$group <- paste(data3$municipality, " - ",data3$state)
data3$municipality <- NULL
data3$state <- NULL

colnames(data3) <- c("time","municipality_code", "aggregation", "area","group")

#tentando resolver problema do aggregate
data3$area <- as.numeric(data3$area)

data3 <- aggregate(area ~ time +  municipality_code + group + aggregation, data3, sum)


# Data for level_1
data4 <- dat
data4$territory_id <- NULL
data4$level_0 <- NULL
data4$level_2 <- NULL
data4$level_3 <- NULL
data4$level_4 <- NULL
data4$color <- NULL
data4$class_id <- NULL
data4$group <- paste(data4$municipality, " - ",data4$state)
data4$municipality <- NULL
data4$state <- NULL

colnames(data4) <- c("time","municipality_code", "aggregation", "area","group")

#tentando resolver problema do aggregate
data4$area <- as.numeric(data4$area)

data4 <- aggregate(area ~ time +  municipality_code + group + aggregation, data4, sum)



# Data for level_0
data5 <- dat
data5$territory_id <- NULL
data5$level_1 <- NULL
data5$level_2 <- NULL
data5$level_3 <- NULL
data5$level_4 <- NULL
data5$color <- NULL
data5$class_id <- NULL
data5$group <- paste(data5$municipality, " - ",data5$state)
data5$municipality <- NULL
data5$state <- NULL

colnames(data5) <- c("time", "municipality_code","aggregation", "area","group")

#tentando resolver problema do aggregate
data5$area <- as.numeric(data5$area)

data5 <- aggregate(area ~ time  +  municipality_code+ group + aggregation, data5, sum)


data <- rbind(data1, data2, data3, data4, data5)

#num de colunas = quantidade de municipio
# num de linhas= anos*agregação, ou seja, moda a area de cada agregação para cada ano
# acho que os warnings ocorrem pq deve aparecer a mesma agregação em mais de uma dataX

datafinal <- pivot_wider(unique(data), names_from = aggregation, values_from = area,
                         values_fill = 0)


labl <- colnames(datafinal)
labl <- labl[-c(1,2,3)]
labl <- substr(labl, 6, 100)
sublabl <- labl[23:27]
sublabl <- substr(sublabl, 5, 100)
labl[23:27] <- sublabl



#para evitar que a ordem esteja descasada, renomeei as colunas uma por uma:
# removi a categoria "Nao aplicado" pois os resultados eram análogos ao "Não observado"
datafinal <- datafinal %>%
    select( time, municipality_code, group,                         
 "Aquicultura"= "Aquaculture"  ,         
 "Praia e Dunas"="Beach and Dune" ,  
 "Cítricos" = "Citrus",
   "Café"  = "Coffe"    ,
 "Algodão" = "Cotton",
 "Formação de Floresta" = "Forest Formation",
   " Plantação de Floresta" = "Forest Plantation"     ,            
  "Pradaria" = "Grassland"  ,                     
 "Mineiração"= "Mining" ,
 "Mosaico de Uso da Terra"="Land Use Mosaic",
 "Cana-de-açúcar" = "Sugar Cane" ,
"Mangue"= "Magrove"  ,
  "Salar" = "Salt flat",                        
  "Não observado"="Non Observed" ,                    
  "Outras formações naturais não florestais"= "Other Non Forest Natural Formation",
 "Outras áreas não vegetadas"= "Other Non Vegetated Area" ,        
  "Outras Culturas Perenes" =  "Other Perennial Crops" ,           
 "Outras Culturas Temporárias"=  "Other Temporary Crops"  ,           
 "Arroz" =  "Rice"    ,                     
 "Rios, Lagos ou Oceanos" =  "River, Lake and Ocean"  ,           
"Afloramento rochoso" =  "Rocky outcrop"  ,                   
  "Formação de Savana" =  "Savanna Formation"    ,           
  "Soja" =  "Soy Beans",
 "Pastagem" =  "Pasture" , 
"Infraestrutura Urbana" =  "Urban Infrastructure",
"Formação de Floresta"=  "Forest Formation" ,                     
"Pântano"=  "Wetland" ,                          
  "Restinga Arborizada"=  "Wooded Restinga" ,                 
  "Culturas Perenes"=  "Perennial Crops",                 
  "Culturas Temporárias" =  "Temporary Crops" ,                
 "Agricultura" =  "Agriculture"  ,                    
  "Floresta" =  "1. Forest"   ,                     
 "Formação Natural Não Florestal" =  "2. Non Forest Natural Formation"   ,
 "Fazenda" =  "3. Farming" ,                       
  "Áreas não vegetadas" =  "4. Non Vegetated Area" ,           
  "Água" = "5. Water"   ,                  
  "Antrópico" = "Anthropic"     ,                   
"Natural"=  "Natural"  )                     

datafinal[is.na(datafinal)] <- 0

#filtrar pra municipios da amazonia legal
municipios_amazonia<- datazoom.amazonia::municipalities
municipios_amazonia <- municipios_amazonia%>%
    filter(legal_amazon == 1)%>%
    select(municipality_code=code_muni)

datafinal <- datafinal%>%
    inner_join(municipios_amazonia)
    

saveRDS(datafinal, "data/mapbiomas_cobertura_munic.rds")

datafinal <- readRDS("data/mapbiomas_cobertura_munic.rds")

#####################
# Build Dictionary 
#####################

# extract variables from data
columns <- colnames(datafinal)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  label = columns,
  desc = columns,
  var_group = "Mapbiomas",
  tipo = 1,
  unidade = "m^2",
  categoria= "Meio ambiente", 
  subcategoria = "Uso da terra"
)

# tentando resolver a questão de terem várias linhas NA 
temp_param_table <-temp_param_table %>%
     drop_na()

# remover o codigo do municipio, pois nao será utilizado aqui
temp_param_table <- temp_param_table %>%
    filter(var != "municipality_code")


temp_param_table$label[1] <- "Ano"
temp_param_table$label[2] <- "Município"
temp_param_table$desc[1] <- "Ano"
temp_param_table$desc[2] <- "Município"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 37))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 37))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, 37))
temp_param_table$size <- c(FALSE, TRUE, rep(FALSE, 37))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 37))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_munic_dic.csv", fileEncoding = "UTF-8")


##############################
# Build Dictionary in English
##############################

#exclui a variável que não será utilizada na construção do dicionário
datafinal<-datafinal %>%
    select(-municipality_code)

# extract variables from data
columns <- colnames(datafinal)

# generate dictionary
temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    label = columns,
    desc = columns,
    var_group = "Mapbiomas",
    tipo = 1,
    unidade = "m^2",
    categoria= "Meio ambiente", 
    subcategoria = "Uso da terra"
)

temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Municipality"
temp_param_table$desc[1] <- "Year"
temp_param_table$desc[2] <- "Municipality"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 37))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 37))
temp_param_table$color <- c(FALSE, TRUE, rep(FALSE, 37))
temp_param_table$size <- c(FALSE, TRUE, rep(FALSE, 37))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 37))

temp_param_table$label[temp_param_table$var==	 "Aquicultura"]= "Aquaculture"  
temp_param_table$label[temp_param_table$var==	 "Praia e Dunas"]="Beach and Dune" 
temp_param_table$label[temp_param_table$var==	 "Cítricos"] = "Citrus"
temp_param_table$label[temp_param_table$var==	   "Café" ] = "Coffe"    
temp_param_table$label[temp_param_table$var==	 "Algodão" ]= "Cotton"
temp_param_table$label[temp_param_table$var==	 "Formação de Floresta"] = "Forest Formation"
temp_param_table$label[temp_param_table$var==	   " Plantação de Floresta" ]= "Forest Plantation"         
temp_param_table$label[temp_param_table$var==	  "Pradaria" ]= "Grassland"                  
temp_param_table$label[temp_param_table$var==	 "Mineiração"]= "Mining" 
temp_param_table$label[temp_param_table$var==	 "Mosaico de Uso da Terra"]="Land Use Mosaic"
temp_param_table$label[temp_param_table$var==	 "Cana-de-açúcar"] = "Sugar Cane" 
temp_param_table$label[temp_param_table$var==	"Mangue"]= "Magrove"  
temp_param_table$label[temp_param_table$var==	  "Salar"] = "Salt flat"                
temp_param_table$label[temp_param_table$var==	  "Não observado"]="Non Observed"                     
temp_param_table$label[temp_param_table$var==	  "Outras formações naturais não florestais"]= "Other Non Forest Natural Formation"
temp_param_table$label[temp_param_table$var==	 "Outras áreas não vegetadas"]= "Other Non Vegetated Area" 
temp_param_table$label[temp_param_table$var==	  "Outras Culturas Perenes"] =  "Other Perennial Crops"           
temp_param_table$label[temp_param_table$var==	 "Outras Culturas Temporárias"]=  "Other Temporary Crops"            
temp_param_table$label[temp_param_table$var==	 "Arroz"] =  "Rice"                        
temp_param_table$label[temp_param_table$var==	 "Rios, Lagos ou Oceanos"] =  "River, Lake and Ocean"            
temp_param_table$label[temp_param_table$var==	"Afloramento rochoso"] =  "Rocky outcrop"                     
temp_param_table$label[temp_param_table$var==	  "Formação de Savana" ]=  "Savanna Formation"              
temp_param_table$label[temp_param_table$var==	  "Soja"] =  "Soy Beans"
temp_param_table$label[temp_param_table$var==	 "Pastagem" ]=  "Pasture" 
temp_param_table$label[temp_param_table$var==	"Infraestrutura Urbana"] =  "Urban Infrastructure"
temp_param_table$label[temp_param_table$var==	"Formação de Floresta"]=  "Forest Formation"                     
temp_param_table$label[temp_param_table$var==	"Pântano"]=  "Wetland"                          
temp_param_table$label[temp_param_table$var==	  "Restinga Arborizada"]=  "Wooded Restinga"                 
temp_param_table$label[temp_param_table$var==	  "Culturas Perenes"]=  "Perennial Crops"                
temp_param_table$label[temp_param_table$var==	  "Culturas Temporárias" ]=  "Temporary Crops"                
temp_param_table$label[temp_param_table$var==	 "Agricultura"] =  "Agriculture"                     
temp_param_table$label[temp_param_table$var==	  "Floresta" ]=  "Forest"                       
temp_param_table$label[temp_param_table$var==	 "Formação Natural Não Florestal"] =  " Non Forest Natural Formation"   
temp_param_table$label[temp_param_table$var==	 "Fazenda" ]=  " Farming"                      
temp_param_table$label[temp_param_table$var==	  "Áreas não vegetadas" ]=  "Non Vegetated Area"           
temp_param_table$label[temp_param_table$var==	  "Água"] = "Water"                    
temp_param_table$label[temp_param_table$var==	  "Antrópico"] = "Anthropic"                       
temp_param_table$label[temp_param_table$var==	"Natural"]=  "Natural"    


# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_munic_dic_en.csv", fileEncoding = "UTF-8")

