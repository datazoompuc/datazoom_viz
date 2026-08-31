# -------------------------------- Define lógica do server --------------------------------

pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")

f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || identical(a, "")) b else a

get_server <- function(files, param) {

  # Duas bases (o toggle geográfico decide qual está ativa). from/to em inglês.
  df_est   <- readRDS(files$db_file_est)   %>% dplyr::ungroup()
  df_munic <- readRDS(files$db_file_munic) %>% dplyr::ungroup()

  leg <- data.table::fread(files$legenda, encoding = "UTF-8")

  label_of <- function(keys, lang) {
    if (lang == "pt") {
      lab <- leg$nome_pt[match(keys, leg$nome_en)]
      lab[is.na(lab)] <- keys[is.na(lab)]
      lab
    } else keys
  }

  niveis_lab <- list(
    pt = c("0" = "Nível 0 — Categorias amplas", "1" = "Nível 1 — Grandes classes",
           "2" = "Nível 2 — Subclasses",        "3" = "Nível 3 — Detalhamento",
           "4" = "Nível 4 — Classes específicas"),
    en = c("0" = "Level 0 — Broad categories",  "1" = "Level 1 — Major classes",
           "2" = "Level 2 — Subclasses",        "3" = "Level 3 — Detail",
           "4" = "Level 4 — Specific classes")
  )
  # choices agrupadas por nível (optgroup): nome = rótulo exibido, valor = chave inglesa
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

  from_keys <- sort(unique(c(df_est$from, df_munic$from)))
  to_keys   <- sort(unique(c(df_est$to,   df_munic$to)))

  # 1º ano da série (rótulo do acumulado)
  yr_first <- sub(" .*", "", sort(unique(c(df_est$time, df_munic$time)))[1])

  # par inicial fixo: Formação Florestal -> Área Urbana (igual ao rk)
  default_from <- if ("Forest Formation" %in% from_keys) "Forest Formation" else from_keys[1]
  default_to   <- if ("Urban Area" %in% to_keys) "Urban Area" else {
    hit <- grep("urban", to_keys, ignore.case = TRUE, value = TRUE)
    if (length(hit)) hit[1] else to_keys[1]
  }

  server <- function(input, output, session) {

    # ---------------------------- Idioma ----------------------------
    lang <- reactiveVal({
      query <- parseQueryString(isolate(session$clientData$url_search))
      if (identical(query[["lang"]], "en")) "en" else "pt"
    })
    observeEvent(input$toggle_lang, {
      new_lang <- ifelse(lang() == "pt", "en", "pt")
      lang(new_lang)
      updateActionButton(session, "toggle_lang", label = param$i18n[[new_lang]]$btn_lang)
    })
    i18n <- reactive({ param$i18n[[lang()]] })

    # ---------------------------- Nível geográfico ----------------------------
    geo <- reactiveVal({
      query <- parseQueryString(isolate(session$clientData$url_search))
      if (identical(query[["geo"]], "munic")) "munic" else "est"
    })
    observeEvent(input$geo_est,   { geo("est") })
    observeEvent(input$geo_munic, { geo("munic") })
    observeEvent(geo(), { session$sendCustomMessage("setGeo", geo()) }, ignoreInit = FALSE)

    df <- reactive({ if (geo() == "munic") df_munic else df_est })

    df_reactived <- reactive({
      d <- df()
      if (!is.null(input$x_from) && input$x_from != "") d <- d[d$from == input$x_from, ]
      if (!is.null(input$x_to)   && input$x_to   != "") d <- d[d$to   == input$x_to, ]
      if (!is.null(input$filter1)) d <- d[d$group %in% input$filter1, ]
      d
    })

    filter_choices <- reactive({
      fc <- sort(unique(df()$group)); fc[!is.na(fc) & fc != ""]
    })

    # ---------------------------- Textos da sidebar ----------------------------
    output$plot_desc      <- renderText({ i18n()$plot_desc })
    output$label_var_name <- renderText({ i18n()$label_var_name })
    output$label_agg      <- renderText({ i18n()$label_agg })
    output$label_geo_est  <- renderText({ i18n()$label_geo_name$est })
    output$label_geo_munic<- renderText({ i18n()$label_geo_name$munic })

    output$switches <- renderUI({
      i <- param$i18n[[lang()]]
      tagList(
        materialSwitch("y_option",
          tags$span(i$label_prop, class = "switch-label"),
          value = isTRUE(isolate(input$y_option)), status = "info"),
        materialSwitch("accumulate",
          tags$span(sprintf(i$label_accum, yr_first), class = "switch-label"),
          value = isTRUE(isolate(input$accumulate)), status = "info")
      )
    })

    # proporcional e acumulado são mutuamente exclusivos
    observeEvent(input$y_option, {
      if (isTRUE(input$y_option)) updateMaterialSwitch(session, "accumulate", value = FALSE)
    }, ignoreInit = TRUE)
    observeEvent(input$accumulate, {
      if (isTRUE(input$accumulate)) updateMaterialSwitch(session, "y_option", value = FALSE)
    }, ignoreInit = TRUE)

    # ---------------------------- Preenchimento inicial (choices) ----------------------------
    observe({
      lg <- lang()
      updateSelectInput(session, "x_from", label = i18n()$label_from,
                        choices = make_choices(from_keys, lg),
                        selected = isolate(input$x_from) %||% default_from)
      updateSelectInput(session, "x_to", label = i18n()$label_to,
                        choices = make_choices(to_keys, lg),
                        selected = isolate(input$x_to) %||% default_to)
    })

    # grupos: sorteia 2 no início; troca choices ao mudar de geo
    observeEvent(geo(), {
      fc <- filter_choices()
      updateSelectizeInput(session, "filter1",
                           label = i18n()$label_geo_name[[geo()]],
                           choices = fc, selected = sample(fc, min(2, length(fc))))
    }, ignoreInit = FALSE)

    # retraduz labels ao trocar idioma (mantém seleção)
    observeEvent(lang(), {
      updateSelectInput(session, "x_from", label = i18n()$label_from,
                        choices = make_choices(from_keys, lang()),
                        selected = isolate(input$x_from))
      updateSelectInput(session, "x_to", label = i18n()$label_to,
                        choices = make_choices(to_keys, lang()),
                        selected = isolate(input$x_to))
      updateSelectizeInput(session, "filter1",
                           label = i18n()$label_geo_name[[geo()]],
                           selected = isolate(input$filter1))
    }, ignoreInit = TRUE)

    # ---------------------------- URL <-> inputs ----------------------------
    update_my_queryString <- function() {
      q_string <- paste0("?", "lang=", lang(), "&", "geo=", geo(),
                         "&", "x_from=", input$x_from, "&", "x_to=", input$x_to,
                         "&", "y_option=", isTRUE(input$y_option),
                         "&", "accumulate=", isTRUE(input$accumulate))
      for (i in input$filter1) q_string <- paste0(q_string, "&", "filter1=", i)
      updateQueryString(q_string, mode = "replace")
    }

    observeEvent(session$clientData$url_search, {
      query <- parseQueryString(session$clientData$url_search)
      if (!is.null(query[["x_from"]]) && query[["x_from"]] %in% from_keys)
        updateSelectInput(session, "x_from", choices = make_choices(from_keys, lang()),
                          selected = query[["x_from"]])
      if (!is.null(query[["x_to"]]) && query[["x_to"]] %in% to_keys)
        updateSelectInput(session, "x_to", choices = make_choices(to_keys, lang()),
                          selected = query[["x_to"]])
      if (!is.null(query[["y_option"]]))
        updateMaterialSwitch(session, "y_option", value = (query[["y_option"]] == "TRUE"))
      if (!is.null(query[["accumulate"]]))
        updateMaterialSwitch(session, "accumulate", value = (query[["accumulate"]] == "TRUE"))
      selected <- unlist(query[names(query) == "filter1"], use.names = FALSE)
      if (!is.null(selected) && all(selected %in% filter_choices()))
        updateSelectizeInput(session, "filter1",
                             label = i18n()$label_geo_name[[geo()]],
                             choices = filter_choices(), selected = selected)
    }, ignoreInit = FALSE, once = TRUE)

    # ---------------------------- Títulos ----------------------------
    output$plot_title <- renderText({
      if (is.null(input$x_from) || input$x_from == "" ||
          is.null(input$x_to)   || input$x_to == "") return(" ")
      paste(label_of(input$x_from, lang()), i18n()$to_connector,
            label_of(input$x_to, lang()))
    })

    output$plot_subtitle <- renderText({
      if (is.null(input$x_from) || input$x_from == "" ||
          is.null(input$x_to)   || input$x_to == "" ||
          is.null(input$filter1) || length(input$filter1) < 1) return(" ")
      if (nrow(df_reactived()) == 0) return(i18n()$no_observation)
      if (isTRUE(input$accumulate)) return(sprintf(i18n()$subtitle_cum, yr_first))
      if (isTRUE(input$y_option)) return(i18n()$subtitle_prop)
      i18n()$subtitle_init
    })

    # ---------------------------- Gráfico (linhas no tempo) ----------------------------
    output$plot <- renderPlotly({
      update_my_queryString()
      fig <- plotly_empty()
      tryCatch({
        if (is.null(input$x_from) || input$x_from == "" ||
            is.null(input$x_to)   || input$x_to == "" ||
            is.null(input$filter1) || length(input$filter1) < 1) {
          fig <- plotly_empty(); stop()
        }

        table_lang <- param$tables[[lang()]]
        x_col <- table_lang[which(table_lang$var == param$x_def), ]
        y_col <- table_lang[which(table_lang$var == param$y_def), ]
        y_col$label <- i18n()$y_label
        x_col$label <- if (isTRUE(input$accumulate)) i18n()$x_label_cum else i18n()$x_label

        d <- df_reactived()
        df_p <- data.frame(d[[x_col$var]], d[[y_col$var]], d$group)
        colnames(df_p) <- c("x", "y", "color")
        df_p$group <- d$group
        df_p$text  <- d$group
        df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y)), ]
        if (nrow(df_p) < 1) { fig <- plotly_empty(); stop() }

        # Acumulado desde o 1º ano: completa a série do grupo (0 nas janelas sem
        # transição) e faz a soma corrente. Vem ANTES do proporcional.
        if (isTRUE(input$accumulate) && is.numeric(df_p$y)) {
          all_win <- sort(unique(df()$time))
          full <- expand.grid(group = unique(df_p$group), x = all_win,
                              stringsAsFactors = FALSE)
          df_p <- merge(full, df_p[, c("group", "x", "y")],
                        by = c("group", "x"), all.x = TRUE)
          df_p$y[is.na(df_p$y)] <- 0
          df_p$text <- df_p$group
          df_p <- df_p %>%
            dplyr::group_by(group) %>%
            dplyr::arrange(x, .by_group = TRUE) %>%
            dplyr::mutate(y = cumsum(y)) %>%
            dplyr::ungroup()
          # eixo temporal = ano final ("acumulado até"), não o intervalo
          df_p$x <- sub(".* - ", "", df_p$x)
        }

        # Proporcional ao intervalo inicial (índice base 100 por grupo)
        if (isTRUE(input$y_option) && is.numeric(df_p$y)) {
          df_p <- df_p %>%
            dplyr::arrange(group, x) %>%
            dplyr::group_by(group) %>%
            dplyr::mutate(y = (y / dplyr::first(y)) * 100) %>%
            dplyr::ungroup()
        }

        unidade <- if (isTRUE(input$y_option)) "%" else "ha"
        df_p$tooltip <- paste0(
          "<b>", df_p$text, "</b><br>",
          x_col$label, ": ", df_p$x, "<br>",
          y_col$label, ": ", format(round(df_p$y, 2), scientific = FALSE,
                                    decimal.mark = ",", big.mark = "."), " (", unidade, ")"
        )

        df_p <- df_p %>% dplyr::arrange(group, x)

        fig_p <- plot_ly(df_p, x = ~x, y = ~y, color = ~group,
                         colors = pallete_discrete,
                         type = "scatter", mode = "lines+markers",
                         text = ~tooltip, hoverinfo = "text")

        y_title <- y_col$label
        if (isTRUE(input$y_option)) y_title <- paste0(y_col$label, " *")

        fig_p <- fig_p %>%
          layout(
            font = f1,
            xaxis = list(title = x_col$label, titlefont = f1, tickfont = f2,
                         automargin = TRUE, autorange = TRUE, showgrid = FALSE, zeroline = FALSE),
            yaxis = list(title = y_title, titlefont = f1, tickfont = f2,
                         automargin = FALSE, autorange = TRUE, showgrid = FALSE, zeroline = FALSE),
            showlegend = TRUE,
            hoverlabel = list(bordercolor = "rgba(255,255,255,1)", bgopacity = "0.5", font = f1)
          ) %>%
          config(displaylogo = FALSE,
                 modeBarButtonsToRemove = c("lasso2d", "select2d", "hoverCompareCartesian"))

        fig <- fig_p
      }, error = function(cond) { print("plot error"); fig <- plotly_empty() })
      fig
    }) %>% bindCache(input$x_from, input$x_to, input$filter1, input$y_option,
                     input$accumulate, lang(), geo())
  }

  server
}
