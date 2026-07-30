# Troubleshooting — datazoom_viz

Problemas não óbvios encontrados durante migrações/deploys reais, com a causa raiz e o que de fato resolveu. Não é uma lista exaustiva — só o que já mordeu alguém e vale não redescobrir do zero.

---

## Tooltips presos abertos no hover do mapa (Leaflet)

**Sintoma:** em mapas coropléticos (`leaflet::addPolygons()`), mover o mouse rápido por vários municípios vizinhos deixa múltiplos tooltips abertos ao mesmo tempo, em vez de só o do polígono atual.

**Causa:** os municípios são polígonos adjacentes sem espaçamento (`stroke = FALSE`). O Leaflet não garante "só um tooltip aberto por vez" sozinho — um `mouseover` no próximo polígono pode disparar antes do `mouseout` do anterior terminar de processar.

> **O que NÃO funcionou:** reimplementar a detecção de hover via eventos `tooltipopen`/`tooltipclose` no nível do mapa (fechando à força qualquer tooltip que não seja o recém-aberto) parecia mais "correto" por seguir a API pública do Leaflet, mas quebrou o hover de formas diferentes em cada tentativa — de "nenhum tooltip abre" a "só abre com clique". Evite esse caminho.

**O que funcionou:** rastrear o último layer com tooltip aberto numa variável simples, fechando explicitamente só o *anterior* quando um novo abre — e deixar o Leaflet cuidar do fechamento nativo no `mouseout` de cada camada (não reimplementar isso também). Trecho de `scripts/map_mapbiomas_cover/server.R`:

```r
fig_p <- fig_p %>%
  htmlwidgets::onRender("
    function(el, x) {
      var map = this;
      var openLayer = null;
      map.eachLayer(function(layer) {
        if (layer.getTooltip && layer.getTooltip()) {
          layer.on('mouseover', function(e) {
            if (openLayer && openLayer !== layer) {
              openLayer.closeTooltip();
            }
            openLayer = layer;
          });
          layer.on('mouseout', function(e) {
            if (openLayer === layer) {
              openLayer = null;
            }
          });
        }
      });
    }
  ")
```

> **Limitação aceita:** se o usuário sai da janela do navegador sem que o `mouseout` dispare (ex: clica em outro monitor), o último tooltip pode ficar visível até o próximo hover. Edge case raro — não vale o risco de regressão no hover normal para cobrir isso.

---

## Município parece ter cor diferente em lugares diferentes (mesmo valor)

**Sintoma:** municípios com o mesmo valor — inclusive `NA`, que `colorBin()` sempre pinta com a mesma cor fixa — aparecem visualmente com cores diferentes dependendo de onde estão no mapa.

**Causa:** `fillOpacity` semitransparente (`< 1`) deixa o basemap por trás mostrar através e se misturar com a cor do preenchimento. Como o basemap não é uniforme (sombreamento de relevo, estradas, terra vs água em tons diferentes), a mesma cor nominal se mistura de um jeito diferente dependendo do que está por baixo — parece uma cor diferente, mas é a mesma cor sendo blendada com fundos diferentes.

**Caminhos tentados, cada um com trade-off:**

- `fillOpacity = 1` pra todo mundo: resolve a mistura, mas deixa o mapa inteiro saturado/alto contraste, e "lava" outros elementos desenhados por cima — linhas de fronteira de estado/Amazônia Legal (`addPolylines()`) usam por padrão a `opacity = 0.5` do próprio Leaflet quando não especificada, e ficam perceptivelmente mais fracas contra um preenchimento totalmente opaco. Se for esse o caminho, ajustar a opacity das linhas junto.
- `fillOpacity` condicional (`NA` = 1, resto = 0.7 via `ifelse(is.na(...), 1, 0.7)`): resolve a mistura só pro `NA` sem saturar o resto do mapa, mas é mais lógica pra manter.
- Trocar o basemap por algo mais "neutro" (`CartoDB.Positron`, `Esri.WorldGrayCanvas`, sem basemap nenhum via `addTiles()`/nada, ou um layer GeoJSON de países com cor sólida própria via `sf::st_read()`): cada opção tem trade-off — sem basemap nenhum tira o contexto visual dos países vizinhos; um GeoJSON próprio dá controle total sobre as cores mas exige baixar e manter um dataset extra fora do pipeline normal de `data-raw/`.

