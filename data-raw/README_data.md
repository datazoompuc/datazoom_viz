# Dados da COMEX (`data/`)

O script `data-raw/comex.R` gera a base central da COMEX, num único arquivo, sem tabelas auxiliares.
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

## Arquivo gerado

`comex_exp_munic_base.rds` é a **base central**, em formato longo, com uma linha por ano × SH4 × município × país de destino. Os nomes de município, país e produto já vêm juntados, então não há arquivos auxiliares.

| Coluna | O que é |
|---|---|
| `ano` | Ano da exportação. |
| `cod_sh4`, `cod_sh2` | Códigos do produto (posição SH4 e capítulo SH2, com zeros à esquerda). |
| `cod_municipio`, `uf` | Município (código IBGE) e UF de origem. |
| `municipio` | Nome do município com acento e a UF no fim (ex.: "Abadiânia - GO"), da API de cidades do Comex Stat. |
| `cod_pais` | Código SISCOMEX do país de destino (3 dígitos). |
| `valor_fob` | Valor exportado, US$ FOB nominais. |
| `kg_liquido` | Quantidade, em kg líquido. |
| `n_meses`, `ano_parcial` | Meses publicados no ano; `ano_parcial` é `TRUE` quando há menos de 12. |
| `pais_pt`, `pais_en` | Nome do país de destino em português e em inglês (`PAIS.csv` do MDIC). |
| `sh4_pt`, `sh4_en` | Nome da posição (SH4) em português e em inglês. |
| `sh2_pt`, `sh2_en` | Nome do capítulo (SH2) em português e em inglês. |
| `sec_pt`, `sec_en` | Nome da seção em português e em inglês. |

Os nomes de produto vêm do `NCM_SH.csv` e os de país do `PAIS.csv` (mesmo servidor do MDIC); os de município vêm da API de cidades do Comex Stat, que às vezes responde 503, então o script tenta de novo várias vezes. O script confere, antes de salvar, que não há chave duplicada, que os totais de `valor_fob` e `kg_liquido` são iguais aos do dado bruto e que nenhum nome ficou vazio.

## Sobre os dados

- **Sem deflator.** Decisão de out/2026: valor nominal e quantidade (kg). A quantidade serve de base para calcular valor real depois.
- **Ano parcial.** O ano mais recente pode ter menos de 12 meses (em 2026, só parte do ano). `n_meses` e `ano_parcial` marcam isso. Nas séries, o último ponto cai por esse motivo.
- **País de destino.** A base não soma sobre países: para obter o total por município e produto, some `valor_fob` e `kg_liquido` agrupando por `ano`, `cod_sh4`, `cod_municipio` e `uf`.

## Arquivos antigos em `data/`

Os arquivos `comex_exp_*` (bases largas, transpostas, mapa, % mundial e dicionários) **não são mais gerados** por este script. Ficam no repositório só porque apps ativos ainda os leem (ver `config/app_manifest.csv`). A exportação para JSON fica com a Fernanda; os arquivos antigos podem sair quando os apps migrarem. O `comex_munic_raw.rds` (dado bruto do MDIC) também fica, pois o script não o grava mais; confirmar se a exportação para JSON o usa antes de apagar.

## Pendências

- `paises_traducao.csv` é lido pelo `app_rk_comex_exp_paises.R`; script que o gera não identificado.
