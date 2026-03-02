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

# Crie um vetor com TODAS as traduções correspondentes
labels_en <- c(
    "Year",
    "Municipality code",
    "Population",
    "Real GDP (R$ 2021)",
    "Real GDP per capita (R$ 2021)",
    "Municipality",
    "Region",
    "State",
    "State abbreviation",
    "Belongs to Legal Amazon (Yes/No)",
    "Municipalities with operating hydroelectric plants (Yes/No)",
    "Municipalities with illegal mining (Yes/No)",
    "Gross mortality rate per 100,000 inhabitants",
    "Age-adjusted mortality rate per 100,000 inhabitants",
    "Mortality from non-communicable diseases per 100,000 inhabitants",
    "Age-adjusted mortality from communicable diseases per 100,000 inhabitants",
    "Mortality from external causes per 100,000 inhabitants",
    "Age-adjusted mortality from external causes per 100,000 inhabitants",
    "Mortality from communicable diseases per 100,000 inhabitants",
    "Age-adjusted mortality from non-communicable diseases per 100,000 inhabitants",
    "Mortality from ill-defined causes per 100,000 inhabitants",
    "Age-adjusted mortality from cardiovascular diseases per 100,000 inhabitants",
    "Age-adjusted mortality from diabetes per 100,000 inhabitants",
    "Age-adjusted mortality from neoplasms per 100,000 inhabitants",
    "Age-adjusted mortality from violence per 100,000 inhabitants",
    "Age-adjusted mortality from traffic accidents per 100,000 inhabitants",
    "Age-adjusted mortality from unintentional accidents per 100,000 inhabitants",
    "Age-adjusted mortality from motorcycle accidents per 100,000 inhabitants",
    "Age-adjusted mortality from non-motorcycle accidents per 100,000 inhabitants",
    "Age-adjusted mortality from malaria per 100,000 inhabitants",
    "Age-adjusted mortality from AIDS per 100,000 inhabitants",
    "Age-adjusted mortality from waterborne diseases per 100,000 inhabitants",
    "Age-adjusted mortality from respiratory diseases per 100,000 inhabitants",
    "Breast cancer mortality per 100,000 women",
    "Cervical cancer mortality per 100,000 women",
    "Violence-related mortality per 100,000 women",
    "Percentage of low birth weight newborns",
    "Percentage of pregnancies among 10-19 year olds",
    "Indigenous crude mortality rate per 100,000 inhabitants",
    "Indigenous mortality from communicable diseases per 100,000 inhabitants",
    "Indigenous mortality from non-communicable diseases per 100,000 inhabitants",
    "Indigenous mortality from external causes per 100,000 inhabitants",
    "Indigenous mortality from ill-defined causes per 100,000 inhabitants",
    "Indigenous infant mortality per 1,000 live births",
    "Family Health Strategy coverage percentage",
    "Primary Health Care coverage percentage (AB Teams + FHS Teams)",
    "Community Health Agents coverage percentage",
    "FHS teams per 1,000 km²",
    "Primary Health Care teams per 1,000 km²",
    "Community Health Agents per 1,000 km²",
    "Riverine and Fluvial Family Health Units",
    "Riverine and Fluvial Family Health Teams",
    "Total hospital beds",
    "SUS hospital beds",
    "Total ICU beds",
    "SUS ICU beds",
    "Distance to nearest emergency service",
    "Distance to nearest medium complexity service",
    "Distance to nearest high complexity service",
    "Distance to nearest ICU",
    "Distance to nearest dialysis service",
    "Distance to nearest chemotherapy service",
    "Physicians per 1,000 inhabitants",
    "Nursing professionals per 1,000 inhabitants",
    "Cardiologists per 1,000 inhabitants",
    "Gynecologists per 1,000 inhabitants",
    "Endocrinologists per 1,000 inhabitants",
    "Oncologists per 1,000 inhabitants",
    "Physicians from More Doctors Program",
    "Proportion of physicians from More Doctors Program",
    "Proportion of private health plan beneficiaries",
    "Proportion of hospitals not affiliated with SUS",
    "Private beds per 100,000 inhabitants",
    "Private ICU beds per 100,000 inhabitants",
    "Private hospitals affiliated with SUS per 100,000 inhabitants",
    "Private hospitals not affiliated with SUS per 100,000 inhabitants",
    "Total health expenditure per capita",
    "Health expenditure from own resources per capita",
    "Health expenditure proportion per capita"
)

# Verifique se o número de labels corresponde ao número de colunas
if (length(labels_en) != ncol(data)) {
    warning(paste("Número de labels EN (", length(labels_en), 
                  ") não corresponde ao número de colunas (", ncol(data), ")"))
}

dict_en <- build_dictionary_base(data) |>
    apply_variable_flags() |>
    mutate(
        label = if_else(
            row_number() <= length(labels_en),
            labels_en[row_number()],
            label  # fallback: mantém nome da variável se faltar tradução
        )
    )

write_csv(dict_en, "data/saude_municipality_dic_en.csv")