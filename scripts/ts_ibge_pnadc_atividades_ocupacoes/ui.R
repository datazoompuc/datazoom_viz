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
                     .menucol { background-color: #41878C; }
                     .btn-primary, .btn-primary:hover,
                     .btn-primary:active, .btn-primary:visited {
                       background-color: #40768B !important;
                       border-color: #40768B !important;
                     }
                     .switch-label { color: white; }
                   '),

                   uiOutput("plot_name_ui"),
                   uiOutput("plot_desc_ui"),
                   hr(),
                   uiOutput("label_var_ui"),

                   div(
                       class = "var_selec_group",
                       selectInput(
                           inputId = "y",
                           label = param$i18n$pt$label_y_name,
                           choices = setNames(param$table$var[param$table$y],
                                              param$table$label[param$table$y]),
                           selected = param$y_def,
                           width = "100%"
                       )
                   ),

                   tags$style(HTML("
                     .switch-group { margin-top: 10px; }
                     .switch-title {
                       display: block;
                       color: white;
                       font-weight: 500;
                       letter-spacing: 0.5px;
                       margin-bottom: 6px;
                     }
                   ")),

                   div(class = "switch-group",
                       uiOutput("label_scale_ui"),
                       materialSwitch(
                           inputId = "ylog",
                           label   = NULL,
                           value   = FALSE,
                           status  = "info"
                       )
                   ),

                   div(class = "switch-group",
                       uiOutput("label_prop_ui"),
                       materialSwitch(
                           inputId = "y_option",
                           label   = NULL,
                           value   = FALSE,
                           status  = "info"
                       )
                   ),

                   selectizeInput(
                       "filter1",
                       param$i18n$pt$label_region_name,
                       choices = NULL,
                       multiple = TRUE,
                       options = list(maxItems = 20),
                       width = "100%"
                   ),

                   selectizeInput(
                       "filter2",
                       param$i18n$pt$label_type_name,
                       choices = NULL,
                       multiple = TRUE,
                       options = list(maxItems = 20),
                       width = "100%",
                       selected = param$ocupation_def
                   ),

                   selectizeInput(
                       "filter3",
                       param$i18n$pt$label_sector_name,
                       choices = NULL,
                       multiple = TRUE,
                       options = list(maxItems = 1),
                       width = "100%",
                       selected = param$sector_def
                   ),

                   div(class = "fakecheckbox"),

                   actionButton(
                       'toggle_lang',
                       label = "English",
                       icon = icon("globe"),
                       class = "btn-primary"
                   ),

                   div(style = "height: 6px;"),

                   actionButton(
                       inputId = 'ab1',
                       label = "Fullscreen",
                       icon = icon("expand"),
                       class = "btn-primary",
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
        )
    )
}
