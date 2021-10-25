
#seeg_farming

seeg_state_farming= load_seeg(dataset = 'seeg_farming', geo_level = 'state', raw_data = FALSE, language = 'pt')
seeg_state_farming= seeg_state_farming%>%
  dplyr::rename(time= .data$Ano, group= .data$estado)
##saving
saveRDS(seeg_state_farming,
        'data/seeg_state_farming.rds'
)

#seeg_industry
seeg_state_industry= load_seeg(dataset = "seeg_industry", geo_level = 'state', raw_data = FALSE, language = 'pt')
seeg_state_industry= seeg_state_industry%>%
  dplyr::rename(time= .data$Ano, group= .data$estado)

##saving
saveRDS(seeg_state_industry,
        'data/seeg_state_industry.rds'
)

#seeg_energy
seeg_state_energy= load_seeg(dataset = "seeg_energy", geo_level = 'state', raw_data = FALSE, language = 'pt')
seeg_state_energy= seeg_state_energy%>%
  dplyr::rename(time= .data$Ano, group= .data$estado)

##saving
saveRDS(seeg_state_energy,
        'data/seeg_state_energy.rds'
)

#seeg_land
seeg_state_land= load_seeg(dataset = "seeg_land", geo_level = 'state', raw_data = FALSE, language = 'pt')
seeg_state_land= seeg_state_land%>%
  dplyr::rename(time= .data$Ano, group= .data$estado)

##saving
saveRDS(seeg_state_land,
        'data/seeg_state_land.rds'
)

#seeg_residuals
seeg_state_residuals= load_seeg(dataset = "seeg_residuals", geo_level = 'state', raw_data = FALSE, language = 'pt')
seeg_state_residuals= seeg_state_residuals%>%
  dplyr::rename(time= .data$Ano, group= .data$estado)

##saving
saveRDS(seeg_state_residuals,
        'data/seeg_state_residuals.rds'
)








