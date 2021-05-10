library(datazoom.amazonia)

#### Generate Data: INPE - PRODES: deforestation

prodes <- load_prodes(
  c(2000:2021),
  space_aggregation = "municipality",
  language = "pt"
)

saveRDS(prodes,
  file = "./data/prodes.rds"
)

#### Generate Data: INPE - DETER: deforestation warnings
deter <- load_deter(
  source = "amazonia",
  time_aggregation = "year",
  space_aggregation = "municipality",
  language = "pt"
)

saveRDS(deter,
     file = "./data/deter.rds"
)

#### Generate Data: INPE - DEGRAD: degradation (Work In Progress)
degrad <- load_degrad(c(2007:2016), 
                    time_aggregation = "year", 
                    space_aggregation = "municipality", 
                    language = "pt")

saveRDS(degrad,
     file = "./data/degrad.rds"
)

#### Generate Data: MDIC - COMEX: exports and imports

#### Generate Data: IBGE - PIB-Munic: gdp
gdp_pop1 <- load_gdp(c(2000:2009)) # Quantidade limite de valores solicitados: 50000
gdp_pop2 <- load_gdp(c(2010:2017)) # Quantidade limite de valores solicitados: 50000
gdp_pop3 <- rbind(gdp_pop1, gdp_pop2)


saveRDS(gdp_pop3,
     file = "./data/gdp.rds"
)

#### Generate Data: IBGE - CEMPRE: formal employment
#### Generate Data: IBGE - Census: income
#### Generate Data: IBGE - SIGMINE: mining area
#### Generate Data: IBGE - PAM: agricultural data
#### Generate Data: IBGE - PEVS: silviculture and plant extraction data
#### Generate Data: MAPBIOMAS: land covering
#### Generate Data: IMAZON - IPS: Social Progress Index by municipality
#### Generate Data: SEEG - Greenhouse gases emissions by municipality