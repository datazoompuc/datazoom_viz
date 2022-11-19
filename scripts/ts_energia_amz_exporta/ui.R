#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {
  div( # div geral
    includeCSS(files$CSS_script), # Inclu? script CSS
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3, # dimensão da coluna do bootstrap
             class = "menucol",
             
             # muda cor do background
             tags$style('.menucol {
                             background-color: #41878C;
              }',),
             
             # muda cor do botao 
             tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                          background-color: #40768B !important;
                          border-color: #40768B !important;
              }',),
             
             h2(class = "plot_name", param$plot_name),
             p(class = "plot_desc", param$plot_desc),
             hr(),
             p(class = "vars", "VARI\u00C1VEIS:"),
             div(
               class = "var_selec_group",
               # Seleciona variável do eixo y
               selectInput(
                 inputId = "y",
                 label = "eixo vertical (y)",
                 choices = param$y_choices,
                 selected = sample(param$y_choices, size = 2, replace = FALSE), #ponto de atencao para possiveis problemas
                 multiple = TRUE,
                 width = "100%"
               )
             ),
             
             # Seleciona eixo log
             checkboxInput(
               inputId = "ylog",
               "escala log",
               value = FALSE,
               width = "100%"
             ),
             # Seleciona eixo
             checkboxInput(
               inputId = "y_option",
               "proporcional ao ano inicial (*)",
               value = FALSE,
               width = "100%"
             ),
             
             
             # espaço vazio
             div(class = "fakecheckbox", ),
             
             div(
               shiny::actionButton(inputId = 'ab1', label = "Fullscreen", 
                                   icon = icon("expand"), 
                                   class = "btn-primary",
                                   onclick = "window.open('https://datazoom.shinyapps.io/app_ts_energia_amz_exporta/', '_blank')")
             ),
      ),
      column(9,
             class = "plotcol h-100",
             textOutput("plot_title"),
             textOutput("plot_subtitle"),
             div( # row do gráfico
               class = "plotrow row justify-content-center flex-grow-1 w-100",
               div(
                 class = "plotdiv w-100 h-100",
                 # Gráfico
                 plotlyOutput("plot", width = "100%", height = "100%")
               )
             )
      )
    ),
  )
}
