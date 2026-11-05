# Como regerar e publicar os dados do app web (ts_comex_exp_municipio)

O app em `web/comex_exp_municipio/` é estático: HTML, CSS e JavaScript lendo
arquivos JSON. Não tem servidor, não tem R rodando em produção. Os JSON são
gerados a partir dos `.rds` do repositório por **dois** scripts em `data-raw/`:
um lê a base longa do COMEX e gera quase tudo, o outro cuida só do mapa.

**Quando usar este documento:** sempre que os `.rds` do COMEX forem atualizados.
Enquanto ninguém rodar os passos abaixo, o site continua mostrando os dados
antigos, mesmo que os `.rds` no repositório já estejam novos. Não existe nada
automático hoje.

Quem faz isso não precisa saber JavaScript. São um ou dois comandos de R e um
`git push`.

---

## 1. Pré-requisitos

R instalado, e estes pacotes:

```r
install.packages(c("dplyr", "tidyr", "jsonlite", "sf"))
```

O `sf` só é necessário para o script do mapa (passo 2b) e é o mais chato de
instalar, porque depende de bibliotecas de sistema (GDAL, GEOS, PROJ). Se você
não mexeu em geometria, pule o 2b e você não precisa do `sf`.

Todos os comandos abaixo rodam a partir da raiz do repositório.

---

## 2. Regerar os JSON

### 2a. Tudo que sai da base do COMEX (quase sempre é só isso)

```sh
Rscript data-raw/web/export_comex_exp_municipio.R
```

Lê **um arquivo só**: `data/comex_exp_munic_base.rds`, a base longa gerada
por `data-raw/comex.R` e descrita em `../README_data.md`. Desde o merge de
nov/2026 ela traz o nome do município, então não há mais auxiliar nenhum.

Escreve 13 arquivos em `web/comex_exp_municipio/data/`:

| Arquivo | O que é |
|---|---|
| `municipality_totals.json`, `region_totals.json` | totais por município e da região |
| `composition_sec.json`, `composition_sh2.json`, `composition_pais.json` | composição da região por categoria e por destino |
| `municipality_composition_{sec,sh2,pais}.json` | o cruzamento município × categoria, em formato esparso |
| `products_sec.json`, `products_sh2.json`, `paises.json` | os rótulos pt/en |
| `product_ranking.json` | ranking no nível SH4 |
| `dictionary.json` | intervalo de anos e quais são parciais |

São treze recortes diferentes da mesma base, por isso saem todos de um script
só. O porquê está em `ARQUITETURA.md`.

Cada arquivo de dados carrega **as duas medidas**, valor e quantidade, na
mesma estrutura. É o que permite o botão Valor/Quantidade do app trocar sem
buscar nada.

### 2b. Mapa (só se a geometria mudar, o que é raro)

```sh
Rscript data-raw/web/export_comex_mapa.R
```

Lê `global/munic_shapefile.rds`, `global/states_boundary.rds`,
`global/legal_amazon_boundary.rds` e `data/comex_exp_munic_sh4_sel.rds`.
Escreve a pasta `map/` (~6,4 MB, a maior parte é fronteira de estado).

Fica separado porque é o único que precisa do `sf` e porque fronteira
municipal quase não muda: rodar junto a cada atualização de dado seria
regerar 6,4 MB idênticos aos anteriores.

Os scripts imprimem no final o que escreveram. Se algum terminar com erro de
arquivo não encontrado, é porque o `.rds` correspondente não foi gerado ainda:
rode `data-raw/comex.R` antes.

## 3. Conferir antes de publicar

### 3a. O intervalo de anos bateu?

```sh
cat web/comex_exp_municipio/data/dictionary.json
```

Deve mostrar o primeiro e o último ano dos dados novos. O app lê esse arquivo
para montar o slider e os textos dos gráficos, então se ele estiver velho o site
inteiro fica velho junto.

O intervalo de anos agora sai da própria base, não há mais nada fixo no script
para editar.

Confira também `year_final_completo` e `anos_parciais`. A base pode terminar num
ano incompleto (em 2026, 9 meses). O app abre no último ano completo e marca o
parcial com "parcial · N meses" ao lado do ano, além de tracejar o último trecho
da sparkline. Se `anos_parciais` vier vazio quando deveria ter algo, as séries
vão mostrar uma queda no último ponto que é só calendário.

### 3b. Abrir o app localmente

```sh
cd web/comex_exp_municipio
python3 -m http.server 8000
```

E abrir <http://localhost:8000> no navegador. Não adianta abrir o `index.html`
com dois cliques: o navegador bloqueia a leitura dos JSON em `file://`.

