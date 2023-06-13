
# packages ----------------------------------------------------------------
library(tidyverse)
library(sf)
library(sp)


# load data ---------------------------------------------------------------
dat <- readRDS(file = "data/comex_munic_raw.rds")
aux <- readRDS("data/auxiliar_cod_sh4.rds")

shapefile <- st_read("data/shapefiles/municipalities_legal_amazon.shp") %>% 
  sf::st_simplify(dTolerance = 400) %>% 
  sf::st_make_valid() %>% 
  mutate(cod_ibge = as.numeric(cod_ibge))

shapefile <- shapefile[!st_is_empty(shapefile), , drop=FALSE]


# get all municipalities --------------------------------------------------
munis <- tibble(cod_ibge = shapefile$cod_ibge)


#keep nome_sh4 and cod_sh4 correspondence ---------------------------------
sh4= dat %>%
  select(lab = nome_sh4, cod_sh4) %>%
  unique()


# aggregate ---------------------------------------------------------------
agg_dat <- dat %>% 
  group_by(ano, cod_municipio, nome_sh4) %>% 
  summarise(value = sum(valor_fob)) %>% 
  filter(nome_sh4 %in% c("Peixes vivos",
                         "Peixes frescos ou refrigerados, exceto os files de peixes e outra carne de peixes da posicao 03.04",
                         "Peixes congelados, exceto os files de peixes e outra carne de peixes da posicao 03.04",
                         "Files de peixes e outra carne de peixes (mesmo picada), frescos, refrigerados ou congelados",
                         "Peixes secos, salgados ou em salmoura; peixes defumados, mesmo cozidos antes ou durante a defumacao; farinhas, pos e pellets, de peixe, proprios para alimentacao humana",
                         "Crustaceos, mesmo sem casca, vivos, frescos, refrigerados, congelados, secos, salgados ou em salmoura; crustaceos com casca, cozidos em agua ou vapor, mesmo refrigerados, congelados, secos, salgados ou em salmoura; farinhas, po e pellets de crustaceos, pr",
                         "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados",
                         "Frutas, nao cozidas ou cozidas em agua ou vapor, congeladas, mesmo adicionadas de acucar ou de outros edulcorantes",
                         "Pimenta (do genero Piper); pimentos dos generos Capsicum ou Pimenta, secos ou triturados ou em po",
                         "Outras sementes e frutos oleaginosos, mesmo triturados",
                         "Goma-laca; gomas, resinas, gomas-resinas e oleorresinas (balsamos por exemplo), naturais",
                         "Oleo de palma e respectivas fraccoes, mesmo refinados, mas nao quimicamente modificados",
                         "Outras gorduras e oleos vegetais (incluido o oleo de jojoba) e respectivas fraccoes, fixos, mesmo refinados, mas nao quimicamente modificados",
                         "Cacau inteiro ou partido, em bruto ou torrado",
                         "Frutas e outras partes comestiveis de plantas, preparadas ou conservadas de outro modo, com ou sem adicao de acucar ou de outros edulcorantes ou de alcool, nao especificadas nem compreendidas noutras posicoes",
                         "Sumos de frutas (incluidos os mostos de uvas) ou de produtos horticolas, nao fermentados, sem adicao de alcool, com ou sem adicao de acucar ou de outros edulcorantes")) %>% 
  ungroup() %>% 
  rename(time = ano, cod_ibge = cod_municipio, group = nome_sh4) %>% 
  right_join(munis) %>% 
  complete(time, cod_ibge, group) %>% 
  replace_na(list(value = 0)) %>% 
  filter(!is.na(group), !is.na(time), !is.na(cod_ibge)) %>% 
  pivot_wider(names_from = group, values_from = value) %>% 
  rowwise() %>%
  mutate(maximo_produto = max(c_across(`Cacau inteiro ou partido, em bruto ou torrado`:`Sumos de frutas (incluidos os mostos de uvas) ou de produtos horticolas, nao fermentados, sem adicao de alcool, com ou sem adicao de acucar ou de outros edulcorantes`)))

agg_dat$produto_principal <- 
  agg_dat %>% 
  select(`Cacau inteiro ou partido, em bruto ou torrado`:`Sumos de frutas (incluidos os mostos de uvas) ou de produtos horticolas, nao fermentados, sem adicao de alcool, com ou sem adicao de acucar ou de outros edulcorantes`) %>% 
  {names(.)[max.col(.)]}

agg_dat <- agg_dat %>% 
  mutate(produto_principal = ifelse(maximo_produto == 0, NA, produto_principal)) %>% 
  mutate(lab = produto_principal,
         produto_principal = ifelse(nchar(produto_principal) >= 40,
                                    paste0(substr(produto_principal, 1, 40), "..."),
                                    produto_principal))


# aggregate with all products ---------------------------------------------
agg_dat_all <- dat %>% 
  group_by(ano, cod_municipio, nome_sh4) %>% 
  summarise(value = sum(valor_fob)) %>% 
  ungroup() %>% 
  rename(time = ano, cod_ibge = cod_municipio, group = nome_sh4) %>% 
  right_join(munis) %>% 
  complete(time, cod_ibge, group) %>% 
  replace_na(list(value = 0)) %>% 
  filter(!is.na(group), !is.na(time), !is.na(cod_ibge)) %>% 
  pivot_wider(names_from = group, values_from = value) %>% 
  rowwise() %>%
  mutate(maximo_produto_todos = max(c_across(`<<Tecidos turcos>>, exceto os artefactos da posicao 5806; tecidos tufados, exceto os artefactos da posicao 5703`:`Zinco em formas brutas`)))

agg_dat_all$produto_principal_todos <- 
  agg_dat_all %>% 
  select(`<<Tecidos turcos>>, exceto os artefactos da posicao 5806; tecidos tufados, exceto os artefactos da posicao 5703`:`Zinco em formas brutas`) %>% 
  {names(.)[max.col(.)]}

agg_dat_all <- agg_dat_all %>% 
  mutate(produto_principal_todos = ifelse(maximo_produto_todos == 0, NA, produto_principal_todos)) %>% 
  mutate(lab_todos = produto_principal_todos,
         produto_principal_todos = ifelse(nchar(produto_principal_todos) >= 40,
                                    paste0(substr(produto_principal_todos, 1, 40), "..."),
                                           produto_principal_todos))


# join tables -------------------------------------------------------------
agg_dat_selcolumns <- agg_dat %>% 
  select(time, cod_ibge, maximo_produto, produto_principal, lab,) %>% 
  mutate(floresta = TRUE)

agg_dat_all_selcolumns <- agg_dat_all %>% 
  select(time, cod_ibge, 
         maximo_produto = maximo_produto_todos, 
         produto_principal = produto_principal_todos, 
         lab = lab_todos) %>% 
  mutate(floresta = FALSE)

df_final <- rbind(agg_dat_selcolumns, agg_dat_all_selcolumns) %>% 
  data.frame() %>% 
  tibble()
  

#add sh4 code -------------------------------------------------------------
df_final <- df_final %>%
  left_join(sh4)


