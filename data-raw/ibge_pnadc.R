# call packages
library(tidyverse)
library(haven)
library(tibble)
library(zoo)
library(tidyr)

library(datazoom.social)
# make sure it is updated and from github

#################################################
## Mercado de Trabalho na Amazônia Legal
## Ouput data from:
## github: https://github.com/datazoompuc/datazoom_labour_amazon
#################################################

# set path to raw data
#github_folder_path <- "https://github.com/datazoompuc/datazoom_labour_amazon/raw/main/Labour_Market/output/" # set github structure path

# PNAD files must be downloaded to the computer
source <- "../data/PNADCR"

# only run this if not already downloaded: takes a long time
# não precisa baixar tudo de uma vez, só ter os .rds de cada trimestre
load_pnadc(save_to = source, 2012:2025, raw_data = FALSE, panel = "none")

# and then all files must be read

files <- list.files(source, pattern = "*.rds", full.names = TRUE)

# function that calculates summary statistics by grouping variable

describe_pnad <- function(df) {
    
    # calculando numeros absolutos
    
    df <- df %>%
        rename("peso" = V1028) %>%
        mutate( # so that the ratios make sense
            nem_nem = nem_nem * pia,
            desalentado = desalentado * pia) %>%
        group_by(Ano, Trimestre, .add = TRUE) %>%
        summarise(
            across(
                c("pia", "ocupado", "desocupado", "formal",
                  "informal", "fora_forca_trab", "forca_trab",
                  "idade_de_trabalhar", "pea", "desempregado",
                  "desalentado", "nem_nem", "empregado_sc",
                  "empregado_cc", "conta_propria", "conta_propria_contrib",
                  "conta_propria_nao_contrib", "empregador",
                  "militar_estatutario", "home_office",
                  "rendimento_habitual_real"),
                ~ sum(. * peso, na.rm = TRUE)
            )
        )
        
     # calculando taxas
        
    df <- df %>%
        mutate(
            # pnad trabalho
            taxa_participacao = pea/pia,
            taxa_ocupacao = ocupado/pia,
            taxa_desemprego = desempregado/forca_trab,
            taxa_informalidade = informal/ocupado,
            taxa_desalento = desalentado/pia,
            taxa_nem_nem = nem_nem/pia,
            # pnad insercao
            prop_empregado_sc = empregado_sc/ocupado,
            prop_empregado_cc = empregado_cc/ocupado,
            prop_conta_propria = conta_propria/ocupado,
            prop_conta_propria_contrib = conta_propria_contrib/ocupado,
            prop_conta_propria_nao_contrib = conta_propria_nao_contrib/ocupado,
            prop_empregador = empregador/ocupado,
            prop_militar_estatutario = militar_estatutario/ocupado,
            prop_home_office = home_office/ocupado,
            # renda
            rendimento_medio = rendimento_habitual_real/ocupado,
            massa_salarial = rendimento_habitual_real
        )
    
    return(df)
}

# All of Brazil

describe_brazil <- function(df) {
    df1 <- df %>%
        describe_pnad() %>%
        mutate(
            group = "Brasil",
            composicao_demografica = "Todos"
        )
    
    df2 <- df %>%
        tidyr::drop_na(sexo) %>%
        group_by(sexo) %>%
        describe_pnad() %>%
        mutate(
            group = "Brasil",
            composicao_demografica = sexo
        )
    
    df3 <- df %>%
        tidyr::drop_na(faixa_idade) %>%
        group_by(faixa_idade) %>%
        describe_pnad() %>%
        mutate(
            group = "Brasil",
            composicao_demografica = faixa_idade
        )
    
    df4 <- df %>%
        tidyr::drop_na(faixa_educ) %>%
        group_by(faixa_educ) %>%
        describe_pnad() %>%
        mutate(
            group = "Brasil",
            composicao_demografica = faixa_educ
        )
    
    bind_rows(
        df1, df2, df3, df4
    )
}

# By region

