# Como regerar e publicar os dados do mapa CEMPRE (map_dz_munic_cempre)

O app em `web/map_dz_munic_cempre/` é estático: HTML, CSS e JavaScript lendo
arquivos JSON e GeoJSON. Não tem servidor, não tem R rodando em produção.

**Quando usar este documento:** sempre que o `.rds` do CEMPRE for atualizado.
Enquanto ninguém rodar os passos abaixo, o site continua mostrando os dados
antigos, mesmo que o `.rds` no repositório já esteja novo. Não existe nada
automático hoje.

O CEMPRE é anual, então isso acontece uma vez por ano — o que é justamente o
motivo de estar escrito: ninguém lembra de um procedimento que roda uma vez
ao ano.

Quem faz isso não precisa saber JavaScript. É um comando de R e um `git push`.

---

## 1. Pré-requisitos

```r
install.packages(c("dplyr", "sf", "jsonlite", "readr"))
```

O `sf` é o mais chato de instalar, porque depende de bibliotecas de sistema
(GDAL, GEOS, PROJ). Aqui ele não é opcional: este app é um mapa e o script
sempre reexporta a geometria.

Todos os comandos rodam a partir da raiz do repositório.

---

## 2. Regerar os dados

```sh
Rscript data-raw/export_map_dz_munic_cempre_web.R
```

Lê:
- `data/cempre_municipality_dza.rds` — os atributos (as 4 variáveis por município e ano)
- `global/munic_shapefile.rds` — polígonos dos municípios
- `global/states_boundary.rds` — fronteiras estaduais
- `global/legal_amazon_boundary.rds` — contorno da Amazônia Legal

Escreve em `web/map_dz_munic_cempre/data/`:
`attributes.json`, `dictionary.json`, `municipalities.geojson`,
`states_boundary.geojson` e `legal_amazon_boundary.geojson` (~8,6 MB no total,
quase tudo geometria).

Se terminar com erro de arquivo não encontrado, é porque o `.rds` do CEMPRE não
foi gerado ainda — veja `config/dataset_registry.csv` para o script que o
constrói.

### A paleta não é regerada aqui

`data-raw/build_sequential_ramp.mjs` gera a escala de 9 cores usada pelo mapa
e está **fixa** no `app.js` (`PALETTE_CONTINUOUS`). Não precisa rodar na
atualização de dados; só se alguém quiser mudar a paleta. Nesse caso:

```sh
node data-raw/build_sequential_ramp.mjs
```

e cole o resultado no `app.js`. O cabeçalho do script explica como validar o
resultado.

---

## 3. Conferir antes de publicar

### 3a. Abrir localmente

```sh
cd web/map_dz_munic_cempre
python3 -m http.server 8000
```

E abrir <http://localhost:8000>. Não adianta abrir o `index.html` com dois
cliques: o navegador bloqueia a leitura dos JSON em `file://`.

Vale conferir: o mapa colore, o slider de ano anda, o "Comparar anos" abre o
gráfico de dumbbell, e "Salvar imagem" baixa um PNG.

### 3b. O ano novo apareceu?

O slider deve ir até o ano novo. O intervalo sai do próprio dado, não há nada
fixo no script para editar.

### 3c. Commitar

```sh
git add web/map_dz_munic_cempre/data
git commit -m "atualiza dados do mapa CEMPRE"
git push
```

---

## 4. Publicar

> Hoje o site é servido pelo repositório **`datazoompuc/datazoom_viz_web`**, que
> é um espelho só da pasta `web/`. O plano é tornar o `datazoom_viz` público e
> servir o GitHub Pages direto dele, o que elimina esta seção inteira. Enquanto
> isso não acontece, siga os passos abaixo.

```sh
# 1. clonar o repositório do site
git clone https://github.com/datazoompuc/datazoom_viz_web.git /tmp/dzweb

# 2. copiar o conteúdo de web/ por cima
rsync -a --delete --exclude ".git" web/ /tmp/dzweb/

# 3. RESTAURAR os dois arquivos que só existem no repositório do site
cd /tmp/dzweb
git checkout -- .nojekyll README.md

# 4. conferir que só mudou o que você esperava
git status --short

# 5. commitar e publicar
git add -A
git commit -m "atualiza dados do CEMPRE (sync from datazoompuc/datazoom_viz@<SHA>)"
git push origin main
```

**O passo 3 não é opcional.** O `rsync --delete` apaga `.nojekyll` e `README.md`
do repositório do site, porque eles não existem dentro de `web/`. Sem o
`.nojekyll`, o GitHub Pages processa o site com Jekyll e ignora qualquer pasta
começada por underscore, quebrando o site de formas difíceis de diagnosticar.

Repare que o `rsync` sincroniza **toda** a pasta `web/`, não só este app. Se
houver outro app com alterações não publicadas, elas vão junto.

### Acompanhar a publicação

```sh
gh api repos/datazoompuc/datazoom_viz_web/pages --jq '.status'
```

Enquanto responder `building`, espere. Quando responder `built`, está no ar:

<https://datazoom.com.br/datazoom_viz_web/map_dz_munic_cempre/>

Costuma levar de um a três minutos.

---

## 5. Armadilhas conhecidas

**O site não mudou depois do deploy.** O CDN guarda `index.html`, `app.js` e
`style.css` por cerca de 10 minutos, e o navegador guarda o CSS e o JS por
conta própria. Antes de concluir que quebrou alguma coisa, dê um reload forçado
(Ctrl+Shift+R ou Cmd+Shift+R) e espere alguns minutos.

**O mapa aparece mas sem cor.** O `attributes.json` não foi gerado ou não foi
commitado. Confira o `git status`.

**"Não foi possível carregar os dados."** Algum arquivo de `data/` não chegou
ao servidor. O botão "Tentar novamente" recarrega a página; se persistir, veja
o console do navegador para saber qual arquivo deu 404.

**Leaflet vem de CDN.** O app carrega Leaflet de `unpkg.com`. Se a unpkg estiver
fora do ar, o mapa não abre. Não há fallback local hoje.

---

## 6. O que alimenta o quê

| `.rds` de origem | JSON gerado |
|---|---|
| `data/cempre_municipality_dza.rds` | `attributes.json`, `dictionary.json` |
| `global/munic_shapefile.rds` | `municipalities.geojson` |
| `global/states_boundary.rds` | `states_boundary.geojson` |
| `global/legal_amazon_boundary.rds` | `legal_amazon_boundary.geojson` |

A geometria praticamente não muda entre atualizações — ela é reexportada junto
só porque o script é um só. Se um dia isso incomodar (são ~8 MB), vale separar
em dois scripts: um para a geometria, que quase nunca muda, e outro para os
atributos. O raciocínio está escrito em `ARQUITETURA_dados_web.md`, que chega
junto com o PR do COMEX (#257) — se ele ainda não tiver sido mergeado, o
arquivo não existe aqui.
