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
  
  if(param$lang){
      
      df <- df %>% mutate(group = case_when( #######
                                                         #Translating produto_principal variable
                                                         group == 
                                                             "Madeira cortada, desenrolada ou polida" ~ "Cut, unrolled or polished wood", group == 
                                                             "Peixes frescos/refrigerados, exceto filés" ~ "Fresh/chilled fish, except fillets", group == 
                                                             "Estanho em formas brutas" ~ "Tin in crude forms", group == 
                                                             "Sumos de frutas, com ou sem aditivos" ~ "Fruit juices, with or without additives", group == 
                                                             "Minerios de estanho e seus concentrados" ~ "Tin ores and concentrates", group == 
                                                             "Café torrado, cascas e sucedâneos" ~ "Roasted coffee, husks and substitutes", group == 
                                                             "Produtos vegetais nao especificados" ~ "Unspecified vegetable products", group == 
                                                             "Arroz" ~ "Rice", group == 
                                                             "Soja, mesmo triturada" ~ "Soybeans, even crushed", group == 
                                                             "Outros veículos aéreos" ~ "Other aerial vehicles", group == 
                                                             "Farinhas animais impróprias para consumo" ~ "Animal flours unfit for human consumption", group == 
                                                             "Couros e peles curtidos ou em crosta" ~ "Tanned or crust hides and skins", group == 
                                                             "Vestimentas de uso feminino" ~ "Women's clothing", group == 
                                                             "Máquinas para trabalhar couro" ~ "Leather-working machinery", group == 
                                                             "Couros preparados após curtimenta" ~ "Prepared hides after tanning", group == 
                                                             "Vestimentas de malha de uso feminino" ~ "Women's knitted clothing", group == 
                                                             "Aparelhos para circuitos elétricos" ~ "Apparatus for electric circuits", group == 
                                                             "Tractores (exceto os da posicao 8709)" ~ "Tractors (except those of position 8709)", group == 
                                                             "Obras de pérolas e pedras preciosas" ~ "Works of pearls and precious stones", group == 
                                                             "Madeira perfilada, mesmo aplainada" ~ "Profiled wood, even planed", group == 
                                                             "Minérios de manganês e seus concentrados" ~ "Manganese ores and concentrates", group == 
                                                             "Açúcares no estado sólido" ~ "Solid sugars", group == 
                                                             "Óleo de soja, não modificado" ~ "Soybean oil, not chemically modified", group == 
                                                             "Carnes e comestíveis de aves domésticas" ~ "Meat and edible offal of domestic poultry", group == 
                                                             "Cocos e castanhas do Brasil e de caju" ~ "Brazil nuts and cashew nuts", group == 
                                                             "Frutas e outros comestíveis de planta" ~ "Fruits and other plant edibles", group == 
                                                             "Cimentos hidráulicos" ~ "Hydraulic cements", group == 
                                                             "Obras de fibrocimento e cimento-celulose" ~ "Works of fibrous cement and cement-board", group == 
                                                             "Carnes bovinas congeladas" ~ "Frozen beef", group == 
                                                             "Madeira contraplacada ou compensada" ~ "Plywood or veneered wood", group == 
                                                             "Folhas de madeira para folheados" ~ "Wood veneer sheets", group == 
                                                             "Outras gorduras e óleos vegetais" ~ "Other vegetable fats and oils", group == 
                                                             "Minerios de zinco e seus concentrados" ~ "Zinc ores and concentrates", group == 
                                                             "Minerios de chumbo e seus concentrados" ~ "Lead ores and concentrates", group == 
                                                             "Outros moveis e suas partes" ~ "Other furniture and its parts", group == 
                                                             "Cacau bruto ou torrado" ~ "Raw or roasted cocoa", group == 
                                                             "Gomas e resinas naturais" ~ "Natural gums and resins", group == 
                                                             "Filés de peixe e outras carnes" ~ "Fish fillets and other meats", group == 
                                                             "Outras sementes e oleaginosos" ~ "Other seeds and oleaginous fruits", group == 
                                                             "Partes para veículos de sh4 8711 a 8713" ~ "Parts for vehicles of HS 8711 to 8713", group == 
                                                             "Partes para motores de sh4 8407 e 8408" ~ "Parts for engines of HS 8407 and 8408", group == 
                                                             "Miudezas comestíveis bovina, suína, etc" ~ "Edible offal of bovine, swine, etc.", group == 
                                                             "Obras de carpintaria para construção" ~ "Carpentry works for construction", group == 
                                                             "Minérios de nióbio, tântalo, vanádio, zircônio" ~ "Niobium, tantalum, vanadium, zirconium ores", group == 
                                                             "Minerios de titanio e seus concentrados" ~ "Titanium ores and concentrates", group == 
                                                             "Minerios de tungstenio e seus concentrados" ~ "Tungsten ores and concentrates", group == 
                                                             "Construcoes pre-fabricadas" ~ "Prefabricated constructions", group == 
                                                             "Pedras preciosas ou semi, exceto diamante" ~ "Precious or semi-precious stones, except diamonds", group == 
                                                             "Dolomite ou aglomerado de dolomite" ~ "Dolomite or dolomite aggregate", group ==
                                                             "Facas de lâmina cortante ou serrilhada" ~ "Cutting or serrated blade knives", group == 
                                                             "Ferramentas para calçados" ~ "Tools for footwear", group == 
                                                             "Águas mineirais com aditivos" ~ "Mineral waters with additives", group == 
                                                             "Mármores e outras pedras de construção" ~ "Marbles and other construction stones", group == 
                                                             "Consumo de bordo" ~ "On-board consumption", group == 
                                                             "Madeira marchetada e artigos desta" ~ "Marquetry wood and articles thereof", group == 
                                                             "Milho" ~ "Corn", group == 
                                                             "Ladrilhos e placas para revestimento" ~ "Tiles and plates for covering", group == 
                                                             "Automóveis para transporte de mercadorias" ~ "Automobiles for goods transportation", group == 
                                                             "Resíduos da extração do óleo de soja" ~ "Residues from soybean oil extraction", group == 
                                                             "Retroescavadoras e carregadoras" ~ "Backhoe loaders and loaders", group == 
                                                             "Tripas de animais, exceto peixes" ~ "Animal casings, except fish", group == 
                                                             "Peixes vivos" ~ "Live fish", group == 
                                                             "Preparações para alimentação animal" ~ "Preparations for animal feeding", group == 
                                                             "Instrumentos de medida de energia e radiação" ~ "Instruments for energy and radiation measurement", group == 
                                                             "Borrachas e gomas em formas primárias" ~ "Rubber and gums in primary forms", group == 
                                                             "Bijutarias" ~ "Costume jewelry", group == 
                                                             "Malas, maletas e estojos" ~ "Bags, suitcases and cases", group == 
                                                             "Resíduos da fabricação de amido, polpas, etc" ~ "Residues from manufacturing starch, pulp, etc.", group == 
                                                             "Hidrocarbonetos gasosos" ~ "Gaseous hydrocarbons", group == 
                                                             "Bombas de ar, compressores, ventiladores" ~ "Air pumps, compressors, fans", group == 
                                                             "Turborreatores e outras turbinas a gás" ~ "Turbojets and other gas turbines", group == 
                                                             "Aparelhos de controle de líquidos e gases" ~ "Apparatus for controlling liquids and gases", group == 
                                                             "Mel natural" ~ "Natural honey", group == 
                                                             "Peixes congelados, exceto filés" ~ "Frozen fish, except fillets", group == 
                                                             "Telhas e mais produtos cerâmicos de construção" ~ "Roof tiles and other ceramic construction products", group == 
                                                             "Preparações e artigos farmacêuticos" ~ "Pharmaceutical preparations and articles", group == 
                                                             "Preparações alimentícias não especificadas" ~ "Unspecified food preparations", group == 
                                                             "Aparelhos para telefonia por fios" ~ "Apparatus for wired telephony", group == 
                                                             "Motocicletas e outros com motor auxiliar" ~ "Motorcycles and other motor-assisted vehicles", group == 
                                                             "Aparelhos emissores para rádio" ~ "Radio transmitting apparatus", group == 
                                                             "Navalhas e aparelhos de barbear" ~ "Razors and shaving appliances", group == 
                                                             "Óleos essenciais e concentrados" ~ "Essential oils and concentrates", group == 
                                                             "Materiais vegetais utilizados em cestaria" ~ "Vegetable materials used in basketry", group == 
                                                             "Plantas para medicina, perfumaria ou inseticida" ~ "Plants for medicine, perfumery, or insecticidal use", group == 
                                                             "Tântalo, seus resíduos e sucatas" ~ "Tantalum, its residues and scrap", group == 
                                                             "Ferro-ligas" ~ "Ferroalloys", group == 
                                                             "Partes para máquinas de sh4 8425 a 8430" ~ "Parts for machines of HS 8425 to 8430", group == 
                                                             "Pimentas secas ou trituradas" ~ "Dried or crushed peppers", group == 
                                                             "Ouro em forma bruta, semimanufaturada ou em pó" ~ "Gold in raw, semi-manufactured, or powdered form", group == 
                                                             "Embarcações de recreio ou desporto" ~ "Pleasure or sports vessels", group == 
                                                             "Calhaus, cascalho e pedras britadas" ~ "Pebbles, gravel, and crushed stones", group == 
                                                             "Perfis de ferro ou aço não ligado" ~ "Iron or non-alloy steel profiles", group == 
                                                             "Monofilamentos, varas, bastões, de plásticos" ~ "Plastics monofilaments, rods, and sticks", group == 
                                                             "Grãos de cereais trabalhados, menos arroz" ~ "Processed cereal grains, except rice", group == 
                                                             "Calçados" ~ "Footwear", group == 
                                                             "Diamantes não montados ou engastados" ~ "Unmounted or unset diamonds", group == 
                                                             "Outros calçados com plástico ou borracha" ~ "Other footwear with plastic or rubber", group == 
                                                             "Carrocerias para veículos" ~ "Vehicle bodies", group == 
                                                             "Farinhas, semolas, pós de legumes" ~ "Flours, semolina, vegetable powders", group ==  
                                                             "Sementes, frutos e esporos, para sementeira" ~ "Seeds, fruits, and spores for sowing", group == 
                                                             "Recipientes de ferro e aço para gases" ~ "Iron and steel containers for gases", group == 
                                                             "Bombas para líquidos" ~ "Pumps for liquids", group == 
                                                             "Sabões e preparações para lavar pele" ~ "Soaps and preparations for skin cleansing", group == 
                                                             "Animais vivos da espécie bovina" ~ "Live animals of the bovine species", group == 
                                                             "Frutas cozidas ou não, misturadas ou não" ~ "Cooked or uncooked fruits, mixed or unmixed", group == 
                                                             "Óleo de palma não modificado" ~ "Unmodified palm oil", group == 
                                                             "Pasta química de madeira, para dissolução" ~ "Wood chemical pulp for dissolving", group == 
                                                             "Pastas químicas de madeira" ~ "Wood chemical pulps", group == 
                                                             "Peixes secos, salgados ou cozidos" ~ "Dried, salted, or cooked fish", group == 
                                                             "Estatuetas e objetos de ornamentação" ~ "Statuettes and ornamental objects", group == 
                                                             "Crustáceos vivos ou não, para alimento" ~ "Live or non-live crustaceans for food", group == 
                                                             "Corindo, óxido e hidróxido de alumínio" ~ "Corundum, aluminum oxide, and hydroxide", group == 
                                                             "Alumínio em formas brutas" ~ "Aluminum in raw forms", group == 
                                                             "Caolim e outras argilas caulínicas" ~ "Kaolin and other kaolinic clays", group == 
                                                             "Máquinas e ferramentas de trabalhar metais" ~ "Machinery and tools for working metals", group == 
                                                             "Adubos minerais ou químicos" ~ "Mineral or chemical fertilizers", group == 
                                                             "Gorduras animais ou vegetais hidrogenadas" ~ "Hydrogenated animal or vegetable fats", group == 
                                                             "Hidrogênio e mais elementos não metálicos" ~ "Hydrogen and other non-metallic elements", group == 
                                                             "Madeira em bruto" ~ "Rough wood", group == 
                                                             "Sacos de quaisquer dimensões, para embalagem" ~ "Bags of any dimensions for packaging", group == 
                                                             "Folhas, ramos e outras partes de planta" ~ "Leaves, branches, and other plant parts", group == 
                                                             "Flores, folhagem e frutos artificiais" ~ "Artificial flowers, foliage, and fruits", group == 
                                                             "Produtos animais impróprios para alimentação" ~ "Animal products unsuitable for consumption", group == 
                                                             "Flores e seus botões para ornamentos" ~ "Flowers and their buds for ornamentation", group == 
                                                             "Minérios de cobre e seus concentrados" ~ "Copper ores and their concentrates", group == 
                                                             "Minérios de ferro e seus concentrados" ~ "Iron ores and their concentrates", group == 
                                                             "Amidos e féculas; inulina" ~ "Starches and flours; inulin", group == 
                                                             "Citrinos, frescos ou secos" ~ "Citrus fruits, fresh or dried", group == 
                                                             "Partes para veículos de sh4 8701 a 8705" ~ "Parts for vehicles of HS 8701 to 8705", group == 
                                                             "Tubos e perfis de ferro ou aço" ~ "Iron or steel tubes and profiles", group == 
                                                             "Carvão vegetal" ~ "Charcoal", group == 
                                                             "Minérios de alumínio e seus concentrados" ~ "Aluminum ores and their concentrates", group == 
                                                             "Ferro fundido e outras formas primárias" ~ "Cast iron and other primary forms", group == 
                                                             "Outras frutas de casca rija" ~ "Other nuts", group == 
                                                             "Instrumentos automáticos para regulação" ~ "Automatic regulating instruments", group == 
                                                             "Níquel em formas brutas" ~ "Nickel in raw forms", group == 
                                                             "Queijos e requeijão" ~ "Cheese and curd", group == 
                                                             "Outros instrumentos musicais de cordas" ~ "Other string musical instruments", group == 
                                                             "Instrumentos musicais elétricos" ~ "Electric musical instruments", group == 
                                                             "Artigos para atividades físicas" ~ "Articles for physical activities", group == 
                                                             "Outras obras de madeira" ~ "Other wooden articles", group == 
                                                             "Microfones, alto-falantes, amplificadores, etc" ~ "Microphones, loudspeakers, amplifiers, etc.", group == 
                                                             "Fornos elétricos industriais" ~ "Industrial electric furnaces", group == 
                                                             "Fluidos para sistemas hidráulicos" ~ "Fluids for hydraulic systems", group == 
                                                             "Minérios de cromo e seus concentrados" ~ "Chromium ores and their concentrates", group == 
                                                             "Areias naturais de qualquer espécie" ~ "Natural sands of any kind", group == 
                                                             "Lenha em qualquer estado" ~ "Firewood in any condition", group == 
                                                             "Arcos e estacas de madeira" ~ "Wooden arches and stakes", group == 
                                                             "Preparações cosméticas e banho" ~ "Cosmetic and bath preparations", group ==  
                                                             "Vestimentas para esportes e banho" ~ "Sportswear and swimwear", group == 
                                                             "Fosfatos naturais" ~ "Natural phosphates", group == 
                                                             "Algodão, não cardado nem penteado" ~ "Cotton, not carded or combed", group == 
                                                             "Obras de cestaria e lufa" ~ "Basketware and luffa works", group == 
                                                             "Partes para máquinas de sh4 8456 a 8465" ~ "Parts for machines of HS 8456 to 8465", group == 
                                                             "Mangas, abacaxis, abacates, figos, etc" ~ "Mangoes, pineapples, avocados, figs, etc.", group == 
                                                             "Outras obras de plástico e outros materiais" ~ "Other plastic and other material works", group == 
                                                             "Quadros e desenhos feitos a mão" ~ "Handmade paintings and drawings", group == 
                                                             "Pedra-pomes, esmeril e outros abrasivos" ~ "Pumice stone, emery, and other abrasives", group == 
                                                             "Melões, melancias e papaias frescos" ~ "Fresh melons, watermelons, and papayas", group == 
                                                             "Aparelhos de topografia, nivelamento, etc" ~ "Surveying, leveling, etc. instruments", group == 
                                                             "Polímeros de olefinas halogenadas" ~ "Halogenated olefin polymers", group == 
                                                             "Outras chapas e tiras de plástico" ~ "Other plastic sheets and strips", group == 
                                                             "Glicerol, lixívias, glicéricas" ~ "Glycerol, lyes, glycerides", group == 
                                                             "Carvões e matérias minerais ativadas" ~ "Activated carbons and mineral materials", group == 
                                                             "Aparas e desperdícios de couros e peles" ~ "Leather and fur cuttings and waste", group == 
                                                             "Couro reconstítuido" ~ "Reconstituted leather", group == 
                                                             "Castinas e calcárias para cimento" ~ "Calcined and hydraulic limestones for cement", group == 
                                                             "Máquinas para colheita e debulha" ~ "Harvesting and threshing machinery", group == 
                                                             "Heterósidos naturais ou sintéticos" ~ "Natural or synthetic heterosides", group == 
                                                             "Preparações capilares" ~ "Hair preparations", group == 
                                                             "Pastas, gazes e análogos para usos medicinais" ~ "Medicinal pastes, gauzes, and analogues", group == 
                                                             "Outras frutas frescas" ~ "Other fresh fruits", group == 
                                                             "Couros e peles de bovinos ou equídeos" ~ "Bovine or equine hides and skins", group == 
                                                             "Outras obras de couro natural ou reconstituído" ~ "Other natural or reconstituted leather works", group == 
                                                             "Assentos" ~ "Seats", group == 
                                                             "Óleos de coco, palmiste ou babaçu" ~ "Coconut, palm kernel, or babassu oils", group == 
                                                             "Tubos e seus acessórios de plástico" ~ "Plastic tubes and their accessories", group == 
                                                             "Outros calçados" ~ "Other footwear", group == 
                                                             "Roupas íntimas e pijamas femininos" ~ "Women's underwear and pajamas", group == 
                                                             "Enzimas e enzimas preparadas" ~ "Enzymes and prepared enzymes", group == 
                                                             "Carnes suínas refrigeradas ou congeladas" ~ "Chilled or frozen pork", group == 
                                                             "Âncoras e fateixas de ferro ou aço" ~ "Iron or steel anchors and grapnels", group == 
                                                             "Águas minerais sem aditivos" ~ "Mineral waters without additives", group == 
                                                             "Vestimentas de uso masculino" ~ "Men's clothing", group == 
                                                             "Aparelhos para medicina e veterinária" ~ "Medical and veterinary instruments", group == 
                                                             "Chaves de porcas e de caixa" ~ "Wrenches and spanners", group == 
                                                             "Aparelhos de laboratórios fotográficos" ~ "Photographic laboratory equipment", group == 
                                                             "Carnes bovinas frescas ou refrigeradas" ~ "Fresh or chilled beef", group == 
                                                             "Aparelhos para selecionar pedras" ~ "Stone sorting apparatus", group == 
                                                             "Gelatina e colas de origem animal" ~ "Gelatin and animal glues", group == 
                                                             "Dispositivo para tratamento de materiais" ~ "Materials treatment devices", group == 
                                                             "Outras preparações de carne e miudezas" ~ "Other meat and offal preparations", group == 
                                                             "Cervejas de malte" ~ "Malt beers", group == 
                                                             "Aparelhos de iluminação e suas partes" ~ "Lighting fixtures and their parts", group == 
                                                             "Dormentes de madeira para vias férreas" ~ "Wooden sleepers for railway tracks", group == 
                                                             "Artefatos de joalheria de metais" ~ "Metal jewelry articles", group == 
                                                             "Vestimentas de malha de uso masculino" ~ "Men's knitted clothing", group == 
                                                             "Carnes e comestíveis salgadas ou secas" ~ "Salted or dried meats and edibles", group == 
                                                             "Gorduras animais bovino, ovino e caprino" ~ "Bovine, ovine, and caprine animal fats", group == 
                                                             "Legumes de vagem em grão secos" ~ "Dried leguminous vegetables", group == 
                                                             "Minérios de metais preciosos" ~ "Precious metal ores", group == 
                                                             "Granito e outras pedras para construção" ~ "Granite and other stones for construction", group == 
                                                             "Outros couros e peles em bruto" ~ "Other raw hides and skins", group == 
                                                             "Couros e peles de animais sem pelos" ~ "Hairless animal hides and skins", group == 
                                                             "Melaços da extração e refino do açúcar" ~ "Molasses from sugar extraction and refining",
                                                         TRUE ~ group
                                                         #######
      ))
  }
  
  df <- df %>%
      mutate(lab = group,
             group = ifelse(nchar(group) >= 40,
                            paste0(substr(group, 1, 40), "..."),
                            group),
             value = value * 100)
  
  server <- function(input, output, session) {
    
    df_reactived <- reactive({
    
      # filtrar para produtos da floresta
      if(input$filter == param$filter_def) {
        w <- df %>% filter(floresta)
      } else {
        w <- df
      }
      
      return(w)
    })
    
    # Cria opções para seleção de grupos
    param$filter_choices <- sort(unique(df$group))
    param$filter_choices <- param$filter_choices[which(param$filter_choices != " - ")]

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      # se input está vazio preenche com valor aleatório da lista de colunas
      if (input$filter == "") {
        updateSelectInput(session, "filter",
          choices = param$filter_choices,
          selected = sample(param$filter_choices, 1)
        )
      }
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "filter=", input$filter
      )
      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["filter"]])) {
        updateSelectInput(session, "filter",
          choices = param$filter_choices,
          selected = query[["filter"]]
        )
      }
    }


    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$filter) || input$filter == "") {
        text <- param$server1
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        text <- param$server2
      }

      text
    })
    output$plot_subtitle <- renderText({
      text <- " "

      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$filter) || input$filter == "") {
        text <- " "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
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
          if (is.null(input$filter) || input$filter == "") {
            fig <- plotly_empty()
            stop()
          }

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          x_col <- param$table[which(param$table$var == "value"), ]
          color_col <- param$table[which(param$table$var == "group"), ]
          slider_col <- param$table[which(param$table$var == "NA"), ]
          text_col <- param$table[which(param$table$var == "group"), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]

          # Cria coluna vazia para o ranking
          y_col <- list()
          y_col$var <- "rank"
          y_col$label <- "Ranking"

          df <- df_reactived()
          
          df_p <- data.frame(
            df[x_col$var],
            NA,
            df[color_col$var],
            df["group"],
            df["group"],
            df[id_col$var],
            df["lab"]
          )

          colnames(df_p) <- c("x", "y", "color", "text", "group", "id", "lab")

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
            "<b>", df_p$lab, "</b><br>",
            x_col$label, ": ", format(df_p$x, scientific = FALSE,
                                      digits = 2,
                                      decimal.mark = ",", 
                                      big.mark = "."), "<br>",
            y_col$label, ": ", df_p$y, "<br>",
            param$server4, x_col$unidade, "</b>"
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
            text = ~tooltip,
            textposition = "middle right",
            showlegend = FALSE,
            # marker = list(
            #  opacity = 0.5,
            #  line = list(width = 1, color = 'white')
            # ),
            hoverinfo = "text"
          )

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
            fig_p <- fig_p %>% animation_slider(currentvalue = list(prefix = param$server5, font = f1))

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
