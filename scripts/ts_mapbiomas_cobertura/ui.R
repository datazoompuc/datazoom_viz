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

        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", textOutput("plot_desc", inline = TRUE)),
        hr(),
        p(class = "vars", textOutput("label_var_name", inline = TRUE)),

        div(
          style = "display: flex; flex-direction: column; gap: 10px;",
          class = "var_selec_group",

          # Seleciona variável do eixo y
          selectInput(
            inputId = "y",
            label   = param$i18n$pt$label_y_name,
            choices = param$y_choices,
            selected = param$y_def,
            width = "100%"
          ),

          # Seleciona recorte geográfico (estados ou municípios)
          selectizeInput(
            "filter1",
            param$i18n$pt$label_geo_name$est,
            choices  = NULL,
            multiple = TRUE,
            options  = list(maxItems = 20),
            width = "100%"
          ),

          div(style = "margin-top: 5px;"), # espaço em branco

          # Switches (renderizados no server p/ traduzir os labels no toggle de idioma):
          #   geo_munic    -> Estado (off) / Município (on)
          #   y_index_base -> proporcional ao ano inicial (índice base 100)
          #   yprop        -> proporção da área
          uiOutput("switches")
        ),

        # espaço vazio
        div(class = "fakecheckbox", ),

        div(
          shiny::actionButton(
            inputId = "ab1", label = "Fullscreen",
            icon = icon("expand"),
            class = "btn-primary",
            onclick = paste0("window.open('", param$link, "', '_blank')")
          ),
          shiny::actionButton(
            "toggle_lang",
            label = param$i18n$pt$btn_lang,
            icon = icon("globe"),
            class = "btn-primary"
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
