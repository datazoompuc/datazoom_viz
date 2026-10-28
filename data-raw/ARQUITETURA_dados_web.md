# Como derivar os JSON de um app web a partir de uma base

## 1. Objetivo e para quem é

Este documento é para quem vai desenhar os dados de um app web novo, ou mexer
nos dados de um que já existe. Ele explica **como decidir** quais arquivos JSON
gerar, em que formato, e em quantos scripts, de forma a não repetir a
multiplicação de `.rds` que existe hoje.

Não é um passo a passo de execução. Como rodar os scripts, conferir o resultado
e publicar está em `README_export_web.md`. O receituário de código para derivar
os JSON de uma base longa, com as armadilhas que apareceram na migração do
COMEX, está em `GUIA_base_long_para_json.md`. Os três ficam lado a lado em
`data-raw/`: este diz por quê, o guia diz como, o runbook diz o que rodar.

Os exemplos vêm do `web/comex_exp_municipio/`, que é o app mais completo
hoje, mas os princípios valem para qualquer um.

---

## 2. Dois princípios centrais

Quase toda a multiplicação de arquivos vem de desrespeitar um destes dois.

### 2a. Uma base, muitas derivações

O padrão caro é dar a cada visualização o seu próprio arquivo pré-agregado.
Como cada visualização quer um recorte diferente, o número de arquivos cresce
junto com o número de telas, e qualquer correção precisa ser aplicada em todos.

Dois exemplos concretos do estado atual:

- `data/comex_exp_munic_sec.rds` tem 596 linhas por 449 colunas, com municípios
  nas colunas. `data/comex_exp_sec_munic.rds` tem 6.297 por 24, com categorias
  nas colunas. **São o mesmo dado transposto** (as somas batem). Existem dois
  arquivos porque duas telas queriam a tabela virada de jeitos diferentes.
- O mesmo par se repete em SH2 (`comex_exp_munic_sh2.rds` e
  `comex_exp_sh2_munic.rds`).

Com uma base longa, nada disso precisa existir em disco. Virar a tabela é um
`group_by` diferente no momento de gerar o JSON, não um arquivo novo. Quem
decide o formato é quem exporta, e exportar é barato.

**Regra:** o `.rds` guarda o grão, não o recorte. Se dois arquivos contêm a
mesma informação em formatos diferentes, um deles não deveria existir.

### 2b. Enviar o grão, não a resposta

Este corta mais arquivo que o anterior, e é o menos intuitivo.

A tentação é pré-calcular o que a tela mostra. O ranking de municípios para
2025, filtrado por categoria X, ordenado por valor — isso é um resultado, e dá
para gerar um arquivo com ele. O problema é que são 29 anos vezes 22 categorias
SEC vezes duas medidas, e isso já são mais de mil arquivos para uma única tela.

O app não faz isso. Ele recebe `municipality_totals.json`, que é só
município × ano × valor, e **ordena no navegador**. Trocar de ano, de filtro ou
de ordenação não busca nada novo: é um `sort` em memória, instantâneo. O mesmo
dado alimenta o ranking, as tendências, o explorar e a variação, que são quatro
telas diferentes lendo um arquivo só.

**Regra:** se o navegador consegue derivar o resultado a partir do que já
baixou, mande o grão e deixe ele derivar. Só pré-calcule quando a conta for
pesada demais para o cliente ou exigir dados que ele não tem.

---

## 3. Dois recortes que não se confundem

Este é o erro conceitual mais fácil de cometer, e vale deixar explícito:

| | decidido por | pergunta que responde |
|---|---|---|
| **Recorte dos arquivos JSON** | o navegador | o que precisa estar disponível, e quando? |
| **Recorte dos scripts** | dependências e cadência | o que é caro ou chato de rodar junto? |

São eixos independentes. Um script só pode gerar quinze arquivos JSON, e três
scripts podem gerar um arquivo cada. Decidir um não decide o outro.

Juntar os dois é o que produz o pior resultado possível: um script por
visualização, cada um relendo a mesma base e refazendo agregação parecida.

---

## 4. Decidindo o recorte dos arquivos JSON

O critério é o tempo até a primeira tela útil. Tudo que não é necessário para
desenhar a primeira tela deve estar em arquivo separado, carregado só quando o
usuário pedir.

No app de COMEX hoje:

| | tamanho | quando carrega |
|---|---|---|
| carga inicial | 0,9 MB | sempre |
| sob demanda | 11,2 MB | só se o usuário abrir aquela visualização |

São **93% do payload adiado**. Quem abre o app, olha o ranking e fecha baixou
0,9 MB em vez de 12 MB. O que fica para depois:

