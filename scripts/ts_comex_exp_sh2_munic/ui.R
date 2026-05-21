#  -------------------------------- Define UI --------------------------------

get_ui <- function(files, param) {
  div(
    includeCSS(files$CSS_script),
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3,
        class = "menucol",

        tags$style('.menucol { background-color: #41878C; }'),
        tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                      background-color: #40768B !important;
                      border-color: #40768B !important; }'),
        tags$style(HTML(".switch-label { color: white; }")),

        uiOutput("plot_name_ui"),
        uiOutput("plot_desc_ui"),
        hr(),
        p(class = "vars", textOutput("label_var_name", inline = TRUE)),

        div(
          class = "var_selec_group",
          selectInput(
            inputId  = "y",
            label    = textOutput("label_y_name", inline = TRUE),
            choices  = NULL,
            selected = NULL,
            width    = "100%"
          )
        ),

        div(class = "fakecheckbox"),

        selectizeInput(
          "filter1",
          choices = NULL,
          textOutput("label_mun_filter", inline = TRUE),
          multiple = TRUE,
          options  = list(maxItems = 20),
          width    = "100%"
        ),

        div(class = "fakecheckbox"),

        div(
          style = "margin-top: 10px;",
          materialSwitch(
            inputId = "ylog",
            label   = tags$span(textOutput("label_scale_name", inline = TRUE), class = "switch-label"),
            value   = FALSE,
            status  = "info"
          )
        ),

        div(
          style = "margin-top: 10px;",
          materialSwitch(
            inputId = "y_option",
            label   = tags$span(textOutput("label_axis_name", inline = TRUE), class = "switch-label"),
            value   = FALSE,
            status  = "info"
          )
        ),

        div(class = "fakecheckbox"),

        div(
          shiny::actionButton(
            inputId = "ab1",
            label   = "Fullscreen",
            icon    = icon("expand"),
            class   = "btn-primary",
            onclick = paste0("window.open('", param$link, "', '_blank')")
          ),
          actionButton(
            inputId = "toggle_lang",
            label   = "English",
            icon    = icon("globe"),
            class   = "btn-primary"
          )
        )
      ),
      column(9,
        class = "plotcol h-100",
        textOutput("plot_title"),
        textOutput("plot_subtitle"),
        div(
          class = "plotrow row justify-content-center flex-grow-1 w-100",
          div(
            class = "plotdiv w-100 h-100",
            style = "position: relative; display: flex; flex-direction: column;",
            div(
              style = "flex-grow: 1; position: relative;",
              withSpinner(
                plotlyOutput("plot", width = "100%", height = "calc(100vh - 150px)"),
                type  = 4,
                color = "#41878C"
              )
            )
          )
        )
      )
    )
  )
}
