# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84","#ffcf48" ,"#c3ff83","#007e47","#00596d","#4fdf94","#99b0c8","#261c4e","#000098","#c368b1","#60458c","#757575")
pallete_continuous <- c("#440154","#481567" ,"#453781","#404788","#39568c","#33638d","#287d8e","#238a8d","#1f968b","#20a387","#29af7f","#3cbb75","#55c667","#73d055","#95d840","#b8de29","#dce319","#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

get_server <- function(files, param) {
    function(input, output, session) {
        
        # Carrega dados
        df <- readRDS(files$db_file) %>%
            filter(year >= 1995)
        
        # Atualiza seletores com valores únicos dos dados
        observe({
            # Atualiza filtro de UF
            updateSelectizeInput(
                session, 
                "filter_uf",
                choices = c("Todos", sort(unique(df$uf))),
                selected = "Todos"
            )
            
            # Atualiza filtro de setor
            updateSelectizeInput(
                session, 
                "filter_setor",
                choices = c("Todos os setores", sort(unique(df$setor))),
                selected = "Todos os setores"
            )
        })
        
        # Gera título dinâmico
        output$plot_title <- renderText({
            if(is.null(input$y)) return("Selecione uma variável")
            
            y_label <- switch(input$y,
                              "real_avg_w" = "Salário Médio",
                              "num_vinculos" = "Número de Vínculos",
                              "tenure" = "Tempo no Emprego")
            
            paste("Evolução do", y_label, "na RAIS")
        })
        
        output$plot_subtitle <- renderText({
            if(is.null(input$x)) return("")
            
            x_label <- switch(input$x,
                              "year" = "por Ano",
                              "uf" = "por Estado",
                              "setor" = "por Setor Econômico",
                              "ocupacao" = "por Ocupação",
                              "sexo" = "por Sexo")
            
            x_label
        })
        
        # Gera o gráfico principal
        output$plot <- renderPlotly({
            # Requer seleção de variáveis
            req(input$x, input$y)
            
            # Filtra os dados
            df_filtrado <- df
            
            # Aplica filtros
            if(!is.null(input$filter_uf) && !"Todos" %in% input$filter_uf) {
                df_filtrado <- df_filtrado %>% filter(uf %in% input$filter_uf)
            }
            
            if(!is.null(input$filter_setor) && !"Todos os setores" %in% input$filter_setor) {
                df_filtrado <- df_filtrado %>% filter(setor %in% input$filter_setor)
            }
            
            # Verifica se há dados após filtragem
            if(nrow(df_filtrado) == 0) {
                return(plotly_empty() %>% 
                           layout(title = list(text = "Nenhum dado encontrado com os filtros selecionados")))
            }
            
            # Agrega os dados conforme necessário
            df_agg <- df_filtrado %>%
                group_by(across(all_of(c(input$x, input$color)))) %>%
                summarize(
                    y_value = case_when(
                        input$y == "real_avg_w" ~ mean(real_avg_w, na.rm = TRUE),
                        input$y == "num_vinculos" ~ sum(num_vinculos, na.rm = TRUE),
                        input$y == "tenure" ~ mean(tenure, na.rm = TRUE)
                    ),
                    .groups = "drop"
                )
            
            # Prepara texto para tooltip
            df_agg$tooltip <- paste0(
                "<b>", if(!is.null(input$color)) df_agg[[input$color]] else "Todos", "</b><br>",
                switch(input$x,
                       "year" = "Ano",
                       "uf" = "UF",
                       "setor" = "Setor",
                       "ocupacao" = "Ocupação",
                       "sexo" = "Sexo"), ": ", df_agg[[input$x]], "<br>",
                switch(input$y,
                       "real_avg_w" = "Salário Médio",
                       "num_vinculos" = "Nº de Vínculos",
                       "tenure" = "Tempo Médio"), ": ", round(df_agg$y_value, 2)
            )
            
            # Cria o gráfico
            p <- plot_ly(df_agg,
                         x = ~get(input$x),
                         y = ~y_value,
                         color = if(!is.null(input$color) && input$color != "none") ~get(input$color) else NULL,
                         type = 'scatter',
                         mode = 'lines+markers',
                         text = ~tooltip,
                         hoverinfo = 'text',
                         line = list(width = 2),
                         marker = list(size = 8))
            
            # Configurações do layout
            p <- p %>% layout(
                xaxis = list(
                    title = switch(input$x,
                                   "year" = "Ano",
                                   "uf" = "Unidade Federativa",
                                   "setor" = "Setor Econômico",
                                   "ocupacao" = "Ocupação",
                                   "sexo" = "Sexo"),
                    tickangle = if(input$x == "setor") 45 else 0
                ),
                yaxis = list(
                    title = switch(input$y,
                                   "real_avg_w" = "Salário Médio (R$)",
                                   "num_vinculos" = "Número de Vínculos",
                                   "tenure" = "Tempo no Emprego (meses)"),
                    type = if("logscale" %in% input$options) "log" else "linear"
                ),
                legend = list(title = list(text = if(!is.null(input$color)) 
                    switch(input$color,
                           "uf" = "UF",
                           "setor" = "Setor",
                           "sexo" = "Sexo",
                           "faixa_etaria" = "Faixa Etária") else NULL)),
                hovermode = "closest",
                margin = list(b = if(input$x == "setor") 100 else 50)
            )
            
            # Adiciona valores se solicitado
            if("showvalues" %in% input$options) {
                p <- p %>% add_annotations(
                    text = ~round(y_value, 2),
                    showarrow = FALSE,
                    yanchor = 'bottom'
                )
            }
            
            # Configurações adicionais
            p %>% config(
                displayModeBar = TRUE,
                modeBarButtonsToRemove = c("select2d", "lasso2d", "autoScale2d"),
                locale = 'pt-BR'
            )
        })
        
        # Observador para atualizar a cor quando o eixo X muda
        observe({
            x_var <- input$x
            
            # Evita que a cor seja a mesma variável do eixo X
            if(!is.null(x_var)) {
                current_color <- input$color
                choices <- list(
                    "Nenhum" = "none",
                    "UF" = "uf",
                    "Setor Econômico" = "setor",
                    "Sexo" = "sexo",
                    "Faixa Etária" = "faixa_etaria"
                )
                
                # Remove a variável atual do eixo X das opções de cor
                if(x_var %in% unlist(choices)) {
                    choices <- choices[!choices %in% x_var]
                }
                
                updateSelectInput(
                    session, 
                    "color",
                    choices = choices,
                    selected = if(current_color == x_var) "none" else current_color
                )
            }
        })
    }
}