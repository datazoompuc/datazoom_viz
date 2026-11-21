# Dados do PRODES (`data/prodes_*.rds`)

O script `data-raw/prodes.R` gera as quatro bases municipais de desmatamento e cobertura florestal do PRODES para a Amazônia Legal: `prodes_deforestation.rds`, `prodes_residual_deforestation.rds`, `prodes_native_vegetation.rds` e `prodes_non_forest.rds`.
Fonte: INPE / TerraBrasilis (PRODES Amazônia Legal), via `datazoom.amazonia::load_prodes()`. Áreas em **km²**. Restrito aos municípios da Amazônia Legal.

## Como atualizar

Na raiz do repositório:

```r
setwd("~/datazoom_viz")
source("data-raw/prodes.R")
```

Os anos disponíveis de cada dataset vêm do `available_time` do manifest do `datazoom.amazonia` (`ano_inicial` é `2007`; use `ano_final_manual` no topo do script apenas se precisar forçar outro ano final).

**Não há checagem automática de atualização no script nem workflow no GitHub Actions.** No PRODES, o endereço do arquivo no TerraBrasilis muda a cada versão publicada pelo INPE (um zip de raster com o ano e a data da versão no nome, ex.: `prodes_amazonia_legal_2025_v20261019.zip`). Quem detecta versão nova é o *resolver* do pacote `datazoom.amazonia`, que atualiza o manifest do pacote. Basta rodar `data-raw/prodes.R` quando o manifest mudar.

Antes de cada `saveRDS()`, o script confere com `stopifnot()` que a base não está vazia, que não há chave duplicada (`cod_ibge × ano`) e que não há valores `NA` na coluna de área medida.

O script requer o `datazoom.amazonia` atualizado (`remotes::install_github("datazoompuc/datazoom.amazonia")`) e os pacotes `terra`, `units`, `sf` e `dplyr`.

## Arquivos gerados

Quatro arquivos em `data/`, com uma linha por município × ano (chave: `cod_ibge × ano`):

- `data/prodes_deforestation.rds`: desmatamento (`dataset = "deforestation"`, 2007 a 2025).
- `data/prodes_residual_deforestation.rds`: desmatamento residual (`dataset = "residual_deforestation"`, 2010 a 2025).
- `data/prodes_native_vegetation.rds`: vegetação nativa remanescente (`dataset = "native_vegetation"`, último ano do raster: 2025).
- `data/prodes_non_forest.rds`: área de não-floresta (`dataset = "non_forest"`, último ano do raster: 2025).

| Coluna | O que é |
|---|---|
| `cod_ibge` | Código IBGE do município (7 dígitos). |
| `municipio` | Nome do município. |
| `cod_uf` | Código IBGE da UF. |
| `uf` | Sigla da UF (9 estados da Amazônia Legal). |
| `nome_uf` | Nome da UF com acento. |
| `cod_regiao` | Código IBGE da grande região. |
| `regiao` | Nome da grande região (`"Norte"`, `"Nordeste"` ou `"Centro-Oeste"`). |
| `area_km2` | Área total do município, em km² (`units`). |
| `desmatamento_km2` | Área desmatada no município e ano, em km² (em `prodes_deforestation.rds`). |
| `desmatamento_residual_km2` | Área de desmatamento residual no município e ano, em km² (em `prodes_residual_deforestation.rds`). |
| `vegetacao_nativa_km2` | Área de vegetação nativa no município, em km² (em `prodes_native_vegetation.rds`). |
| `nao_floresta_km2` | Área de não-floresta no município, em km² (em `prodes_non_forest.rds`). |
| `ano` | Ano de referência. |

## Arquivos antigos em `data/`

Os arquivos abaixo não são mais gerados por `data-raw/prodes.R`, mas permanecem em `data/` enquanto apps Shiny e scripts legados ainda os leem:

- `data/prodes.rds`: base antiga (2000–2021), ainda lida por `apps/app_map_dz_munic_prodes.R`.
- `data/prodes_2022_2024.rds` e `data/map_dz_munic_prodes_data.rds`: usados por `data-raw/map_dz_munic_prodes_data.R`.

## Sobre os dados

- **2007 é acumulado; 2008 em diante é incremento anual.** Em `prodes_deforestation.rds`, o ano de 2007 representa o desmatamento acumulado até 2007, enquanto de 2008 em diante cada linha traz o incremento anual.
- **Vegetação nativa e Não-floresta só têm o último ano.** O raster do PRODES traz para essas classes apenas o retrato do último ano da versão (ex.: 2025), e não uma série histórica.
- **Cobertura.** Apenas municípios da Amazônia Legal (806 municípios; Passagem Franca/MA é filtrado pelo pacote).

## Pendências

- Migrar o app `apps/app_map_dz_munic_prodes.R`, que ainda lê o `data/prodes.rds` antigo (2000–2021).

