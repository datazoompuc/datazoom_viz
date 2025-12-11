#  -------------------------------- Define UI --------------------------------

# FuncÃ£o para retornar objeto server
get_ui <- function(files, param) {
  div( # div geral
    includeCSS(files$CSS_script), # Inclu? script CSS
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3, # dimensÃ£o da coluna do bootstrap
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
        p(class = "vars", param$label_var_name),
        
        
        
        # Seleciona filtro de países
        selectizeInput(
            "filter1",
            param$label_country_filter,
            choices = NULL,
            multiple = TRUE,
            options = list(maxItems = 20),
            width = "100%"
        ),
        
        # espaço vazio
        div(class = "fakecheckbox", ),

        
        # Seleciona eixo log
        tags$style(HTML(".switch-label { color: white; }")),
        div(
            style = "margin-top: 10px;",
            materialSwitch(
                inputId = "ylog",
                label = tags$span(param$label_scale_name, class = "switch-label"),
                value = FALSE, 
                status = "info"
            )
        ),
        
        # Seleciona proporcional
        div(
            style = "margin-top: 10px;",
            materialSwitch(
                inputId = "y_option",
                label = tags$span(param$label_axis_name, class = "switch-label"),
                value = FALSE, 
                status = "info"
            )
        ),
        
        # Seleciona deflação
        div(
            style = "margin-top: 10px;",
            materialSwitch(
                inputId = "ydefl",
                label = tags$span(param$label_deflator, class = "switch-label"),
                value = FALSE,  # começa desligado
                status = "info"
            )
        ),
     

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
