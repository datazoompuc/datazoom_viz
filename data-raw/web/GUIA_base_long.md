# Guia: transformar uma base longa nos JSON de um app web

Companheiro prático do `ARQUITETURA.md`. Aquele explica **por que**
uma base só e como decidir os recortes; este mostra **como** fazer, com o
código e as armadilhas reais do COMEX, que foi o primeiro app migrado para
esse formato.

Serve de modelo para os próximos (MapBiomas é o candidato imediato).

---

## 1. O que a base longa precisa ter

O COMEX acertou quase tudo na primeira tentativa. A lista abaixo é o que
funcionou, mais o que faltou.

### 1a. Uma linha por combinação, no grão mais fino que alguma tela usa

```
ano | cod_sh4 | cod_sh2 | cod_municipio | uf | cod_pais | valor_fob | kg_liquido | ...
```

Uma linha por `ano × SH4 × município × país`. Nada pré-agregado: cada recorte
que o app precisa sai de um `group_by` diferente sobre isso.

Dá 302.060 linhas e 5,9 MB. Para efeito de comparação, as matrizes largas que
esse arquivo substituiu somavam mais arquivos e mais bytes carregando **menos**
informação (sem país, sem quantidade).

### 1b. Códigos *e* taxonomias intermediárias

A base traz `cod_sh4`, `cod_sh2` **e** `cod_sec` juntos, em vez de só o mais
fino. Parece redundante — SH2 dá para derivar de SH4 — mas evita que o script
de export precise carregar uma tabela de-para, e deixa a agregação ser um
`group_by` direto. Foi uma boa decisão deles.

### 1c. Uma coluna por medida, nunca uma tabela por medida

`valor_fob` e `kg_liquido` lado a lado na mesma linha. Acrescentar uma terceira
medida (valor deflacionado, quando houver) é uma coluna, não um arquivo.

Medida que dá para calcular não precisa ser guardada: valor unitário é
`valor_fob / kg_liquido` e sai no export ou no próprio navegador.

### 1d. Rótulos de TODA dimensão, nos dois idiomas

A base traz `pais_pt`, `pais_en`, `sh4_pt`, `sh4_en`, `sh2_pt`, `sh2_en`,
`sec_pt`, `sec_en`. Isso eliminou quatro CSVs de dicionário que o export lia
antes, e com eles uma classe inteira de bug (dicionário fora de sincronia com
os dados).

**A exceção, e a lição:** o nome do município ficou de fora — a base tem só
`cod_municipio` e `uf`. Como o app indexa municípios pela string
`"Nome - UF"`, o export precisa de um `left_join` com
`auxiliar_cod_municipais.rds`, que é justamente um dos auxiliares que a
limpeza queria eliminar.

Não dá para contornar pelo pacote: tanto `datazoom.amazonia::municipalities$name_muni`
quanto `$municipality_mapbiomas` vêm **sem acento**, o que renomearia 212 dos
450 municípios ("Açailândia" → "Acailandia") e quebraria toda URL salva.

> **Regra:** se uma dimensão aparece como rótulo em alguma tela, o rótulo vem
> na base. Vale para a dimensão principal tanto quanto para as categóricas.

### 1e. Metadados de completude

`n_meses` e `ano_parcial` marcam o ano em curso. Sem isso o app não tem como
saber que 2026 tem 9 meses, e **todo gráfico mostra uma queda de 14% que é só
calendário** (anualizado, 2026 está 14% acima de 2025).

Carregar isso como colunas repetidas em 302 mil linhas é desperdício de bytes,
mas tem a vantagem real de nunca sair de sincronia com os dados. Funciona. O
export colapsa para um objeto pequeno no `dictionary.json`.

### 1f. Chaves estáveis

Qualquer coisa que vire chave de JSON (nome de município, nome de categoria)
tem que ser estável entre atualizações. Mudar "Açailândia - MA" para outra
grafia invalida links salvos e quebra o estado guardado na URL.

Quando o COMEX passou de 446 para 450 municípios, os 446 antigos continuaram
idênticos e os 4 novos entraram como adição. É assim que tem que ser.

---

## 2. O receituário

Todo output é a mesma receita com um `group_by` diferente. O exemplo completo
está em `web/export_comex_exp_municipio.R`.

### Preparação, uma vez

```r
base <- readRDS("data/comex_exp_munic_base.rds")

# rótulos que não vieram na base
base <- base %>%
  mutate(cod_municipio = as.character(cod_municipio)) %>%
  left_join(municipios_aux, by = "cod_municipio")

# a medida, num nome só, para trocar depois sem reescrever nada
MEDIDA <- "valor_fob"
base$valor <- base[[MEDIDA]]
```

Vale falhar alto se o join não fechar, em vez de exportar JSON com `null`:

```r
faltando <- sum(is.na(base$municipio))
if (faltando > 0) stop(sprintf("%d linhas sem nome de municipio", faltando))
```

### Totais de uma entidade

```r
munic_totals <- base %>%
  group_by(municipio, ano) %>%
  summarise(valor = round(sum(valor)), .groups = "drop")
```

Soma sobre **todas** as outras dimensões. Alimenta quatro telas sozinho.

### Composição regional por categoria

```r
composition <- base %>%
  group_by(produto = sec_pt, ano) %>%
  summarise(valor = round(sum(valor)), .groups = "drop")
```

