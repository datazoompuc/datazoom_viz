############################################################
#### Generate rds data in the folder ./data/ 
############################################################

devtools::install_github("datazoompuc/datazoom.amazonia")
library(tidyverse)
library(datazoom.amazonia)
library(labelled)

#Loading old gdp.rds file
gdp_antigo <- readRDS(file = "./data/gdp.rds")

#Defining the most recent year downloaded
year_max <- max(gdp_antigo$ano)

#Loading a more recent year of gdp data
gdp <- load_pibmunic(raw_data = F, 
                     time_period = 2002:2021, 
                     language = "pt",
                     geo_level = "municipality")

#Selecting variables and renaming them
gdp <- gdp %>% 
    select(c("ano", "geo_id", "produto_interno_bruto_a_precos_correntes_v37")) %>% 
    rename(cod_ibge = geo_id, gdp = produto_interno_bruto_a_precos_correntes_v37) %>%
    remove_labels()

#Harmonizing variable classes
class(gdp$ano) <- "numeric"
class(gdp$gdp) <- "numeric"

#Loading a more recent year of population data
population <- load_population(raw_data = F,
                                time_period = year_max + 1,
                                language = "pt",
                                geo_level = "municipality")


if("populacao_residente_v93" %in% colnames(population)){
    if("populacao_residente_estimada_v9324" %in% colnames(population)){
        
        #If there are both "populacao_residente_v93" and "populacao_residente_estimada_v9324"
        #Combine them into "pop"
    population <- population %>% 
            mutate(pop = case_when(!is.na(populacao_residente_v93) ~ populacao_residente_v93,
                                   !is.na(populacao_residente_estimada_v9324) ~ populacao_residente_estimada_v9324,
                                   TRUE ~ NA)) %>%
            select(-c("populacao_residente_v93","populacao_residente_estimada_v9324"))
    
    } else {
        
        #If there is no "populacao_residente_estimada_v9324", there must be only "populacao_residente_v93"
        #Therefore, proceed to rename it to "pop"
        population <- population %>% 
            rename(pop = populacao_residente_v93)
    }
} else {
    
    #If there is no "populacao_residente_v93", there must be only "populacao_residente_estimada_v9324"
    #Therefore, proceed to rename it to "pop"
    population <- population %>% 
        rename("pop" = "populacao_residente_estimada_v9324")
}

#Rename variables
population <- population %>%
    rename(cod_ibge = geo_id)

#Load dataset (from datazoom.amazonia) with municipalities' info
municipality <- arrange(municipalities, code_muni) %>%
    rename(cod_ibge = code_muni)

#Harmonizing variables for merging
population$cod_ibge <- population$cod_ibge %>% as.character()
population$pop <- population$pop %>% as.numeric()
population$ano <- population$ano %>% as.integer()

municipality$cod_ibge <- municipality$cod_ibge %>% as.character()

gdp$cod_ibge <- gdp$cod_ibge %>% as.character()
gdp$ano <- gdp$ano %>% as.integer()
gdp$gdp <- gdp$gdp %>% as.numeric()

#Merging population and municipality datasets
population_final <- inner_join(population, municipality, by = "cod_ibge") %>%
    mutate(Municipality = paste0(municipality_mapbiomas, " - ", abbrev_state)) %>%
    select(pop, cod_ibge, ano, Municipality)

#Merging previously merged dataset and gdp dataset
gdp_final <- population_final %>%
    inner_join(gdp, by = c("cod_ibge", "ano")) %>%
    mutate(gd_ppc = gdp*1000/pop) %>%
    relocate(cod_ibge,Municipality, ano, pop)

#Binding rows of new and old final dataset
gdp_final <- gdp_final %>% 
    bind_rows(gdp_antigo)

#saving 
saveRDS(gdp_final,
        file = "./data/gdp.rds")