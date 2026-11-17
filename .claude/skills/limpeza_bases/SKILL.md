---
name: limpeza_bases
description: >
  Como preparar (limpar, montar e conferir) as bases de data/ do datazoom_viz para os
  apps novos em JavaScript (web/). Use sempre que for criar ou editar um script de
  data-raw/ que gera uma base (population.R, pibmunic.R, prodes.R,
  mapbiomas_cobertura_base.R, comex.R ou uma fonte nova), escrever o README_<fonte>_data.md
  de uma base, decidir se um script precisa de checagem de atualização ou de workflow, ou
  migrar uma base antiga (larga, com dicionários auxiliares) para o formato novo.
---

# Limpeza de bases para os apps em JavaScript

Estamos migrando os apps de Shiny para JavaScript (`web/<app>/`). Nessa migração, cada
fonte passa a ter **um script em `data-raw/` que gera uma base central em `data/`**, e
tudo o que o app web lê (JSON, GeoJSON) é derivado dessa base por um script em
`web/_export/`. Os scripts antigos de `data-raw/` (bases largas, um `.rds` por nível e
dicionários CSV por idioma) **não são modelo**: o modelo são os scripts abaixo.

| Script | Base gerada | Referência para |
|---|---|---|
| `data-raw/population.R` | `data/population.rds` | fonte SIDRA, checagem completa de atualização, estado + município |
| `data-raw/pibmunic.R` | `data/pibmunic.rds` | igual ao de população, com várias variáveis |
| `data-raw/comex.R` | `data/comex_exp_munic_base.rds` | rótulos PT/EN juntados na base, ano parcial, checagem de atualização mensal |
| `data-raw/mapbiomas_cobertura_base.R` | `data/mapbiomas_cobertura_base.rds` | base nacional com flag `amazonia_legal`, classes hierárquicas, sem zeros |
| `data-raw/prodes.R` | `data/prodes_*.rds` | o mínimo: anos do manifest e gravar |

Cada base tem um `data-raw/README_<fonte>_data.md` (ver "README da base" abaixo).

## 1. Anos: sempre do manifest do pacote

O ano final (e os anos disponíveis) vêm do `available_time` do manifest do
`datazoom.amazonia`, nunca de uma consulta direta à fonte nem de um número fixo no script.
É o procedimento padrão:

```r
ano_inicial      <- 2001   # primeiro ano que a base usa
ano_final_manual <- NULL   # só para forçar outro ano final

anos_fonte <- datazoom.amazonia:::parse_years(
  datazoom.amazonia:::dataset_meta("<fonte>", "<dataset>", "available_time")
)
if (length(anos_fonte) == 0) stop("O manifest do pacote não traz o available_time ...")
ultimo_ano <- if (is.null(ano_final_manual)) max(anos_fonte) else ano_final_manual
anos <- anos_fonte[anos_fonte >= ano_inicial & anos_fonte <= ultimo_ano]
```

- Use `anos_fonte`, não `ano_inicial:ultimo_ano`: o manifest guarda as lacunas da série
  (população: `"2001-2022, 2024-2026"`, sem 2023), e o script não deve pedir um ano que
  não existe.
- `dataset_meta()` e `parse_years()` são internos (`:::`). `dataset_meta()` só serve para
  campos que todas as linhas do dataset compartilham; para um dataset com linhas por
  `geo_level` (MapBiomas), leia o campo da linha certa.
- Se o manifest estiver atrasado, a correção é no pacote (o resolver), não no script; até
  lá, `ano_final_manual`.
- Um aviso (`warning`) quando o manifest passa N anos sem ano novo é útil
  (2 para população, 3 para o PIB): aponta tabela nova na fonte ou manifest parado.

## 2. Checagem de atualização: depende de como o link muda

A pergunta é: **quando a fonte publica dado novo, o endereço do arquivo muda?**

