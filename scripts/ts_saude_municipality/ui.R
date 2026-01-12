#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {
  div( # div geral
    includeCSS(files$CSS_script), # Inclu? script CSS
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
        p(class = "plot_desc", param$plot_desc),
        hr(),
        p(class = "vars",  param$label_var_name),
        
        tags$style(HTML(".switch-label { color: white; }")),
        div(
            style = "display: flex; flex-direction: column; gap: 10px;", # espaçamento dos botões
            
          class = "var_selec_group",
          # Seleciona variável do eixo y
          selectInput(
            inputId = "y",
            label = param$label_y_name,
            choices = param$y_choices,
            selected = param$y_def,
            width = "100%"
          ),
          
          div(style = "margin-top: 5px;"),  # espaço em branco
          
          
          # BLOCO DOS BOTÕES
          
          # Seleciona eixo log
          materialSwitch(
              inputId = "ylog",
              label = tags$span(param$label_log_name, class = "switch-label"),
              value = FALSE,
              status = "info"
          ),
          
          # Variação do ano inicial 
          materialSwitch(
              inputId = "y_index_base",
              label = tags$span(param$label_prop_name, class = "switch-label"),
              value = FALSE,
              status = "info"
          ),
          
          # Seleciona filtro
          selectizeInput(
              "uf",
              param$label_uf_name,
              choices = c("Rondônia (RO)" = "RO", 
                          "Acre (AC)" = "AC", 
                          "Amazonas (AM)" = "AM",
                          "Roraima (RR)" = "RR",
                          "Pará (PA)" = "PA",
                          "Amapá (AP)" = "AP",
                          "Tocantins (TO)" = "TO",
                          "Maranhão (MA)" = "MA",
                          "Piauí (PI)" = "PI",
                          "Bahia (BA)" = "BA",
                          "Mato Grosso do Sul (MS)" = "MS",
                          "Mato Grosso (MT)" = "MT",
                          "Goiás (GO)" = "GO"),
              selected = param$uf_def,
              multiple = TRUE,
              options = list(maxItems = 20, plugins = list('remove_button')),
              width = "100%"
          ),
          
          # Filtro de municípios (só aparece quando NÃO está agregado por estado)
          conditionalPanel(
              condition = "input.aggregate_state == false",
              selectizeInput(
                  "filter1",
                  param$label_geo_name,
                  choices = param$munic_def,
                  selected = param$munic_def,
                  multiple = TRUE,
                  options = list(maxItems = 20, plugins = list('remove_button')),
                  width = "100%"
              )
          ),
          
          #alterar a visualização municipal e estadual
          materialSwitch(
              inputId = "aggregate_state",
              label = tags$span(param$label_aggregate_name, class = "switch-label"),
              value = FALSE,
              status = "info"
          ),
        ),

        # espaço vazio
        div(class = "fakecheckbox", ),
        
        div(
          shiny::actionButton(inputId = 'ab1', label = "Fullscreen", 
                              icon = icon("expand"), 
                              class = "btn-primary",
                              onclick = paste0("window.open('", param$link, "', '_blank')"))
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
