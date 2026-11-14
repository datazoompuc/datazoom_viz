# Dados do PIB municipal (`data/pibmunic.rds`)

O script `data-raw/pibmunic.R` gera o PIB, os impostos e o valor adicionado bruto (VAB) de cada estado e de cada município do Brasil, num único arquivo, em todos os anos publicados.
Fonte: IBGE, PIB dos Municípios (tabela 5938 do SIDRA, referência 2010), via `datazoom.amazonia::load_pibmunic()`. Valores **nominais** (preços correntes), em **R$ mil**. Brasil inteiro; a coluna `amazonia_legal` permite filtrar.

## Como atualizar

Na raiz do repositório:

```r
setwd("~/datazoom_viz")
source("data-raw/pibmunic.R")
```

Mesma checagem de `data-raw/population.R` (ver `README_population_data.md`), feita antes do download municipal:

1. pergunta direto à API de dados do SIDRA qual é o último ano publicado na tabela 5938 (uma consulta);
2. baixa o nível estadual de todos os anos com `load_pibmunic()` (uma consulta por ano);
3. compara esse nível estadual, linha a linha, com o da base salva.

Se for idêntico, o script avisa e para sem baixar os municípios. Qualquer diferença (ano novo, valor revisado, coluna nova) refaz a base inteira; `forcar_atualizacao <- TRUE` refaz mesmo sem diferença. O script para sem gravar se a nova base tiver menos anos que a salva, se a soma do PIB dos municípios de alguma UF não bater com o PIB da UF (download incompleto; cada ano é tentado 3 vezes), se faltar UF ou ano, ou se houver PIB vazio.

O download municipal é o mais lento do repositório depois da COMEX: 27 consultas por ano, com as 46 variáveis da tabela em cada uma (cerca de 4 minutos por ano).

O script precisa do `datazoom.amazonia` de nov/2026 em diante (PR "Update pibmunic", #375).

## Arquivo gerado

`pibmunic.rds`, uma linha por nível × unidade × ano. Todos os valores em R$ mil correntes.

| Coluna | O que é |
|---|---|
| `nivel` | `"estado"` ou `"municipio"`. |
| `cod_ibge` | Código IBGE: 2 dígitos (UF) ou 7 dígitos (município), em texto. |
| `nome` | Nome da UF (com acento) ou do município no formato `"Alta Floresta D'Oeste - RO"` (tabela `municipalities` do pacote, sem acento, como no antigo `gdp.rds`). `NA` para município criado depois dessa tabela. |
| `uf` | Sigla da UF. |
| `amazonia_legal` | 1 se está na Amazônia Legal, 0 se não. Nos estados, os 9 da Amazônia Legal (o Maranhão inteiro conta como 1). |
| `ano` | Ano de referência. |
| `pib` | PIB a preços correntes (variável 37). |
| `impostos_liquidos` | Impostos, líquidos de subsídios, sobre produtos (543). |
| `vab_total` | VAB total (498). `pib = vab_total + impostos_liquidos`. |
| `vab_agropecuaria` | VAB da agropecuária (513). |
| `vab_industria` | VAB da indústria (517). |
| `vab_servicos` | VAB dos serviços, exceto administração pública (6575). |
| `vab_adm_publica` | VAB da administração, defesa, educação e saúde públicas e seguridade social (525). |

As outras 39 variáveis da tabela são participações percentuais (no PIB da UF, do Brasil, da microrregião etc.) e não entram: dá para recalculá-las.

## Sobre os dados

- **Só nominal.** O IBGE não publica PIB real (a preços constantes) por município. Para estados, as Contas Regionais publicam a variação em volume do PIB, mas isso não está na tabela 5938 nem no `load_pibmunic()` (e volumes encadeados não são aditivos: não dá para chegar ao PIB real de um estado somando partes). Para valores reais, deflacionar na visualização (como fazia o antigo `dz_munic.R`).
- **2022 e 2023 só têm o PIB.** O IBGE suspendeu a abertura por atividade até a nova série das Contas Nacionais (ano-base 2021): nesses anos, `impostos_liquidos` e as colunas `vab_*` ficam `NA`. De 2002 a 2021 tudo está preenchido.
- **PIB per capita** não está na tabela: juntar com `data/population.rds` (`pib * 1000 / populacao` dá R$ por habitante).
- **Próxima atualização: 2027.** Pela Nota técnica 01/2026 do IBGE, o PIB dos Municípios de 2024 foi adiado para 2027, junto com o de 2025 e a série desde 2002, só com o PIB a preços de mercado. O IBGE diz que, na divulgação da nova série (ano-base 2021), os resultados serão reapresentados de forma definitiva. Se saírem na própria tabela 5938, a checagem pega tanto os anos novos quanto a revisão da série. Se saírem numa tabela nova, a 5938 para em 2023 e o script avisa (warning) quando passar de três anos sem ano novo: aí é preciso apontar o pacote e o script para a tabela nova.
- **Série mais longa.** 2002 é o início da série de referência 2010. A série antiga (referência 2002, tabela 21, 1999-2012) tem outra metodologia e não é comparável em nível.
