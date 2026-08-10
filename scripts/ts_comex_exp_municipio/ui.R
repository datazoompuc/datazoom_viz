#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto ui
get_ui <- function(files, param) {
  div( # div geral
    includeCSS(files$CSS_script),
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3, # dimensão da coluna do bootstrap
        class = "menucol",

        tags$style('.menucol {
                             background-color: #41878C;
              }', ),

        tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                          background-color: #40768B !important;
                          border-color: #40768B !important;
              }', ),
        tags$style(HTML(".switch-label { color: white; }")),
        tags$style(HTML(
          ".transpose-box { background: rgba(255,255,255,.10); border-radius: 6px;
             padding: 8px 10px; margin-bottom: 6px; }
           .transpose-box .role { color: #fff; font-size: 13px; line-height: 1.5; }
           .transpose-box .role b { font-weight: 600; }
           .btn-swap { width: 100%; margin-top: 6px; }
           .sidebar-gap { height: 16px; }"
        )),

        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", textOutput("plot_desc", inline = TRUE)),
        hr(),
        p(class = "vars", textOutput("label_var_name", inline = TRUE)),

        # Painel de transposição (papéis dos eixos + botão de inverter)
        div(
          class = "transpose-box",
          div(class = "role", textOutput("role_y", inline = TRUE)),
          div(class = "role", textOutput("role_lines", inline = TRUE)),
          actionButton(
            "swap",
            label = textOutput("label_swap", inline = TRUE),
            icon = icon("right-left"),
            class = "btn-primary btn-swap"
          )
        ),

        div(class = "sidebar-gap"),

        div(
          class = "var_selec_group",
          # Eixo y (entidade fixada)
          selectInput(
            inputId = "y",
            label = param$i18n$pt$munic_sh2$label_y,
            choices = NULL,
            selected = NULL,
            width = "100%"
          )
        ),
        
        div(class = "sidebar-gap"),

        # Toggle SH2/SEC com dois actionButton (binding nativo, sempre funciona).
        # O destaque do ativo é feito por um handler JS custom.
        tags$style(HTML(
          ".agg-toggle { display: flex; width: 100%; }
           .agg-toggle .agg-btn { flex: 1; border-radius: 0; margin: 0;
             font-size: 14px; padding: 8px 12px; }
           .agg-toggle .agg-btn:first-child { border-radius: 6px 0 0 6px; }
           .agg-toggle .agg-btn:last-child  { border-radius: 0 6px 6px 0; }
           .agg-toggle .agg-active {
             background-color: #2b5560 !important;
             box-shadow: inset 0 0 0 2px rgba(255,255,255,.65) !important;
             font-weight: 600;
           }"
        )),
        tags$script(HTML(
          "Shiny.addCustomMessageHandler('setAgg', function(v){
             var a = document.getElementById('agg_sh2');
             var b = document.getElementById('agg_sec');
             if (a) a.classList.toggle('agg-active', v === 'sh2');
             if (b) b.classList.toggle('agg-active', v === 'sec');
           });"
        )),

        # Agregação SH2 / SEC (antes do seletor de produtos)
        div(
          tags$div(class = "switch-label", style = "margin-bottom: 4px;",
                   textOutput("label_agg", inline = TRUE)),
          div(
            class = "agg-toggle",
            actionButton("agg_sh2", "SH2", class = "btn-primary agg-btn agg-active"),
            actionButton("agg_sec", "SEC", class = "btn-primary agg-btn")
          )
        ),

        div(class = "sidebar-gap"),

        # Filtro (linhas comparadas)
        selectizeInput(
          "filter1",
          param$i18n$pt$munic_sh2$label_filter,
          choices = NULL,
          multiple = TRUE,
          options = list(maxItems = 20),
          width = "100%"
        ),
        
        div(class = "sidebar-gap"),

        # Escala log
        div(
          materialSwitch(
            inputId = "ylog",
            label = tags$span(textOutput("label_scale_name", inline = TRUE), class = "switch-label"),
            value = FALSE,
            status = "info"
          )
        ),

        # Proporcional ao ano inicial
        div(
          materialSwitch(
            inputId = "y_option",
            label = tags$span(textOutput("label_prop_name", inline = TRUE), class = "switch-label"),
            value = FALSE,
            status = "info"
          )
        ),

        div(class = "sidebar-gap"),

        # Idioma + Fullscreen lado a lado
        div(
          style = "display: flex; gap: 8px;",
          actionButton(
            "toggle_lang",
            label = "English",
            icon = icon("globe"),
            class = "btn-primary",
            style = "flex: 1;"
          ),
          shiny::actionButton(
            inputId = "ab1",
            label = textOutput("btn_fullscreen", inline = TRUE),
            icon = icon("expand"),
            class = "btn-primary",
            style = "flex: 1;",
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
