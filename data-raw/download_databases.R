#downloading and saving databases using datazoom packages

devtools::install_github(datazoompuc/datazoomamazonia)

### Generate data -> IBGE - PPM

  #livestock_inventory

##state
ppm_state_livestock_inventory= load_ppm(dataset = 'ppm_livestock_inventory', 'state', 1974:2019, language = "pt")
##municipality
ppm_municipality_livestock_inventory= load_ppm(dataset = 'ppm_livestock_inventory', 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_livestock_inventory= load_dictionary(dataset = 'ppm_livestock_inventory')


  #sheep_farming -> está faltando o dicionário no pacote

##state
ppm_state_sheep_farming= load_ppm(dataset = 'ppm_sheep_farming', 'state', 1974:2019, language = "pt")
##municipality
ppm_municipality_sheep_farming= load_ppm(dataset = 'ppm_sheep_farming', 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_sheep_farming= load_dictionary(dataset = 'ppm_sheep_farming')


  #animal_origin_production 
##state
ppm_state_animal_origin_production= load_ppm(dataset = 'ppm_animal_origin_production', 'state', 1974:2019, language = "pt")
##municipality
ppm_municipality_animal_orig_production= load_ppm(dataset = 'ppm_animal_origin_production', 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_animal_origin_production= load_dictionary(dataset = 'ppm_animal_origin_production')

  #ppm_cow_farming -> está faltando o dicionário no pacote

##state
ppm_state_cow_farming= load_ppm(dataset = 'ppm_cow_farming', 'state', 1974:2019, language = "pt")
##municipality
ppm_municipality_cow_farming= load_ppm(dataset = 'ppm_cow_farming', 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_cow_farming= load_dictionary(dataset = 'ppm_cow_farming')

  #ppm_aquaculture

##state
ppm_state_aquaculture= load_ppm(dataset = 'ppm_aquaculture', 'state', 1974:2019, language = "pt")
##municipality
ppm_municipality_aquaculture= load_ppm(dataset = 'ppm_aquaculture', 'municipality', 1974:2019, language = "pt")
##dictionary
dic_ppm_aquaculture= load_dictionary(dataset = 'ppm_aquaculture')

### Generate data -> IBGE - PEVS

  #silviculture  

##state
pevs_state_silviculture= load_pevs(dataset = 'pevs_silviculture', 'state', 1986:2019, language = "pt")
##municipality
pevs_municipality_silviculture= load_pevs(dataset = 'pevs_silviculture', 'municipality', 1986:2019, language = "pt")
##dictionary
dic_pevs_silviculture= load_dictionary(dataset = 'pevs_silviculture')
##saving

  #forest_crops

##state
pevs_state_forest_crops= load_pevs(dataset = 'pevs_forest_crops', 'state', 1986:2019, language = "pt")
##municipality
pevs_municipality_forest_crops= load_pevs(dataset = 'pevs_forest_crops', 'municipality', 1986:2019, language = "pt")
##dictionary
dic_pevs_forest_crops= load_dictionary(dataset = 'pevs_forest_crops')
##saving

  #silviculture_area

##state
pevs_state_silviculture_area= load_pevs(dataset = 'pevs_silviculture_area', 'state', 1986:2019, language = "pt")
##municipality
pevs_municipality_silviculture_area= load_pevs(dataset = 'pevs_silviculture_area', 'municipality', 1986:2019, language = "pt")
##dictionary
dic_pevs_silviculture_area= load_dictionary(dataset = 'pevs_silviculture_area')
##saving



### Generate data -> IBGE - PAM