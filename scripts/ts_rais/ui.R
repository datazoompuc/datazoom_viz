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
                   
                   h2(class = "plot_name", param$plot_name),
                   p(class = "plot_desc", param$plot_desc),
                   hr(),
                   p(class = "vars", param$label_var_name),
                   
                   # Controles de visualização
                   div(
                       class = "var_selec_group",
                       selectInput(
                           inputId = "y",
                           label = param$label_y_name,
                           choices = list(
                               "Salário Médio" = "real_avg_w",
                               "Número de Vínculos" = "num_vinculos",
                               "Tempo no Emprego" = "tenure"
                           ),
                           selected = param$y_def,
                           width = "100%"
                       )
                   ),
                   
                   checkboxInput(
                       inputId = "ylog",
                       label = param$label_scale_name,
                       value = FALSE,
                       width = "100%"
                   ),
                   
                   checkboxInput(
                       inputId = "y_option",
                       label = param$label_prop_name,
                       value = FALSE,
                       width = "100%"
                   ),
                   
                   
                   
                   # Filtro geográfico
                   div(
                       class = "var_selec_group",
                       selectizeInput(
                           inputId = "filter_geo",
                           label = param$label_geo,  # Mesmo estilo que label_y_name
                           choices = NULL,
                           multiple = TRUE,
                           options = list(placeholder = 'Selecione regiões/estados...', maxItems = 20),
                           width = "100%"
                       )
                   ),
                   
                   # Filtro de grupos
                   div(
                       class = "var_selec_group",
                       selectizeInput(
                           inputId = "filter_group",
                           label = param$label_group,
                           choices = param$group_categories,
                           multiple = FALSE,
                           options = list(placeholder = 'Selecione grupos...'),
                           width = "100%"
                       )
                   ),
                   
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

