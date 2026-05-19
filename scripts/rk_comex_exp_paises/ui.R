#  -------------------------------- Define UI --------------------------------

get_ui <- function(files, param) {
  div(
    includeCSS(files$CSS_script),
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3,
        class = "menucol",

        tags$style('.menucol {
                        background-color: #3E688B;
              }',),

        tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                        background-color: #3E5688 !important;
                        border-color: #3E5688 !important;
              }',),

        uiOutput("plot_name_ui"),
        uiOutput("plot_desc_ui"),
        hr(),

        tags$style(HTML(".switch-label { color: white; }")),
        div(
          style = "margin-top: 10px;",
          materialSwitch(
            inputId = "ydefl",
            label = tags$span(textOutput("label_deflator", inline = TRUE), class = "switch-label"),
            value = FALSE,
            status = "info"
          )
        ),

        div(class = "fakecheckbox"),

        div(
          shiny::actionButton(inputId = 'ab1', label = "Fullscreen",
                              icon = icon("expand"),
                              class = "btn-primary",
                              onclick = paste0("window.open('", param$link, "', '_blank')")),
          actionButton(
            inputId = "toggle_lang",
            label   = "English",
            icon    = icon("globe"),
            class   = "btn-primary"
          ),
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
