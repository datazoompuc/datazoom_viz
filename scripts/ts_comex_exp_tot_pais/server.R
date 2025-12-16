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
    
    # Carrega índice de preços anual
    indice <- read.csv("data/indice_precos_anual.csv",
                       stringsAsFactors = FALSE)
    
    # Garante tipos e nomes compatíveis com o df principal
    indice$time <- as.integer(indice$CO_ANO)
    indice$indice_anual_base1998 <- as.numeric(indice$indice_anual_base1998)
    indice <- indice[, c("time", "indice_anual_base1998")]
    
    #######
    #Translating country names
    if(param$lang){
        
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
                                         "Bonaires, Saint Eustatius e Saba" ~ "Bonaire, Saint Eustatius and Saba", group ==
                                         "Bósnia-Herzegovina" ~ "Bosnia and Herzegovina", group ==
                                         "Botsuana" ~ "Botswana", group ==
                                         "Bouvet, Ilha" ~ "Bouvet Island", group ==
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
    
    # Cria opções para seleção de grupos
    param$filter_choices <- sort(unique(df$group))
    param$filter_choices <- param$filter_choices[which(param$filter_choices != " - ")]

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      updateSelectInput(session,
        "filter1",
        choices = param$filter_choices,
        selected = sample(param$filter_choices, 3) # numero de parametros aleatórios que são escolhidos na geração do gráfico
      )

    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "&", "y_option=", param$y_def
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
      updateSelectInput(session,
        "filter1",
        choices = param$filter_choices,
        selected = NULL
      )

      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["y"]])) {
        updateSelectInput(session, "y",
          choices = param$y_choices,
          selected = query[["y"]]
        )
      }

      if (!is.null(query[["ylog"]])) {
        updateCheckboxInput(session, "ylog",
          value = (query[["ylog"]] == "TRUE")
        )
      }



      selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
      if (!is.null(query[["filter"]])) {
        updateSelectInput(session,
          "filter1",
          choices = param$filter_choices,
          selected = selected
        )
      }

      # Se query está vazia, preenche aleatório
      if (is.null(query[["filter"]]) && is.null(query[["y"]])) {
        random_inputs() # preenche inputs se estiverem vazios
      }
    }

    # Output titulo do gráfico
    output$plot_title <- renderText({
      text <- param$plot_title
      
      text
    })
    output$plot_subtitle <- renderText({
        if (is.null(param$y_def) || param$y_def == "") 
            return("")
        
        
        if (isTRUE(input$y_option) && isTRUE(input$ydefl)) {
            paste0(param$ylabel_deflator, " ", param$label_prop)
            
        } else if (isTRUE(input$y_option)) {
            paste0(param$currency, " ", param$label_prop)
        
        } else if (isTRUE(input$ydefl)) {
            paste0(param$currency, param$subtitle_deflator)
        } else {
            param$currency
        }
    })

    # Output gráfico
    output$plot <- renderPlotly({
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco
      tryCatch(
        {
          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(param$y_def) || param$y_def == "" ||
            is.null(input$filter1) || length(input$filter1) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          # Cria dataframe do gráfico
          x_col <- param$table[which(param$table$var == param$x_def), ]
          y_col <- param$table[which(param$table$var == param$y_def), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]
          color_col <- param$table[which(param$table$var == param$color_def), ]

          # Filtra dataframe com grupos selecionados
          df_filtered <- df[which(df$group %in% input$filter1), ]
          
          # Decide qual variável vai para o eixo Y:
          #   - nominal (original) quando ydefl == FALSE
          #   - deflacionada quando ydefl == TRUE
          y_var <- y_col$var  # padrão: coluna original
          
          if (isTRUE(input$ydefl)) {
              # Remove anos sem índice (ex.: 1997)
              df_filtered <- df_filtered[df_filtered$time >= 1998, ]
              
              # Anexa o índice via match, sem mudar ordem nem número de linhas
              df_filtered$indice_anual_base1998 <- indice$indice_anual_base1998[
                  match(df_filtered$time, indice$time)
              ]
              
              # Se por algum motivo faltar índice para algum ano, joga fora
              df_filtered <- df_filtered[!is.na(df_filtered$indice_anual_base1998), ]
              
              # Cria uma coluna nova deflacionada (US$ de 1998)
              df_filtered$y_defl <- df_filtered[[y_col$var]] *
                  (100 / df_filtered$indice_anual_base1998)
              
              y_var <- "y_defl"
          }

          df_p <- data.frame(
            df_filtered[x_col$var],
            df_filtered[[y_var]],
            df_filtered[color_col$var]
          )
          colnames(df_p) <- c("x", "y", "color")
          df_p$group <- df_filtered$group
          df_p$text <- df_p$group
          
          if (isTRUE(input$y_option)) {
              # garante ordem por país e ano
              df_p <- df_p[order(df_p$group, df_p$x), ]
              
              # Proporcional ao ano inicial (índice 100)
              df_p <- df_p %>%
                  group_by(group) %>%
                  mutate(
                      y = 100 * y / first(na.omit(y))
                  ) %>%
                  ungroup()
          }

          # Filtra colunas onde x,y e size são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y)), ]
          

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }


          # Se a coluna de cor for toda NA, preenche com strings em branco
          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }
          
          measurement_label <- case_when(
          isTRUE(input$y_option) ~ param$label_prop,  # índice, sem unidade monetária
          isTRUE(input$ydefl)    ~ param$ylabel_deflator,
          TRUE                   ~ param$measurement
          )
          

          # Monta html do tooltip
          df_p$tooltip <- paste0(
              "<b>", df_p$text, "</b><br>",
              x_col$label, ": ", df_p$x, "<br>",
              y_col$label, " (", measurement_label, "): ",
              format(df_p$y,
                     scientific   = FALSE,
                     digits       = 2,
                     decimal.mark = ",",
                     big.mark     = "."),
              "<br>"
          )

          # Define paleta de cores
          pallete <- pallete_discrete

          # Monta gráfico
          fig_p <- plot_ly(df_p,
            x = ~x,
            y = ~y,
            color = ~group,
            type = "scatter",
            mode = "lines",
            text = ~tooltip,
            hovertemplate = ~tooltip
          )

          # Layout eixos
          x_axis_layout <- list(
            title = x_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )
          y_axis_layout <- list(
            title = y_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )

          if (input$ylog & is.numeric(df_p$y)) {
              y_axis_layout$type <- "log"
          }
          
          label_defl_suffix <- if (isTRUE(input$ydefl)) paste0(" (", param$ylabel_deflator, ")") else ""
          
          label_prop_suffix <- if (isTRUE(input$y_option)) paste0(" (", param$label_prop, ")") else ""
          
          
          y_axis_layout$title <- paste0(y_col$label, label_defl_suffix, label_prop_suffix)
          
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
              showlegend = TRUE
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
