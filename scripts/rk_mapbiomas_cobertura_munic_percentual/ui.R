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
        background-color: #50A486;
                   }'),
        
        # muda cor do botao 
        tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                        background-color: #48968B !important;
                        border-color: #48968B !important;
              }',),
        
        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", param$plot_desc),
        hr(),
        p(class = "vars", param$ui1),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo x
          selectInput(
            inputId = "x",
            label = param$ui2,
            choices = param$x_choices,
            selected = param$x_def,
            width = "100%"
          )
        ),
        
        # botão proporção
        
        tags$style(HTML("
        .switch-label {
        color: white;
        }
                        
                        ")),
        div(
            style = "margin-top: 10px;",
            materialSwitch(
                inputId = "yprop",
                label = tags$span(param$prop_button_label, class = "switch-label"),
                value = TRUE,
                status = "info"   # ← mesma cor usada no outro app
            )
        ),
        
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
              style = "flex-grow: 1; position: relative;", 
              withSpinner(
                  plotlyOutput("plot", width = "100%", height = "calc(100vh - 150px)"),
                  type = 4,
                  color = "#41878C"
            )
          )
        )
      )
    ),
  )
}
