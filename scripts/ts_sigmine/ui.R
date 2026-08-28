#  -------------------------------- Define UI --------------------------------
get_ui <- function(files, param) {
    div(
        includeCSS(files$CSS_script),
        class = "container-fluid h-100 d-flex flex-column apppanel",
        
        tags$style(HTML(".switch-label { color: white; }")),
        
        fluidRow(
            class = "mainrow h-100",
            column(3,
                   class = "menucol",
                   h2(class = "plot_name", param$plot_name),
                   uiOutput("plot_desc_ui"),
                   hr(),
                   p(class = "vars", textOutput("label_var_name", inline = TRUE)),
                   
                   div(
                       class = "var_selec_group",
                       selectInput(
                           inputId = "y",
                           label = param$label_y_name,
                           choices = param$y_choices,
                           selected = param$y_def,
                           width = "100%"
                       )
                   ),
                   
                   # materialSwitch: escala log
                   div(
                       style = "margin-top: 10px;",
                       materialSwitch(
                           inputId = "ylog",
                           label   = tags$span(textOutput("label_scale_name", inline = TRUE), class = "switch-label"),
                           value   = FALSE,
                           status  = "info"
                       )
                   ),
                   
                   # materialSwitch: proporcional ao ano inicial
                   div(
                       style = "margin-top: 10px;",
                       materialSwitch(
                           inputId = "y_option",
                           label   = tags$span(textOutput("label_axis_name", inline = TRUE), class = "switch-label"),
                           value   = FALSE,
                           status  = "info"
                       )
                   ),
                   
                   selectizeInput(
                       "filter1",
                       param$label_mun_filter,
                       choices = NULL,
                       multiple = TRUE,
                       options = list(maxItems = 20),
                       width = "100%"
                   ),
                   
                   div(class = "fakecheckbox", ),
                   
                   # Botão de idioma, acima do fullscreen
                   div(
                       actionButton(
                           inputId = "toggle_lang",
                           label   = "English",
                           icon    = icon("globe"),
                           class   = "btn-primary"
                       )
                   ),
                   div(style = "height: 6px;"),
                   
                   div(
                       shiny::actionButton(inputId = "ab1", label = "Fullscreen",
                                           icon = icon("expand"),
                                           class = "btn-primary",
                                           onclick = paste0("window.open('", param$link, "', '_blank')"))
                   ),
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
        ),
    )
}