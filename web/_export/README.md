# `web/_export/`

Tudo que diz respeito aos **apps web estáticos** em `web/`: os scripts que
transformam `.rds` em JSON, e a documentação de como e por quê.

Fica aqui, dentro de `web/`, porque diz respeito aos apps web, e não ao
lado de `data-raw/`, que tem ~46 scripts construindo os `.rds` a partir das
fontes originais. São dois estágios diferentes do mesmo caminho:

```
fonte (IBGE, MDIC, MapBiomas...)
   ↓  data-raw/*.R              <- constrói os .rds
data/*.rds
   ↓  web/_export/export_*.R   <- converte para JSON
web/<app>/data/*.json
   ↓  GitHub Pages
site
```

## Por onde começar

| Quero... | Leia |
|---|---|
| Atualizar os dados de um app que já existe | `RUNBOOK_*.md` do app |
| Criar os dados de um app novo | `GUIA_base_long.md` |
| Entender por que os dados estão assim | `ARQUITETURA.md` |
| Começar um app web novo | `SHARED.md` |
| Saber por que o CI reprovou o app | `smoke_comex.py` |

Em uma frase: **arquitetura diz por quê, guia diz como, runbook diz o que rodar.**

## Arquivos

### Documentação

- **`ARQUITETURA.md`** — princípios. Por que uma base longa só em vez de um
  `.rds` por visualização, como decidir o recorte dos arquivos JSON e o dos
  scripts, os quatro formatos de JSON e quando usar cada um.
- **`GUIA_base_long.md`** — o receituário. O que a base precisa carregar, o
  código de cada tipo de derivação, como acrescentar uma dimensão nova, e as
  armadilhas que já custaram tempo.
- **`RUNBOOK_comex.md`** — passo a passo operacional do app de COMEX: rodar,
  conferir e publicar.

### Scripts de export

- **`export_comex_exp_municipio.R`** — gera os dez JSON do app de COMEX a
  partir de `data/comex_exp_munic_base.rds`. Dez recortes diferentes da
  mesma base, por isso num script só.
- **`export_comex_mapa.R`** — gera a geometria do mapa do mesmo app. Fica
  separado porque é o único que precisa do `sf` (GDAL/GEOS/PROJ) e porque
  fronteira municipal quase não muda.

### Teste

- **`smoke_comex.py`** — abre o app num navegador de verdade e percorre a
  matriz de vista × medida × orientação × escopo, conferindo que o gráfico
  saiu. Roda no `web-check.yml`, a cada PR. Existe porque validar JSON e
  sintaxe de JS não prova que o app funciona: um bug real passou pelas duas e
  deixou a Composição em quantidade desenhando um gráfico vazio. O cabeçalho
  do arquivo explica a matriz e por que as asserções são as que são.

  Para rodar localmente:

  ```sh
  pip install playwright && python -m playwright install chromium
  python3 web/_export/smoke_comex.py web/
  ```

Todos rodam a partir da **raiz do repositório**:

```sh
Rscript web/_export/export_comex_exp_municipio.R
```

## Convenção para apps novos

Ao migrar um app novo para o formato estático, acrescente aqui:

- `export_<app>.R` — o script de export
- `RUNBOOK_<app>.md` — como atualizar e publicar aquele app

A arquitetura e o guia são gerais e não precisam de versão por app.

## O underscore não é enfeite

O workflow do Pages monta o site copiando `web/` **sem esta pasta**. É o que
permite scripts e guias morarem junto dos apps sem virar página do site:

```
web/
  comex_exp_municipio/   → vai ao ar
  shared/                → vai ao ar
  _export/               → não vai
```

O `web-check.yml` valida o site montado e **falha** se achar `.R`, `.Rmd`,
`.md` ou `.mjs` nele. Então acrescentar um guia fora do `_export/` quebra o
PR com a mensagem dizendo onde. Já aconteceu uma vez de um README em
`web/shared/` ir ao ar sem ninguém notar; o guarda existe por causa disso.

O que é compartilhado entre os apps no lado do navegador (CSS e utilitários
de JS) mora em `web/shared/`, que **é** servido. A documentação dele é o
`SHARED.md` aqui.
