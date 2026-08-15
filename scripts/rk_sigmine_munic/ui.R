#  -------------------------------- Define UI --------------------------------
get_ui <- function(files, param) {
    div( # div geral
        includeCSS(files$CSS_script),
        class = "container-fluid h-100 d-flex flex-column apppanel",
        
        # NOVO: CSS do label dos switches (não tem switch aqui ainda, mas é o padrão)
        tags$style(HTML(".switch-label { color: white; }")),
        
        fluidRow(
            class = "mainrow h-100",
            column(3,
                   class = "menucol",
                   
                   tags$style('.menucol {
                        background-color: #3E688B;
              }',),
                   
                   tags$style('.btn-primary, .btn-primary:hover, .btn-primary:active, .btn-primary:visited {
                        background-color: #3E5688 !important;
                        border-color: #3E5688 !important;
              }',),
                   
                   # ANTES: h2(class = "plot_name", param$plot_name)
                   # DEPOIS: nome do app não muda com idioma, continua fixo
                   h2(class = "plot_name", param$plot_name),
                   
                   # ANTES: p(class = "plot_desc", param$plot_desc)  -- texto fixo
                   # DEPOIS: uiOutput, populado no server a partir do i18n()
                   uiOutput("plot_desc_ui"),
                   
                   hr(),
                   
                   # ANTES: p(class = "vars", param$ui1)
                   p(class = "vars", textOutput("label_ui1", inline = TRUE)),
                   
                   div(
                       class = "var_selec_group",
                       selectInput(
                           inputId = "x",
                           label = param$ui2,   # label inicial; será atualizado via updateSelectInput no lang toggle
                           choices = param$x_choices,
                           selected = param$x_def,
                           width = "100%"
                       )
                   ),
                   div(
                       class = "var_selec_group",
                       selectInput(
                           inputId = "color",
                           label = param$ui3,  # idem
                           choices = param$color_choices,
                           selected = param$color_def,
                           width = "100%"
                       )
                   ),
                   
                   div(class = "fakecheckbox", ),
                   
                   # NOVO: botão de lang toggle, ACIMA do fullscreen
                   div(
                       actionButton(
                           inputId = "toggle_lang",
                           label   = "English",
                           icon    = icon("globe"),
                           class   = "btn-primary"
                       )
                   ),
                   div(style = "height: 6px;"),  # espaço entre os botões
                   
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
                   div(
                       class = "plotrow row justify-content-center flex-grow-1 w-100",
                       # NOVO: div externo precisa de display:flex; flex-direction:column para o spinner funcionar
                       div(
                           class = "plotdiv w-100 h-100",
                           style = "position: relative; display: flex; flex-direction: column;",
                           div(
                               style = "flex-grow: 1; position: relative;",
                               # NOVO: plot envolvido em withSpinner, height em vh em vez de "100%"
                               withSpinner(
                                   plotlyOutput("plot", width = "100%", height = "calc(100vh - 150px)"),
                                   type  = 4,
                                   color = "#41878C"
                               )
                           )
                       )
                   )
            )
        ),
    )
}