describe_region <- function(df) {
    df1 <- df %>%
        tidyr::drop_na(regiao) %>%
        group_by(regiao) %>%
        describe_pnad() %>%
        mutate(
            group = regiao,
            composicao_demografica = "Todos"
        )
    
    df2 <- df %>%
        tidyr::drop_na(regiao, sexo) %>%
        group_by(regiao, sexo) %>%
        describe_pnad() %>%
        mutate(
            group = regiao,
            composicao_demografica = sexo
        )
    
    df3 <- df %>%
        tidyr::drop_na(regiao, faixa_idade) %>%
        group_by(regiao, faixa_idade) %>%
        describe_pnad() %>%
        mutate(
            group = regiao,
            composicao_demografica = faixa_idade
        )
    
    df4 <- df %>%
        tidyr::drop_na(regiao, faixa_educ) %>%
        group_by(regiao, faixa_educ) %>%
        describe_pnad() %>%
        mutate(
            group = regiao,
            composicao_demografica = faixa_educ
        )
    
    bind_rows(
        df1, df2, df3, df4
    )
}

# By legal amazon

describe_amazon <- function(df) {
    df <- df %>%
        mutate(legal_amazon = ifelse(UF %in% c(11, 12, 13, 14, 15, 16, 17, 21, 51),
                                     "Amaz\u00f4nia Legal", "Fora da Amaz\u00f4nia Legal"))
    
    df1 <- df %>%
        tidyr::drop_na(legal_amazon) %>%
        group_by(legal_amazon) %>%
    describe_pnad() %>%
        mutate(
            group = legal_amazon,
            composicao_demografica = "Todos"
        )
    
    df2 <- df %>%
        tidyr::drop_na(legal_amazon, sexo) %>%
        group_by(legal_amazon, sexo) %>%
        describe_pnad() %>%
        mutate(
            group = legal_amazon,
            composicao_demografica = sexo
        )
    
    df3 <- df %>%
        tidyr::drop_na(legal_amazon, faixa_idade) %>%
        group_by(legal_amazon, faixa_idade) %>%
        describe_pnad() %>%
        mutate(
            group = legal_amazon,
            composicao_demografica = faixa_idade
        )
    
    df4 <- df %>%
        tidyr::drop_na(legal_amazon, faixa_educ) %>%
        group_by(legal_amazon, faixa_educ) %>%
        describe_pnad() %>%
        mutate(
            group = legal_amazon,
            composicao_demografica = faixa_educ
        )
    
    bind_rows(
        df1, df2, df3, df4
    )
}

# By state

describe_states <- function(df) {
    df <- df %>%
        dplyr::mutate(
            sigla_uf = dplyr::case_match(
                UF,
                11 ~ "RO",
                12 ~ "AC",
                13 ~ "AM",
                14 ~ "RO",
                15 ~ "PA",
                16 ~ "AP",
                17 ~ "TO",
                21 ~ "MA",
                22 ~ "PI",
                23 ~ "CE",
                24 ~ "RN",
                25 ~ "PB",
                26 ~ "PE",
                27 ~ "AL",
                28 ~ "SE",
                29 ~ "BA",
                31 ~ "MG",
                32 ~ "ES",
                33 ~ "RJ",
                35 ~ "SP",
                41 ~ "PR",
                42 ~ "SC",
                43 ~ "RS",
                50 ~ "MS",
                51 ~ "MT",
                52 ~ "GO",
                53 ~ "DF"
            )
        )
    
    df1 <- df %>%
        tidyr::drop_na(sigla_uf) %>%
        group_by(sigla_uf) %>%
    describe_pnad() %>%
        mutate(
            group = sigla_uf,
            composicao_demografica = "Todos"
        )
    
    df2 <- df %>%
        tidyr::drop_na(sigla_uf, sexo) %>%
        group_by(sigla_uf, sexo) %>%
        describe_pnad() %>%
        mutate(
            group = sigla_uf,
            composicao_demografica = sexo
        )
    
    df3 <- df %>%
        tidyr::drop_na(sigla_uf, faixa_idade) %>%
        group_by(sigla_uf, faixa_idade) %>%
        describe_pnad() %>%
        mutate(
            group = sigla_uf,
            composicao_demografica = faixa_idade
        )
    
    df4 <- df %>%
        tidyr::drop_na(sigla_uf, faixa_educ) %>%
        group_by(sigla_uf, faixa_educ) %>%
        describe_pnad() %>%
        mutate(
            group = sigla_uf,
            composicao_demografica = faixa_educ
        )
    
    bind_rows(
        df1, df2, df3, df4
    )
}

# Running all of the above

