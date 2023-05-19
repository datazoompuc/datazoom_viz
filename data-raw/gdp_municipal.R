############################################################
#### Generate rds data in the folder ./data/ 
############################################################

devtools::install_github("datazoompuc/datazoom.amazonia")
library(tidyverse)
library(datazoom.amazonia)

gdp_antigo <- readRDS(file = "./data/gdp.rds")

year_max <- max(gdp_antigo$Year)

gdp <- load_pibmunic(raw_data = F, 
                     time_period = year_max + 1, 
                     language = "pt",
                     geo_level = "municipality")

gdp <- gdp %>% mutate(Municipio = case_when(!is.na(Municipality) ~ Municipality, 
                                            TRUE ~ MunicÃ.pio)) 
gdp <- gdp %>% 
    select(-c("MunicÃ.pio", "Municipality")) %>% 
    rename(Municipality = Municipio)
    
#tabela puxada de "https://sidra.ibge.gov.br/tabela/6579"
population <- load_population(raw_data = F,
                                time_period = 2002:2020,
                                language = "pt",
                                geo_level = "municipality")

population <- population %>% 
    mutate(pop = case_when(!is.na(populacao_residente_v93) ~ populacao_residente_v93,
                                 !is.na(populacao_residente_estimada_v9324) ~ populacao_residente_estimada_v9324,
                                 TRUE ~ NA)) %>%
    select(-c("populacao_residente_v93","populacao_residente_estimada_v9324")) %>%
    rename(code_muni = geo_id, year = ano)

municipality <- arrange(municipalities, code_muni)

population$code_muni <- population$code_muni %>% as.integer()
municipality$code_muni <- municipality$code_muni %>% as.integer()



population_final <- inner_join(population, municipality, by = "code_muni") %>%
    mutate(Municipality = paste0(municipality_mapbiomas, " - ", abbrev_state)) %>%
    select(pop, code_muni, year, Municipality) %>%
    rename(Pop = pop, Year = year, CodIBGE = code_muni)
    
population_final$CodIBGE <- population_final$CodIBGE %>% as.character()
population_final$Pop <- population_final$Pop %>% as.numeric()
gdp_munic_2020$year <- gdp_munic_2020$year %>% as.integer()
gdp_munic_2020$produto_interno_bruto_a_precos_correntes_v37 <- gdp_munic_2020$produto_interno_bruto_a_precos_correntes_v37 %>% 
    as.numeric()

gdp_final <- population_final %>%
    inner_join(gdp, by = )
    mutate(GDPpc = GDP / Pop) %>%
    relocate(CodIBGE,Municipality, Year)


gdp_pc_2020$CodIBGE <- gdp_pc_2020$CodIBGE %>% as.integer() 

gdp_final <- gdp_antigo %>% 
    select(-X) %>%
    bind_rows(gdp_pc_2020)

    gdp_final <- gdp

#saving 
saveRDS(gdp_final,
        file = "./data/gdp.rds")