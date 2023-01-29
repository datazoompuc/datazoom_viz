#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {
  div( # div geral
    includeCSS(files$CSS_script), # Inclu? script CSS
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
    "),
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
        p(class = "vars", param$variable),
        div(
          class = "var_selec_group",
          # Seleciona filtro
          selectizeInput(
            "filter1",
            "Subdivisão geográfica",
            choices = NULL,
            multiple = TRUE,
            width = "100%")
        ),
        
        # Seleciona eixo log
        checkboxInput(
          inputId = "ylog",
          param$logx,
          value = TRUE,
          width = "100%"
        ),
        
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo de data
          sliderInput(inputId = "filter_ano",
                      label = param$ref_year,
                      min = param$year_inicio,
                      max = param$year_final,
                      value = param$year_final,
                      step = 1,
                      width = "100%",
                      sep = "")
        ),
        
        # espaço vazio
        div(class = "fakecheckbox", ),
        
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
            # Gráfico
            plotlyOutput("plot", width = "100%", height = "100%")
          )
        )
      )
    ),
  )
}
