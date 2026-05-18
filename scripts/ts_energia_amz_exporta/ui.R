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
             p(class = "plot_desc", textOutput("plot_desc", inline = TRUE)),
             hr(),
             p(class = "vars", textOutput("label_var_name", inline = TRUE)),
             div(
               class = "var_selec_group",
               
               # Seleciona filtro
               selectizeInput(
                 "filter1",
                 textOutput("label_geo_name", inline = TRUE),
                 selected = c("Amazônia Legal", "Fora da Amazônia Legal"), 
                 choices = param$filter_choices,
                 multiple = TRUE,
                 width = "100%"),
               
               # espaço vazio
               div(style = "height: 12px;"),
               
               # Seleciona variável do eixo y
               selectInput(
                 inputId = "y",
                 label = param$label_y_name,
                 choices = param$y_choices,
                 selected = c("total produzido", "consumo total"), 
                 multiple = TRUE,
                 width = "100%"
               )
             ),
             
             # espaço vazio
             div(style = "height: 12px;"),
             
             # Seleciona eixo log
             tags$style(HTML(".switch-label { color: white; }")),
             div(
               style = "margin-top: 10px;",
               materialSwitch(
                 inputId = "ylog",
                 label = tags$span(textOutput("label_scale_name", inline = TRUE), class = "switch-label"),
                 value = FALSE,
                 status = "info"
               )
             ),

             # Seleciona eixo
             div(
               style = "margin-top: 10px;",
               materialSwitch(
                 inputId = "y_option",
                 label = tags$span(textOutput("label_prop_name", inline = TRUE), class = "switch-label"),
                 value = FALSE, 
                 status = "info"
               )
             ),
             
             
             # espaço vazio
             div(class = "fakecheckbox", ),

             actionButton(
               "toggle_lang",
               label = "English",
               icon = icon("globe"),
               class = "btn-primary"
             ),

             div(style = "height: 6px;"),

             div(
               shiny::actionButton(inputId = 'ab1', label = "Fullscreen", 
                                   icon = icon("expand"), 
                                   class = "btn-primary",
                                   onclick = paste0("window.open('", param$link, "', '_blank')"))
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
                 style = "position: relative; display: flex; flex-direction: column;",
                 div(
                   style = "flex-grow: 1; position: relative;", 
                   withSpinner(
                     plotlyOutput("plot", width = "100%", height = "calc(100vh - 150px)"),
                     type = 4,
                     color = "#41878C"
                   )
                 )
               )
             )
      )
    ),
  )
}
