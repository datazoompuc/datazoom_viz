# Dados de população (`data/population.rds`)

O script `data-raw/population.R` gera a população residente de cada estado e de cada município do Brasil, num único arquivo, em todos os anos que o IBGE publica.
Fonte: IBGE, via `datazoom.amazonia::load_population()`. Brasil inteiro; a coluna `amazonia_legal` permite filtrar.

## Como atualizar

Na raiz do repositório:

```r
setwd("~/datazoom_viz")
source("data-raw/population.R")
```

O script tem uma checagem de atualização embutida, feita antes do download municipal (o lento):

1. pergunta direto à API de dados do SIDRA qual é o último ano publicado na tabela 6579 (uma consulta);
2. baixa o nível estadual de todos os anos com `load_population()` (uma consulta por ano, rápido);
3. compara esse nível estadual, linha a linha, com o da base salva.

Se for idêntico, não há ano novo nem revisão: o script avisa e para, sem baixar os municípios e sem tocar no arquivo. Qualquer diferença (ano novo, valor revisado, coluna nova) refaz a base inteira. Para refazer mesmo sem diferença (por exemplo, depois de mudar o tratamento), use `forcar_atualizacao <- TRUE` no topo do script.

O último ano vem da própria tabela do SIDRA, não do `available_time` do manifest do pacote: esse campo é atualizado por uma rotina do pacote que hoje não consegue acessar a API de metadados do IBGE a partir do GitHub Actions, e pode ficar para trás.

O script para com erro, sem gravar nada, se:

- a nova base tiver menos anos que a salva (falha do SIDRA ou do download; só passa com `forcar_atualizacao`);
- a soma dos municípios de alguma UF não bater com o total da UF (download municipal incompleto; cada ano é tentado 3 vezes antes);
- faltar alguma UF ou algum ano, um ano tiver menos de 5.500 municípios, ou houver população vazia.

Os anos municipais já baixados ficam guardados numa pasta temporária: se o script parar no meio, basta rodar de novo na mesma sessão do R.

O script precisa do `datazoom.amazonia` com o PR `update-population` (tabela do Censo 2022 e consultas que não passam pela página do SIDRA bloqueada pelo Cloudflare). Enquanto o PR não for mergeado, rode antes `devtools::load_all("~/datazoom.amazonia")` na branch desse PR.

## Arquivo gerado

`population.rds`, uma linha por nível × unidade × ano.

| Coluna | O que é |
|---|---|
| `nivel` | `"estado"` ou `"municipio"`. |
| `cod_ibge` | Código IBGE: 2 dígitos (UF) ou 7 dígitos (município), em texto. |
| `nome` | Nome da UF (com acento) ou do município no formato `"Alta Floresta D'Oeste - RO"` (tabela `municipalities` do pacote, sem acento, como no antigo `gdp.rds`). `NA` para município criado depois dessa tabela. |
| `uf` | Sigla da UF. |
| `amazonia_legal` | 1 se está na Amazônia Legal, 0 se não. Nos estados, os 9 da Amazônia Legal (o Maranhão inteiro conta como 1). |
| `ano` | Ano de referência. |
| `populacao` | População residente (pessoas). |
| `fonte` | `"estimativa"`, `"contagem"` (2007) ou `"censo"` (2010 e 2022). |

## Sobre os dados

- **Quatro tabelas, uma série.** O pacote escolhe a tabela de cada ano: 6579 (Estimativas de População, 2001-2006, 2008-2009, 2011-2021 e 2024 em diante), 793 (Contagem da População 2007), 1378 (Censo 2010) e 4714 (Censo 2022).
- **2023 não existe.** O IBGE não publicou estimativa entre o Censo 2022 e a estimativa de 2024. Numa série temporal, o ponto de 2023 fica em branco (ou interpolado, se a visualização pedir).
- **Estimativa e censo não são a mesma medida.** As estimativas são para 1º de julho; os censos e a contagem, para a data de referência de cada operação. Em anos de censo há um salto na série que não é crescimento real: 213,3 milhões estimados para 2021 contra 203,1 milhões contados no Censo 2022.
- **Atualização.** A estimativa de um ano sai por volta de agosto do mesmo ano. O script avisa se a tabela 6579 ficar mais de dois anos sem ano novo.
- **Série mais longa.** 2001 é o início do que o pacote oferece. Anos anteriores (Censos 1991 e 2000, Contagem 1996) existem no SIDRA, mas em outras tabelas, fora do `load_population()`.
