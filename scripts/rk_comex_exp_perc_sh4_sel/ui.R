#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {
    
    db_years <- readRDS(files$db_file)
    years <- sort(unique(db_years$time))
    
    
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
        p(class = "plot_desc", param$plot_desc),
        hr(),
        p(class = "vars", param$ui1),
        div(
          class = "var_selec_group",
          # Seleciona variável de cor
          selectInput(
            inputId = "forest_filter",
            label = param$ui2,
            choices = param$filter_choices,
            selected = param$filter_def,
            width = "100%"
          ),
          
          div(class = "fakecheckbox", ), # espaço vazio
          
          sliderInput(
              inputId = "year_filter",
              label = param$ui4,
              min = min(years, na.rm = TRUE),
              max = max(years, na.rm = TRUE),
              value = max(years, na.rm = TRUE),
              step = 1,
              sep = ""
          ),
        ),
        # espaço vazio
        div(class = "fakecheckbox", ),
        div(
          shiny::actionButton(inputId = 'ab1', label = "Fullscreen", 
                              icon = icon("expand"), 
                              class = "btn-primary",
                              onclick = paste0("window.open('", param$ui3, "', '_blank')"))
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