# value as relative -------------------------------------------------------
total_value_amz <- dat %>% 
  group_by(ano, nome_sh4) %>% 
  summarise(value = sum(valor_fob))

change_to_relative_value <- function(valor, ano_produto, produto) {
  
  valor_total <- total_value_amz %>% 
    filter(nome_sh4 == produto, ano == ano_produto) %>% 
    pull(value)
  
  return((valor/valor_total) * 100)
  
}

df_final <- df_final %>% 
  rowwise() %>% 
  mutate(maximo_produto = ifelse(maximo_produto != 0,
                                 change_to_relative_value(maximo_produto, time, lab),
                                 0))



###sh2 code and sh2 name columns
df_final$cod_sh2 <- gsub('.{2}$', '', df_final$cod_sh4)

df_final$cod_sh2 <- as.numeric(df_final$cod_sh2)
df_final$nome_sh2 <- df_final$cod_sh2
df_final$nome_sh2 <- plyr::mapvalues(df_final$nome_sh2, from = aux$CO_SH2, to = aux$NO_SH2_POR)

# df_final$nome_sh2 <- ifelse(nchar(df_final$nome_sh2) >= 40,
#                             paste0(substr(df_final$nome_sh2, 1, 40), "..."),
#                             df_final$nome_sh2)



# merge with shape --------------------------------------------------------
data <- sp::merge(shapefile, data.frame(df_final)) %>% 
  select(-fid, -cd_geocmu)

st_geometry(data) <- data$geometry


# export ------------------------------------------------------------------
# save simplified sf for faster maps
cols <- colnames(data)
data <- rmapshaper::ms_simplify(data, 
                                keep_shapes = TRUE, 
                                keep = 0.01)

