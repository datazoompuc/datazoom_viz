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
  df <- readRDS(files$db_file) %>% 
    right_join(tidyr::expand(., time, group)) %>%  # add all combinations of time and group
    mutate(value = ifelse(is.na(value), 0, value))
    
  if(param$lang == TRUE){
      
      df <- df %>% 
          mutate(group = case_when(group == 
                                       "Afeganistão" ~ "Afghanistan", group ==
                                       "África do Sul" ~ "South Africa", group ==
                                       "Albânia" ~ "Albania", group ==
                                       "Alemanha" ~ "Germany", group ==
                                       "Andorra" ~ "Andorra", group ==
                                       "Angola" ~ "Angola", group ==
                                       "Anguilla" ~ "Anguilla", group ==
                                       "Antígua e Barbuda" ~ "Antigua and Barbuda", group ==
                                       "Antilhas Holandesas" ~ "Netherlands Antilles", group ==
                                       "Arábia Saudita" ~ "Saudi Arabia", group ==
                                       "Argélia" ~ "Algeria", group ==
                                       "Argentina" ~ "Argentina", group ==
                                       "Armênia" ~ "Armenia", group ==
                                       "Aruba" ~ "Aruba", group ==
                                       "Austrália" ~ "Australia", group ==
                                       "Áustria" ~ "Austria", group ==
                                       "Azerbaijão" ~ "Azerbaijan", group ==
                                       "Bahamas" ~ "Bahamas", group ==
                                       "Bahrein" ~ "Bahrain", group ==
                                       "Bangladesh" ~ "Bangladesh", group ==
                                       "Barbados" ~ "Barbados", group ==
                                       "Belarus" ~ "Belarus", group ==
                                       "Bélgica" ~ "Belgium", group ==
                                       "Belize" ~ "Belize", group ==
                                       "Benin" ~ "Benin", group ==
                                       "Bermudas" ~ "Bermuda", group ==
                                       "Bolívia" ~ "Bolivia", group ==
                                       "Bonaires, Saint Eustatius e Saba" ~ "Bonaire, group == Sint Eustatius and Saba", group ==
                                       "Bósnia-Herzegovina" ~ "Bosnia and Herzegovina", group ==
                                       "Botsuana" ~ "Botswana", group ==
                                       "Bouvet, group == Ilha" ~ "Bouvet Island", group ==
                                       "Brasil" ~ "Brazil", group ==
                                       "Brunei" ~ "Brunei", group ==
                                       "Bulgária" ~ "Bulgaria", group ==
                                       "Burkina Faso" ~ "Burkina Faso", group ==
                                       "Cabo Verde" ~ "Cape Verde", group ==
                                       "Camarões" ~ "Cameroon", group ==
                                       "Camboja" ~ "Cambodia", group ==
                                       "Canadá" ~ "Canada", group ==
                                       "Canárias, group == Ilhas" ~ "Canary Islands", group ==
                                       "Catar" ~ "Qatar", group ==
                                       "Cayman, Ilhas" ~ "Cayman Islands", group ==
                                       "Cazaquistão" ~ "Kazakhstan", group ==
                                       "Chade" ~ "Chad", group ==
                                       "Chile" ~ "Chile", group ==
                                       "China" ~ "China", group ==
                                       "Chipre" ~ "Cyprus", group ==
                                       "Cingapura" ~ "Singapore", group ==
                                       "Colômbia" ~ "Colombia", group ==
                                       "Comores" ~ "Comoros", group ==
                                       "Congo" ~ "Congo", group ==
                                       "Cook, Ilhas" ~ "Cook Islands", group ==
                                       "Coreia do Norte" ~ "North Korea", group ==
                                       "Coreia do Sul" ~ "South Korea", group ==
                                       "Costa do Marfim" ~ "Ivory Coast", group ==
                                       "Costa Rica" ~ "Costa Rica", group ==
                                       "Croácia" ~ "Croatia", group ==
                                       "Cuba" ~ "Cuba", group ==
                                       "Curaçao" ~ "Curaçao", group ==
                                       "Dinamarca" ~ "Denmark", group ==
                                       "Djibuti" ~ "Djibouti", group ==
                                       "Dominica" ~ "Dominica", group ==
                                       "Egito" ~ "Egypt", group ==
                                       "El Salvador" ~ "El Salvador", group ==
                                       "Emirados Árabes Unidos" ~ "United Arab Emirates", group ==
                                       "Equador" ~ "Ecuador", group ==
                                       "Eritreia" ~ "Eritrea", group ==
                                       "Eslováquia" ~ "Slovakia", group ==
                                       "Eslovênia" ~ "Slovenia", group ==
                                       "Espanha" ~ "Spain", group ==
                                       "Estados Unidos" ~ "United States", group ==
                                       "Estônia" ~ "Estonia", group ==
                                       "Etiópia" ~ "Ethiopia", group ==
                                       "Falkland, Ilhas (Malvinas)" ~ "Falkland Islands (Malvinas)", group ==
                                       "Faroé, Ilhas" ~ "Faroe Islands", group ==
                                       "Fiji" ~ "Fiji", group ==
                                       "Filipinas" ~ "Philippines", group ==
                                       "Finlândia" ~ "Finland", group ==
                                       "França" ~ "France", group ==
                                       "Gabão" ~ "Gabon", group ==
                                       "Gâmbia" ~ "Gambia", group ==
                                       "Gana" ~ "Ghana", group ==
                                       "Geórgia" ~ "Georgia", group ==
                                       "Geórgia do Sul e Ilhas Sandwich do Sul" ~ "South Georgia and the South Sandwich Islands", group ==
                                       "Gibraltar" ~ "Gibraltar", group ==
                                       "Grécia" ~ "Greece", group ==
                                       "Grenada" ~ "Grenada", group ==
                                       "Groenlândia" ~ "Greenland", group ==
                                       "Guadalupe" ~ "Guadeloupe", group ==
                                       "Guam" ~ "Guam", group ==
                                       "Guatemala" ~ "Guatemala", group ==
                                       "Guiana" ~ "Guyana", group ==
                                       "Guiana Francesa" ~ "French Guiana", group ==
                                       "Guiné" ~ "Guinea", group ==
                                       "Guiné Equatorial" ~ "Equatorial Guinea", group ==
                                       "Guiné-Bissau" ~ "Guinea-Bissau", group ==
                                       "Haiti" ~ "Haiti", group ==
                                       "Holanda (Países Baixos)" ~ "Netherlands", group ==
                                       "Honduras" ~ "Honduras", group ==
                                       "Hong Kong" ~ "Hong Kong", group ==
                                       "Hungria" ~ "Hungary", group ==
                                       "Iêmen" ~ "Yemen", group ==
                                       "Ilha Heard e Ilhas McDonald" ~ "Heard Island and McDonald Islands", group ==
                                       "Ilhas Maldivas" ~ "Maldives", group ==
                                       "Ilhas Marianas do Norte" ~ "Northern Mariana Islands", group ==
                                       "Ilhas Marshall" ~ "Marshall Islands", group ==
                                       "Ilhas Menores Distantes dos Estados Unidos" ~ "United States Minor Outlying Islands", group ==
                                       "Ilhas Norfolk" ~ "Norfolk Island", group ==
                                       "Ilhas Pitcairn" ~ "Pitcairn Islands", group ==
                                       "Ilhas Salomão" ~ "Solomon Islands", group ==
                                       "Ilhas Turcas e Caicos" ~ "Turks and Caicos Islands", group ==
                                       "Ilhas Virgens, Britânicas" ~ "British Virgin Islands", group ==
                                       "Ilhas Virgens, EUA" ~ "United States Virgin Islands", group ==
                                       "Ilhas Wallis e Futuna" ~ "Wallis and Futuna", group ==
                                       "Índia" ~ "India", group ==
                                       "Indonésia" ~ "Indonesia", group ==
                                       "Irã" ~ "Iran", group ==
                                       "Iraque" ~ "Iraq", group ==
                                       "Irlanda" ~ "Ireland", group ==
                                       "Islândia" ~ "Iceland", group ==
                                       "Israel" ~ "Israel", group ==
                                       "Itália" ~ "Italy", group ==
                                       "Jamaica" ~ "Jamaica", group ==
                                       "Japão" ~ "Japan", group ==
                                       "Jersey" ~ "Jersey", group ==
                                       "Jordânia" ~ "Jordan", group ==
                                       "Kiribati" ~ "Kiribati", group ==
                                       "Kuwait" ~ "Kuwait", group ==
                                       "Laos" ~ "Laos", group ==
                                       "Lesoto" ~ "Lesotho", group ==
                                       "Letônia" ~ "Latvia", group ==
                                       "Líbano" ~ "Lebanon", group ==
                                       "Libéria" ~ "Liberia", group ==
                                       "Líbia" ~ "Libya", group ==
                                       "Liechtenstein" ~ "Liechtenstein", group ==
                                       "Lituânia" ~ "Lithuania", group ==
                                       "Luxemburgo" ~ "Luxembourg", group ==
                                       "Macau" ~ "Macau", group ==
                                       "Macedônia" ~ "Macedonia", group ==
                                       "Madagascar" ~ "Madagascar", group ==
                                       "Malásia" ~ "Malaysia", group ==
                                       "Malawi" ~ "Malawi", group ==
                                       "Mali" ~ "Mali", group ==
                                       "Malta" ~ "Malta", group ==
                                       "Marrocos" ~ "Morocco", group ==
                                       "Martinica" ~ "Martinique", group ==
                                       "Maurício" ~ "Mauritius", group ==
                                       "Mauritânia" ~ "Mauritania", group ==
                                       "Mayotte" ~ "Mayotte", group ==
                                       "México" ~ "Mexico", group ==
                                       "Micronésia" ~ "Micronesia", group ==
                                       "Moçambique" ~ "Mozambique", group ==
                                       "Moldávia" ~ "Moldova", group ==
                                       "Mônaco" ~ "Monaco", group ==
                                       "Mongólia" ~ "Mongolia", group ==
                                       "Montenegro" ~ "Montenegro", group ==
                                       "Montserrat" ~ "Montserrat", group ==
                                       "Myanmar" ~ "Myanmar", group ==
                                       "Namíbia" ~ "Namibia", group ==
                                       "Nauru" ~ "Nauru", group ==
                                       "Nepal" ~ "Nepal", group ==
                                       "Nicarágua" ~ "Nicaragua", group ==
                                       "Níger" ~ "Niger", group ==
                                       "Nigéria" ~ "Nigeria", group ==
                                       "Niue" ~ "Niue", group ==
                                       "Noruega" ~ "Norway", group ==
                                       "Nova Caledônia" ~ "New Caledonia", group ==
                                       "Nova Zelândia" ~ "New Zealand", group ==
                                       "Omã" ~ "Oman", group ==
                                       "Palau" ~ "Palau", group ==
                                       "Palestina" ~ "Palestine", group ==
                                       "Panamá" ~ "Panama", group ==
                                       "Papua-Nova Guiné" ~ "Papua New Guinea", group ==
                                       "Paquistão" ~ "Pakistan", group ==
                                       "Paraguai" ~ "Paraguay", group ==
                                       "Peru" ~ "Peru", group ==
                                       "Polinésia Francesa" ~ "French Polynesia", group ==
                                       "Polônia" ~ "Poland", group ==
                                       "Porto Rico" ~ "Puerto Rico", group ==
                                       "Portugal" ~ "Portugal", group ==
                                       "Quênia" ~ "Kenya", group ==
                                       "Reino Unido" ~ "United Kingdom", group ==
                                       "República Centro-Africana" ~ "Central African Republic", group ==
                                       "República Dominicana" ~ "Dominican Republic", group ==
                                       "República Tcheca" ~ "Czech Republic", group ==
                                       "Reunião" ~ "Réunion", group ==
                                       "Romênia" ~ "Romania", group ==
                                       "Ruanda" ~ "Rwanda", group ==
                                       "Rússia" ~ "Russia", group ==
                                       "Saara Ocidental" ~ "Western Sahara", group ==
                                       "Samoa" ~ "Samoa", group ==
                                       "Samoa Americana" ~ "American Samoa", group ==
                                       "Santa Helena" ~ "Saint Helena", group ==
                                       "Santa Lúcia" ~ "Saint Lucia", group ==
                                       "Santa Sé (Cidade-Estado do Vaticano)" ~ "Vatican City", group ==
                                       "São Bartolomeu" ~ "Saint Barthélemy", group ==
                                       "São Cristóvão e Neves" ~ "Saint Kitts and Nevis", group ==
                                       "São Martinho (França)" ~ "Saint Martin (French part)", group ==
                                       "São Martinho (Países Baixos)" ~ "Sint Maarten (Dutch part)", group ==
                                       "São Tomé e Príncipe" ~ "Sao Tome and Principe", group ==
                                       "São Vicente e Granadinas" ~ "Saint Vincent and the Grenadines", group ==
                                       "Senegal" ~ "Senegal", group ==
                                       "Serra Leoa" ~ "Sierra Leone", group ==
                                       "Sérvia" ~ "Serbia", group ==
                                       "Seychelles" ~ "Seychelles", group ==
                                       "Síria" ~ "Syria", group ==
                                       "Somália" ~ "Somalia", group ==
                                       "Sri Lanka" ~ "Sri Lanka", group ==
                                       "Suazilândia" ~ "Eswatini", group ==
                                       "Sudão" ~ "Sudan", group ==
                                       "Suécia" ~ "Sweden", group ==
                                       "Suíça" ~ "Switzerland", group ==
                                       "Suriname" ~ "Suriname", group ==
                                       "Svalbard e Jan Mayen" ~ "Svalbard and Jan Mayen", group ==
                                       "Tadjiquistão" ~ "Tajikistan", group ==
                                       "Tailândia" ~ "Thailand", group ==
                                       "Taiwan" ~ "Taiwan", group ==
                                       "Tanzânia" ~ "Tanzania", group ==
                                       "Terras Austrais e Antárticas Francesas" ~ "French Southern Territories", group ==
                                       "Território Britânico do Oceano Índico" ~ "British Indian Ocean Territory", group ==
                                       "Timor-Leste" ~ "Timor-Leste", group ==
                                       "Togo" ~ "Togo", group ==
                                       "Tokelau" ~ "Tokelau", group ==
                                       "Tonga" ~ "Tonga", group ==
                                       "Trinidad e Tobago" ~ "Trinidad and Tobago", group ==
                                       "Tunísia" ~ "Tunisia", group ==
                                       "Turquemenistão" ~ "Turkmenistan", group ==
                                       "Turquia" ~ "Turkey", group ==
                                       "Tuvalu" ~ "Tuvalu", group ==
                                       "Ucrânia" ~ "Ukraine", group ==
                                       "Uganda" ~ "Uganda", group ==
                                       "Uruguai" ~ "Uruguay", group ==
                                       "Uzbequistão" ~ "Uzbekistan", group ==
                                       "Vanuatu" ~ "Vanuatu", group ==
                                       "Venezuela" ~ "Venezuela", group ==
                                       "Vietnã" ~ "Vietnam", group ==
                                       "Zâmbia" ~ "Zambia", group ==
                                       "Zimbábue" ~ "Zimbabwe"))
      
      
  }
  
  server <- function(input, session) {
      browser()
    # Cria opções para seleção de grupos
    param$filter_choices <- sort(unique(df$group))
    param$filter_choices <- param$filter_choices[which(param$filter_choices != " - ")]

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      # se input está vazio preenche com valor aleatório da lista de colunas
      if (input$x == "") {
        updateSelectInput(session, "x",
          choices = param$x_choices,
          selected = sample(param$x_cols$var, 1)
        )
      }

      if (input$color == "") {
        updateSelectInput(session, "color",
          choices = param$color_choices,
          selected = sample(param$color_cols$var, 1)
        )
      }
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "x=", input$x,
        "&", "color=", input$color
      )
      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["x"]])) {
        # se tem x na url atribui valor ao selecinput x
        updateSelectInput(session, "x",
          choices = param$x_choices,
          selected = query[["x"]]
        )
      }

      if (!is.null(query[["color"]])) {
        updateSelectInput(session, "color",
          choices = param$color_choices,
          selected = query[["color"]]
        )
      }
    }


    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$x) || input$x == "" ||
        is.null(input$color) || input$color == "") {
        text <- param$server1
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- param$table[which(param$table$var == input$x), ]

        text <- paste0(param$server2, x_col$label)
      }

      text
    })
    output$plot_subtitle <- renderText({
      text <- " "

      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$color) || input$color == "") {
        text <- " "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        color_col <- param$table[which(param$table$var == input$color), ]
        text <- paste0(param$server3)
      }

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
          if (is.null(input$x) || input$x == "" ||
            is.null(input$color) || input$color == "") {
            fig <- plotly_empty()
            stop()
          }

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          x_col <- param$table[which(param$table$var == input$x), ]
          color_col <- param$table[which(param$table$var == input$color), ]
          slider_col <- param$table[which(param$table$var == param$slider_def), ]
          text_col <- param$table[which(param$table$var == param$text_def), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]

          # Cria coluna vazia para o ranking
          y_col <- list()
          y_col$var <- "rank"
          y_col$label <- "Ranking"

          df_p <- data.frame(
            df[x_col$var],
            NA,
            df[color_col$var],
            df[slider_col$var],
            df["group"],
            df["group"],
            df[id_col$var]
          )

          colnames(df_p) <- c("x", "y", "color", "slider", "text", "group", "id")

          # Filtra colunas onde variáveis são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$color)), ]

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Filtra sem grupo
          df_p <- df_p[which(df_p$group != " - "), ]

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
          top_n <- 10
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

          if (!is.numeric(df_p$color)) {
            # adiciona barra sem split para a legenda
            fig_p <- fig_p %>% add_segments(
              hoverinfo = "none",
              showlegend = TRUE,
              x = 0,
              xend = 0,
              y = ~y,
              yend = ~y,
              color = ~color,
              line = list(width = 30),
              opacity = 0.7
            )
          } else {
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
                        transition = list(duration = 1500, easing = "linear", redraw = TRUE),
                        fromcurrent = TRUE,
                        frame = list(redraw = TRUE, duration = 1500)
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
              showlegend = TRUE,
              legend = list(title = list(text = color_col$label)),
              hoverlabel = tooltip
            )

          fig <- fig %>% animation_opts(
            1500,
            easing = "linear", redraw = FALSE
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
    }) %>%
      bindCache(input$x, input$color)

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
