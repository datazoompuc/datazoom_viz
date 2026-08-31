#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {
  div( # div geral
    includeCSS(files$CSS_script), # Incluí script CSS
    tags$style(type = "text/css", 
      # remove o ultimo ano no slider (2018 e 2019 estavam um em cima do outro)
      # remove tracos intermediarios do slider
      # move botao de play para a esquerda e para baixo
      # aumenta tamanho do botao de play
      "
      .irs-grid-text.js-grid-text-10 {display: none;}
      .irs-grid-pol.small {display: none;}
      .slider-animate-container {width: 5%; margin-top: 1px;}
      .slider-animate-button {font-size: 20px;}
      
      /* Legenda retrátil no hover para não poluir o mapa */
      .legend {
        max-height: 28px;
        overflow: hidden;
        transition: max-height 0.4s ease-in-out, opacity 0.3s;
        opacity: 0.85;
        cursor: pointer;
      }
      .legend:hover, .legend.pinned {
        max-height: 500px;
        opacity: 1;
      }
    "),
    tags$script(HTML("
      $(document).on('click', '.legend', function() {
        $(this).toggleClass('pinned');
      });
    ")),
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3, # dimensão da coluna do bootstrap
        class = "menucol",
        
        # muda cor do background
        tags$style('.menucol {
                             background-color: #50A486;
              }',),
        
        # muda cor do botao 
        tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                          background-color: #48968B !important;
                          border-color: #48968B !important;
              }',),
        
        uiOutput("plot_name_ui"),
        uiOutput("plot_desc_ui"),
        hr(),
        textOutput("label_var_name"),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo x
          selectInput(
            inputId = "x",
            label = param$label_x_name,
            choices = param$x_choices,
            selected = param$x_def,
            width = "100%"
          )
        ),
        # espaço vazio
        div(class = "fakecheckbox", ),
        div(
          class = "var_selec_group slider-inline",
          # Seleciona variável do eixo de data
          sliderInput(inputId = "filter1",
                      label = param$label_year,
                      min = param$year_inicio,
                      max = param$year_final,
                      value = param$year_final,
                      step = 1,
                      width = "100%",
                      animate = animationOptions(interval = 3000,
                                                 playButton = icon("play"),
                                                 pauseButton = icon("pause")),
                      sep = "")
        ),
        # espaço vazio
        div(class = "fakecheckbox", ),
        div(
          class = "d-flex gap-2",
          shiny::actionButton(inputId = 'ab1', label = "Tela Cheia", 
                              icon = icon("expand"), 
                              class = "btn-primary",
                              onclick = paste0("window.open('", param$link, "', '_blank')")),
          actionButton("toggle_lang", label = "English", class = "btn-primary")
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
            withSpinner(leafletOutput("map", width = "100%", height = "calc(100vh - 150px)"), type = 4, color = "#50A486")
          )
        )
      )
    ),
  )
}