describe_quarter <- function(df) {
    df1 <- describe_brazil(df)
    df2 <- describe_region(df)
    df3 <- describe_amazon(df)
    df4 <- describe_states(df)
    
    bind_rows(df1, df2, df3, df4)
}

# Big loop to run one of those for each quarter

dat <- purrr::map_dfr(
    files,
    function(file_name) {
        message(file_name)
        readr::read_rds(file_name) %>%
            describe_quarter()
    }
)

# setting up time variable

dat <- dat %>%
    mutate(Mes = 3*Trimestre - 2) %>%
    mutate(time = lubridate::make_date(Ano, Mes))

dat <- dat %>%
    mutate(prop_informal = taxa_informalidade)

# saving data file

readr::write_rds(dat, "data/ibge_pnadc_trabalho.rds", compress = "gz")

############################
## Dictionary -- Trabalho ##
############################

temp_param_table <- tibble::tibble(
    var = c("group", "composicao_demografica", "time",
            "taxa_participacao", "taxa_ocupacao",
            "taxa_desemprego", "taxa_informalidade",
            "taxa_desalento", "taxa_nem_nem"),
    x = TRUE,
    y = FALSE,
    color = TRUE,
    label = NA,
    desc = NA,
    var_group = "IBGE - PNAD Cont\u00ednua",
    categoria = "Economia",
    subcategoria = "Mercado de Trabalho"
)

temp_param_table <- temp_param_table %>%
    mutate(
        y = ifelse(
            stringr::str_detect(var, "taxa"), TRUE, FALSE
        ),
        label = dplyr::case_match(
            var,
            "group" ~ "Recorte Regional",
            "composicao_demografica" ~ "Composi\u00e7\u00e3o Demogr\u00e1fica",
            "time" ~ "Ano - Trimestre",
            "taxa_participacao" ~ "Taxa de Participa\u00e7\u00e3o",
            "taxa_ocupacao" ~ "Taxa de Ocupa\u00e7\u00e3o",
            "taxa_desemprego" ~ "Taxa de Desemprego",
            "taxa_informalidade" ~ "Taxa de Informalidade",
            "taxa_desalento" ~ "Taxa de Desalento",
            "taxa_nem_nem" ~ "Taxa de Nem-Nem"
        ),
        desc = label,
        desc = case_match(
            var,
            "taxa_participacao" ~ "Taxa de Participa\u00e7\u00e3o sobre a PIA",
            "taxa_ocupacao" ~ "Taxa de Ocupa\u00e7\u00e3o sobra a PIA",
            "taxa_desemprego" ~ "Taxa de Desemprego sobre a For\u00e7a de Trabalho",
            "taxa_informalidade" ~ "Taxa de Informalidade sobre os Ocupados",
            "taxa_desalento" ~ "Taxa de Desalento sobre a PIA",
            "taxa_nem_nem" ~ "Taxa de Nem-Nem sobre a PIA",
            .default = desc
        )
    )

write.csv(temp_param_table, file = "data/ibge_pnadc_trabalho_dic.csv", fileEncoding = "UTF-8")

## English dictionary

temp_param_table <- tibble::tibble(
    var = c("group", "composicao_demografica", "time",
            "taxa_participacao", "taxa_ocupacao",
            "taxa_desemprego", "taxa_informalidade",
            "taxa_desalento", "taxa_nem_nem"),
    x = TRUE,
    y = FALSE,
    color = TRUE,
    label = NA,
    desc = NA,
    var_group = "IBGE - Continuous PNAD",
    categoria = "Economia",
    subcategoria = "Mercado de Trabalho"
)

temp_param_table <- temp_param_table %>%
    mutate(
        y = ifelse(
            stringr::str_detect(var, "taxa"), TRUE, FALSE
        ),
        label = dplyr::case_match(
            var,
            "group" ~ "Region",
            "composicao_demografica" ~ "Demographic Group",
            "time" ~ "Year - Quarter",
            "taxa_participacao" ~ "Participation Rate",
            "taxa_ocupacao" ~ "Occupation Rate",
            "taxa_desemprego" ~ "Unemployment Rate",
            "taxa_informalidade" ~ "Informality Rate",
            "taxa_desalento" ~ "Discouraged Rate",
            "taxa_nem_nem" ~ "NEET Rate"
        ),
        desc = label,
        desc = case_match(
            var,
            "taxa_participacao" ~ "Participation Rate over the working age population",
            "taxa_ocupacao" ~ "Occupation Rate over the working age population",
            "taxa_desemprego" ~ "Unemployment Rate over the Workforce",
            "taxa_informalidade" ~ "Informality Rate over the Occupied",
            "taxa_desalento" ~ "Discouraged Rate over the working age population",
            "taxa_nem_nem" ~ "NEET Rate over the working age population",
            .default = desc
        )
    )

