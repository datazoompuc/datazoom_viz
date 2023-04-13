############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(tidyverse)
library(datazoom.amazonia)

gdp <- load_pibmunic(raw_data = F, 
                     time_period = 2002:2020, 
                     language = "pt",
                     geo_level = "municipality")



#saving 
saveRDS(gdp,
        file = "./data/gdp.rds")