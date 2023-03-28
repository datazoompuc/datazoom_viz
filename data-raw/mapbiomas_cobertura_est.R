############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(datazoom.amazonia)
library(tidyverse)
library(tibble)
library(zoo)
library(readxl)

# load data ------------------------------------------------------------------------
# carrega por municipio, pois filtraremos os municipios que participam da amazonia legal
# antes de agregar por UF

dat <- load_mapbiomas(dataset = "mapbiomas_cover", geo_level = "municipality", 
                      cover_level = "none")



saveRDS(dat, file = "data/mapbiomas_cobertura_est_raw.rds")

# Data for level_4
data1 <- dat
data1$territory_id <- NULL
data1$level_0 <- NULL
data1$level_1 <- NULL
data1$level_2 <- NULL
data1$level_3 <- NULL
data1$color <- NULL
data1$class_id <- NULL
data1$municipality <- NULL

# filtra os municipios que participam da Amazonia Legal

municipios_amazonia<- datazoom.amazonia::municipalities
municipios_amazonia <- municipios_amazonia%>%
    filter(legal_amazon == 1)%>%
    select(municipality_code=code_muni)

data1 <- data1%>%
    inner_join(municipios_amazonia)

data1$municipality_code <- NULL

#agrega por UF
colnames(data1) <- c("time","state", "group","area" )
data1 <- aggregate(area ~ time + state + group, data1, sum)


# Data for level_3
data2 <- dat
data2$territory_id <- NULL
data2$level_0 <- NULL
data2$level_1 <- NULL
data2$level_2 <- NULL
data2$level_4 <- NULL
data2$color <- NULL
data2$class_id <- NULL
data2$municipality <- NULL

# filtra os municipios que participam da Amazonia Legal

municipios_amazonia<- datazoom.amazonia::municipalities
municipios_amazonia <- municipios_amazonia%>%
    filter(legal_amazon == 1)%>%
    select(municipality_code=code_muni)

data2 <- data2%>%
    inner_join(municipios_amazonia)

data2$municipality_code <- NULL

#agrega por UF
colnames(data2) <- c("time","state", "group","area" )
data2 <- aggregate(area ~ time + state + group, data2, sum)


# Data for level_2
data3 <- dat
data3$territory_id <- NULL
data3$level_0 <- NULL
data3$level_1 <- NULL
data3$level_3 <- NULL
data3$level_4 <- NULL
data3$color <- NULL
data3$class_id <- NULL
data3$municipality <- NULL

# filtra os municipios que participam da Amazonia Legal

municipios_amazonia<- datazoom.amazonia::municipalities
municipios_amazonia <- municipios_amazonia%>%
    filter(legal_amazon == 1)%>%
    select(municipality_code=code_muni)

data3 <- data3%>%
    inner_join(municipios_amazonia)

data3$municipality_code <- NULL

#agrega por UF
colnames(data3) <- c("time","state", "group","area" )
data3 <- aggregate(area ~ time + state + group, data3, sum)



# Data for level_1
data4 <- dat
data4$territory_id <- NULL
data4$level_0 <- NULL
data4$level_2 <- NULL
data4$level_3 <- NULL
data4$level_4 <- NULL
data4$color <- NULL
data4$class_id <- NULL
data4$municipality <- NULL

# filtra os municipios que participam da Amazonia Legal

municipios_amazonia<- datazoom.amazonia::municipalities
municipios_amazonia <- municipios_amazonia%>%
    filter(legal_amazon == 1)%>%
    select(municipality_code=code_muni)

data4 <- data4%>%
    inner_join(municipios_amazonia)

data4$municipality_code <- NULL

#agrega por UF
colnames(data4) <- c("time","state", "group","area" )
data4 <- aggregate(area ~ time + state + group, data4, sum)



# Data for level_0
data5 <- dat
data5$territory_id <- NULL
data5$level_1 <- NULL
data5$level_2 <- NULL
data5$level_3 <- NULL
data5$level_4 <- NULL
data5$color <- NULL
data5$class_id <- NULL
data5$municipality <- NULL

# filtra os municipios que participam da Amazonia Legal

municipios_amazonia<- datazoom.amazonia::municipalities
municipios_amazonia <- municipios_amazonia%>%
    filter(legal_amazon == 1)%>%
    select(municipality_code=code_muni)

data5 <- data5%>%
    inner_join(municipios_amazonia)

data5$municipality_code <- NULL

#agrega por UF
colnames(data5) <- c("time","state", "group","area" )
data5 <- aggregate(area ~ time + state + group, data5, sum)


# juntando as bases e criando o df final
data <- rbind(data1, data2, data3, data4, data5)

datafinal <- pivot_wider(unique(data), names_from = group, values_from = area,
                         values_fill = 0)


labl <- colnames(datafinal)
labl <- labl[-c(1,2)]
labl <- substr(labl, 6, 100)
sublabl <- labl[22:26]
sublabl <- substr(sublabl, 5, 100)
#para evitar que a ordem esteja descasada, renomeei as colunas uma por uma:
# removi a categoria "Nao aplicado" pois os resultados eram análogos ao "Não observado"
datafinal <- datafinal %>%
    select( time, state,                         
            "Praia e Dunas"="Beach and Dune" ,  
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
            "Culturas Perenes"=  "Perennial Crops",                 
            "Culturas Temporárias" =  "Temporary Crops" ,                
            "Agricultura" =  "Agriculture"  ,                    
            "Floresta" =  "1. Forest"   ,                     
            "Formação Natural Não Florestal" =  "2. Non Forest Natural Formation"   ,
            "Fazenda" =  "3. Farming" ,                       
            "Áreas não vegetadas" =  "4. Non Vegetated Area" ,           
            "Água" = "5. Water" ,                 
            "Antrópico" = "Anthropic" ,                  
            "Natural"=  "Natural"   )               

