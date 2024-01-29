library(sf)
library(dplyr)

url <- "https://geoftp.ibge.gov.br/organizacao_do_territorio/estrutura_territorial/amazonia_legal/2022/Limites_Amazonia_Legal_2022_shp.zip"

dir <- tempdir()

temp <- tempfile(tmpdir = dir, fileext = ".zip")

download.file(url, temp)

unzip(temp, exdir = dir)


dat <- read_sf(file.path(dir, "Limites_Amazonia_Legal_2022.shp"))

dat <- dat %>%
    st_simplify(dTolerance = 700)

readr::write_rds(dat, "data/legal_amazon_boundary.rds")

states_boundary <- geobr::read_state()

readr::write_rds(states_boundary, "data/states_boundary.rds")

url <- "https://geoftp.ibge.gov.br/organizacao_do_territorio/estrutura_territorial/areas_territoriais/2022/AR_BR_RG_UF_RGINT_MES_MIC_MUN_2022.xls"

temp <- tempfile(fileext = ".xls")

download.file(url, temp)

dat <- readxl::read_xls("C:/Users/igorr/Downloads/AR_BR_RG_UF_RGINT_MES_MIC_MUN_2022.xls", sheet = "AR_BR_MUN_2022")

dat <- dat %>%
    janitor::clean_names() %>%
    select(
        "cod_municipio" = cd_mun, "area_km2" = ar_mun_2022
    )

readr::write_rds(dat, "data/area_municipios.rds")

