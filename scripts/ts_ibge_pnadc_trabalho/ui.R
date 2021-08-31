#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {
  div( # div geral
    includeCSS(files$CSS_script), # Incluí script CSS
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3, # dimensão da coluna do bootstrap
        class = "menucol",
        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", param$plot_desc),
        hr(),
        p(class = "vars", "VARI\u00C1VEIS:"),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo y
          selectInput(
            inputId = "y",
            label = "Eixo vertical (y)",
            choices = param$y_choices,
            selected = param$y_def,
            width = "100%"
          )
        ),

        # espaço vazio
        div(class = "fakecheckbox", ),

        # Seleciona filtro de municípios
        selectizeInput(
          "filter1",
          "Recorte de região geográfica",
          choices = NULL,
          multiple = TRUE,
          options = list(maxItems = 20),
          width = "100%"
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
            # Gráfico
            plotlyOutput("plot", width = "100%", height = "100%")
          )
        )
      )
    ),
  )
}
