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
                             background-color: #73C373;
              }',),
        
        # muda cor do botao 
        tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                      background-color: #5FB37E !important;
                      border-color: #5FB37E !important;
          }',),
        
        
        
        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", param$plot_desc),
        hr(),
        p(class = "vars", param$label_var_name),
        div(
          class = "var_selec_group",
          # Seleciona variável de cor (produto/categoria)
          selectInput(
            inputId = "y",
            label = param$label_colour_name,
            choices = param$y_choices,
            selected = param$y_def,
            width = "100%"
          )
        ),
        # O ano é controlado pelo slider/play nativo do plotly (frames)
        # espaço vazio
        div(class = "fakecheckbox", ),
        div(
          shiny::actionButton(inputId = 'ab1', label = "Fullscreen", 
                              icon = icon("expand"), 
                              class = "btn-primary",
                              onclick = paste0("window.open('",param$link,"', '_blank')"))
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
            plotlyOutput("plot", width = "100%", height = "100%") # %>% withSpinner()
          )
        )
      )
    ),
  )
}