#simplifying products' names to fit the map
{
data= data%>%
  mutate(lab= case_when(lab == "Peixes vivos" ~ "Peixes vivos",
                        lab == "Peixes frescos ou refrigerados, exceto os files de peixes e outra carne de peixes da posicao 03.04" ~ "Peixes frescos/refrigerados, exceto filés",
                        lab == "Peixes congelados, exceto os files de peixes e outra carne de peixes da posicao 03.04" ~ "Peixes congelados, exceto filés",
                        lab == "Files de peixes e outra carne de peixes (mesmo picada), frescos, refrigerados ou congelados" ~ "Filés de peixe e outras carnes",
                        lab == "Peixes secos, salgados ou em salmoura; peixes defumados, mesmo cozidos antes ou durante a defumacao; farinhas, pos e pellets, de peixe, proprios para alimentacao humana" ~ "Peixes secos, salgados ou cozidos",
                        lab == "Crustaceos, mesmo sem casca, vivos, frescos, refrigerados, congelados, secos, salgados ou em salmoura; crustaceos com casca, cozidos em agua ou vapor, mesmo refrigerados, congelados, secos, salgados ou em salmoura; farinhas, po e pellets de crustaceos, pr" ~ "Crustaceos vivos ou não, para alimento",
                        lab == "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados" ~ "Cocos e castanhas do Brasil e de caju",
                        lab == "Frutas, nao cozidas ou cozidas em agua ou vapor, congeladas, mesmo adicionadas de acucar ou de outros edulcorantes" ~ "Frutas cozidas ou não, misturadas ou não",
                        lab == "Pimenta (do genero Piper); pimentos dos generos Capsicum ou Pimenta, secos ou triturados ou em po" ~ "Pimentas secas ou trituradas",
                        lab == "Outras sementes e frutos oleaginosos, mesmo triturados" ~ "Outras sementes e oleaginosos",
                        lab == "Goma-laca; gomas, resinas, gomas-resinas e oleorresinas (balsamos por exemplo), naturais" ~ "Gomas e resinas naturais",
                        lab == "Oleo de palma e respectivas fraccoes, mesmo refinados, mas nao quimicamente modificados" ~ "Óleo de palma não modificado",
                        lab == "Outras gorduras e oleos vegetais (incluido o oleo de jojoba) e respectivas fraccoes, fixos, mesmo refinados, mas nao quimicamente modificados" ~ "Outras gorduras e óleos vegetais",
                        lab == "Cacau inteiro ou partido, em bruto ou torrado" ~ "Cacau bruto ou torrado",
                        lab == "Frutas e outras partes comestiveis de plantas, preparadas ou conservadas de outro modo, com ou sem adicao de acucar ou de outros edulcorantes ou de alcool, nao especificadas nem compreendidas noutras posicoes" ~ "Frutas e outros comestíveis de planta",
                        lab == "Sumos de frutas (incluidos os mostos de uvas) ou de produtos horticolas, nao fermentados, sem adicao de alcool, com ou sem adicao de acucar ou de outros edulcorantes" ~ "Sumos de frutas, com ou sem aditivos",
                        lab == "Madeira serrada ou endireitada longitudinalmente, cortada ou desenrolada, mesmo aplainada, polida ou unida pelas extremidades, de espessura superior a 6 mm" ~"Madeira cortada, desenrolada ou polida" ,
                        lab == "Cafe, mesmo torrado ou descafeinado; cascas e peliculas de cafe; sucedaneos do cafe contendo cafe em qualquer proporcao" ~ "Café torrado, cascas e sucedâneos", 
                        lab == "Produtos vegetais nao especificados nem compreendidos noutras posicoes"~"Produtos vegetais nao especificados",
                        lab == "Outros veiculos aereos (por exemplo: helicopteros, avioes); veiculos espaciais (incluidos os satelites) e seus veiculos de lancamento e veiculos suborbitais" ~ "Outros veículos aéreos"   ,
                        lab == "Farinhas, po e pellets, de carnes, miudezas, peixes ou crustaceos, moluscos ou outros invertebrados aquaticos, improprios para a alimentacao humana; torresmos" ~ "Farinhas animais impróprias para consumo" ,
                        lab == "Acucares de cana ou de beterraba e sacarose quimicamente pura, no estado solido" ~ "Açúcares no estado sólido" ,
                        lab == "Adubos (fertilizantes) minerais ou quimicos, fosfatados" ~ "Adubos minerais ou químicos",
                        lab == "Aguas, incluidas as aguas minerais e as aguas gaseificadas, adicionadas de acucar ou de outros edulcorantes ou aromatizadas e outras bebidas nao alcoolicas, exceto sumos de frutas ou de produtos horticolas, da posicao 2009" ~ "Águas mineirais com aditivos",
                        lab == "Aguas, incluidas as aguas minerais, naturais ou artificiais, e as aguas gaseificadas, nao adicionadas de acucar ou de outros edulcorantes nem aromatizadas; gelo e neve" ~ "Águas mineirais sem aditivos",
                        lab == "Ancoras, fateixas, e suas partes, de ferro fundido, ferro ou aco" ~ "Âncoras e fateixas de ferro ou aço",
                        lab == "Aparas e outros desperd.de couros/peles, preparados, etc." ~ "Aparas e desperdícios de couros e peles",
                        lab == "Aparelhos de iluminacao (incluidos os projectores) e suas partes, nao especificados nem compreendidos em outras posicoes; anuncios, tabuletas ou cartazes e placas indicadoras luminosos, e artigos semelhantes, que contenham uma fonte luminosa fixa permanen" ~ "Aparelhos de iluminação e suas partes",
                        lab == "Aparelhos e dispositivos, mesmo aquecidos electricamente (exceto fornos e outros aparelhos da posicao 8514), para tratamento de materias por meio de operacoes que impliquem mudanca de temperatura, tais como o aquecimento, cozimento, torrefaccao, destilac" ~ "Dispositivo para tratamento de materiais",
                        lab == "Aparelhos e material dos tipos usados nos laboratorios fotograficos ou cinematograficos (incluidos os aparelhos para projeccao ou execucao de tracados de circuitos sobre superficies sensibilizadas de materiais semicondutores), nao especificados nem compre" ~ "Aparelhos de laboratórios fotográficos",
                        lab == "Aparelhos eletricos para telefonia ou telegrafia por fios, incluidos os aparelhos telefonicos por fio combinados com auscultadores sem fio e os aparelhos de telecomunicacao por corrente portadora ou de telecomunicacao digital; videofones" ~ "Aparelhos para telefonia por fios",
                        lab == "Aparelhos emissores (transmissores) para radiotelefonia, radiotelegrafia, radiodifusao ou televisao, mesmo incorporando um aparelho de recepcao ou um aparelho de gravacao ou de reproducao de som; camaras de televisao; camaras de video de imagens fixas e o" ~ "Aparelhos emissores para rádio",   
                        lab == "Aparelhos para interrupcao, seccionamento, proteccao, derivacao, ligacao ou conexao de circuitos eletricos (por exemplo: interruptores, comutadores, reles, corta-circuitos, eliminadores de onda, tomadas de corrente, machos e femeas, suportes para lampada" ~ "Aparelhos para circuitos elétricos",
                        lab == "Arcos de madeira; estacas fendidas; estacas agucadas, nao serradas longitudinalmente; madeira simplesmente desbastada ou arredondada, nao torneada, nao recurvada nem trabalhada de qualquer outro modo, para fabricacao de bengalas, guarda-chuvas, cabos de f" ~ "Arcos e estacas de madeira",
                        lab == "Areias naturais de qualquer especie, mesmo coradas, exceto areias metaliferas do Capitulo 26" ~ "Areias naturais de qualquer espécie", 
                        lab == "Artefactos de joalharia e suas partes, de metais preciosos ou de metais folheados ou chapeados de metais preciosos" ~ "Artefatos de joalheria de metais",
                        lab == "Artigos e equipamentos para cultura fisica, ginastica, atletismo, outros desportos (incluido o tenis de mesa) ou jogos ao ar livre, nao especificados nem compreendidos em outras posicoes deste capitulo; piscinas, incluidas as infantis" ~ "Artigos para atividades físicas",
                        lab == "Assentos (exceto os da posicao 9402), mesmo transformaveis em camas, e suas partes" ~ "Assentos",
                        lab == "Bombas de ar ou de vacuo, compressores de ar ou de outros gases e ventiladores; exaustores (coifas aspirantes) para extraccao ou reciclagem, com ventilador incorporado, mesmo filtrantes" ~ "Bombas de ar, compressores, ventiladores",
                        lab == "Bombas para liquidos, mesmo com dispositivo medidor; elevadores de liquidos"  ~ "Bombas para líquidos",
                        lab == "Borracha natural, balata, guta-percha, guaiule, chicle e gomas naturais analogas, em formas primarias ou em chapas, folhas ou tiras" ~ "Borrachas e gomas em formas primárias",
                        lab == "Bulldozers, angledozers, niveladoras, raspo-transportadoras (scrapers), pas mecanicas, escavadoras, carregadoras e pas carregadoras, compactadores e rolos ou cilindros compressores, autopropulsores" ~ "Retroescavadoras e carregadoras",
                        lab == "Calcado com sola exterior de borracha, plastico, couro natural ou reconstituido e parte superior de materias texteis" ~ "Calçados",
                        lab == "Calhaus, cascalho, pedras britadas, dos tipos geralmente usados em betao (concreto) ou para empedramento de estradas, de vias ferreas ou outros balastros, seixos rolados e silex, mesmo tratados termicamente; macadame de escorias de altos fornos, de outras" ~ "Calhaus, cascalho e pedras britadas",
                        lab == "Carnes de animais da especie bovina, congeladas" ~ "Carnes bovinas congeladas",
                        lab == "Carnes de animais da especie bovina, frescas ou refrigeradas" ~ "Carnes bovinas frescas ou refrigeradas",
                        lab == "Carnes de animais da especie suina, frescas, refrigeradas ou congeladas" ~ "Carnes suínas refrigeradas ou congeladas",
                        lab == "Carnes e miudezas comestiveis, frescas, refrigeradas ou congeladas, das aves da posicao 0105" ~ "Carnes e comestíveis de aves domésticas",
                        lab == "Carnes e miudezas, comestiveis, salgadas ou em salmoura, secas ou defumadas; farinhas e pos, comestiveis, de carnes ou de miudezas" ~ "Carnes e comestíveis salgadas ou secas",
                        lab == "Carrocarias para os veiculos automoveis das posicoes 8701 a 8705, incluidas as cabinas" ~ "Carrocerias para veículos",
                        lab == "Carvao vegetal (incluindo o carvao de cascas ou de carocos), mesmo aglomerado" ~ "Carvão vegetal",  
                        lab == "Carvoes activados; materias minerais naturais activadas; negros de origem animal, incluido o negro animal esgotado" ~ "Carvões e matérias minerais ativadas"  ,
                        lab == "Castinas; pedras calcarias utilizadas na fabricacao de cal ou de cimento"  ~ "Castinas e calcárias para cimento" ,
                        lab == "Caulim e outras argilas caulinicas, mesmo calcinadas" ~ "Caulim e outras argilias caulínicas",
                        lab == "Chaves de porcas, manuais (incluidas as chaves dinamometricas); chaves de caixa intercambiaveis, mesmo com cabos" ~ "Chaves de porcas e de caixa",
                        lab == "Cimentos hidraulicos (incluidos os cimentos nao pulverizados, denominados clinkers), mesmo corados" ~ "Cimentos hidráulicos",
                        lab == "Combinacoes, saiotes, calcinhas, camisas de noite, pijamas, deshabilles, roupoes de banho, robes de quarto e semelhantes, de malha, de uso feminino" ~ "Roupas íntimas e pijamas femininos",
                        lab == "Consumo de bordo (combustiveis e lubrificantes para embarcacoes e aeronaves)" ~ "Consumo de bordo",
                        lab == "Corindo artificial, quimicamente definido ou nao; oxido de aluminio; hidroxido de aluminio" ~ "Corindo, óxido e hidróxido de alumínio",
                        lab == "Couro reconstituido a base de couro ou de fibras de couro, em chapas, folhas ou tiras, mesmo enroladas; aparas e outros desperdicios de couros ou de peles preparados ou de couro reconstituido, nao utilizaveis para fabricacao de obras de couro; serragem, p" ~ "Couro reconstítuido",
                        lab == "Couros e peles curtidos ou em crosta, de bovinos (incluindo os bufalos) ou de equideos, depilados, mesmo divididos, mas nao preparados de outro modo" ~ "Couros e peles curtidos ou em crosta" ,
                        lab == "Couros e peles em bruto de bovinos (incluindo os bufalos) ou de equideos (frescos, ou salgados, secos, tratados pela cal, << piclados >> ou conservados de outro modo, mas nao curtidos, nem apergaminhados nem preparados de outro modo), mesmo depilados ou div" ~ "Couros e peles de bovinos ou equideos",
                        lab == "Couros e peles, depilados, de outros animais e peles de animais desprovidos de pelos, curtidos ou em crosta, mesmo divididos, mas nao preparados de outro modo" ~ "Couros e peles de animais sem pelos",
                        lab == "Couros preparados apos curtimenta ou apos secagem e couros e peles apergaminhados, de bovinos (incluindo os bufalos) ou de equideos, depilados, mesmo divididos, exceto os da posicao 4114" ~ "Couros preparados após curtimenta",
                        lab == "Diamantes, mesmo trabalhados, mas nao montados nem engastados" ~ "Diamantes não montados ou engastados",
                        lab == "Dolomite, mesmo sinterizada ou calcinada, incluindo a dolomite desbastada ou simplesmente cortada a serra ou por outro meio, em blocos ou placas de forma quadrada ou rectangular; aglomerado de dolomite" ~ "Dolomite ou aglomerado de dolomite",
                        lab == "Dormentes de madeira para vias ferreas ou semelhantes" ~ "Dormentes de madeira para vias férreas",
                        lab == "Enzimas; enzimas preparadas nao especificadas nem compreendidas em outras posicoes" ~ "Enzimas e enzimas preparadas",
                        lab == "Estatuetas e outros objectos de ornamentacao, de ceramica" ~ "Estatuetas e objetos de ornamentação",
                        lab == "Facas (exceto da posicao 8208) de lamina cortante ou serrilhada, incluidas as podadeiras de lamina movel, e suas laminas" ~ "Facas de lâmina cortante ou serrilhada",
                        lab == "Farinhas, semolas e pos, de legumes de vagem secos da posicao 0713, de sagu ou das raizes ou tuberculos da posicao 0714 e dos produtos do Capitulo 8" ~ "Farinhas, semolas, pós de legumes",
                        lab == "Fatos de saia-casaco, conjuntos, casacos, vestidos, saias, saias-calcas, calcas, jardineiras, bermudas e calcoes (shorts) (exceto de banho), de malha, de uso feminino" ~ "Vestimentas de malha de uso feminino",
                        lab == "Fatos de saia-casaco, conjuntos, casacos, vestidos, saias, saias-calcas, calcas, jardineiras, bermudas e calcoes (shorts) (exceto de banho), de uso feminino" ~ "Vestimentas de uso feminino",
                        lab == "Fatos de treino para desporto, fatos-macacos e conjuntos de esqui, malhos, biquinis, calcoes (shorts) e slips, de banho, de malha" ~ "Vestimentas para esportes e banho",
                        lab == "Fatos, conjuntos, casacos, calcas, jardineiras, bermudas e calcoes (shorts) (exceto de banho), de malha, de uso masculino" ~ "Vestimentas de malha de uso masculino",
                        lab == "Fatos, conjuntos, casacos, calcas, jardineiras, bermudas e calcoes (shorts) (exceto de banho), de uso masculino" ~ "Vestimentas de uso masculino",
                        lab == "Ferramentas, armacoes e cabos de ferramentas, de escovas e de vassouras, de madeira; formas, alargadeiras e esticadores, de madeira, para calcados" ~ "Ferramentas para calçados",
                        lab == "Ferro fundido bruto e ferro spiegel (especular), em lingotes, linguados ou outras formas primarias" ~ "Ferro fundido e outras formas primarias",
                        lab == "Flores e seus botoes, cortados para ramos ou para ornamentacao, frescos, secos, branqueados, tingidos, impregnados ou preparados de outro modo" ~ "Flores e seus botões para ornamentos",
                        lab == "Flores, folhagem e frutos, artificiais, e suas partes; artefactos confeccionados com flores, folhagem e frutos, artificiais" ~ "Flores, folhagem e frutos artificiais",
                        lab == "Fluidos para freios hidraulicos e outros liquidos preparados para transmissoes hidraulicas, que nao contenham oleos de petroleo nem de minerais betuminosos, ou que os contenham em proporcao inferior a 70 %, em peso" ~ "Fluidos para sistemas hidráulicos",
                        lab == "Folhagem, folhas, ramos e outras partes de plantas, sem flores nem botoes de flores, e ervas, musgos e liquenes, para ramos ou para ornamentacao, frescos, secos, branqueados, tingidos, impregnados ou preparados de outro modo" ~ "Folhas, ramos e outras partes de planta",
                        lab == "Folhas para folheados (incluindo as obtidas por corte de madeira estratificada), folhas para contraplacados ou compensados ou para outras madeiras estratificadas semelhantes e madeira serrada longitudinalmente, cortada ou desenrolada, mesmo aplainada, pol" ~ "Folhas de madeira para folheados",  
                        lab == "Fornos eletricos industriais ou de laboratorio, incluidos os que funcionam por inducao ou por perdas dieletricas; outros aparelhos industriais ou de laboratorio, para tratamento termico de materias por inducao ou por perdas dieletricas" ~ "Fornos elétricos industriais",
                        lab == "Fosfatos de calcio naturais, fosfatos aluminocalcicos naturais e cre fosfatado" ~ "Fosfatos naturais",
                        lab == "Gas de petroleo e outros hidrocarbonetos gasosos" ~ "Hidrocarbonetos gasosos",
                        lab == "Gelatinas e seus derivados; ictiocola e outras colas de origem animal, exceto cola de caseina" ~ "Gelatina e colas de origem animal",
                        lab == "Gengibre, acafrao, curcuma, tomilho, louro, caril e outras especiarias" ~ "Gengibre, açafrão e outras especiarias",
                        lab == "Glicerol em bruto; aguas e lixivias, glicericas" ~ "Glicerol, lixivias, glicéricas",
                        lab == "Gorduras de animais das especies bovina, ovina ou caprina, exceto as da posicao 1503" ~ "Gorduras animais bovino, ovino e caprino",
                        lab == "Gorduras e oleos animais ou vegetais, e respectivas fraccoes, parcial ou totalmente hidrogenados, interesterificados, reesterificados ou elaidinizados, mesmo refinados, mas nao preparados de outro modo" ~ "Gorduras animais ou vegetais hidrogenadas",
                        lab == "Granito, porfiro, basalto, arenito e outras pedras de cantaria ou de construcao, mesmo desbastados ou simplesmente cortados a serra ou por outro meio, em blocos ou placas de forma quadrada ou rectangular" ~ "Granito e outras pedras para construção",
                        lab == "Graos de cereais trabalhados de outro modo (por exemplo: descascados, pelados, esmagados, em flocos, em perolas, cortados ou partidos), com exclusao do arroz da posicao 1006; germes de cereais, inteiros, esmagados, em flocos ou moidos" ~ "Grãos de cereais trabalhados, menos arroz",
                        lab == "Heterosidos, naturais ou sinteticos, seus sais, eteres, esteres e outros derivados" ~ "Heterósidos naturais ou sintéticos",
                        lab == "Hidrogenio, gases raros e outros elementos nao metalicos" ~ "Hidrogênio e mais elementos não metálicos",
                        lab == "Iates e outros barcos e embarcacoes de recreio ou de desporto; barcos a remos e canoas" ~ "Embarcações de recreio ou desporto",
                        lab == "Instrumentos e aparelhos de geodesia, topografia, agrimensura, nivelamento, fotogrametria, hidrografia, oceanografia, hidrologia, meteorologia ou de geofisica, exceto bussolas; telemetros" ~ "Aparelhos de topografia, nivelamento, etc",
                        lab == "Instrumentos e aparelhos para medicina, cirurgia, odontologia e veterinaria, incluidos os aparelhos de cintilografia e outros aparelhos electromedicos, bem como os aparelhos para testes visuais" ~ "Aparelhos para medicina e veterinária",
                        lab == "Instrumentos e aparelhos para medida ou controlo do caudal (vazao), do nivel, da pressao ou de outras caracteristicas variaveis dos liquidos ou gases (por exemplo: medidores de caudal, indicadores de nivel, manometros, contadores de calor), exceto os ins" ~ "Aparelhos de controle de líquidos e gases",
                        lab == "Instrumentos e aparelhos para regulacao ou controlo, automaticos" ~ "Instrumentos automáticos para regulação",
                        lab == "Instrumentos musicais cujo som e produzido ou amplificado por meios eletricos (por exemplo: orgaos, guitarras, acordeoes)" ~ "Instrumentos musicais elétricos",
                        lab == "Ladrilhos e placas (lajes), para pavimentacao ou revestimento, vidrados ou esmaltados, de ceramica; cubos, pastilhas e artigos semelhantes, para mosaicos, vidrados ou esmaltados, de ceramica, mesmo com suporte" ~ "Ladrilhos e placas para revestimento",
                        lab == "Legumes de vagem, secos, em grao, mesmo pelados ou partidos" ~ "Legumes de vagem em grão secos",
                        lab == "Lenha em qualquer estado, madeira em estilhas ou em particulas; serradura, desperdicios e residuos de madeira, mesmo aglomerados em bolas, briquetes, pellets ou em formas semelhantes" ~ "Lenha em qualquer estado",
                        lab == "Madeira (incluidos os tacos e frisos para soalhos, nao montados) perfilada (com espigas, ranhuras, filetes, entalhes, chanfrada, com juntas em V, com cercadura, boleada ou semelhantes) ao longo de uma ou mais bordas, faces ou extremidades, mesmo aplainada" ~ "Madeira perfilada, mesmo aplainada",
                        lab == "Madeira contraplacada ou compensada, madeira folheada, e madeiras estratificadas semelhantes" ~ "Madeira contraplacada ou compensada",
                        lab == "Madeira em bruto, mesmo descascada, desalburnada ou esquadriada" ~ "Madeira em bruto",
                        lab == "Madeira marchetada e madeira incrustada; estojos e guarda-joias, para joalharia e ourivesaria, e obras semelhantes, de madeira; estatuetas e outros objectos de ornamentacao, de madeira; artigos de mobiliario, de madeira, que nao se incluam no Capitulo 94" ~ "Madeira marchetada e artigos desta",
                        lab == "Malas e maletas, incluidas as de toucador e as maletas e pastas para documentos e de estudantes, os estojos para oculos, binoculos, maquinas fotograficas e de filmar, instrumentos musicais, armas, e artefactos semelhantes; sacos de viagem, sacos isolantes" ~ "Malas, maletas e estojos",
                        lab == "Maquinas-ferramentas (incluidas as prensas) para forjar ou estampar, martelos, martelos-piloes e martinetes, para trabalhar metais; maquinas- -ferramentas (incluidas as prensas) para enrolar, arquear, dobrar, endireitar, aplanar, cisalhar, puncionar ou ch" ~ "Máquinas e ferramentas de trabalhar metais",
                        lab == "Maquinas e aparelhos para colheita ou debulha de produtos agricolas, incluidas as enfardadeiras de palha ou forragem; cortadores de relva e ceifeiras; maquinas para limpar e seleccionar ovos, frutas ou outros produtos agricolas, exceto as da posicao 8437" ~ "Máquinas para colheita e debulha",
                        lab == "Maquinas e aparelhos, para preparar, curtir ou trabalhar couros ou peles, ou para fabricar ou consertar calcado e outras obras de couro ou de pele, exceto maquinas de costura" ~ "Máquinas para trabalhar couro",
                        lab == "Maquinas e aparelhos, para seleccionar, peneirar, separar, lavar, esmagar, moer, misturar ou amassar terras, pedras, minerios ou outras substancias minerais solidas (incluidos os pos e pastas); maquinas para aglomerar ou moldar combustiveis minerais solid" ~ "Aparelhos para selecionar pedras",
                        lab == "Marmores, travertinos, granitos belgas e outras pedras calcarias de cantaria ou de construcao, de densidade aparente igual ou superior a 2,5, e alabastro, mesmo desbastados ou simplesmente cortados a serra ou por outro meio, em blocos ou placas de forma q"  ~ "Mármores e outras pedras de construção",
                        lab == "Materias vegetais das especies principalmente utilizadas em cestaria ou espartaria (por exemplo: bambus, rotins, canas, juncos, vimes, rafia, palha de cereais limpa, branqueada ou tingida, casca de tilia)" ~ "Materiais vegetais utilizados em cestaria",
                        lab == "Melacos resultantes da extraccao ou refinacao do acucar" ~ "Melaços da extração e refino do açúcar",
                        lab == "Meloes, melancias e papaias (mamoes), frescos" ~ "Melões, melancias e papaias frescos",
                        lab == "Microfones e seus suportes; altifalantes, mesmo montados nos seus receptaculos; capacetes com auscultadores e auscultadores, mesmo combinados com um microfone, e conjuntos ou sortidos constituidos por um microfone e um ou varios altifalantes; amplificador" ~ "Microfones, altofalantes, amplificadores, etc",
                        lab == "Minerios de ferro e seus concentrados, incluidas as pirites de ferro ustuladas (cinzas de pirites)" ~ "Minérios de ferro e seus concentrados",
                        lab == "Minerios de manganes e seus concentrados, incluidos os minerios de manganes ferruginosos e seus concentrados, de teor de manganes de => 20%, em peso, sobre o produto seco" ~ "Minérios de manganês e seus concentrados",
                        lab == "Minerios de metais preciosos e seus concentrados"  ~ "Minérios de metais preciosos",
                        lab == "Minerios de niobio, tantalo, vanadio ou de zirconio, e seus concentrados" ~ "Minérios de nióbio, tântalo, vanádio, zircônio",
                        lab == "Miudezas comestiveis de animais das especies bovina, suina, ovina, caprina, cavalar, asinina e muar, frescas, refrigeradas ou congeladas" ~ "Miudezas comestíveis bovina, suína, etc",
                        lab == "Monofilamentos cuja maior dimensao do corte transversal seja superior a 1 mm (monofios), varas, bastoes e perfis, mesmo trabalhados a superficie mas sem qualquer outro trabalho, de plasticos" ~ "Monofilamentos, varas, bastões, de plásticos",
                        lab == "Motocicletas (incluidos os ciclomotores) e outros ciclos equipados com motor auxiliar, mesmo com carro lateral; carros laterais" ~ "Motocicletas e outros com motor auxiliar",
                        lab == "Navalhas e aparelhos de barbear e suas laminas (incluidos os esbocos em tiras)" ~ "Navalhas e aparelhos de barbear",
                        lab == "Obras de carpintaria para construcoes, incluidos os paineis celulares, os paineis para soalhos e as fasquias para telhados (shingles e shakes), de madeira" ~ "Obras de carpintaria para construção",
                        lab == "Obras de cestaria obtidas directamente na sua forma a partir de materias para entrancar ou fabricadas com os artigos da posicao 4601; obras de lufa" ~ "Obras de cestaria e lufa",
                        lab == "Obras de fibrocimento, cimento-celulose e produtos semelhantes" ~ "Obras de fibrocimento e cimento-celulose",
                        lab == "Obras de perolas naturais ou cultivadas, de pedras preciosas ou semipreciosas, pedras sinteticas ou reconstituidas" ~ "Obras de pérolas e pedras preciosas",
                        lab == "Oleo de soja e respectivas fraccoes, mesmo refinados, mas nao quimicamente modificados"  ~ "Óleo de soja, não modificado",
                        lab == "Oleos de coco (oleo de copra), de palmiste ou de babacu e respectivas fraccoes, mesmo refinados, mas nao quimicamente modificados" ~ "Óleos de coco, palmiste ou babaçu",
                        lab == "Oleos essenciais (desterpenizados ou nao), incluidos os chamados << concretos >> ou << absolutos >>; resinoides; oleorresinas de extraccao; solucoes concentradas de oleos essenciais em gorduras, em oleos fixos, em ceras ou em materias analogas, obtidas por tr" ~ "Óleos essenciais e concentrados",
                        lab == "Osciloscopios, analisadores de espectro e outros instrumentos e aparelhos para medida ou controlo de grandezas eletricas; instrumentos e aparelhos para medida ou deteccao de radiacoes alfa, beta, gama, X, cosmicas ou outras radiacoes ionizantes" ~ "Instrumentos de medida de energia e radiação",
                        lab == "Ouro (incluido o ouro platinado), em formas brutas ou semimanufacturadas, ou em po" ~ "Ouro em forma bruta, semimanufaturada ou em pó",
                        lab == "Outras chapas, folhas, peliculas, tiras e laminas, de plastico" ~ "Outras chapas e tiras de plástico",
                        lab == "Outras frutas de casca rija, frescas ou secas, mesmo sem casca ou peladas" ~ "Outras frutas de casca rija",
                        lab == "Outras obras de plastico e obras de outras materias das posicoes 3901 a 3914" ~ "Outras obras de plástico e outros materiais",
                        lab == "Outras preparacoes e conservas de carne, miudezas ou sangue" ~ "Outras preparações de carne e miudezas",
                        lab == "Outro calcado com sola exterior e parte superior de borracha ou plastico" ~ "Outros calçados com plástico ou borracha",
                        lab == "Outros couros e peles em bruto (frescos, ou salgados, secos, tratados pela cal, << piclados >> ou conservados de outro modo, mas nao curtidos, nem apergaminhados nem preparados de outro modo), mesmo depilados ou divididos, com excepcao das excluidos pela No" ~ "Outros couros e peles em bruto",
                        lab == "Outros instrumentos musicais de cordas (por exemplo: guitarras, violinos, harpas)"  ~ "Outros instrumentos musicais de cordas",
                        lab == "Partes e acessorios dos veiculos automoveis das posicoes 8701 a 8705" ~ "Partes para veículos de sh4 8701 a 8705",
                        lab == "Partes e acessorios dos veiculos das posicoes 8711 a 8713" ~ "Partes para veículos de sh4 8711 a 8713",
                        lab == "Partes e acessorios reconheciveis como exclusiva ou principalmente destinados as maquinas das posicoes 8456 a 8465, incluidos os porta-pecas e porta-ferramentas, as fieiras de abertura automatica, os dispositivos divisores e outros dispositivos especiais," ~ "Partes para máquinas de sh4 8456 a 8465",
                        lab == "Partes reconheciveis como exclusiva ou principalmente destinadas aos motores das posicoes 8407 ou 8408" ~ "Partes para motores de sh4 8407 e 8408",
                        lab == "Partes reconheciveis como exclusiva ou principalmente destinadas as maquinas e aparelhos das posicoes 8425 a 8430" ~ "Partes para máquinas de sh4 8425 a 8430",
                        lab == "Pastas (ouates), gazes, ataduras e artigos analogos (por exemplo: pensos, esparadrapos, sinapismos), impregnados ou recobertos de substancias farmaceuticas ou acondicionados para venda a retalho para usos medicinais, cirurgicos, dentarios ou veterinarios" ~ "Pastas, gazes e análogos para usos medicinais",
                        lab == "Pastas quimicas de madeira, a soda ou ao sulfato, exceto pastas para dissolucao" ~ "Pastas químicas de madeira",
                        lab == "Pedra-pomes; esmeril; corindo natural, granada natural e outros abrasivos naturais, mesmo tratados termicamente" ~ "Pedra-pomes, esmeril e outros abrasivos",
                        lab == "Pedras preciosas (exceto diamantes) ou semipreciosas, mesmo trabalhadas ou combinadas, mas nao enfiadas, nem montadas, nem engastadas; pedras preciosas (exceto diamantes) ou semipreciosas, nao combinadas, enfiadas temporariamente para facilidade de tran" ~ "Pedras preciosas ou semi, exceto diamante",
                        lab == "Plantas, partes de plantas, sementes e frutos, das especies utilizadas principalmente em perfumaria, medicina ou como insecticidas, parasiticidas e semelhantes, frescos ou secos, mesmo cortados, triturados ou em po" ~ "Plantas para medicina, perfumaria ou inseticida",
                        lab == "Polimeros de cloreto de vinilo ou de outras olefinas halogenadas, em formas primarias" ~ "Polímeros de olefinas halogenadas",   
                        lab == "Preparacoes alimenticias nao especificadas nem compreendidas noutras posicoes" ~ "Preparações alimentícias não especificadas",
                        lab == "Preparacoes dos tipos utilizados na alimentacao de animais" ~ "Preparações para alimentação animal",
                        lab == "Preparacoes e artigos farmaceuticos indicados na Nota 4 do presente capitulo" ~ "Preparações e artigos farmacêuticos",
                        lab == "Preparacoes para barbear (antes, durante ou apos), desodorizantes corporais, preparacoes para banhos, depilatorios, outros produtos de perfumaria ou de toucador preparados e outras preparacoes cosmeticas, nao especificados nem compreendidos em outras posi" ~ "Preparações cosméticas e banho",
                        lab == "Produtos de origem animal, nao especificados nem compreendidos em outras posicoes; animais mortos dos Capitulos 1 ou 3, improprios para alimentacao humana" ~ "Produtos animais impróprios para alimentação",
                        lab == "Quadros, pinturas e desenhos, feitos inteiramente a mao, exceto os desenhos da posicao 4906 e os artigos manufacturados decorados a mao; colagens e quadros decorativos semelhantes" ~ "Quadros e desenhos feitos a mão",
                        lab == "Recipientes para gases comprimidos ou liquefeitos, de ferro fundido, ferro ou aco" ~ "Recipientes de ferro e aço para gases",
                        lab == "Residuos da fabricacao do amido e residuos semelhantes, polpas de beterraba, bagaco de cana-de-acucar e outros desperdicios da industria do acucar, borras e desperdicios da industria da cerveja e das destilarias, mesmo em pellets" ~ "Resíduos da fabricação de amido, polpas, etc",
                        lab == "Saboes; produtos e preparacoes organicos tensoactivos utilizados como sabao, em barras, paes, pedacos ou figuras moldadas, mesmo contendo sabao; produtos e preparacoes organicos tensoactivos para lavagem da pele, sob a forma de liquido ou de creme, acondi" ~ "Sabões e preparações para lavar pele",
                        lab == "Tamaras, figos, ananases (abacaxis), abacates, goiabas, mangas e mangostoes, frescos ou secos" ~ "Mangas, abacaxis, abacates, figos, etc",
                        lab == "Tantalo e suas obras, incluidos os desperdicios, residuos e sucata" ~ "Tântalo, seus resíduos e sucatas",
                        lab == "Telhas, elementos de chamines, condutores de fumo, ornamentos arquitectonicos, de ceramica, e outros produtos ceramicos para construcao" ~ "Telhas e mais produtos cerâmicos de construção",
                        lab == "Tortas e outros residuos solidos da extracao do oleo de soja" ~ "Resíduos da extração do óleo de soja",
                        lab == "Tripas, bexigas e estomagos de animais, exceto peixes, inteiros ou em pedacos, frescos, refrigerados, congelados, salgados, secos ou defumados" ~ "Tripas de animais, exceto peixes",
                        lab == "Tubos e perfis ocos, sem costura, de ferro ou aco" ~ "Tubos e perfis de ferro ou aço",
                        lab == "Tubos e seus acessorios (por exemplo: juntas, cotovelos, flanges, unioes), de plastico" ~ "Tubos e seus acessórios de plástico",
                        lab == "Turborreactores, turbopropulsores e outras turbinas a gas" ~ "Turborreatores e outras turbinas a gás",
                        lab == "Veiculos automoveis para transporte de mercadorias" ~ "Automóveis para transporte de mercadorias",
                        TRUE ~ lab)) 
  
data= data%>%
  mutate(nome_sh2= case_when(nome_sh2 == "Brinquedos, jogos, artigos para divertimento ou para esporte; suas partes e acessórios" ~ "Brinquedos, jogos e artigos para esporte"  ,
                              nome_sh2 == "Calçados, polainas e artefatos semelhantes; suas partes" ~ "Calçados, polainas e semelhantes" ,
                              nome_sh2 == "Combustíveis minerais, óleos minerais e produtos da sua destilação; matérias betuminosas; ceras minerais" ~ "Combustíveis, óleos e ceras minerais" ,
                              nome_sh2 == "Ferramentas, artefatos de cutelaria e talheres, e suas partes, de metais comuns" ~ "Ferramentas, cutelaria e talheres" ,
                              nome_sh2 == "Frutas; cascas de frutos cítricos e de melões" ~ "Frutas, cascas de cítricos e de melões" ,
                              nome_sh2 == "Gomas, resinas e outros sucos e extratos vegetais" ~ "Gomas resinas e outros extratos vegetais",
                              nome_sh2 == "Gorduras e óleos animais ou vegetais; produtos da sua dissociação; gorduras alimentares elaboradas; ceras de origem animal ou vegetal" ~ "Gorduras e óleos animais ou vegetais" ,
                              nome_sh2 == "Instrumentos e aparelhos de óptica, de fotografia, de cinematografia, de medida, de controle ou de precisão; instrumentos e aparelhos médico-cirúrgicos; suas partes e acessórios" ~ "Aparelhos médicos, fotografia e de medida",
                              nome_sh2 == "Instrumentos musicais; suas partes e acessórios" ~ "Instrumentos musicais e suas partes",
                              nome_sh2 == "Leite e lacticínios; ovos de aves; mel natural; produtos comestíveis de origem animal, não especificados nem compreendidos noutros Capítulos" ~ "Leite, ovos, mel e outros de origem animal",
                              nome_sh2 == "Máquinas, aparelhos e materiais elétricos, e suas partes; aparelhos de gravação ou de reprodução de som, aparelhos de gravação ou de reprodução de imagens e de som em televisão, e suas partes e acessórios" ~ "Aparelhos de som e imagem",
                              nome_sh2 == "Matérias albuminóides; produtos à base de amidos ou de féculas modificados; colas; enzimas"   ~ "Produtos de amido, enzimas, albuminóides" ,
                              nome_sh2 == "Matérias para entrançar e outros produtos de origem vegetal, não especificados nem compreendidos noutros Capítulos" ~ "Outros produtos de origem vegetal" ,
                              nome_sh2 == "Móveis; mobiliário médico-cirúrgico, colchões, almofadas e semelhantes; aparelhos de iluminação não especificados nem compreendidos em outros capítulos; anúncios, cartazes ou tabuletas e placas indicadoras luminosos, e artigos semelhantes; Construções Pré" ~ "Mobiliário, iluminação, entre outros",
                              nome_sh2 == "Objetos de arte, de coleção e antiguidades" ~ "Objetos de arte, coleção e antiguidades",
                              nome_sh2 == "Obras de couro; artigos de correeiro ou de seleiro; artigos de viagem, bolsas e artefatos semelhantes; obras de tripa" ~ "Obras de couro, tripa, bolsas e outros" ,
                              nome_sh2 == "Obras de pedra, gesso, cimento, amianto, mica ou de matérias semelhantes" ~ "Obras de pedra, cimento, gesso e outros" ,
                              nome_sh2 == "Óleos essenciais e resinóides; produtos de perfumaria ou de toucador preparados e preparações cosméticas" ~ "Óleos essenciais, perfumaria e cosméticos",
                              nome_sh2 == "Outros artefatos têxteis confeccionados; sortidos; artefatos de matérias têxteis, calçados, chapéus e artefatos de uso semelhante, usados; trapos" ~ "Artefatos têxteis, chapéus e calçados" ,
                              nome_sh2 == "Outros metais comuns; ceramais (cermets); obras dessas matérias" ~ "Outros metais comuns e suas obras" ,
                              nome_sh2 == "Outros produtos de origem animal, não especificados nem compreendidos noutros Capítulos" ~ "Outros produtos de origem animal" ,
                              nome_sh2 == "Pastas de madeira ou de outras matérias fibrosas celulósicas; papel ou cartão para reciclar (desperdícios e aparas)." ~ "Pastas de madeira e papel para reciclar",
                              nome_sh2 == "Peixes e crustáceos, moluscos e outros invertebrados aquáticos" ~ "Peixes e invertebrados aquáticos",
                              nome_sh2 == "Peles, exceto as peles com pelo, e couros" ~ "Peles, exceto as com pelo, e couros"  ,
                              nome_sh2 == "Penas e penugem preparadas e suas obras; flores artificiais; obras de cabelo" ~ "Penas e suas obras e flores artificais",
                              nome_sh2 == "Pérolas naturais ou cultivadas, pedras preciosas ou semipreciosas e semelhantes, metais preciosos, metais folheados ou chapeados de metais preciosos (plaquê), e suas obras; bijuterias; moedas" ~ "Pedras e metais preciosos, bijuterias" ,
                              nome_sh2 == "Preparações de carne, de peixes ou de crustáceos, de moluscos ou de outros invertebrados aquáticos" ~ "Preparações de carne, peixes e outros",
                              nome_sh2 == "Preparações de produtos hortícolas, de frutas ou de outras partes de plantas" ~ "Preparações de vegetais, frutas e outros" ,
                              nome_sh2 == "Produtos da indústria de moagem; malte; amidos e féculas; inulina; glúten de trigo" ~ "Produtos de moagem, amidos e féculas",
                              nome_sh2 == "Produtos hortícolas, plantas, raízes e tubérculos, comestíveis." ~ "Produtos hortícolas e plantas, comestíveis",
                              nome_sh2 == "Produtos químicos inorgânicos; compostos inorgânicos ou orgânicos de metais preciosos, de elementos radioativos, de metais das terras raras ou de isótopos" ~ "Produtos químicos inorgânicos",
                              nome_sh2 == "Reatores nucleares, caldeiras, máquinas, aparelhos e instrumentos mecânicos, e suas partes" ~ "Reatores, caldeiras e aparelhos mecânicos",
                              nome_sh2 == "Resíduos e desperdícios das indústrias alimentares; alimentos preparados para animais" ~ "Desperdícios das indústrias alimentares",
                              nome_sh2 == "Sabões, agentes orgânicos de superfície, preparações para lavagem, preparações lubrificantes, ceras artificiais, ceras preparadas, produtos de conservação e limpeza, velas e artigos semelhantes, massas ou pastas para modelar, \"ceras\" para dentistas e Comp" ~ "Sabões, ceras e produtos de limpeza",
                              nome_sh2 == "Sal; enxofre; terras e pedras; gesso, cal e cimento" ~ "Sal, enxofre, cimento, terras e pedras",
                              nome_sh2 == "Sementes e frutos oleaginosos; grãos, sementes e frutos diversos; plantas industriais ou medicinais; palhas e forragens" ~ "Sementes, grãos e frutos diversos",
                              nome_sh2 == "Veículos automóveis, tratores, ciclos e outros veículos terrestres, suas partes e acessórios" ~ "Veículos terrestres",
                              nome_sh2 == "Vestuário e seus acessórios, de malha" ~ "Vestuário, de malha",
                              nome_sh2 == "Vestuário e seus acessórios, exceto de Malha" ~ "Vestuário, exceto de malha",
                              TRUE ~ nome_sh2))
}
data$produto_principal = data$lab