> **Fix final adotado:** `fillOpacity` fixo (não condicional) combinado com um basemap mais neutro (`CartoDB.PositronNoLabels`, sem custar um dataset extra). Não elimina 100% a variação de mistura, mas reduz bastante sem a complexidade de manter lógica condicional ou um layer de países à parte. Se precisar eliminar completamente, o caminho é a versão condicional (`NA` opaco, resto semitransparente) ou o GeoJSON próprio — ambos já testados e funcionais, só descartados aqui por serem mais código pra manter em troca de um ganho marginal.

---

## Espaços em branco entre municípios vizinhos no shapefile (over-simplificação)

**Sintoma:** o shapefile de municípios (`global/munic_shapefile.rds`) tem espaços em branco visíveis entre municípios vizinhos que deveriam compartilhar a mesma fronteira — parece um erro de projeção/CRS, mas não é.

**Causa:** simplificar geometria de polígonos adjacentes com uma função que não é "topology-aware" (não sabe que dois polígonos compartilham uma fronteira) simplifica cada lado da fronteira de forma independente. Cada lado acaba descartando pontos diferentes ao longo da mesma linha nominal, criando frestas/sobreposições onde antes havia uma fronteira compartilhada exata. `sf::st_simplify()` sozinho tem esse problema; `rmapshaper::ms_simplify()` é topology-aware e preserva fronteiras compartilhadas — mas só se for a única simplificação aplicada, ou a última antes de qualquer coisa que dependa da topologia.

**Fix:** em `data-raw/mapbiomas_cobertura_map.R`, a geração do shapefile já usa só `rmapshaper::ms_simplify()` (sem `sf::st_simplify()` antes):

```r
shapefile <- datazoom.amazonia:::external_download("geo_municipalities", source = "internal") |>
    left_join(datazoom.amazonia::municipalities, by = "code_muni") |>
    select(municipality_code = code_muni, geom, legal_amazon) |>
    st_make_valid() |>
    rmapshaper::ms_simplify()
```

> **Se ainda estiver "grosso demais" (poucos detalhes) ou pesado demais (arquivo grande):** `ms_simplify()` aceita um parâmetro `keep` (fração de pontos a manter, default `0.05` = mantém só 5%). Aumentar esse valor (ex: `rmapshaper::ms_simplify(keep = 0.15)`) dá mais detalhe às custas de um arquivo maior — não mexer em `st_simplify()`/simplificação por fora do `rmapshaper`, é isso que reintroduz as frestas.

---

## Paths antigos em scripts de `data-raw/`

**Sintoma:** rodar um script de `data-raw/*.R` e receber erro de "path not found"/arquivo não encontrado, mesmo com o arquivo existindo no repositório.

**Causa:** a reorganização de pastas de abril/2026 (commit `f657434`, "Nova organização...") moveu tudo para `apps/`, `scripts/`, `global/` e `data/` na raiz do repo. Vários scripts de `data-raw/` são anteriores a essa migração e ainda referenciam a estrutura antiga por app (`app_<nome>/global/...`, `app_<nome>/dic.csv`, etc.), que não existe mais.

**Fix:** antes de investigar como um bug de lógica, `grep` o script pelo nome da pasta antiga do próprio app (`app_<nome>`) — já apareceu em mais de um arquivo não relacionado (no script que hoje é `data-raw/mapbiomas_cobertura_map.R` e no script do app `mapbiomas8_cover_pasture`), então é bem provável que existam outros por aí ainda não descobertos.

---

## testServer() não popula inputs reativos que dependem de init via URL/materialSwitch

**Sintoma:** o app funciona perfeitamente no navegador, mas testar via `shiny::testServer()` mostra `input$x` vazio mesmo depois de `session$flushReact()`, ou erro "argumento tem comprimento zero" ao checar `if (input$algum_materialSwitch)`.

**Causa:** `testServer()` não roda o fluxo real de inicialização do navegador — `observeEvent(session$clientData$url_search, ...)` que dispara `random_inputs()` no carregamento normal não popula sozinho no harness de teste, e inputs vindos de `materialSwitch`/`actionButton` (renderizados via `renderUI`) ficam `NULL` até serem setados explicitamente. Confirmado reproduzindo o mesmo comportamento no app `ts_mapbiomas_cobertura` já em produção — não é bug do app sendo testado, é limitação do harness.

