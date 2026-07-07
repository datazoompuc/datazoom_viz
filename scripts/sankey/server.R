# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# Funcão para retornar objeto server
get_server <- function(files, param) {
  server <- function(input, output, session) {

    # Carrega dados
    df <- readRDS(files$db_file)
    
    # Tradução dos nomes de país PT -> EN via lookup do auxiliar_cod_pais.rds
    # (mesma fonte que gerou o dataset: MDIC, colunas NO_PT/NO_EN). Substitui o
    # antigo case_when hardcoded de ~200 países.
    aux_pais <- readRDS(files$aux_pais_file)
    map_pais_en <- setNames(aux_pais$NO_EN, aux_pais$NO_PT)
    traduz_pais_df <- function(df) {
      en <- map_pais_en[df$group]
      df$group <- ifelse(is.na(en), df$group, unname(en))
      df
    }

    # ---------------------------- Lang toggle ----------------------------
    lang <- reactiveVal("pt")
    observeEvent(input$toggle_lang, {
      lang(ifelse(lang() == "pt", "en", "pt"))
    })
    i18n <- reactive({ param$i18n[[lang()]] })

    # rótulo (label) da categoria selecionada no idioma atual
    y_label <- reactive({
      tbl <- param$tables[[lang()]]
      lab <- tbl$label[tbl$var == input$y]
      if (length(lab)) lab[1] else input$y
    })

    # Textos dinâmicos da sidebar
    output$plot_desc      <- renderText({ i18n()$plot_desc })
    output$label_var_name <- renderText({ i18n()$label_var_name })

    # Atualiza choices/labels/botões quando o idioma muda
    observeEvent(lang(), {
      ii  <- i18n()
      tbl <- param$tables[[lang()]]
      cats <- tbl[tbl$y == TRUE, ]
      updateSelectInput(
        session, "y",
        label    = ii$label_colour_name,
        choices  = setNames(cats$var, cats$label),
        selected = isolate(input$y)
      )
      updateActionButton(session, "toggle_lang", label = ii$btn_lang)
      updateActionButton(session, "ab1",         label = ii$btn_fullscreen)
    }, ignoreInit = FALSE)


    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      updateSelectInput(session, "y", selected = param$y_def)
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0("?", "y=", input$y)

      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      # idioma via ?lang=en
      if (!is.null(query[["lang"]]) && query[["lang"]] == "en") lang("en")

      if (!is.null(query[["y"]])) {
        # só o valor selecionado; as choices são geridas pelo observer de idioma
        updateSelectInput(session, "y", selected = query[["y"]])
      } else {
        random_inputs() # preenche inputs se estiverem vazios
      }
    }

    # Output titulo do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$y) || input$y == "") {
        text <- " "
      } else {
        # título = rótulo da categoria no idioma atual
        text <- y_label()
      }

      text
    })
    output$plot_subtitle <- renderText({
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$y) || input$y == "") {
        text <- " "
      } else {
        text <- paste0("")
      }

      text
    })

    # Output gráfico
    output$plot <- renderPlotly({
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco
      tryCatch(
        {
          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(input$y) || input$y == "") {
            fig <- plotly_empty()
            stop()
          }

          lg <- lang()
          y_col <- param$table[which(param$table$var == input$y), ]  # var em PT (= coluna do df)
          pallete <- pallete_discrete
          anos <- sort(unique(df$time))

          # Monta o data.frame (país + valor) de um ano, ordenado por valor
          build_dp <- function(yr) {
            dff <- df[which(df$time == yr), ]
            dp <- data.frame(
              y = dff[[y_col$var]],
              group = dff$group,
              stringsAsFactors = FALSE
            )
            dp <- dp[which(!is.na(dp$y)), ]
            dp <- dp[order(-dp$y), ]
            if (lg == "en") dp <- traduz_pais_df(dp)  # traduz nomes de país
            # agrega tudo abaixo do top 10 num único nó "Outros" (evita poluição)
            if (nrow(dp) > 10) {
              outros_lab <- if (lg == "en") "Others" else "Outros"
              resto <- data.frame(
                y = sum(dp$y[-(1:10)], na.rm = TRUE),
                group = outros_lab,
                stringsAsFactors = FALSE
              )
              dp <- rbind(dp[1:10, ], resto)
            }
            dp
          }

          # Constrói os nós/links do sankey para um data.frame de um ano.
          # Posições fixas: empilha os alvos na ORDEM do dp (top 10 desc, "Outros"
          # por último = sempre embaixo), independentemente do valor.
          build_nodes_links <- function(dp) {
            n <- nrow(dp)
            cores <- c(pallete[4], rep(pallete[3], 5), rep(pallete[2], 5),
                       rep(pallete[1], max(0, n - 10)))
            cores <- cores[1:(n + 1)]
            # centro vertical de cada alvo = fração acumulada do valor (empilhamento)
            frac    <- dp$y / sum(dp$y)
            tops    <- cumsum(c(0, head(frac, -1)))
            centros <- tops + frac / 2
            centros <- pmin(pmax(centros, 1e-3), 1 - 1e-3)
            list(
              node = list(
                label = c("Amazônia", dp$group),
                color = cores,
                hovertemplate = "<b> %{label} </b>",
                pad = 15, thickness = 10,
                line = list(color = "black", width = 0.5),
                x = c(0.01, rep(0.9, n)),   # fonte à esquerda, alvos à direita
                y = c(0.5, centros)
              ),
              link = list(
                source = rep(0, n),
                target = 1:n,
                value = dp$y / 1e6,
                hoverinfo = "none"
              )
            )
          }

          # Frame inicial = último ano
          dp0 <- build_dp(anos[length(anos)])
          if (nrow(dp0) < 1) {
            fig <- plotly_empty()
            stop()
          }
          nl0 <- build_nodes_links(dp0)

          fig_p <- plot_ly(
            type = "sankey",
            orientation = "h",
            arrangement = "fixed",   # respeita as posições y (mantém "Outros" embaixo)
            valueformat = ".2f",
            valuesuffix = paste0(" (", i18n()$unit, y_col$unidade, ") "),
            hoverlabel = list(namelength = -1),
            node = nl0$node,
            link = nl0$link
          )

          # Um frame por ano (o plotly redesenha o sankey a cada frame)
          fig_p$x$frames <- lapply(anos, function(yr) {
            nl <- build_nodes_links(build_dp(yr))
            list(
              name = as.character(yr),
              data = list(list(node = nl$node, link = nl$link))
            )
          })

          # Passos do slider (um por ano)
          steps <- lapply(anos, function(yr) {
            list(
              method = "animate",
              label = as.character(yr),
              args = list(
                list(as.character(yr)),
                list(mode = "immediate",
                     frame = list(duration = 10, redraw = TRUE),
                     transition = list(duration = 0))
              )
            )
          })

          # Layout + slider + botões de play/pause nativos do plotly
          fig_p <- fig_p %>%
            layout(
              font = f1,
              margin = list(b = 80),
              sliders = list(list(
                active = length(anos) - 1,
                x = 0.05, len = 0.9, pad = list(t = 30),
                currentvalue = list(prefix = paste0(i18n()$label_x_name, ": "), font = f1),
                steps = steps
              )),
              updatemenus = list(list(
                type = "buttons", direction = "left", showactive = FALSE,
                x = 0.05, y = -0.02, xanchor = "right", yanchor = "top",
                pad = list(t = 30, r = 10),
                buttons = list(
                  list(method = "animate", label = "▶",
                       args = list(NA, list(mode = "immediate", fromcurrent = FALSE,
                                            frame = list(duration = 3000, redraw = TRUE),
                                            transition = list(duration = 0)))),
                  list(method = "animate", label = "⏸",
                       args = list(list(), list(mode = "immediate",
                                            frame = list(duration = 0, redraw = FALSE),
                                            transition = list(duration = 0))))
                )
              ))
            )

          fig_p <- fig_p %>%
            config(
              displaylogo = FALSE,
              modeBarButtonsToRemove = c(
                "lasso2d",
                "select2d",
                "hoverCompareCartesian"
              )
            )

          fig <- fig_p # retorna a figura do gráfico
        },
        error = function(cond) {
          # se encontrar erro retorna fig em branco
          print("plot error")
          fig <- plotly_empty()
        }
      )
      fig
    })

    # Observa eventos
    observe({
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)
      update_my_inputs()
    })
  }

  # Retorna objeto server
  server
}
