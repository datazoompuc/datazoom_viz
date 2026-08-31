#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {
    div( # div geral
        includeCSS(files$CSS_script), # Inclui script CSS
        class = "container-fluid h-100 d-flex flex-column apppanel",
        fluidRow(
            class = "mainrow h-100",
            column(3, # dimensão da coluna do bootstrap
                   class = "menucol",

                   # muda cor do background
                   tags$style('.menucol {
                             background-color: #73C373;
              }',),

                   # muda cor do botao
                   tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                          background-color: #5FB37E !important;
                          border-color: #5FB37E !important;
              }',),

                   h2(class = "plot_name", param$plot_name),
                   p(class = "plot_desc", textOutput("plot_desc", inline = TRUE)),
                   hr(),
                   p(class = "vars", textOutput("label_var_name", inline = TRUE)),
                   div(
                       class = "var_selec_group",
                       # Seleciona filtro
                       selectizeInput(
                           "filter1",
                           param$i18n$pt$label_geo_name,
                           choices = NULL,
                           options = list(maxItems = 20),
                           multiple = TRUE,
                           width = "100%")
                   ),

                   # espaço vazio
                   div(style = "height: 12px;"),

                   p(class = "vars", textOutput("label_scales", inline = TRUE)),

                   # Seleciona eixo log
                   tags$style(HTML(".switch-label { color: white; }")),
                   div(
                       style = "margin-top: 10px;",
                       materialSwitch(
                           inputId = "ylog",
                           label = tags$span(textOutput("label_log_name", inline = TRUE), class = "switch-label"),
                           value = TRUE,
                           status = "info"
                       )
                   ),

                   # O ano nao tem input na sidebar: ele e o frame da animacao do
                   # plotly, entao slider e play/pause saem embaixo do grafico
                   # (mesmo padrao dos apps rk_* e bubble_*)

                   # espaço vazio
                   div(class = "fakecheckbox", ),

                   div(
                       shiny::actionButton(inputId = 'ab1', label = "Fullscreen",
                                           icon = icon("expand"),
                                           class = "btn-primary",
                                           onclick = paste0("window.open('", param$link, "', '_blank')")),
                       shiny::actionButton("toggle_lang", label = "English",
                                           icon = icon("globe"),
                                           class = "btn-primary")
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
                               # Gráfico
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
