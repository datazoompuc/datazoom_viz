# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis
pallete_discrete <- sort(pallete_discrete)

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# Funcão para retornar objeto server
# `df` chega pronto do arquivo do app (carregado uma vez por processo)
get_server <- function(files, param, df) {

  # Monta o recorte pedido a partir das colunas neutras da base. Antes esses três
  # recortes vinham empilhados na coluna "uf" do .rds, triplicando o arquivo.
  filtra_grupo <- function(d, grupo) {
    if (grupo == "AMZ_IN") return(d[legal_amazon == TRUE])
    if (grupo == "AMZ_OUT") return(d[legal_amazon == FALSE])
    if (grupo %in% levels(d$regiao)) return(d[regiao == grupo])
    d[uf == grupo]
  }

  server <- function(input, output, session) {

    # --- LANG TOGGLE ---

    # Língua inicial (lida da URL)
    lang <- reactiveVal({
      query <- parseQueryString(isolate(session$clientData$url_search))
      if (identical(query[["lang"]], "en")) "en" else "pt"
    })

    # Alterna língua ao clicar no botão
    observeEvent(input$toggle_lang, {
      lang(ifelse(lang() == "pt", "en", "pt"))
    })

    # Atalho para os textos da língua ativa
    i18n <- reactive({ param$i18n[[lang()]] })

    # Rótulo de cada chave de recorte no idioma ativo (siglas de UF não mudam)
    geo_label <- function(keys) {
      lbl <- i18n()$geo_labels
      ifelse(keys %in% names(lbl), unname(lbl[keys]), keys)
    }

    # Escolhas agrupadas do selectize, com as chaves neutras como valor
    geo_choices <- reactive({
      k <- param$geo_keys
      setNames(
        list(
          setNames(k$amazonia, geo_label(k$amazonia)),
          setNames(k$regioes, geo_label(k$regioes)),
          setNames(k$estados, k$estados)
        ),
        c(i18n()$group_amazonia, i18n()$group_regioes, i18n()$group_estados)
      )
    })

    # Rótulo e unidade da variável saem do dicionário, como nos outros apps
    # (o param$i18n fica só com texto que é de UI mesmo)
    var_row <- reactive({
      tbl <- param$tables[[lang()]]
      tbl[which(tbl$var == param$x_def), ]
    })

    # Título do eixo x: a unidade do dicionário, embrulhada em Log() quando ligado
    x_title <- reactive({
      if (isTRUE(input$ylog)) sprintf(i18n()$fmt_log, var_row()$unidade) else var_row()$unidade
    })

    # Textos da sidebar que dependem do idioma
    # (o label do materialSwitch é um textOutput, então se traduz sozinho)
    output$plot_desc <- renderText({ i18n()$plot_desc })
    output$label_var_name <- renderText({ i18n()$label_var_name })
    output$label_scales <- renderText({ i18n()$label_scales })
    output$label_log_name <- renderText({ i18n()$label_log_name })

    # Atualiza escolhas e labels quando o idioma muda (as chaves selecionadas são
    # neutras, então a seleção do usuário sobrevive à troca)
    observeEvent(lang(), {
      updateSelectizeInput(session, "filter1",
                           label = i18n()$label_geo_name,
                           choices = geo_choices(),
                           selected = isolate(input$filter1))
      updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
      updateActionButton(session, "ab1", label = i18n()$btn_fullscreen)
      # ignoreInit = FALSE para o app já abrir traduzido quando a URL vem com ?lang=en
    }, ignoreInit = FALSE)

    # Funcão para preencher inputs com os recortes padrão
    random_inputs <- function() {
      updateSelectizeInput(session,
        "filter1",
        choices = geo_choices(),
        selected = param$geo_def
      )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "lang=", lang(),
        "&", "ylog=", isTRUE(input$ylog)
      )

      for (i in input$filter1) {
        q_string <- paste0(
          q_string,
          "&", "filter=", i
        )
      }
      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Preenche filtro vazio
      updateSelectizeInput(session,
        "filter1",
        choices = geo_choices(),
        selected = NULL
      )

      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
      if (!is.null(query[["filter"]])) {
        updateSelectizeInput(session,
                             "filter1",
                             choices = geo_choices(),
                             selected = selected
        )
      }

      if (!is.null(query[["ylog"]])) {
        updateMaterialSwitch(session, "ylog", value = query[["ylog"]] == "TRUE")
      }

      # Se query está vazia, preenche com os recortes padrão
      if (is.null(query[["filter"]])) {
        random_inputs()
      }
    }

    # Output titulo do gráfico
    output$plot_title <- renderText({

      # Se algum campo estiver vazio retorna só o nome da variável
      if (is.null(input$filter1)) {
        text <- var_row()$label
      } else {
        # Monta titulo a partir dos recortes selecionados nos inputs
        text <- paste0(var_row()$label, ": ",
                       paste(geo_label(input$filter1), collapse = ", "))
      }

      text
    })
    output$plot_subtitle <- renderText({

      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$filter1)) {
        text <- " "
      } else {
        text <- i18n()$subtitle
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
          if (is.null(input$filter1) || length(input$filter1) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Monta uma série por recorte selecionado, com o ano como frame
          df_p <- rbindlist(lapply(input$filter1, function(k) {
            d <- filtra_grupo(df, k)
            d <- d[!is.na(get(param$x_def))]
            if (!nrow(d)) return(NULL)
            data.table(y = d[[param$x_def]],
                       slider = d[[param$slider_def]],
                       group = geo_label(k))
          }))

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          ### Aplicando log(x+1)
          if (isTRUE(input$ylog)) df_p[, y := log10(y + 1)]

          # Bins fixos: sem isso o plotly re-binaria a cada frame e as barras
          # mudariam de largura no meio da animação
          rng <- range(df_p$y, na.rm = TRUE)
          x_bins <- list(start = rng[1],
                         end = rng[2],
                         size = max(diff(rng), .Machine$double.eps) / 40)

          # Define paleta de cores
          pallete <- pallete_discrete

          # Monta gráfico
          fig_p <- plot_ly(df_p,
                           x = ~y,
                           color = ~group,
                           colors = pallete,
                           type = "histogram",
                           frame = ~slider,
                           autobinx = FALSE,
                           xbins = x_bins,
                           showlegend = TRUE,
                           hoverinfo = "text",
                           hovertemplate = paste0(i18n()$label_count, ": %{y}<br>",
                                                  x_title(), ": %{x}")
          )

          # Parâmetros animação e slider (se tiver mais de um frame)
          if (length(unique(df_p$slider)) > 1) {
            # Edita slider
            fig_p <- fig_p %>% animation_slider(currentvalue = list(prefix = i18n()$slider_prefix, font = f1))

            # Botões da animação
            #  edita botão padrão (editar move ele para o updatemenus)
            fig_p <- fig_p %>% animation_button(label = "Play")

            #  sobrescreve updatemenus, adicionando play e pause
            fig_p$x$layout$updatemenus <- list(
              list(
                type = "buttons",
                direction = "right",
                showactive = FALSE,
                x = 0,
                y = 0,
                xanchor = "top",
                yanchor = "right",
                pad = list(t = 60, r = 5),
                buttons = list(
                  list(
                    method = "animate",
                    label = "\u25B6",
                    args = list(
                      NA, # primeiro arg vazio para play
                      list(
                        mode = "immediate",
                        transition = list(duration = 1500, easing = "linear", redraw = TRUE),
                        fromcurrent = TRUE,
                        frame = list(redraw = TRUE, duration = 1500)
                      )
                    )
                  ),
                  list(
                    method = "animate",
                    label = "I I",
                    args = list(
                      list(), # primeiro arg lista vazia para pause
                      list(
                        mode = "immediate",
                        transition = list(duration = 0),
                        frame = list(redraw = FALSE, duration = 0)
                      )
                    )
                  )
                )
              )
            )

            # Pula animação para último frame (custom JS)
            first_frame <- min(df_p$slider)
            last_frame <- max(df_p$slider)
            fig_p <- fig_p %>% onRender("
            function(el,x,data){
              Plotly.animate(el, data, {frame: [{duration: 0}]})
            }",
                                        data = c(first_frame, last_frame)
            )
          }

          # Layout eixos
          x_axis_layout <- list(
            title = x_title(),
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )
          y_axis_layout <- list(
            title = i18n()$label_count,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )
          # Layout hover/tooltip
          tooltip <- list(
            bordercolor = "rgba(255, 255, 255, 1)",
            bgopacity = "0.5",
            font = f1
          )

          # Aplica layout
          fig_p <- fig_p %>%
            layout(
              font = f1,
              xaxis = x_axis_layout,
              yaxis = y_axis_layout,
              showlegend = TRUE,
              hoverlabel = tooltip,
              bargap = 0.1
            )

          #  Configura botões do plotly
          fig_p <- fig_p %>%
            config(
              # toImageButtonOptions = list(format = "svg"),
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

    # Observa eventos: preenche os inputs a partir da URL no carregamento
    # (só uma vez - depois quem cuida dos inputs é o observer de idioma)
    observeEvent(session$clientData$url_search, {
      update_my_inputs()
    }, once = TRUE)
  }

  # Retorna objeto server
  server
}
