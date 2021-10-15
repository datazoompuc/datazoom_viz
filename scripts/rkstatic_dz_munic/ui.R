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
          # Seleciona variável do eixo x
          selectInput(
            inputId = "x",
            label = "Ranking - eixo horizontal (x):",
            choices = param$x_choices,
            selected = param$x_def,
            width = "100%"
          )
        ),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo x
          sliderInput("slider", 
                      label = "Intervalo de tempo:", 
                      min = as.Date("2000-01-01","%Y-%m-%d"), 
                      max = as.Date("2019-01-01","%Y-%m-%d"), 
                      value = c(as.Date("2000-01-01","%Y-%m-%d"), 
                                as.Date("2019-01-01","%Y-%m-%d")),
                      timeFormat = "%Y"),
        ),
        # Seleciona filtro
        selectInput(
          "filter1",
          "Subdivisão geográfica",
          choices = NULL,
          multiple = TRUE,
          width = "100%"
        ),
        # espaço vazio
        div(class = "fakecheckbox", ),
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
            plotlyOutput("plot", width = "100%", height = "100%") # %>% withSpinner()
          )
        )
      )
    ),
  )
}
