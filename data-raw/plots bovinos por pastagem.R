library(tidyverse)
library(plotly)

###filtering for a single year
ppm_mapbiomas= readRDS("./data/dz_munic_ppm_mapbiomas.rds")

plot_ppm= function(recorte, regiao, estado){
  
  param= list()
  param$recorte= recorte
  param$regiao= regiao
  param$estado= estado
  
  if (recorte == "amazonia_legal") {
    dat= ppm_mapbiomas%>%
      filter(legal_amazon == TRUE)
  }
  if(recorte == "regiao"){
    dat= ppm_mapbiomas%>%
      filter(regiao == param$regiao)
  }
  if(recorte == "estado"){
    dat= ppm_mapbiomas%>%
      filter(uf == param$estado)
  }
  return(dat)
}



#filtering for 2019
ppm_mapbiomas19= ppm_mapbiomas%>%
  filter(ano==2019)

#removing infinit values
ppm_mapbiomas19= ppm_mapbiomas19 %>% 
  filter_if(~is.numeric(.), all_vars(!is.infinite(.)))

#applying log
ppm_mapbiomas19$log= log(ppm_mapbiomas19$n_bovino_por_area_pastagem)

### plotting overlaying histograms for each region
fig <- plot_ly(alpha = 0.6, )
fig <- fig %>% add_histogram(x = ppm_mapbiomas19$log[ppm_mapbiomas19$regiao == "Sul"])
fig <- fig %>% add_histogram(x = ppm_mapbiomas19$log[ppm_mapbiomas19$regiao == "Sudeste"])
fig <- fig %>% add_histogram(x = ppm_mapbiomas19$log[ppm_mapbiomas19$regiao == "Centro-Oeste"])
fig <- fig %>% add_histogram(x = ppm_mapbiomas19$log[ppm_mapbiomas19$regiao == "Nordeste"])
fig <- fig %>% add_histogram(x = ppm_mapbiomas19$log[ppm_mapbiomas19$regiao == "Norte"])
fig <- fig %>% layout(barmode = "overlay")

fig




# ppm_mapbiomas19= ppm_mapbiomas%>%
#   filter(n_bovino_por_area_pastagem>=10)

###filtering for each region
ppm_mapbiomas_s= ppm_mapbiomas19%>%
  filter(regiao=="Sul")

ppm_mapbiomas_se= ppm_mapbiomas19%>%
  filter(regiao=="Sudeste", n_bovino_por_area_pastagem!=0)

ppm_mapbiomas_n= ppm_mapbiomas19%>%
  filter(regiao=="Norte", n_bovino_por_area_pastagem!=0)

ppm_mapbiomas_ne= ppm_mapbiomas19%>%
  filter(regiao=="Nordeste")

ppm_mapbiomas_co= ppm_mapbiomas19%>%
  filter(regiao=="Centro-Oeste")

legal_true= ppm_mapbiomas19%>%
  filter(legal_amazon== TRUE)

legal_false= ppm_mapbiomas19%>%
  filter(legal_amazon== FALSE)

###ploting histogram for each region
ggplot()+
  geom_histogram(data= ppm_mapbiomas_ne, aes(x=log), bins = 30)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Nordeste)")

ggplot()+
  geom_histogram(data= ppm_mapbiomas_n, aes(x=log), bins = 30)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Norte)")

ggplot()+
  geom_histogram(data= ppm_mapbiomas_s, aes(x=log), bins = 30)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Sul)")

ggplot()+
  geom_histogram(data= ppm_mapbiomas_se, aes(x=log), bins = 30)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Sudeste)")

ggplot()+
  geom_histogram(data= ppm_mapbiomas_co, aes(x=log), bins = 30)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Centro-Oeste)")

ggplot()+
  geom_histogram(data= legal_true, aes(x=log), bins = 30)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Amazônia Legal)")

ggplot()+
  geom_histogram(data= legal_false, aes(x=log), bins = 30)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Fora da Amazônia Legal)")


#means for each state
medias= ppm_mapbiomas19%>%
  group_by(uf)%>%
  summarise(media= mean(n_bovino_por_area_pastagem, na.rm=TRUE))

#plotting the mean for each state
ggplot(data= medias)+
  geom_col(aes(x=uf, y= media))

#plotting boxplot
ggplot(data= ppm_mapbiomas19)+
  geom_boxplot(aes(x= regiao, y= log))+
  xlab("Regiões")+
  ylab("Bovinos / Hectare de Pastagem")

ggplot(data= ppm_mapbiomas19)+
  geom_boxplot(aes(x= legal_amazon, y= log))+
  xlab("Amazônia Legal")+
  ylab("Bovinos / Hectare de Pastagem")
