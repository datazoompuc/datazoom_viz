############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(tidyverse)
library(datazoom.amazonia)

gdp <- load_pibmunic(raw_data = F, 
                     time_period = 2000:2021, 
                     language = "pt",
                     geo_level = "municipality"
                     )


#saving 
saveRDS(prodes,
        file = "./data/gdp.rds"
)