**Fix:** sempre setar manualmente todos os inputs relevantes, incluindo toggles, antes de `session$flushReact()`:

```r
testServer(app, {
  session$setInputs(x = "Forest", yprop = TRUE, geo_munic = 1)
  session$flushReact()
  ...
})
```

Para inspecionar o conteúdo real de um gráfico Plotly renderizado (tipo de trace, texto do tooltip) sem precisar de navegador:

```r
j <- jsonlite::fromJSON(output$plot, simplifyVector = FALSE)
j$x$data[[1]]$type   # ex: "bar", "scatter"
j$x$data[[1]]$text   # tooltips renderizados
```

---

## format(x, digits=2) arredonda por algarismos significativos, não casas decimais

**Sintoma:** valores no tooltip aparecem truncados de forma estranha — `94.18136` vira `"94"`, `460.004` vira `"460"` — mesmo o código "parecendo" pedir 2 casas decimais.

**Causa:** em `format()`, o argumento `digits` controla algarismos SIGNIFICATIVOS, não casas decimais. Para um número com 2+ dígitos inteiros, `digits = 2` corta toda a parte decimal.

**Fix:** usar `round(x, 2)` antes de `format()`, e envolver com `trimws()` (`format()` alinha por largura de vetor, deixando espaço em branco à esquerda em números menores):

```r
trimws(format(round(x, 2), scientific = FALSE, decimal.mark = ",", big.mark = "."))
```

Já apareceu em três apps (`rk_mapbiomas_cobertura`, `map_mapbiomas_cover`, `ts_mapbiomas_cobertura`), todos copiados do mesmo padrão antigo — bem provável que exista em outros ainda não revisados.

---

## Logo do datazoom some em sidebars com mais conteúdo

**Sintoma:** o logo do datazoom (mostrado via CSS em todo `.menucol`) não aparece em apps com sidebar mais cheia (ex: `map_mapbiomas_cover`, que tem botão de lang toggle + `materialSwitch` + slider a mais que apps antigos), mesmo com a classe `menucol` presente e idêntica à de apps onde o logo aparece normalmente.

**Causa:** o logo é um `::after` em `.menucol` (`global/dza_lumen.css`). A versão antiga usava `position: absolute; bottom: 20px;` — ou seja, 20px a partir do fundo da **própria caixa** de `.menucol`, não do viewport. `.menucol` só tinha `min-height` (sem teto), então a caixa cresce conforme o conteúdo da sidebar; apps com sidebar mais cheia ficam com uma caixa mais alta, e o logo, ainda a 20px do fundo *dessa caixa maior*, acaba bem abaixo da dobra inicial da tela. Não é `overflow: hidden` escondendo o logo (confirmado que não existe em nenhum ancestral) — a página rola normalmente, só que o logo fica "escondido" mais para baixo do que o usuário costuma rolar.

> **O que NÃO funcionou:** trocar `position: absolute` por `position: sticky` no `::after` (a ideia era grudar o logo a 20px do fundo do *viewport*, em vez de uma caixa de altura variável). Não funcionou nesse caso específico — o logo simplesmente sumiu por completo, provavelmente porque `.menucol` é ele mesmo um item flex (filho de `.row`, que é `display: flex` no Bootstrap), e `position: sticky` num pseudo-elemento descendente de um item flex é uma combinação frágil que pode falhar em estabelecer um contexto de scroll válido.

**Fix:** transformar `.menucol` num container flex em coluna e ancorar o logo no fundo via `margin-top: auto` — o padrão robusto para "sempre no fundo de um container de altura variável", sem depender de sticky:

```css
.menucol {
  background-color: #43868c;
  padding: 20px;
  border-radius: 10px;
  position: relative;
  min-height: calc(100vh - 40px);
  display: flex;
  flex-direction: column;
}
.menucol::after {
  content: "";
  margin-top: auto;
  height: 100px;
  background-image: url("img/logo_datazoom_branco_horizontal.png");
  background-repeat: no-repeat;
  background-position: center bottom;
  background-size: contain;
  pointer-events: none;
  opacity: 0.95;
}
```

