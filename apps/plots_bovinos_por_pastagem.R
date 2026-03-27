library(tidyverse)


###filtering for a single year
ppm_mapbiomas= readRDS("./data/dz_munic_ppm_mapbiomas.rds")

ppm_mapbiomas19= ppm_mapbiomas%>%
  filter(ano==2019)

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

ggplot(data= ppm_mapbiomas_ne, aes(x=n_bovino_por_area_pastagem), lims(2, 1000)) + geom_density()

ggplot()+
  geom_histogram(data= ppm_mapbiomas_ne, aes(x=n_bovino_por_area_pastagem), bins = 10)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Nordeste)")

ggplot()+
  geom_histogram(data= ppm_mapbiomas_n, aes(x=n_bovino_por_area_pastagem), bins = 10)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Norte)")


ggplot()+
  geom_histogram(data= ppm_mapbiomas_s, aes(x=n_bovino_por_area_pastagem), bins = 10)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Sul)")


ggplot()+
  geom_histogram(data= ppm_mapbiomas_se, aes(x=n_bovino_por_area_pastagem), bins = 10)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Sudeste)")


ggplot()+
  geom_histogram(data= ppm_mapbiomas_co, aes(x=n_bovino_por_area_pastagem), bins = 10)+
  ggtitle("Número de Bovino/Hectares de Área de Pastagem (Centro-Oeste)")


