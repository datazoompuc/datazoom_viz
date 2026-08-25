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

          # O intervalo não tem seletor aqui: é o slider de animação embaixo do
          # gráfico (um passo por janela), igual ao sankey do COMEX.

          # Estado / Município
          div(
            tags$div(
              class = "switch-label", style = "margin-bottom: 4px;",
              textOutput("label_agg", inline = TRUE)
            ),
            div(
              class = "seg-toggle",
              actionButton("geo_est", textOutput("label_geo_est", inline = TRUE),
                           class = "btn-primary seg-btn seg-active"),
              actionButton("geo_munic", textOutput("label_geo_munic", inline = TRUE),
                           class = "btn-primary seg-btn")
            )
          ),

          # Seleciona recorte geográfico (um estado ou um município por vez: o
          # sankey mostra a matriz de transição de UMA unidade)
          selectizeInput(
            "filter1",
            param$i18n$pt$label_geo_name$est,
            choices  = NULL,
            multiple = FALSE,
            width    = "100%"
          ),

          # Quantos fluxos exibir. Uma matriz de transição tem centenas de pares
          # de/para; sem corte o sankey vira um borrão. O default (15) cobre a
          # quase totalidade da área transicionada na maioria dos recortes.
          selectInput(
            inputId  = "top_n",
            label    = param$i18n$pt$label_topn_name,
            choices  = c(10, 15, 20, 30),
            selected = 15,
            width    = "100%"
          ),

          div(style = "margin-top: 5px;"), # espaço em branco

          # Switch renderizado no server p/ traduzir o label no toggle de idioma:
          #   accumulate -> soma os fluxos desde a 1ª janela até a selecionada
          uiOutput("switches")
        ),

        # espaço vazio
        div(class = "fakecheckbox", ),

        div(
          shiny::actionButton(
            "toggle_lang",
            label = param$i18n$pt$btn_lang,
            icon = icon("globe"),
            class = "btn-primary"
          ),
          div(style = "height: 6px;"),
          shiny::actionButton(
            inputId = "ab1", label = "Fullscreen",
            icon = icon("expand"),
            class = "btn-primary",
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
