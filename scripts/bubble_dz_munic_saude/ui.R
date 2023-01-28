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
                             background-color: #414683;
              }',),
        
        # muda cor do botao 
        tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                          background-color: #423379 !important;
                          border-color: #423379 !important;
              }',),
        
        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", param$plot_desc),
        hr(),
        p(class = "vars", param$variable),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo x
          selectInput(
            inputId = "x",
            label = param$label_x,
            choices = param$x_choices,
            selected = param$x_def,
            width = "100%"
          )
        ),
        # Seleciona eixo log
        checkboxInput(
          inputId = "xlog",
          "escala log",
          value = FALSE,
          width = "100%"
        ),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo y
          selectInput(
            inputId = "y",
            label = param$label_y,
            choices = param$y_choices,
            selected = param$y_def,
            width = "100%"
          )
        ),
        # Seleciona eixo log
        checkboxInput(
          inputId = "ylog",
          param$log_scale,
          value = FALSE,
          width = "100%"
        ),
        div(
          class = "var_selec_group",
          # Seleciona variável de cor
          selectInput(
            inputId = "color",
            label = param$color_label,
            choices = param$color_choices,
            selected = param$color_def,
            width = "100%"
          )
        ),
        # espaço vazio
        div(class = "fakecheckbox", ),
        div(
          class = "var_selec_group",
          # Seleciona variável de tamanho
          selectInput(
            inputId = "size",
            label = param$marker_size,
            choices = param$size_choices,
            selected = param$size_def,
            width = "100%"
          )
        ),
        
        # espaço vazio
        div(class = "fakecheckbox", ),
        
        div(
          shiny::actionButton(inputId = 'ab1', label = "Fullscreen", 
                              icon = icon("expand"), 
                              class = "btn-primary",
                              onclick = "window.open('https://datazoom.shinyapps.io/app_bubble_dz_munic_saude/', '_blank')")
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
