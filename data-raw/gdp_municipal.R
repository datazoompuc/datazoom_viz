############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(tidyverse)
library(datazoom.amazonia)

gdp <- load_pibmunic(raw_data = F, 
                     time_period = 2002:2020, 
                     language = "pt",
                     geo_level = "municipality")

population <- readxl::read_xlsx("C:\\Users\\vhste\\Downloads\\tabela6579.xlsx", skip = 2) %>% 
    drop_na(Município) %>% 
    mutate(year = 2020) %>% 
    rename(pop = Ano) %>% 
    mutate(municipality = str_split_i(Município, " (", 1))

#saving 
saveRDS(gdp,
        file = "./data/gdp.rds")