### Cruzamento entidade × categoria (formato esparso)

O caso que exige cuidado, porque a grade cheia é quase toda zero:

```r
por_municipio <- base %>%
  group_by(municipio, produto = sec_pt, ano) %>%
  summarise(valor = sum(valor), .groups = "drop") %>%
  filter(valor > 0)                      # <- o que torna esparso

municipios_idx <- sort(unique(por_municipio$municipio))
produtos_idx   <- sort(unique(por_municipio$produto))

list(
  municipios = municipios_idx,
  produtos   = produtos_idx,
  cells = por_municipio %>%
    transmute(
      municipio_idx = match(municipio, municipios_idx) - 1L,
      produto_idx   = match(produto,   produtos_idx)   - 1L,
      ano = as.integer(ano),
      valor = round(valor)
    ) %>% as.matrix() %>% unname()
)
```

Os índices são **0-based** (`- 1L`) porque quem lê é JavaScript.

Densidades reais, para calibrar quando isso vale a pena:

| grade | densidade | esparso | grade cheia |
|---|---|---|---|
| município × SEC × ano | 6,3% | 368 KB | — |
| município × SH2 × ano | 2,3% | 595 KB | 16,8 MB |
| município × país × ano | 2,7% | 1,8 MB | — |

Vinte e oito vezes menor no caso do SH2. Abaixo de uns 30% de densidade, use
esparso.

### Rótulos

```r
dic <- base %>%
  distinct(var = sec_pt, label_en = sec_en) %>%
  filter(var %in% produtos_idx)

list(pt = dic %>% transmute(var, label = var),
     en = dic %>% transmute(var, label = coalesce(label_en, var)))
```

O `coalesce` é de propósito: rótulo faltando degrada para o nome em português,
em vez de virar `null` na tela.

### Metadados

```r
anos_meta <- base %>% distinct(ano, n_meses, ano_parcial)
list(
  year_inicio = min(anos_meta$ano),
  year_final  = max(anos_meta$ano),
  year_final_completo = max(anos_meta$ano[!anos_meta$ano_parcial]),
  anos_parciais = setNames(as.list(parciais$n_meses), as.character(parciais$ano))
)
```

Nada de anualizar ou extrapolar aqui. Sinalize, e deixe quem lê decidir.

---

## 3. Como acrescentar uma dimensão nova

Receita real, do dia em que país entrou. Levou um commit.

1. **No export**, gere os três arquivos da dimensão, com a mesma forma dos que
   já existem: composição regional, cruzamento esparso e rótulos.
2. **Nomeie os campos do JSON pelo que eles são** (`pais`, `paises`), e remapeie
   para o nome genérico interno no carregamento. Duas linhas ali evitam um ramo
   paralelo em cada função de render.
3. **No app**, faça os pontos de despacho conhecerem o nível novo. No COMEX
   eram três: qual índice usar, quais linhas brutas usar, qual dicionário usar.
4. **Carregue sob demanda.** A dimensão nova não deve custar nada a quem não a
   abre.

O que torna isso barato é a forma ser a mesma. Se a dimensão nova precisar de
um formato próprio, provavelmente o recorte está errado.

---

## 4. Armadilhas que custaram tempo

**Acento em chave.** Já descrito em 1d. Qualquer fonte "normalizada" de nomes
vai te dar ASCII e quebrar links salvos silenciosamente.

**Zero explícito vs ausência.** O formato largo preenchia zero em toda célula
vazia; a base longa simplesmente não tem a linha. Isso cortou
`municipality_totals.json` de 741 KB para 390 KB *já incluindo um ano novo*.
Só é seguro porque o app trata ausência como zero (`.get(ano) || 0`) em todo
caminho. **Confira isso antes de omitir.**

**Ano parcial.** Já descrito em 1e. O sintoma é uma queda no último ponto de
todo gráfico.

**Truncagem na fonte.** Dois dos 97 nomes de capítulo SH2 vêm cortados em
exatamente 255 caracteres, do `NCM_SH.csv` do MDIC. Não é nosso e não tem
conserto do nosso lado — mas vale saber antes de alguém passar uma tarde
procurando o bug no export.

**Rótulos mudam quando a fonte muda.** Ao trocar os CSVs à mão pelos nomes
oficiais, 91 dos 97 rótulos em inglês mudaram. Foram melhorias, mas vale
conferir um punhado antes de publicar.

---

## 5. Checklist

Antes de pedir a base:

- [ ] Uma linha por combinação, no grão mais fino que alguma tela usa
- [ ] Uma coluna por medida
- [ ] Rótulo pt/en de **toda** dimensão que vira texto na tela
- [ ] Metadado de completude, se a série pode terminar incompleta
- [ ] Chaves estáveis entre atualizações

Antes de publicar os JSON:

- [ ] Reconcilia com o que está no ar? (compare valor a valor nos anos comuns)
- [ ] As chaves antigas continuam idênticas?
- [ ] Carga inicial continua pequena? O que é novo entrou como sob demanda?
- [ ] Abriu o app e clicou em todas as telas?

A reconciliação é a mais importante e a mais fácil de pular. Na migração do
COMEX ela confirmou 6.267 totais município × ano e 70.251 células do ranking
SH4 **idênticos** ao que estava publicado — o que transformou "acho que está
certo" em "está certo", antes de qualquer deploy.
