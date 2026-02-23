#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
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
          }'
                   ),
                   
                   uiOutput("plot_name_ui"),
                   uiOutput("plot_desc_ui"),
                   hr(),
                   uiOutput("label_var_ui"),
                   
                   # Controles de visualização
                   div(
                       class = "var_selec_group",
                       selectInput(
                           inputId = "y",
                           label = param$label_y_name,
                           choices = setNames(param$table$var[param$table$y], 
                                              param$table$label[param$table$y]),
                           selected = param$y_def,
                           width = "100%"
                       )
                   ),
                   
                   # espaço vazio
                   div(style = "height: 12px;"),
                   
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
                           label = tags$span(param$label_prop_name, class = "switch-label"),
                           value = FALSE, 
                           status = "info"
                       )
                   ),
                      
                   hr(),
                   
                   
                   # Filtro geográfico
                   div(
                       class = "var_selec_group",
                       selectizeInput(
                           inputId = "filter_geo",
                           label = param$label_geo,  # Mesmo estilo que label_y_name
                           choices = NULL,
                           multiple = TRUE,
                           options = list(placeholder = param$label_geo, maxItems = 20),
                           width = "100%"
                       )
                   ),
                   
                   # espaço vazio
                   div(style = "height: 6px;"),
                   
                   # Filtro de grupos
                   div(
                       class = "var_selec_group",
                       selectizeInput(
                           inputId = "filter_group",
                           label = param$label_group,
                           choices = param$group_categories,
                           multiple = FALSE,
                           options = list(placeholder = param$label_group),
                           width = "100%"
                       )
                   ),
                   
                   # espaço vazio
                   div(class = "fakecheckbox", ),
                   
                   actionButton(
                       'toggle_lang',
                       label = "English",
                       icon = icon("globe"),
                       class = "btn-primary"
                   ),
                   
                   # espaço vazio
                   div(style = "height: 6px;"),
                   
                   actionButton(
                       'ab1', 
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
        )
    )
}