- SH2 (281 KB + 594 KB + 33 KB) — só se trocar a agregação de produto
- `product_ranking.json` (1,7 MB) — só se filtrar por produto SH4
- país (225 KB + 1,8 MB + 31 KB) — só se abrir a orientação Países
- o mapa (6,4 MB, quase tudo fronteira de estado) — só se abrir o Mapa

A proporção melhorou quando país entrou: a dimensão nova acrescentou 2 MB ao
total sem tocar num byte da carga inicial. É assim que tem que ser.

Do lado do dado, isso exige que o recorte seja previsível: um arquivo por
unidade que o usuário pode pedir. Do lado do app, cada um desses tem uma função
`ensure*Loaded()` que busca na primeira vez e guarda daí em diante.

**Regra prática:** se mais da metade dos usuários não vai usar aquele dado, ele
não deve estar na carga inicial.

---

## 5. Os quatro formatos, e quando usar cada um

### 5a. Série simples

Array de objetos, um por observação:

```json
[{"municipio": "Belém - PA", "ano": 1997, "valor": 20008803}, ...]
```

Usado em `municipality_totals.json` (740 KB) e `region_totals.json`. Legível,
trivial de gerar com `jsonlite::write_json(..., dataframe = "rows")`, e
suficiente quando o volume é pequeno. É o default: só saia dele quando houver
motivo.

### 5b. Cross-product esparso

Quando o dado é o cruzamento de várias dimensões, a grade cheia é quase toda
zero e repetir o nome das dimensões em cada célula domina o arquivo.

Densidade real no COMEX:

| grade | células possíveis | preenchidas | densidade |
|---|---|---|---|
| município × categoria SEC × ano | 297.000 | 18.978 | 6,4% |
| município × categoria SH2 × ano | 1.309.500 | 31.060 | 2,4% |
| município × país × ano | 3.199.500 | 86.763 | 2,7% |

O formato usado em `municipality_composition_*.json` é:

```json
{
  "municipios": ["Abaetetuba - PA", "Abel Figueiredo - PA", ...],
  "produtos":   ["Animais vivos...", "Produtos minerais", ...],
  "cells":      [[29, 0, 1997, 150164], ...]
}
```

Dois arrays de lookup e uma lista de células `[índice_município,
índice_produto, ano, valor]`, **descartando os zeros**. O nome de cada
município aparece uma vez, não uma vez por célula.

O ganho medido, para SH2: **595 KB contra 16,8 MB** da mesma informação como
objeto aninhado em grade cheia. Vinte e oito vezes menor.

Foi esta técnica que tornou viável acrescentar país. A 2,7% de densidade a
grade cheia seria inviável; esparsa, são 1,8 MB carregados sob demanda.

**Regra:** densidade abaixo de uns 30%, use esparso.

### 5c. Metadados

`dictionary.json` carrega o que descreve o conjunto, não os dados: hoje o
primeiro e o último ano. O app lê isso para montar o slider e os textos.

É onde entram naturalmente as flags de dado parcial (se existe ano incompleto e
até que mês). A alternativa de carregar esse metadado como colunas repetidas na
própria base funciona e tem a vantagem de nunca sair de sincronia com os dados;
o custo é repetir um escalar em centenas de milhares de linhas. Qualquer um dos
dois serve, desde que seja um só.

**Regra:** metadado em um lugar só, e nunca duplicado em cada arquivo.

### 5d. Geometria

GeoJSON, sempre em arquivo próprio. Geometria é grande (6,4 MB dos 10,4 MB do
app, sendo 4,4 MB só de fronteira estadual), praticamente não muda entre
atualizações, e é a única coisa que exige `sf` para gerar. Misturar geometria
com dado de atributo é o pior dos dois mundos: regenera o que não mudou e
obriga quem só quer atualizar números a ter a pilha geoespacial instalada.

---

## 6. Várias medidas na mesma base

A base do COMEX já traz duas medidas lado a lado, `valor_fob` (US$ nominais) e
`kg_liquido`. Valor deflacionado ficou de fora por decisão de out/2026, com a
quantidade servindo de base para calcular valor real depois — ou seja, uma
terceira medida é esperada.

Isso muda o desenho da base, e vale decidir agora em vez de depois.

**O que não fazer:** uma tabela por medida. Elas têm exatamente as mesmas
dimensões e o mesmo grão. Separar significa triplicar o número de arquivos,
triplicar o custo de qualquer correção de dimensão, e criar a possibilidade de
as três saírem de sincronia.

**O que fazer:** medidas como colunas lado a lado na mesma linha.

```
ano | cod_municipio | uf | cod_sh4 | cod_sh2 | cod_sec | cod_pais | valor_fob | kg_liquido | valor_real
```

Acrescentar uma quarta medida depois vira uma coluna a mais, não um arquivo a
mais, e nada do que já existe muda.

Duas consequências práticas:

