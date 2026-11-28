# Dados do BACI (`data/auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci.rds`)

O script `data-raw/baci_load.R` gera a base agregada de comércio internacional mundial por produto (posição SH4) e ano a partir do BACI (CEPII).
Fonte: BACI / CEPII (revisão HS92), via `datazoom.amazonia::load_baci(dataset = "HS92", raw_data = TRUE)`. Valores em **mil US$ correntes** (nominais).

## Como atualizar

Na raiz do repositório:

```r
setwd("~/datazoom_viz")
source("data-raw/baci_load.R")
```

Os anos disponíveis vêm do `available_time` do manifest do `datazoom.amazonia` (`ano_inicial` é `1995`; use `ano_final_manual` no topo do script apenas se precisar forçar outro ano final).

**Não há checagem automática de atualização no script nem workflow no GitHub Actions.** No BACI, o endereço do arquivo no CEPII muda a cada versão anual publicada (`BACI_HS92_V<versao>.zip`, ex.: `BACI_HS92_V202601.zip`). Quem detecta versão nova é o *resolver* do pacote `datazoom.amazonia`, que atualiza `url`, `version` e `available_time` no manifest do pacote. Basta rodar `data-raw/baci_load.R` quando o manifest mudar.

Antes do `saveRDS()`, o script confere com `stopifnot()` que a base não está vazia, que não há chave duplicada (`ano × cod_sh4`), que não há `NA` em `cod_sh4` ou `valor_total` e que todos os anos esperados estão presentes.

## Arquivo gerado

`data/auxiliar_exportacoes_totais_produtos_sh4_selecionados_baci.rds`, em formato longo com **uma linha por ano × posição SH4** (chave: `ano × cod_sh4`).

| Coluna | O que é |
|---|---|
| `ano` | Ano da exportação (inteiro, 1995 em diante). |
| `cod_sh4` | Código da posição SH4 (4 dígitos em texto, com zero à esquerda, extraído dos 4 primeiros dígitos do código SH6). |
| `valor_total` | Valor total exportado no mundo para aquele SH4 no ano, em **mil US$ correntes**. |

## Sobre os dados

- **Unidade em mil US$.** O BACI publica os valores (`v`) em milhares de dólares correntes (US$ mil), enquanto a COMEX publica em dólares (US$ FOB). Ao cruzar as duas bases para calcular a participação da Amazônia nas exportações mundiais (como no app `rk_comex_exp_perc_sh4_sel`), é obrigatório dividir o `valor_fob` da COMEX por `1000` (ou multiplicar `valor_total` do BACI por `1000`).
- **Uso de `raw_data = TRUE`.** O script usa `raw_data = TRUE` em `load_baci()` porque só precisa somar o valor mundial por `ano` e `cod_sh4`, evitando o custo de juntar os dicionários de países e produtos linha a linha nos milhões de fluxos bilaterais SH6 antes de agregar.
- **Limpeza.** O script antigo `data-raw/baci.R` (um remendo manual para 2019–2020) foi removido e substituído por `data-raw/baci_load.R`.
