#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto ui
get_ui <- function(files, param) {
  div( # div geral
    includeCSS(files$CSS_script), # Incluí script CSS
    tags$style(type = "text/css",
      # remove o ultimo ano no slider (2018 e 2019 estavam um em cima do outro)
      # remove tracos intermediarios do slider
      # posicionamento e tamanho do botão de play/pause: ver .slider-inline
      # em global/dza_lumen.css (não duplicar regras aqui — a mesma
      # especificidade quebraria o layout flex definido lá)
      "
      .irs-grid-text.js-grid-text-10 {display: none;}
      .irs-grid-pol.small {display: none;}
    "),
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

        tags$style(HTML(".switch-label { color: white; }")),

        uiOutput("plot_name_ui"),
        uiOutput("plot_desc_ui"),
        hr(),
        p(class = "vars", textOutput("label_var_name", inline = TRUE)),
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
        # Proporcional ao municipio(*)
        div(
          style = "margin-top: 10px;",
          materialSwitch(
            inputId = "x_prop",
            label   = tags$span(textOutput("label_prop_name", inline = TRUE), class = "switch-label"),
            value   = FALSE,
            status  = "info"
          )
        ),
        # espaço vazio
        div(class = "fakecheckbox", ),
        div(
          class = "var_selec_group slider-inline",
          # Seleciona variável do eixo de data
          sliderInput(inputId = "filter1",
                      label = param$ref_year,
                      min = param$year_inicio,
                      max = param$year_final,
                      value = 2000,
                      step = 1,
                      width = "100%",
                      animate = animationOptions(interval = 5000,
                                                 playButton = icon("play"),
                                                 pauseButton = icon("pause")),
                      sep = "")
        ),
        # espaço vazio
        div(class = "fakecheckbox", ),
        # Botão de troca de idioma
        div(
          actionButton(
            inputId = "toggle_lang",
            label   = "English",
            icon    = icon("globe"),
            class   = "btn-primary"
          )
        ),
        div(style = "height: 6px;"), # espaço entre os botões
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
            style = "position: relative; display: flex; flex-direction: column;",
            div(
              style = "flex-grow: 1; position: relative;",
              withSpinner(
                leafletOutput("map", width = "100%", height = "calc(100vh - 150px)"),
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
