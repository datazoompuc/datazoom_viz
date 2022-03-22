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
        p(class = "vars", "VARI\u00C1VEIS::"),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo de data
          selectInput(inputId = "filter1",
                      label = "Ano referente",
                      choices = param$year_inicio:param$year_final,
                      selected = param$year_final,
                      width = "100%")
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
            # Map
            leafletOutput("map", width = "100%", height = "100%") # %>% withSpinner()
          )
        )
      )
    ),
  )
}
