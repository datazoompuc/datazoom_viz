############################################################
#### Generate rds data in the folder ./data/ 
############################################################

devtools::install_github("datazoompuc/datazoom.amazonia")
library(tidyverse)
library(datazoom.amazonia)

gdp <- load_pibmunic(raw_data = F, 
                     time_period = 2002:2020, 
                     language = "pt",
                     geo_level = "municipality")

#tabela puxada de "https://sidra.ibge.gov.br/tabela/6579"
population <- readxl::read_xlsx("C:\\Users\\vhste\\Downloads\\tabela6579.xlsx", skip = 2) %>% 
    drop_na(Município, Ano) %>% 
    mutate(year = 2020) %>% 
    rename(pop = Ano, code_muni = Cód.) %>%
    arrange(code_muni)

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


gdp_pc_2020 <- gdp_munic_2020 %>% 
    select(year, geo_id, produto_interno_bruto_a_precos_correntes_v37) %>%
    rename(Year = year, CodIBGE = geo_id, GDP = produto_interno_bruto_a_precos_correntes_v37) %>%
    labelled::remove_labels() %>%
    inner_join(population_final, by = c("CodIBGE", "Year")) %>%
    mutate(GDPpc = GDP / Pop) %>%
    relocate(CodIBGE,Municipality, Year)


gdp_pc_2020$CodIBGE <- gdp_pc_2020$CodIBGE %>% as.integer() 

gdp_final <- gdp_antigo %>% 
    select(-X) %>%
    bind_rows(gdp_pc_2020)

    

#saving 
saveRDS(gdp_final,
        file = "./data/gdp.rds")