write.csv(temp_param_table, file = "data/ibge_pnadc_trabalho_dic_en.csv", fileEncoding = "UTF-8")

############################
## Dictionary -- Insercao ##
############################

temp_param_table <- tibble::tibble(
    var = c("group", "composicao_demografica", "time",
            "prop_empregado_sc", "prop_informal",
            "prop_empregado_cc", "prop_conta_propria", "prop_conta_propria_contrib",
            "prop_conta_propria_nao_contrib", "prop_empregador",
            "prop_militar_estatutario", "prop_home_office"),
    x = TRUE,
    y = FALSE,
    color = TRUE,
    label = NA,
    desc = NA,
    var_group = "IBGE - PNAD Cont\u00ednua",
    categoria = "Economia",
    subcategoria = "Mercado de Trabalho"
)

temp_param_table <- temp_param_table %>%
    mutate(
        y = ifelse(
            stringr::str_detect(var, "prop"), TRUE, FALSE
        ),
        label = dplyr::case_match(
            var,
            "group" ~ "Região",
            "composicao_demografica" ~ "Composição Demográfica",
            "time" ~ "Ano - Trimestre",
            "prop_empregado_sc" ~ "Proporção de Empregados Sem Carteira",
            "prop_empregado_cc" ~ "Proporção de Empregados Com Carteira",
            "prop_conta_propria" ~ "Proporção de Conta-Própria",
            "prop_conta_propria_contrib" ~ "Proporção de Conta-Própria Contribuintes",
            "prop_conta_propria_nao_contrib" ~ "Proporção de Conta-Própria Não-Contribuintes",
            "prop_empregador" ~ "Proporção de Empregadores",
            "prop_militar_estatutario" ~ "Proporção de Militares e Estatutários",
            "prop_home_office" ~ "Proporção de Home Office",
            "prop_informal" ~ "Proporção de Informais"
        ),
        desc = label,
        desc = ifelse(
            stringr::str_detect(var, "prop"), paste(label, "entre Total de Ocupados"), desc
        )
    )

write.csv(temp_param_table, file = "data/ibge_pnadc_trabalho_insercao_dic.csv", fileEncoding = "UTF-8")


################
## CNAE e COD ##
################

# All of Brazil

describe_brazil <- function(df) {
    df1 <- df %>%
        describe_pnad() %>%
        mutate(
            group = "Brasil",
            composicao_demografica = "Todos",
            id = "All"
        )
    
    df2 <- df %>%
        tidyr::drop_na(cnae_2dig) %>%
        group_by(cnae_2dig) %>%
        describe_pnad() %>%
        mutate(
            group = "Brasil",
            composicao_demografica = cnae_2dig,
            id = "CNAE"
        )
    
    df3 <- df %>%
        tidyr::drop_na(cod_2dig) %>%
        group_by(cod_2dig) %>%
        describe_pnad() %>%
        mutate(
            group = "Brasil",
            composicao_demografica = cod_2dig,
            id = "COD"
        )
    
    bind_rows(
        df1, df2, df3
    )
}

# By region

describe_region <- function(df) {
    df1 <- df %>%
        tidyr::drop_na(regiao) %>%
        group_by(regiao) %>%
        describe_pnad() %>%
        mutate(
            group = regiao,
            composicao_demografica = "Todos",
            id = "All"
        )
    
    df2 <- df %>%
        tidyr::drop_na(regiao, cnae_2dig) %>%
        group_by(regiao, cnae_2dig) %>%
        describe_pnad() %>%
        mutate(
            group = regiao,
            composicao_demografica = cnae_2dig,
            id = "CNAE"
        )
    
    df3 <- df %>%
        tidyr::drop_na(regiao, cod_2dig) %>%
        group_by(regiao, cod_2dig) %>%
        describe_pnad() %>%
        mutate(
            group = regiao,
            composicao_demografica = cod_2dig,
            id = "COD"
        )
    
    bind_rows(
        df1, df2, df3
    )
}