| | Link fixo, conteúdo muda | Link muda a cada versão |
|---|---|---|
| Exemplos | COMEX (`EXP_<ano>_MUN.csv` reescrito todo mês no mesmo endereço); SIDRA (população, PIB: a mesma tabela ganha anos e tem valores revisados) | PRODES (zip com a data da versão no nome); MapBiomas (arquivo novo no Dataverse a cada coleção) |
| Quem percebe a novidade | **ninguém**, a não ser o próprio script: o manifest não muda | o resolver do `datazoom.amazonia`, que troca `url`/`version` no manifest e abre um PR lá |
| Checagem no script | **necessária** | **não precisa**: rodar o script quando o manifest mudar |

Para decidir, olhe a linha da fonte no manifest
(`inst/extdata/manifest/v1/datasets_link.csv` no pacote): se `url` ou `version` trazem
versão, data ou id de arquivo e um `resolver` os atualiza, o link muda. Se a `url` é fixa
(ou é um `sidra_code`), o link é fixo.

### Como fazer a checagem (link fixo)

Antes do download pesado, baixe algo barato, compare com a base salva e pare se for igual:

- **SIDRA** (`population.R`, `pibmunic.R`): baixa o nível estadual de todos os anos (uma
  consulta por ano) e compara **linha a linha** com o nível estadual da base salva
  (`comparar_com_salva()`). Pega ano novo **e** revisão de valor. Só baixa os municípios
  (o lento) se algo mudou.
- **COMEX** (`comex.R`): baixa só o ano mais recente e compara o último ano/mês com a base
  salva. Igual: `quit(status = 0)` sem reprocessar.
- Sempre com `forcar_atualizacao <- TRUE` (ou equivalente) no topo, para refazer sem
  diferença (por exemplo, depois de mudar o tratamento).
- A checagem roda no próprio script; o workflow (`.github/workflows/check-<fonte>-updates.yml`,
  como o do COMEX, mensal) só executa o script e commita o `.rds` se ele mudou.

## 3. Formato da base central

- **Uma base longa por fonte, sem arquivos auxiliares.** Uma linha por chave (ex.: COMEX
  `ano × cod_sh4 × cod_municipio × cod_pais`; MapBiomas `ano × cod_municipio × classe_en`;
  população `nivel × cod_ibge × ano`). Escreva a chave no cabeçalho do script e no README.
- **Rótulos juntados na base**, em PT e EN quando o app é bilíngue (`pais_pt`/`pais_en`,
  `sh4_pt`/`sh4_en`, `classe_pt`/`classe_en`). Nada de dicionário por nível e idioma. Um
  CSV à parte só quando outro app ou script de fato o lê (ex.: `mapbiomas_legenda.csv`);
  documente quem lê.
- **Brasil inteiro com uma coluna `amazonia_legal`**, e o app filtra (MapBiomas, população,
  PIB). Restringir à Amazônia Legal no script (COMEX) só se o volume exigir; diga no README.
- **Agregados**: não guarde o que é só a soma de outro nível (MapBiomas: estado = soma dos
  municípios). Guarde quando a fonte publica o nível e ele não é exatamente a soma
  (população: o IBGE publica 2004, 2008 e 2012 com a soma dos municípios até 0,32% acima
  da UF), numa coluna `nivel` (`"estado"`/`"municipio"`).
- **Sem linhas de zero** quando ausência quer dizer zero (MapBiomas); diga no README que
  quem monta a tabela larga preenche com zero.
- **Códigos com zero à esquerda em texto** (`sprintf("%04d", sh4)`, país com 3 dígitos,
  `cod_ibge` como texto).
- **Unidade e preço explícitos**: valores nominais, sem deflator (decisão de out/2026 para
  o COMEX; o PIB municipal só existe nominal). A coluna de quantidade (kg) fica para quem
  quiser calcular valor real.
- **Ano parcial marcado**, não descartado: `n_meses` e `ano_parcial` (COMEX).
- **Lacunas da série** ficam como lacuna (população 2023), não interpoladas na base.
- **Classes hierárquicas**: guarde o nível (`nivel` 0 a 4 no MapBiomas) e avise no README
  para não somar classes de níveis diferentes.

## 4. Robustez do download

- Rodar da raiz do repositório e conferir logo no início
  (`stopifnot(basename(getwd()) == "datazoom_viz")` ou `dir.exists("data")` com mensagem).
