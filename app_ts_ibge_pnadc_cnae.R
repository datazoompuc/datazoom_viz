# Carrega bibliotecas
library(shiny)
library(ggplot2)
library(plotly)
library(htmlwidgets)

# Define nome de arquivos a serem carregados
files <- list()
files$ui_script <- "scripts/ts_ibge_pnadc_cnae/ui.R"
files$server_script <- "scripts/ts_ibge_pnadc_cnae/server.R"
files$param_script <- "scripts/ts_ibge_pnadc_cnae/db_params.R"
files$CSS_script <- "scripts/dza_lumen.css"
files$param_file <- "data/ibge_pnadc_cnae_dic.csv"
files$db_file <- "data/ibge_pnadc_cnae.rds"

# Carrega scripts
source(files$param_script)
source(files$ui_script)
source(files$server_script)



# Parâmetros da visualização (define as variáveis/culunas padrões para os eixos do gráfico)
param <- get_db_param(files$param_file, files$db_file) # carrega lista de variáveis e parâmetros
param$x_def <- "time" # variável padrão do eixo x
param$y_def <- "rendimento_medio" # variável padrão do eixo y
param$slider_def <- "time"
param$color_def <- "group" # variável padrão de cor
param$text_def <- "group" # variável padrão de texto sobre o gráfico (quando passa o mouse em cima)

# Descrição da visualização no eixo de opções
param$plot_name <- "Data Zoom Amaz\u00f4nia"
param$plot_desc <- "Dados sobre atividades econ\u00f4micas gerados a partir da PNAD Cont\u00ednua Trimestral - IBGE"

### Parametros especificos no UI
param$label_var_name <- "VARIÁVEIS:"
param$label_y_name <- "eixo vertical (y)"
param$label_scale_name <- "escala log"
param$label_prop_name <- "proporcional ao trimestre inicial (*)"
param$label_region_name <- "Recorte regional"
param$label_type_name <- "Atividade econômica"
param$label_sector_name <- "Setor"
param$link <- "https://datazoom.shinyapps.io/app_ts_ibge_pnadc_cnae/"

### Parametros especificos no server
param$title_init <- "Evolução trimestral de" # expressão titulo
param$subtitle_init <- "por atividade econômica" # expressão subtitulo


# Outros parâmetros e configurações
param$y_choices[[1]] <- NULL

param$filter_choices <- list(
    "Brasil" = list("Brasil", ""),
    "Amaz\u00f4nia Legal" = list("Amaz\u00f4nia Legal", "Fora da Amaz\u00f4nia Legal"),
    "Regi\u00e3o" = list("Norte", "Nordeste", "Sudeste", "Sul", "Centro-Oeste"),
    "UF" = list(
        "RO", "AC", "AM", "RO", "PA", "AP", "TO",
        "MA", "PI", "CE", "RN", "PB", "PE", "AL",
        "SE", "BA", "MG", "ES", "RJ", "SP", "PR",
        "SC", "RS", "MS", "MT", "GO", "DF"
    )
)

param$ocupation_choices <- list(
    "Todos",
    "Administração pública, defesa e seguridade social",     
    "Alimentos, bebidas e fumo",                          
    "Artes, cultura, esportes e recreação",                  
    "Atividades profissionais, científicas e técnicas",      
    "Automóveis e equipamentos de transporte",               
    "Comércio",                                              
    "Construção",                                            
    "Educação",                                              
    "Eletrônicos, máquinas e equipamentos",                  
    "Estadia e turismo",                                     
    "Madeira, celulose e papel",                             
    "Móveis",                                                
    "Organizações religiosas, sindicais e patronais",        
    "Outros",                                                
    "Pecuária e criação de animais",                         
    "Pesca, caça e aquicultura",                             
    "Produtos de metal, minerais não-metálicos e metalurgia",
    "Químicos, farmacêuticos, borracha e plástico",          
    "Saúde e assistência social",                            
    "Segurança e edifícios",                                 
    "Serviços de alimentação",                              
    "Serviços de informação e comunicação",                  
    "Serviços domésticos",                                   
    "Serviços financeiros e de seguros",                     
    "Serviços jurídicos",                                   
    "Serviços pessoais (cabelereiros, lavanderias, etc.)",  
    "Terceirização de mão-de-obra",                         
    "Transporte e correio",                                  
    "Têxtil, vestuário, couro e calçados"
)

param$ocupation_def <- list("Todos") 

param$sector_choices <- list(
    "Todos" = "todos",
    "Formal" = "formal",
    "Informal" = "informal",
    "Público" = "publico",
    "Privado" = "privado"
)

param$sector_def <- "formal"

#  --------------------------------  Roda a aplicação Shiny --------------------------------
ui <- get_ui(files, param)
server <- get_server(files, param)

shinyApp(ui = ui, server = server)
