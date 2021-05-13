############################################################
#### Generate rds data in the folder ./data/ 
############################################################

#### Generate Data: INPE - PRODES: deforestation
library(datazoom.amazonia)

#### Generate Data: INPE - PRODES: deforestation
prodes <- load_prodes(
  c(2000:2021),
  space_aggregation = "municipality",
  language = "pt"
)

saveRDS(data,
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

imp_ncm <- load_comex(year, ncm = TRUE, imp = TRUE, language = "pt")

saveRDS(imp_ncm,
        file = "./data/imp_ncm.rds"
)

#### Generate Data: IBGE - PIB-Munic: gdp
gdp_pop1 <- load_gdp(c(2000:2009)) # Quantidade limite de valores solicitados: 50000
gdp_pop2 <- load_gdp(c(2010:2017)) # Quantidade limite de valores solicitados: 50000
gdp <- rbind(gdp_pop1, gdp_pop2)


saveRDS(gdp,
     file = "./data/gdp.rds"
)

#### Generate Data: IBGE - CEMPRE: formal employment
employment1 <- load_amazon_employment(c(2006:2010), space_aggregation = "municipality", language = "pt")
employment2 <- load_amazon_employment(c(2010:2015), space_aggregation = "municipality", language = "pt")
employment3 <- load_amazon_employment(c(2016:2020), space_aggregation = "municipality", language = "pt")

employment <- rbind(employment1, employment2)
employment <- rbind(employment, employment3)

saveRDS(employment,
     file = "./data/employment.rds"
)

#### Generate Data: IBGE - Census: income
income <- load_amazon_income(2010, space_aggregation = "municipality", language = "pt")

saveRDS(income,
     file = "./data/income.rds"
)

#### Generate Data: IBGE - SIGMINE: mining area
sigmine <- load_sigmine(space_aggregation = 'municipality', source = NULL)

saveRDS(sigmine,
     file = "./data/sigmine.rds"
)

#### Generate Data: IBGE - PPM
ppm_cow_farm <- load_ppm(type=94 ,years = 2000:2019, aggregation_level = "municipality", language = "pt")
ppm_cattle_number <- load_ppm(type=3939 ,years = 2000:2019, aggregation_level = "municipality", language = "pt")
ppm_animal_orig_prod <- load_ppm(type=74 ,years = 2000:2019, aggregation_level = "municipality", language = "pt")
ppm_water_orig_prod <- load_ppm(type=3940 ,years = 2000:2019, aggregation_level = "municipality", language = "pt")

saveRDS(ppm_cow_farm,
        file = "./data/ppm_cow_farm.rds"
)

saveRDS(ppm_cattle_number,
        file = "./data/ppm_cattle_number.rds"
)
saveRDS(ppm_animal_orig_prod,
        file = "./data/ppm_animal_orig_prod.rds"
)
saveRDS(ppm_water_orig_prod,
        file = "./data/ppm_water_orig_prod.rds"
)

#### Generate Data: IBGE - PAM: agricultural data
pam <- load_pam_permanent(2015, aggregation_level = "municipality", language = "pt")

saveRDS(pam,
     file = "./data/pam.rds"
)

#### Generate Data: IBGE - PEVS: silviculture and plant extraction data
pevs <- datazoom.amazonia::load_pevs_areasilv(2017, aggregation_level = "municipality", language = "pt")

saveRDS(pevs,
     file = "./data/pevs.rds"
)

#### Generate Data: MAPBIOMAS: land covering
mapbiomas <- load_mapbiomas_covering(space_aggregation = 'municipality', path = NULL, covering = 3, years = c(2000:2010))

saveRDS(mapbiomas,
     file = "./data/mapbiomas.rds"
)

#### Generate Data: IMAZON - IPS: Social Progress Index by municipality
ips <- load_IPS(download_directory = getwd(), language = "pt")

saveRDS(ips,
     file = "./data/ips.rds"
)

#### Generate Data: SEEG - Greenhouse gases emissions by municipality
seeg <- load_seeg(language = "pt")

saveRDS(seeg,
     file = "./data/seeg.rds"
)