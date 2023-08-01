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

    # Traduz opções de seleção
    if(param$lang){
        df <- df %>% 
            mutate(group = case_when(group == "Açúcares e produtos de confeitaria" ~ "Sugar and Confectionery Products", group ==
                                         "Adubos (fertilizantes)" ~ "Fertilizers", group ==
                                         "Aeronaves e aparelhos espaciais, e suas partes" ~ "Aircraft and Spacecraft, and their parts", group ==
                                         "Algodão" ~ "Cotton", group ==
                                         "Alumínio e suas obras" ~ "Aluminum and its works", group ==
                                         "Animais vivos" ~ "Live Animals", group ==
                                         "Armas e munições; suas partes e acessórios" ~ "Arms and Ammunition; their parts and accessories", group ==
                                         "Artigos de relojoaria" ~ "Clocks and Watches", group ==
                                         "Bebidas, líquidos alcoólicos e vinagres" ~ "Beverages, alcoholic liquids, and vinegars", group ==
                                         "Borracha e suas obras" ~ "Rubber and its works", group ==
                                         "Brinquedos, jogos, artigos para divertimento ou para esporte; suas partes e acessórios" ~ "Toys, games, and sports equipment; their parts and accessories", group ==
                                         "Cacau e suas preparações" ~ "Cocoa and its preparations", group ==
                                         "Café, chá, mate e especiarias" ~ "Coffee, tea, mate, and spices", group ==
                                         "Calçados, polainas e artefatos semelhantes; suas partes" ~ "Footwear, leggings, and similar articles; their parts", group ==
                                         "Carnes e miudezas, comestíveis" ~ "Meat and edible offal", group ==
                                         "Cereais" ~ "Cereals", group ==
                                         "Chapéus e artefatos de uso semelhante, e suas partes" ~ "Hats and similar articles; their parts", group ==
                                         "Chumbo e suas obras" ~ "Lead and its works", group ==
                                         "Cobre e suas obras" ~ "Copper and its works", group ==
                                         "Combustíveis minerais, óleos minerais e produtos da sua destilação; matérias betuminosas; ceras minerais" ~ "Mineral fuels, mineral oils, and products of their distillation; bituminous substances; mineral waxes", group ==
                                         "Cortiça e suas obras" ~ "Cork and its works", group ==
                                         "Embarcações e estruturas flutuantes" ~ "Ships and floating structures", group ==
                                         "Estanho e suas obras" ~ "Tin and its works", group ==
                                         "Extratos tanantes e tintoriais; taninos e seus derivados; pigmentos e outras matérias corantes; tintas e vernizes; mástiques; tintas de escrever" ~ "Tanning and dyeing extracts; tannins and their derivatives; pigments and other coloring matter; paints and varnishes; putty and inks", group ==
                                         "Ferramentas, artefatos de cutelaria e talheres, e suas partes, de metais comuns" ~ "Tools, cutlery, and tableware; their parts, of base metal", group ==
                                         "Ferro fundido, ferro e aço" ~ "Iron and steel", group ==
                                         "Fibras sintéticas ou artificiais, descontínuas" ~ "Synthetic or artificial staple fibers", group ==
                                         "Filamentos sintéticos ou artificiais" ~ "Synthetic or artificial filament", group ==
                                         "Frutas; cascas de frutos cítricos e de melões" ~ "Fruits; citrus and melon peels", group ==
                                         "Gomas, resinas e outros sucos e extratos vegetais" ~ "Gums, resins, and other vegetable saps and extracts", group ==
                                         "Gorduras e óleos animais ou vegetais; produtos da sua dissociação; gorduras alimentares elaboradas; ceras de origem animal ou vegetal" ~ "Animal or vegetable fats and oils; their cleavage products; prepared edible fats; animal or vegetable waxes", group ==
                                         "Guarda-chuvas, sombrinhas, guarda-sóis, bengalas, bengalas-assentos, chicotes, pingalins, e suas partes" ~ "Umbrellas, sun umbrellas, walking-sticks, seat-sticks, whips, riding-crops, and parts thereof", group ==
                                         "Instrumentos e aparelhos de óptica, de fotografia, de cinematografia, de medida, de controle ou de precisão; instrumentos e aparelhos médico-cirúrgicos; suas partes e acessórios" ~ "Optical, photographic, cinematographic, measuring, checking, precision, medical or surgical instruments and apparatus; parts and accessories thereof", group ==
                                         "Instrumentos musicais; suas partes e acessórios" ~ "Musical instruments; their parts and accessories", group ==
                                         "Lã, pelos finos ou grosseiros; fios e tecidos de crina" ~ "Wool, fine or coarse animal hair; horsehair yarn and woven fabric", group ==
                                         "Leite e lacticínios; ovos de aves; mel natural; produtos comestíveis de origem animal, não especificados nem compreendidos noutros Capítulos" ~ "Milk and dairy products; eggs of birds; natural honey; edible products of animal origin, not elsewhere specified or included", group ==
                                         "Livros, jornais, gravuras e outros produtos das indústrias gráficas; textos manuscritos ou datilografados, planos e plantas" ~ "Books, newspapers, pictures and other products of the printing industry; manuscripts, typescripts, and plans", group ==
                                         "Madeira, carvão vegetal e obras de madeira" ~ "Wood, charcoal, and wood products", group ==
                                         "Máquinas, aparelhos e materiais elétricos, e suas partes; aparelhos de gravação ou de reprodução de som, aparelhos de gravação ou de reprodução de imagens e de som em televisão, e suas partes e acessórios" ~ "Electrical machinery and equipment, and parts thereof; sound recorders and reproducers, television image and sound recorders and reproducers, and parts and accessories of such articles", group ==
                                         "Matérias albuminóides; produtos à base de amidos ou de féculas modificados; colas; enzimas" ~ "Albuminoidal substances; modified starches, glues; enzymes", group ==
                                         "Matérias para entrançar e outros produtos de origem vegetal, não especificados nem compreendidos noutros Capítulos" ~ "Plaiting materials and other products of vegetable plaiting materials, not elsewhere specified or included", group ==
                                         "Minerios, escórias e cinzas" ~ "Ores, slag, and ash", group ==
                                         "Móveis; mobiliário médico-cirúrgico, colchões, almofadas e semelhantes; aparelhos de iluminação não especificados nem compreendidos em outros capítulos; anúncios, cartazes ou tabuletas e placas indicadoras luminosos, e artigos semelhantes; Construções Pré" ~ "Furniture; medical, surgical, dental, or veterinary furniture; mattresses and cushions; lamps and lighting fittings, not elsewhere specified or included; illuminated signs, illuminated nameplates, and the like; prefabricated buildings", group ==
                                         "Níquel e suas obras" ~ "Nickel and its works", group ==
                                         "Objetos de arte, de coleção e antiguidades" ~ "Works of art, collectors' pieces, and antiques", group ==
                                         "Obras de couro; artigos de correeiro ou de seleiro; artigos de viagem, bolsas e artefatos semelhantes; obras de tripa" ~ "Leather articles; saddlery and harness; travel goods, handbags, and similar articles; gut (other than silk-worm gut)", group ==
                                         "Obras de espartaria ou de cestaria" ~ "Basketware and wickerwork", group ==
                                         "Obras de ferro fundido, ferro ou aço" ~ "Articles of iron or steel", group ==
                                         "Obras de pedra, gesso, cimento, amianto, mica ou de matérias semelhantes" ~ "Articles of stone, plaster, cement, asbestos, mica, or similar materials", group ==
                                         "Obras diversas" ~ "Miscellaneous articles", group ==
                                         "Obras diversas de metais comuns" ~ "Miscellaneous articles of base metal", group ==
                                         "Óleos essenciais e resinóides; produtos de perfumaria ou de toucador preparados e preparações cosméticas" ~ "Essential oils and resinoids; perfumery, cosmetic, or toilet preparations", group ==
                                         "Outras fibras têxteis vegetais; fios de papel e tecidos de fios de papel" ~ "Other vegetable textile fibers; paper yarn and woven fabrics of paper yarn", group ==
                                         "Outros artefatos têxteis confeccionados; sortidos; artefatos de matérias têxteis, calçados, chapéus e artefatos de uso semelhante, usados; trapos" ~ "Other made-up textile articles; sets; worn clothing and worn textile articles; rags", group ==
                                         "Outros metais comuns; ceramais (cermets); obras dessas matérias" ~ "Other base metals; cermet articles; articles of common metal", group ==
                                         "Outros produtos de origem animal, não especificados nem compreendidos noutros Capítulos" ~ "Other animal products, not elsewhere specified or included", group ==
                                         "Papel e cartão; obras de pasta de celulose, de papel ou de cartão" ~ "Paper and paperboard; articles of paper pulp, paper or paperboard", group ==
                                         "Pastas (ouates), feltros e falsos tecidos; fios especiais; cordéis, cordas e cabos; artigos de cordoaria" ~ "Impregnated, coated, covered or laminated textile fabrics; textile articles of a kind suitable for industrial use; cordage, rope, and cables", group ==
                                         "Pastas de madeira ou de outras matérias fibrosas celulósicas; papel ou cartão para reciclar (desperdícios e aparas)." ~ "Wood pulp or other fibrous cellulosic material; recovered (waste and scrap) paper or paperboard", group ==
                                         "Peixes e crustáceos, moluscos e outros invertebrados aquáticos" ~ "Fish and crustaceans, molluscs, and other aquatic invertebrates", group ==
                                         "Peles com pelo e suas obras; peles com pelo artificiais" ~ "Animal skins with fur; artificial fur skins", group ==
                                         "Peles, exceto as peles com pelo, e couros" ~ "Raw hides and skins, other than fur skins and leather", group ==
                                         "Penas e penugem preparadas e suas obras; flores artificiais; obras de cabelo" ~ "Prepared feathers and down and articles made of feathers or of down; artificial flowers; articles of human hair", group ==
                                         "Pérolas naturais ou cultivadas, pedras preciosas ou semipreciosas e semelhantes, metais preciosos, metais folheados ou chapeados de metais preciosos (plaquê), e suas obras; bijuterias; moedas" ~ "Natural or cultured pearls, precious or semi-precious stones, precious metals, metals clad with precious metal, and articles thereof; imitation jewelry; coin", group ==
                                         "Plantas vivas e produtos de floricultura" ~ "Live trees and other plants; bulbs, roots, and the like; cut flowers and ornamental foliage", group ==
                                         "Plásticos e suas obras" ~ "Plastics and articles thereof", group ==
                                         "Pólvoras e explosivos; artigos de pirotecnia; fósforos; ligas pirofóricas; matérias inflamáveis" ~ "Explosives; pyrotechnic products; matches; pyrophoric alloys; certain combustible preparations", group ==
                                         "Preparações à base de cereais, farinhas, amidos, féculas ou leite; produtos de pastelaria" ~ "Preparations of cereals, flour, starch, or milk; pastrycooks' products", group ==
                                         "Preparações alimentícias diversas" ~ "Miscellaneous edible preparations", group ==
                                         "Preparações de carne, de peixes ou de crustáceos, de moluscos ou de outros invertebrados aquáticos" ~ "Preparations of meat, of fish, or of crustaceans, molluscs or other aquatic invertebrates", group ==
                                         "Preparações de produtos hortícolas, de frutas ou de outras partes de plantas" ~ "Preparations of vegetables, fruit, nuts, or other parts of plants", group ==
                                         "Produtos cerâmicos" ~ "Ceramic products", group ==
                                         "Produtos da indústria de moagem; malte; amidos e féculas; inulina; glúten de trigo" ~ "Milling products; malt; starches; inulin; gluten", group ==
                                         "Produtos diversos das indústrias químicas" ~ "Miscellaneous chemical products", group ==
                                         "Produtos farmacêuticos" ~ "Pharmaceutical products", group ==
                                         "Produtos hortícolas, plantas, raízes e tubérculos, comestíveis." ~ "Edible vegetables and certain roots and tubers", group ==
                                         "Produtos para fotografia e cinematografia" ~ "Photographic or cinematographic goods", group ==
                                         "Produtos químicos inorgânicos; compostos inorgânicos ou orgânicos de metais preciosos, de elementos radioativos, de metais das terras raras ou de isótopos" ~ "Inorganic chemicals; organic or inorganic compounds of precious metals, of rare-earth metals, of radioactive elements, or of isotopes", group ==
                                         "Produtos químicos orgânicos" ~ "Organic chemicals", group ==
                                         "Reatores nucleares, caldeiras, máquinas, aparelhos e instrumentos mecânicos, e suas partes" ~ "Nuclear reactors, boilers, machinery, and mechanical appliances; parts thereof", group ==
                                         "Resíduos e desperdícios das indústrias alimentares; alimentos preparados para animais" ~ "Residues and waste from the food industries; prepared animal fodder", group ==
                                         "Sabões, agentes orgânicos de superfície, preparações para lavagem, preparações lubrificantes, ceras artificiais, ceras preparadas, produtos de conservação e limpeza, velas e artigos semelhantes, massas ou pastas para modelar, \"ceras\" para dentistas e Comp" ~ "Soaps; organic surface-active agents; washing, lubricating, polishing, or scouring preparations; artificial waxes, prepared waxes, polishing or scouring preparations; candles and similar articles, modeling pastes, dental waxes, and dental preparations", group ==
                                         "Sal; enxofre; terras e pedras; gesso, cal e cimento" ~ "Salt; sulfur; earths and stone; plastering materials, lime, and cement", group ==
                                         "Sementes e frutos oleaginosos; grãos, sementes e frutos diversos; plantas industriais ou medicinais; palhas e forragens" ~ "Seeds and oleaginous fruits; miscellaneous grains, seeds, and fruit; industrial or medicinal plants; straw and fodder", group ==
                                         "Tabaco e seus sucedâneos manufaturados" ~ "Tobacco and manufactured tobacco substitutes", group ==
                                         "Tapetes e outros revestimentos para pisos (pavimentos), de matérias têxteis" ~ "Carpets and other textile floor coverings", group ==
                                         "Tecidos de malha" ~ "Knitted or crocheted fabrics", group ==
                                         "Tecidos especiais; tecidos tufados; rendas; tapeçarias; passamanarias; bordados." ~ "Special woven fabrics; tufted textile fabrics; lace; tapestries; trimmings; embroidery", group ==
                                         "Tecidos impregnados, revestidos, recobertos ou estratificados; artigos para usos técnicos de matérias têxteis" ~ "Impregnated, coated, covered, or laminated textile fabrics; textile articles of a kind suitable for industrial use", group ==
                                         "Transações especiais" ~ "Special transactions", group ==
                                         "Veículos automóveis, tratores, ciclos e outros veículos terrestres, suas partes e acessórios" ~ "Vehicles; other than railway or tramway rolling-stock, and parts and accessories thereof", group ==
                                         "Veículos e material para vias férreas ou semelhantes, e suas partes; aparelhos mecânicos (incluindo os eletromecânicos) de sinalização para vias de comunicação" ~ "Vehicles and equipment for railways or similar; signaling devices for roads, waterways, parking facilities, and the like", group ==
                                         "Vestuário e seus acessórios, de malha" ~ "Knitted or crocheted clothing and accessories", group ==
                                         "Vestuário e seus acessórios, exceto de Malha" ~ "Clothing and accessories, not knitted or crocheted", group ==
                                         "Vidro e suas obras" ~ "Glass and glassware", group ==
                                         "Zinco e suas obras" ~ "Zinc and its works"
            ))
    }
    
    
    # Cria opções para seleção de grupos
    param$filter_choices <- sort(unique(df$group))
    param$filter_choices <- param$filter_choices[which(param$filter_choices != " - ")]

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      updateSelectInput(session,
        "filter1",
        choices = param$filter_choices,
        selected = sample(param$filter_choices, 2) # 2 significa o numero de parametros aleatórios que são escolhidos na geração do gráfico
      )

      selected <- sample(sample(param$y_choices, 1)[[1]], 1)
      updateSelectInput(session,
        "y",
        choices = param$y_choices,
        selected = selected
      )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "y=", input$y,
        "&", "ylog=", input$ylog,
        "&", "y_option=", input$y_option
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

      if (!is.null(query[["y_option"]])) {
        updateCheckboxInput(session, "y_option",
          value = (query[["y_option"]] == "TRUE")
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
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$y) || input$y == "") {
        text <- " "
      } else {
        # Monta titulo a partir de variáveis selecionadas nos inputs
        y_col <- param$table[which(param$table$var == input$y), ]

        text <- paste0("", y_col$label)
        if (input$y_option) {
          text <- paste0("", y_col$label, "*")
        }
      }

      text
    })
    output$plot_subtitle <- renderText({
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$y) || input$y == "") {
        text <- " "
      } else {
        text <- paste0("",param$currency,"")
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
          if (is.null(input$y) || input$y == "" ||
            is.null(input$filter1) || length(input$filter1) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          # Cria dataframe do gráfico
          x_col <- param$table[which(param$table$var == param$x_def), ]
          y_col <- param$table[which(param$table$var == input$y), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]
          color_col <- param$table[which(param$table$var == param$color_def), ]

          # Filtra dataframe com grupos selecionados
          df_filtered <- df[which(df$group %in% input$filter1), ]

          df_p <- data.frame(
            df_filtered[x_col$var],
            df_filtered[y_col$var],
            df_filtered[color_col$var]
          )
          colnames(df_p) <- c("x", "y", "color")
          df_p$group <- df_filtered$group
          df_p$text <- df_p$group

          # Filtra colunas onde x,y e size são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y)), ]

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Alternativa de medida para y
          if (input$y_option & is.numeric(df_p$y)) {
            df_p <- df_p %>%
              group_by(df_p$group) %>%
              mutate(
                aux1 = first(y),
                y_option = (y / aux1) * 100
              )
            df_p$y <- df_p$y_option
            param$measurement <- ""
          }

          # Se a coluna de cor for toda NA, preenche com strings em branco
          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }

          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            x_col$label, ": ", df_p$x, "<br>",
            y_col$label, ": ", param$measurement, format(df_p$y, scientific = FALSE,
                                                         digits = 2,
                                                         decimal.mark = ",", 
                                                         big.mark = "."), "<br>"
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

          if (input$y_option) {
            y_axis_layout$title <- paste0(y_col$label, "*")
          }

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
