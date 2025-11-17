#  -------------------------------- Define UI --------------------------------

# Funcão para retornar objeto server
get_ui <- function(files, param) {
    
    df_temp <- readRDS(files$db_file)
    years <- sort(unique(df_temp$time))
    
    if (param$lang) {
        param$uf_choices <- c("All", sort(unique(df_temp$uf)))
    } else {
        param$uf_choices <- c("Todos", sort(unique(df_temp$uf)))
    }
    
    
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
        
        h2(class = "plot_name", param$plot_name),
        p(class = "plot_desc", param$plot_desc),
        hr(),
        p(class = "vars", param$ui1),
        
        div(
          class = "var_selec_group",
          selectInput(
            inputId = "forest_filter",
            label = param$ui2,
            choices = param$filter_choices,
            selected = param$filter_def,
            width = "100%"
          )),
          
          div(class = "fakecheckbox", ), # espaço vazio
          
        div(
            class = "var_selec_group",
            selectInput(
                inputId = "uf_filter",
                label = "Estado (UF)",          # se quiser, cria param$ui5 em pt/en
                choices = param$uf_choices,
                selected = param$uf_choices[1], # "Todos" ou "All"
                width = "100%"
        )),
          
          div(class = "fakecheckbox", ), # espaço vazio
          
          sliderInput(
              inputId = "year_filter",
              label = param$ui4,
              min = min(years, na.rm = TRUE),
              max = max(years, na.rm = TRUE),
              value = max(years, na.rm = TRUE),
              step = 1,
              sep = "",
              animate = animationOptions(interval = 2000,
                                                  playButton = "\u25B6",
                                                  pauseButton = "\u23F8"),
          ),
        
        # espaço vazio
        div(class = "fakecheckbox", ),
        div(
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
