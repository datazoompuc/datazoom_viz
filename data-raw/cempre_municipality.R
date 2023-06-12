############################################################
#### Generate rds data in the folder ./data/ 
############################################################

devtools::install_github("datazoompuc/datazoom.amazonia")
library(tidyverse)
library(datazoom.amazonia)
library(labelled)

cempre_municipality_antigo <- readRDS(file = "./data/cempre_municipality_dza.rds")

year_max <- max(as.numeric(cempre_municipality_antigo$ano))

cempre_update <- load_cempre(dataset = "cempre", 
                             raw_data = FALSE, 
                             geo_level = "municipality", 
                             time_period = year_max + 1,
                             language = "pt") %>%
     rename(cod_ibge = geo_id,
            cempre_n_empresas_organizacoes = numero_de_empresas_e_outras_organizacoes,
            cempre_n_ocupados = pessoal_ocupado_total,
            cempre_n_ocupados_assalariados = pessoal_ocupado_assalariado,
            cempre_salarios_remuneracoes = salarios_e_outras_remuneracoes) %>%
    relocate(cod_ibge,ano,cempre_n_empresas_organizacoes,cempre_n_ocupados,cempre_n_ocupados_assalariados)

class(cempre_update$cod_ibge) <- "character"
class(cempre_update$ano) <- "integer"
class(cempre_update$cempre_n_empresas_organizacoes) <- "integer"
class(cempre_update$cempre_n_ocupados) <- "integer"
class(cempre_update$cempre_n_ocupados_assalariados) <- "integer"
class(cempre_update$cempre_salarios_remuneracoes) <- "integer"

cempre_final <- cempre_municipality_antigo %>%
    bind_rows(cempre_update)

saveRDS(cempre_final, file = "./data/cempre_municipality_dza.rds")



