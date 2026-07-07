#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {

  div( # div geral
    includeCSS(files$CSS_script),
    tags$style(type = "text/css", "
        /* some o último rótulo da grade */
        .irs-grid-text.js-grid-text-10 {display: none;}
        /* some tracinhos pequenos da grade */
        .irs-grid-pol.small {display: none;}
        
        /* posição/tamanho do botão de play/pause do slider */
        .slider-animate-container {width: 5%; margin-top: 1px;}
        .slider-animate-button {font-size: 20px;}
        
        /* deixar anos em branco (texto) */
        .irs-grid-text { color: #FFFFFF; }
        .irs-single, .irs-min, .irs-max, .irs-from, .irs-to {
          color: #FFFFFF;
          background: transparent;
        }
      "),
    tags$style(HTML(".switch-label { color: white; }")),
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3, # dimensão da coluna do bootstrap
        class = "menucol",
        
        # muda cor do background
        tags$style('.menucol {
                        background-color: #3E688B;
              }',),
        
        # muda cor do botao 
        tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                        background-color: #3E5688 !important;
                        border-color: #3E5688 !important;
              }',),

        uiOutput("plot_name_ui"),
        uiOutput("plot_desc_ui"),
        hr(),
        p(class = "vars", textOutput("label_ui1", inline = TRUE)),

        div(
          class = "var_selec_group",
          selectInput(
            inputId = "forest_filter",
            label = param$i18n$pt$ui2,
            choices = param$i18n$pt$filter_choices,
            selected = param$i18n$pt$filter_choices[1],
            width = "100%"
          )),
          
          div(class = "fakecheckbox", ), # espaço vazio
          
        div(
            class = "var_selec_group",
            selectInput(
                inputId = "uf_filter",
                label = param$i18n$pt$ui5,
                choices = NULL,
                width = "100%"
        )),
          
          div(class = "fakecheckbox", ), # espaço vazio

          uiOutput("year_slider"),

        # espaço vazio
        div(class = "fakecheckbox", ),
        div(
          shiny::actionButton(inputId = "toggle_lang", label = param$i18n$pt$btn_lang,
                              icon = icon("globe"),
                              class = "btn-primary"),
          shiny::actionButton(inputId = 'ab1', label = "Fullscreen",
                              icon = icon("expand"),
                              class = "btn-primary",
                              onclick = paste0("window.open('", param$ui3, "', '_blank')"))
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
