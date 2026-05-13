# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# Funcão para retornar objeto server
get_server <- function(files, param) {
  
  # Carrega dados
  df <- readRDS(files$db_file)

  server <- function(input, output, session) {

    # Língua inicial (lida da URL)
    lang <- reactiveVal({
      query <- parseQueryString(isolate(session$clientData$url_search))
      if (identical(query[["lang"]], "en")) "en" else "pt"
    })

    # Alterna língua ao clicar no botão
    observeEvent(input$toggle_lang, {
      new_lang <- ifelse(lang() == "pt", "en", "pt")
      lang(new_lang)
      updateActionButton(session, "toggle_lang",
                         label = ifelse(new_lang == "pt", "English", "Português"))
    })

    # Atalho para os textos da língua ativa
    i18n <- reactive({ param$i18n[[lang()]] })

    # Outputs de texto da sidebar
    output$plot_desc <- renderText({ i18n()$plot_desc })
    output$ui1       <- renderText({ i18n()$ui1 })

    # Tradução reativa das colunas de filtro
    df_translated <- reactive({
      d <- df
      if (lang() == "en") {
        d$fonte <- d$fonte %>%
          str_replace_all(c("Termoelétrica" = "Thermal Power",
                            "Eólica" = "Wind Power",
                            "Solar" = "Solar Power",
                            "Pequena Central Hidrelétrica" = "Small Hydroelectric Center",
                            "Central Geradora Hidrelétrica" = "Hydroelectric Generating Center",
                            "Usina Hidrelétrica" = "Hydroelectric Power Plant",
                            "Energia Termonuclear" = "Thermonuclear Power"))

        d$origem <- d$origem %>%
          str_replace_all(c("Fóssil" = "Fossil",
                            "Biomassa" = "Biomass",
                            "Eólica" = "Wind",
                            "Hídrica" = "Hydric"))

        d$tipo <- d$tipo %>%
          str_replace_all(c("Carvão Mineral" = "Mineral Coal",
                            "Petróleo" = "Oil",
                            "Radiação Solar" = "Solar Radiation",
                            "Gás Natural" = "Natural Gas",
                            "Floresta" = "Forest",
                            "Cinética Do Vento" = "Wind Kinetics",
                            "Potencial Hidráulico" = "Hydraulic Potential",
                            "Agroindustriais" = "Agroindustrial",
                            "Biocombustíveis Líquidos" = "Liquid Biofuels",
                            "Resíduos Animais" = "Animal Residue",
                            "Outros Fósseis" = "Other Fossil",
                            "Resíduos Solidos Urbanos" = "Solid Urban Residue",
                            "Urânio" = "Uranium"))

        d$combustivel_final <- d$combustivel_final %>%
          str_replace_all(c("Carvão Mineral" = "Mineral Coal",
                            "Óleo Diesel" = "Diesel",
                            "Gás De Alto Forno - Biomassa" = "Blast Furnace Gas - Biomass",
                            "Gás De Alto Forno - CM" = "Blast Furnace Gas",
                            "Radiação Solar" = "Solar Radiation",
                            "Óleo Combustivel" = "Fuel Oil",
                            "Gás Natural" = "Natural Gas",
                            "Cinética Do Vento" = "Wind Kinetics",
                            "Licor Negro" = "Black Liquor",
                            "Calor De Processo - GN" = "Process Heat - GN",
                            "Lenha" = "Firewood",
                            "Capim Elefante" = "Elephant Grass",
                            "Carvão Vegetal" = "Charcoal",
                            "Potencial Hidráulico" = "Hydraulic Potential",
                            "Resíduos Florestais" = "Forest Residue",
                            "Bagaço De Cana" = "Sugar Cane Bagasse",
                            "Óleos Vegetais" = "Vegetable Oils",
                            "Biogás Resíduo Animal" = "Biogas - Animal Residue",
                            "Calor De Processo - OF" = "Process Heat - OF",
                            "Casca De Arroz" = "Rice Husk",
                            "Carvão - RU" = "Coal - RU",
                            "Biogás - Agroindustriais" = "Biogas - Agroindustrial",
                            "Urânio" = "Uranium",
                            "Biogás - Resíduos Urbanos" = "Biogas - Urban Residue",
                            "Resíduos Sólidos Urbanos" = "Solid Urban Residue",
                            "Outros Energéticos de Petróleo" = "Other Oil Energetics",
                            "Gás De Refinaria" = "Refinery Gas",
                            "Calor De Processo - CM" = "Process Heat - CM",
                            "Biogas - Floresta" = "Biogas - Forest",
                            "Gás De Alto Forno - PE" = "Blast Funace Gas - PE",
                            "Etanol" = "Ethanol"
          ))
      }
      d
    })

    df_reactived <- reactive({

      d <- df_translated() %>% filter(ano != as.numeric(str_extract(Sys.Date(), "^.{4}")))
      if (input$tipo != i18n()$server7) d <- d %>% filter(tipo == input$tipo)
      if (input$fonte != i18n()$server7) d <- d %>% filter(fonte == input$fonte)
      if (input$origem != i18n()$server7) d <- d %>% filter(origem == input$origem)
      if (input$combustivel != i18n()$server7) d <- d %>% filter(combustivel_final == input$combustivel)

      d %>%
        group_by(ano, estado) %>%
        summarise(potencia_outorgada_kw = sum(potencia_outorgada_kw))
    })

    # Atualiza opções dos selects ao trocar língua
    observeEvent(lang(), {
      d <- df_translated()
      fonte_choices       <- c(i18n()$server7, sort(unique(d$fonte)))
      origem_choices      <- c(i18n()$server7, sort(unique(d$origem)))
      tipo_choices        <- c(i18n()$server7, sort(unique(d$tipo)))
      combustivel_choices <- c(i18n()$server7, sort(unique(d$combustivel_final)))

      updateSelectInput(session, "fonte",
                        label = i18n()$ui2, choices = fonte_choices, selected = i18n()$server7)
      updateSelectInput(session, "origem",
                        label = i18n()$ui3, choices = origem_choices, selected = i18n()$server7)
      updateSelectInput(session, "tipo",
                        label = i18n()$ui4, choices = tipo_choices, selected = i18n()$server7)
      updateSelectInput(session, "combustivel",
                        label = i18n()$ui5, choices = combustivel_choices, selected = i18n()$server7)
    })

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "lang=", lang(),
        "&", "fonte=", input$fonte,
        "&", "origem=", input$origem,
        "&", "tipo=", input$tipo,
        "&", "combustivel=", input$combustivel
      )
      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)
      d <- df_translated()
      fonte_choices       <- c(i18n()$server7, sort(unique(d$fonte)))
      origem_choices      <- c(i18n()$server7, sort(unique(d$origem)))
      tipo_choices        <- c(i18n()$server7, sort(unique(d$tipo)))
      combustivel_choices <- c(i18n()$server7, sort(unique(d$combustivel_final)))

      if (!is.null(query[["fonte"]])) {
        updateSelectInput(session, "fonte",
          choices = fonte_choices,
          selected = query[["fonte"]]
        )
      }
      if (!is.null(query[["origem"]])) {
        updateSelectInput(session, "origem",
          choices = origem_choices,
          selected = query[["origem"]]
        )
      }
      if (!is.null(query[["tipo"]])) {
        updateSelectInput(session, "tipo",
          choices = tipo_choices,
          selected = query[["tipo"]]
        )
      }
      if (!is.null(query[["combustivel"]])) {
        updateSelectInput(session, "combustivel",
          choices = combustivel_choices,
          selected = query[["combustivel"]]
        )
      }
    }


    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$tipo) || is.null(input$origem) || 
          is.null(input$fonte) || is.null(input$combustivel)) {
        text <- i18n()$server1
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- param$tables[[lang()]][which(param$tables[[lang()]]$var == param$x_def), ]

        text <- paste0(i18n()$server2, x_col$label)
      }

      text
    })
    output$plot_subtitle <- renderText({
      text <- paste0(i18n()$server3, input$fonte, i18n()$server4, input$origem,
                     i18n()$server5, input$tipo, i18n()$server6, input$combustivel)

      text
    })

    # Output gráfico
    output$plot <- renderPlotly({

      # random_inputs() #preenche inputs se estiverem vazios
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco

      tryCatch(
        {

          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(input$tipo) || is.null(input$origem) || 
              is.null(input$fonte) || is.null(input$combustivel)) {
            fig <- plotly_empty()
            stop()
          }
          
          
          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          table_lang <- param$tables[[lang()]]
          x_col <- table_lang[which(table_lang$var == param$x_def), ]
          color_col <- table_lang[which(table_lang$var == param$color_def), ]
          slider_col <- table_lang[which(table_lang$var == param$slider_def), ]
          group_col <- table_lang[which(table_lang$var == param$group), ]
          text_col <- table_lang[which(table_lang$var == param$text_def), ]
          id_col <- table_lang[which(table_lang$var == param$id_def), ]

          # Cria coluna vazia para o ranking
          y_col <- list()
          y_col$var <- "rank"
          y_col$label <- "Ranking"

          df_p <- data.frame(
            df_reactived()[x_col$var],
            NA,
            df_reactived()[color_col$var],
            df_reactived()[slider_col$var],
            df_reactived()[group_col$var],
            df_reactived()[text_col$var],
            df_reactived()[id_col$var]
          )

          colnames(df_p) <- c("x", "y", "color", "slider", "group", "text", "id")

          # Filtra colunas onde variáveis são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$color)), ]
          
          # Adicionar combinações de municipio e ano (slider buga se municipios nao aparecem sempre no df)
          comb <- tidyr::expand(df_p, slider, group) %>%
            left_join(df_p %>% select(color, group)) %>%
            unique() %>%
            mutate(text = group, id = group, y = NA)
         
           df_p <- df_p %>% 
              right_join(comb) %>%  # add all combinations of time and group
              mutate(x = ifelse(is.na(x), 0, x))

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Ordena base por variável de ranking e preenche y
          df_p <- df_p %>%
            group_by(slider) %>% # para cada ano
            mutate(y = order(order(x, decreasing = TRUE))) %>% # rank pela var de x
            arrange(y, .by_group = TRUE) # ordena por rank e ano

          # Se o rank for NA coloca para o final do ranking e zera x
          df_p$y[is.na(df_p$y)] <- max(df_p$y) + 1
          df_p$x[is.na(df_p$x)] <- 0

          # Se a coluna de cor for toda NA, preenche com strings em branco
          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }

          # Deixa somente grupos que tem rank <n em algum momento
          top_n <- 5
          top_groups <- unique(df_p$group[which(df_p$y <= top_n)])
          df_p <- df_p %>% filter(group %in% top_groups)
          
          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            "(", df_p$slider, ")", "<br><br>",
            x_col$label, ": ", format(df_p$x, scientific = FALSE,
                                      digits = 2,
                                      decimal.mark = ",", 
                                      big.mark = "."), "<br>",
            y_col$label, ": ", df_p$y, "<br>",
            color_col$label, ": ", df_p$color
          )

          # Define paleta de cores
          pallete <- pallete_continuous
          if (!is.numeric(df_p$color)) {
            pallete <- pallete_discrete
          }

          # Calcula menor e maior valor de x
          min_x <- min(0, min(df_p$x))
          max_x <- max(0, max(df_p$x))

          # Monta gráfico

          # base do gráfico
          fig_p <- plot_ly(df_p,
            x = ~x,
            y = ~y,
            color = ~color,
            colors = pallete,
            frame = ~slider,
            text = ~tooltip,
            textposition = "middle right",
            showlegend = FALSE,
            # marker = list(
            #  opacity = 0.5,
            #  line = list(width = 1, color = 'white')
            # ),
            hoverinfo = "text"
          ) %>% animation_opts(redraw = TRUE, transition = 500)

          # adiciona barras
          fig_p <- fig_p %>% add_segments(
            x = 0,
            xend = ~x,
            y = ~y,
            yend = ~y,
            split = ~id,
            color = ~color,
            line = list(width = 30),
            opacity = 0.7
          )

          # adiciona textos
          fig_p <- fig_p %>% add_text(
            x = 0.01 * max_x, # ~x/2,
            text = ~text,
            ids = ~id,
            hoverinfo = "none",
            textfont = f1,
            textposition = "middle right"
          )

          if (is.numeric(df_p$color)) {
            fig_p <- fig_p %>% colorbar(title = color_col$label)
          }



          # Parâmetros animação e slider (se tiver mais de um frame)
          if (length(unique(df_p$slider)) > 1) {
            # Edita slider
            fig_p <- fig_p %>% animation_slider(currentvalue = list(prefix = "Ano: ", font = f1))

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
                        transition = list(duration = 1750, easing = "linear", redraw = TRUE),
                        fromcurrent = TRUE,
                        frame = list(redraw = TRUE, duration = 1750)
                      )
                    )
                  ),
                  list(
                    method = "animate",
                    # label = "<U+25FC>",
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
            title = x_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = FALSE,
            range = c(min_x, max_x), # fixa range do x
            showgrid = FALSE,
            zeroline = FALSE
          )
          y_axis_layout <- list(
            title = y_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = FALSE,
            showgrid = FALSE,
            zeroline = FALSE,
            dtick = 1,
            tick0 = 1,
            range = c(top_n + 0.5, 0.5), # fixa range do y somente para top 10
            type = "numeric"
          )

          # Tipo de eixo (se log selecionado)
          # if (input$xlog & is.numeric(df_p$x)) {
          #  x_axis_layout$type <- "log"
          # }

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
              showlegend = FALSE,
              hoverlabel = tooltip
            )

          fig <- fig

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
