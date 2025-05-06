#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {
    div(
        includeCSS(files$CSS_script),
        class = "container-fluid h-100 d-flex flex-column apppanel",
        fluidRow(
            class = "mainrow h-100",
            column(3,
                   class = "menucol",
                   tags$style('
          .menucol { background-color: #41878C; }
          .btn-primary, .btn-primary:hover, 
          .btn-primary:active, .btn-primary:visited {
            background-color: #40768B !important;
            border-color: #40768B !important;
          }'
                   ),
                   
                   h2(class = "plot_name", param$plot_name),
                   p(class = "plot_desc", param$plot_desc),
                   hr(),
                   
                   # Controles de visualização
                   selectInput("y", param$label_y_name,
                               choices = list(
                                   "Salário Médio" = "real_avg_w",
                                   "Número de Vínculos" = "num_vinculos",
                                   "Tempo no Emprego" = "tenure"
                               ),
                               selected = param$y_def
                   ),
                   
                   selectInput("x", "Eixo horizontal (x):",
                               choices = list(
                                   "Ano" = "year",
                                   "UF" = "uf",
                                   "Setor Econômico" = "setor",
                                   "Ocupação" = "ocupacao",
                                   "Sexo" = "sexo"
                               ),
                               selected = param$x_def
                   ),
                   
                   selectInput("color", "Cor por:",
                               choices = list(
                                   "Nenhum" = "none",
                                   "UF" = "uf",
                                   "Setor" = "setor",
                                   "Sexo" = "sexo",
                                   "Faixa Etária" = "faixa_etaria"
                               ),
                               selected = param$color_def
                   ),
                   
                   checkboxGroupInput("options", "Opções:",
                                      choices = list(
                                          "Escala logarítmica" = "logscale",
                                          "Mostrar valores" = "showvalues"
                                      )
                   ),
                   
                   # Filtros
                   selectizeInput("filter_uf", param$label_geo,
                                  choices = NULL, multiple = TRUE,
                                  options = list(placeholder = 'Selecione UFs...')
                   ),
                   
                   selectizeInput("filter_setor", param$label_sect,
                                  choices = NULL, multiple = TRUE,
                                  options = list(placeholder = 'Selecione setores...')
                   ),
                   
                   actionButton('ab1', "Visualização Completa", 
                                icon = icon("expand"), class = "btn-primary",
                                onclick = paste0("window.open('", param$link, "', '_blank')")
                   )
            ),  # Fechamento da primeira column(3)
            
            column(9,
                   class = "plotcol h-100",
                   h3(textOutput("plot_title"), align = "center"),
                   h4(textOutput("plot_subtitle"), align = "center"),
                   div(
                       class = "plotrow row justify-content-center flex-grow-1 w-100",
                       div(
                           class = "plotdiv w-100 h-100",
                           # Gráfico com spinner
                           withSpinner(
                               plotlyOutput("plot", width = "100%", height = "100%"),
                               type = 4, color = "#41878C"
                           )
                       )
                   )
            )  # Fechamento da column(9)
        )  # Fechamento do fluidRow
    )  # Fechamento do div principal
}
