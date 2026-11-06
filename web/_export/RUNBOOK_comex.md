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
Rscript web/_export/export_comex_exp_municipio.R
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
Rscript web/_export/export_comex_mapa.R
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

**É só fazer merge na `main`.**

O GitHub Pages serve este repositório direto, e o workflow
`.github/workflows/deploy-pages.yml` republica a cada push na `main` que toque
`web/`. Não há repositório de staging, nem `rsync`, nem passo manual.

```sh
git add web/comex_exp_municipio/data
git commit -m "atualiza dados do app de COMEX"
git push
```

Abra um PR como de costume. O `web-check.yml` valida os JSON e o JS antes do
merge; o `deploy-pages.yml` publica depois.

### O que vai ao ar, e o que não vai

O workflow monta o site copiando `web/` **sem a pasta `_export/`**:

```
web/
  comex_exp_municipio/   → vai ao ar
  shared/                → vai ao ar
  _export/               → NÃO vai: scripts e guias, inclusive este arquivo
```

Por isso os scripts de export e a documentação moram em `web/_export/`: ficam
junto do que descrevem, sem virar página do site.

Se você acrescentar um script ou um `.md` fora do `_export/`, o `web-check.yml`
**falha** e diz onde. É de propósito: lista de exclusão erra calada nas duas
direções, enquanto o build falhando aponta o arquivo.

### Acompanhar a publicação

Na aba **Actions** do repositório, o workflow *Deploy web apps to GitHub Pages*.
Costuma levar de um a três minutos. O endereço do app aparece no resumo da
execução.

## 4b. O app dentro do site

A página <https://datazoom.com.br/amazonia/pt/viz/comercio-exterior/> embute o
app num iframe. O endereço de lá leva `?embed=1`:

```
.../comex_exp_municipio/?embed=1
.../comex_exp_municipio/?lang=en&embed=1
```

Esse parâmetro esconde o que a página já mostra: a marca e a descrição na
barra lateral, a logo do rodapé dela, e o seletor de idioma. O seletor em
especial não pode aparecer ali — ele trocaria só o conteúdo do iframe e
deixaria a página em volta no idioma anterior. Quem manda no idioma é a nav
bar do site.

Aberto direto na própria URL, sem o parâmetro, o app continua completo.

## 5. Armadilhas conhecidas

**O site não mudou depois do deploy.** O CDN guarda `index.html`, `app.js` e
`style.css` por cerca de 10 minutos (`cache-control: max-age=600`), e o navegador
guarda o CSS e o JS por conta própria. Antes de concluir que quebrou alguma
coisa, dê um reload forçado (Ctrl+Shift+R ou Cmd+Shift+R) e espere alguns
minutos. Isso já gerou mais de um falso alarme.

**Um gráfico ficou preso em "Carregando...".** Algum JSON não foi gerado ou não
foi commitado. Confira se os scripts do passo 2 rodaram sem erro e se o
`git status` não mostra arquivo novo esquecido.

**O PR falhou em "Check web/ static apps".** Se a queixa for sobre script ou
documento, você pôs um arquivo em `web/` fora do `_export/` e ele viraria
página do site. A mensagem diz qual. Se for JSON ou JS, algum arquivo gerado
saiu malformado: rode o export de novo.

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
