# Cache
cache_folder <- "rk_comex_exp_munic_produtosamz/cache/"
shinyOptions(cache = cachem::cache_disk(cache_folder))

# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "rk_comex_exp_munic_produtosamz/ui.R"
files$server_script <- "rk_comex_exp_munic_produtosamz/server.R"
files$param_script <- "rk_comex_exp_munic_produtosamz/db_params.R"
files$CSS_script <- "global/dza_lumen.css"
files$param_file <- "rk_comex_exp_munic_produtosamz/comex_exp_sh4_munic_dic.csv"
files$db_file <- "rk_comex_exp_munic_produtosamz/comex_exp_sh4_munic.rds"
files$aux_file <- "rk_comex_exp_munic_produtosamz/auxiliar_cod_sh4.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)

# Parâmetros da visualização (define as variáveis/colunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "value" # variável padrão do eixo x
param$y_def <- "" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)
param$group <- "group" # variável de agrupamento
param$id_def <- "group" # variável padrão de id
param$lang <- FALSE

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amazônia"
param$plot_desc <- "municípios que mais exportam produtos da Amazônia Legal"

# Outros parâmetros e configurações
param$x_choices[[1]] <- NULL
param$starter_choices <- list(
    "Agro e alimentos" = c(
        "Soja, mesmo triturada" = "1201",
        "Milho" = "1005",
        "Legumes de vagem, secos, em grão" = "0713",
        "Produtos hortícolas congelados" = "0710",
        "Tomates, frescos ou refrigerados" = "0702",
        "Pepinos e pepininhos, frescos ou refrigerados" = "0707",
        "Grãos de cereais trabalhados (flocos/partidos etc.)" = "1104",
        "Produtos à base de cereais (expandidos/torrados)" = "1904",
        "Produtos hortícolas preparados/conservados (exceto vinagre)" = "2005",
        "Frutas e partes comestíveis, preparadas ou conservadas" = "2008",
        "Águas (minerais/gaseificadas) sem açúcar" = "2201",
        "Extratos e preparações de café/chá/mate" = "2101",
        "Cocos/castanha do Brasil/castanha de caju (frescos ou secos)" = "0801"
    ),
    
    "Carnes e produtos de origem animal" = c(
        "Carnes bovinas, congeladas" = "0202",
        "Carnes bovinas, frescas ou refrigeradas" = "0201",
        "Miudezas comestíveis (bov./suín./ovín. etc.)" = "0206",
        "Tripas, bexigas e estômagos de animais (exceto peixes)" = "0504",
        "Gorduras de bovinos/ovinos/caprinos (exceto 1503)" = "1502",
        "Farinhas/pó/pellets de carnes/miudezas/peixes (impróprios p/ alimentação humana)" = "2301"
    ),
    
    "Óleos e derivados" = c(
        "Óleo de soja e frações (mesmo refinado)" = "1507"
    ),
    
    "Florestais e madeira" = c(
        "Madeira serrada/endireitada longitudinalmente (> 6mm)" = "4407",
        "Madeira perfilada (tacos/frisos para soalhos etc.)" = "4409"
    ),
    
    "Metais e minerais" = c(
        "Ouro (bruto/semimanufaturado ou em pó)" = "7108",
        "Algodão, não cardado nem penteado" = "5201"
    ),
    
    "Indústria e manufaturados" = c(
        "Parafusos, porcas, anilhas, rebites e afins" = "7318",
        "Rolamentos (esferas/roletes/agulhas)" = "8482",
        "Papel/pasta para higiene e toucador" = "4818",
        "Vestuário feminino (conjuntos/vestidos/saias/calças etc.)" = "6204",
        "Malas, maletas, estojos e bolsas" = "4202",
        "Preparações e artigos farmacêuticos" = "3006"
    )
)

#Mudanças específicas no server
param$label_no_variable<- paste0("Variável não selecionada")
param$x_label<- "Valor (US$ FOB)"
param$plot_title<- "Ranking de exportação por município"
param$pct_anual <- "Participação no ano: "
# param$label_amazon<- paste0("Amazônia Legal")

#Mudanças específicas no UI

param$label_variable<- "VARI\u00C1VEIS:"
param$label_x_choice_rk<- "Categoria de produtos:"
param$link<-"https://datazoom.shinyapps.io/app_rk_comex_exp_munic_produtosamz/"


#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
