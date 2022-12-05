#######################
## Geração Distribuída
#######################

# Sistema de Informações de Geração da Aneel
# fonte: Agencia Nacional de Energia Elétrica
# https://dadosabertos.aneel.gov.br/dataset/relacao-de-empreendimentos-de-geracao-distribuida


# packages --------------------------------------------------------------------------
library(tidyverse)
library(lubridate)
library(datazoom.amazonia)
library(sf)
library(sp)
library(scales) # to use label_percent()
library(rmapshaper)

# load data -------------------------------------------------------------------------
db_geracao_distribuida <- read_csv2(file = "C:/Users/DELL/Desktop/empreendimento-geracao-distribuida.csv") %>%
  janitor::clean_names()

db_geracao_distribuida$cod_ibge <- db_geracao_distribuida$cod_municipio_ibge

hhh <- pivot_wider(
  db_geracao_distribuida,
  id_cols = c(cod_ibge, sig_uf),
  id_expand = FALSE,
  names_from = c(dsc_classe_consumo, 
                 sig_modalidade_empreendimento, 
                 sig_tipo_geracao, 
                 dsc_fonte_geracao),
  values_from = c(mda_potencia_instalada_kw, qtd_uc_recebe_credito),
  values_fn = sum
)

?pivot_wider

# colnames(db_geracao_distribuida)
db_geracao_distribuida <- db_geracao_distribuida %>%
  group_by(cod_municipio_ibge, 
           sig_uf, 
           dsc_classe_consumo, 
           sig_modalidade_empreendimento, 
           sig_tipo_geracao, 
           dsc_fonte_geracao) %>%
  summarise(
    mda_potencia_instalada_kw = sum(mda_potencia_instalada_kw),
    qtd_uc_recebe_credito = sum(qtd_uc_recebe_credito)
  )

###################
# TERRABRASILIS
###################
# read shapefile
shapefile <- st_read("data/shapefiles/municipalities_legal_amazon.shp")

# data too heavy (over 100mb)
# solution: simplify geometry
#shapefile <- sf::st_simplify(shapefile, dTolerance = 400)

# plot(shapefile)
# shapefile$cod_ibge

######################################################
# merge data with amazon municipalities shapefile
######################################################
temporary_data <- sp::merge(shapefile, hhh, by.x = "cod_ibge", by.y = "cod_ibge")

# drop municipalities with empty geometry
temporary_data <- temporary_data[!st_is_empty(temporary_data), , drop = FALSE]

# save simplified sf for faster maps
cols <- colnames(temporary_data)
temporary_data <- rmapshaper::ms_simplify(temporary_data, 
                                keep_shapes = TRUE, 
                                keep = 0.01)

colnames(temporary_data) <- cols

# save at rds format
saveRDS(temporary_data,
  file = "./data/aneel_geracao_distribuida.rds"
)

#####################
# Build Dictionary
#####################

# call data
temp <- readRDS("./data/aneel_geracao_distribuida.rds")

columns <- colnames(temp)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = FALSE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns,
  desc = columns,
  var_group = "Energia - ANEEL",
  tipo = 1,
  unidade = "",
  categoria = "Economia",
  subcategoria = "Energia"
)

# Label
temp_param_table$label <- temp_param_table$var
temp_param_table$label[temp_param_table$var == "dsc_classe_consumo"] <- "Classificação de consumo"
temp_param_table$label[temp_param_table$var == "sig_modalidade_empreendimento"] <- "Sigla da modalidade"
temp_param_table$label[temp_param_table$var == "sig_tipo_geracao"] <- "Tipo de geração"
temp_param_table$label[temp_param_table$var == "dsc_fonte_geracao"] <- "Combustível usado"
temp_param_table$label[temp_param_table$var == "mda_potencia_instalada_kw"] <- "Potência instalada"
temp_param_table$label[temp_param_table$var == "qtd_uc_recebe_credito"] <- "Quantidade de unidades consumidoras"

temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Comercial	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Residencial	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_R_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Residencial	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Industrial	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Rural	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder P\xfablico_P_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Poder Público	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Comercial	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Servi\xe7o P\xfablico_P_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Serviço Público	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_C_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Residencial	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Rural	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Industrial	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_M_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Comercial	M	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_C_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Comercial	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_C_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Rural	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder P\xfablico_R_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Poder Público	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_G\xe1s de Alto Forno - Biomassa"] <- "Potência Instalada -	Comercial	P	UTE	Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_G\xe1s de Alto Forno - Biomassa"] <- "Potência Instalada -	Comercial	R	UTE	Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_EOL_Cin\xe9tica do vento"] <- "Potência Instalada -	Comercial	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Ilumina\xe7ão p\xfablica_P_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Iluminação pública	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_G\xe1s Natural"] <- "Potência Instalada -	Comercial	R	UTE	Gás Natural"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Potência Instalada -	Comercial	R	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Servi\xe7o P\xfablico_R_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Serviço Público	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_C_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Industrial	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_EOL_Cin\xe9tica do vento"] <- "Potência Instalada -	Residencial	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_EOL_Cin\xe9tica do vento"] <- "Potência Instalada -	Industrial	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder P\xfablico_P_EOL_Cin\xe9tica do vento"] <- "Potência Instalada -	Poder Público	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_EOL_Cin\xe9tica do vento"] <- "Potência Instalada -	Rural	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_EOL_Cin\xe9tica do vento"] <- "Potência Instalada -	Comercial	R	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_C_EOL_Cin\xe9tica do vento"] <- "Potência Instalada -	Comercial	C	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_R_EOL_Cin\xe9tica do vento"] <- "Potência Instalada -	Residencial	R	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Potência Instalada -	Rural	R	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UTE_Biog\xe1s-AGR"] <- "Potência Instalada -	Rural	R	UTE	Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Biog\xe1s - RA"] <- "Potência Instalada -	Rural	P	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UTE_Biog\xe1s - RA"] <- "Potência Instalada -	Rural	R	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_C_UTE_Biog\xe1s - RA"] <- "Potência Instalada -	Comercial	C	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Biog\xe1s - RA"] <- "Potência Instalada -	Comercial	P	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_CGH_Potencial hidr\xe1ulico"] <- "Potência Instalada -	Rural	P	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_UTE_Biog\xe1s - RA"] <- "Potência Instalada -	Residencial	P	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Potência Instalada -	Industrial	P	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_M_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Residencial	M	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_M_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Rural	M	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_M_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Industrial	M	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Biog\xe1s-AGR"] <- "Potência Instalada -	Rural	P	UTE	Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Biog\xe1s - Floresta"] <- "Potência Instalada -	Comercial	P	UTE	BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Biog\xe1s - RU"] <- "Potência Instalada -	Rural	P	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Ilumina\xe7ão p\xfablica_R_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Iluminação pública	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_Biog\xe1s - RA"] <- "Potência Instalada -	Comercial	R	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UTE_Biog\xe1s - RU"] <- "Potência Instalada -	Rural	R	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_UTE_Biog\xe1s - Floresta"] <- "Potência Instalada -	Rural	R	UTE	BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_CGH_Potencial hidr\xe1ulico"] <- "Potência Instalada -	Comercial	R	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_CGH_Potencial hidr\xe1ulico"] <- "Potência Instalada -	Industrial	P	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_CGH_Potencial hidr\xe1ulico"] <- "Potência Instalada -	Comercial	P	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_C_CGH_Potencial hidr\xe1ulico"] <- "Potência Instalada -	Comercial	C	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_R_CGH_Potencial hidr\xe1ulico"] <- "Potência Instalada -	Rural	R	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Potência Instalada -	Rural	P	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Biog\xe1s - Floresta"] <- "Potência Instalada -	Rural	P	UTE	BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_CGH_Potencial hidr\xe1ulico"] <- "Potência Instalada -	Industrial	R	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UTE_G\xe1s de Alto Forno - Biomassa"] <- "Potência Instalada -	Industrial	R	UTE	Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_C_CGH_Potencial hidr\xe1ulico"] <- "Potência Instalada -	Rural	C	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_C_CGH_Potencial hidr\xe1ulico"] <- "Potência Instalada -	Industrial	C	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder P\xfablico_C_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Poder Público	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Potência Instalada -	Comercial	P	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_G\xe1s de Alto Forno - Biomassa"] <- "Potência Instalada -	Industrial	P	UTE	Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Biog\xe1s - RA"] <- "Potência Instalada -	Industrial	P	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Res\xedduos S\xf3lidos Urbanos - RU"] <- "Potência Instalada -	Rural	P	UTE	Resíduos Sólidos Urbanos - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Potência Instalada -	Residencial	P	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder P\xfablico_M_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Poder Público	M	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Biog\xe1s - RU"] <- "Potência Instalada -	Comercial	P	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Biog\xe1s - RU"] <- "Potência Instalada -	Industrial	P	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder P\xfablico_P_UTE_Biog\xe1s - RA"] <- "Potência Instalada -	Poder Público	P	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Res\xedduos Florestais"] <- "Potência Instalada -	Industrial	P	UTE	Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder P\xfablico_R_UTE_Biog\xe1s - RU"] <- "Potência Instalada -	Poder Público	R	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Res\xedduos Florestais"] <- "Potência Instalada -	Comercial	P	UTE	Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Biog\xe1s-AGR"] <- "Potência Instalada -	Industrial	P	UTE	Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_C_UTE_Biog\xe1s - RA"] <- "Potência Instalada -	Rural	C	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_Biog\xe1s - Floresta"] <- "Potência Instalada -	Comercial	R	UTE	BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Poder P\xfablico_P_CGH_Potencial hidr\xe1ulico"] <- "Potência Instalada -	Poder Público	P	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UTE_Biog\xe1s-AGR"] <- "Potência Instalada -	Industrial	R	UTE	Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UTE_Biog\xe1s - RU"] <- "Potência Instalada -	Industrial	R	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_NA_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Residencial	NA	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_C_UTE_Res\xedduos Florestais"] <- "Potência Instalada -	Comercial	C	UTE	Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Casca de Arroz"] <- "Potência Instalada -	Industrial	P	UTE	Casca de Arroz"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_CGH_Potencial hidr\xe1ulico"] <- "Potência Instalada -	Residencial	P	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_Res\xedduos Florestais"] <- "Potência Instalada -	Rural	P	UTE	Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UTE_Casca de Arroz"] <- "Potência Instalada -	Industrial	R	UTE	Casca de Arroz"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_G\xe1s Natural"] <- "Potência Instalada -	Comercial	P	UTE	Gás Natural"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_R_UTE_Biog\xe1s - RU"] <- "Potência Instalada -	Comercial	R	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Servi\xe7o P\xfablico_P_EOL_Cin\xe9tica do vento"] <- "Potência Instalada -	Serviço Público	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_P_UTE_Res\xedduos S\xf3lidos Urbanos - RU"] <- "Potência Instalada -	Industrial	P	UTE	Resíduos Sólidos Urbanos - RU"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_EOL_Cin\xe9tica do vento"] <- "Potência Instalada -	Industrial	R	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_R_UTE_Biog\xe1s - RA"] <- "Potência Instalada -	Residencial	R	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Servi\xe7o P\xfablico_C_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Serviço Público	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Residencial_P_UTE_G\xe1s Natural"] <- "Potência Instalada -	Residencial	P	UTE	Gás Natural"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Ilumina\xe7ão p\xfablica_C_UFV_Radia\xe7ão solar"] <- "Potência Instalada -	Iluminação pública	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Industrial_R_UTE_G\xe1s Natural"] <- "Potência Instalada -	Industrial	R	UTE	Gás Natural"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Comercial_P_UTE_Biog\xe1s-AGR"] <- "Potência Instalada -	Comercial	P	UTE	Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "mda_potencia_instalada_kw_Rural_P_UTE_G\xe1s de Alto Forno - Biomassa"] <- "Potência Instalada -	Rural	P	UTE	Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Comercial	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Residencial	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_R_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Residencial	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Industrial	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Rural	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder P\xfablico_P_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Poder Público	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Comercial	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Servi\xe7o P\xfablico_P_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Serviço Público	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_C_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Residencial	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Rural	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Industrial	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_M_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Comercial	M	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_C_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Comercial	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_C_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Rural	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder P\xfablico_R_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Poder Público	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_G\xe1s de Alto Forno - Biomassa"] <- "Quantidade de unidades consumidoras	Comercial	P	UTE	Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_G\xe1s de Alto Forno - Biomassa"] <- "Quantidade de unidades consumidoras	Comercial	R	UTE	Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_EOL_Cin\xe9tica do vento"] <- "Quantidade de unidades consumidoras	Comercial	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Ilumina\xe7ão p\xfablica_P_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Iluminação pública	P	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_G\xe1s Natural"] <- "Quantidade de unidades consumidoras	Comercial	R	UTE	Gás Natural"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Quantidade de unidades consumidoras	Comercial	R	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Servi\xe7o P\xfablico_R_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Serviço Público	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_C_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Industrial	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_EOL_Cin\xe9tica do vento"] <- "Quantidade de unidades consumidoras	Residencial	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_EOL_Cin\xe9tica do vento"] <- "Quantidade de unidades consumidoras	Industrial	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder P\xfablico_P_EOL_Cin\xe9tica do vento"] <- "Quantidade de unidades consumidoras	Poder Público	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_EOL_Cin\xe9tica do vento"] <- "Quantidade de unidades consumidoras	Rural	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_EOL_Cin\xe9tica do vento"] <- "Quantidade de unidades consumidoras	Comercial	R	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_C_EOL_Cin\xe9tica do vento"] <- "Quantidade de unidades consumidoras	Comercial	C	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_R_EOL_Cin\xe9tica do vento"] <- "Quantidade de unidades consumidoras	Residencial	R	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Quantidade de unidades consumidoras	Rural	R	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UTE_Biog\xe1s-AGR"] <- "Quantidade de unidades consumidoras	Rural	R	UTE	Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Biog\xe1s - RA"] <- "Quantidade de unidades consumidoras	Rural	P	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UTE_Biog\xe1s - RA"] <- "Quantidade de unidades consumidoras	Rural	R	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_C_UTE_Biog\xe1s - RA"] <- "Quantidade de unidades consumidoras	Comercial	C	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Biog\xe1s - RA"] <- "Quantidade de unidades consumidoras	Comercial	P	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_CGH_Potencial hidr\xe1ulico"] <- "Quantidade de unidades consumidoras	Rural	P	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_UTE_Biog\xe1s - RA"] <- "Quantidade de unidades consumidoras	Residencial	P	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Quantidade de unidades consumidoras	Industrial	P	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_M_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Residencial	M	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_M_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Rural	M	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_M_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Industrial	M	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Biog\xe1s-AGR"] <- "Quantidade de unidades consumidoras	Rural	P	UTE	Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Biog\xe1s - Floresta"] <- "Quantidade de unidades consumidoras	Comercial	P	UTE	BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Biog\xe1s - RU"] <- "Quantidade de unidades consumidoras	Rural	P	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Ilumina\xe7ão p\xfablica_R_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Iluminação pública	R	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_Biog\xe1s - RA"] <- "Quantidade de unidades consumidoras	Comercial	R	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UTE_Biog\xe1s - RU"] <- "Quantidade de unidades consumidoras	Rural	R	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_UTE_Biog\xe1s - Floresta"] <- "Quantidade de unidades consumidoras	Rural	R	UTE	BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_CGH_Potencial hidr\xe1ulico"] <- "Quantidade de unidades consumidoras	Comercial	R	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_CGH_Potencial hidr\xe1ulico"] <- "Quantidade de unidades consumidoras	Industrial	P	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_CGH_Potencial hidr\xe1ulico"] <- "Quantidade de unidades consumidoras	Comercial	P	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_C_CGH_Potencial hidr\xe1ulico"] <- "Quantidade de unidades consumidoras	Comercial	C	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_R_CGH_Potencial hidr\xe1ulico"] <- "Quantidade de unidades consumidoras	Rural	R	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Quantidade de unidades consumidoras	Rural	P	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Biog\xe1s - Floresta"] <- "Quantidade de unidades consumidoras	Rural	P	UTE	BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_CGH_Potencial hidr\xe1ulico"] <- "Quantidade de unidades consumidoras	Industrial	R	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UTE_G\xe1s de Alto Forno - Biomassa"] <- "Quantidade de unidades consumidoras	Industrial	R	UTE	Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_C_CGH_Potencial hidr\xe1ulico"] <- "Quantidade de unidades consumidoras	Rural	C	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_C_CGH_Potencial hidr\xe1ulico"] <- "Quantidade de unidades consumidoras	Industrial	C	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder P\xfablico_C_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Poder Público	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Quantidade de unidades consumidoras	Comercial	P	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_G\xe1s de Alto Forno - Biomassa"] <- "Quantidade de unidades consumidoras	Industrial	P	UTE	Gás de Alto Forno - Biomassa"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Biog\xe1s - RA"] <- "Quantidade de unidades consumidoras	Industrial	P	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Res\xedduos S\xf3lidos Urbanos - RU"] <- "Quantidade de unidades consumidoras	Rural	P	UTE	Resíduos Sólidos Urbanos - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_UTE_Baga\xe7o de Cana de A\xe7\xfacar"] <- "Quantidade de unidades consumidoras	Residencial	P	UTE	Bagaço de Cana de Açúcar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder P\xfablico_M_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Poder Público	M	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Biog\xe1s - RU"] <- "Quantidade de unidades consumidoras	Comercial	P	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Biog\xe1s - RU"] <- "Quantidade de unidades consumidoras	Industrial	P	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder P\xfablico_P_UTE_Biog\xe1s - RA"] <- "Quantidade de unidades consumidoras	Poder Público	P	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Res\xedduos Florestais"] <- "Quantidade de unidades consumidoras	Industrial	P	UTE	Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder P\xfablico_R_UTE_Biog\xe1s - RU"] <- "Quantidade de unidades consumidoras	Poder Público	R	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Res\xedduos Florestais"] <- "Quantidade de unidades consumidoras	Comercial	P	UTE	Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Biog\xe1s-AGR"] <- "Quantidade de unidades consumidoras	Industrial	P	UTE	Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_C_UTE_Biog\xe1s - RA"] <- "Quantidade de unidades consumidoras	Rural	C	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_Biog\xe1s - Floresta"] <- "Quantidade de unidades consumidoras	Comercial	R	UTE	BioGás - Floresta"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Poder P\xfablico_P_CGH_Potencial hidr\xe1ulico"] <- "Quantidade de unidades consumidoras	Poder Público	P	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UTE_Biog\xe1s-AGR"] <- "Quantidade de unidades consumidoras	Industrial	R	UTE	Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UTE_Biog\xe1s - RU"] <- "Quantidade de unidades consumidoras	Industrial	R	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_NA_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Residencial	NA	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_C_UTE_Res\xedduos Florestais"] <- "Quantidade de unidades consumidoras	Comercial	C	UTE	Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Casca de Arroz"] <- "Quantidade de unidades consumidoras	Industrial	P	UTE	Casca de Arroz"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_CGH_Potencial hidr\xe1ulico"] <- "Quantidade de unidades consumidoras	Residencial	P	CGH	Potencial hidráulico"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_Res\xedduos Florestais"] <- "Quantidade de unidades consumidoras	Rural	P	UTE	Resíduos Florestais"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UTE_Casca de Arroz"] <- "Quantidade de unidades consumidoras	Industrial	R	UTE	Casca de Arroz"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_G\xe1s Natural"] <- "Quantidade de unidades consumidoras	Comercial	P	UTE	Gás Natural"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_R_UTE_Biog\xe1s - RU"] <- "Quantidade de unidades consumidoras	Comercial	R	UTE	BioGás - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Servi\xe7o P\xfablico_P_EOL_Cin\xe9tica do vento"] <- "Quantidade de unidades consumidoras	Serviço Público	P	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_P_UTE_Res\xedduos S\xf3lidos Urbanos - RU"] <- "Quantidade de unidades consumidoras	Industrial	P	UTE	Resíduos Sólidos Urbanos - RU"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_EOL_Cin\xe9tica do vento"] <- "Quantidade de unidades consumidoras	Industrial	R	EOL	Cinética do vento"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_R_UTE_Biog\xe1s - RA"] <- "Quantidade de unidades consumidoras	Residencial	R	UTE	BioGás - RA"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Servi\xe7o P\xfablico_C_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Serviço Público	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Residencial_P_UTE_G\xe1s Natural"] <- "Quantidade de unidades consumidoras	Residencial	P	UTE	Gás Natural"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Ilumina\xe7ão p\xfablica_C_UFV_Radia\xe7ão solar"] <- "Quantidade de unidades consumidoras	Iluminação pública	C	UFV	Radiação solar"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Industrial_R_UTE_G\xe1s Natural"] <- "Quantidade de unidades consumidoras	Industrial	R	UTE	Gás Natural"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Comercial_P_UTE_Biog\xe1s-AGR"] <- "Quantidade de unidades consumidoras	Comercial	P	UTE	Biogás-AGR"
temp_param_table$label[temp_param_table$var  == "qtd_uc_recebe_credito_Rural_P_UTE_G\xe1s de Alto Forno - Biomassa"] <- "Quantidade de unidades consumidoras	Rural	P	UTE	Gás de Alto Forno - Biomassa"