datafinal[is.na(datafinal)] <- 0

saveRDS(datafinal, "data/mapbiomas_cobertura_est.rds")

datafinal <- readRDS("data/mapbiomas_cobertura_est.rds")

datafinal <-datafinal %>%
    select(group = state, everything())

####################
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

temp_param_table$label[1] <- "UF"
temp_param_table$label[2] <- "Ano"
temp_param_table$desc[1] <- "UF"
temp_param_table$desc[2] <- "Ano"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 32))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 32))
temp_param_table$color <- c(rep(TRUE, 1), rep(FALSE, 33))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 32))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 32))

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_est_dic.csv", fileEncoding = "UTF-8")


##############################
# Build Dictionary in English
#############################

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

temp_param_table$label[1] <- "State"
temp_param_table$label[2] <- "Year"
temp_param_table$desc[1] <- "State"
temp_param_table$desc[2] <- "Year"
temp_param_table$x <- c(rep(FALSE, 2), rep(TRUE, 32))
temp_param_table$y <- c(rep(FALSE, 2), rep(TRUE, 32))
temp_param_table$color <- c(rep(TRUE, 1), rep(FALSE, 33))
temp_param_table$size <- c(rep(FALSE, 2), rep(TRUE, 32))
temp_param_table$slider <- c(rep(FALSE, 2), rep(TRUE, 32))


temp_param_table$label[temp_param_table$var==	"Praia e Dunas"]="Beach and Dune"
temp_param_table$label[temp_param_table$var==	            "Algodão"]= "Cotton"
 temp_param_table$label[temp_param_table$var==	            "Formação de Floresta"]= "Forest Formation"
temp_param_table$label[temp_param_table$var==	            " Plantação de Floresta"]= "Forest Plantation"               
temp_param_table$label[temp_param_table$var==	            "Pradaria"]= "Grassland"                    
temp_param_table$label[temp_param_table$var==	            "Mineiração"]= "Mining" 
temp_param_table$label[temp_param_table$var==	            "Mosaico de Uso da Terra"]="Land Use Mosaic"
temp_param_table$label[temp_param_table$var==	            "Cana-de-açúcar"]= "Sugar Cane" 
temp_param_table$label[temp_param_table$var==	            "Mangue"]= "Magrove"  
temp_param_table$label[temp_param_table$var==	            "Salar"]= "Salt flat"                       
temp_param_table$label[temp_param_table$var==	            "Não observado"]="Non Observed"                  
temp_param_table$label[temp_param_table$var==	            "Outras áreas não vegetadas"]= "Other Non Vegetated Area"      
temp_param_table$label[temp_param_table$var==	            "Outras Culturas Perenes"]=  "Other Perennial Crops"         
temp_param_table$label[temp_param_table$var==	            "Outras Culturas Temporárias"]=  "Other Temporary Crops"          
temp_param_table$label[temp_param_table$var==	            "Arroz"]=  "Rice"                      
temp_param_table$label[temp_param_table$var==	            "Rios, Lagos ou Oceanos"]=  "River, Lake and Ocean"          
temp_param_table$label[temp_param_table$var==	            "Afloramento rochoso"]=  "Rocky outcrop"                  
temp_param_table$label[temp_param_table$var==	            "Formação de Savana"]=  "Savanna Formation"            
 temp_param_table$label[temp_param_table$var==	            "Soja"]=  "Soy Beans"
temp_param_table$label[temp_param_table$var==	            "Pastagem"]=  "Pasture"  
temp_param_table$label[temp_param_table$var==	            "Infraestrutura Urbana"]=  "Urban Infrastructure"
temp_param_table$label[temp_param_table$var==	            "Formação de Floresta"]=  "Forest Formation"                   
temp_param_table$label[temp_param_table$var==	            "Pântano"]=  "Wetland"                        
temp_param_table$label[temp_param_table$var==	            "Culturas Perenes"]=  "Perennial Crops"                 
temp_param_table$label[temp_param_table$var==	            "Culturas Temporárias"]=  "Temporary Crops"              
temp_param_table$label[temp_param_table$var==	            "Agricultura"]=  "Agriculture"                   
temp_param_table$label[temp_param_table$var==	            "Floresta"]=  " Forest"                     
temp_param_table$label[temp_param_table$var==	            "Formação Natural Não Florestal"]=  " Non Forest Natural Formation"  
temp_param_table$label[temp_param_table$var==	            "Fazenda"]=  " Farming"                     
temp_param_table$label[temp_param_table$var==	            "Áreas não vegetadas"]=  " Non Vegetated Area"         
temp_param_table$label[temp_param_table$var==	            "Água"]= " Water"                  
temp_param_table$label[temp_param_table$var==	            "Antrópico"]= "Anthropic"                     
temp_param_table$label[temp_param_table$var==	            "Natural"]=  "Natural" 
                               

                       
                       

View(temp_param_table)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/mapbiomas_cobertura_est_dic_en.csv", fileEncoding = "UTF-8")

