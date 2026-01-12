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

prodes_2022 <- load_prodes(raw_data = F,
                           time_period = 2022,
                           language = "pt")

prodes_2023 <- load_prodes(raw_data = F,
                           time_period = 2023,
                           language = "pt")

prodes_2024 <- load_prodes(raw_data = F,
                           time_period = 2024,
                           language = "pt")

prodes_new <- list(prodes_2022, prodes_2023, prodes_2024) %>% 
    bind_rows()

saveRDS(prodes_new, file = "./data/prodes_2022_2024.rds")
