#  -------------------------------- Define UI --------------------------------

get_ui <- function(files, param) {
    div(
        includeCSS(files$CSS_script),
        class = "container-fluid h-100 d-flex flex-column apppanel",
        fluidRow(
            class = "mainrow h-100",
            column(3,
                   class = "menucol",

                   tags$style('
                     .menucol { background-color: #3E688B; }
                     .btn-primary, .btn-primary:hover,
                     .btn-primary:active, .btn-primary:visited {
                       background-color: #3E5688 !important;
                       border-color: #3E5688 !important;
                     }
                   '),

                   uiOutput("plot_name_ui"),
                   uiOutput("plot_desc_ui"),
                   hr(),
                   uiOutput("label_var_ui"),

                   div(
                       class = "var_selec_group",
                       selectInput(
                           inputId  = "x",
                           label    = param$i18n$pt$label_x_name,
                           choices  = param$x_choices,
                           selected = param$x_def,
                           width    = "100%"
                       )
                   ),

                   uiOutput("deflator_notice_ui"),

                   selectInput(
                       inputId  = "filter2",
                       label    = param$i18n$pt$label_type_name,
                       choices  = list(
                           param$i18n$pt$type_cnae,
                           param$i18n$pt$type_cod
                       ),
                       selected = param$type_def,
                       width    = "100%"
                   ),

                   selectizeInput(
                       "filter1",
                       param$i18n$pt$label_region_name,
                       choices  = NULL,
                       width    = "100%",
                       selected = param$group_def
                   ),

                   selectizeInput(
                       "filter3",
                       param$i18n$pt$label_sector_name,
                       choices  = NULL,
                       width    = "100%",
                       selected = param$sector_def
                   ),

                   div(class = "fakecheckbox"),

                   div(actionButton(
                       "toggle_lang",
                       label = "English",
                       icon  = icon("globe"),
                       class = "btn-primary"
                   ),

                   shiny::actionButton(
                       inputId = "ab1",
                       label   = "Fullscreen",
                       icon    = icon("expand"),
                       class   = "btn-primary",
                       onclick = paste0("window.open('", param$link, "', '_blank')")
                   ))
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
                                   color = "#3E688B"
                               )
                           )
                       )
                   )
            )
        )
    )
}
