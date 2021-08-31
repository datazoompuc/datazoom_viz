### Generate data -> IBGE - PEVS

#silviculture  

##state
pevs_state_silviculture= load_pevs(dataset = 'pevs_silviculture', raw_data = FALSE, 'state', 1986:2019, language = "pt")
##municipality (ainda nao salvo)
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
##municipality (ainda nao salvo)
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
##municipality (ainda nao salvo)
pevs_municipality_silviculture_area= load_pevs(dataset = 'pevs_silviculture_area', raw_data = FALSE, 'municipality', 1986:2019, language = "pt")
##dictionary
dic_pevs_silviculture_area= load_dictionary(dataset = 'pevs_silviculture_area')
##saving
saveRDS(pevs_state_silviculture_area,
        file = "./data/pevs_state_silviculture_area.rds"
)

