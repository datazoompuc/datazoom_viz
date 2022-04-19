library(tidyverse)
library(datazoom.amazonia)

#dados finais divergindo um pouco do bruno
# > max(abs(exp_mun_raw$valor_total-world_trade$total))
# [1] 2435674
# > mean(abs(exp_mun_raw$valor_total-world_trade$total))
# [1] 463724.7
# > sd(abs(exp_mun_raw$valor_total-world_trade$total))
# [1] 590322.8

### 2019 DATA
#BACI
#exp_mun_19 <- load_baci(dataset = "HS92", raw_data = TRUE, time_period = 2019)

exp_mun_19 = exp_mun_raw %>%
  dplyr::rename(ano = t,
                exportador = i,
                importador = j,
                co_sh6 = k,
                valor = v,
                quantidade = q)

exp_mun_19_sh4= exp_mun_19
exp_mun_19_sh2= exp_mun_19

#the sh4 codes are the first 4 digits of the sh6 codes
#the sh2 codes are the first 2 digits of the sh6 codes
exp_mun_19_sh4$cod_sh4= gsub('.{2}$', '', exp_mun_19$co_sh6)
exp_mun_19_sh2$cod_sh2= gsub('.{4}$', '', exp_mun_19$co_sh6)

exp_mun_19_sh2$valor= as.numeric(exp_mun_19_sh2$valor)
exp_mun_19_sh4$valor= as.numeric(exp_mun_19_sh4$valor)

#getting the total value from all world trade by summing all the values from each country for all the products
exp_mun_19_sh4= exp_mun_19_sh4%>%
  group_by(cod_sh4, ano)%>%
  summarise(valor_total= sum(valor))%>%
  filter(cod_sh4 %in% c("0102", "0201", "0202", "0203", "0206", "0207" ,"0301" ,"0302", "0303", "0304", "0305",
                        "0306", "0407", "0504", "0510" ,"0511", "0713" ,"0801" ,"0811", "0901", "0904", "1005",
                        "1006" ,"1101" ,"1201", "1207" ,"1301", "1404" ,"1502" ,"1507", "1511", "1515" ,"1517",
                        "1520", "1701" ,"1801", "1901", "1902", "1905" ,"2008" ,"2009"))  #filtering the amazon products

exp_mun_19_sh2= exp_mun_19_sh2%>%
  group_by(cod_sh2, ano)%>%
  summarise(total= sum(valor))

#saveRDS(exp_mun_19_sh4, "data/auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci19.rds")
#saveRDS(exp_mun_19_sh2, "data/auxiliar_exportacoes_totais_produtos_sh2_selecionados_baci19.rds")


### 2020 DATA
#BACI
#exp_mun_20 <- load_baci(dataset = "HS92", raw_data = TRUE, time_period = 2020)

exp_mun_20 = exp_mun_20 %>%
  dplyr::rename(ano = t,
                exportador = i,
                importador = j,
                co_sh6 = k,
                valor = v,
                quantidade = q)


exp_mun_20_sh4= exp_mun_20
exp_mun_20_sh2= exp_mun_20


#the sh4 codes are the first 4 digits of the sh6 codes
#the sh2 codes are the first 2 digits of the sh6 codes
exp_mun_20_sh4$cod_sh4= gsub('.{2}$', '', exp_mun_20_sh4$co_sh6)
exp_mun_20_sh2$cod_sh2= gsub('.{4}$', '', exp_mun_20_sh2$co_sh6)

exp_mun_20_sh2$valor= as.numeric(exp_mun_20_sh2$valor)
exp_mun_20_sh4$valor= as.numeric(exp_mun_20_sh4$valor)

#getting the total value from all world trade by summing all the values from each country for all the products
exp_mun_20_sh4= exp_mun_20_sh4%>%
  group_by(cod_sh4, ano)%>%
  summarise(total= sum(valor))%>%
  filter(cod_sh4 %in% c("0102", "0201", "0202", "0203", "0206", "0207" ,"0301" ,"0302", "0303", "0304", "0305",
                        "0306", "0407", "0504", "0510" ,"0511", "0713" ,"0801" ,"0811", "0901", "0904", "1005",
                        "1006" ,"1101" ,"1201", "1207" ,"1301", "1404" ,"1502" ,"1507", "1511", "1515" ,"1517",
                        "1520", "1701" ,"1801", "1901", "1902", "1905" ,"2008" ,"2009"))  #filtering the amazon products

exp_mun_20_sh2= exp_mun_20_sh2%>%
  group_by(cod_sh2, ano)%>%
  summarise(total= sum(valor))

#saveRDS(exp_mun_20_sh4, "data/auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci20.rds")
#saveRDS(exp_mun_20_sh2, "data/auxiliar_exportacoes_totais_produtos_sh2_selecionados_baci20.rds")