- **Medida derivada não precisa ser armazenada.** Valor unitário (US$/kg) é
  `valor_fob / kg_liquido`, e sai de graça no export ou no próprio navegador.
  Só armazene o que não dá para recalcular. Deflator é o caso oposto: depende
  de um índice externo, então precisa vir pronto da base.
- **Deflator pede metadado.** Valor real só significa alguma coisa se estiver
  claro qual índice foi usado e qual é o ano-base. Isso é metadado de conjunto,
  então vai em `dictionary.json` (ver 5c) e aparece na legenda do gráfico. Um
  eixo que diz só "US$" quando os valores são de 2025 constantes está errado.

Do lado do app, acrescentar medida é barato porque o código já separa "qual
coluna estou lendo" de "como eu desenho". Foi assim que a escala logarítmica e
a indexação entraram no Explorar sem tocar no resto.

---

## 7. Decidindo o recorte dos scripts

Separe por **dependência** e por **cadência**, nunca por visualização.

- *Dependência*: o script do mapa precisa de `sf`, que puxa GDAL, GEOS e PROJ.
  É de longe a dependência mais chata de instalar e a mais pesada em CI. Tudo
  que não precisa dela fica livre dela.
- *Cadência*: geometria muda quando o IBGE muda limite municipal, ou seja,
  quase nunca. Dado de COMEX muda a cada atualização. Rodar os dois juntos é
  regerar 6,4 MB idênticos a cada vez.

No COMEX, depois da migração para a base longa, isso deu **dois scripts**:

1. **Tudo que sai da base longa** — ranking, composição, tendências, variação,
   explorar. Mesma fonte, mesmas dependências (`dplyr`, `tidyr`, `jsonlite`),
   muda só o `group_by`. Eram dois scripts só porque as fontes eram `.rds`
   diferentes; com a base unificada deixaram de ter razão de ser e viraram um.
2. **Mapa** — precisa de `sf`, lê shapefiles de `global/`, roda raramente.

Não faça um script por visualização. Cada um releria a mesma base e refaria
agregação parecida, que é a mesma multiplicação dos `.rds`, movida um andar
abaixo. Um passo só sobre a base, gerando todos os arquivos derivados dela,
é mais rápido e mantém a lógica de agregação num lugar só.

---

## 8. Checklist para uma visualização nova

Na ordem:

1. **Que grão ela precisa?** Dimensões e medida, no nível mais fino que a tela
   realmente usa.
2. **Já existe JSON nesse grão?** Se sim, acabou: a tela lê o que já está lá.
   Foi assim que ranking, tendências, explorar e variação acabaram
   compartilhando `municipality_totals.json`.
3. **O navegador consegue derivar isso do que já baixou?** Se sim, não gere
   arquivo nenhum (princípio 2b).
4. **Precisa no load inicial ou sob demanda?** Na dúvida, sob demanda.
5. **Qual formato?** Calcule a densidade. Acima de ~30%, série simples; abaixo,
   esparso.
6. **Cabe num script que já existe?** Se as dependências e a cadência forem as
   mesmas, sim. Script novo só quando um dos dois mudar.

---

## 9. Apêndice: o app de COMEX hoje

| visualização | lê | grão | quando |
|---|---|---|---|
| Ranking | `municipality_totals.json` | município × ano | inicial |
| Ranking (filtrado por categoria) | `municipality_composition_{sec,sh2}.json` | município × produto × ano | SEC inicial, SH2 sob demanda |
| Ranking (filtrado por SH4) | `product_ranking.json` | produto × município × ano | sob demanda |
| Composição | `composition_*.json`, `municipality_composition_*.json` | produto × ano | SEC inicial, SH2 sob demanda |
| Tendências | `municipality_totals.json` | município × ano | inicial |
| Variação | `municipality_totals.json` | município × ano | inicial |
| Explorar | `municipality_totals.json` | município × ano | inicial |
| Ranking/Tendências/Variação/Explorar (orientação Países) | `municipality_composition_pais.json`, `composition_pais.json` | município × país × ano | sob demanda |
| Mapa | `map/*.geojson`, `map/map_data.json` | município (geometria) | sob demanda |
| todas | `dictionary.json` | metadado | inicial |

Quatro das nove linhas lêem o mesmo arquivo. Isso não é coincidência: é o
princípio 2b funcionando. Se cada uma tivesse recebido o seu recorte pronto,
seriam quatro arquivos com a mesma informação, e o número cresceria a cada
filtro novo.

A sparkline do topo e o total da região saem de `region_totals.json`, que é o
único arquivo pequeno o bastante para não valer discussão.

Repare na penúltima linha: quatro telas compartilham **um** par de arquivos para
a orientação Países, porque as quatro querem o mesmo grão. Se cada uma tivesse
ganho o seu recorte, seriam oito arquivos em vez de dois — e a dimensão seguinte
custaria oito de novo.
