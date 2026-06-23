---
name: datazoom_viz
description: >
  Conhecimento completo do repositório datazoom_viz (Data Zoom Amazônia).
  Use esta skill SEMPRE que o usuário mencionar a pasta datazoom_viz, qualquer
  arquivo de app Shiny do repositório, scripts em apps/ ou scripts/, arquivos
  em data/ ou data-raw/, workflows de GitHub Actions do repositório, ou qualquer
  tarefa relacionada aos apps do site datazoom.com.br/amazonia. Também use quando
  o usuário pedir para criar, editar, refatorar ou entender qualquer componente
  desse repositório — mesmo que não cite o nome explicitamente.
---

# datazoom_viz — Conhecimento do Repositório

> ⚠️ **Ajuste o caminho do repositório:** substitua `<CAMINHO_LOCAL_DO_REPOSITORIO>` pelo local onde o `datazoom_viz` está clonado na sua máquina (ex.: `C:\Users\seu_usuario\...\datazoom_viz` ou `~/datazoom_viz`).

Repositório: `<CAMINHO_LOCAL_DO_REPOSITORIO>`  
Site: https://datazoom.com.br/amazonia

---

## Estrutura de Diretórios

```
datazoom_viz/
├── apps/
│   └── app_<app_id>.R         # entry-point: carrega libs, define paths, roda shinyApp()
├── scripts/
│   └── <app_id>/
│       ├── ui.R               # interface do usuário
│       ├── server.R           # lógica do servidor
│       └── db_params.R        # carregamento de dados e parâmetros
├── data/
│   ├── <dataset_id>.rds       # datasets processados
│   └── <dataset_id>_dic.csv   # dicionários de variáveis
├── data-raw/
│   └── <script>.R             # scripts que constroem os datasets em data/
├── config/
│   ├── app_manifest.csv       # dependências por app (auto-gerado — não editar)
│   └── dataset_registry.csv   # mapeamento dataset → script (auto-gerado — não editar)
├── global/
│   └── dza_lumen.css          # stylesheet compartilhado
└── .github/
    └── workflows/             # GitHub Actions
```

### Convenção de nomes de app

Prefixo indica o tipo de gráfico:

| Prefixo | Tipo |
|---|---|
| `app_ts_` | gráfico de linha (time series) |
| `app_bar_` | gráfico de barras |
| `app_bubble_` | scatter plot |
| `app_hist_` | histograma |
| `app_map_` / `app_mapstatic_` | mapa |
| `app_rk_` / `app_rkstatic_` | ranking |
| `app_sankey_` | sankey |
| `app_tab_` | tabela |

---

## Fluxo de um App Shiny

Cada app segue este fluxo de três camadas:

1. **`apps/app_<id>.R`** — entry-point
   - Carrega bibliotecas
   - Define `files$param_file_pt/en`, `files$db_file`, etc.
   - Monta `param` com `get_db_param()`, `param$i18n`, `param$tables`
   - Chama `source()` nos scripts de `scripts/<id>/`
   - Executa `shinyApp(ui, server)`

2. **`scripts/<id>/ui.R`** — interface
   - Define layout, sidebar, inputs, outputs
   - Usa `materialSwitch` para inputs binários
   - Usa `withSpinner` para envolver o plot
   - Inclui botão `toggle_lang` e botão de fullscreen

3. **`scripts/<id>/server.R`** — lógica
   - Contém `get_server(files, param)` que retorna `function(input, output, session)`
   - Inclui lógica de lang toggle (ver seção abaixo)
   - Renderiza plots, tabelas e outputs reativos

---

## Padrão Atual de UI (obrigatório em novos apps e migrações)

Os três componentes abaixo são o padrão atual. Apps de referência já implementados: `ts_rais`, `ts_comex_exp_tot_pais`, `ts_energia_sistemas_isolados`.

Para detalhes completos de implementação, leia: `tutorial_novo_ui.md`

### 1. `materialSwitch` (pacote `shinyWidgets`)
- Substitui `checkboxInput` em qualquer input com **dois estados**
- Label deve ser `tags$span(..., class = "switch-label")` com CSS `.switch-label { color: white; }`
- `status = "info"`, envolvido em `div(style = "margin-top: 10px;")`
- **No server, nada muda** — retorna `TRUE/FALSE` igual ao checkbox

### 2. `withSpinner` (pacote `shinycssloaders`)
- Envolve o `plotlyOutput` no ui.R
- `type = 4`, `color = "#41878C"`
- O `div` do plot deve ter `display: flex; flex-direction: column;`
- Height do plot: `"calc(100vh - 150px)"` (não `"100%"`)

