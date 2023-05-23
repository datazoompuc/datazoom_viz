############################################################
#### Generate rds data in the folder ./data/ 
############################################################

devtools::install_github("datazoompuc/datazoom.amazonia")
library(tidyverse)
library(datazoom.amazonia)

gdp_antigo <- readRDS(file = "./data/gdp.rds")

year_max <- max(gdp_antigo$Year)

gdp <- load_pibmunic(raw_data = F, 
                     time_period = 2002:2020, 
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
    rename(cod_ibge = code_muni)
    
population_final$cod_ibge <- population_final$cod_ibge %>% as.integer()
population_final$pop <- population_final$pop %>% as.numeric()
gdp_munic_2020$year <- gdp_munic_2020$year %>% as.integer()
gdp_munic_2020$produto_interno_bruto_a_precos_correntes_v37 <- gdp_munic_2020$produto_interno_bruto_a_precos_correntes_v37 %>% 
    as.numeric()

gdp_final <- population_final %>%
    inner_join(gdp, by = "cod_ibge")
    mutate(gdp_pc = gdp*1000/pop) %>%
    relocate(cod_ibge,Municipality, year)

#gdp <- gdp_safe %>%
#    mutate(gd_ppc = case_when(ano == 2020 ~ gd_ppc*1000,
#                              TRUE ~ gd_ppc),
#           gd_ppc_deflacionado = case_when(ano == 2020 ~ gd_ppc_deflacionado*1000,
#                                           TRUE ~ gd_ppc_deflacionado),
#           ano = ano)

#saving 
saveRDS(gdp_final,
        file = "./data/gdp.rds")