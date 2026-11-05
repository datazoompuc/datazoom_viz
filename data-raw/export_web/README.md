# `data-raw/export_web/`

Tudo que diz respeito aos **apps web estáticos** em `web/`: os scripts que
transformam `.rds` em JSON, e a documentação de como e por quê.

Fica separado do resto de `data-raw/` porque aquela pasta tem ~46 scripts que
constroem os `.rds` a partir das fontes originais. São dois estágios
diferentes do mesmo caminho:

```
fonte (IBGE, MDIC, MapBiomas...)
   ↓  data-raw/*.R              <- constrói os .rds
data/*.rds
   ↓  data-raw/export_web/export_*.R   <- converte para JSON
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

Todos rodam a partir da **raiz do repositório**:

```sh
Rscript data-raw/export_web/export_comex_exp_municipio.R
```

## Convenção para apps novos

Ao migrar um app novo para o formato estático, acrescente aqui:

- `export_<app>.R` — o script de export
- `RUNBOOK_<app>.md` — como atualizar e publicar aquele app

A arquitetura e o guia são gerais e não precisam de versão por app.

O que é compartilhado entre os apps no lado do navegador (CSS e utilitários
de JS) mora em `web/shared/`. A documentação daquela pasta é o `SHARED.md`
aqui, e não lá dentro, porque **tudo que está em `web/` é publicado**: o
workflow do Pages manda a pasta inteira para o ar, então um `.md` lá viraria
URL do site.

Pelo mesmo motivo os scripts de export ficam aqui e não em `web/`: script de
build não é conteúdo de site, e ainda entraria no peso do que é publicado.