Vale clicar nas seis visualizações (Ranking, Composição, Explorar, Variação,
Tendências, Mapa) e arrastar o slider de ano. Se alguma ficar presa em
"Carregando...", algum JSON não foi gerado.

### 3c. Commitar

```sh
git add web/comex_exp_municipio/data
git commit -m "atualiza dados do app web de COMEX"
git push
```

---

## 4. Publicar

> Hoje o site é servido pelo repositório **`datazoompuc/datazoom_viz_web`**, que
> é um espelho da pasta `web/`. O plano é tornar o `datazoom_viz` público e
> servir o GitHub Pages direto dele, o que elimina esta seção inteira. Enquanto
> isso não acontece, siga os passos abaixo.

### ⚠️ Sincronize por app, não a pasta `web/` inteira

O staging hospeda **todos** os apps, mas cada app em desenvolvimento vive na
sua própria branch. Então a sua branch quase nunca tem a pasta `web/`
completa: o app de COMEX está numa branch, o mapa do CEMPRE está em outra.

Um `rsync --delete web/ ...` apaga do site tudo que não existe na sua branch.
Na prática isso significa **derrubar os apps dos outros** sem perceber. Em
novembro de 2026 esse comando teria apagado o `map_dz_munic_cempre` inteiro,
dados e tudo.

Por isso o `rsync` abaixo é feito **uma pasta por vez**, nomeando o que a sua
branch de fato possui. O `--delete` continua valendo dentro de cada pasta, que
é o que você quer (arquivo removido do app some do site), sem alcançar o que
não é seu.

Quando os PRs dos apps mergearem na main, a `web/` passa a ser completa em
todo lugar e esse cuidado deixa de ser necessário. O workflow de publicação
automática (PR #253) também não tem esse risco, porque roda a partir da main.

```sh
# 1. clonar o repositório do site
git clone https://github.com/datazoompuc/datazoom_viz_web.git /tmp/dzweb

# 2. VER o que seria apagado, antes de apagar
rsync -a --delete --exclude ".git" --dry-run --itemize-changes \
  web/ /tmp/dzweb/ | grep "^\*deleting"
#    Se aparecer qualquer coisa de um app que não é o seu, NÃO use o
#    comando acima para valer. Use o passo 3.

# 3. copiar uma pasta por vez (ajuste a lista ao que a sua branch tem)
rsync -a --delete --exclude ".git" web/comex_exp_municipio /tmp/dzweb/
rsync -a --delete --exclude ".git" web/shared             /tmp/dzweb/

# 4. RESTAURAR os dois arquivos que só existem no repositório do site
cd /tmp/dzweb
git checkout -- .nojekyll README.md

# 5. conferir que só mudou o que você esperava
git status --short

# 6. commitar e publicar
git add -A
git commit -m "atualiza dados de COMEX (sync from datazoompuc/datazoom_viz@<SHA>)"
git push origin main
```

No lugar de `<SHA>` use o hash do commit do passo 3c (`git rev-parse --short HEAD`
no `datazoom_viz`). É o que permite descobrir depois qual versão do código gerou
cada versão do site.

**O passo 4 não é opcional.** O `rsync --delete` apaga `.nojekyll` e `README.md`
do repositório do site quando você sincroniza a raiz, porque eles não existem
dentro de `web/`. Sem o `.nojekyll`, o GitHub Pages processa o site com Jekyll
e ignora qualquer pasta começada por underscore, quebrando o site de formas
difíceis de diagnosticar. Sincronizando por pasta eles não são tocados, mas o
`git checkout` é barato e garante.

### Acompanhar a publicação

```sh
gh api repos/datazoompuc/datazoom_viz_web/pages --jq '.status'
```

Enquanto responder `building`, espere. Quando responder `built`, está no ar:

<https://datazoom.com.br/datazoom_viz_web/comex_exp_municipio/>

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

**O último ano parece ter despencado.** Provavelmente é ano parcial. Confira
`anos_parciais` no `dictionary.json` (veja 3a). Em 2026, com 9 de 12 meses, o
total fica 14% abaixo de 2025, mas anualizado está 14% acima.

---

## 6. O que alimenta o quê

| `.rds` de origem | script | JSON gerado |
|---|---|---|
| `comex_exp_munic_base.rds` | 2a | os 13 da raiz de `data/` |
| `comex_exp_munic_sh4_sel.rds` + `global/*.rds` | 2b | os 4 da pasta `map/` |

Os `.rds` acima são produzidos por `data-raw/comex.R` (os de COMEX) e vêm do
`global/` (as geometrias). Este documento começa depois deles: se o `.rds` estiver
velho, regerar os JSON não adianta.
