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

        # Toggle Estado/Município: dois actionButton estilizados como segmented
        # control. O CSS (.seg-toggle/.seg-btn/.seg-active) está no CSS global;
        # aqui fica só o handler que destaca o botão ativo (IDs específicos do app).
        tags$script(HTML(
          "Shiny.addCustomMessageHandler('setGeo', function(v){
             var a = document.getElementById('geo_est');
             var b = document.getElementById('geo_munic');
             if (a) a.classList.toggle('seg-active', v === 'est');
             if (b) b.classList.toggle('seg-active', v === 'munic');
           });"
        )),

        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", textOutput("plot_desc", inline = TRUE)),
        hr(),
        p(class = "vars", textOutput("label_var_name", inline = TRUE)),

        div(
          style = "display: flex; flex-direction: column; gap: 10px;",
          class = "var_selec_group",

          # Seleciona classe de origem (de) — rótulo PT/EN atualizado no server;
          # choices trazem label PT/EN e valor = chave em inglês
          selectInput(
            inputId = "x_from",
            label   = param$i18n$pt$label_from,
            choices = NULL,
            width = "100%"
          ),

          # Seleciona classe de destino (para)
          selectInput(
            inputId = "x_to",
            label   = param$i18n$pt$label_to,
            choices = NULL,
            width = "100%"
          ),

          div(class = "sidebar-gap"),

          # Estado / Município
          div(
            tags$div(class = "switch-label", style = "margin-bottom: 4px; color: white;",
                     textOutput("label_agg", inline = TRUE)),
            div(
              class = "seg-toggle",
              actionButton("geo_est", textOutput("label_geo_est", inline = TRUE),
                           class = "btn-primary seg-btn seg-active"),
              actionButton("geo_munic", textOutput("label_geo_munic", inline = TRUE),
                           class = "btn-primary seg-btn")
            )
          ),

          div(style = "margin-top: 5px;"), # espaço

          # Switch "acumulado desde o 1º ano" (label renderizado no server p/ idioma+ano)
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
        uiOutput("plot_subtitle"),
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
