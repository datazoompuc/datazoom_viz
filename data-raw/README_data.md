# Arquivos `.rds` da COMEX (`data/`)

Todos os arquivos abaixo são gerados por um único script, `data-raw/comex.R`.
Fonte: Comex Stat / MDIC, exportações por município (`datazoom.amazonia::load_br_trade(dataset = "export_mun")`), restrito à Amazônia Legal. Valores em US$ FOB **nominais** (sem deflator) e quantidade em kg líquido.

## Como atualizar

Na raiz do repositório:

```r
setwd("~/datazoom_viz")
source("data-raw/comex.R")
```

O script descobre sozinho o último ano disponível no site do MDIC (`ano_inicial` é o único parâmetro). Se o site estiver fora do ar ou com erro de certificado, ele para na primeira tentativa e mostra o motivo. A seção [6] precisa do pacote `rmapshaper`, e a [7] do arquivo do BACI gerado por `data-raw/baci.R`.

## Sobre os dados

- **Sem deflator.** Decisão de out/2026: os arquivos trazem valor nominal e quantidade (kg). A quantidade serve de base para calcular valor real depois, se for preciso.
- **Ano parcial.** O ano mais recente pode ter menos de 12 meses (em 2026, só parte do ano). A base central tem as colunas `n_meses` e `ano_parcial` para marcar isso. Nas séries, o último ponto cai por esse motivo. Mantido por enquanto, a discutir.
- **Série de participação (% mundial)** só vai até 2024, que é o fim do BACI.

## Seções de `comex.R` e arquivos gerados

| Arquivo | Seção | O que é |
|---|---|---|
| `comex_munic_raw.rds` | 1 | Dado bruto do MDIC (ano, mês, município, UF, país, SH4, valor FOB, kg). Entrada das demais seções. |
| `auxiliar_cod_pais.rds` | 2 | Códigos de países (SISCOMEX → nome PT/EN), via API do Comex Stat. |
| `auxiliar_cod_sh4.rds` | 2 | SH4 → nome do produto, capítulo (SH2) e seção, PT e EN (`NCM_SH.csv` do MDIC). |
| `auxiliar_cod_municipais.rds` | 2 | Códigos de municípios → nome, via API do Comex Stat. |
| `comex_exp_munic_base.rds` | 3 | **Base central**, formato longo: ano × SH4 × município × UF, com `valor_fob`, `kg_liquido`, `n_meses` e `ano_parcial`. |
| `comex_exp_munic_sh4.rds` / `comex_exp_sh4_munic.rds` | 4 | Município × SH4, formato largo e sua transposta (valor FOB). |
| `comex_exp_munic_sh2.rds` / `comex_exp_sh2_munic.rds` | 4 | Idem, por capítulo SH2 (inclui total "Amazônia Legal"). |
| `comex_exp_munic_sec.rds` / `comex_exp_sec_munic.rds` | 4 | Idem, por seção (inclui total "Amazônia Legal"). |
| `comex_exp_tot_pais.rds` | 4 | Exportação total por país de destino (longo: ano, país, valor). |
| `comex_exp_sec_pais.rds` / `comex_exp_pais_sec.rds` | 4 | País × seção, formato largo e sua transposta. |
| `comex_exp_munic_sh4_sel.rds` | 6 | Objeto `sf` com o principal produto exportado por município e ano, separado entre produtos compatíveis com a floresta (`floresta = TRUE`) e os demais. `maximo_produto` é a participação do produto no total da Amazônia (%). Alimenta o mapa. |
| `comex_exp_perc_sh4_sel.rds` | 7 | Exportação da Amazônia por SH4 selecionado, como % das exportações mundiais do produto (denominador: BACI, `auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci.rds`). Só entram produtos com valor ≥ US$ 1 milhão e anos que existem no BACI. |
| `*_dic.csv`, `*_dic_en.csv` | 5, 6, 7 | Dicionário de cada base (rótulos, descrição, variáveis de x, y, cor, tamanho e slider), em PT e EN. |

Os pares "munic_X" e "X_munic" **não são duplicados**: são a mesma informação em orientações diferentes, e cada visualização usa uma delas.

A lista de SH4 "compatíveis com a floresta" (16 códigos) fica definida uma vez, no começo da seção [6] de `comex.R`, e é usada também na [7].

## Observações

- O mapa do site (`web/ts_comex_exp_municipio`, branch `poc/js-ts-comex-exp-municipio`) calcula a classificação das cores no `app.js` (`computeMapRatioClass`), não no R.
- Os scripts antigos (`comex_munic_sel.R`, `comex_percentual.R`, `sh4_floresta.R`, `Indice_precos_exportacao.R`) foram incorporados ou removidos. O índice de preços e o deflator do PIB deixaram de ser usados.

## Pendências

- `comex_exp_tot_sec.rds` e `comex_exp_tot_sh2.rds` existem em `data/`, mas `comex.R` não os gera. Confirmar origem antes de apagar.
- `paises_traducao.csv` é lido pelo `app_rk_comex_exp_paises.R`; script que o gera não identificado.
