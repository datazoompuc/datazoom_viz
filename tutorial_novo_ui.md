# Tutorial: Novo UI dos Apps Shiny — Material Switch, Spinner e Lang Toggle

Este tutorial explica como implementar as três atualizações de UI que estão sendo padronizadas nos apps do Data Zoom Amazônia. Os exemplos de referência são os apps `ts_rais`, `ts_comex_exp_tot_pais` e `ts_energia_sistemas_isolados`, que já têm tudo implementado.

---

## Índice

1. [Substituir `selectInput`/`checkboxInput` por `materialSwitch`](#1-substituir-selectinput--checkboxinput-por-materialswitch)
2. [Adicionar spinner com `withSpinner`](#2-adicionar-spinner-com-withspinner)
3. [Criar o botão de lang toggle](#3-criar-o-botão-de-lang-toggle)

---

## 1. Substituir `checkboxInput` por `materialSwitch`

O `materialSwitch` é um toggle visual (on/off) do pacote **`shinyWidgets`**. Ele substitui checkboxes e selects binários (sim/não, log/linear, etc.) por um switch mais moderno e legível no fundo verde do menu.

### Quando usar

Use `materialSwitch` sempre que o input tiver apenas **dois estados** — por exemplo:
- Escala logarítmica
- Proporcional ao ano inicial
- Deflacionar

Para inputs com múltiplas opções (ex: escolha de variável), continue usando `selectInput` ou `selectizeInput`.

### Visual: antes e depois

| Antes (checkboxInput) | Depois (materialSwitch) |
|---|---|
| ![Checkboxes antigos](docs/imgs/before_checkbox.png) | ![Material switches](docs/imgs/after_switch.png) |

### Passo a passo

**1. Adicionar o pacote no arquivo do app (ex: `app_ts_meuapp.R`)**

```r
library(shinyWidgets)
```

**2. Adicionar o CSS de cor do label no `ui.R`**

O label do switch precisa ficar branco para aparecer sobre o fundo verde do menu. Adicione esta linha **uma única vez** em qualquer lugar dentro do `div()` principal da UI:

```r
tags$style(HTML(".switch-label { color: white; }"))
```

**3. Substituir o input antigo pelo `materialSwitch`**

**Antes** (usando `checkboxInput`):
```r
checkboxInput(
    inputId = "ylog",
    label   = param$label_scale_name,
    value   = FALSE
)
```

**Depois** (usando `materialSwitch`):
```r
div(
    style = "margin-top: 10px;",
    materialSwitch(
        inputId = "ylog",
        label   = tags$span(param$label_scale_name, class = "switch-label"),
        value   = FALSE,
        status  = "info"
    )
)
```

> **O que mudou:**
> - O `label` agora é um `tags$span()` com a classe `switch-label` — isso aplica o CSS branco que adicionamos.
> - `status = "info"` define a cor do switch quando ativado (azul do Bootstrap). Não mude isso.
> - O `div(style = "margin-top: 10px;")` é para dar um respiro visual entre os switches.

**Exemplo real** — trecho do `scripts/ts_comex_exp_tot_pais/ui.R`:
```r
# CSS do label (adicionar uma vez)
tags$style(HTML(".switch-label { color: white; }")),

# Switch de escala log
div(
    style = "margin-top: 10px;",
    materialSwitch(
        inputId = "ylog",
        label   = tags$span(param$label_scale_name, class = "switch-label"),
        value   = FALSE,
        status  = "info"
    )
),

# Switch proporcional
div(
    style = "margin-top: 10px;",
    materialSwitch(
        inputId = "y_option",
        label   = tags$span(param$label_axis_name, class = "switch-label"),
        value   = FALSE,
        status  = "info"
    )
),
```

### No server — nada muda

O `materialSwitch` retorna `TRUE` ou `FALSE` igual ao `checkboxInput`. Todo código no `server.R` que usava `input$ylog` continua funcionando sem nenhuma alteração.

---

## 2. Adicionar spinner com `withSpinner`

O `withSpinner` exibe uma animação de carregamento enquanto o gráfico ainda está sendo renderizado. Ele vem do pacote **`shinycssloaders`**.

### Passo a passo

**1. Adicionar o pacote no arquivo do app**

```r
library(shinycssloaders)
```

**2. Ajustar o `div` do plot no `ui.R`**

O `withSpinner` envolve o output do gráfico. Mas para funcionar bem, o `div` que contém o plot precisa ter `display: flex` e `flex-direction: column`, e o `height` do gráfico precisa ser absoluto (em `vh`) em vez de `"100%"`.

**Antes:**
```r
div(
    class = "plotdiv w-100 h-100",
    plotlyOutput("plot", width = "100%", height = "100%")
)
```

**Depois:**
```r
div(
    class = "plotdiv w-100 h-100",
    style = "position: relative; display: flex; flex-direction: column;",
    div(
        style = "flex-grow: 1; position: relative;",
        withSpinner(
            plotlyOutput("plot", width = "100%", height = "calc(100vh - 150px)"),
            type  = 4,
            color = "#41878C"
        )
    )
)
```

> **O que mudou:**
> - O `div` externo ganha `display: flex; flex-direction: column;` para o layout funcionar.
> - Um `div` interno com `flex-grow: 1` garante que o spinner ocupe o espaço disponível.
> - O `height` do `plotlyOutput` muda de `"100%"` para `"calc(100vh - 150px)"` — isso é necessário porque o spinner precisa de uma altura definida para aparecer corretamente.
> - O estilo do spinner `type = 4` (círculo girando) e o verde-azulado `color = "#41878C"` são o padrão dos nossos apps.

---

## 3. Criar o botão de lang toggle

O lang toggle é um `actionButton` que alterna o idioma do app entre PT e EN **sem recarregar a página**. É a nova abordagem que substitui o sistema antigo de ter dois apps separados (`app_meuapp.R` e `app_meuapp_en.R`).

A lógica funciona assim:
1. O app tem **um único arquivo** (sem versão `_en`)
2. `param$i18n` guarda todos os textos em PT e EN (i18n é a abreviação padrão em desenvolvimento de software para "internationalization")
3. Um `reactiveVal("pt")` controla o idioma ativo
4. Quando o botão é clicado, o idioma muda e os textos atualizam

### Passo a passo

#### 3.1 — No arquivo do app (ex: `app_ts_meuapp.R`)

**Antes** (abordagem antiga com dois arquivos):
```r
param$lang <- FALSE  # ou TRUE no arquivo _en.R
files$param_file <- "../data/meu_app_dic.csv"
files$db_file       <- "../data/meuapp.rds"
...
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
```

**Depois** (nova abordagem com toggle):

Passe a chamar dois arquivos de dicionário (PT e EN) e monte o `param$i18n`:

```r
# SEM param$lang

files$param_file_pt <- "../data/meuapp_dic.csv"
files$param_file_en <- "../data/meuapp_dic_en.csv"
files$db_file       <- "../data/meuapp.rds"

param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)

param        <- param_pt           # PT como idioma padrão
param$tables <- list(
    pt = param_pt$table,
    en = param_en$table
)

# Todos os textos que aparecem na UI, em PT e EN:
param$i18n <- list(
    pt = list(
        plot_desc        = "Descrição do app em português",
        label_var_name   = "VARIÁVEIS:",
        label_y_name     = "Eixo vertical (y)",
        label_scale_name = "Escala log",
        label_prop_name  = "Proporcional ao ano inicial",
        btn_lang         = "English",     # label do botão quando app está em PT
        btn_fullscreen   = "Fullscreen"
    ),
    en = list(
        plot_desc        = "App description in English",
        label_var_name   = "VARIABLES:",
        label_y_name     = "Vertical axis (y)",
        label_scale_name = "Log scale",
        label_prop_name  = "Proportional to starting year",
        btn_lang         = "Português",   # label do botão quando app está em EN
        btn_fullscreen   = "Fullscreen"
    )
)
```

> **Dica:** O `btn_lang` sempre mostra o **idioma de destino**, não o atual. Quando o app está em PT, o botão mostra "English". Quando está em EN, mostra "Português".

#### 3.2 — No `ui.R`

Adicione o botão de lang toggle na sidebar, antes do botão de Fullscreen:

```r
# Botão de troca de idioma
actionButton(
    inputId = "toggle_lang",
    label   = "English",
    icon    = icon("globe"),
    class   = "btn-primary"
),

div(style = "height: 6px;"),   # espaço entre os botões

# Botão de fullscreen (já existente)
actionButton(
    inputId = "ab1",
    label   = "Fullscreen",
    icon    = icon("expand"),
    class   = "btn-primary",
    onclick = paste0("window.open('", param$link, "', '_blank')")
),
```

Os textos que mudam de idioma (título, descrição, labels) devem ser renderizados via `textOutput()` / `uiOutput()` em vez de valores fixos de `param`:

```r
# No lugar de:  h2(class = "plot_name", param$plot_name)
# Use:          uiOutput("plot_name_ui")

uiOutput("plot_name_ui"),
uiOutput("plot_desc_ui"),
hr(),
p(class = "vars", textOutput("label_var_name", inline = TRUE)),
```

O resultado final fica assim na sidebar:

![Botões Fullscreen e English](docs/imgs/lang_toggle_button.png)

#### 3.3 — No `server.R`

Adicione a lógica de lang **antes** dos outros outputs e observadores:

```r
get_server <- function(files, param) {
  function(input, output, session) {

    # --- LANG TOGGLE ---

    # Reativo que guarda o idioma atual ("pt" ou "en")
    lang <- reactiveVal("pt")

    # Troca o idioma quando o botão é clicado
    observeEvent(input$toggle_lang, {
        lang(ifelse(lang() == "pt", "en", "pt"))
    })

    # Atalho para os textos do idioma ativo
    i18n <- reactive({ param$i18n[[lang()]] })

    # Renderiza os textos dinâmicos da sidebar
    output$plot_name_ui  <- renderUI({ h2(class = "plot_name", param$plot_name) })
    output$plot_desc_ui  <- renderUI({ p(class = "plot_desc", i18n()$plot_desc) })
    output$label_var_name <- renderText({ i18n()$label_var_name })

    # Atualiza inputs e botões quando o idioma muda
    observeEvent(lang(), {

        # Atualiza as choices do selectInput com a tabela traduzida
        tbl <- param$tables[[lang()]]
        updateSelectInput(
            session,
            "y",
            label    = i18n()$label_y_name,
            choices  = setNames(tbl$var[tbl$y], tbl$label[tbl$y]),
            selected = isolate(input$y)
        )

        # Atualiza o label dos switches
        # (o texto do label é um textOutput, então atualiza automaticamente via i18n())

        # Atualiza o label dos botões
        updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
        updateActionButton(session, "ab1",         label = i18n()$btn_fullscreen)
    }, ignoreInit = FALSE)

    # --- RESTO DO SERVER (plots, filtros, etc.) ---
    # ... código existente continua aqui ...
  }
}
```

> **Detalhe importante:** `ignoreInit = FALSE` no `observeEvent(lang(), ...)` garante que os choices e labels sejam populados corretamente logo no carregamento inicial do app, mesmo sem o usuário clicar no botão.

#### 3.4 — Como o `materialSwitch` interage com o lang toggle

Quando o label do switch é um `textOutput`, ele atualiza automaticamente:

```r
# No ui.R — label dinâmico via textOutput
materialSwitch(
    inputId = "ylog",
    label   = tags$span(textOutput("label_scale_name", inline = TRUE), class = "switch-label"),
    value   = FALSE,
    status  = "info"
)

# No server.R — renderiza o texto do label
output$label_scale_name <- renderText({ i18n()$label_scale_name })
```

---

## Resumo: o que muda em cada arquivo

| Arquivo | O que fazer |
|---|---|
| `app_meuapp.R` | Adicionar `library(shinyWidgets)` e `library(shinycssloaders)`; montar `param$i18n` e `param$tables` |
| `app_meuapp_en.R` | **Deletar** (não é mais necessário) |
| `scripts/meuapp/ui.R` | Trocar `checkboxInput` por `materialSwitch`; envolver plot com `withSpinner`; adicionar botão `toggle_lang`; usar `textOutput`/`uiOutput` para textos dinâmicos |
| `scripts/meuapp/server.R` | Adicionar `reactiveVal`, `observeEvent(toggle_lang)`, `observeEvent(lang())` para atualizar inputs e botões |

