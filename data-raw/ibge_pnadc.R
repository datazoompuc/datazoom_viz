################################################################################
##
##  PNADC — Script de geração dos datasets do site Data Zoom Amazônia
##  Fonte: PNAD Contínua Trimestral (IBGE) via pacote datazoom.social
##
##  Datasets gerados:
##    data/ibge_pnadc_trabalho.rds          — mercado de trabalho (demográfico)
##    data/ibge_pnadc_atividades_ocupacoes.rds — CNAE + COD + setor combinados
##
##  ── COMO ATUALIZAR ──────────────────────────────────────────────────────────
##
##  !! IMPORTANTE — DEFLATOR:
##  A PNADC revisa retroativamente os deflatores a cada nova divulgação.
##  Por isso, a cada atualização é necessário REBAIXAR TODOS os trimestres
##  (não apenas o mais recente), do contrário as séries históricas ficam
##  inconsistentes. Não reutilize arquivos .rds de runs anteriores.
##
##  Passo a passo:
##
##  1. BAIXAR DADOS (Seção 1 abaixo)
##     - Ajuste `source_path` para uma pasta onde os .rds serão salvos
##     - Execute o bloco "SEÇÃO 1 — DOWNLOAD" para baixar todos os trimestres
##     - Isso pode demorar bastante (vários GB de dados brutos)
##
##  2. GERAR DATASET DEMOGRÁFICO — ibge_pnadc_trabalho (Seção 2)
##     - Execute a "SEÇÃO 2 — DATASET DEMOGRÁFICO"
##     - Gera: ibge_pnadc_trabalho.rds
##
##  3. GERAR DATASETS CNAE/COD/ATIVIDADES (Seção 3)
##     - Execute a "SEÇÃO 3 — DATASETS CNAE / COD / ATIVIDADES"
##     - Gera: ibge_pnadc_atividades_ocupacoes.rds
##
##  OBS:  Execute as seções 2 e 3 de forma independente — elas redefinem
##  funções com o mesmo nome (describe_brazil etc.) de forma propositada.
##  Rodar o script inteiro de uma vez também funciona.
##
################################################################################

# ── Pacotes ───────────────────────────────────────────────────────────────────

library(tidyverse)
library(haven)
library(tibble)
library(zoo)
library(tidyr)
library(magrittr)
library(datazoom.social)  # instalar do GitHub se não estiver atualizado com devtools::install_github("datazoompuc/datazoom.social")

# ── SEÇÃO 1 — DOWNLOAD ───────────────────────────────────────────────────────
#
#  Ajuste o caminho abaixo para onde os arquivos brutos serão salvos.
#  Execute este bloco UMA VEZ por atualização (demora bastante).
#
#  Sempre baixe TODOS os trimestres disponíveis (não só o novo),
#  pois o deflator é revisado retroativamente a cada divulgação.

source_path <- "F:/PNADC/load_pnadc DZ"  

load_pnadc(save_to = source_path, 2012:2026, raw_data = FALSE, panel = "none")

# Lê a lista de arquivos baixados
files <- list.files(source_path, pattern = "*.rds", full.names = TRUE)


# ── SEÇÃO 2 — DATASET DEMOGRÁFICO ────────────────────────────────────────────
#
#  Gera ibge_pnadc_trabalho.rds.
#  Recortes: Brasil, regiões, Amazônia Legal, UFs × Todos/Sexo/Faixa etária/Escolaridade.

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
                14 ~ "RR",
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

# UTF-8 encoding

dat %<>% mutate(across(where(is.character), enc2utf8))

# saving data file

readr::write_rds(dat, "ts_ibge_pnadc_trabalho/ibge_pnadc_trabalho.rds", compress = "gz")

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


# ── SEÇÃO 3 — DATASETS CNAE / COD / ATIVIDADES ───────────────────────────────
#
#  Gera três arquivos:
#    ibge_pnadc_atividades_ocupacoes.rds — dataset completo (CNAE + COD + setor)
#    ibge_pnadc_cnae.rds                 — filtro: id %in% c("All", "CNAE")
#    ibge_pnadc_cod.rds                  — filtro: id %in% c("All", "COD")
#
#  As funções describe_brazil / describe_region / describe_amazon / describe_states
#  são REDEFINIDAS aqui (versões CNAE/COD). describe_quarter() é reaproveitada
#  e chamará automaticamente as novas versões.
#
#  Para rodar apenas esta seção: execute do aqui até o final do arquivo.

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
                14 ~ "RR",
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

readr::write_rds(dat, "data/ibge_pnadc_atividades_ocupacoes.rds", compress = "gz")

