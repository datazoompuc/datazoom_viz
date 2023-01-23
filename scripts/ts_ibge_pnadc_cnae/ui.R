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
        p(class = "vars",  param$label_var_name),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo y
          selectInput(
            inputId = "y",
            label = param$label_y_name,
            choices = param$y_choices,
            selected = param$y_def,
            width = "100%"
          )
        ),

        # Seleciona eixo log
        checkboxInput(
          inputId = "ylog",
          param$label_scale_name,
          value = FALSE,
          width = "100%"
        ),
        # Seleciona eixo
        checkboxInput(
          inputId = "y_option",
          param$label_prop_name,
          value = FALSE,
          width = "100%"
        ),

        # Seleciona filtro de municípios
        selectizeInput(
          "filter1",
          param$label_eco_name,
          choices = NULL,
          multiple = TRUE,
          options = list(maxItems = 20),
          width = "100%"
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
