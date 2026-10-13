# Como regerar e publicar os dados do app web (ts_comex_exp_municipio)

O app em `web/ts_comex_exp_municipio/` é estático: HTML, CSS e JavaScript lendo
arquivos JSON. Não tem servidor, não tem R rodando em produção. Os JSON são
gerados a partir dos `.rds` do repositório por três scripts em `data-raw/`.

**Quando usar este documento:** sempre que os `.rds` do COMEX forem atualizados.
Enquanto ninguém rodar os passos abaixo, o site continua mostrando os dados
antigos, mesmo que os `.rds` no repositório já estejam novos. Não existe nada
automático hoje.

Quem faz isso não precisa saber JavaScript. São três comandos de R e um
`git push`.

---

## 1. Pré-requisitos

R instalado, e estes pacotes:

```r
install.packages(c("dplyr", "tidyr", "jsonlite", "data.table", "sf"))
```

O `sf` só é necessário para o script do mapa (passo 2c) e é o mais chato de
instalar, porque depende de bibliotecas de sistema (GDAL, GEOS, PROJ). Se você
não mexeu em geometria, pule o 2c e você não precisa do `sf`.

Todos os comandos abaixo rodam a partir da raiz do repositório.

---

## 2. Regerar os JSON

São três scripts independentes. Rode só os que correspondem ao que mudou.

### 2a. Dados principais (quase sempre é só isso)

```sh
Rscript data-raw/export_ts_comex_exp_municipio_web.R
```

Lê:
- `data/comex_exp_munic_sec.rds`
- `data/comex_exp_munic_sh2.rds`
- `data/comex_exp_sec_munic_dic.csv` e `data/comex_exp_sec_munic_en_dic.csv`
- `data/comex_exp_sh2_munic_dic.csv` e `data/comex_exp_sh2_munic_en_dic.csv`

Escreve em `web/ts_comex_exp_municipio/data/`:
`composition_sec.json`, `composition_sh2.json`,
`municipality_composition_sec.json`, `municipality_composition_sh2.json`,
`products_sec.json`, `products_sh2.json`, `municipality_totals.json`,
`region_totals.json` e `dictionary.json`.

### 2b. Ranking por produto SH4

```sh
Rscript data-raw/export_ts_comex_exp_municipio_produtos_web.R
```

Lê `data/comex_exp_sh4_munic.rds` e `data/auxiliar_cod_sh4.rds`.
Escreve `product_ranking.json` (~1,7 MB).

### 2c. Mapa (só se a geometria mudar, o que é raro)

```sh
Rscript data-raw/export_map_comex_exp_sh4_sel_web.R
```

Lê `global/munic_shapefile.rds`, `global/states_boundary.rds`,
`global/legal_amazon_boundary.rds` e `data/comex_exp_munic_sh4_sel.rds`.
Escreve a pasta `map/` (~6,4 MB, a maior parte é fronteira de estado).

Os três scripts imprimem no final o que escreveram. Se algum terminar com erro
de arquivo não encontrado, é porque o `.rds` correspondente não foi gerado ainda:
rode `data-raw/comex.R` antes.

---

## 3. Conferir antes de publicar

### 3a. O intervalo de anos bateu?

```sh
cat web/ts_comex_exp_municipio/data/dictionary.json
```

Deve mostrar o primeiro e o último ano dos dados novos. O app lê esse arquivo
para montar o slider e os textos dos gráficos, então se ele estiver velho o site
inteiro fica velho junto.

Atenção: `year_inicio` e `year_final` estão **fixos** no topo do
`export_ts_comex_exp_municipio_web.R`. Se os dados passarem a cobrir um ano novo,
edite essas duas variáveis no script, senão o app ignora o ano novo.

### 3b. Abrir o app localmente

```sh
cd web/ts_comex_exp_municipio
python3 -m http.server 8000
```

E abrir <http://localhost:8000> no navegador. Não adianta abrir o `index.html`
com dois cliques: o navegador bloqueia a leitura dos JSON em `file://`.

Vale clicar nas seis visualizações (Ranking, Composição, Explorar, Variação,
Tendências, Mapa) e arrastar o slider de ano. Se alguma ficar presa em
"Carregando...", algum JSON não foi gerado.

### 3c. Commitar

```sh
git add web/ts_comex_exp_municipio/data
git commit -m "atualiza dados do app web de COMEX"
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
git commit -m "atualiza dados de COMEX (sync from datazoompuc/datazoom_viz@<SHA>)"
git push origin main
```

No lugar de `<SHA>` use o hash do commit do passo 3c (`git rev-parse --short HEAD`
no `datazoom_viz`). Isso é o que permite descobrir depois qual versão do código
gerou cada versão do site.

**O passo 3 não é opcional.** O `rsync --delete` apaga `.nojekyll` e `README.md`
do repositório do site, porque eles não existem dentro de `web/`. Sem o
`.nojekyll`, o GitHub Pages processa o site com Jekyll e ignora qualquer pasta
começada por underscore, quebrando o site de formas difíceis de diagnosticar.

### Acompanhar a publicação

```sh
gh api repos/datazoompuc/datazoom_viz_web/pages --jq '.status'
```

Enquanto responder `building`, espere. Quando responder `built`, está no ar:

<https://datazoom.com.br/datazoom_viz_web/ts_comex_exp_municipio/>

Costuma levar de um a três minutos.

---

## 5. Armadilhas conhecidas

**O site não mudou depois do deploy.** O CDN guarda `index.html`, `app.js` e
`style.css` por cerca de 10 minutos (`cache-control: max-age=600`), e o navegador
guarda o CSS e o JS por conta própria. Antes de concluir que quebrou alguma
coisa, dê um reload forçado (Ctrl+Shift+R ou Cmd+Shift+R) e espere alguns
minutos. Isso já gerou mais de um falso alarme.

**Um gráfico ficou preso em "Carregando...".** Algum JSON não foi gerado ou não
foi commitado. Confira se os três scripts do passo 2 rodaram sem erro e se o
`git status` não mostra arquivo novo esquecido.

**O slider não chega no ano novo.** É o `year_final` fixo no script, veja 3a.

**Rodei só o 2a e o ranking por produto continua velho.** Os três scripts são
independentes. O 2a não regenera o `product_ranking.json`.

---

## 6. O que alimenta o quê

| `.rds` de origem | script | JSON gerado |
|---|---|---|
| `comex_exp_munic_sec.rds` | 2a | composição, totais, produtos (SEC) |
| `comex_exp_munic_sh2.rds` | 2a | composição, produtos (SH2) |
| `comex_exp_sh4_munic.rds` | 2b | `product_ranking.json` |
| `comex_exp_munic_sh4_sel.rds` + `global/*.rds` | 2c | pasta `map/` |

Os `.rds` acima são produzidos por `data-raw/comex.R` (os de COMEX) e vêm do
`global/` (as geometrias). Este documento começa depois deles: se o `.rds` estiver
velho, regerar os JSON não adianta.
