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

        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", param$plot_desc),
        hr(),
        p(class = "vars", param$label_var_name),

        div(
          class = "var_selec_group",
          selectInput(
            inputId  = "y",
            label    = param$label_y_name,
            choices  = param$y_choices,
            selected = param$y_def,
            width    = "100%"
          )
        ),
        
        div(class = "fakecheckbox"),

        selectizeInput(
          "filter1",
          param$label_mun_filter,
          choices = NULL,
          multiple = TRUE,
          options  = list(maxItems = 20),
          width    = "100%"
        ),

        div(class = "fakecheckbox"),

        div(
          style = "margin-top: 10px;",
          materialSwitch(
            inputId = "ylog",
            label   = tags$span(param$label_scale_name, class = "switch-label"),
            value   = FALSE,
            status  = "info"
          )
        ),

        div(
          style = "margin-top: 10px;",
          materialSwitch(
            inputId = "y_option",
            label   = tags$span(param$label_axis_name, class = "switch-label"),
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
