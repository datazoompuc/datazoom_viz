#downloading and saving databases using datazoom packages

devtools::install_github(datazoompuc/datazoomamazonia)

### Generate data -> IBGE - PPM

ppm= load_ppm()


### Generate data -> IBGE - PEVS
pevs= load_pevs(time_period = 1973:2018)

### Generate data -> IBGE - PAM