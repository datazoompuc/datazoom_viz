############################################################
##
## Generate rds data in the folder ./data/
##
## This script must be run periodically to update databases.
##
############################################################

# call packages
library(tidyverse)
library(haven)
library(tibble)
library(zoo)
library(tidyr)
library(PNADcIBGE)


#################################################
## Mercado de Trabalho na Amazônia Legal
## Ouput data from:
## github: https://github.com/datazoompuc/datazoom_labour_amazon
#################################################

# set path to raw data
#github_folder_path <- "https://github.com/datazoompuc/datazoom_labour_amazon/raw/main/Labour_Market/output/" # set github structure path

# PNAD files must be downloaded to the computer
source <- "F:/Dados/PNADC"

# only run this if not already downloaded: takes a long time
load_pnadc(save_to = source, 2012:2023, raw_data = FALSE, panel = "none")

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
                  "desalentado", "nem_nem"),
                ~ sum(. * peso, na.rm = TRUE)
            )
        )
        
     # calculando taxas
        
    df <- df %>%
        mutate(
            taxa_participacao = pea/pia,
            taxa_ocupacao = ocupado/pia,
            taxa_desemprego = desempregado/forca_trab,
            taxa_informalidade = informal/ocupado,
            taxa_desalento = desalentado/pia,
            taxa_nem_nem = nem_nem/pia
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





#views CNAE e COD
#picking the firt 2 digits of V4013 and V4010

CNAE  <- pnadc_2023_4 %>% mutate(prefixo = substr(V4013, 1, 2)) 
COD <- pnadc_2023_4 %>% mutate(prefixo = substr(V4010, 1, 2))

#creating the 
CNAE <- CNAE %>%
    mutate(titulo = case_match(prefixo,
                                '00' ~ "Outros",
                                '01' ~ "Agricultura",
                                '02' ~ "Extração florestal",
                                '03' ~ "Pesca, caça e aquicultura",
                                '05' ~ "Extração mineral e de carvão, petróleo e gás",
                                '06' ~ "Extração mineral e de carvão, petróleo e gás",
                                '07' ~ "Extração mineral e de carvão, petróleo e gás",
                                '08' ~ "Extração mineral e de carvão, petróleo e gás",
                                '09' ~ "Extração mineral e de carvão, petróleo e gás",
                                '10' ~ "Alimentos, bebidas e fumo",
                                '11' ~ "Alimentos, bebidas e fumo",
                                '12' ~ "Pecuária e criação de animais",
                                '13' ~ "Têxtil, vestuário, couro e calçados",
                                '14' ~ "Pecuária e criação de animais",
                                '15' ~ "Pesca, caça e aquicultura",
                                '16' ~ "Madeira, celulose e papel",
                                '17' ~ "Madeira, celulose e papel",
                                '18' ~ "Madeira, celulose e papel",
                                '19' ~ "Químicos, farmacêuticos, borracha e plástico",
                                '20' ~ "Químicos, farmacêuticos, borracha e plástico",
                                '21' ~ "Químicos, farmacêuticos, borracha e plástico",
                                '22' ~ "Químicos, farmacêuticos, borracha e plástico",
                                '23' ~ "Produtos de metal, minerais não-metálicos e metalurgia",
                                '24' ~ "Produtos de metal, minerais não-metálicos e metalurgia",
                                '25' ~ "Produtos de metal, minerais não-metálicos e metalurgia",
                                '26' ~ "Serviços jurídicos",
                                '27' ~ "Eletrônicos, máquinas e equipamentos",
                                '28' ~ "Eletrônicos, máquinas e equipamentos",
                                '29' ~ "Automóveis e equipamentos de transporte",
                                '30' ~ "Automóveis e equipamentos de transporte",
                                '31' ~ "Móveis",
                                '32' ~ "Outros",
                                '34' ~ "Serviços jurídicos",
                                '33' ~ "Eletrônicos, máquinas e equipamentos",
                                '35' ~ "Eletrônicos, máquinas e equipamentos",
                                '36' ~ "Eletrônicos, máquinas e equipamentos",
                                '37' ~ "Eletrônicos, máquinas e equipamentos",
                                '38' ~ "Eletrônicos, máquinas e equipamentos",
                                '39' ~ "Eletrônicos, máquinas e equipamentos",
                                '41' ~ "Construção",
                                '42' ~ "Construção",
                                '43' ~ "Construção",
                                '45' ~ "Comércio",
                                '48' ~ "Comércio",
                                '49' ~ "Transporte e correio",
                                '50' ~ "Transporte e correio",
                                '51' ~ "Transporte e correio",
                                '52' ~ "Transporte e correio",
                                '53' ~ "Transporte e correio",
                                '55' ~ "Estadia e turismo",
                                '56' ~ "Serviços de alimentação",
                                '58' ~ "Serviços de informação e comunicação",
                                '59' ~ "Serviços de informação e comunicação",
                                '60' ~ "Serviços de informação e comunicação",
                                '61' ~ "Serviços de informação e comunicação",
                                '62' ~ "Serviços de informação e comunicação",
                                '63' ~ "Serviços de informação e comunicação",
                                '64' ~ "Serviços financeiros e de seguros",
                                '65' ~ "Serviços financeiros e de seguros",
                                '66' ~ "Serviços financeiros e de seguros",
                                '68' ~ "Atividades profissionais, científicas e técnicas",
                                '69' ~ "Atividades profissionais, científicas e técnicas",
                                '70' ~ "Atividades profissionais, científicas e técnicas",
                                '71' ~ "Atividades profissionais, científicas e técnicas",
                                '72' ~ "Atividades profissionais, científicas e técnicas",
                                '73' ~ "Atividades profissionais, científicas e técnicas",
                                '74' ~ "Atividades profissionais, científicas e técnicas",
                                '75' ~ "Atividades profissionais, científicas e técnicas",
                                '78' ~ "Terceirização de mão-de-obra",
                                '79' ~ "Estadia e turismo",
                                '80' ~ "Segurança e edifícios",
                                '81' ~ "Segurança e edifícios",
                                '82' ~ "Segurança e edifícios",
                                '84' ~ "Administração pública, defesa e seguridade social",
                                '85' ~ "Educação",
                                '86' ~ "Saúde e assistência social",
                                '87' ~ "Saúde e assistência social",
                                '88' ~ "Saúde e assistência social",
                                '90' ~ "Artes, cultura, esportes e recreação",
                                '91' ~ "Artes, cultura, esportes e recreação",
                                '92' ~ "Artes, cultura, esportes e recreação",
                                '93' ~ "Artes, cultura, esportes e recreação",
                                '94' ~ "Organizações religiosas, sindicais e patronais",
                                '95' ~ "Serviços de informação e comunicação",
                                '96' ~ "Serviços pessoais (cabelereiros, lavanderias, etc.)",
                                '97' ~ "Serviços domésticos",
                                '99' ~ "Outros"))

COD <- COD %>% 
    mutate(titulo = case_match(prefixo,
                                '01' ~ "Policiais, bombeiros e forças armadas",
                                '02' ~ "Policiais, bombeiros e forças armadas",
                                '04' ~ "Policiais, bombeiros e forças armadas",
                                '05' ~ "Policiais, bombeiros e forças armadas",
                                '11' ~ "Trabalhadores no governo",
                                '12' ~ "Dirigentes e gerentes",
                                '13' ~ "Dirigentes e gerentes",
                                '14' ~ "Dirigentes e gerentes",
                                '21' ~ "Cientistas e engenheiros",
                                '22' ~ "Profissionais da saúde",
                                '23' ~ "Profissionais do ensino",
                                '24' ~ "Administradores e especialista em gestão",
                                '25' ~ "Serviços de TI e comunicação",
                                '26' ~ "Serviços jurídicos",
                                '31' ~ "Cientistas e engenheiros",
                                '32' ~ "Profissionais da saúde",
                                '33' ~ "Serviços financeiros e administrativos",
                                '34' ~ "Serviços jurídicos",
                                '35' ~ "Serviços de TI e comunicação",
                                '41' ~ "Escriturários",
                                '42' ~ "Atendimento direto ao público",
                                '43' ~ "Apoio administrativo",
                                '44' ~ "Apoio administrativo",
                                '51' ~ "Serviços e cuidados pessoais",
                                '52' ~ "Vendedores",
                                '53' ~ "Serviços e cuidados pessoais",
                                '54' ~ "Profissionais de segurança",
                                '61' ~ "Pecuaristas e criadores de animais",
                                '62' ~ "Pecuaristas e criadores de animais",
                                '71' ~ "Operários da construção, metalurgia e indústria",
                                '72' ~ "Operários da construção, metalurgia e indústria",
                                '73' ~ "Artesões e artes gráficas",
                                '74' ~ "Técnicos de eletricidade e eletrônica",
                                '75' ~ "Operários de processamento e instalações",
                                '81' ~ "Operários de processamento e instalações",
                                '82' ~ "Montadores e condutores de veículos",
                                '83' ~ "Montadores e condutores de veículos",
                                '91' ~ "Domésticos",
                                '92' ~ "Pecuaristas e criadores de animais",
                                '93' ~ "Operários da construção, metalurgia e indústria",
                                '94' ~ "Profissionais em alimentação",
                                '95' ~ "Ambulantes",
                                '96' ~ "Coletores de lixo"))  %>% 
    mutate(titulo = ifelse(V4010 == 9215, "Extrativistas florestais",titulo))


#Statistics

#Variables

#ocupados
CNAE <- CNAE %>% mutate(ocupado = ifelse(VD4002 == 1, 1, 0))
COD <- COD %>% mutate(ocupado = ifelse(VD4002 == 1, 1, 0))

#desocupados
CNAE <- CNAE %>% mutate(desocupado = ifelse(VD4002 == 2, 1, 0))
COD <- COD  %>% mutate(desocupado = ifelse(VD4002 == 2, 1, 0))

#trabalhador formal
CNAE <- CNAE %>% mutate(formal = ifelse((VD4002 == 1 & VD4009 %in% c("01","03","05","07")), 1,
                                        ifelse((VD4002 == 01 & VD4009 %in% c("08","09") & VD4012 == 1), 1, 0)))

COD <- COD  %>% mutate(formal = ifelse((VD4002 == 1 & VD4009 %in% c("01","03","05","07")), 1,
                                       ifelse((VD4002 == 1 & VD4009 %in% c("08","09") & VD4012 == 1), 1, 0)))

#trabalhador informal
CNAE <- CNAE %>% mutate(informal = ifelse((VD4002 == 1 & VD4009 %in% c("02","04","06","10")), 1,
                                           ifelse((VD4002 == 1 & VD4009 %in% c("08","09") & VD4012 == 2),1,0)))
    
COD <- COD %>% mutate(informal = ifelse((VD4002 == 1 & VD4009 %in% c("02","04","06","10")), 1,
                                        ifelse((VD4002 == 1 & VD4009 %in% c("08","09") & VD4012 == 2),1,0)))

#ocupado no setor publico
CNAE <- CNAE %>% mutate(publico = ifelse(V4012 %in% c(2,4), 1, 0))
COD <- COD %>% mutate(publico = ifelse(V4012 %in% c(2,4), 1, 0))

#privado no setor privado
CNAE <- CNAE %>% mutate(privado = ifelse(V4012 %in% c(1,3,5,6,7), 1, 0))
COD <- COD %>% mutate(privado = ifelse(V4012 %in% c(1,3,5,6,7), 1, 0))

#rendimento Real
CNAE <- CNAE %>% mutate(rendimento_real = (VD4019 * Habitual))
COD <- COD %>% mutate(rendimento_real = (VD4019 * Habitual))



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

# saving data file

readr::write_rds(dat, "data/ibge_pnadc_trabalho.rds")

################
## Dictionary ##
################

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

readr::write_csv(temp_param_table, "data/ibge_pnadc_trabalho_dic.csv")

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
            stringr::str_detect(var, "taxa")
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
            "taxa_nem_nem" ~ "NEET Rate over the working age population"
            .default = desc
        )
    )

readr::write_csv(temp_param_table, "data/ibge_pnadc_trabalho_dic_en.csv")