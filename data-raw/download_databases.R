#downloading and saving databases using datazoom packages

devtools::install_github(datazoompuc/datazoomamazonia)

### Generate data -> IBGE - PPM

  #livestock_inventory

##state
ppm_state_livestock_inventory= load_ppm(dataset = 'ppm_livestock_inventory', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality
ppm_municipality_livestock_inventory= load_ppm(dataset = 'ppm_livestock_inventory', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_livestock_inventory= load_dictionary(dataset = 'ppm_livestock_inventory')
##saving
saveRDS(ppm_state_livestock_inventory,
        file = "./data/ppm_state_livestock_inventory.rds"
)
saveRDS(ppm_municipality_livestock_inventory,
        file = "./data/ppm_municipality_livestock_inventory.rds"
)

  #sheep_farming 

##state
ppm_state_sheep_farming= load_ppm(dataset = 'ppm_sheep_farming', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality
ppm_municipality_sheep_farming= load_ppm(dataset = 'ppm_sheep_farming', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_sheep_farming= load_dictionary(dataset = 'ppm_sheep_farming')
##saving
saveRDS(ppm_state_sheep_farming,
        file = "./data/ppm_state_sheep_farming.rds"
)

  #animal_origin_production 

##state
ppm_state_animal_origin_production= load_ppm(dataset = 'ppm_animal_origin_production', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality
ppm_municipality_animal_orig_production= load_ppm(dataset = 'ppm_animal_origin_production', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_animal_origin_production= load_dictionary(dataset = 'ppm_animal_origin_production')
##saving
saveRDS(ppm_state_animal_origin_production,
        file = "./data/ppm_state_animal_origin_production.rds"
)

  #ppm_cow_farming 

##state
ppm_state_cow_farming= load_ppm(dataset = 'ppm_cow_farming', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality
ppm_municipality_cow_farming= load_ppm(dataset = 'ppm_cow_farming', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_cow_farming= load_dictionary(dataset = 'ppm_cow_farming')
##saving
saveRDS(ppm_state_cow_farming,
        file = "./data/ppm_state_cow_farming.rds"
)

  #ppm_aquaculture

##state
ppm_state_aquaculture= load_ppm(dataset = 'ppm_aquaculture', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality
ppm_municipality_aquaculture= load_ppm(dataset = 'ppm_aquaculture', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_aquaculture= load_dictionary(dataset = 'ppm_aquaculture')
##saving
saveRDS(ppm_state_aquaculture,
        file = "./data/ppm_state_aquaculture.rds"
)

### Generate data -> IBGE - PEVS

  #silviculture  

##state
pevs_state_silviculture= load_pevs(dataset = 'pevs_silviculture', raw_data = FALSE, 'state', 1986:2019, language = "pt")
##municipality
pevs_municipality_silviculture= load_pevs(dataset = 'pevs_silviculture', raw_data = FALSE, 'municipality', 1986:2019, language = "pt")
##dictionary
dic_pevs_silviculture= load_dictionary(dataset = 'pevs_silviculture')
##saving
saveRDS(pevs_state_silviculture,
        file = "./data/pevs_state_silviculture.rds"
)

  #forest_crops

##state
pevs_state_forest_crops= load_pevs(dataset = 'pevs_forest_crops', raw_data = FALSE, 'state', 1986:2019, language = "pt")
##municipality
pevs_municipality_forest_crops= load_pevs(dataset = 'pevs_forest_crops', raw_data = FALSE, 'municipality', 1986:2019, language = "pt")
##dictionary
dic_pevs_forest_crops= load_dictionary(dataset = 'pevs_forest_crops')
##saving
saveRDS(pevs_state_forest_crops,
        file = "./data/pevs_state_forest_crops.rds"
)

  #silviculture_area

##state
pevs_state_silviculture_area= load_pevs(dataset = 'pevs_silviculture_area', raw_data = FALSE, 'state', 1986:2019, language = "pt")
##municipality
pevs_municipality_silviculture_area= load_pevs(dataset = 'pevs_silviculture_area', raw_data = FALSE, 'municipality', 1986:2019, language = "pt")
##dictionary
dic_pevs_silviculture_area= load_dictionary(dataset = 'pevs_silviculture_area')
##saving
saveRDS(pevs_state_silviculture_area,
        file = "./data/pevs_state_silviculture_area.rds"
)




### Generate data -> IBGE - PAM

  #all_crops

##state
pam_state_all_crops= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality
pam_municipality_all_crops= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_pam_all_crops= load_dictionary(dataset= 'pam_all_crops')
##saving
saveRDS(pam_state_all_crops,
        file = "./data/pam_state_all_crops.rds"
)

  #permanent_crops

##state
pam_state_permanent_crops= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality
pam_municipality_permanent_crops= load_pam(dataset = 'pam_all_crops', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_pam_permanent_crops= load_dictionary(dataset= 'pam_permanent_crops')
##saving
saveRDS(pam_state_permanent_crops,
        file = "./data/pam_state_permanent_crops.rds"
)

  #temporary_crops

##state
pam_state_temporary_crops= load_pam(dataset = 'pam_temporary_crops', raw_data = FALSE, 'state', 1974:2019, language = "pt")
##municipality
pam_municipality_temporary_crops= load_pam(dataset = 'pam_temporary_crops', raw_data = FALSE, 'municipality', 1974:2019, language = "pt")
##dictionary
dic_pam_temporary_crops= load_dictionary(dataset= 'pam_temporary_crops')
##saving
saveRDS(pam_state_temporary_crops,
        file = "./data/pam_state_temporary_crops.rds"
)


  #pam_xx (xx= corn, potato, peanut, beans)

##state
pam_state_corn= load_pam(dataset = 'pam_corn', raw_data = FALSE, 'state', 2003:2019, language = "pt")
pam_state_potato= load_pam(dataset = 'pam_potato', raw_data = FALSE, 'state', 2003:2019, language = "pt")
pam_state_peanut= load_pam(dataset = 'pam_peanut', raw_data = FALSE, 'state', 2003:2019, language = "pt")
pam_state_beans= load_pam(dataset = 'pam_beans', raw_data = FALSE, 'state', 2003:2019, language = "pt")

##municipality
pam_municipality_corn= load_pam(dataset = 'pam_corn', raw_data = FALSE, 'municipality', 2003:2019, language = "pt")
pam_municipality_potato= load_pam(dataset = 'pam_potato', raw_data = FALSE, 'municipality', 2003:2019, language = "pt")
pam_municipality_peanut= load_pam(dataset = 'pam_peanut', raw_data = FALSE, 'municipality', 2003:2019, language = "pt")
pam_municipality_beans= load_pam(dataset = 'pam_beans', raw_data = FALSE, 'municipality', 2003:2019, language = "pt")

##dictionary
dic_pam_corn= load_dictionary(dataset= 'pam_corn')
dic_pam_potato= load_dictionary(dataset= 'pam_potato')
dic_pam_peanut= load_dictionary(dataset= 'pam_peanut')
dic_pam_beans= load_dictionary(dataset= 'pam_beans')

##saving
saveRDS(pam_state_corn,
        file = "./data/pam_state_corn.rds"
)
saveRDS(pam_state_potato,
        file = "./data/pam_state_potato.rds"
)
saveRDS(pam_state_peanut,
        file = "./data/pam_state_peanut.rds"
)
saveRDS(pam_state_beans,
        file = "./data/pam_state_beans.rds"
)

### Generate data -> MAPBIOMAS 
 
  #cover

mapbiomas_cover= load_mapbiomas = function(dataset = mapbiomas_cover ,raw_data=FALSE,geo_level = 'state',time_period='all',language = 'pt',time_id = 'year',cover_level = 1)
  #transition
  
  #deforestation_regeneration

  #irrigation

  #grazing_quality
