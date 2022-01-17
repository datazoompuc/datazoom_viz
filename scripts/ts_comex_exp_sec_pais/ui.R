#  -------------------------------- Define UI --------------------------------

# Func√£o para retornar objeto server
get_ui <- function(files, param) {
  div( # div geral
    includeCSS(files$CSS_script), # Inclu? script CSS
    class = "container-fluid h-100 d-flex flex-column apppanel",
    fluidRow(
      class = "mainrow h-100",
      column(3, # dimens√£o da coluna do bootstrap
        class = "menucol",
        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", param$plot_desc),
        hr(),
        p(class = "vars", "VARI\u00C1VEIS:"),
        div(
          class = "var_selec_group",
          # Seleciona vari√°vel do eixo y
          selectInput(
            inputId = "y",
            label = "PaÌses destino das exportaÁıes",
            choices = param$y_choices,
            selected = param$y_def,
            width = "100%"
          )
        ),

        # Seleciona eixo log
        checkboxInput(
          inputId = "ylog",
          "escala log",
          value = FALSE,
          width = "100%"
        ),
        # Seleciona eixo
        checkboxInput(
          inputId = "y_option",
          "proporcional ao ano inicial (*)",
          value = FALSE,
          width = "100%"
        ),

        # Seleciona filtro de munic√≠pios
        selectizeInput(
          "filter1",
          "Categorias da exportaÁ„o (agregaÁ„o da SEC)",
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
        div( # row do gr√°fico
          class = "plotrow row justify-content-center flex-grow-1 w-100",
          div(
            class = "plotdiv w-100 h-100",
            # Gr√°fico
            plotlyOutput("plot", width = "100%", height = "100%")
          )
        )
      )
    ),
  )
}
