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
        
        # muda cor do background
        tags$style('.menucol {
                             background-color: #41878C;
              }',),
        
        # muda cor do botao 
        tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                          background-color: #40768B !important;
                          border-color: #40768B !important;
              }',),
        
        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", textOutput("plot_desc", inline = TRUE)),
        hr(),
        div(
          class = "var_selec_group",
          # Seleciona variável do eixo y
          selectInput(
            inputId = "y",
            label = param$i18n$pt$label_y_name,
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
          param$i18n$pt$label_region_name,
          choices = NULL,
          multiple = TRUE,
          options = list(maxItems = 20),
          width = "100%"
        ),
        
        # espaço vazio
        div(class = "fakecheckbox", ),
          p(class = "vars", textOutput("label_var_name", inline = TRUE)),
        # Seleciona filtro de modalidade empreendimento
        selectInput(
          "filter_sig_modalidade_empreendimento",
          param$i18n$pt$label_type_name,
          choices = NULL,
          selected = param$i18n$pt$filter_modalidade_def,
          width = "100%"
        ),
        # Seleciona filtro de tipo geracao
        selectInput(
          "filter_dsc_fonte_geracao",
          param$i18n$pt$label_source_name,
          choices = NULL,
          selected = param$i18n$pt$filter_fonte_def,
          width = "100%"
        ),
        # Seleciona filtro de tipo porte
        selectInput(
          "filter_dsc_porte",
          param$i18n$pt$label_size_name,
          choices = NULL,
          selected = param$i18n$pt$filter_porte_def,
          width = "100%"
        ),
        
        # espaço vazio
        div(class = "fakecheckbox", ),
        
        div(
          shiny::actionButton(inputId = 'ab1', label = "Fullscreen",
                              icon = icon("expand"),
                              class = "btn-primary",
                              onclick = paste0("window.open('", param$link, "', '_blank')")),
          shiny::actionButton("toggle_lang", label = "English",
                              icon = icon("globe"),
                              class = "btn-primary")
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