# Unidade de medida
temp_param_table$unidade[temp_param_table$var == "mda_potencia_instalada_kw"] <- "KiloWatz"

# var_group variables
temp_param_table$var_group[temp_param_table$var == "mda_potencia_instalada_kw"] <- "Produção"
temp_param_table$var_group[temp_param_table$var == "qtd_uc_recebe_credito"] <- "Demanda"

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "dsc_classe_consumo"] <- FALSE
temp_param_table$y[temp_param_table$var == "sig_modalidade_empreendimento"] <- FALSE
temp_param_table$y[temp_param_table$var == "sig_tipo_geracao"] <- FALSE
temp_param_table$y[temp_param_table$var == "dsc_fonte_geracao"] <- FALSE

# block variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "dsc_classe_consumo"] <- FALSE
temp_param_table$x[temp_param_table$var == "sig_modalidade_empreendimento"] <- FALSE
temp_param_table$x[temp_param_table$var == "sig_tipo_geracao"] <- FALSE
temp_param_table$x[temp_param_table$var == "dsc_fonte_geracao"] <- FALSE

# allow variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "mda_potencia_instalada_kw"] <- TRUE
temp_param_table$y[temp_param_table$var == "qtd_uc_recebe_credito"] <- TRUE

# allow variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "mda_potencia_instalada_kw"] <- TRUE
temp_param_table$x[temp_param_table$var == "qtd_uc_recebe_credito"] <- TRUE

# allow variables geometry in maps
temp_param_table$y[temp_param_table$var == "geometry"] <- TRUE

# save csv in utf-8 encoding
write.csv(temp_param_table,
  file = "data/aneel_geracao_distribuida_dic.csv",
  fileEncoding = "UTF-8"
)
