############################################################
#### Generate rds data in the folder ./data/
############################################################

#### Packages
library(tidyverse)
library(tibble)
library(zoo)
library(sf)
library(sp)
library(scales) # to use label_percent()
library(datazoom.amazonia)
library(rmapshaper)

####################
# 1) Call and clean data
###################
ips_2021 <- readxl::read_xlsx("C:\\Users\\DELL\\Desktop\\IPS_Amazonia_2021.xlsx") %>%
    janitor::clean_names()

# colnames(ips_2021)

ips_2021 <- ips_2021 %>%
  mutate(cod_ibge = codigo_ibge )

###################
# TERRABRASILIS
###################
# read shapefile
shapefile <- st_read("data/shapefiles/municipalities_legal_amazon.shp")

# data too heavy (over 100mb)
# solution: simplify geometry
shapefile <- sf::st_simplify(shapefile, dTolerance = 400)

# plot(shapefile)
# shapefile$cod_ibge
  
######################################################
# merge data with amazon municipalities shapefile
######################################################
temporary_data <- sp::merge(shapefile, ips_2021, by.x = "cod_ibge", by.y = "cod_ibge")

temporary_data$estado <- temporary_data$uf

# unique(temporary_data$uf)
# temporary_data <- temporary_data %>% dplyr::filter(estado == "AC" | estado == "AP" | estado == "AM" | estado == "PA" | estado == "MA" | estado == "RR" | estado == "RO" | estado == "MT" | estado == "TO")
class(temporary_data$cod_ibge)
temporary_data$cod_ibge <- as.factor(temporary_data$cod_ibge)
temporary_data$estado <- as.factor(temporary_data$estado)

# groups at the level: municipio
temporary_data$group <- temporary_data$nm_municip

# unique rows
# temporary_data <- unique(temporary_data, by = c(cod_ibge, estado))
temporary_data <- temporary_data %>% group_by(cod_ibge, ano)

# arrange data by
temporary_data <- temporary_data %>%
  arrange(cod_ibge)

# Identify and remove duplicate data
# xxx <- temporary_data %>% distinct(cod_ibge, ano, .keep_all = TRUE)

# drop municipalities with empty geometry
temporary_data <- temporary_data[!st_is_empty(temporary_data), , drop = FALSE]

ips_2021 <- temporary_data
remove(temporary_data)
remove(shapefile)

# save simplified sf for faster maps
ips_2021 <- rmapshaper::ms_simplify(ips_2021, 
                                         keep_shapes = TRUE, 
                                         keep = 0.01)

# select only relevant variables
ips_2021 <- ips_2021 %>%
  select(cod_ibge, 
         nm_municip, 
         uf, 
         ips_amazonia_2021, 
         necessidades_humanas_basicas,
         fundamentos_para_o_bem_estar,
         oportunidades,
         nutricao_e_cuidados_medicos_basicos,
         agua_e_saneamento,
         moradia,
         seguranca_pessoal,
         acesso_ao_conhecimento_basico,
         acesso_a_informacao_e_comunicacao,
         saude_e_bem_estar,
         qualidade_do_meio_ambiente,
         direitos_individuais,
         liberdade_individual_e_de_escolha,
         inclusao_social,
         acesso_a_educacao_superior,
         mortalidade_infantil_ate_5_anos_2019_obitos_1_000_nasc_vivos,
         mortalidade_materna_2019_obitos_maternos_100_000_nascidos_vivos,
         mortalidade_por_doencas_infecciosas_2019_obitos_100_000_habitantes,
         mortalidade_por_desnutricao_2019_obitos_100_000_habitantes,
         subnutricao_2020_percent_da_populacao,
         abastecimento_de_agua_adequado_2020_percent_da_populacao,
         esgotamento_sanitario_adequado_2020_percent_da_populacao,
         indice_atendimento_de_agua_2019_percent_da_populacao,
         coleta_de_lixo_2020_percent_de_domicilios,
         domicilios_com_iluminacao_eletrica_adequadas_2020_percent_de_domicilios,
         domicilios_com_paredes_adequadas_2020_percent_de_domicilios,
         domicilios_com_pisos_adequados_2020_percent_de_domicilios,
         assassinatos_de_jovens_2019_obitos_100_000_habitantes_de_15_a_29_anos,
         assassinatos_de_jovens_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40,
         homicidios_2019_obitos_100_000_habitantes,
         homicidios_categorico_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40,
         mortes_por_acidente_no_transito_obitos_100_000_habitantes,
         distorcao_idade_serie_ensino_fundamental_2019_percent_de_alunos,
         distorcao_idade_serie_ensino_medio_2019_percent_de_alunos,
         taxa_de_abandono_escolar_ensino_fundamental_2019_percent_de_alunos,
         taxa_de_reprovacao_escolar_ensino_fundamental_2019_percent_de_alunos,
         qualidade_da_educacao_ideb_2019,
         densidade_internet_banda_larga_fixa_2020_no_de_acessos_100_domicilios,
         densidade_telefonia_fixa_2020_no_de_acessos_100_domicilios,
         densidade_telefonia_movel_2020_no_de_acessos_100_habitantes,
         densidade_tv_por_assinatura_2020_no_de_acessos_100_domicilios,
         mortalidade_por_doencas_circulatorias_2019_obitos_100_000_habitantes,
         mortalidade_por_doencas_respiratorias_2019_obitos_100_000_habitantes,
         mortalidade_por_diabetes_mellitus_2019_obitos_100_000_habitantes,
         mortalidade_por_neoplasias_cancer_2019_obitos_100_000_habitantes,
         taxa_de_suicidios_2019_obitos_100_000_habitantes,
         areas_protegidas_2020_percent_area_total_do_municipio,
         desmatamento_acumulado_2020_percent_area_total_do_municipio,
         desmatamento_recente_2018_2019_2020_percent_do_desmatamento_total,
         emissoes_co2_2018_ton_co2eq_gwp_ar5_habitante,
         focos_de_calor_2020_na_de_focos_1_000_habitantes,
         diversidade_partidaria_2020_percent_de_vereadores_eleitos_de_partidos_diferentes,
         mobilidade_urbana_transporte_publico_2020_no_de_onibus_e_micro_onibus_1_000_habitantes,
         acesso_a_cultura_e_lazer_2018_categorica_1_10,
         maes_adolescentes_ou_criancas_2019_percent_de_filhos_de_maes_adolescentes_ou_criancas,
         trabalho_infantil_2019_no_de_familias_com_ao_menos_1_membro_em_trabalho_infantil_1_000_familias,
         vulnerabilidade_familiar_2019_percent_de_filhos_de_maes_solteiras,
         violencia_contra_indigenas_2014_no_de_casos_1_000_indigenas,
         violencia_contra_indigenas_2014_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_0_1_2_7_3_2_7_8_8_4_8_8_20_8_5_20_8,
         violencia_contra_mulheres_2019_no_de_casos_100_000_mulheres,
         violencia_infantil_2019_no_de_casos_100_000_pessoas_de_0_14_anos,
         violencia_infantil_2019_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_1_1_40_1_3_40_1_133_1_4_133_1_496_0_5_496_0,
         empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes,
         mulheres_com_empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes,
         group,
         geometry
         )

# save data
saveRDS(ips_2021,
        file = "./data/ips_2021.rds"
)

#####################
# Build Dictionary
#####################

# call data
ips_2021 <- readRDS("./data/ips_2021.rds")

# extract variables from data
columns <- colnames(ips_2021)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns,
  desc = columns,
  var_group = "",
  unidade = "Unidade de medida",
  categoria = "Social",
  subcategoria = "Desenvolvimento"
)

