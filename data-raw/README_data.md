# Arquivos `.rds` da COMEX (`data/`)

Documentação dos arquivos gerados pelos scripts de `data-raw/` da COMEX.
Fonte dos dados: Comex Stat / MDIC (exportações por município, via `datazoom.amazonia::load_br_trade(dataset = "export_mun")`), restrito à Amazônia Legal. Valores em US$ FOB.

## Como atualizar

Na raiz do repositório, nesta ordem:

```r
setwd("~/datazoom_viz")
source("data-raw/comex.R")           # baixa o COMEX, gera as bases e os dicionários
source("data-raw/comex_munic_sel.R") # base do mapa (produto principal por município)
source("data-raw/comex_percentual.R")# participação nas exportações mundiais (usa BACI)
```

O `comex.R` descobre sozinho o último ano disponível no site do MDIC (`ano_inicial` é o único parâmetro de início) e usa o deflator do PIB (SIDRA, tabela 6784) para calcular o valor real. O deflator só vai até 2023; nos anos seguintes `valor_real` fica `NA`.

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
| `comex_exp_perc_sh4_sel.rds` | Exportação da Amazônia por SH4 selecionado, como % das exportações mundiais do produto (denominador: BACI, `auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci.rds`, gerado por `data-raw/baci.R`). Só entram produtos com valor ≥ US$ 1 milhão e anos que existem no BACI. |
| `comex_exp_perc_sh4_sel_dic.csv`, `_dic_en.csv` | Dicionários. |

## Pendente de preencher

- Conferir quais `.rds` seguem em uso (o app roda hoje nos JSONs; ver lista de candidatos a apagar).
- `comex_exp_tot_sec.rds` e `comex_exp_tot_sh2.rds` existem em `data/`, mas nenhum dos três scripts gera. Confirmar origem antes de apagar.
