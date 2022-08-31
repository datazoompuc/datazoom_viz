############################################################
#### Generate rds data in the folder ./data/ 
############################################################

library(tidyverse)
library(datazoom.amazonia)

prodes <- load_prodes(raw_data = F, 
                      time_period = 2000:2021, 
                      language = "pt"
                      )

#saving 
saveRDS(prodes,
        file = "./data/prodes.rds"
)