# By legal amazon

describe_amazon <- function(df) {
    df <- df %>%
        mutate(legal_amazon = ifelse(UF %in% c(11, 12, 13, 14, 15, 16, 17, 21, 51),
                                     "Amaz\u00f4nia Legal", "Fora da Amaz\u00f4nia Legal"))
    
    df1 <- df %>%
        tidyr::drop_na(legal_amazon) %>%
        group_by(legal_amazon) %>%
        describe_pnad() %>%
        mutate(
            group = legal_amazon,
            composicao_demografica = "Todos",
            id = "All"
        )
    
    df2 <- df %>%
        tidyr::drop_na(legal_amazon, cnae_2dig) %>%
        group_by(legal_amazon, cnae_2dig) %>%
        describe_pnad() %>%
        mutate(
            group = legal_amazon,
            composicao_demografica = cnae_2dig,
            id = "CNAE"
        )
    
    df3 <- df %>%
        tidyr::drop_na(legal_amazon, cod_2dig) %>%
        group_by(legal_amazon, cod_2dig) %>%
        describe_pnad() %>%
        mutate(
            group = legal_amazon,
            composicao_demografica = cod_2dig,
            id = "COD"
        )
    
    bind_rows(
        df1, df2, df3
    )
}

# By state

describe_states <- function(df) {
    df <- df %>%
        dplyr::mutate(
            sigla_uf = dplyr::case_match(
                UF,
                11 ~ "RO",
                12 ~ "AC",
                13 ~ "AM",
                14 ~ "RO",
                15 ~ "PA",
                16 ~ "AP",
                17 ~ "TO",
                21 ~ "MA",
                22 ~ "PI",
                23 ~ "CE",
                24 ~ "RN",
                25 ~ "PB",
                26 ~ "PE",
                27 ~ "AL",
                28 ~ "SE",
                29 ~ "BA",
                31 ~ "MG",
                32 ~ "ES",
                33 ~ "RJ",
                35 ~ "SP",
                41 ~ "PR",
                42 ~ "SC",
                43 ~ "RS",
                50 ~ "MS",
                51 ~ "MT",
                52 ~ "GO",
                53 ~ "DF"
            )
        )
    
    df1 <- df %>%
        tidyr::drop_na(sigla_uf) %>%
        group_by(sigla_uf) %>%
        describe_pnad() %>%
        mutate(
            group = sigla_uf,
            composicao_demografica = "Todos",
            id = "All"
        )
    
    df2 <- df %>%
        tidyr::drop_na(sigla_uf, cnae_2dig) %>%
        group_by(sigla_uf, cnae_2dig) %>%
        describe_pnad() %>%
        mutate(
            group = sigla_uf,
            composicao_demografica = cnae_2dig,
            id = "CNAE"
        )
    
    df3 <- df %>%
        tidyr::drop_na(sigla_uf, cod_2dig) %>%
        group_by(sigla_uf, cod_2dig) %>%
        describe_pnad() %>%
        mutate(
            group = sigla_uf,
            composicao_demografica = cod_2dig,
            id = "COD"
        )
    
    bind_rows(
        df1, df2, df3
    )
}

# Big loop to run one of those for each quarter

dat <- purrr::map_dfr(
    files,
    function(file_name) {
        message(file_name)
        df <- readr::read_rds(file_name)
        
        # todos
        df1 <- df %>%
            describe_quarter() %>%
            mutate(setor = "todos")
        
        # formal
        df2 <- df %>%
            filter(formal == 1) %>%
            describe_quarter() %>%
            mutate(setor = "formal")
        
        # informal
        df3 <- df %>%
            filter(informal == 1) %>%
            describe_quarter() %>%
            mutate(setor = "informal")
        
        # publico
        df4 <- df %>%
            filter(publico == 1) %>%
            describe_quarter() %>%
            mutate(setor = "publico")
        
        # privado
        df5 <- df %>%
            filter(privado == 1) %>%
            describe_quarter() %>%
            mutate(setor = "privado")
        
        bind_rows(
            df1, df2,df3, df4, df5
        )
            
    }
)

