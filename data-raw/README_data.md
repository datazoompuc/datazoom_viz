# Arquivos `.rds` da COMEX (`data/`)

Documentação dos arquivos gerados pelos scripts de `data-raw/` da COMEX.
Fonte dos dados: Comex Stat / MDIC (exportações por município, via `datazoom.amazonia::load_br_trade(dataset = "export_mun")`), restrito à Amazônia Legal. Valores em US$ FOB.

## Como atualizar

Na raiz do repositório, nesta ordem:

```r
setwd("~/datazoom_viz")
source("data-raw/comex.R")                  # baixa o COMEX, gera as bases e os dicionários
source("data-raw/comex_munic_sel.R")        # base do mapa (produto principal por município); precisa do pacote rmapshaper
source("data-raw/comex_percentual.R")       # participação nas exportações mundiais (usa BACI)
source("data-raw/Indice_precos_exportacao.R") # índice de preços usado para deflacionar nos apps (ver abaixo)
```

O `comex.R` descobre sozinho o último ano disponível no site do MDIC (`ano_inicial` é o único parâmetro de início) e usa o deflator do PIB (SIDRA, tabela 6784) para calcular o valor real. O deflator só vai até 2023; nos anos seguintes `valor_real` fica `NA`. Se o site do MDIC estiver fora do ar ou com erro de certificado, o script para na primeira tentativa e mostra o motivo.

## Gerados por `comex.R`

| Arquivo | O que é |
|---|---|
| `comex_munic_raw.rds` | Dado bruto baixado do MDIC (ano, mês, município, UF, país, SH4, valor FOB, kg). Entrada dos demais scripts. |
| `comex_exp_munic_base.rds` | **Base central.** Formato longo: ano × SH4 × município × UF, com `valor_nominal` e `valor_real` (deflacionado pelo deflator do PIB, a preços do último ano com deflator). |
| `auxiliar_cod_pais.rds` | Tabela de códigos de países (código SISCOMEX → nome PT/EN). |
| `auxiliar_cod_sh4.rds` | Tabela de códigos SH4 → nome do produto, capítulo (SH2) e seção, em PT e EN. |
| `auxiliar_cod_municipais.rds` | Tabela de códigos de municípios → nome. |
| `comex_exp_munic_sh4.rds` | Município × SH4, formato largo: uma linha por (ano, posição SH4), colunas = municípios. |
| `comex_exp_sh4_munic.rds` | Mesma informação, transposta: uma linha por (ano, município), colunas = posições SH4. |
| `comex_exp_munic_sh2.rds` / `comex_exp_sh2_munic.rds` | Idem, agregado por capítulo SH2. |
| `comex_exp_munic_sec.rds` / `comex_exp_sec_munic.rds` | Idem, agregado por seção. |
| `comex_exp_tot_pais.rds` | Exportação total por país de destino (longo: ano, país, valor). |
| `comex_exp_sec_pais.rds` / `comex_exp_pais_sec.rds` | País × seção, formato largo e sua transposta. |
| `*_dic.csv`, `*_dic_en.csv` | Dicionário de cada base (rótulos, descrição, quais variáveis entram em x, y, cor, tamanho e slider da visualização), em PT e EN. |

Os pares "munic_X" e "X_munic" **não são duplicados**: são a mesma informação em orientações diferentes, e cada visualização usa uma delas.

## Gerados por `comex_munic_sel.R`

| Arquivo | O que é |
|---|---|
| `comex_exp_munic_sh4_sel.rds` | Objeto `sf` (polígonos dos municípios) com o principal produto exportado por município e ano, separado entre produtos compatíveis com a floresta (`floresta = TRUE`) e os demais. `maximo_produto` é a participação do produto no total do município (%). Alimenta o mapa. |
| dicionários correspondentes (`.csv`) | Idem acima. |

## Gerado por `comex_percentual.R`

| Arquivo | O que é |
|---|---|
| `comex_exp_perc_sh4_sel.rds` | Exportação da Amazônia por SH4 selecionado, como % das exportações mundiais do produto (denominador: BACI, `auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci.rds`, gerado por `data-raw/baci.R`). Só entram produtos com valor ≥ US$ 1 milhão e anos que existem no BACI (hoje, até 2024). |
| `comex_exp_perc_sh4_sel_dic.csv`, `_dic_en.csv` | Dicionários. |

## Índice de preços (deflator usado nos apps)

Os apps de série e ranking do COMEX (por exemplo `app_ts_comex_exp_tot_pais.R` e `app_rk_comex_exp_paises.R`) têm um botão "Deflacionar (US$ de 1998)". Ele usa um índice de preços de exportação, que é independente do `valor_real` da base central (essa usa o deflator do PIB).

| Arquivo | O que é |
|---|---|
| `Dados_totais_mensal.csv` | Dado bruto do MDIC, Índices de Preços e Quantum, total mensal (https://balanca.economia.gov.br/balanca/IPQ/totais_mes.html, botão "Baixar: Dados brutos (.csv)"). Baixado à mão, ou automaticamente se `url_ipq` estiver preenchida no script. |
| `indice_precos_anual.csv` | Gerado por `data-raw/Indice_precos_exportacao.R`: média anual do índice de preços de exportação, reescalada para 1998 = 100 (coluna `indice_anual_base1998`). Última atualização: dados até novembro de 2025. |

## Outros arquivos que os apps do COMEX leem

| Arquivo | O que é |
|---|---|
| `paises_traducao.csv` | Tabela de tradução dos nomes de países, lida pelo `app_rk_comex_exp_paises.R`. Script que a gera: não identificado. |

## Observações

- A lista de SH4 "compatíveis com a floresta" (16 códigos) está escrita em dois lugares, `comex_munic_sel.R` e `comex_percentual.R`. Conferido em 04/10/2026: as duas listas são iguais. Se uma mudar, a outra precisa mudar junto.
- O ano mais recente do COMEX pode ser parcial (em 2026, só alguns meses), o que faz as séries caírem no último ponto.
- O mapa do site (`web/ts_comex_exp_municipio`, branch `poc/js-ts-comex-exp-municipio`) calcula a classificação do mapa no `app.js` (`computeMapRatioClass`), não nos scripts R.

## Pendências

- Quais `.rds` seguem em uso: uma varredura com `grep` em 04/10/2026 não encontrou referência nos scripts `.R`/`.Rmd` a `cempre_state_dza`, `employment`, `comex_exp_tot_sec`, `mapbiomas_cobertura_munic_en` e `mapbiomas_cobertura_munic_pt`. Outros só aparecem no script que os gera (`comex_exp_munic_sh4`, `comex_exp_tot_sh2`, `rais_groups`, `map_dz_munic_prodes_data`, `auxiliar_cod_municipais`). Os `pam_municipality_all_crops<ano>` de 2000 a 2024 são usados (`dz_munic.R` e `map_dz_munic_prodes_data.R`). O grep não pega leitura com caminho montado em código; confirmar antes de apagar.
- `comex_exp_tot_sec.rds` e `comex_exp_tot_sh2.rds` existem em `data/`, mas nenhum dos três scripts do COMEX os gera. Confirmar origem.
- O `indice_precos_anual.csv` só vai até 2025; atualizar quando o site do MDIC voltar (estava com certificado inválido em 04/10/2026).