- Conferir que o pacote instalado tem o que o script precisa
  (`exists("<objeto>", envir = asNamespace("datazoom.amazonia"))`) e parar com a instrução
  de atualização (`remotes::install_github("datazoompuc/datazoom.amazonia")`).
- Repetir cada consulta com pausa crescente (`com_tentativas()`, `baixar_ano()`): a fonte
  às vezes recusa ou corta uma conexão.
- Guardar cada ano baixado em `tempdir()` (`pasta_cache`) para retomar na mesma sessão, e
  **só depois de conferido**: se a conferência falhar, apagar o arquivo do cache.
- Servidor instável com arquivos grandes (MDIC): curl do sistema com retomada
  (`download.file.method = "curl"`, `-C - --retry`) e `options(timeout = ...)` alto.

## 5. Conferências antes de gravar

Tudo o que não fecha **para o script com `stop()` e não grava** (nunca grava NA ou base
incompleta em silêncio):

- chave sem duplicata (`anyDuplicated`);
- totais iguais aos do dado bruto depois das junções (`all.equal(sum(...))`, COMEX);
- soma dos municípios igual ao total da UF, com tolerância justificada (população, PIB:
  1%), o que pega download municipal incompleto;
- contagens esperadas (27 UFs; ao menos 5.500 municípios por ano) e anos esperados
  (`"1985"` e `"2024"` presentes no MapBiomas);
- nenhum rótulo vazio depois das junções (mostrar os códigos que ficaram sem nome);
- a base nova não perde anos que a salva tinha (só com `forcar_atualizacao`);
- antes de um `distinct()` que descartaria linhas, conferir que elas são de fato iguais
  (MapBiomas: aviso com amostra se as áreas divergem).

Avisos (`message`) para o que não impede gravar: classe sem nome PT oficial (usa o EN),
município sem nome na tabela do pacote, colunas que o IBGE acrescentou, anos parciais.
No fim, imprimir um resumo: linhas, anos, municípios, tamanho do arquivo.

## 6. README da base

`data-raw/README_<fonte>_data.md`, em português, com estas seções:

1. **Título e fonte**: o que a base é, de qual função do pacote vem, unidade, cobertura.
2. **Como atualizar**: o bloco `setwd(...); source("data-raw/<script>.R")`, de onde vêm
   os anos (manifest, `ano_final_manual`), se há checagem de atualização e workflow, quando
   o script para sem gravar, quanto tempo leva, a versão do pacote exigida.
3. **Arquivo gerado**: tabela `| Coluna | O que é |`, com a chave da base.
4. **Sobre os dados**: armadilhas de interpretação (níveis que não se somam, ano parcial,
   nominal, quebras de série, anos que não existem, próxima atualização da fonte).
5. **Pendências**, se houver.

O README descreve o script **atual**: ao mudar o script, atualize o README no mesmo commit.
(Já aconteceu de um README dizer "sempre baixa de novo" enquanto o script tinha checagem.)

## 7. Do `.rds` ao app web

- O app JavaScript não lê o `.rds`: `web/_export/export_<app>.R` deriva os JSON/GeoJSON de
  `web/<app>/data/` **a partir da base central**, nunca do dado bruto nem de bases antigas.
- Recortes, rankings e agregações próprios de um app ficam no export, não na base.
- Quando a base nova substitui arquivos antigos (`*_munic.rds`, `*_est.rds`, `*_dic*.csv`),
  liste no README quais foram removidos e quais ficaram (e quem ainda os lê).

## Checklist de um script novo

- [ ] Anos do manifest (`dataset_meta` + `parse_years`), com `ano_inicial` e `ano_final_manual`
- [ ] Link fixo ou link que muda? Checagem de atualização só no primeiro caso
- [ ] Base longa única, chave definida, rótulos PT/EN juntados, sem auxiliares desnecessários
- [ ] Brasil inteiro + `amazonia_legal` (ou recorte justificado)
- [ ] Repetição de consultas e cache por ano em `tempdir()`
- [ ] Conferências com `stop()` antes do `saveRDS()`
- [ ] README com as cinco seções, igual ao script
- [ ] Export do app web lendo só da base central
