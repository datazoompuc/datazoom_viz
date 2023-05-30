# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis
pallete_discrete <- rev(pallete_discrete)
pallete_continuous <- rev(pallete_continuous)

# Fontes

# Funcão para retornar objeto server
get_server <- function(files, param) {

  # Carrega dados
  df <- readRDS(files$db_file) %>% 
    st_transform(crs = "+init=epsg:4326")

  if(param$lang){
      
      df <- df %>% mutate(produto_principal = case_when( #######
                                                         #Translating produto_principal variable
                                                        produto_principal == 
                                                        "Madeira cortada, desenrolada ou polida" ~ "Cut, unrolled or polished wood", produto_principal == 
                                                        "Peixes frescos/refrigerados, exceto filés" ~ "Fresh/chilled fish, except fillets", produto_principal == 
                                                        "Estanho em formas brutas" ~ "Tin in crude forms", produto_principal == 
                                                        "Sumos de frutas, com ou sem aditivos" ~ "Fruit juices, with or without additives", produto_principal == 
                                                        "Minerios de estanho e seus concentrados" ~ "Tin ores and concentrates", produto_principal == 
                                                        "Café torrado, cascas e sucedâneos" ~ "Roasted coffee, husks and substitutes", produto_principal == 
                                                        "Produtos vegetais nao especificados" ~ "Unspecified vegetable products", produto_principal == 
                                                        "Arroz" ~ "Rice", produto_principal == 
                                                        "Soja, mesmo triturada" ~ "Soybeans, even crushed", produto_principal == 
                                                        "Outros veículos aéreos" ~ "Other aerial vehicles", produto_principal == 
                                                        "Farinhas animais impróprias para consumo" ~ "Animal flours unfit for human consumption", produto_principal == 
                                                        "Couros e peles curtidos ou em crosta" ~ "Tanned or crust hides and skins", produto_principal == 
                                                        "Vestimentas de uso feminino" ~ "Women's clothing", produto_principal == 
                                                        "Máquinas para trabalhar couro" ~ "Leather-working machinery", produto_principal == 
                                                        "Couros preparados após curtimenta" ~ "Prepared hides after tanning", produto_principal == 
                                                        "Vestimentas de malha de uso feminino" ~ "Women's knitted clothing", produto_principal == 
                                                        "Aparelhos para circuitos elétricos" ~ "Apparatus for electric circuits", produto_principal == 
                                                        "Tractores (exceto os da posicao 8709)" ~ "Tractors (except those of position 8709)", produto_principal == 
                                                        "Obras de pérolas e pedras preciosas" ~ "Works of pearls and precious stones", produto_principal == 
                                                        "Madeira perfilada, mesmo aplainada" ~ "Profiled wood, even planed", produto_principal == 
                                                        "Minérios de manganês e seus concentrados" ~ "Manganese ores and concentrates", produto_principal == 
                                                        "Açúcares no estado sólido" ~ "Solid sugars", produto_principal == 
                                                        "Óleo de soja, não modificado" ~ "Soybean oil, not chemically modified", produto_principal == 
                                                        "Carnes e comestíveis de aves domésticas" ~ "Meat and edible offal of domestic poultry", produto_principal == 
                                                        "Cocos e castanhas do Brasil e de caju" ~ "Brazil nuts and cashew nuts", produto_principal == 
                                                        "Frutas e outros comestíveis de planta" ~ "Fruits and other plant edibles", produto_principal == 
                                                        "Cimentos hidráulicos" ~ "Hydraulic cements", produto_principal == 
                                                        "Obras de fibrocimento e cimento-celulose" ~ "Works of fibrous cement and cement-board", produto_principal == 
                                                        "Carnes bovinas congeladas" ~ "Frozen beef", produto_principal == 
                                                        "Madeira contraplacada ou compensada" ~ "Plywood or veneered wood", produto_principal == 
                                                        "Folhas de madeira para folheados" ~ "Wood veneer sheets", produto_principal == 
                                                        "Outras gorduras e óleos vegetais" ~ "Other vegetable fats and oils", produto_principal == 
                                                        "Minerios de zinco e seus concentrados" ~ "Zinc ores and concentrates", produto_principal == 
                                                        "Minerios de chumbo e seus concentrados" ~ "Lead ores and concentrates", produto_principal == 
                                                        "Outros moveis e suas partes" ~ "Other furniture and its parts", produto_principal == 
                                                        "Cacau bruto ou torrado" ~ "Raw or roasted cocoa", produto_principal == 
                                                        "Gomas e resinas naturais" ~ "Natural gums and resins", produto_principal == 
                                                        "Filés de peixe e outras carnes" ~ "Fish fillets and other meats", produto_principal == 
                                                        "Outras sementes e oleaginosos" ~ "Other seeds and oleaginous fruits", produto_principal == 
                                                        "Partes para veículos de sh4 8711 a 8713" ~ "Parts for vehicles of HS 8711 to 8713", produto_principal == 
                                                        "Partes para motores de sh4 8407 e 8408" ~ "Parts for engines of HS 8407 and 8408", produto_principal == 
                                                        "Miudezas comestíveis bovina, suína, etc" ~ "Edible offal of bovine, swine, etc.", produto_principal == 
                                                        "Obras de carpintaria para construção" ~ "Carpentry works for construction", produto_principal == 
                                                        "Minérios de nióbio, tântalo, vanádio, zircônio" ~ "Niobium, tantalum, vanadium, zirconium ores", produto_principal == 
                                                        "Minerios de titanio e seus concentrados" ~ "Titanium ores and concentrates", produto_principal == 
                                                        "Minerios de tungstenio e seus concentrados" ~ "Tungsten ores and concentrates", produto_principal == 
                                                        "Construcoes pre-fabricadas" ~ "Prefabricated constructions", produto_principal == 
                                                        "Pedras preciosas ou semi, exceto diamante" ~ "Precious or semi-precious stones, except diamonds", produto_principal == 
                                                        "Dolomite ou aglomerado de dolomite" ~ "Dolomite or dolomite aggregate", produto_principal ==
          "Facas de lâmina cortante ou serrilhada" ~ "Cutting or serrated blade knives", produto_principal == 
          "Ferramentas para calçados" ~ "Tools for footwear", produto_principal == 
          "Águas mineirais com aditivos" ~ "Mineral waters with additives", produto_principal == 
          "Mármores e outras pedras de construção" ~ "Marbles and other construction stones", produto_principal == 
          "Consumo de bordo" ~ "On-board consumption", produto_principal == 
          "Madeira marchetada e artigos desta" ~ "Marquetry wood and articles thereof", produto_principal == 
          "Milho" ~ "Corn", produto_principal == 
          "Ladrilhos e placas para revestimento" ~ "Tiles and plates for covering", produto_principal == 
          "Automóveis para transporte de mercadorias" ~ "Automobiles for goods transportation", produto_principal == 
          "Resíduos da extração do óleo de soja" ~ "Residues from soybean oil extraction", produto_principal == 
          "Retroescavadoras e carregadoras" ~ "Backhoe loaders and loaders", produto_principal == 
          "Tripas de animais, exceto peixes" ~ "Animal casings, except fish", produto_principal == 
          "Peixes vivos" ~ "Live fish", produto_principal == 
          "Preparações para alimentação animal" ~ "Preparations for animal feeding", produto_principal == 
          "Instrumentos de medida de energia e radiação" ~ "Instruments for energy and radiation measurement", produto_principal == 
          "Borrachas e gomas em formas primárias" ~ "Rubber and gums in primary forms", produto_principal == 
          "Bijutarias" ~ "Costume jewelry", produto_principal == 
          "Malas, maletas e estojos" ~ "Bags, suitcases and cases", produto_principal == 
          "Resíduos da fabricação de amido, polpas, etc" ~ "Residues from manufacturing starch, pulp, etc.", produto_principal == 
          "Hidrocarbonetos gasosos" ~ "Gaseous hydrocarbons", produto_principal == 
          "Bombas de ar, compressores, ventiladores" ~ "Air pumps, compressors, fans", produto_principal == 
          "Turborreatores e outras turbinas a gás" ~ "Turbojets and other gas turbines", produto_principal == 
          "Aparelhos de controle de líquidos e gases" ~ "Apparatus for controlling liquids and gases", produto_principal == 
          "Mel natural" ~ "Natural honey", produto_principal == 
          "Peixes congelados, exceto filés" ~ "Frozen fish, except fillets", produto_principal == 
          "Telhas e mais produtos cerâmicos de construção" ~ "Roof tiles and other ceramic construction products", produto_principal == 
          "Preparações e artigos farmacêuticos" ~ "Pharmaceutical preparations and articles", produto_principal == 
          "Preparações alimentícias não especificadas" ~ "Unspecified food preparations", produto_principal == 
          "Aparelhos para telefonia por fios" ~ "Apparatus for wired telephony", produto_principal == 
          "Motocicletas e outros com motor auxiliar" ~ "Motorcycles and other motor-assisted vehicles", produto_principal == 
          "Aparelhos emissores para rádio" ~ "Radio transmitting apparatus", produto_principal == 
          "Navalhas e aparelhos de barbear" ~ "Razors and shaving appliances", produto_principal == 
          "Óleos essenciais e concentrados" ~ "Essential oils and concentrates", produto_principal == 
          "Materiais vegetais utilizados em cestaria" ~ "Vegetable materials used in basketry", produto_principal == 
          "Plantas para medicina, perfumaria ou inseticida" ~ "Plants for medicine, perfumery, or insecticidal use", produto_principal == 
          "Tântalo, seus resíduos e sucatas" ~ "Tantalum, its residues and scrap", produto_principal == 
          "Ferro-ligas" ~ "Ferroalloys", produto_principal == 
          "Partes para máquinas de sh4 8425 a 8430" ~ "Parts for machines of HS 8425 to 8430", produto_principal == 
          "Pimentas secas ou trituradas" ~ "Dried or crushed peppers", produto_principal == 
          "Ouro em forma bruta, semimanufaturada ou em pó" ~ "Gold in raw, semi-manufactured, or powdered form", produto_principal == 
          "Embarcações de recreio ou desporto" ~ "Pleasure or sports vessels", produto_principal == 
          "Calhaus, cascalho e pedras britadas" ~ "Pebbles, gravel, and crushed stones", produto_principal == 
          "Perfis de ferro ou aço não ligado" ~ "Iron or non-alloy steel profiles", produto_principal == 
          "Monofilamentos, varas, bastões, de plásticos" ~ "Plastics monofilaments, rods, and sticks", produto_principal == 
          "Grãos de cereais trabalhados, menos arroz" ~ "Processed cereal grains, except rice", produto_principal == 
          "Calçados" ~ "Footwear", produto_principal == 
          "Diamantes não montados ou engastados" ~ "Unmounted or unset diamonds", produto_principal == 
          "Outros calçados com plástico ou borracha" ~ "Other footwear with plastic or rubber", produto_principal == 
          "Carrocerias para veículos" ~ "Vehicle bodies", produto_principal == 
          "Farinhas, semolas, pós de legumes" ~ "Flours, semolina, vegetable powders", produto_principal ==  
              "Sementes, frutos e esporos, para sementeira" ~ "Seeds, fruits, and spores for sowing", produto_principal == 
          "Recipientes de ferro e aço para gases" ~ "Iron and steel containers for gases", produto_principal == 
          "Bombas para líquidos" ~ "Pumps for liquids", produto_principal == 
          "Sabões e preparações para lavar pele" ~ "Soaps and preparations for skin cleansing", produto_principal == 
          "Animais vivos da espécie bovina" ~ "Live animals of the bovine species", produto_principal == 
          "Frutas cozidas ou não, misturadas ou não" ~ "Cooked or uncooked fruits, mixed or unmixed", produto_principal == 
          "Óleo de palma não modificado" ~ "Unmodified palm oil", produto_principal == 
          "Pasta química de madeira, para dissolução" ~ "Wood chemical pulp for dissolving", produto_principal == 
          "Pastas químicas de madeira" ~ "Wood chemical pulps", produto_principal == 
          "Peixes secos, salgados ou cozidos" ~ "Dried, salted, or cooked fish", produto_principal == 
          "Estatuetas e objetos de ornamentação" ~ "Statuettes and ornamental objects", produto_principal == 
          "Crustáceos vivos ou não, para alimento" ~ "Live or non-live crustaceans for food", produto_principal == 
          "Corindo, óxido e hidróxido de alumínio" ~ "Corundum, aluminum oxide, and hydroxide", produto_principal == 
          "Alumínio em formas brutas" ~ "Aluminum in raw forms", produto_principal == 
          "Caolim e outras argilas caulínicas" ~ "Kaolin and other kaolinic clays", produto_principal == 
          "Máquinas e ferramentas de trabalhar metais" ~ "Machinery and tools for working metals", produto_principal == 
          "Adubos minerais ou químicos" ~ "Mineral or chemical fertilizers", produto_principal == 
          "Gorduras animais ou vegetais hidrogenadas" ~ "Hydrogenated animal or vegetable fats", produto_principal == 
          "Hidrogênio e mais elementos não metálicos" ~ "Hydrogen and other non-metallic elements", produto_principal == 
          "Madeira em bruto" ~ "Rough wood", produto_principal == 
          "Sacos de quaisquer dimensões, para embalagem" ~ "Bags of any dimensions for packaging", produto_principal == 
          "Folhas, ramos e outras partes de planta" ~ "Leaves, branches, and other plant parts", produto_principal == 
          "Flores, folhagem e frutos artificiais" ~ "Artificial flowers, foliage, and fruits", produto_principal == 
          "Produtos animais impróprios para alimentação" ~ "Animal products unsuitable for consumption", produto_principal == 
          "Flores e seus botões para ornamentos" ~ "Flowers and their buds for ornamentation", produto_principal == 
          "Minérios de cobre e seus concentrados" ~ "Copper ores and their concentrates", produto_principal == 
          "Minérios de ferro e seus concentrados" ~ "Iron ores and their concentrates", produto_principal == 
          "Amidos e féculas; inulina" ~ "Starches and flours; inulin", produto_principal == 
          "Citrinos, frescos ou secos" ~ "Citrus fruits, fresh or dried", produto_principal == 
          "Partes para veículos de sh4 8701 a 8705" ~ "Parts for vehicles of HS 8701 to 8705", produto_principal == 
          "Tubos e perfis de ferro ou aço" ~ "Iron or steel tubes and profiles", produto_principal == 
          "Carvão vegetal" ~ "Charcoal", produto_principal == 
          "Minérios de alumínio e seus concentrados" ~ "Aluminum ores and their concentrates", produto_principal == 
          "Ferro fundido e outras formas primárias" ~ "Cast iron and other primary forms", produto_principal == 
          "Outras frutas de casca rija" ~ "Other nuts", produto_principal == 
          "Instrumentos automáticos para regulação" ~ "Automatic regulating instruments", produto_principal == 
          "Níquel em formas brutas" ~ "Nickel in raw forms", produto_principal == 
          "Queijos e requeijão" ~ "Cheese and curd", produto_principal == 
          "Outros instrumentos musicais de cordas" ~ "Other string musical instruments", produto_principal == 
          "Instrumentos musicais elétricos" ~ "Electric musical instruments", produto_principal == 
          "Artigos para atividades físicas" ~ "Articles for physical activities", produto_principal == 
          "Outras obras de madeira" ~ "Other wooden articles", produto_principal == 
          "Microfones, alto-falantes, amplificadores, etc" ~ "Microphones, loudspeakers, amplifiers, etc.", produto_principal == 
          "Fornos elétricos industriais" ~ "Industrial electric furnaces", produto_principal == 
          "Fluidos para sistemas hidráulicos" ~ "Fluids for hydraulic systems", produto_principal == 
          "Minérios de cromo e seus concentrados" ~ "Chromium ores and their concentrates", produto_principal == 
          "Areias naturais de qualquer espécie" ~ "Natural sands of any kind", produto_principal == 
          "Lenha em qualquer estado" ~ "Firewood in any condition", produto_principal == 
          "Arcos e estacas de madeira" ~ "Wooden arches and stakes", produto_principal == 
          "Preparações cosméticas e banho" ~ "Cosmetic and bath preparations", produto_principal ==  
              "Vestimentas para esportes e banho" ~ "Sportswear and swimwear", produto_principal == 
          "Fosfatos naturais" ~ "Natural phosphates", produto_principal == 
          "Algodão, não cardado nem penteado" ~ "Cotton, not carded or combed", produto_principal == 
          "Obras de cestaria e lufa" ~ "Basketware and luffa works", produto_principal == 
          "Partes para máquinas de sh4 8456 a 8465" ~ "Parts for machines of HS 8456 to 8465", produto_principal == 
          "Mangas, abacaxis, abacates, figos, etc" ~ "Mangoes, pineapples, avocados, figs, etc.", produto_principal == 
          "Outras obras de plástico e outros materiais" ~ "Other plastic and other material works", produto_principal == 
          "Quadros e desenhos feitos a mão" ~ "Handmade paintings and drawings", produto_principal == 
          "Pedra-pomes, esmeril e outros abrasivos" ~ "Pumice stone, emery, and other abrasives", produto_principal == 
          "Melões, melancias e papaias frescos" ~ "Fresh melons, watermelons, and papayas", produto_principal == 
          "Aparelhos de topografia, nivelamento, etc" ~ "Surveying, leveling, etc. instruments", produto_principal == 
          "Polímeros de olefinas halogenadas" ~ "Halogenated olefin polymers", produto_principal == 
          "Outras chapas e tiras de plástico" ~ "Other plastic sheets and strips", produto_principal == 
          "Glicerol, lixívias, glicéricas" ~ "Glycerol, lyes, glycerides", produto_principal == 
          "Carvões e matérias minerais ativadas" ~ "Activated carbons and mineral materials", produto_principal == 
          "Aparas e desperdícios de couros e peles" ~ "Leather and fur cuttings and waste", produto_principal == 
          "Couro reconstítuido" ~ "Reconstituted leather", produto_principal == 
          "Castinas e calcárias para cimento" ~ "Calcined and hydraulic limestones for cement", produto_principal == 
          "Máquinas para colheita e debulha" ~ "Harvesting and threshing machinery", produto_principal == 
          "Heterósidos naturais ou sintéticos" ~ "Natural or synthetic heterosides", produto_principal == 
          "Preparações capilares" ~ "Hair preparations", produto_principal == 
          "Pastas, gazes e análogos para usos medicinais" ~ "Medicinal pastes, gauzes, and analogues", produto_principal == 
          "Outras frutas frescas" ~ "Other fresh fruits", produto_principal == 
          "Couros e peles de bovinos ou equídeos" ~ "Bovine or equine hides and skins", produto_principal == 
          "Outras obras de couro natural ou reconstituído" ~ "Other natural or reconstituted leather works", produto_principal == 
          "Assentos" ~ "Seats", produto_principal == 
          "Óleos de coco, palmiste ou babaçu" ~ "Coconut, palm kernel, or babassu oils", produto_principal == 
          "Tubos e seus acessórios de plástico" ~ "Plastic tubes and their accessories", produto_principal == 
          "Outros calçados" ~ "Other footwear", produto_principal == 
          "Roupas íntimas e pijamas femininos" ~ "Women's underwear and pajamas", produto_principal == 
          "Enzimas e enzimas preparadas" ~ "Enzymes and prepared enzymes", produto_principal == 
          "Carnes suínas refrigeradas ou congeladas" ~ "Chilled or frozen pork", produto_principal == 
          "Âncoras e fateixas de ferro ou aço" ~ "Iron or steel anchors and grapnels", produto_principal == 
          "Águas minerais sem aditivos" ~ "Mineral waters without additives", produto_principal == 
          "Vestimentas de uso masculino" ~ "Men's clothing", produto_principal == 
          "Aparelhos para medicina e veterinária" ~ "Medical and veterinary instruments", produto_principal == 
          "Chaves de porcas e de caixa" ~ "Wrenches and spanners", produto_principal == 
          "Aparelhos de laboratórios fotográficos" ~ "Photographic laboratory equipment", produto_principal == 
          "Carnes bovinas frescas ou refrigeradas" ~ "Fresh or chilled beef", produto_principal == 
          "Aparelhos para selecionar pedras" ~ "Stone sorting apparatus", produto_principal == 
          "Gelatina e colas de origem animal" ~ "Gelatin and animal glues", produto_principal == 
          "Dispositivo para tratamento de materiais" ~ "Materials treatment devices", produto_principal == 
          "Outras preparações de carne e miudezas" ~ "Other meat and offal preparations", produto_principal == 
          "Cervejas de malte" ~ "Malt beers", produto_principal == 
          "Aparelhos de iluminação e suas partes" ~ "Lighting fixtures and their parts", produto_principal == 
          "Dormentes de madeira para vias férreas" ~ "Wooden sleepers for railway tracks", produto_principal == 
          "Artefatos de joalheria de metais" ~ "Metal jewelry articles", produto_principal == 
          "Vestimentas de malha de uso masculino" ~ "Men's knitted clothing", produto_principal == 
          "Carnes e comestíveis salgadas ou secas" ~ "Salted or dried meats and edibles", produto_principal == 
          "Gorduras animais bovino, ovino e caprino" ~ "Bovine, ovine, and caprine animal fats", produto_principal == 
          "Legumes de vagem em grão secos" ~ "Dried leguminous vegetables", produto_principal == 
          "Minérios de metais preciosos" ~ "Precious metal ores", produto_principal == 
          "Granito e outras pedras para construção" ~ "Granite and other stones for construction", produto_principal == 
          "Outros couros e peles em bruto" ~ "Other raw hides and skins", produto_principal == 
          "Couros e peles de animais sem pelos" ~ "Hairless animal hides and skins", produto_principal == 
          "Melaços da extração e refino do açúcar" ~ "Molasses from sugar extraction and refining",
          TRUE ~ produto_principal
                                                #######
                                                        ),
                          lab = case_when( #######
                                           #Translating lab variable
                                           lab == 
                                               "Madeira cortada, desenrolada ou polida" ~ "Cut, unrolled or polished wood", lab == 
                                               "Peixes frescos/refrigerados, exceto filés" ~ "Fresh/chilled fish, except fillets", lab == 
                                               "Estanho em formas brutas" ~ "Tin in crude forms", lab == 
                                               "Sumos de frutas, com ou sem aditivos" ~ "Fruit juices, with or without additives", lab == 
                                               "Minerios de estanho e seus concentrados" ~ "Tin ores and concentrates", lab == 
                                               "Café torrado, cascas e sucedâneos" ~ "Roasted coffee, husks and substitutes", lab == 
                                               "Produtos vegetais nao especificados" ~ "Unspecified vegetable products", lab == 
                                               "Arroz" ~ "Rice", lab == 
                                               "Soja, mesmo triturada" ~ "Soybeans, even crushed", lab == 
                                               "Outros veículos aéreos" ~ "Other aerial vehicles", lab == 
                                               "Farinhas animais impróprias para consumo" ~ "Animal flours unfit for human consumption", lab == 
                                               "Couros e peles curtidos ou em crosta" ~ "Tanned or crust hides and skins", lab == 
                                               "Vestimentas de uso feminino" ~ "Women's clothing", lab == 
                                               "Máquinas para trabalhar couro" ~ "Leather-working machinery", lab == 
                                               "Couros preparados após curtimenta" ~ "Prepared hides after tanning", lab == 
                                               "Vestimentas de malha de uso feminino" ~ "Women's knitted clothing", lab == 
                                               "Aparelhos para circuitos elétricos" ~ "Apparatus for electric circuits", lab == 
                                               "Tractores (exceto os da posicao 8709)" ~ "Tractors (except those of position 8709)", lab == 
                                               "Obras de pérolas e pedras preciosas" ~ "Works of pearls and precious stones", lab == 
                                               "Madeira perfilada, mesmo aplainada" ~ "Profiled wood, even planed", lab == 
                                               "Minérios de manganês e seus concentrados" ~ "Manganese ores and concentrates", lab == 
                                               "Açúcares no estado sólido" ~ "Solid sugars", lab == 
                                               "Óleo de soja, não modificado" ~ "Soybean oil, not chemically modified", lab == 
                                               "Carnes e comestíveis de aves domésticas" ~ "Meat and edible offal of domestic poultry", lab == 
                                               "Cocos e castanhas do Brasil e de caju" ~ "Brazil nuts and cashew nuts", lab == 
                                               "Frutas e outros comestíveis de planta" ~ "Fruits and other plant edibles", lab == 
                                               "Cimentos hidráulicos" ~ "Hydraulic cements", lab == 
                                               "Obras de fibrocimento e cimento-celulose" ~ "Works of fibrous cement and cement-board", lab == 
                                               "Carnes bovinas congeladas" ~ "Frozen beef", lab == 
                                               "Madeira contraplacada ou compensada" ~ "Plywood or veneered wood", lab == 
                                               "Folhas de madeira para folheados" ~ "Wood veneer sheets", lab == 
                                               "Outras gorduras e óleos vegetais" ~ "Other vegetable fats and oils", lab == 
                                               "Minerios de zinco e seus concentrados" ~ "Zinc ores and concentrates", lab == 
                                               "Minerios de chumbo e seus concentrados" ~ "Lead ores and concentrates", lab == 
                                               "Outros moveis e suas partes" ~ "Other furniture and its parts", lab == 
                                               "Cacau bruto ou torrado" ~ "Raw or roasted cocoa", lab == 
                                               "Gomas e resinas naturais" ~ "Natural gums and resins", lab == 
                                               "Filés de peixe e outras carnes" ~ "Fish fillets and other meats", lab == 
                                               "Outras sementes e oleaginosos" ~ "Other seeds and oleaginous fruits", lab == 
                                               "Partes para veículos de sh4 8711 a 8713" ~ "Parts for vehicles of HS 8711 to 8713", lab == 
                                               "Partes para motores de sh4 8407 e 8408" ~ "Parts for engines of HS 8407 and 8408", lab == 
                                               "Miudezas comestíveis bovina, suína, etc" ~ "Edible offal of bovine, swine, etc.", lab == 
                                               "Obras de carpintaria para construção" ~ "Carpentry works for construction", lab == 
                                               "Minérios de nióbio, tântalo, vanádio, zircônio" ~ "Niobium, tantalum, vanadium, zirconium ores", lab == 
                                               "Minerios de titanio e seus concentrados" ~ "Titanium ores and concentrates", lab == 
                                               "Minerios de tungstenio e seus concentrados" ~ "Tungsten ores and concentrates", lab == 
                                               "Construcoes pre-fabricadas" ~ "Prefabricated constructions", lab == 
                                               "Pedras preciosas ou semi, exceto diamante" ~ "Precious or semi-precious stones, except diamonds", lab == 
                                               "Dolomite ou aglomerado de dolomite" ~ "Dolomite or dolomite aggregate", lab ==
                                               "Facas de lâmina cortante ou serrilhada" ~ "Cutting or serrated blade knives", lab == 
                                               "Ferramentas para calçados" ~ "Tools for footwear", lab == 
                                               "Águas mineirais com aditivos" ~ "Mineral waters with additives", lab == 
                                               "Mármores e outras pedras de construção" ~ "Marbles and other construction stones", lab == 
                                               "Consumo de bordo" ~ "On-board consumption", lab == 
                                               "Madeira marchetada e artigos desta" ~ "Marquetry wood and articles thereof", lab == 
                                               "Milho" ~ "Corn", lab == 
                                               "Ladrilhos e placas para revestimento" ~ "Tiles and plates for covering", lab == 
                                               "Automóveis para transporte de mercadorias" ~ "Automobiles for goods transportation", lab == 
                                               "Resíduos da extração do óleo de soja" ~ "Residues from soybean oil extraction", lab == 
                                               "Retroescavadoras e carregadoras" ~ "Backhoe loaders and loaders", lab == 
                                               "Tripas de animais, exceto peixes" ~ "Animal casings, except fish", lab == 
                                               "Peixes vivos" ~ "Live fish", lab == 
                                               "Preparações para alimentação animal" ~ "Preparations for animal feeding", lab == 
                                               "Instrumentos de medida de energia e radiação" ~ "Instruments for energy and radiation measurement", lab == 
                                               "Borrachas e gomas em formas primárias" ~ "Rubber and gums in primary forms", lab == 
                                               "Bijutarias" ~ "Costume jewelry", lab == 
                                               "Malas, maletas e estojos" ~ "Bags, suitcases and cases", lab == 
                                               "Resíduos da fabricação de amido, polpas, etc" ~ "Residues from manufacturing starch, pulp, etc.", lab == 
                                               "Hidrocarbonetos gasosos" ~ "Gaseous hydrocarbons", lab == 
                                               "Bombas de ar, compressores, ventiladores" ~ "Air pumps, compressors, fans", lab == 
                                               "Turborreatores e outras turbinas a gás" ~ "Turbojets and other gas turbines", lab == 
                                               "Aparelhos de controle de líquidos e gases" ~ "Apparatus for controlling liquids and gases", lab == 
                                               "Mel natural" ~ "Natural honey", lab == 
                                               "Peixes congelados, exceto filés" ~ "Frozen fish, except fillets", lab == 
                                               "Telhas e mais produtos cerâmicos de construção" ~ "Roof tiles and other ceramic construction products", lab == 
                                               "Preparações e artigos farmacêuticos" ~ "Pharmaceutical preparations and articles", lab == 
                                               "Preparações alimentícias não especificadas" ~ "Unspecified food preparations", lab == 
                                               "Aparelhos para telefonia por fios" ~ "Apparatus for wired telephony", lab == 
                                               "Motocicletas e outros com motor auxiliar" ~ "Motorcycles and other motor-assisted vehicles", lab == 
                                               "Aparelhos emissores para rádio" ~ "Radio transmitting apparatus", lab == 
                                               "Navalhas e aparelhos de barbear" ~ "Razors and shaving appliances", lab == 
                                               "Óleos essenciais e concentrados" ~ "Essential oils and concentrates", lab == 
                                               "Materiais vegetais utilizados em cestaria" ~ "Vegetable materials used in basketry", lab == 
                                               "Plantas para medicina, perfumaria ou inseticida" ~ "Plants for medicine, perfumery, or insecticidal use", lab == 
                                               "Tântalo, seus resíduos e sucatas" ~ "Tantalum, its residues and scrap", lab == 
                                               "Ferro-ligas" ~ "Ferroalloys", lab == 
                                               "Partes para máquinas de sh4 8425 a 8430" ~ "Parts for machines of HS 8425 to 8430", lab == 
                                               "Pimentas secas ou trituradas" ~ "Dried or crushed peppers", lab == 
                                               "Ouro em forma bruta, semimanufaturada ou em pó" ~ "Gold in raw, semi-manufactured, or powdered form", lab == 
                                               "Embarcações de recreio ou desporto" ~ "Pleasure or sports vessels", lab == 
                                               "Calhaus, cascalho e pedras britadas" ~ "Pebbles, gravel, and crushed stones", lab == 
                                               "Perfis de ferro ou aço não ligado" ~ "Iron or non-alloy steel profiles", lab == 
                                               "Monofilamentos, varas, bastões, de plásticos" ~ "Plastics monofilaments, rods, and sticks", lab == 
                                               "Grãos de cereais trabalhados, menos arroz" ~ "Processed cereal grains, except rice", lab == 
                                               "Calçados" ~ "Footwear", lab == 
                                               "Diamantes não montados ou engastados" ~ "Unmounted or unset diamonds", lab == 
                                               "Outros calçados com plástico ou borracha" ~ "Other footwear with plastic or rubber", lab == 
                                               "Carrocerias para veículos" ~ "Vehicle bodies", lab == 
                                               "Farinhas, semolas, pós de legumes" ~ "Flours, semolina, vegetable powders", lab ==  
                                               "Sementes, frutos e esporos, para sementeira" ~ "Seeds, fruits, and spores for sowing", lab == 
                                               "Recipientes de ferro e aço para gases" ~ "Iron and steel containers for gases", lab == 
                                               "Bombas para líquidos" ~ "Pumps for liquids", lab == 
                                               "Sabões e preparações para lavar pele" ~ "Soaps and preparations for skin cleansing", lab == 
                                               "Animais vivos da espécie bovina" ~ "Live animals of the bovine species", lab == 
                                               "Frutas cozidas ou não, misturadas ou não" ~ "Cooked or uncooked fruits, mixed or unmixed", lab == 
                                               "Óleo de palma não modificado" ~ "Unmodified palm oil", lab == 
                                               "Pasta química de madeira, para dissolução" ~ "Wood chemical pulp for dissolving", lab == 
                                               "Pastas químicas de madeira" ~ "Wood chemical pulps", lab == 
                                               "Peixes secos, salgados ou cozidos" ~ "Dried, salted, or cooked fish", lab == 
                                               "Estatuetas e objetos de ornamentação" ~ "Statuettes and ornamental objects", lab == 
                                               "Crustáceos vivos ou não, para alimento" ~ "Live or non-live crustaceans for food", lab == 
                                               "Corindo, óxido e hidróxido de alumínio" ~ "Corundum, aluminum oxide, and hydroxide", lab == 
                                               "Alumínio em formas brutas" ~ "Aluminum in raw forms", lab == 
                                               "Caolim e outras argilas caulínicas" ~ "Kaolin and other kaolinic clays", lab == 
                                               "Máquinas e ferramentas de trabalhar metais" ~ "Machinery and tools for working metals", lab == 
                                               "Adubos minerais ou químicos" ~ "Mineral or chemical fertilizers", lab == 
                                               "Gorduras animais ou vegetais hidrogenadas" ~ "Hydrogenated animal or vegetable fats", lab == 
                                               "Hidrogênio e mais elementos não metálicos" ~ "Hydrogen and other non-metallic elements", lab == 
                                               "Madeira em bruto" ~ "Rough wood", lab == 
                                               "Sacos de quaisquer dimensões, para embalagem" ~ "Bags of any dimensions for packaging", lab == 
                                               "Folhas, ramos e outras partes de planta" ~ "Leaves, branches, and other plant parts", lab == 
                                               "Flores, folhagem e frutos artificiais" ~ "Artificial flowers, foliage, and fruits", lab == 
                                               "Produtos animais impróprios para alimentação" ~ "Animal products unsuitable for consumption", lab == 
                                               "Flores e seus botões para ornamentos" ~ "Flowers and their buds for ornamentation", lab == 
                                               "Minérios de cobre e seus concentrados" ~ "Copper ores and their concentrates", lab == 
                                               "Minérios de ferro e seus concentrados" ~ "Iron ores and their concentrates", lab == 
                                               "Amidos e féculas; inulina" ~ "Starches and flours; inulin", lab == 
                                               "Citrinos, frescos ou secos" ~ "Citrus fruits, fresh or dried", lab == 
                                               "Partes para veículos de sh4 8701 a 8705" ~ "Parts for vehicles of HS 8701 to 8705", lab == 
                                               "Tubos e perfis de ferro ou aço" ~ "Iron or steel tubes and profiles", lab == 
                                               "Carvão vegetal" ~ "Charcoal", lab == 
                                               "Minérios de alumínio e seus concentrados" ~ "Aluminum ores and their concentrates", lab == 
                                               "Ferro fundido e outras formas primárias" ~ "Cast iron and other primary forms", lab == 
                                               "Outras frutas de casca rija" ~ "Other nuts", lab == 
                                               "Instrumentos automáticos para regulação" ~ "Automatic regulating instruments", lab == 
                                               "Níquel em formas brutas" ~ "Nickel in raw forms", lab == 
                                               "Queijos e requeijão" ~ "Cheese and curd", lab == 
                                               "Outros instrumentos musicais de cordas" ~ "Other string musical instruments", lab == 
                                               "Instrumentos musicais elétricos" ~ "Electric musical instruments", lab == 
                                               "Artigos para atividades físicas" ~ "Articles for physical activities", lab == 
                                               "Outras obras de madeira" ~ "Other wooden articles", lab == 
                                               "Microfones, alto-falantes, amplificadores, etc" ~ "Microphones, loudspeakers, amplifiers, etc.", lab == 
                                               "Fornos elétricos industriais" ~ "Industrial electric furnaces", lab == 
                                               "Fluidos para sistemas hidráulicos" ~ "Fluids for hydraulic systems", lab == 
                                               "Minérios de cromo e seus concentrados" ~ "Chromium ores and their concentrates", lab == 
                                               "Areias naturais de qualquer espécie" ~ "Natural sands of any kind", lab == 
                                               "Lenha em qualquer estado" ~ "Firewood in any condition", lab == 
                                               "Arcos e estacas de madeira" ~ "Wooden arches and stakes", lab == 
                                               "Preparações cosméticas e banho" ~ "Cosmetic and bath preparations", lab ==  
                                               "Vestimentas para esportes e banho" ~ "Sportswear and swimwear", lab == 
                                               "Fosfatos naturais" ~ "Natural phosphates", lab == 
                                               "Algodão, não cardado nem penteado" ~ "Cotton, not carded or combed", lab == 
                                               "Obras de cestaria e lufa" ~ "Basketware and luffa works", lab == 
                                               "Partes para máquinas de sh4 8456 a 8465" ~ "Parts for machines of HS 8456 to 8465", lab == 
                                               "Mangas, abacaxis, abacates, figos, etc" ~ "Mangoes, pineapples, avocados, figs, etc.", lab == 
                                               "Outras obras de plástico e outros materiais" ~ "Other plastic and other material works", lab == 
                                               "Quadros e desenhos feitos a mão" ~ "Handmade paintings and drawings", lab == 
                                               "Pedra-pomes, esmeril e outros abrasivos" ~ "Pumice stone, emery, and other abrasives", lab == 
                                               "Melões, melancias e papaias frescos" ~ "Fresh melons, watermelons, and papayas", lab == 
                                               "Aparelhos de topografia, nivelamento, etc" ~ "Surveying, leveling, etc. instruments", lab == 
                                               "Polímeros de olefinas halogenadas" ~ "Halogenated olefin polymers", lab == 
                                               "Outras chapas e tiras de plástico" ~ "Other plastic sheets and strips", lab == 
                                               "Glicerol, lixívias, glicéricas" ~ "Glycerol, lyes, glycerides", lab == 
                                               "Carvões e matérias minerais ativadas" ~ "Activated carbons and mineral materials", lab == 
                                               "Aparas e desperdícios de couros e peles" ~ "Leather and fur cuttings and waste", lab == 
                                               "Couro reconstítuido" ~ "Reconstituted leather", lab == 
                                               "Castinas e calcárias para cimento" ~ "Calcined and hydraulic limestones for cement", lab == 
                                               "Máquinas para colheita e debulha" ~ "Harvesting and threshing machinery", lab == 
                                               "Heterósidos naturais ou sintéticos" ~ "Natural or synthetic heterosides", lab == 
                                               "Preparações capilares" ~ "Hair preparations", lab == 
                                               "Pastas, gazes e análogos para usos medicinais" ~ "Medicinal pastes, gauzes, and analogues", lab == 
                                               "Outras frutas frescas" ~ "Other fresh fruits", lab == 
                                               "Couros e peles de bovinos ou equídeos" ~ "Bovine or equine hides and skins", lab == 
                                               "Outras obras de couro natural ou reconstituído" ~ "Other natural or reconstituted leather works", lab == 
                                               "Assentos" ~ "Seats", lab == 
                                               "Óleos de coco, palmiste ou babaçu" ~ "Coconut, palm kernel, or babassu oils", lab == 
                                               "Tubos e seus acessórios de plástico" ~ "Plastic tubes and their accessories", lab == 
                                               "Outros calçados" ~ "Other footwear", lab == 
                                               "Roupas íntimas e pijamas femininos" ~ "Women's underwear and pajamas", lab == 
                                               "Enzimas e enzimas preparadas" ~ "Enzymes and prepared enzymes", lab == 
                                               "Carnes suínas refrigeradas ou congeladas" ~ "Chilled or frozen pork", lab == 
                                               "Âncoras e fateixas de ferro ou aço" ~ "Iron or steel anchors and grapnels", lab == 
                                               "Águas minerais sem aditivos" ~ "Mineral waters without additives", lab == 
                                               "Vestimentas de uso masculino" ~ "Men's clothing", lab == 
                                               "Aparelhos para medicina e veterinária" ~ "Medical and veterinary instruments", lab == 
                                               "Chaves de porcas e de caixa" ~ "Wrenches and spanners", lab == 
                                               "Aparelhos de laboratórios fotográficos" ~ "Photographic laboratory equipment", lab == 
                                               "Carnes bovinas frescas ou refrigeradas" ~ "Fresh or chilled beef", lab == 
                                               "Aparelhos para selecionar pedras" ~ "Stone sorting apparatus", lab == 
                                               "Gelatina e colas de origem animal" ~ "Gelatin and animal glues", lab == 
                                               "Dispositivo para tratamento de materiais" ~ "Materials treatment devices", lab == 
                                               "Outras preparações de carne e miudezas" ~ "Other meat and offal preparations", lab == 
                                               "Cervejas de malte" ~ "Malt beers", lab == 
                                               "Aparelhos de iluminação e suas partes" ~ "Lighting fixtures and their parts", lab == 
                                               "Dormentes de madeira para vias férreas" ~ "Wooden sleepers for railway tracks", lab == 
                                               "Artefatos de joalheria de metais" ~ "Metal jewelry articles", lab == 
                                               "Vestimentas de malha de uso masculino" ~ "Men's knitted clothing", lab == 
                                               "Carnes e comestíveis salgadas ou secas" ~ "Salted or dried meats and edibles", lab == 
                                               "Gorduras animais bovino, ovino e caprino" ~ "Bovine, ovine, and caprine animal fats", lab == 
                                               "Legumes de vagem em grão secos" ~ "Dried leguminous vegetables", lab == 
                                               "Minérios de metais preciosos" ~ "Precious metal ores", lab == 
                                               "Granito e outras pedras para construção" ~ "Granite and other stones for construction", lab == 
                                               "Outros couros e peles em bruto" ~ "Other raw hides and skins", lab == 
                                               "Couros e peles de animais sem pelos" ~ "Hairless animal hides and skins", lab == 
                                               "Melaços da extração e refino do açúcar" ~ "Molasses from sugar extraction and refining",
                                               TRUE ~ lab
                                                #######
                                          ),
                          nome_sh2 = case_when( nome_sh2 == "Madeira, carvão vegetal e obras de madeira" ~ "Wood, charcoal, and woodworks", nome_sh2 == 
                                                "Peixes e invertebrados aquáticos" ~ "Fish and aquatic invertebrates", nome_sh2 == 
                                                "Estanho e suas obras" ~ "Tin and its works", nome_sh2 == 
                                                "Preparações de vegetais, frutas e outros" ~ "Preparations of vegetables, fruits, and others", nome_sh2 == 
                                                "Minérios, escórias e cinzas" ~ "Ores, slag, and ashes", nome_sh2 == 
                                                "Café, chá, mate e especiarias" ~ "Coffee, tea, mate, and spices", nome_sh2 == 
                                                "Outros produtos de origem vegetal" ~ "Other plant-based products", nome_sh2 == 
                                                "Cereais" ~ "Cereals", nome_sh2 == 
                                                "Sementes, grãos e frutos diversos" ~ "Seeds, grains, and various fruits", nome_sh2 == 
                                                "Aeronaves e aparelhos espaciais, e suas partes" ~ "Aircraft and spacecraft, and their parts", nome_sh2 == 
                                                "Desperdícios das indústrias alimentares" ~ "Food industry waste", nome_sh2 == 
                                                "Peles, exceto as com pelo, e couros" ~ "Skins, excluding fur, and leather", nome_sh2 == 
                                                "Vestuário, exceto de malha" ~ "Clothing, except knitted", nome_sh2 == 
                                                "Reatores, caldeiras e aparelhos mecânicos" ~ "Reactors, boilers, and mechanical appliances", nome_sh2 == 
                                                "Vestuário, de malha" ~ "Knitted clothing", nome_sh2 == 
                                                "Aparelhos de som e imagem" ~ "Sound and image devices", nome_sh2 == 
                                                "Veículos terrestres" ~ "Land vehicles", nome_sh2 == 
                                                "Pedras e metais preciosos, bijuterias" ~ "Precious stones and metals, costume jewelry", nome_sh2 == 
                                                "Açúcares e produtos de confeitaria" ~ "Sugars and confectionery products", nome_sh2 == 
                                                "Gorduras e óleos animais ou vegetais" ~ "Animal or vegetable fats and oils", nome_sh2 == 
                                                "Carnes e miudezas, comestíveis" ~ "Meat and edible offal", nome_sh2 == 
                                                "Frutas, cascas de cítricos e de melões" ~ "Fruits, citrus and melon peels", nome_sh2 == 
                                                "Sal, enxofre, cimento, terras e pedras" ~ "Salt, sulfur, cement, earth, and stones", nome_sh2 == 
                                                "Obras de pedra, cimento, gesso e outros" ~ "Stone, cement, plaster, and other works", nome_sh2 == 
                                                "Mobiliário, iluminação, entre outros" ~ "Furniture, lighting, and others", nome_sh2 == 
                                                "Cacau e suas preparações" ~ "Cocoa and its preparations", nome_sh2 == 
                                                "Gomas, resinas e outros extratos vegetais" ~ "Gums, resins, and other plant extracts", nome_sh2 == 
                                                "Ferramentas, cutelaria e talheres" ~ "Tools, cutlery, and utensils", nome_sh2 == 
                                                "Bebidas, líquidos alcoólicos e vinagres" ~ "Beverages, alcoholic liquids, and vinegars", nome_sh2 == 
                                                "Transações especiais" ~ "Special transactions", nome_sh2 == 
                                                "Produtos cerâmicos" ~ "Ceramic products", nome_sh2 == 
                                                "Outros produtos de origem animal" ~ "Other animal-based products", nome_sh2 == 
                                                "Aparelhos médicos, fotografia e de medida" ~ "Medical, photographic, and measuring devices", nome_sh2 == 
                                                "Borracha e suas obras" ~ "Rubber and its works", nome_sh2 == 
                                                "Obras de couro, tripa, bolsas e outros" ~ "Leather, gut, bags, and other works", nome_sh2 == 
                                                "Combustíveis, óleos e ceras minerais" ~ "Fuels, mineral oils, and waxes", nome_sh2 == 
                                                "Leite, ovos, mel e outros de origem animal" ~ "Milk, eggs, honey, and other animal-based products", nome_sh2 == 
                                                "Produtos farmacêuticos" ~ "Pharmaceutical products", nome_sh2 == 
                                                "Preparações alimentícias diversas" ~ "Various food preparations", nome_sh2 == 
                                                "Óleos essenciais, perfumaria e cosméticos" ~ "Essential oils, perfumery, and cosmetics", nome_sh2 == 
                                                "Outros metais comuns e suas obras" ~ "Other common metals and their works", nome_sh2 == 
                                                "Ferro fundido, ferro e aço" ~ "Cast iron, iron, and steel", nome_sh2 == 
                                                "Embarcações e estruturas flutuantes" ~ "Vessels and floating structures", nome_sh2 == 
                                                "Plásticos e suas obras" ~ "Plastics and their works", nome_sh2 == 
                                                "Produtos de moagem, amidos e féculas" ~ "Milling products, starches, and starches", nome_sh2 == 
                                                "Calçados, polainas e semelhantes" ~ "Footwear, gaiters, and similar", nome_sh2 == 
                                                "Obras de ferro fundido, ferro ou aço" ~ "Cast iron, iron, or steel works", nome_sh2 == 
                                                "Sabões, ceras e produtos de limpeza" ~ "Soaps, waxes, and cleaning products", nome_sh2 == 
                                                "Animais vivos" ~ "Live animals", nome_sh2 == 
                                                "Pastas de madeira e papel para reciclar" ~ "Wood and paper pulp for recycling", nome_sh2 == 
                                                "Produtos químicos inorgânicos" ~ "Inorganic chemical products", nome_sh2 == 
                                                "Alumínio e suas obras" ~ "Aluminum and its works", nome_sh2 == 
                                                "Adubos (fertilizantes)" ~ "Fertilizers", nome_sh2 == 
                                                "Artefatos têxteis, chapéus e calçados" ~ "Textile articles, hats, and footwear", nome_sh2 == 
                                                "Plantas vivas e produtos de floricultura" ~ "Live plants and floriculture products", nome_sh2 == 
                                                "Penas e suas obras e flores artificiais" ~ "Feathers and their works, and artificial flowers", nome_sh2 == 
                                                "Níquel e suas obras" ~ "Nickel and its works", nome_sh2 == 
                                                "Instrumentos musicais e suas partes" ~ "Musical instruments and their parts", nome_sh2 == 
                                                "Brinquedos, jogos e artigos para esporte" ~ "Toys, games, and sports articles", nome_sh2 == 
                                                "Produtos diversos das indústrias químicas" ~ "Various chemical industry products", nome_sh2 == 
                                                "Algodão" ~ "Cotton", nome_sh2 == 
                                                "Obras de espartaria ou de cestaria" ~ "Wicker or basketware works", nome_sh2 == 
                                                "Objetos de arte, coleção e antiguidades" ~ "Works of art, collectibles, and antiques", nome_sh2 == 
                                                "Produtos químicos orgânicos" ~ "Organic chemical products", nome_sh2 == 
                                                "Produtos de amido, enzimas, albuminóides" ~ "Starch, enzymes, albuminoid products", nome_sh2 == 
                                                "Preparações de carne, peixes e outros" ~ "Preparations of meat, fish, and others", nome_sh2 ==
                                                "Produtos hortícolas e plantas, comestíveis" ~ "Horticultural and edible plant products"
                                                 #######
                                             )
                                                
                          )
  }
  
  server <- function(input, output, session) {
    df_reactived <- reactive({
      w <- df %>%
        filter(time == input$filter1)

      if (input$x == param$forest) {
          w <- w %>% 
            filter(floresta)
      } else {
        w <- w %>% 
          filter(!floresta)
      }
      
      return(w)
    })

    # Cria opções para seleção de datas
    param$filter_choices <- sort(unique(df$time))

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      updateSelectizeInput(session,
                           "filter1",
                           choices = param$filter_choices,
                           selected = param$year_final
      )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "x=", input$x,
        "&", "filter=", input$filter1
      )

      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      # Preenche filtro vazio
      selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
      updateSelectizeInput(session,
        "filter1",
        choices = param$filter_choices,
        selected = selected
      )

      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      # Se query está vazia, preenche aleatório
      if (is.null(query[["filter"]])) {
        random_inputs() # preenche inputs se estiverem vazios
      }
    }

    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$filter1) || input$filter1 == "") {
        text <- " "
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        text <- paste0(param$titulo1)
      }

      text
    })
    output$plot_subtitle <- renderText({
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$filter1) || input$filter1 == "") {
        text <- param$titulo2
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        text <- paste0(param$titulo3, input$x)
      }

      text
    })

    # Output gráfico
    output$map <- renderLeaflet({

      # random_inputs() #preenche inputs se estiverem vazios
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- leaflet() %>%
        addProviderTiles(provider = "CartoDB.VoyagerNoLabels") %>%
        setView(-58, -7, zoom = 5) # inicia figura com gráfico em branco

      # Define paleta de cores
      pal1 <- pallete_continuous
      if (!is.numeric(df_reactived()[["nome_sh2"]])) {
        pal1 <- pallete_discrete
      }

      # Determina a paleta para as legendas
      pal <- colorFactor(palette = pal1, domain = df[["nome_sh2"]])

      tryCatch(
        {
          
          # Monta mapa
          
          # Monta html do tooltip
          x_col <- param$table[which(param$table$var == "produto_principal"), ]
          title_legend <- paste0("", x_col$label)
          labels <- paste0(
              param$tooltip1, df_reactived()$nm_municip, "</b> <br>",
              param$tooltip2, df_reactived()$uf, "</b> <br>",
              param$tooltip3, df_reactived()[["produto_principal"]], "</b> <br>",
              param$tooltip4, df_reactived()[["nome_sh2"]], "</b> <br>",
              param$tooltip5, format(df_reactived()$maximo_produto, scientific = FALSE,
                                  digits = 2,
                                  decimal.mark = ",", 
                                  big.mark = "."), "<br>",
              param$tooltip6, param$tooltip7, "</b>"
          ) %>%
            lapply(htmltools::HTML)

          fig_p <- df_reactived() %>% 
            leaflet() %>%
            addProviderTiles(provider = "CartoDB.VoyagerNoLabels") %>%
            setView(-58, -7, zoom = 5) %>%
            addPolygons(
              data = df_reactived(),
              label = labels,
              stroke = FALSE,
              smoothFactor = .5,
              fillOpacity = 0.7,
              fillColor = ~ pal(df_reactived()[["nome_sh2"]]),
              highlightOptions = highlightOptions(
                weight = 5,
                fillOpacity = 1,
                color = "black",
                opacity = 1,
                bringToFront = TRUE
              )
            ) %>%
            addLegend("bottomright",
              pal = pal,
              values = ~ df_reactived()[["nome_sh2"]],
              title = param$legend,
              opacity = 0.7
            )

          fig <- fig_p # retorna a figura do gráfico
        },
        error = function(cond) {
          # se encontrar erro retorna fig em branco
          print("Plot error in tryCatch environment")
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
