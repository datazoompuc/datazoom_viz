#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {
  div( # div geral
    includeCSS(files$CSS_script), # Incluí script CSS
    tags$style(type = "text/css", "
      .irs-grid-text.js-grid-text-10 {display: none;}
      .irs-grid-pol.small {display: none;}
      .slider-animate-container {width: 5%; margin-top: 1px;}
      .slider-animate-button {font-size: 20px;}
    "),
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3, # dimensão da coluna do bootstrap
        class = "menucol",
        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", param$plot_desc),
        hr(),
        p(class = "vars", "VARI\u00C1VEIS::"),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo x
          selectInput(
            inputId = "x",
            label = "Seleciona variável (x)",
            choices = param$x_choices,
            selected = param$x_def,
            width = "100%"
          )
        ),
        # espaço vazio
        div(class = "fakecheckbox", ),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo de data
          sliderInput(inputId = "filter1",
                      label = "Ano referente",
                      min = 2000,
                      max = 2019,
                      value = 2000,
                      step = 1,
                      width = "100%",
                      animate = animationOptions(interval = 2000,
                                                 playButton = "\u25B6",
                                                 pauseButton = "\u23F8"),
                      sep = "")
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
            # Map
            leafletOutput("map", width = "100%", height = "100%") # %>% withSpinner()
          )
        )
      )
    ),
  )
}
