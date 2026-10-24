# Dados da COMEX (`data/`)

O script `data-raw/comex.R` gera a base central da COMEX e duas tabelas auxiliares.
Fonte: Comex Stat / MDIC, exportações por município (`datazoom.amazonia::load_br_trade(dataset = "export_mun")`), restrito à Amazônia Legal. Valores em US$ FOB **nominais** (sem deflator) e quantidade em kg líquido.

## Como atualizar

Na raiz do repositório:

```r
setwd("~/datazoom_viz")
source("data-raw/comex.R")
```

O último ano vem do `available_time` do manifest do `datazoom.amazonia` (`ano_inicial` é o único parâmetro; use `ano_final_manual` para forçar outro) e o script sempre baixa os dados de novo.

O servidor do MDIC (balanca.mdic.gov.br) tem a cadeia de certificado incompleta (visto no macOS) e costuma derrubar conexões em arquivos grandes. Por isso os downloads usam o curl do sistema sem verificar o certificado (só para esses arquivos públicos), retomam de onde caíram e repetem até 5 vezes por ano. Os anos já baixados ficam guardados, então, se o script parar em algum ano, basta rodar de novo na mesma sessão do R.

O script precisa do `datazoom.amazonia` com o dicionário do COMEX baixado por `download.file()` (PR `comex-dicionario-download-file`). Enquanto o PR não for mergeado, rode antes `devtools::load_all("~/datazoom.amazonia")` na branch desse PR; depois do merge, basta instalar o pacote atualizado. O ano final e a URL do dicionário são lidos com funções internas do pacote (`:::`).

## Arquivos gerados

| Arquivo | O que é |
|---|---|
| `comex_exp_munic_base.rds` | **Base central**, formato longo: ano × SH4 × município × UF, com `valor_fob`, `kg_liquido`, `n_meses` e `ano_parcial`. |
| `auxiliar_cod_pais.rds` | Códigos de países (SISCOMEX → nome PT/EN), via API do Comex Stat. |
| `auxiliar_cod_sh4.rds` | SH4 → nome do produto, capítulo (SH2) e seção, PT e EN (`NCM_SH.csv` do MDIC). |

## Sobre os dados

- **Sem deflator.** Decisão de out/2026: valor nominal e quantidade (kg). A quantidade serve de base para calcular valor real depois.
- **Ano parcial.** O ano mais recente pode ter menos de 12 meses (em 2026, só parte do ano). `n_meses` e `ano_parcial` marcam isso. Nas séries, o último ponto cai por esse motivo.

## Arquivos antigos em `data/`

Os arquivos `comex_exp_*` (bases largas, transpostas, mapa, % mundial e dicionários) **não são mais gerados** por este script. Ficam no repositório só porque apps ativos ainda os leem (ver `config/app_manifest.csv`). A exportação para JSON fica com a Fernanda; os arquivos antigos podem sair quando os apps migrarem. O `comex_munic_raw.rds` (dado bruto do MDIC) também fica, pois o script não o grava mais; confirmar se a exportação para JSON o usa antes de apagar.

## Pendências

- `paises_traducao.csv` é lido pelo `app_rk_comex_exp_paises.R`; script que o gera não identificado.