colnames(data) <- cols

saveRDS(data, "data/comex_exp_munic_sh4_sel.rds")


# dictionary --------------------------------------------------------------
# extract variables from data
df_final <- readRDS(file = "data/comex_exp_munic_sh4_sel.rds")
columns <- colnames(df_final)

# generate dictionary
temp_param_table <- tibble(
  var = columns,
  x = TRUE,
  y = TRUE,
  color = FALSE,
  size = FALSE,
  slider = FALSE,
  geometry = FALSE,
  label = columns,
  desc = columns,
  var_group = "Comex",
  tipo = 1,
  unidade = "-",
  categoria= "Economia", 
  subcategoria = "Com\u00e9rcio exterior"
)

temp_param_table$label <- temp_param_table$var

temp_param_table$label[temp_param_table$var == 'cod_ibge'] <- "C\u00f3digo IBGE"
temp_param_table$label[temp_param_table$var == 'time'] <- "Ano"
temp_param_table$label[temp_param_table$var == 'uf'] <- "Estado"
temp_param_table$label[temp_param_table$var == 'nm_municip'] <- "Munic\u00edpio"
temp_param_table$label[temp_param_table$var == 'maximo_produto'] <- "Valor relativo do principal produto exportado"
temp_param_table$label[temp_param_table$var == 'produto_principal'] <- "Principal produto exportado (sh2)"
temp_param_table$label[temp_param_table$var == 'floresta'] <- "Produtos Compat\u00edveis com a Floresta"
temp_param_table$label[temp_param_table$var == 'cod_sh4'] <- "C\u00f3digo no sistema unificado 4"
temp_param_table$label[temp_param_table$var == 'cod_sh2'] <- "C\u00f3digo no sistema unificado 2"
temp_param_table$label[temp_param_table$var == 'nome_sh2'] <- "Nome no sistema unificado 2"

temp_param_table$unidade[temp_param_table$var == 'maximo_produto'] <- "% das exporta\u00e7\u00f5es mundiais"

temp_param_table$x <- c(FALSE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
temp_param_table$y <- c(FALSE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
temp_param_table$color <- c(FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
temp_param_table$size <- c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
temp_param_table$slider <- c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_munic_sh4_sel_dic.csv", fileEncoding = "UTF-8")

# relabel in english ----------------------------------------------------------------
temp_param_table$label[1] <- "Year"
temp_param_table$label[2] <- "Municipality"
temp_param_table$label[3] <- "Main exported product relative value"
temp_param_table$label[4] <- "Main exported product"
temp_param_table$label[6] <- "Forest Compatible Products"

temp_param_table$unidade <- "% of world exports"
temp_param_table$categoria <- "Economy"
temp_param_table$subcategoria <- "Foreign Trade"

# save csv in utf-8 encoding
write.csv(temp_param_table, file = "data/comex_exp_munic_sh4_sel_dic_en.csv", fileEncoding = "UTF-8")