### 3. Lang Toggle (botão PT/EN sem reload)

**Arquitetura:**
- Um único arquivo de app (sem versão `_en`)
- `param$i18n` contém todos os textos em PT e EN
- `param$tables` contém `list(pt = ..., en = ...)` com as choices traduzidas
- `reactiveVal("pt")` controla o idioma ativo no server

**No `apps/app_<id>.R`:**
```r
param_pt <- get_db_param(files$param_file_pt, files$db_file)
param_en <- get_db_param(files$param_file_en, files$db_file)
param        <- param_pt
param$tables <- list(pt = param_pt$table, en = param_en$table)
param$i18n   <- list(pt = list(...), en = list(...))
```

**No `server.R`:**
```r
lang  <- reactiveVal("pt")
observeEvent(input$toggle_lang, { lang(ifelse(lang() == "pt", "en", "pt")) })
i18n  <- reactive({ param$i18n[[lang()]] })
observeEvent(lang(), {
  updateSelectInput(session, "y", label = i18n()$label_y_name, ...)
  updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
}, ignoreInit = FALSE)
```

- `btn_lang` sempre mostra o **idioma de destino** ("English" quando em PT, "Português" quando em EN)
- `ignoreInit = FALSE` é obrigatório para popular os choices no carregamento inicial

---

## Config Files (auto-gerados — nunca editar manualmente)

### `config/app_manifest.csv`
Gerado por `scripts/generate_app_manifest.R` via GitHub Actions.  
Colunas: `app_id`, `language_mode`, `app_script`, `ui_script`, `server_script`, `param_script`, `css_file`, `dictionary_files`, `db_file`, `extra_files`.  
Usado por `deploy_shiny_script()` para resolver dependências no deploy.

### `config/dataset_registry.csv`
Gerado por `scripts/build_dataset_registry.R` via GitHub Actions.  
Colunas: `dataset_id`, `db_file`, `build_script`, `build_function`, `source_package`, `notes`.  
Mapeia cada dataset ao script que o constrói.

Ambos são atualizados automaticamente pelo workflow `.github/workflows/update-manifest-registry.yml`.

---

## Deploy

```r
source("scripts/deploy_shiny_script.R")
deploy_shiny_script("app_id")  # ex: deploy_shiny_script("ts_ibge_pnadc_cnae")
```

Para ver logs de erro:
```r
rsconnect::showLogs(appName = "app_app_id", account = "datazoom")
```

---

## GitHub Actions

### Workflow existente: check-pnadc-updates

`.github/workflows/check-pnadc-updates.yml` — roda toda segunda às 09:00 (horário de Brasília).

**Script:** `scripts/check_pnadc_updates.R`  
**Lógica:**
1. Lê `config/dataset_registry.csv` para identificar datasets PNADC (função `load_pnadc`)
2. Inspeciona cada `.rds` local para ver o último ano-trimestre disponível
3. Consulta o FTP do IBGE para ver o trimestre mais recente publicado
4. Compara e atribui status: `UP_TO_DATE`, `OUTDATED`, `RDS_MISSING`, `READ_ERROR`
5. Salva resultado em `reports/pnadc_update_status.csv` (também como artifact do Actions)
6. Se qualquer dataset estiver `OUTDATED`, envia notificação no Slack via webhook

### Workflows planejados: check de outros datasets

O padrão do PNADC deve ser replicado para outros datasets (COMEX, RAIS, etc.).  
Ao criar um novo workflow de checagem, seguir o mesmo padrão:
- Ler `dataset_registry.csv` filtrando pela `build_function` do dataset
- Comparar versão local vs. fonte remota
- Salvar relatório em `reports/<dataset>_update_status.csv`
- Notificar Slack se `OUTDATED`

---

## Migração em andamento: remoção dos apps `_en`

**Regra ativa:** Apps com sufixo `_en` são a abordagem **antiga** e devem ser eliminados.

**Estado atual:**
- Apps já migrados para lang toggle: `ts_rais`, `ts_comex_exp_tot_pais`, `ts_energia_sistemas_isolados`
- Demais apps com `_en` ainda não foram migrados

**Ao trabalhar em qualquer app:**
- Se o app já tem lang toggle → não há arquivo `_en`, está correto
- Se o app ainda tem `_en` separado → **não criar novos `_en`**; ao migrar, deletar o `_en` correspondente
- Nunca criar arquivo `app_<id>_en.R` novo sob nenhuma circunstância

**Para verificar o status de migração de um app**, consulte `language_mode` em `config/app_manifest.csv`:
- `"both"` → lang toggle implementado; arquivo `_en` separado pode ser deletado
- `"pt"` → ainda usa sistema antigo; arquivo `_en` correspondente ainda é necessário

