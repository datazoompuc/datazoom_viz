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
    
    if(param$lang){
        df<-df %>%
            rename("Weapons and ammunition; their parts and accessories" =
                       "Armas e munições; suas partes e acessórios",
                   "Footwear, hats, and similar articles; umbrellas, parasols, walking sticks,
                 whips" = "Calçado, chapéus e artefatos de uso semelhante, guarda-chuvas, guarda-sóis, bengalas, chicotes",
                   "Animal or vegetable fats and oils; products of their cleavage; edible fats" = "Gorduras e óleos animais ou vegetais; Produtos da sua dossociação; Gorduras alimentares elabor",
                   "Optical, photographic, cinematographic, measuring, control or precision instruments and apparatus" = "Instrumentos e aparelhos de ótica, fotografia ou cinematografia, medida, controle ou de precis",
                   "Wood, charcoal, and wood articles; cork and articles of cork; basketware and wickerwork" = "Madeira, carvão vegetal e obras de madeira; Cortiça e suas obras; Obras de espartaria ou de ce",
                   "Machinery and mechanical appliances; electrical equipment; parts thereof; sound recorders and reproducers" = "Máquinas e aparelhos, material elétrico e suas partes; Aparelhos de gravação ou reprodução de ",
                   "Transportation equipment" = "Material de transporte",
                   "Textiles and textile articles" = "Matérias têxteis e suas obras",
                   "Miscellaneous manufactured articles" = "Mercadorias e produtos diversos",
                   "Base metals and articles of base metal" = "Metais comuns e suas obras",
                   "Works of art, collectors' pieces, and antiques" = "Objetos de arte, de coleção e antiguidades",
                   "Stone, plaster, cement, asbestos, mica, or similar materials; ceramic products" = "Obras de pedra, gesso, cimento, amianto, mica ou de matérias semelhantes; Produtos cerâmicos; ",
                   "Wood pulp or other fibrous cellulose material; recovered (waste and scrap) paper or paperboard" = "Pastas de madeira ou de outras matérias fibrosas celulósicas; Papel ou cartão para reciclar (d",
                   "Skins and other parts of birds, with their feathers or down; articles of leather or of composition leather" = "Peles, couros, peles com pelo e obras destas matérias; Artigos de correeiro ou de seleiro; Art",
                   "Natural or cultured pearls, precious or semi-precious stones, precious metals" = "Pérolas naturais ou cultivadas, pedras preciosas ou semipreciosas e semelhantes, metais precio",
                   "Plastics and articles thereof; rubber and articles thereof" = "Plásticos e suas obras; Borracha e suas obras",
                   "Chemical or allied industries products" = "Produtos das indústrias químicas ou indústrias conexas",
                   "Food industry products; beverages, spirits, and vinegar; tobacco" = "Produtos das indútrias alimentares; Bebidas, líquidos alcoólicos e vinagres; Tabaco e seus suc",
                   "Vegetable products" = "Produtos do reino vegetal",
                   "Mineral products" = "Produtos minerais",
                   "Special transactions" = "Transações especiais") %>% 
          mutate(group = case_when(
            group == "Afeganistão"               ~ "Afghanistan",
            group == "África do Sul"             ~ "South Africa",
            group == "Albânia"                   ~ "Albania",
            group == "Alemanha"                  ~ "Germany",
            group == "Andorra"                   ~ "Andorra",
            group == "Angola"                    ~ "Angola",
            group == "Anguilla"                  ~ "Anguilla",
            group == "Antígua e Barbuda"         ~ "Antigua and Barbuda",
            group == "Antilhas Holandesas"       ~ "Netherlands Antilles",
            group == "Arábia Saudita"            ~ "Saudi Arabia",
            group == "Argélia"                   ~ "Algeria",
            group == "Argentina"                 ~ "Argentina",
            group == "Armênia"                   ~ "Armenia",
            group == "Aruba"                     ~ "Aruba",
            group == "Austrália"                 ~ "Australia",
            group == "Áustria"                   ~ "Austria",
            group == "Azerbaijão"                ~ "Azerbaijan",
            group == "Bahamas"                   ~ "Bahamas",
            group == "Bahrein"                   ~ "Bahrain",
            group == "Bangladesh"                ~ "Bangladesh",
            group == "Barbados"                  ~ "Barbados",
            group == "Belarus"                   ~ "Belarus",
            group == "Bélgica"                   ~ "Belgium",
            group == "Belize"                    ~ "Belize",
            group == "Benin"                     ~ "Benin",
            group == "Bermudas"                  ~ "Bermuda",
            group == "Bolívia"                   ~ "Bolivia",
            group == "Bonaires, Saint Eustatius e Saba" ~ "Bonaire, Sint Eustatius and Saba",
            group == "Bósnia-Herzegovina"        ~ "Bosnia and Herzegovina",
            group == "Botsuana"                  ~ "Botswana",
            group == "Bouvet, Ilha"              ~ "Bouvet Island",
            group == "Brasil"                    ~ "Brazil",
            group == "Brunei"                    ~ "Brunei",
            group == "Bulgária"                  ~ "Bulgaria",
            group == "Burkina Faso"              ~ "Burkina Faso",
            group == "Cabo Verde"                ~ "Cape Verde",
            group == "Camarões"                  ~ "Cameroon",
            group == "Camboja"                   ~ "Cambodia",
            group == "Canadá"                    ~ "Canada",
            group == "Canárias, Ilhas"           ~ "Canary Islands",
            group == "Catar"                     ~ "Qatar",
            group == "Cayman, Ilhas"             ~ "Cayman Islands",
            group == "Cazaquistão"               ~ "Kazakhstan",
            group == "Chade"                     ~ "Chad",
            group == "Chile"                     ~ "Chile",
            group == "China"                     ~ "China",
            group == "Chipre"                    ~ "Cyprus",
            group == "Cingapura"                 ~ "Singapore",
            group == "Colômbia"                  ~ "Colombia",
            group == "Comores"                   ~ "Comoros",
            group == "Congo"                     ~ "Congo",
            group == "Cook, Ilhas"               ~ "Cook Islands",
            group == "Coreia do Norte"           ~ "North Korea",
            group == "Coreia do Sul"             ~ "South Korea",
            group == "Costa do Marfim"           ~ "Ivory Coast",
            group == "Costa Rica"                ~ "Costa Rica",
            group == "Croácia"                   ~ "Croatia",
            group == "Cuba"                      ~ "Cuba",
            group == "Curaçao"                   ~ "Curaçao",
            group == "Dinamarca"                 ~ "Denmark",
            group == "Djibuti"                   ~ "Djibouti",
            group == "Dominica"                  ~ "Dominica",
            group == "Egito"                     ~ "Egypt",
            group == "El Salvador"               ~ "El Salvador",
            group == "Emirados Árabes Unidos"    ~ "United Arab Emirates",
            group == "Equador"                   ~ "Ecuador",
            group == "Eslováquia"                ~ "Slovakia",
            group == "Eslovênia"                 ~ "Slovenia",
            group == "Espanha"                   ~ "Spain",
            group == "Estados Unidos"            ~ "United States",
            group == "Estônia"                   ~ "Estonia",
            group == "Eswatini (antiga Suazilândia)" ~ "Eswatini (formerly Swaziland)",
            group == "Etiópia"                   ~ "Ethiopia",
            group == "Falkland (Malvinas)"       ~ "Falkland Islands (Malvinas)",
            group == "Faroe, Ilhas"              ~ "Faroe Islands",
            group == "Fiji"                      ~ "Fiji",
            group == "Filipinas"                 ~ "Philippines",
            group == "Finlândia"                 ~ "Finland",
            group == "França"                    ~ "France",
            group == "Gabão"                     ~ "Gabon",
            group == "Gâmbia"                    ~ "Gambia",
            group == "Gana"                      ~ "Ghana",
            group == "Geórgia"                   ~ "Georgia",
            group == "Gibraltar"                 ~ "Gibraltar",
            group == "Granada"                   ~ "Grenada",
            group == "Grécia"                    ~ "Greece",
            group == "Guadalupe"                 ~ "Guadeloupe",
            group == "Guatemala"                 ~ "Guatemala",
            group == "Guiana"                    ~ "Guyana",
            group == "Guiana Francesa"           ~ "French Guiana",
            group == "Guiné"                     ~ "Guinea",
            group == "Guiné-Bissau"              ~ "Guinea-Bissau",
            group == "Guiné Equatorial"          ~ "Equatorial Guinea",
            group == "Haiti"                     ~ "Haiti",
            group == "Honduras"                  ~ "Honduras",
            group == "Hong Kong"                 ~ "Hong Kong",
            group == "Hungria"                   ~ "Hungary",
            group == "Iêmen"                     ~ "Yemen",
            group == "Índia"                     ~ "India",
            group == "Indonésia"                 ~ "Indonesia",
            group == "Irã"                       ~ "Iran",
            group == "Iraque"                    ~ "Iraq",
            group == "Irlanda"                   ~ "Ireland",
            group == "Islândia"                  ~ "Iceland",
            group == "Israel"                    ~ "Israel",
            group == "Itália"                    ~ "Italy",
            group == "Jamaica"                   ~ "Jamaica",
            group == "Japão"                     ~ "Japan",
            group == "Jordânia"                  ~ "Jordan",
            group == "Kuweit (Coveite)"          ~ "Kuwait",
            group == "Laos"                      ~ "Laos",
            group == "Lesoto"                    ~ "Lesotho",
            group == "Letônia"                   ~ "Latvia",
            group == "Líbano"                    ~ "Lebanon",
            group == "Libéria"                   ~ "Liberia",
            group == "Líbia"                     ~ "Libya",
            group == "Liechtenstein"             ~ "Liechtenstein",
            group == "Lituânia"                  ~ "Lithuania",
            group == "Luxemburgo"                ~ "Luxembourg",
            group == "Macau"                     ~ "Macau",
            group == "Macedônia do norte"        ~ "North Macedonia",
            group == "Madagascar"                ~ "Madagascar",
            group == "Madeira, Ilha da"          ~ "Madeira Island",
            group == "Malásia"                   ~ "Malaysia",
            group == "Malavi"                    ~ "Malawi",
            group == "Maldivas"                  ~ "Maldives",
            group == "Mali"                      ~ "Mali",
            group == "Malta"                     ~ "Malta",
            group == "Man, Ilha de"              ~ "Isle of Man",
            group == "Marrocos"                  ~ "Morocco",
            group == "Marshall, Ilhas"           ~ "Marshall Islands",
            group == "Martinica"                 ~ "Martinique",
            group == "Maurício"                  ~ "Mauritius",
            group == "Mauritânia"                ~ "Mauritania",
            group == "México"                    ~ "Mexico",
            group == "Mianmar"                   ~ "Myanmar",
            group == "Midway, Ilhas"             ~ "Midway Islands",
            group == "Moçambique"                ~ "Mozambique",
            group == "Moldávia"                  ~ "Moldova",
            group == "Mônaco"                    ~ "Monaco",
            group == "Mongólia"                  ~ "Mongolia",
            group == "Montenegro"                ~ "Montenegro",
            group == "Namíbia"                   ~ "Namibia",
            group == "Nepal"                     ~ "Nepal",
            group == "Nicarágua"                 ~ "Nicaragua",
            group == "Níger"                     ~ "Niger",
            group == "Nigéria"                   ~ "Nigeria",
            group == "Norfolk, Ilha"             ~ "Norfolk Island",
            group == "Noruega"                   ~ "Norway",
            group == "Nova Caledônia"            ~ "New Caledonia",
            group == "Nova Zelândia"             ~ "New Zealand",
            group == "Omã"                       ~ "Oman",
            group == "Pacífico, Ilhas do (EUA)"  ~ "Pacific Islands (U.S.)",
            group == "Países Baixos (Holanda)"   ~ "Netherlands (Holland)",
            group == "Palau"                     ~ "Palau",
            group == "Palestina"                 ~ "Palestine",
            group == "Panamá"                    ~ "Panama",
            group == "Papua Nova Guiné"          ~ "Papua New Guinea",
            group == "Paquistão"                 ~ "Pakistan",
            group == "Paraguai"                  ~ "Paraguay",
            group == "Peru"                      ~ "Peru",
            group == "Polinésia Francesa"        ~ "French Polynesia",
            group == "Polônia"                   ~ "Poland",
            group == "Porto Rico"                ~ "Puerto Rico",
            group == "Portugal"                  ~ "Portugal",
            group == "Quênia"                    ~ "Kenya",
            group == "Quirguistão"               ~ "Kyrgyzstan",
            group == "Reino Unido"               ~ "United Kingdom",
            group == "República Centro-Africana" ~ "Central African Republic",
            group == "República Democrática do Congo" ~ "Democratic Republic of the Congo",
            group == "República Dominicana"      ~ "Dominican Republic",
            group == "República Tcheca"          ~ "Czech Republic",
            group == "Reunião"                   ~ "Réunion",
            group == "Romênia"                   ~ "Romania",
            group == "Ruanda"                    ~ "Rwanda",
            group == "Rússia"                    ~ "Russia",
            group == "Saara Ocidental"           ~ "Western Sahara",
            group == "Salomão, Ilhas"            ~ "Solomon Islands",
            group == "San Marino"                ~ "San Marino",
            group == "Santa Helena"              ~ "Saint Helena",
            group == "Santa Lúcia"               ~ "Saint Lucia",
            group == "São Cristóvão e Névis"     ~ "Saint Kitts and Nevis",
            group == "São Martinho, ilha de (parte francesa)" ~ "Saint Martin (French part)",
            group == "São Martinho, ilha de (parte holandesa)" ~ "Sint Maarten (Dutch part)",
            group == "São Tomé e Príncipe"       ~ "São Tomé and Príncipe",
            group == "São Vicente e Granadinas"  ~ "Saint Vincent and the Grenadines",
            group == "Senegal"                   ~ "Senegal",
            group == "Serra Leoa"                ~ "Sierra Leone",
            group == "Sérvia"                    ~ "Serbia",
            group == "Seychelles"                ~ "Seychelles",
            group == "Síria"                     ~ "Syria",
            group == "Somália"                   ~ "Somalia",
            group == "Sri Lanka"                 ~ "Sri Lanka",
            group == "Sudão"                     ~ "Sudan",
            group == "Suécia"                    ~ "Sweden",
            group == "Suíça"                     ~ "Switzerland",
            group == "Suriname"                  ~ "Suriname",
            group == "Tailândia"                 ~ "Thailand",
            group == "Taiwan (Formosa)"          ~ "Taiwan",
            group == "Tanzânia"                  ~ "Tanzania",
            group == "Território Britânico do Oceano Índico" ~ "British Indian Ocean Territory",
            group == "Togo"                      ~ "Togo",
            group == "Tonga"                     ~ "Tonga",
            group == "Trinidad e Tobago"         ~ "Trinidad and Tobago",
            group == "Tunísia"                   ~ "Tunisia",
            group == "Turcas e Caicos, Ilhas"    ~ "Turks and Caicos Islands",
            group == "Turcomenistão"             ~ "Turkmenistan",
            group == "Turquia"                   ~ "Turkey",
            group == "Tuvalu"                    ~ "Tuvalu",
            group == "Ucrânia"                   ~ "Ukraine",
            group == "Uganda"                    ~ "Uganda",
            group == "Uruguai"                   ~ "Uruguay",
            group == "Uzbequistão"               ~ "Uzbekistan",
            group == "Vanuatu"                   ~ "Vanuatu",
            group == "Venezuela"                 ~ "Venezuela",
            group == "Vietnã"                    ~ "Vietnam",
            group == "Virgens, Ilhas (Americanas)" ~ "Virgin Islands (U.S.)",
            group == "Virgens, Ilhas (Britânicas)" ~ "Virgin Islands (British)",
            group == "Wallis e Futuna, Ilhas"    ~ "Wallis and Futuna Islands",
            group == "Zâmbia"                    ~ "Zambia",
            group == "Zimbábue"                  ~ "Zimbabwe"
          ))
        
    }
    
    
    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      selected <- sample(sample(param$y_choices, 1)[[1]], 1)
      updateSelectInput(session,
        "y",
        choices = param$y_choices,
        selected = param$y_def
      )
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

      if (!is.null(query[["y"]])) {
        updateSelectInput(session, "y",
          choices = param$y_choices,
          selected = query[["y"]]
        )
      }

      # Se query está vazia, preenche aleatório
      if (is.null(query[["y"]])) {
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
        # Monta titulo a partir de variáveis selecionadas nos inputs
        y_col <- param$table[which(param$table$var == input$y), ]

        text <- paste0("", y_col$label)
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

          y_col <- param$table[which(param$table$var == input$y), ]
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
            dp[order(-dp$y), ]
          }

          # Constrói os nós/links do sankey para um data.frame de um ano
          build_nodes_links <- function(dp) {
            n <- nrow(dp)
            cores <- c(pallete[4], rep(pallete[3], 5), rep(pallete[2], 5),
                       rep(pallete[1], max(0, n - 10)))
            cores <- cores[1:(n + 1)]
            list(
              node = list(
                label = c("Amazônia", dp$group),
                color = cores,
                hovertemplate = "<b> %{label} </b>",
                pad = 15, thickness = 10,
                line = list(color = "black", width = 0.5),
                x = c(-0.001, rep(NA, n)),
                y = c(0.5, rep(NA, n))
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
            valueformat = ".2f",
            valuesuffix = paste0(" (", param$unit, y_col$unidade, ") "),
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
                currentvalue = list(prefix = paste0(param$label_x_name, ": "), font = f1),
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
