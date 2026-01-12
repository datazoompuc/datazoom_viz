################################################################################
#   DADOS PARA O files$db_file
################################################################################

# Saúde municipal ---------------------------------------------------------

library(tidyverse)
library(sf)
library(readxl)

df_saude <- read_csv(
    "data/ext_data/saude/Dados A Saude na Amazonia Legal/dados_mun/df_mun.csv",
    show_col_types = FALSE
) |>
    select(-N) |>
    rename(cod_ibge = cod_mun) |>
    distinct() |>
    mutate(
        across(
            c(d_am_legal, d_hidro_oper, d_min_ilegal),
            ~ factor(.x, levels = c(0, 1), labels = c("Não", "Sim"))
        )
    )

# Dados socioeconômicos ----------------------------------------------------

dz_munic <- read_rds("data/dz_munic.rds") |>
    st_drop_geometry() |>
    select(ano, cod_ibge, pop, gdp_deflacionado, gd_ppc_deflacionado) |>
    mutate(
        cod_ibge = as.numeric(substr(cod_ibge, 1, 6)),
        ano      = year(ano)
    ) |>
    filter(between(ano, 2008, 2019)) |>
    distinct()

# Merge -------------------------------------------------------------------

data <- inner_join(dz_munic, df_saude)

saveRDS(data, "data/saude_municipality.rds")

################################################################################
#   DADOS DICIONÁRIO PARA files$param_file
################################################################################

build_dictionary_base <- function(data) {
    
    tibble(
        var          = colnames(data),
        x            = TRUE,
        y            = TRUE,
        color        = FALSE,
        size         = FALSE,
        slider       = FALSE,
        geometry     = FALSE,
        label        = colnames(data),
        desc         = colnames(data),
        var_group    = "Saúde - DATASUS",
        tipo         = 1,
        unidade      = "",
        categoria    = "Social",
        subcategoria = "Saúde"
    )
}

apply_variable_flags <- function(dict) {
    
    dict |>
        mutate(
            x      = c(FALSE, FALSE, rep(TRUE, 3), rep(FALSE, 7), rep(TRUE, 67)),
            y      = c(FALSE, FALSE, rep(TRUE, 3), rep(FALSE, 7), rep(TRUE, 67)),
            color  = c(rep(FALSE, 6), rep(TRUE, 2), FALSE, FALSE, TRUE, TRUE, rep(FALSE, 67)),
            size   = c(FALSE, FALSE, TRUE, TRUE, TRUE, rep(FALSE, 71), TRUE, TRUE, TRUE),
            slider = c(TRUE, rep(FALSE, 78)),
            var_group = case_when(
                row_number() %in% 3:5  ~ "IBGE",
                row_number() %in% 6:12 ~ " ",
                TRUE ~ var_group
            )
        )
}


################################################################################
#   DICIONÁRIO PT
################################################################################

dic_saude_pt <- read_excel(
    "data/ext_data/saude/Dados A Saude na Amazonia Legal/dados_mun/variaveis_dados_municipios.xlsx"
) |>
    pull(`Descrição`)

labels_custom <- c(
    "Ano",
    "Codigo do municipio",
    "População",
    "PIB real (R$ 2021)",
    "PIB per capita real (R$ 2021)",
    dic_saude_pt
)

dict_pt <- build_dictionary_base(data) |>
    apply_variable_flags() |>
    mutate(
        label = if_else(
            row_number() <= length(labels_custom),
            labels_custom[row_number()],
            label
        )
    )


write_csv(dict_pt, "data/saude_municipality_dic.csv")

################################################################################
#   DICIONÁRIO EN
################################################################################

labels_en <- c(
    "Year",
    "Municipality code",
    "Population",
    "Real GDP (R$ 2021)",
    "Real GDP per capita (R$ 2021)",
    "Municipality's name",
    "Region",
    "State's name"
)

dict_en <- build_dictionary_base(data) |>
    apply_variable_flags() |>
    mutate(
        label = case_when(
            row_number() <= length(labels_en) ~ labels_en[row_number()],
            TRUE ~ label
        )
    )

write_csv(dict_en, "data/saude_municipality_dic_en.csv")