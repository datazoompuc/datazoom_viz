#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {
  div( # div geral
    includeCSS(files$CSS_script), # Incluí script CSS
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3, # dimensão da coluna do bootstrap
        class = "menucol",
        
        # muda cor do background
        tags$style('.menucol {
                        background-color: #3E688B;
              }',),
        
        # muda cor do botao 
        tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                        background-color: #3E5688 !important;
                        border-color: #3E5688 !important;
              }',),
        
        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", textOutput("plot_desc", inline = TRUE)),
        hr(),
        p(class = "vars", textOutput("ui1", inline = TRUE)),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo x
          selectInput(
            inputId = "fonte",
            label = param$i18n$pt$ui2,
            choices = c(param$i18n$pt$server7, param$x_choices),
            selected = param$i18n$pt$server7,
            width = "100%"
          ),
          selectInput(
            inputId = "origem",
            label = param$i18n$pt$ui3,
            choices = c(param$i18n$pt$server7, param$x_choices),
            selected = param$i18n$pt$server7,
            width = "100%"
          ),
          selectInput(
            inputId = "tipo",
            label = param$i18n$pt$ui4,
            choices = c(param$i18n$pt$server7, param$x_choices),
            selected = param$i18n$pt$server7,
            width = "100%"
          ),
          selectInput(
            inputId = "combustivel",
            label = param$i18n$pt$ui5,
            choices = c(param$i18n$pt$server7, param$x_choices),
            selected = param$i18n$pt$server7,
            width = "100%"
          )
        ),

        # espaço vazio
        div(class = "fakecheckbox", ),
        div(
          shiny::actionButton(inputId = 'ab1', label = "Fullscreen",
                              icon = icon("expand"),
                              class = "btn-primary",
                              onclick = paste0("window.open('", param$link, "', '_blank')")),
          shiny::actionButton("toggle_lang", label = "English",
                              icon = icon("globe"),
                              class = "btn-primary")
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
