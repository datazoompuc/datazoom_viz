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
                   }'),
                   tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                        background-color: #3E5688 !important;
                        border-color: #3E5688 !important;
                   }'),

                   h2(class = "plot_name", param$plot_name),
                   p(class  = "plot_desc", param$plot_desc),
                   hr(),
                   p(class  = "vars", param$label_var_name),

                   div(
                       class = "var_selec_group",
                       selectInput(
                           inputId  = "x",
                           label    = param$label_x_name,
                           choices  = param$x_choices,
                           selected = param$x_def,
                           width    = "100%"
                       )
                   ),

                   uiOutput("deflator_notice_ui"),

                   selectInput(
                       inputId  = "filter2",
                       label    = param$label_type_name,
                       choices  = param$type_choices,
                       selected = param$type_def,
                       width    = "100%"
                   ),

                   selectizeInput(
                       "filter1",
                       param$label_region_name,
                       choices  = param$filter_choices,
                       width    = "100%",
                       selected = param$group_def
                   ),

                   selectizeInput(
                       "filter3",
                       param$label_sector_name,
                       choices  = param$sector_choices,
                       width    = "100%",
                       selected = param$sector_def
                   ),

                   div(class = "fakecheckbox"),

                   shiny::actionButton(
                       inputId = "ab1",
                       label   = "Fullscreen",
                       icon    = icon("expand"),
                       class   = "btn-primary",
                       onclick = paste0("window.open('", param$link, "', '_blank')")
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
                           plotlyOutput("plot", width = "100%", height = "100%")
                       )
                   )
            )
        )
    )
}
