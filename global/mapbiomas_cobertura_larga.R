################################################################################
# MapBiomas - Cobertura: tabelas largas a partir da base longa
#
# A base data/mapbiomas_cobertura_base.rds guarda uma linha por
# ano x município x classe (formato longo). Os apps de cobertura (ts e rk)
# trabalham com tabelas largas, uma coluna por classe, no nível de estado e no
# de município. Esta função monta as duas em memória, então esses arquivos não
# precisam existir em disco.
#
# Uso:
#   base     <- readRDS("data/mapbiomas_cobertura_base.rds")
#   df_munic <- cobertura_larga(base, "munic")
#   df_est   <- cobertura_larga(base, "est")
#
# Classe ausente numa linha da base vale zero (a base não guarda os zeros).
################################################################################

cobertura_larga <- function(base, nivel = c("munic", "est")) {
  nivel <- match.arg(nivel)

  if (nivel == "munic") {
    w <- base %>%
      dplyr::mutate(group = paste(municipio, "-", uf)) %>%
      tidyr::pivot_wider(
        id_cols     = c(ano, cod_municipio, group, area_municipio_km2),
        names_from  = classe_en,
        values_from = area_ha,
        values_fill = 0
      ) %>%
      dplyr::rename(time = ano,
                    municipality_code = cod_municipio,
                    area_km2 = area_municipio_km2) %>%
      dplyr::relocate(area_km2, .after = dplyr::last_col()) %>%
      dplyr::arrange(group, time)
    return(w)
  }

  # estado: soma dos municípios (a área do estado é a soma das áreas municipais)
  areas_uf <- base %>%
    dplyr::distinct(cod_municipio, uf, area_municipio_km2) %>%
    dplyr::summarise(area_km2 = sum(area_municipio_km2, na.rm = TRUE), .by = uf)

  base %>%
    dplyr::summarise(area = sum(area_ha, na.rm = TRUE), .by = c(ano, uf, classe_en)) %>%
    tidyr::pivot_wider(
      id_cols     = c(ano, uf),
      names_from  = classe_en,
      values_from = area,
      values_fill = 0
    ) %>%
    dplyr::rename(time = ano, group = uf) %>%
    dplyr::left_join(areas_uf, by = c("group" = "uf")) %>%
    dplyr::arrange(group, time)
}
