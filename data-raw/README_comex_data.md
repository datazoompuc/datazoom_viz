# Dados da COMEX (`data/`)

O script `data-raw/comex.R` gera a base central da COMEX, num único arquivo, sem tabelas auxiliares.
Fonte: Comex Stat / MDIC, exportações por município (`datazoom.amazonia::load_br_trade(dataset = "export_mun")`), restrito à Amazônia Legal. Valores em US$ FOB **nominais** (sem deflator) e quantidade em kg líquido.

## Como atualizar

Na raiz do repositório:

```r
setwd("~/datazoom_viz")
source("data-raw/comex.R")
```

O script possui checagem automática integrada: antes de iniciar o reprocessamento de todos os anos, ele baixa a amostra do ano mais recente via `datazoom.amazonia::load_br_trade(dataset = "export_mun", time_period = ano_final)` e compara o último mês e ano disponíveis com os registrados na base local `data/comex_exp_munic_base.rds`. Se os dados forem iguais (sem novos meses ou anos na fonte oficial), o script encerra imediatamente com status 0 sem baixar a série histórica novamente. Havendo dado novo ou caso a base local não exista, o processamento completo de todos os anos prossegue normalmente.

Além da execução manual, a verificação e atualização é executada automaticamente todo dia 8 de cada mês às 09:00 UTC (06:00 BRT) via GitHub Actions (`.github/workflows/check-comex-updates.yml`).

O último ano vem do `available_time` do manifest do `datazoom.amazonia` (`ano_inicial` é o único parâmetro; use `ano_final_manual` para forçar outro).

O servidor do MDIC (balanca.mdic.gov.br) costuma derrubar conexões em arquivos grandes. Por isso os downloads usam o curl do sistema, que retoma de onde caiu e repete em caso de erro, e o script tenta cada ano até 5 vezes. Os anos já baixados ficam guardados, então, se o script parar em algum ano, basta rodar de novo na mesma sessão do R.

O script precisa do `datazoom.amazonia` com o PR "Comex resolver migration" (#354), já no master: o ano final e a URL dos arquivos de nomes do MDIC (linha `comex_dic` do manifest) são lidos com funções internas do pacote (`:::`).

## Arquivo gerado

`comex_exp_munic_base.rds` é a **base central**, em formato longo, com uma linha por ano × SH4 × município × país de destino. Os nomes de município, país e produto já vêm juntados, então não há arquivos auxiliares.

| Coluna | O que é |
|---|---|
| `ano` | Ano da exportação. |
| `cod_sh4`, `cod_sh2` | Códigos do produto (posição SH4 e capítulo SH2, com zeros à esquerda). |
| `cod_municipio`, `uf` | Município (código IBGE) e UF de origem. |
| `municipio` | Nome do município com acento e a UF no fim (ex.: "Abadiânia - GO"), do `UF_MUN.csv` do MDIC. |
| `cod_pais` | Código SISCOMEX do país de destino (3 dígitos). |
| `valor_fob` | Valor exportado, US$ FOB nominais. |
| `kg_liquido` | Quantidade, em kg líquido. |
| `n_meses`, `ano_parcial` | Meses publicados no ano; `ano_parcial` é `TRUE` quando há menos de 12. |
| `pais_pt`, `pais_en` | Nome do país de destino em português e em inglês (`PAIS.csv` do MDIC). |
| `sh4_pt`, `sh4_en` | Nome da posição (SH4) em português e em inglês. |
| `sh2_pt`, `sh2_en` | Nome do capítulo (SH2) em português e em inglês. |
| `sec_pt`, `sec_en` | Nome da seção em português e em inglês. |

Os nomes de produto vêm do `NCM_SH.csv`, os de país do `PAIS.csv` e os de município do `UF_MUN.csv`, todos do mesmo servidor do MDIC (a URL vem do manifest do pacote, trocando só o nome do arquivo). O script confere, antes de salvar, que não há chave duplicada, que os totais de `valor_fob` e `kg_liquido` são iguais aos do dado bruto e que nenhum nome ficou vazio.

## Sobre os dados

- **Sem deflator.** Decisão de out/2026: valor nominal e quantidade (kg). A quantidade serve de base para calcular valor real depois.
- **Ano parcial.** O ano mais recente pode ter menos de 12 meses (em 2026, só parte do ano). `n_meses` e `ano_parcial` marcam isso. Nas séries, o último ponto cai por esse motivo.
- **País de destino.** A base não soma sobre países: para obter o total por município e produto, some `valor_fob` e `kg_liquido` agrupando por `ano`, `cod_sh4`, `cod_municipio` e `uf`.

## Arquivos em `data/`

Sobra **um arquivo**: `data/comex_exp_munic_base.rds`, a base central longa gerada por
este script. Todos os `comex_exp_*` antigos (bases largas, matrizes transpostas, % mundial
e os dicionários CSV), o `comex_exp_munic_sh4_sel.rds` do mapa e o `comex_munic_raw.rds`
foram removidos.

Toda a geração de JSON e GeoJSON da visualização web (`web/comex_exp_municipio/`) sai
dessa base, por `web/_export/export_comex_exp_municipio.R`. O mapa deixou de ter script
próprio: era `export_comex_mapa.R`, hoje faz parte do mesmo export.

Os apps Shiny que liam os arquivos removidos continuam no repositório e **vão quebrar se
forem redeployados**, porque o `config/app_manifest.csv` ainda resolve as dependências
pelos nomes antigos. Estão listados nas Pendências.

## Pendências

Os oito apps Shiny do COMEX foram **removidos** em nov/2026, junto com os
`scripts/` e as entradas em `config/`. Três viraram o app estático em
`web/comex_exp_municipio/` (a série temporal original, o ranking de produtos
SH4 e o mapa, hoje a vista Mapa) e cinco saíram da página do site.

Eles continuam publicados no shinyapps.io até alguém encerrar por lá, e as
páginas dos cinco continuam no repositório do site.

- `data/paises_traducao.csv` ficou órfão: era lido pelo `app_rk_comex_exp_paises.R`, que foi removido, e nenhum script de `data-raw/` o gera. Pode sair numa limpeza.