**Ao concluir o lang toggle de um app, atualizar também o site datazoom.com.br/amazonia:**

O site é mantido em um repositório separado (Amazônia). O link EN de cada visualização fica em:
```
en/viz/<app_id>.md
```

Nesse arquivo, trocar o link do Shiny de:
```
https://datazoom.shinyapps.io/app_<app_id>_en/
```
para:
```
https://datazoom.shinyapps.io/app_<app_id>/?lang=en
```

Nunca atualizar o site sem antes confirmar que o lang toggle está deployado e funcionando.

---

## Datasets do repositório

### Dados Ambientais
- **PRODES** — desmatamento anual (INPE/TerraBrasilis), nível municipal
- **MapBiomas** — cobertura e uso do solo, 1989–presente
- **SEEG** — estimativas de emissão de GEE, 1970–2020

### Dados Sociais
- **IPS** — Índice de Progresso Social da Amazônia (IMAZON), 2014 e 2018
- **DATASUS** — mortalidade e leitos hospitalares
- **PNADC** — mercado de trabalho e características socioeconômicas (IBGE, trimestral)

### Dados Econômicos
- **COMEX** — comércio exterior brasileiro (Siscomex), mensal, desde 1989
- **RAIS** — mercado formal de trabalho, anual (Ministério do Trabalho)
- **CEMPRE** — empresas formais (IBGE), 2006–2019
- **PPM** — pecuária municipal, anual, desde 1974
- **SIGMINE** — mineração legal (ANM), municipal e estadual
- **ANEEL** — energia elétrica (geração distribuída), estadual
- **EPE** — consumo e produção de energia, estadual

---

## Planilha de Monitoramento (Google Sheets)

A planilha de monitoramento rastreia o status de UI e atualização de todos os apps. Está no Google Drive e deve ser consultada e atualizada via conector do Google Drive no Claude.

**Link:** https://docs.google.com/spreadsheets/d/1RqOPwqaO94Vxb1_Sfo8moB4tnXTqcIKHYk2YtjVpW2c/edit

**Regra obrigatória:** qualquer escrita na planilha requer aprovação explícita antes de executar. Sempre mostrar o que será alterado (app, coluna, valor antigo → novo) e aguardar confirmação.

### Estrutura da aba "Monitor de Apps"

Colunas por app:

| Coluna | Descrição |
|---|---|
| `Grupo` | Dataset ao qual o app pertence (PNADC, RAIS, ENERGIA, COMEX, etc.) |
| `App ID` | Identificador do app (sem prefixo `app_`) |
| `Idioma` | `PT`, `EN`, ou `BOTH` (BOTH = lang toggle implementado) |
| `materialSwitch` | ✅ / ❌ / ⚠️ Parcial / N/A |
| `withSpinner` | ✅ / ❌ / ⚠️ Parcial / N/A |
| `Labels (pt)` | ✅ / ❌ / ⚠️ Parcial / N/A — labels dinâmicos em PT implementados |
| `UI Completo` | ✅ Completo / ⚠️ Parcial / ❌ Pendente |
| `Lang Toggle` | ✅ / ❌ |
| `Dataset (.rds)` | Nome do arquivo `.rds` em `data/` |
| `Último deploy` | Data do último deploy (número serial Excel ou data) |
| `Periodicidade` | Frequência de atualização da fonte de dados |
| `Próxima Atualiz.` | Previsão da próxima atualização de dados |
| `Pode Excluir?` | 🗑 DEPRECADO / ⚠️ Pode excluir / vazio |
| `Observações` | Notas livres |

### Legenda de cores (referência visual)

- Verde claro — app totalmente atualizado (UI ✅ + Lang Toggle ✅)
- Vermelho claro — app DEPRECADO, a excluir
- Amarelo claro — app `_en` cujo par PT já tem lang toggle (pode excluir)
- Azul claro — app em inglês (`_en`) ainda ativo

### Quando consultar a planilha

- Ao perguntar sobre status de qualquer app
- Ao verificar quais apps ainda precisam de migração de UI
- Ao identificar apps `_en` que podem ser deletados
- Ao planejar próximas atualizações de dados

### Quando atualizar a planilha

Sempre que uma das seguintes mudanças for concluída:
- `materialSwitch` implementado em um app
- `withSpinner` adicionado
- Lang toggle implementado (atualizar também `Idioma` para `BOTH`)
- App `_en` deletado
- Deploy realizado (atualizar `Último deploy`)
- Dataset atualizado (atualizar `Próxima Atualiz.`)