# setting up time variable

dat <- dat %>%
    mutate(Mes = 3*Trimestre - 2) %>%
    mutate(time = lubridate::make_date(Ano, Mes))

# saving data files

dat_cnae <- dat %>%
    filter(id %in% c("All", "CNAE")) %>%
    select(-id)

readr::write_rds(dat_cnae, "data/ibge_pnadc_cnae.rds", compress = "gz")

dat_cod <- dat %>%
    filter(id %in% c("All", "COD")) %>%
    select(-id)

readr::write_rds(dat_cod, "data/ibge_pnadc_cod.rds", compress = "gz")

##############################
## Dictionary -- CNAE e COD ##
##############################

## CNAE

temp_param_table <- tibble::tibble(
    var = c("group", "setor", "composicao_demografica", "time",
            "ocupado", "rendimento_medio", "massa_salarial"),
    x = TRUE,
    y = FALSE,
    color = TRUE,
    label = NA,
    desc = NA,
    var_group = "IBGE - PNAD Cont\u00ednua",
    categoria = "Economia",
    subcategoria = "Mercado de Trabalho"
)

temp_param_table <- temp_param_table %>%
    mutate(
        y = ifelse(
            var %in% c("ocupado", "rendimento_medio", "massa_salarial"), TRUE, FALSE
        ),
        label = dplyr::case_match(
            var,
            "group" ~ "Região",
            "setor" ~ "Setor",
            "composicao_demografica" ~ "Atividade Econômica",
            "time" ~ "Ano - Trimestre",
            "ocupado" ~ "Número de ocupados",
            "rendimento_medio" ~ "Rendimento Médio",
            "massa_salarial" ~ "Massa Salarial"
        ),
        desc = label,
        desc = case_match(
            var,
            "composicao_demografica" ~ "Atividade Econômica - Código CNAE",
            "rendimento_medio" ~ "Rendimento Habitual Médio Real",
            .default = desc
        )
    )

write.csv(temp_param_table, file = "data/ibge_pnadc_cnae_dic.csv", fileEncoding = "UTF-8")

temp_param_table <- temp_param_table %>%
    mutate(slider = c(F,F,F,T,F,F,F)) %>%
    mutate(x = y, y = FALSE)

write.csv(temp_param_table, file = "data/ibge_pnadc_cnae_rk_dic.csv", fileEncoding = "UTF-8")

## COD

temp_param_table <- tibble::tibble(
    var = c("group", "setor", "composicao_demografica", "time",
            "ocupado", "rendimento_medio", "massa_salarial"),
    x = TRUE,
    y = FALSE,
    color = TRUE,
    label = NA,
    desc = NA,
    var_group = "IBGE - PNAD Cont\u00ednua",
    categoria = "Economia",
    subcategoria = "Mercado de Trabalho"
)

temp_param_table <- temp_param_table %>%
    mutate(
        y = ifelse(
            var %in% c("ocupado", "rendimento_medio", "massa_salarial"), TRUE, FALSE
        ),
        label = dplyr::case_match(
            var,
            "group" ~ "Região",
            "setor" ~ "Setor",
            "composicao_demografica" ~ "Atividade Econômica",
            "time" ~ "Ano - Trimestre",
            "ocupado" ~ "Número de ocupados",
            "rendimento_medio" ~ "Rendimento Médio",
            "massa_salarial" ~ "Massa Salarial"
        ),
        desc = label,
        desc = case_match(
            var,
            "composicao_demografica" ~ "Atividade Econômica - Código CNAE",
            "rendimento_medio" ~ "Rendimento Habitual Médio Real",
            .default = desc
        )
    )

temp_param_table <- temp_param_table %>%
    mutate(
        label = ifelse(var == "composicao_demografica", "Tipo de Ocupação", label),
        desc = ifelse(var == "composicao_demografica", "Ocupação - Código COD", desc)
    )

write.csv(temp_param_table, file = "data/ibge_pnadc_cod_dic.csv", fileEncoding = "UTF-8")

temp_param_table <- temp_param_table %>%
    mutate(slider = c(F,F,F,T,F,F,F)) %>%
    mutate(x = y, y = FALSE)

write.csv(temp_param_table, file = "data/ibge_pnadc_cod_rk_dic.csv", fileEncoding = "UTF-8")