# label variables
temp_param_table$label[temp_param_table$var == "cod_ibge"] <- "Código IBGE"
temp_param_table$label[temp_param_table$var == "nm_municip"] <- "Município"
temp_param_table$label[temp_param_table$var == "uf"] <- "Estado"
temp_param_table$label[temp_param_table$var == "ips_amazonia_2021"] <- "IPS Amazônia 2021"
temp_param_table$label[temp_param_table$var == "necessidades_humanas_basicas"] <- "Necessidades Humanas Básicas"
temp_param_table$label[temp_param_table$var == "fundamentos_para_o_bem_estar"] <- "Fundamentos para o Bem-Estar"
temp_param_table$label[temp_param_table$var == "oportunidades"] <- "Oportunidades"
temp_param_table$label[temp_param_table$var == "nutricao_e_cuidados_medicos_basicos"] <- "Nutrição e Cuidados Médicos Básicos"
temp_param_table$label[temp_param_table$var == "agua_e_saneamento"] <- "Água e Saneamento"
temp_param_table$label[temp_param_table$var == "moradia"] <- "Moradia"
temp_param_table$label[temp_param_table$var == "seguranca_pessoal"] <- "Segurança Pessoal "
temp_param_table$label[temp_param_table$var == "acesso_ao_conhecimento_basico"] <- "Acesso ao Conhecimento Básico"
temp_param_table$label[temp_param_table$var == "acesso_a_informacao_e_comunicacao"] <- "Acesso à Informação e Comunicação"
temp_param_table$label[temp_param_table$var == "saude_e_bem_estar"] <- "Saúde e Bem-Estar"
temp_param_table$label[temp_param_table$var == "qualidade_do_meio_ambiente"] <- "Qualidade do Meio Ambiente"
temp_param_table$label[temp_param_table$var == "direitos_individuais"] <- "Direitos Individuais"
temp_param_table$label[temp_param_table$var == "liberdade_individual_e_de_escolha"] <- "Liberdade Individual e de Escolha"
temp_param_table$label[temp_param_table$var == "inclusao_social"] <- "Inclusão Social"
temp_param_table$label[temp_param_table$var == "acesso_a_educacao_superior"] <- "Acesso à Educação Superior"
temp_param_table$label[temp_param_table$var == "mortalidade_infantil_ate_5_anos_2019_obitos_1_000_nasc_vivos"] <- "Mortalidade Infantil até 5 anos 2019 "
temp_param_table$label[temp_param_table$var == "mortalidade_materna_2019_obitos_maternos_100_000_nascidos_vivos"] <- "Mortalidade materna 2019"
temp_param_table$label[temp_param_table$var == "mortalidade_por_doencas_infecciosas_2019_obitos_100_000_habitantes"] <- "Mortalidade por doenças infecciosas 2019"
temp_param_table$label[temp_param_table$var == "mortalidade_por_desnutricao_2019_obitos_100_000_habitantes"] <- "Mortalidade por desnutrição 2019"
temp_param_table$label[temp_param_table$var == "subnutricao_2020_percent_da_populacao"] <- "Subnutrição 2020"
temp_param_table$label[temp_param_table$var == "abastecimento_de_agua_adequado_2020_percent_da_populacao"] <- "Abastecimento de água adequado 2020"
temp_param_table$label[temp_param_table$var == "esgotamento_sanitario_adequado_2020_percent_da_populacao"] <- "Esgotamento sanitário adequado 2020"
temp_param_table$label[temp_param_table$var == "indice_atendimento_de_agua_2019_percent_da_populacao"] <- "Índice atendimento de água 2019"
temp_param_table$label[temp_param_table$var == "coleta_de_lixo_2020_percent_de_domicilios"] <- "Coleta de lixo 2020"
temp_param_table$label[temp_param_table$var == "domicilios_com_iluminacao_eletrica_adequadas_2020_percent_de_domicilios"] <- "Domicílios com iluminação elétrica adequadas 2020"
temp_param_table$label[temp_param_table$var == "domicilios_com_paredes_adequadas_2020_percent_de_domicilios"] <- "Domicílios com paredes adequadas 2020"
temp_param_table$label[temp_param_table$var == "domicilios_com_pisos_adequados_2020_percent_de_domicilios"] <- "Domicílios com pisos adequados 2020"
temp_param_table$label[temp_param_table$var == "assassinatos_de_jovens_2019_obitos_100_000_habitantes_de_15_a_29_anos"] <- "Assassinatos de jovens 2019"
temp_param_table$label[temp_param_table$var == "assassinatos_de_jovens_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Assassinatos de jovens categórico 2019"
temp_param_table$label[temp_param_table$var == "homicidios_2019_obitos_100_000_habitantes"] <- "Homicídios 2019"
temp_param_table$label[temp_param_table$var == "homicidios_categorico_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Homicídios categórico 2019"
temp_param_table$label[temp_param_table$var == "mortes_por_acidente_no_transito_obitos_100_000_habitantes"] <- "Mortes por acidente no trânsito"
temp_param_table$label[temp_param_table$var == "distorcao_idade_serie_ensino_fundamental_2019_percent_de_alunos"] <- "Distorção idade-série Ensino Fundamental 2019"
temp_param_table$label[temp_param_table$var == "distorcao_idade_serie_ensino_medio_2019_percent_de_alunos"] <- "Distorção idade-série Ensino Médio 2019"
temp_param_table$label[temp_param_table$var == "taxa_de_abandono_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "Taxa de abandono escolar Ensino Fundamental 2019"
temp_param_table$label[temp_param_table$var == "taxa_de_reprovacao_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "Taxa de reprovação escolar Ensino Fundamental 2019"
temp_param_table$label[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "Qualidade da educação - Ideb 2019"
temp_param_table$label[temp_param_table$var == "densidade_internet_banda_larga_fixa_2020_no_de_acessos_100_domicilios"] <- "Densidade internet banda-larga fixa 2020"
temp_param_table$label[temp_param_table$var == "densidade_telefonia_fixa_2020_no_de_acessos_100_domicilios"] <- "Densidade telefonia fixa 2020"
temp_param_table$label[temp_param_table$var == "densidade_telefonia_movel_2020_no_de_acessos_100_habitantes"] <- "Densidade telefonia movel 2020"
temp_param_table$label[temp_param_table$var == "densidade_tv_por_assinatura_2020_no_de_acessos_100_domicilios"] <- "Densidade TV por assinatura 2020"
temp_param_table$label[temp_param_table$var == "mortalidade_por_doencas_circulatorias_2019_obitos_100_000_habitantes"] <- "Mortalidade por doenças circulatórias 2019"
temp_param_table$label[temp_param_table$var == "mortalidade_por_doencas_respiratorias_2019_obitos_100_000_habitantes"] <- "Mortalidade por doenças respiratórias 2019"
temp_param_table$label[temp_param_table$var == "mortalidade_por_diabetes_mellitus_2019_obitos_100_000_habitantes"] <- "Mortalidade por diabetes mellitus 2019"
temp_param_table$label[temp_param_table$var == "mortalidade_por_neoplasias_cancer_2019_obitos_100_000_habitantes"] <- "Mortalidade por neoplasias (câncer) 2019"
temp_param_table$label[temp_param_table$var == "taxa_de_suicidios_2019_obitos_100_000_habitantes"] <- "Taxa de suicídios 2019"
temp_param_table$label[temp_param_table$var == "areas_protegidas_2020_percent_area_total_do_municipio"] <- "Áreas Protegidas 2020"
temp_param_table$label[temp_param_table$var == "desmatamento_acumulado_2020_percent_area_total_do_municipio"] <- "Desmatamento acumulado 2020"
temp_param_table$label[temp_param_table$var == "desmatamento_recente_2018_2019_2020_percent_do_desmatamento_total"] <- "Desmatamento recente 2018, 2019, 2020"
temp_param_table$label[temp_param_table$var == "emissoes_co2_2018_ton_co2eq_gwp_ar5_habitante"] <- "Emissões CO2 2018"
temp_param_table$label[temp_param_table$var == "focos_de_calor_2020_na_de_focos_1_000_habitantes"] <- "Focos de calor 2020"
temp_param_table$label[temp_param_table$var == "diversidade_partidaria_2020_percent_de_vereadores_eleitos_de_partidos_diferentes"] <- "Diversidade partidária 2020"
temp_param_table$label[temp_param_table$var == "mobilidade_urbana_transporte_publico_2020_no_de_onibus_e_micro_onibus_1_000_habitantes"] <- "Mobilidade urbana (transporte público) 2020"
temp_param_table$label[temp_param_table$var == "acesso_a_cultura_e_lazer_2018_categorica_1_10"] <- "Acesso à cultura e lazer 2018"
temp_param_table$label[temp_param_table$var == "maes_adolescentes_ou_criancas_2019_percent_de_filhos_de_maes_adolescentes_ou_criancas"] <- "Mães adolescentes ou crianças 2019"
temp_param_table$label[temp_param_table$var == "trabalho_infantil_2019_no_de_familias_com_ao_menos_1_membro_em_trabalho_infantil_1_000_familias"] <- "Trabalho Infantil 2019"
temp_param_table$label[temp_param_table$var == "vulnerabilidade_familiar_2019_percent_de_filhos_de_maes_solteiras"] <- "Vulnerabilidade familiar 2019"
temp_param_table$label[temp_param_table$var == "violencia_contra_indigenas_2014_no_de_casos_1_000_indigenas"] <- "Violência contra indígenas 2014"
temp_param_table$label[temp_param_table$var == "violencia_contra_indigenas_2014_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_0_1_2_7_3_2_7_8_8_4_8_8_20_8_5_20_8"] <- "Violência contra indígenas categórica 2014 "
temp_param_table$label[temp_param_table$var == "violencia_contra_mulheres_2019_no_de_casos_100_000_mulheres"] <- "Violência contra mulheres 2019"
temp_param_table$label[temp_param_table$var == "violencia_infantil_2019_no_de_casos_100_000_pessoas_de_0_14_anos"] <- "Violência infantil 2019"
temp_param_table$label[temp_param_table$var == "violencia_infantil_2019_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_1_1_40_1_3_40_1_133_1_4_133_1_496_0_5_496_0"] <- "Violência infantil categórica 2019"
temp_param_table$label[temp_param_table$var == "empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Empregos ensino superior 2019"
temp_param_table$label[temp_param_table$var == "mulheres_com_empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Mulheres com empregos ensino superior 2019"
temp_param_table$label[temp_param_table$var == "group"] <- ""
temp_param_table$label[temp_param_table$var == "geometry"] <- ""


# unidade variables
# unidade variables
temp_param_table$unidade[temp_param_table$var == "cod_ibge"] <- "Geral"
temp_param_table$unidade[temp_param_table$var == "nm_municip"] <- "Geral"
temp_param_table$unidade[temp_param_table$var == "uf"] <- "Geral"
temp_param_table$unidade[temp_param_table$var == "ips_amazonia_2021"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "necessidades_humanas_basicas"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "fundamentos_para_o_bem_estar"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "oportunidades"] <- "IPS Amazônia 2021 - Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "nutricao_e_cuidados_medicos_basicos"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "agua_e_saneamento"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "moradia"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "seguranca_pessoal"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "acesso_ao_conhecimento_basico"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "acesso_a_informacao_e_comunicacao"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "saude_e_bem_estar"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "qualidade_do_meio_ambiente"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "direitos_individuais"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "liberdade_individual_e_de_escolha"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "inclusao_social"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "acesso_a_educacao_superior"] <- "Escala de 0 a 100"
temp_param_table$unidade[temp_param_table$var == "mortalidade_infantil_ate_5_anos_2019_obitos_1_000_nasc_vivos"] <- "Óbitos por mil nascidos vivos"
temp_param_table$unidade[temp_param_table$var == "mortalidade_materna_2019_obitos_maternos_100_000_nascidos_vivos"] <- "Óbitos maternos por 100 mil nascidos vivos"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_doencas_infecciosas_2019_obitos_100_000_habitantes"] <- "Óbitos por 100 mil habitantes"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_desnutricao_2019_obitos_100_000_habitantes"] <- "Óbitos por 100 mil habitantes"
temp_param_table$unidade[temp_param_table$var == "subnutricao_2020_percent_da_populacao"] <- "% da população"
temp_param_table$unidade[temp_param_table$var == "abastecimento_de_agua_adequado_2020_percent_da_populacao"] <- "% de domicílios"
temp_param_table$unidade[temp_param_table$var == "esgotamento_sanitario_adequado_2020_percent_da_populacao"] <- "% de domicílios"
temp_param_table$unidade[temp_param_table$var == "indice_atendimento_de_agua_2019_percent_da_populacao"] <- "% da população"
temp_param_table$unidade[temp_param_table$var == "coleta_de_lixo_2020_percent_de_domicilios"] <- "% de domicílios"
temp_param_table$unidade[temp_param_table$var == "domicilios_com_iluminacao_eletrica_adequadas_2020_percent_de_domicilios"] <- "% de domicílios"
temp_param_table$unidade[temp_param_table$var == "domicilios_com_paredes_adequadas_2020_percent_de_domicilios"] <- "% de domicílios"
temp_param_table$unidade[temp_param_table$var == "domicilios_com_pisos_adequados_2020_percent_de_domicilios"] <- "% de domicílios"
temp_param_table$unidade[temp_param_table$var == "assassinatos_de_jovens_2019_obitos_100_000_habitantes_de_15_a_29_anos"] <- "Óbitos/100.000 habitantes de 15 a 29 anos"
temp_param_table$unidade[temp_param_table$var == "assassinatos_de_jovens_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Pontuados em uma escala de 1-6"
temp_param_table$unidade[temp_param_table$var == "homicidios_2019_obitos_100_000_habitantes"] <- "Óbitos por 100 mil habitantes"
temp_param_table$unidade[temp_param_table$var == "homicidios_categorico_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Pontuados em uma escala de 1-6"
temp_param_table$unidade[temp_param_table$var == "mortes_por_acidente_no_transito_obitos_100_000_habitantes"] <- "Óbitos por 100 mil habitantes "
temp_param_table$unidade[temp_param_table$var == "distorcao_idade_serie_ensino_fundamental_2019_percent_de_alunos"] <- "% de alunos"
temp_param_table$unidade[temp_param_table$var == "distorcao_idade_serie_ensino_medio_2019_percent_de_alunos"] <- "% de alunos"
temp_param_table$unidade[temp_param_table$var == "taxa_de_abandono_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "% de alunos"
temp_param_table$unidade[temp_param_table$var == "taxa_de_reprovacao_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "% de alunos"
temp_param_table$unidade[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "Ideb (0-10)"
temp_param_table$unidade[temp_param_table$var == "densidade_internet_banda_larga_fixa_2020_no_de_acessos_100_domicilios"] <- "nº de acessos/100 domicílios"
temp_param_table$unidade[temp_param_table$var == "densidade_telefonia_fixa_2020_no_de_acessos_100_domicilios"] <- "nº de acessos/100 domicílios"
temp_param_table$unidade[temp_param_table$var == "densidade_telefonia_movel_2020_no_de_acessos_100_habitantes"] <- "nº de acessos/100 domicílios"
temp_param_table$unidade[temp_param_table$var == "densidade_tv_por_assinatura_2020_no_de_acessos_100_domicilios"] <- "nº de acessos/100 domicílios"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_doencas_circulatorias_2019_obitos_100_000_habitantes"] <- "Óbitos por 100 mil habitantes"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_doencas_respiratorias_2019_obitos_100_000_habitantes"] <- "Óbitos por 100 mil habitantes"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_diabetes_mellitus_2019_obitos_100_000_habitantes"] <- "Óbitos por 100 mil habitantes"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_neoplasias_cancer_2019_obitos_100_000_habitantes"] <- "Óbitos por 100 mil habitantes"
temp_param_table$unidade[temp_param_table$var == "taxa_de_suicidios_2019_obitos_100_000_habitantes"] <- "Óbitos por 100 mil habitantes"
temp_param_table$unidade[temp_param_table$var == "areas_protegidas_2020_percent_area_total_do_municipio"] <- "% área total do município"
temp_param_table$unidade[temp_param_table$var == "desmatamento_acumulado_2020_percent_area_total_do_municipio"] <- "% área total do município"
temp_param_table$unidade[temp_param_table$var == "desmatamento_recente_2018_2019_2020_percent_do_desmatamento_total"] <- "% do desmatamento total"
temp_param_table$unidade[temp_param_table$var == "emissoes_co2_2018_ton_co2eq_gwp_ar5_habitante"] <- "Toneladas CO2eq GWP-AR5 por habitante"
temp_param_table$unidade[temp_param_table$var == "focos_de_calor_2020_na_de_focos_1_000_habitantes"] <- "nª de focos por 1.000 habitantes"
temp_param_table$unidade[temp_param_table$var == "diversidade_partidaria_2020_percent_de_vereadores_eleitos_de_partidos_diferentes"] <- "% de vereadores eleitos de partidos diferentes"
temp_param_table$unidade[temp_param_table$var == "mobilidade_urbana_transporte_publico_2020_no_de_onibus_e_micro_onibus_1_000_habitantes"] <- "nº de ônibus e micro-ônibus por 1.000 habitantes"
temp_param_table$unidade[temp_param_table$var == "acesso_a_cultura_e_lazer_2018_categorica_1_10"] <- "Categórica (0 = nenhuma estrutura, de 1 = estrutura minima a 10 = todas as estruturas)"
temp_param_table$unidade[temp_param_table$var == "maes_adolescentes_ou_criancas_2019_percent_de_filhos_de_maes_adolescentes_ou_criancas"] <- "%"
temp_param_table$unidade[temp_param_table$var == "trabalho_infantil_2019_no_de_familias_com_ao_menos_1_membro_em_trabalho_infantil_1_000_familias"] <- "nº de famílias com ao menos 1 membro em trabalho infantil por 1.000 famílias"
temp_param_table$unidade[temp_param_table$var == "vulnerabilidade_familiar_2019_percent_de_filhos_de_maes_solteiras"] <- "% "
temp_param_table$unidade[temp_param_table$var == "violencia_contra_indigenas_2014_no_de_casos_1_000_indigenas"] <- "Nº de casos por mil indígenas"
temp_param_table$unidade[temp_param_table$var == "violencia_contra_indigenas_2014_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_0_1_2_7_3_2_7_8_8_4_8_8_20_8_5_20_8"] <- "Pontuados em uma escala de 1-5"
temp_param_table$unidade[temp_param_table$var == "violencia_contra_mulheres_2019_no_de_casos_100_000_mulheres"] <- "Nº de casos de violência por 100 mil mulheres"
temp_param_table$unidade[temp_param_table$var == "violencia_infantil_2019_no_de_casos_100_000_pessoas_de_0_14_anos"] <- "Nº de casos de violência por 100 mil pessoas de 0-14 anos"
temp_param_table$unidade[temp_param_table$var == "violencia_infantil_2019_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_1_1_40_1_3_40_1_133_1_4_133_1_496_0_5_496_0"] <- "Pontuados em uma escala de 1-5"
temp_param_table$unidade[temp_param_table$var == "empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Nº de empregos por 100.000 habitantes"
temp_param_table$unidade[temp_param_table$var == "mulheres_com_empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Nº de empregos por 100.000 habitantes"
temp_param_table$unidade[temp_param_table$var == "group"] <- ""
temp_param_table$unidade[temp_param_table$var == "geometry"] <- ""

# var_group variables
temp_param_table$var_group[temp_param_table$var == "cod_ibge"] <- "Geral"
temp_param_table$var_group[temp_param_table$var == "nm_municip"] <- "Geral"
temp_param_table$var_group[temp_param_table$var == "uf"] <- "Geral"
temp_param_table$var_group[temp_param_table$var == "ips_amazonia_2021"] <- "IMAZON - Índice de Progresso Social (IPS)"
temp_param_table$var_group[temp_param_table$var == "necessidades_humanas_basicas"] <- "Principais Dimensões"
temp_param_table$var_group[temp_param_table$var == "fundamentos_para_o_bem_estar"] <- "Principais Dimensões"
temp_param_table$var_group[temp_param_table$var == "oportunidades"] <- "Principais Dimensões"
temp_param_table$var_group[temp_param_table$var == "nutricao_e_cuidados_medicos_basicos"] <- "Componentes: Necessidades Humanas Básicas"
temp_param_table$var_group[temp_param_table$var == "agua_e_saneamento"] <- "Componentes: Necessidades Humanas Básicas"
temp_param_table$var_group[temp_param_table$var == "moradia"] <- "Componentes: Necessidades Humanas Básicas"
temp_param_table$var_group[temp_param_table$var == "seguranca_pessoal"] <- "Componentes: Necessidades Humanas Básicas"
temp_param_table$var_group[temp_param_table$var == "acesso_ao_conhecimento_basico"] <- "Componentes: Fundamentos para o Bem-Estar "
temp_param_table$var_group[temp_param_table$var == "acesso_a_informacao_e_comunicacao"] <- "Componentes: Fundamentos para o Bem-Estar "
temp_param_table$var_group[temp_param_table$var == "saude_e_bem_estar"] <- "Componentes: Fundamentos para o Bem-Estar "
temp_param_table$var_group[temp_param_table$var == "qualidade_do_meio_ambiente"] <- "Componentes: Fundamentos para o Bem-Estar "
temp_param_table$var_group[temp_param_table$var == "direitos_individuais"] <- "Componentes: Oportunidades"
temp_param_table$var_group[temp_param_table$var == "liberdade_individual_e_de_escolha"] <- "Componentes: Oportunidades"
temp_param_table$var_group[temp_param_table$var == "inclusao_social"] <- "Componentes: Oportunidades"
temp_param_table$var_group[temp_param_table$var == "acesso_a_educacao_superior"] <- "Componentes: Oportunidades"
temp_param_table$var_group[temp_param_table$var == "mortalidade_infantil_ate_5_anos_2019_obitos_1_000_nasc_vivos"] <- "Indicadores: Nutrição e Cuidados Médicos Básicos"
temp_param_table$var_group[temp_param_table$var == "mortalidade_materna_2019_obitos_maternos_100_000_nascidos_vivos"] <- "Indicadores: Nutrição e Cuidados Médicos Básicos"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_doencas_infecciosas_2019_obitos_100_000_habitantes"] <- "Indicadores: Nutrição e Cuidados Médicos Básicos"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_desnutricao_2019_obitos_100_000_habitantes"] <- "Indicadores: Nutrição e Cuidados Médicos Básicos"
temp_param_table$var_group[temp_param_table$var == "subnutricao_2020_percent_da_populacao"] <- "Indicadores: Nutrição e Cuidados Médicos Básicos"
temp_param_table$var_group[temp_param_table$var == "abastecimento_de_agua_adequado_2020_percent_da_populacao"] <- "Indicadores: Saneamento"
temp_param_table$var_group[temp_param_table$var == "esgotamento_sanitario_adequado_2020_percent_da_populacao"] <- "Indicadores: Saneamento"
temp_param_table$var_group[temp_param_table$var == "indice_atendimento_de_agua_2019_percent_da_populacao"] <- "Indicadores: Saneamento"
temp_param_table$var_group[temp_param_table$var == "coleta_de_lixo_2020_percent_de_domicilios"] <- "Indicadores: Moradia"
temp_param_table$var_group[temp_param_table$var == "domicilios_com_iluminacao_eletrica_adequadas_2020_percent_de_domicilios"] <- "Indicadores: Moradia"
temp_param_table$var_group[temp_param_table$var == "domicilios_com_paredes_adequadas_2020_percent_de_domicilios"] <- "Indicadores: Moradia"
temp_param_table$var_group[temp_param_table$var == "domicilios_com_pisos_adequados_2020_percent_de_domicilios"] <- "Indicadores: Moradia"
temp_param_table$var_group[temp_param_table$var == "assassinatos_de_jovens_2019_obitos_100_000_habitantes_de_15_a_29_anos"] <- "Indicadores: Segurança Pessoal"
temp_param_table$var_group[temp_param_table$var == "assassinatos_de_jovens_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Indicadores: Segurança Pessoal"
temp_param_table$var_group[temp_param_table$var == "homicidios_2019_obitos_100_000_habitantes"] <- "Indicadores: Segurança Pessoal"
temp_param_table$var_group[temp_param_table$var == "homicidios_categorico_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Indicadores: Segurança Pessoal"
temp_param_table$var_group[temp_param_table$var == "mortes_por_acidente_no_transito_obitos_100_000_habitantes"] <- "Indicadores: Segurança Pessoal"
temp_param_table$var_group[temp_param_table$var == "distorcao_idade_serie_ensino_fundamental_2019_percent_de_alunos"] <- "Indicadores: Acesso ao Conhecimento Básico"
temp_param_table$var_group[temp_param_table$var == "distorcao_idade_serie_ensino_medio_2019_percent_de_alunos"] <- "Indicadores: Acesso ao Conhecimento Básico"
temp_param_table$var_group[temp_param_table$var == "taxa_de_abandono_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "Indicadores: Acesso ao Conhecimento Básico"
temp_param_table$var_group[temp_param_table$var == "taxa_de_reprovacao_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "Indicadores: Acesso ao Conhecimento Básico"
temp_param_table$var_group[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "Indicadores: Acesso ao Conhecimento Básico"
temp_param_table$var_group[temp_param_table$var == "densidade_internet_banda_larga_fixa_2020_no_de_acessos_100_domicilios"] <- "Indicadores: Acesso à Informação e Comunicação"
temp_param_table$var_group[temp_param_table$var == "densidade_telefonia_fixa_2020_no_de_acessos_100_domicilios"] <- "Indicadores: Acesso à Informação e Comunicação"
temp_param_table$var_group[temp_param_table$var == "densidade_telefonia_movel_2020_no_de_acessos_100_habitantes"] <- "Indicadores: Acesso à Informação e Comunicação"
temp_param_table$var_group[temp_param_table$var == "densidade_tv_por_assinatura_2020_no_de_acessos_100_domicilios"] <- "Indicadores: Acesso à Informação e Comunicação"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_doencas_circulatorias_2019_obitos_100_000_habitantes"] <- "Indicadores: Saúde e Bem-Estar"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_doencas_respiratorias_2019_obitos_100_000_habitantes"] <- "Indicadores: Saúde e Bem-Estar"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_diabetes_mellitus_2019_obitos_100_000_habitantes"] <- "Indicadores: Saúde e Bem-Estar"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_neoplasias_cancer_2019_obitos_100_000_habitantes"] <- "Indicadores: Saúde e Bem-Estar"
temp_param_table$var_group[temp_param_table$var == "taxa_de_suicidios_2019_obitos_100_000_habitantes"] <- "Indicadores: Saúde e Bem-Estar"
temp_param_table$var_group[temp_param_table$var == "areas_protegidas_2020_percent_area_total_do_municipio"] <- "Indicadores: Qualidade do  Meio Ambiente"
temp_param_table$var_group[temp_param_table$var == "desmatamento_acumulado_2020_percent_area_total_do_municipio"] <- "Indicadores: Qualidade do  Meio Ambiente"
temp_param_table$var_group[temp_param_table$var == "desmatamento_recente_2018_2019_2020_percent_do_desmatamento_total"] <- "Indicadores: Qualidade do  Meio Ambiente"
temp_param_table$var_group[temp_param_table$var == "emissoes_co2_2018_ton_co2eq_gwp_ar5_habitante"] <- "Indicadores: Qualidade do  Meio Ambiente"
temp_param_table$var_group[temp_param_table$var == "focos_de_calor_2020_na_de_focos_1_000_habitantes"] <- "Indicadores: Qualidade do  Meio Ambiente"
temp_param_table$var_group[temp_param_table$var == "diversidade_partidaria_2020_percent_de_vereadores_eleitos_de_partidos_diferentes"] <- "Indicadores: Direitos individuais"
temp_param_table$var_group[temp_param_table$var == "mobilidade_urbana_transporte_publico_2020_no_de_onibus_e_micro_onibus_1_000_habitantes"] <- "Indicadores: Direitos individuais"
temp_param_table$var_group[temp_param_table$var == "acesso_a_cultura_e_lazer_2018_categorica_1_10"] <- "Indicadores: Liberdades individuais"
temp_param_table$var_group[temp_param_table$var == "maes_adolescentes_ou_criancas_2019_percent_de_filhos_de_maes_adolescentes_ou_criancas"] <- "Indicadores: Liberdades individuais"
temp_param_table$var_group[temp_param_table$var == "trabalho_infantil_2019_no_de_familias_com_ao_menos_1_membro_em_trabalho_infantil_1_000_familias"] <- "Indicadores: Liberdades individuais"
temp_param_table$var_group[temp_param_table$var == "vulnerabilidade_familiar_2019_percent_de_filhos_de_maes_solteiras"] <- "Indicadores: Liberdades individuais"
temp_param_table$var_group[temp_param_table$var == "violencia_contra_indigenas_2014_no_de_casos_1_000_indigenas"] <- "Indicadores: Inclusão Social"
temp_param_table$var_group[temp_param_table$var == "violencia_contra_indigenas_2014_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_0_1_2_7_3_2_7_8_8_4_8_8_20_8_5_20_8"] <- "Indicadores: Inclusão Social"
temp_param_table$var_group[temp_param_table$var == "violencia_contra_mulheres_2019_no_de_casos_100_000_mulheres"] <- "Indicadores: Inclusão Social"
temp_param_table$var_group[temp_param_table$var == "violencia_infantil_2019_no_de_casos_100_000_pessoas_de_0_14_anos"] <- "Indicadores: Inclusão Social"
temp_param_table$var_group[temp_param_table$var == "violencia_infantil_2019_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_1_1_40_1_3_40_1_133_1_4_133_1_496_0_5_496_0"] <- "Indicadores: Inclusão Social"
temp_param_table$var_group[temp_param_table$var == "empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Indicadores: Acesso à Educação Superior"
temp_param_table$var_group[temp_param_table$var == "mulheres_com_empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Indicadores: Acesso à Educação Superior"
temp_param_table$var_group[temp_param_table$var == "group"] <- ""
temp_param_table$var_group[temp_param_table$var == "geometry"] <- ""

# label data category
temp_param_table$categoria[temp_param_table$var == "geometry"] <- ""
temp_param_table$categoria[temp_param_table$var == "estado"] <- ""
temp_param_table$categoria[temp_param_table$var == "group"] <- ""

# subcategoria variables
temp_param_table$subcategoria[temp_param_table$var == "geometry"] <- ""
temp_param_table$subcategoria[temp_param_table$var == "estado"] <- ""
temp_param_table$subcategoria[temp_param_table$var == "group"] <- ""

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "cod_ibge"] <- FALSE # "Código do município"
temp_param_table$y[temp_param_table$var == "nm_municip"] <- FALSE # "nm_municip"
temp_param_table$y[temp_param_table$var == "uf"] <- FALSE # "uf_x"
temp_param_table$y[temp_param_table$var == "ano"] <- FALSE # "ano"
temp_param_table$y[temp_param_table$var == "geometry"] <- FALSE # "geometry"
temp_param_table$y[temp_param_table$var == "group"] <- FALSE # "estado"
temp_param_table$y[temp_param_table$var == "estado"] <- FALSE # "estado"
temp_param_table$y[temp_param_table$var == "group"] <- FALSE 

# block variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "cod_ibge"] <- FALSE # "Código do município"
temp_param_table$x[temp_param_table$var == "nm_municip"] <- FALSE # "nm_municip"
temp_param_table$x[temp_param_table$var == "uf"] <- FALSE # "uf_x"
temp_param_table$x[temp_param_table$var == "ano"] <- FALSE # "ano"
temp_param_table$x[temp_param_table$var == "geometry"] <- FALSE # "geometry"
temp_param_table$x[temp_param_table$var == "estado"] <- FALSE # "estado"
temp_param_table$x[temp_param_table$var == "group"] <- FALSE 

# allow variables in graphs size, color, and slider-axis
temp_param_table$color[temp_param_table$var == "estado"] <- TRUE #

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ips_2021_dic.csv", fileEncoding = "UTF-8")

###########################
# Build English Dictionary
###########################

# call data
ips_2021 <- readRDS("./data/ips_2021.rds")

# extract variables from data
columns <- colnames(ips_2021)

# generate dictionary
temp_param_table <- tibble(
    var = columns,
    x = TRUE,
    y = TRUE,
    color = FALSE,
    size = FALSE,
    slider = FALSE,
    geometry = FALSE,
    label = columns,
    desc = columns,
    var_group = "",
    unidade = "Measurement Unit",
    categoria = "Social",
    subcategoria = "Development"
)

# label variables
temp_param_table$label[temp_param_table$var == "cod_ibge"] <- "Municipality code"
temp_param_table$label[temp_param_table$var == "nm_municip"] <- "Municipality"
temp_param_table$label[temp_param_table$var == "uf"] <- "State"
temp_param_table$label[temp_param_table$var == "ips_amazonia_2021"] <- "IPS Amazon 2021"
temp_param_table$label[temp_param_table$var == "necessidades_humanas_basicas"] <- "Basic Human Needs"
temp_param_table$label[temp_param_table$var == "fundamentos_para_o_bem_estar"] <- "Fundamentals for Well-Being"
temp_param_table$label[temp_param_table$var == "oportunidades"] <- "Oportunities"
temp_param_table$label[temp_param_table$var == "nutricao_e_cuidados_medicos_basicos"] <- "Nutrition and Basic Medical Care"
temp_param_table$label[temp_param_table$var == "agua_e_saneamento"] <- "Water and Sanitation"
temp_param_table$label[temp_param_table$var == "moradia"] <- "Housing"
temp_param_table$label[temp_param_table$var == "seguranca_pessoal"] <- "Personal Safety"
temp_param_table$label[temp_param_table$var == "acesso_ao_conhecimento_basico"] <- "Access to basic knowledge"
temp_param_table$label[temp_param_table$var == "acesso_a_informacao_e_comunicacao"] <- "Access to Information and Communications"
temp_param_table$label[temp_param_table$var == "saude_e_bem_estar"] <- "Health and Well-Being"
temp_param_table$label[temp_param_table$var == "qualidade_do_meio_ambiente"] <- "Environmental Quality"
temp_param_table$label[temp_param_table$var == "direitos_individuais"] <- "Individual Rights"
temp_param_table$label[temp_param_table$var == "liberdade_individual_e_de_escolha"] <- "Individual Freedom and Choice"
temp_param_table$label[temp_param_table$var == "inclusao_social"] <- "Social Inclusion"
temp_param_table$label[temp_param_table$var == "acesso_a_educacao_superior"] <- "Access to Higher Education"
temp_param_table$label[temp_param_table$var == "mortalidade_infantil_ate_5_anos_2019_obitos_1_000_nasc_vivos"] <- "Child Mortality up to 5 years-old, 2019 "
temp_param_table$label[temp_param_table$var == "mortalidade_materna_2019_obitos_maternos_100_000_nascidos_vivos"] <- "Maternal Mortality, 2019"
temp_param_table$label[temp_param_table$var == "mortalidade_por_doencas_infecciosas_2019_obitos_100_000_habitantes"] <- "Infectious Disease Mortality, 2019"
temp_param_table$label[temp_param_table$var == "mortalidade_por_desnutricao_2019_obitos_100_000_habitantes"] <- "Mortalidade por desnutrição 2019"
temp_param_table$label[temp_param_table$var == "subnutricao_2020_percent_da_populacao"] <- "Malnutrition 2020"
temp_param_table$label[temp_param_table$var == "abastecimento_de_agua_adequado_2020_percent_da_populacao"] <- "Adequate Water Supply, 2020"
temp_param_table$label[temp_param_table$var == "esgotamento_sanitario_adequado_2020_percent_da_populacao"] <- "Adequate sanitary sewerage, 2020"
temp_param_table$label[temp_param_table$var == "indice_atendimento_de_agua_2019_percent_da_populacao"] <- "Water Supply Index, 2019"
temp_param_table$label[temp_param_table$var == "coleta_de_lixo_2020_percent_de_domicilios"] <- "Waste collection, 2020"
temp_param_table$label[temp_param_table$var == "domicilios_com_iluminacao_eletrica_adequadas_2020_percent_de_domicilios"] <- "Households with adequate electrical lighting, 2020"
temp_param_table$label[temp_param_table$var == "domicilios_com_paredes_adequadas_2020_percent_de_domicilios"] <- "Households with proper walls, 2020"
temp_param_table$label[temp_param_table$var == "domicilios_com_pisos_adequados_2020_percent_de_domicilios"] <- "Households with proper floors, 2020"
temp_param_table$label[temp_param_table$var == "assassinatos_de_jovens_2019_obitos_100_000_habitantes_de_15_a_29_anos"] <- "Youth murders, 2019"
temp_param_table$label[temp_param_table$var == "assassinatos_de_jovens_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Categorical: youth homicide rate, 2019"
temp_param_table$label[temp_param_table$var == "homicidios_2019_obitos_100_000_habitantes"] <- "Homicides, 2019"
temp_param_table$label[temp_param_table$var == "homicidios_categorico_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Categorical: Homicide rate, 2019"
temp_param_table$label[temp_param_table$var == "mortes_por_acidente_no_transito_obitos_100_000_habitantes"] <- "Traffic accidents deaths, 2019"
temp_param_table$label[temp_param_table$var == "distorcao_idade_serie_ensino_fundamental_2019_percent_de_alunos"] <- "Age-grade distortion Primary Education, 2019"
temp_param_table$label[temp_param_table$var == "distorcao_idade_serie_ensino_medio_2019_percent_de_alunos"] <- "Age-grade distortion High School, 2019"
temp_param_table$label[temp_param_table$var == "taxa_de_abandono_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "School dropout rate in Elementary School, 2019"
temp_param_table$label[temp_param_table$var == "taxa_de_reprovacao_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "Failing rate in Elementary School, 2019"
temp_param_table$label[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "Qualidade da educação - Ideb 2019"
temp_param_table$label[temp_param_table$var == "densidade_internet_banda_larga_fixa_2020_no_de_acessos_100_domicilios"] <- "Fixed Broadband Internet Density, 2020"
temp_param_table$label[temp_param_table$var == "densidade_telefonia_fixa_2020_no_de_acessos_100_domicilios"] <- "Density of fixed telephony, 2020"
temp_param_table$label[temp_param_table$var == "densidade_telefonia_movel_2020_no_de_acessos_100_habitantes"] <- "Density of mobile telephony, 2020"
temp_param_table$label[temp_param_table$var == "densidade_tv_por_assinatura_2020_no_de_acessos_100_domicilios"] <- "Density of Cable-TV, 2020"
temp_param_table$label[temp_param_table$var == "mortalidade_por_doencas_circulatorias_2019_obitos_100_000_habitantes"] <- "Mortality from circulatory diseases, 2019"
temp_param_table$label[temp_param_table$var == "mortalidade_por_doencas_respiratorias_2019_obitos_100_000_habitantes"] <- "Mortality from respiratory diseases, 2019"
temp_param_table$label[temp_param_table$var == "mortalidade_por_diabetes_mellitus_2019_obitos_100_000_habitantes"] <- "Mortality from diabetes melittus, 2019"
temp_param_table$label[temp_param_table$var == "mortalidade_por_neoplasias_cancer_2019_obitos_100_000_habitantes"] <- "Mortality from neoplasms (cancer), 2019"
temp_param_table$label[temp_param_table$var == "taxa_de_suicidios_2019_obitos_100_000_habitantes"] <- "Suicide rate, 2019"
temp_param_table$label[temp_param_table$var == "areas_protegidas_2020_percent_area_total_do_municipio"] <- "Protected Areas, 2020"
temp_param_table$label[temp_param_table$var == "desmatamento_acumulado_2020_percent_area_total_do_municipio"] <- "Accumulated deforestation, 2020"
temp_param_table$label[temp_param_table$var == "desmatamento_recente_2018_2019_2020_percent_do_desmatamento_total"] <- "Recent deforestation: 2018, 2019, 2020"
temp_param_table$label[temp_param_table$var == "emissoes_co2_2018_ton_co2eq_gwp_ar5_habitante"] <- "CO2 Emissions, 2018"
temp_param_table$label[temp_param_table$var == "focos_de_calor_2020_na_de_focos_1_000_habitantes"] <- "Heat Spots, 2020"
temp_param_table$label[temp_param_table$var == "diversidade_partidaria_2020_percent_de_vereadores_eleitos_de_partidos_diferentes"] <- "Party Diversity, 2020"
temp_param_table$label[temp_param_table$var == "mobilidade_urbana_transporte_publico_2020_no_de_onibus_e_micro_onibus_1_000_habitantes"] <- "Urban mobility (public transportation), 2020"
temp_param_table$label[temp_param_table$var == "acesso_a_cultura_e_lazer_2018_categorica_1_10"] <- "Access to culture or leisure, 2018"
temp_param_table$label[temp_param_table$var == "maes_adolescentes_ou_criancas_2019_percent_de_filhos_de_maes_adolescentes_ou_criancas"] <- "Teenage mothers or children mothers, 2019"
temp_param_table$label[temp_param_table$var == "trabalho_infantil_2019_no_de_familias_com_ao_menos_1_membro_em_trabalho_infantil_1_000_familias"] <- "Child Labor, 2019"
temp_param_table$label[temp_param_table$var == "vulnerabilidade_familiar_2019_percent_de_filhos_de_maes_solteiras"] <- "Family vulnerability, 2019"
temp_param_table$label[temp_param_table$var == "violencia_contra_indigenas_2014_no_de_casos_1_000_indigenas"] <- "Violence against indigenous people, 2014"
temp_param_table$label[temp_param_table$var == "violencia_contra_indigenas_2014_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_0_1_2_7_3_2_7_8_8_4_8_8_20_8_5_20_8"] <- "Categorical: Violence against indigenous people, 2014 "
temp_param_table$label[temp_param_table$var == "violencia_contra_mulheres_2019_no_de_casos_100_000_mulheres"] <- "Violence against women, 2019"
temp_param_table$label[temp_param_table$var == "violencia_infantil_2019_no_de_casos_100_000_pessoas_de_0_14_anos"] <- "Violence against children, 2019"
temp_param_table$label[temp_param_table$var == "violencia_infantil_2019_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_1_1_40_1_3_40_1_133_1_4_133_1_496_0_5_496_0"] <- "Categorical: Violence against children 2019"
temp_param_table$label[temp_param_table$var == "empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Higher education jobs, 2019"
temp_param_table$label[temp_param_table$var == "mulheres_com_empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Women with higher education jobs, 2019"
temp_param_table$label[temp_param_table$var == "group"] <- ""
temp_param_table$label[temp_param_table$var == "geometry"] <- ""


# unidade variables
# unidade variables
temp_param_table$unidade[temp_param_table$var == "cod_ibge"] <- "General"
temp_param_table$unidade[temp_param_table$var == "nm_municip"] <- "General"
temp_param_table$unidade[temp_param_table$var == "uf"] <- "General"
temp_param_table$unidade[temp_param_table$var == "ips_amazonia_2021"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "necessidades_humanas_basicas"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "fundamentos_para_o_bem_estar"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "oportunidades"] <- "IPS Amazônia 2021 - Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "nutricao_e_cuidados_medicos_basicos"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "agua_e_saneamento"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "moradia"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "seguranca_pessoal"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "acesso_ao_conhecimento_basico"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "acesso_a_informacao_e_comunicacao"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "saude_e_bem_estar"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "qualidade_do_meio_ambiente"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "direitos_individuais"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "liberdade_individual_e_de_escolha"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "inclusao_social"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "acesso_a_educacao_superior"] <- "Scale from 0 to 100"
temp_param_table$unidade[temp_param_table$var == "mortalidade_infantil_ate_5_anos_2019_obitos_1_000_nasc_vivos"] <- "Deaths per 1,000 live births"
temp_param_table$unidade[temp_param_table$var == "mortalidade_materna_2019_obitos_maternos_100_000_nascidos_vivos"] <- "Maternal deaths per 100,000 live births"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_doencas_infecciosas_2019_obitos_100_000_habitantes"] <- "Deaths per 100,000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_desnutricao_2019_obitos_100_000_habitantes"] <- "Deaths per 100,000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "subnutricao_2020_percent_da_populacao"] <- "% of the population"
temp_param_table$unidade[temp_param_table$var == "abastecimento_de_agua_adequado_2020_percent_da_populacao"] <- "% of households"
temp_param_table$unidade[temp_param_table$var == "esgotamento_sanitario_adequado_2020_percent_da_populacao"] <- "% of households"
temp_param_table$unidade[temp_param_table$var == "indice_atendimento_de_agua_2019_percent_da_populacao"] <- "% of the population"
temp_param_table$unidade[temp_param_table$var == "coleta_de_lixo_2020_percent_de_domicilios"] <- "% of households"
temp_param_table$unidade[temp_param_table$var == "domicilios_com_iluminacao_eletrica_adequadas_2020_percent_de_domicilios"] <- "% of households"
temp_param_table$unidade[temp_param_table$var == "domicilios_com_paredes_adequadas_2020_percent_de_domicilios"] <- "% of households"
temp_param_table$unidade[temp_param_table$var == "domicilios_com_pisos_adequados_2020_percent_de_domicilios"] <- "% of households"
temp_param_table$unidade[temp_param_table$var == "assassinatos_de_jovens_2019_obitos_100_000_habitantes_de_15_a_29_anos"] <- "Deaths/100,000 inhabitants aged 15-29 years"
temp_param_table$unidade[temp_param_table$var == "assassinatos_de_jovens_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Scored on a scale of 1-6"
temp_param_table$unidade[temp_param_table$var == "homicidios_2019_obitos_100_000_habitantes"] <- "Deaths per 100,000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "homicidios_categorico_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Scored on a scale of 1-6"
temp_param_table$unidade[temp_param_table$var == "mortes_por_acidente_no_transito_obitos_100_000_habitantes"] <- "Deaths per 100,000 inhabitants "
temp_param_table$unidade[temp_param_table$var == "distorcao_idade_serie_ensino_fundamental_2019_percent_de_alunos"] <- "% of students"
temp_param_table$unidade[temp_param_table$var == "distorcao_idade_serie_ensino_medio_2019_percent_de_alunos"] <- "% of students"
temp_param_table$unidade[temp_param_table$var == "taxa_de_abandono_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "% of students"
temp_param_table$unidade[temp_param_table$var == "taxa_de_reprovacao_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "% of students"
temp_param_table$unidade[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "Ideb (0-10)"
temp_param_table$unidade[temp_param_table$var == "densidade_internet_banda_larga_fixa_2020_no_de_acessos_100_domicilios"] <- "number of accesses/100 households"
temp_param_table$unidade[temp_param_table$var == "densidade_telefonia_fixa_2020_no_de_acessos_100_domicilios"] <- "number of accesses/100 households"
temp_param_table$unidade[temp_param_table$var == "densidade_telefonia_movel_2020_no_de_acessos_100_habitantes"] <- "number of accesses/100 households"
temp_param_table$unidade[temp_param_table$var == "densidade_tv_por_assinatura_2020_no_de_acessos_100_domicilios"] <- "number of accesses/100 households"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_doencas_circulatorias_2019_obitos_100_000_habitantes"] <- "Deaths per 100,000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_doencas_respiratorias_2019_obitos_100_000_habitantes"] <- "Deaths per 100,000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_diabetes_mellitus_2019_obitos_100_000_habitantes"] <- "Deaths per 100,000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "mortalidade_por_neoplasias_cancer_2019_obitos_100_000_habitantes"] <- "Deaths per 100,000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "taxa_de_suicidios_2019_obitos_100_000_habitantes"] <- "Deaths per 100,000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "areas_protegidas_2020_percent_area_total_do_municipio"] <- "% municipalitie's total area"
temp_param_table$unidade[temp_param_table$var == "desmatamento_acumulado_2020_percent_area_total_do_municipio"] <- "% municipalitie's total area"
temp_param_table$unidade[temp_param_table$var == "desmatamento_recente_2018_2019_2020_percent_do_desmatamento_total"] <- "% of total deforestation"
temp_param_table$unidade[temp_param_table$var == "emissoes_co2_2018_ton_co2eq_gwp_ar5_habitante"] <- "Tons of CO2eq GWP-AR5 per inhabitant"
temp_param_table$unidade[temp_param_table$var == "focos_de_calor_2020_na_de_focos_1_000_habitantes"] <- "number of spots per 1000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "diversidade_partidaria_2020_percent_de_vereadores_eleitos_de_partidos_diferentes"] <- "% of councilors elected of different parties"
temp_param_table$unidade[temp_param_table$var == "mobilidade_urbana_transporte_publico_2020_no_de_onibus_e_micro_onibus_1_000_habitantes"] <- "Number of buses and micro-buses per 1000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "acesso_a_cultura_e_lazer_2018_categorica_1_10"] <- "Categorical (0 = no structure, 1 = minimal structure to 10 = all structures)"
temp_param_table$unidade[temp_param_table$var == "maes_adolescentes_ou_criancas_2019_percent_de_filhos_de_maes_adolescentes_ou_criancas"] <- "%"
temp_param_table$unidade[temp_param_table$var == "trabalho_infantil_2019_no_de_familias_com_ao_menos_1_membro_em_trabalho_infantil_1_000_familias"] <- "No. of families with at least 1 member in child labor per 1,000 families"
temp_param_table$unidade[temp_param_table$var == "vulnerabilidade_familiar_2019_percent_de_filhos_de_maes_solteiras"] <- "% "
temp_param_table$unidade[temp_param_table$var == "violencia_contra_indigenas_2014_no_de_casos_1_000_indigenas"] <- "Number of cases per 1000 indigineous people"
temp_param_table$unidade[temp_param_table$var == "violencia_contra_indigenas_2014_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_0_1_2_7_3_2_7_8_8_4_8_8_20_8_5_20_8"] <- "Scored in a scale from 1-5"
temp_param_table$unidade[temp_param_table$var == "violencia_contra_mulheres_2019_no_de_casos_100_000_mulheres"] <- "Nº de casos de violência por 100 mil mulheres"
temp_param_table$unidade[temp_param_table$var == "violencia_infantil_2019_no_de_casos_100_000_pessoas_de_0_14_anos"] <- "Number of cases of violence per 100,000 people aged 0-14 years"
temp_param_table$unidade[temp_param_table$var == "violencia_infantil_2019_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_1_1_40_1_3_40_1_133_1_4_133_1_496_0_5_496_0"] <- "Scored in a scale from 1-5"
temp_param_table$unidade[temp_param_table$var == "empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Number of jobs per 100,000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "mulheres_com_empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Number of jobs per 100,000 inhabitants"
temp_param_table$unidade[temp_param_table$var == "group"] <- ""
temp_param_table$unidade[temp_param_table$var == "geometry"] <- ""

# var_group variables
temp_param_table$var_group[temp_param_table$var == "cod_ibge"] <- "General"
temp_param_table$var_group[temp_param_table$var == "nm_municip"] <- "General"
temp_param_table$var_group[temp_param_table$var == "uf"] <- "General"
temp_param_table$var_group[temp_param_table$var == "ips_amazonia_2021"] <- "IMAZON - Social Progress Index (IPS)"
temp_param_table$var_group[temp_param_table$var == "necessidades_humanas_basicas"] <- "Main Dimensions"
temp_param_table$var_group[temp_param_table$var == "fundamentos_para_o_bem_estar"] <- "Main Dimensions"
temp_param_table$var_group[temp_param_table$var == "oportunidades"] <- "Main Dimensions"
temp_param_table$var_group[temp_param_table$var == "nutricao_e_cuidados_medicos_basicos"] <- "Components: Basic Human Needs"
temp_param_table$var_group[temp_param_table$var == "agua_e_saneamento"] <- "Components: Basic Human Needs"
temp_param_table$var_group[temp_param_table$var == "moradia"] <- "Components: Basic Human Needs"
temp_param_table$var_group[temp_param_table$var == "seguranca_pessoal"] <- "Components: Basic Human Needs"
temp_param_table$var_group[temp_param_table$var == "acesso_ao_conhecimento_basico"] <- "Components: Well-Being Fundamentals "
temp_param_table$var_group[temp_param_table$var == "acesso_a_informacao_e_comunicacao"] <- "Components: Well-Being Fundamentals "
temp_param_table$var_group[temp_param_table$var == "saude_e_bem_estar"] <- "Components: Well-Being Fundamentals "
temp_param_table$var_group[temp_param_table$var == "qualidade_do_meio_ambiente"] <- "Components: Well-Being Fundamentals "
temp_param_table$var_group[temp_param_table$var == "direitos_individuais"] <- "Components: Oportunities"
temp_param_table$var_group[temp_param_table$var == "liberdade_individual_e_de_escolha"] <- "Components: Oportunities"
temp_param_table$var_group[temp_param_table$var == "inclusao_social"] <- "Components: Oportunities"
temp_param_table$var_group[temp_param_table$var == "acesso_a_educacao_superior"] <- "Components: Oportunities"
temp_param_table$var_group[temp_param_table$var == "mortalidade_infantil_ate_5_anos_2019_obitos_1_000_nasc_vivos"] <- "Indicators: Nutrition and Basic Medical Care"
temp_param_table$var_group[temp_param_table$var == "mortalidade_materna_2019_obitos_maternos_100_000_nascidos_vivos"] <- "Indicators: Nutrition and Basic Medical Care"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_doencas_infecciosas_2019_obitos_100_000_habitantes"] <- "Indicators: Nutrition and Basic Medical Care"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_desnutricao_2019_obitos_100_000_habitantes"] <- "Indicators: Nutrition and Basic Medical Care"
temp_param_table$var_group[temp_param_table$var == "subnutricao_2020_percent_da_populacao"] <- "Indicators: Nutrition and Basic Medical Care"
temp_param_table$var_group[temp_param_table$var == "abastecimento_de_agua_adequado_2020_percent_da_populacao"] <- "Indicators: Sanitation"
temp_param_table$var_group[temp_param_table$var == "esgotamento_sanitario_adequado_2020_percent_da_populacao"] <- "Indicators: Sanitation"
temp_param_table$var_group[temp_param_table$var == "indice_atendimento_de_agua_2019_percent_da_populacao"] <- "Indicators: Sanitation"
temp_param_table$var_group[temp_param_table$var == "coleta_de_lixo_2020_percent_de_domicilios"] <- "Indicators: Housing"
temp_param_table$var_group[temp_param_table$var == "domicilios_com_iluminacao_eletrica_adequadas_2020_percent_de_domicilios"] <- "Indicators: Housing"
temp_param_table$var_group[temp_param_table$var == "domicilios_com_paredes_adequadas_2020_percent_de_domicilios"] <- "Indicators: Housing"
temp_param_table$var_group[temp_param_table$var == "domicilios_com_pisos_adequados_2020_percent_de_domicilios"] <- "Indicators: Housing"
temp_param_table$var_group[temp_param_table$var == "assassinatos_de_jovens_2019_obitos_100_000_habitantes_de_15_a_29_anos"] <- "Indicators: Personal Safety"
temp_param_table$var_group[temp_param_table$var == "assassinatos_de_jovens_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Indicators: Personal Safety"
temp_param_table$var_group[temp_param_table$var == "homicidios_2019_obitos_100_000_habitantes"] <- "Indicators: Personal Safety"
temp_param_table$var_group[temp_param_table$var == "homicidios_categorico_2019_taxa_pontuada_em_uma_escala_de_1_6_1_0_2_1_6_3_6_10_4_10_20_5_20_40_6_40"] <- "Indicators: Personal Safety"
temp_param_table$var_group[temp_param_table$var == "mortes_por_acidente_no_transito_obitos_100_000_habitantes"] <- "Indicators: Personal Safety"
temp_param_table$var_group[temp_param_table$var == "distorcao_idade_serie_ensino_fundamental_2019_percent_de_alunos"] <- "Indicators: Access to Basic Knowledge"
temp_param_table$var_group[temp_param_table$var == "distorcao_idade_serie_ensino_medio_2019_percent_de_alunos"] <- "Indicators: Access to Basic Knowledge"
temp_param_table$var_group[temp_param_table$var == "taxa_de_abandono_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "Indicators: Access to Basic Knowledge"
temp_param_table$var_group[temp_param_table$var == "taxa_de_reprovacao_escolar_ensino_fundamental_2019_percent_de_alunos"] <- "Indicators: Access to Basic Knowledge"
temp_param_table$var_group[temp_param_table$var == "qualidade_da_educacao_ideb_2019"] <- "Indicators: Access to Basic Knowledge"
temp_param_table$var_group[temp_param_table$var == "densidade_internet_banda_larga_fixa_2020_no_de_acessos_100_domicilios"] <- "Indicators: Access to Information and Communications"
temp_param_table$var_group[temp_param_table$var == "densidade_telefonia_fixa_2020_no_de_acessos_100_domicilios"] <- "Indicators: Access to Information and Communications"
temp_param_table$var_group[temp_param_table$var == "densidade_telefonia_movel_2020_no_de_acessos_100_habitantes"] <- "Indicators: Access to Information and Communications"
temp_param_table$var_group[temp_param_table$var == "densidade_tv_por_assinatura_2020_no_de_acessos_100_domicilios"] <- "Indicators: Access to Information and Communications"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_doencas_circulatorias_2019_obitos_100_000_habitantes"] <- "Indicators: Health and Well-Being"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_doencas_respiratorias_2019_obitos_100_000_habitantes"] <- "Indicators: Health and Well-Being"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_diabetes_mellitus_2019_obitos_100_000_habitantes"] <- "Indicators: Health and Well-Being"
temp_param_table$var_group[temp_param_table$var == "mortalidade_por_neoplasias_cancer_2019_obitos_100_000_habitantes"] <- "Indicators: Health and Well-Being"
temp_param_table$var_group[temp_param_table$var == "taxa_de_suicidios_2019_obitos_100_000_habitantes"] <- "Indicators: Health and Well-Being"
temp_param_table$var_group[temp_param_table$var == "areas_protegidas_2020_percent_area_total_do_municipio"] <- "Indicators: Environmental Quality"
temp_param_table$var_group[temp_param_table$var == "desmatamento_acumulado_2020_percent_area_total_do_municipio"] <- "Indicators: Environmental Quality"
temp_param_table$var_group[temp_param_table$var == "desmatamento_recente_2018_2019_2020_percent_do_desmatamento_total"] <- "Indicators: Environmental Quality"
temp_param_table$var_group[temp_param_table$var == "emissoes_co2_2018_ton_co2eq_gwp_ar5_habitante"] <- "Indicators: Environmental Quality"
temp_param_table$var_group[temp_param_table$var == "focos_de_calor_2020_na_de_focos_1_000_habitantes"] <- "Indicators: Environmental Quality"
temp_param_table$var_group[temp_param_table$var == "diversidade_partidaria_2020_percent_de_vereadores_eleitos_de_partidos_diferentes"] <- "Indicators: Individual Rights"
temp_param_table$var_group[temp_param_table$var == "mobilidade_urbana_transporte_publico_2020_no_de_onibus_e_micro_onibus_1_000_habitantes"] <- "Indicators: Individual Rights"
temp_param_table$var_group[temp_param_table$var == "acesso_a_cultura_e_lazer_2018_categorica_1_10"] <- "Indicators: Individual Freedom"
temp_param_table$var_group[temp_param_table$var == "maes_adolescentes_ou_criancas_2019_percent_de_filhos_de_maes_adolescentes_ou_criancas"] <- "Indicators: Individual Freedom"
temp_param_table$var_group[temp_param_table$var == "trabalho_infantil_2019_no_de_familias_com_ao_menos_1_membro_em_trabalho_infantil_1_000_familias"] <- "Indicators: Individual Freedom"
temp_param_table$var_group[temp_param_table$var == "vulnerabilidade_familiar_2019_percent_de_filhos_de_maes_solteiras"] <- "Indicators: Individual Freedom"
temp_param_table$var_group[temp_param_table$var == "violencia_contra_indigenas_2014_no_de_casos_1_000_indigenas"] <- "Indicators: Social Inclusion"
temp_param_table$var_group[temp_param_table$var == "violencia_contra_indigenas_2014_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_0_1_2_7_3_2_7_8_8_4_8_8_20_8_5_20_8"] <- "Indicators: Social Inclusion"
temp_param_table$var_group[temp_param_table$var == "violencia_contra_mulheres_2019_no_de_casos_100_000_mulheres"] <- "Indicators: Social Inclusion"
temp_param_table$var_group[temp_param_table$var == "violencia_infantil_2019_no_de_casos_100_000_pessoas_de_0_14_anos"] <- "Indicators: Social Inclusion"
temp_param_table$var_group[temp_param_table$var == "violencia_infantil_2019_taxa_pontuada_em_uma_escala_de_1_5_1_0_2_1_1_40_1_3_40_1_133_1_4_133_1_496_0_5_496_0"] <- "Indicators: Social Inclusion"
temp_param_table$var_group[temp_param_table$var == "empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Indicators: Access to Higher Education"
temp_param_table$var_group[temp_param_table$var == "mulheres_com_empregos_ensino_superior_2019_no_de_empregos_por_100_mil_habitantes"] <- "Indicators: Access to Higher Education"
temp_param_table$var_group[temp_param_table$var == "group"] <- ""
temp_param_table$var_group[temp_param_table$var == "geometry"] <- ""

# label data category
temp_param_table$categoria[temp_param_table$var == "geometry"] <- ""
temp_param_table$categoria[temp_param_table$var == "estado"] <- ""
temp_param_table$categoria[temp_param_table$var == "group"] <- ""

# subcategoria variables
temp_param_table$subcategoria[temp_param_table$var == "geometry"] <- ""
temp_param_table$subcategoria[temp_param_table$var == "estado"] <- ""
temp_param_table$subcategoria[temp_param_table$var == "group"] <- ""

# block variables in graphs y-axis
temp_param_table$y[temp_param_table$var == "cod_ibge"] <- FALSE # "Código do município"
temp_param_table$y[temp_param_table$var == "nm_municip"] <- FALSE # "nm_municip"
temp_param_table$y[temp_param_table$var == "uf"] <- FALSE # "uf_x"
temp_param_table$y[temp_param_table$var == "ano"] <- FALSE # "ano"
temp_param_table$y[temp_param_table$var == "geometry"] <- FALSE # "geometry"
temp_param_table$y[temp_param_table$var == "group"] <- FALSE # "estado"
temp_param_table$y[temp_param_table$var == "estado"] <- FALSE # "estado"
temp_param_table$y[temp_param_table$var == "group"] <- FALSE 

# block variables in graphs x-axis
temp_param_table$x[temp_param_table$var == "cod_ibge"] <- FALSE # "Código do município"
temp_param_table$x[temp_param_table$var == "nm_municip"] <- FALSE # "nm_municip"
temp_param_table$x[temp_param_table$var == "uf"] <- FALSE # "uf_x"
temp_param_table$x[temp_param_table$var == "ano"] <- FALSE # "ano"
temp_param_table$x[temp_param_table$var == "geometry"] <- FALSE # "geometry"
temp_param_table$x[temp_param_table$var == "estado"] <- FALSE # "estado"
temp_param_table$x[temp_param_table$var == "group"] <- FALSE 

# allow variables in graphs size, color, and slider-axis
temp_param_table$color[temp_param_table$var == "estado"] <- TRUE #

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "./data/ips_2021_dic_en.csv", fileEncoding = "UTF-8")

