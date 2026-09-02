#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto ui
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
                             background-color: #41878C;
              }', ),

        # muda cor do botao
        tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                          background-color: #40768B !important;
                          border-color: #40768B !important;
              }', ),

        # labels dos materialSwitch em branco
        tags$style(HTML(".switch-label { color: white; }")),

        uiOutput("plot_name_ui"),
        uiOutput("plot_desc_ui"),
        hr(),
        p(class = "vars", textOutput("label_var_name", inline = TRUE)),

        div(
          style = "display: flex; flex-direction: column; gap: 10px;",
          class = "var_selec_group",

          # 1. Seleciona variável do eixo y
          selectInput(
            inputId = "y",
            label   = param$label_y_name,
            choices = param$y_choices,
            selected = param$y_def,
            width = "100%"
          ),

          # 2. Seleciona municípios de todos os estados (sem seletor de estado)
          selectizeInput(
            "filter1",
            param$label_geo_name,
            choices  = param$munic_def,
            selected = param$munic_def,
            multiple = TRUE,
            options  = list(maxItems = 20, plugins = list('remove_button')),
            width = "100%"
          ),

          div(style = "margin-top: 5px;"),

          # 3. Switches
          materialSwitch(
            inputId = "y_index_base",
            label   = tags$span(textOutput("label_prop_name", inline = TRUE), class = "switch-label"),
            value   = FALSE,
            status  = "info"
          ),
          materialSwitch(
            inputId = "ylog",
            label   = tags$span(textOutput("label_scale_name", inline = TRUE), class = "switch-label"),
            value   = FALSE,
            status  = "info"
          ),
        ),

        # espaço vazio
        div(class = "fakecheckbox"),

        div(
          actionButton(
            inputId = "toggle_lang",
            label   = "English",
            icon    = icon("globe"),
            class   = "btn-primary"
          ),
          div(style = "height: 6px;"),
          shiny::actionButton(
            inputId = "ab1",
            label   = param$i18n$pt$btn_fullscreen,
            icon    = icon("expand"),
            class   = "btn-primary",
            onclick = paste0("window.open('", param$link, "', '_blank')")
          )
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