O `padding-bottom: 160px` (reserva fixa de espaço da versão antiga) não é mais necessário — o flex já reserva exatamente a altura do logo, não importa quanto conteúdo tenha acima.

> **Efeito colateral desse fix — `hr()` sumindo:** virar `.menucol` num flex container quebrou os `hr()` da sidebar (usados como divisor entre a descrição e "VARIÁVEIS:"). É um gotcha clássico de flexbox: um `<hr>` sem conteúdo, dentro de um `flex-direction: column`, pode colapsar pra ~0px de altura (o Bootstrap já define `hr { height: 0; }` — a linha visível normalmente vem só da borda — e como item flex isso interage mal com o sizing automático). A correção ficou toda em `.menucol>hr`, precisou de três ajustes em sequência pra chegar no resultado certo:
>
> 1. `flex-shrink: 0` sozinho não resolveu — a base já era `0` (do `height:0` do Bootstrap), então não havia o que "não encolher".
> 2. `width: 100%; height: 1px;` explícitos trouxeram a linha de volta, mas com bordas (`border: 1px solid`) criando um efeito de moldura clara por fora e vazio por dentro (a borda é uma faixa separada da área de conteúdo — mesmo com a mesma cor, renderiza como dois tons).
> 3. Fix final: trocar `border` por `background-color` preenchendo a área toda, com `border: none`:
>
> ```css
> .menucol>hr {
>   border: none;
>   background-color: rgba(255, 255, 255, 0.38);
>   margin-top: 35px;
>   margin-bottom: 35px;
>   flex-shrink: 0;
>   width: 100%;
>   height: 2px;
> }
> ```
>
> Moral da história: qualquer mudança em `.menucol` (classe usada por praticamente todo app do repo) vale testar em pelo menos um app com sidebar cheia (`map_mapbiomas_cover`) e um com `hr()` na sidebar (`ts_mapbiomas_cobertura`) antes de considerar resolvido — o efeito colateral em elementos "vazios" (hr, spacers) é fácil de não perceber testando só um app.

---

## Logo (e qualquer coisa em `apps/www/`) funciona local, some no deploy

**Sintoma:** o logo do datazoom (ou qualquer imagem/asset servido de `apps/www/`) aparece normalmente rodando o app localmente, mas some sem erro nenhum depois do deploy no shinyapps.io.

**Causa:** bug em `deploy_shiny_script.R`. A função tinha `extra = c("global", "apps/www")`, e `copy_one()` sempre espelha o path de origem no destino do staging — `apps/www/img/logo.png` virava `td/apps/www/img/logo.png` no bundle deployado. O problema é que o Shiny só serve assets estáticos automaticamente de uma pasta chamada **`www`** que fica **ao lado do `app.R`** — e como `app.R` no bundle é uma cópia achatada do `apps/app_<id>.R` (sem mais o prefixo `apps/`), a pasta de assets também precisa ficar achatada em `www/`, não `apps/www/`.

Funciona localmente porque, ao rodar `apps/app_<id>.R` direto, o Shiny trata `apps/` como raiz do app — `apps/www/` já cai exatamente onde o Shiny espera `www/`. O bug só existe no bundle deployado, onde a estrutura de pastas é achatada.

> **Pista de que já era um bug conhecido e não corrigido:** o próprio `deploy_shiny_script.R` já reescrevia qualquer referência a `"../www/..."` no código do app para `"www/..."` (`gsub` na linha que monta o `app.R` final) — ou seja, o script já *assumia* que o destino certo era `td/www/`, só a cópia de fato não fazia isso.

**Fix:** tirar `"apps/www"` da lista genérica `extra` (que sempre espelha path) e copiar separadamente para `www/` na raiz do staging, remapeando o destino:

```r
extra = c("global"),  # apps/www não entra mais aqui
...
if (dir.exists("apps/www")) {
    www_dest <- file.path(td, "www")
    dir.create(www_dest, recursive = TRUE, showWarnings = FALSE)
    www_inner <- list.files("apps/www", full.names = TRUE)
    file.copy(www_inner, www_dest, recursive = TRUE, overwrite = TRUE)
}
```

Afeta qualquer app que use algo de `apps/www/`, não só o logo — vale reconferir depois de um deploy se alguma imagem/asset estático sumiu sem motivo aparente.

---
