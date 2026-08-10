# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# operador de default (NULL-coalescing) para as choices iniciais
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || identical(a, "")) b else a

# Funcão para retornar objeto server
get_server <- function(files, param) {

  # Carrega as duas bases (o toggle geográfico decide qual está ativa). As classes
  # from/to ficam em inglês (chave interna); a tradução PT/EN é só de rótulo.
  df_est   <- readRDS(files$db_file_est)   %>% dplyr::ungroup()
  df_munic <- readRDS(files$db_file_munic) %>% dplyr::ungroup()

  # Legenda oficial EN->PT (substitui o antigo str_replace_all inline)
  leg <- data.table::fread(files$legenda, encoding = "UTF-8")

  # rótulo de uma classe (chave inglesa) no idioma; fallback = a própria chave
  label_of <- function(keys, lang) {
    if (lang == "pt") {
      lab <- leg$nome_pt[match(keys, leg$nome_en)]
      lab[is.na(lab)] <- keys[is.na(lab)]
      lab
    } else {
      keys
    }
  }
  # rótulos de nível (optgroup) do MapBiomas
  niveis_lab <- list(
    pt = c("0" = "Nível 0 — Categorias amplas", "1" = "Nível 1 — Grandes classes",
           "2" = "Nível 2 — Subclasses",        "3" = "Nível 3 — Detalhamento",
           "4" = "Nível 4 — Classes específicas"),
    en = c("0" = "Level 0 — Broad categories",  "1" = "Level 1 — Major classes",
           "2" = "Level 2 — Subclasses",        "3" = "Level 3 — Detail",
           "4" = "Level 4 — Specific classes")
  )
  # choices agrupadas por NÍVEL (optgroup): dentro de cada grupo, nome = rótulo
  # exibido (PT/EN) e valor = chave inglesa. Nível vem da legenda oficial.
  make_choices <- function(keys, lang) {
    lab <- label_of(keys, lang)
    niv <- leg$nivel[match(keys, leg$nome_en)]
    niv[is.na(niv)] <- 99L
    ord  <- order(niv, lab)
    keys <- keys[ord]; lab <- lab[ord]; niv <- niv[ord]
    grp    <- niveis_lab[[lang]]
    outras <- if (lang == "pt") "Outras" else "Other"
    hdr <- ifelse(as.character(niv) %in% names(grp), grp[as.character(niv)], outras)
    split(stats::setNames(keys, lab), factor(hdr, levels = unique(hdr)))
  }

  # opções estáveis (união das duas bases; independem do geo)
  from_keys <- sort(unique(c(df_est$from, df_munic$from)))
  to_keys   <- sort(unique(c(df_est$to,   df_munic$to)))

  # 1º e último ano da série (para subtítulo e rótulo do acumulado)
  time_all <- sort(unique(c(df_est$time, df_munic$time)))
  yr_first <- sub(" .*", "", time_all[1])
  yr_last  <- sub(".* ", "", time_all[length(time_all)])

  # par (from,to) INICIAL fixo: Formação Florestal -> Área Urbana. A chave interna
  # é em inglês, então vale igual para PT/EN e para estado/município. O fallback só
  # protege caso o nome exato mude numa coleção futura.
  default_from <- if ("Forest Formation" %in% from_keys) "Forest Formation" else from_keys[1]
  default_to   <- if ("Urban Area" %in% to_keys) "Urban Area" else {
    hit <- grep("urban", to_keys, ignore.case = TRUE, value = TRUE)
    if (length(hit)) hit[1] else to_keys[1]
  }
  default_pair <- list(from = default_from, to = default_to)

  server <- function(input, output, session) {

    # ---------------------------- Idioma ----------------------------
    lang <- reactiveVal({
      query <- parseQueryString(isolate(session$clientData$url_search))
      if (identical(query[["lang"]], "en")) "en" else "pt"
    })
    observeEvent(input$toggle_lang, {
      new_lang <- ifelse(lang() == "pt", "en", "pt")
      lang(new_lang)
      updateActionButton(session, "toggle_lang",
                         label = param$i18n[[new_lang]]$btn_lang)
    })
    i18n <- reactive({ param$i18n[[lang()]] })

    # ---------------------------- Nível geográfico ----------------------------
    # Estado/Município via dois actionButton (mesmo padrão do ts_mapbiomas_cobertura)
    geo <- reactiveVal({
      query <- parseQueryString(isolate(session$clientData$url_search))
      if (identical(query[["geo"]], "munic")) "munic" else "est"
    })
    observeEvent(input$geo_est,   { geo("est") })
    observeEvent(input$geo_munic, { geo("munic") })
    observeEvent(geo(), {
      session$sendCustomMessage("setGeo", geo())
    }, ignoreInit = FALSE)

    df <- reactive({ if (geo() == "munic") df_munic else df_est })

    # base filtrada pelo par (from,to) selecionado
    df_reactived <- reactive({
      d <- df()
      if (!is.null(input$x_from) && input$x_from != "") d <- d[d$from == input$x_from, ]
      if (!is.null(input$x_to)   && input$x_to   != "") d <- d[d$to   == input$x_to, ]
      d
    })

    # ---------------------------- Textos da sidebar ----------------------------
    output$plot_desc      <- renderText({ i18n()$plot_desc })
    output$label_var_name <- renderText({ i18n()$label_var_name })
    output$label_agg      <- renderText({ i18n()$label_agg })
    output$label_geo_est  <- renderText({ i18n()$label_geo_name$est })
    output$label_geo_munic<- renderText({ i18n()$label_geo_name$munic })

    # Switch "acumulado desde o 1º ano" (label traduzido, com o ano embutido)
    output$switches <- renderUI({
      materialSwitch(
        "accumulate",
        tags$span(sprintf(i18n()$label_accum, yr_first), class = "switch-label"),
        value = isTRUE(isolate(input$accumulate)), status = "info"
      )
    })

    # ---------------------------- Preenchimento inicial ----------------------------
    # choices de/para com rótulo no idioma atual, valor = chave inglesa
    observe({
      lg <- lang()
      updateSelectInput(session, "x_from",
                        label = i18n()$label_from,
                        choices = make_choices(from_keys, lg),
                        selected = isolate(input$x_from) %||% default_pair$from)
      updateSelectInput(session, "x_to",
                        label = i18n()$label_to,
                        choices = make_choices(to_keys, lg),
                        selected = isolate(input$x_to) %||% default_pair$to)
    })

    # ---------------------------- URL <-> inputs ----------------------------
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "lang=", lang(),
        "&", "geo=", geo(),
        "&", "x_from=", input$x_from,
        "&", "x_to=", input$x_to
      )
      updateQueryString(q_string, mode = "replace")
    }

    # inputs iniciais a partir da URL (roda uma vez)
    observeEvent(session$clientData$url_search, {
      query <- parseQueryString(session$clientData$url_search)
      if (!is.null(query[["x_from"]]) && query[["x_from"]] %in% from_keys) {
        updateSelectInput(session, "x_from",
                          choices = make_choices(from_keys, lang()),
                          selected = query[["x_from"]])
      }
      if (!is.null(query[["x_to"]]) && query[["x_to"]] %in% to_keys) {
        updateSelectInput(session, "x_to",
                          choices = make_choices(to_keys, lang()),
                          selected = query[["x_to"]])
      }
    }, ignoreInit = FALSE, once = TRUE)

    # ---------------------------- Títulos ----------------------------
    output$plot_title <- renderText({
      if (is.null(input$x_from) || input$x_from == "" ||
          is.null(input$x_to)   || input$x_to == "") {
        return(i18n()$no_variable)
      }
      if (nrow(df_reactived()) == 0) return(i18n()$no_observation)
      paste0(i18n()$server1,
             label_of(input$x_from, lang()), i18n()$server2,
             label_of(input$x_to, lang()))
    })

    output$plot_subtitle <- renderUI({
      if (is.null(input$x_from) || input$x_from == "" ||
          is.null(input$x_to)   || input$x_to == "" ||
          nrow(df_reactived()) == 0) return(HTML("&nbsp;"))
      # janela mostrada até o JS do slider atualizar: a última, que é onde a
      # animação começa. O <span> é reescrito no cliente a cada troca de quadro.
      # No acumulado mostramos só o ANO FINAL da janela ("...até 1989").
      # Acumulado: subtítulo estático (o ano corrente vai no slider, nativo).
      # Não-acumulado: janela selecionada via <span> reescrito pelo JS do slider.
      if (isTRUE(input$accumulate)) return(HTML(sprintf(i18n()$subtitle_cum, yr_first)))
      frame0 <- tail(sort(unique(df_reactived()$time)), 1)
      span   <- sprintf("<span id='subtitle_frame'>%s</span>", frame0)
      HTML(sprintf(i18n()$subtitle_annual, span))
    })

    # ---------------------------- Gráfico (bar-race do ranking) ----------------------------
    output$plot <- renderPlotly({

      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco

      tryCatch(
        {
          table_lang <- param$tables[[lang()]]
          x_col      <- table_lang[which(table_lang$var == param$x_def), ]
          color_col  <- table_lang[which(table_lang$var == param$color_def), ]
          slider_col <- table_lang[which(table_lang$var == param$slider_def), ]
          text_col   <- table_lang[which(table_lang$var == param$text_def), ]
          id_col     <- table_lang[which(table_lang$var == param$id_def), ]

          # Coluna vazia para o ranking (y = rank)
          y_col <- list(var = "rank", label = i18n()$rank_label)
          x_col$label <- i18n()$x_label

          d <- df_reactived()
          df_p <- data.frame(
            d[[x_col$var]],
            NA,
            d[[color_col$var]],
            d[[slider_col$var]],
            d[[text_col$var]],
            d[[color_col$var]],
            d[[id_col$var]]
          )
          colnames(df_p) <- c("x", "y", "color", "slider", "text", "group", "id")

          # Remove NAs
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$color)), ]
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Acumulado desde o 1º ano: soma corrente da área por grupo ao longo dos
          # anos. A base vem com grade completa (0 nos anos sem transição), então o
          # cumsum é contínuo. Somar a MESMA transição from->to ano a ano é aditivo
          # (é fluxo acumulado, não a janela "1985->ano" da fonte).
          if (isTRUE(input$accumulate)) {
            df_p <- df_p %>%
              arrange(group, slider) %>%
              group_by(group) %>%
              mutate(x = cumsum(x)) %>%
              ungroup()
            # eixo temporal = ano final ("acumulado até"), não o intervalo
            df_p$slider <- sub(".* - ", "", df_p$slider)
          }

          # Ranking por ano (slider): ordena por x e preenche y
          df_p <- df_p %>%
            group_by(slider) %>%
            mutate(y = order(order(x, decreasing = TRUE))) %>%
            arrange(y, .by_group = TRUE)

          df_p$y[is.na(df_p$y)] <- max(df_p$y) + 1
          df_p$x[is.na(df_p$x)] <- 0

          if (all(is.na(df_p$color))) df_p$color <- " "

          # Só grupos que ficam no top n em algum momento
          top_n <- 10
          top_groups <- unique(df_p$group[which(df_p$y <= top_n)])
          df_p <- df_p %>% filter(group %in% top_groups)

          # Tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            "(", df_p$slider, ")", "<br><br>",
            label_of(input$x_from, lang()), i18n()$to_connector,
            label_of(input$x_to, lang()), "<br>",
            i18n()$measur_unit1, ": ", format(df_p$x, scientific = FALSE,
                                              digits = 2,
                                              decimal.mark = ",",
                                              big.mark = "."), i18n()$measur_unit2, "<br>",
            y_col$label, ": ", df_p$y, "<br>"
          )

          # Paleta
          pallete <- pallete_continuous
          if (!is.numeric(df_p$color)) pallete <- pallete_discrete

          min_x <- min(0, min(df_p$x))
          max_x <- max(0, max(df_p$x))

          # base do gráfico
          fig_p <- plot_ly(df_p,
            x = ~x, y = ~y, color = ~color, colors = pallete,
            frame = ~slider, text = ~tooltip,
            textposition = "middle right", showlegend = FALSE,
            hoverinfo = "text"
          )

          # barras
          fig_p <- fig_p %>% add_segments(
            x = 0, xend = ~x, y = ~y, yend = ~y,
            split = ~id, color = ~color,
            line = list(width = 30), opacity = 0.7
          )

          # textos
          fig_p <- fig_p %>% add_text(
            x = 0.01 * max_x, text = ~text, ids = ~id,
            hoverinfo = "none", textfont = f1, textposition = "middle right"
          )

          if (!is.numeric(df_p$color)) {
            fig_p <- fig_p %>% add_segments(
              hoverinfo = "none", showlegend = TRUE,
              x = 0, xend = 0, y = ~y, yend = ~y, color = ~color,
              line = list(width = 30), opacity = 0.7
            )
          } else {
            fig_p <- fig_p %>% colorbar(title = color_col$label)
          }

          # Animação/slider (se mais de um frame)
          if (length(unique(df_p$slider)) > 1) {
            fig_p <- fig_p %>% animation_slider(
              currentvalue = list(
                prefix = if (isTRUE(input$accumulate)) i18n()$slider_prefix_cum
                         else i18n()$slider_prefix,
                font = f1))
            fig_p <- fig_p %>% animation_button(label = "Play")

            fig_p$x$layout$updatemenus <- list(
              list(
                type = "buttons", direction = "right", showactive = FALSE,
                x = 0, y = 0, xanchor = "top", yanchor = "right",
                pad = list(t = 60, r = 5),
                buttons = list(
                  list(
                    method = "animate", label = "\u25B6",
                    args = list(NA, list(
                      mode = "immediate",
                      transition = list(duration = 1500, easing = "linear", redraw = TRUE),
                      fromcurrent = TRUE,
                      frame = list(redraw = TRUE, duration = 1500)
                    ))
                  ),
                  list(
                    method = "animate", label = "I I",
                    args = list(list(), list(
                      mode = "immediate",
                      transition = list(duration = 0),
                      frame = list(redraw = FALSE, duration = 0)
                    ))
                  )
                )
              )
            )

            first_frame <- min(df_p$slider)
            last_frame  <- max(df_p$slider)
            # no acumulado o subtítulo mostra só o ano final da janela
            fmt_js <- if (isTRUE(input$accumulate)) "v.split(' - ').pop().trim()" else "v"
            fig_p <- fig_p %>% onRender(sprintf("
            function(el, x, data){
              Plotly.animate(el, data, {frame: [{duration: 0}]});
              var sub = document.getElementById('subtitle_frame');
              function fmt(v){ return %s; }
              function setYr(v){ if (sub && v != null && v !== '') sub.innerText = fmt(v); }
              setYr(data[data.length - 1]);
              el.on('plotly_animatingframe', function(e){ if (e && e.name) setYr(e.name); });
              el.on('plotly_sliderchange', function(e){
                if (e && e.step) setYr(e.step.label || e.step.value);
              });
            }", fmt_js), data = c(first_frame, last_frame))
          }

          # Layout eixos
          x_axis_layout <- list(
            title = x_col$label, titlefont = f1, tickfont = f2,
            automargin = FALSE, autorange = FALSE,
            range = c(min_x, max_x), showgrid = FALSE, zeroline = FALSE
          )
          y_axis_layout <- list(
            title = y_col$label, titlefont = f1, tickfont = f2,
            automargin = FALSE, autorange = FALSE,
            showgrid = FALSE, zeroline = FALSE,
            dtick = 1, tick0 = 1,
            range = c(top_n + 0.5, 0.5), type = "numeric"
          )

          tooltip <- list(
            bordercolor = "rgba(255, 255, 255, 1)", bgopacity = "0.5", font = f1
          )

          fig_p <- fig_p %>%
            layout(
              font = f1, xaxis = x_axis_layout, yaxis = y_axis_layout,
              showlegend = TRUE,
              legend = list(title = list(text = color_col$label)),
              hoverlabel = tooltip
            )

          fig <- fig %>% animation_opts(1500, easing = "linear", redraw = FALSE)

          fig_p <- fig_p %>%
            config(
              displaylogo = FALSE,
              modeBarButtonsToRemove = c("lasso2d", "select2d", "hoverCompareCartesian")
            )

          fig <- fig_p
        },
        error = function(cond) {
          print("plot error")
          fig <- plotly_empty()
        }
      )
      fig
    }) %>% bindCache(input$x_from, input$x_to, lang(), geo(), input$accumulate)
  }

  # Retorna objeto server
  server
}
