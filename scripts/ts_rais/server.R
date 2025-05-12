# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84","#ffcf48" ,"#c3ff83","#007e47","#00596d","#4fdf94","#99b0c8","#261c4e","#000098","#c368b1","#60458c","#757575")
pallete_continuous <- c("#440154","#481567" ,"#453781","#404788","#39568c","#33638d","#287d8e","#238a8d","#1f968b","#20a387","#29af7f","#3cbb75","#55c667","#73d055","#95d840","#b8de29","#dce319","#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

get_server <- function(files, param) {
    function(input, output, session) {
        
        # Carrega dados como reativo
        dados <- reactive({
            df <- readRDS(files$db_file) %>%
                filter(year >= 2003) %>%
                mutate(
                    regiao = case_when(
                        uf %in% c("Acre", "Amapá", "Amazonas", "Pará", "Rondônia", "Roraima", "Tocantins") ~ "Norte",
                        uf %in% c("Alagoas", "Bahia", "Ceará", "Maranhão", "Paraíba", "Pernambuco", "Piauí", 
                                  "Rio Grande do Norte", "Sergipe") ~ "Nordeste",
                        uf %in% c("Espírito Santo", "Minas Gerais", "Rio de Janeiro", "São Paulo") ~ "Sudeste",
                        uf %in% c("Paraná", "Rio Grande do Sul", "Santa Catarina") ~ "Sul",
                        uf %in% c("Distrito Federal", "Goiás", "Mato Grosso", "Mato Grosso do Sul") ~ "Centro-Oeste",
                        TRUE ~ "Outros"
                    ),
                    amazonia_legal = ifelse(
                        uf %in% c("Acre", "Amapá", "Amazonas", "Maranhão", "Mato Grosso", 
                                  "Pará", "Rondônia", "Roraima", "Tocantins"),
                        "Amazônia Legal", 
                        "Fora da Amazônia Legal"
                    )
                )
            
            return(df)
        })
        
        # Atualiza seletores
        observe({
            df <- dados()
            
            # Atualiza filtro geográfico
            updateSelectizeInput(
                session, 
                "filter_geo",
                choices = list(
                    "Brasil" = "Brasil",
                    "Amazônia Legal" = c("Amazônia Legal", "Fora da Amazônia Legal"),
                    "Regiões" = c("Norte", "Nordeste", "Sudeste", "Sul", "Centro-Oeste"),
                    "Estados" = sort(unique(df$uf))
                ),
                selected = "Brasil"
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
            req(input$y)  
            
            y_label <- switch(input$y,
                              "real_avg_w" = "Salário Médio",
                              "num_vinculos" = "Número de Vínculos",
                              "tenure" = "Tempo no Emprego")
            
            paste("Evolução do", y_label)
        })
        
       
        
        # Gera o gráfico principal
        output$plot <- renderPlotly({
            req(input$y, input$filter_geo, input$filter_setor)
            df <- dados()
            
            # Aplica filtros geográficos
            if(!"Brasil" %in% input$filter_geo) {
                df <- df %>% 
                    filter(uf %in% input$filter_geo | 
                               regiao %in% input$filter_geo | 
                               amazonia_legal %in% input$filter_geo)
                
                # Define o nome do grupo geográfico
                df <- df %>%
                    mutate(geo_group = case_when(
                        uf %in% input$filter_geo ~ uf,
                        regiao %in% input$filter_geo ~ regiao,
                        amazonia_legal %in% input$filter_geo ~ amazonia_legal
                    ))
            } else {
                df <- df %>% mutate(geo_group = "Brasil")
            }
            
            # Aplica filtros de setor
            if(!"Todos os setores" %in% input$filter_setor) {
                df <- df %>% 
                    filter(setor %in% input$filter_setor)
            }
            
            # Agrupa os dados conforme os filtros selecionados
            if("Brasil" %in% input$filter_geo && "Todos os setores" %in% input$filter_setor) {
                # Caso 1: Brasil e todos os setores - agregar tudo
                df_agg <- df %>%
                    group_by(year) %>%
                    summarize(
                        y_value = case_when(
                            input$y == "real_avg_w" ~ mean(real_avg_w, na.rm = TRUE),
                            input$y == "num_vinculos" ~ sum(num_vinculos, na.rm = TRUE),
                            input$y == "tenure" ~ mean(tenure, na.rm = TRUE)
                        ),
                        .groups = "drop"
                    ) %>%
                    mutate(combinacao = "Todos os Setores")
                
            } else if ("Brasil" %in% input$filter_geo) {
                # Caso 2: Brasil com setores específicos - agrupar por setor
                df_agg <- df %>%
                    group_by(year, setor) %>%
                    summarize(
                        y_value = case_when(
                            input$y == "real_avg_w" ~ mean(real_avg_w, na.rm = TRUE),
                            input$y == "num_vinculos" ~ sum(num_vinculos, na.rm = TRUE),
                            input$y == "tenure" ~ mean(tenure, na.rm = TRUE)
                        ),
                        .groups = "drop"
                    ) %>%
                    mutate(combinacao = as.character(setor))
                
            } else if ("Todos os setores" %in% input$filter_setor) {
                # Caso 3: Regiões/Estados com todos os setores - agrupar por grupo geográfico
                df_agg <- df %>%
                    group_by(year, geo_group) %>%
                    summarize(
                        y_value = case_when(
                            input$y == "real_avg_w" ~ mean(real_avg_w, na.rm = TRUE),
                            input$y == "num_vinculos" ~ sum(num_vinculos, na.rm = TRUE),
                            input$y == "tenure" ~ mean(tenure, na.rm = TRUE)
                        ),
                        .groups = "drop"
                    ) %>%
                    mutate(combinacao = geo_group)
                
            } else {
                # Caso 4: Regiões/Estados com setores específicos - agrupar por combinação
                df_agg <- df %>%
                    group_by(year, geo_group, setor) %>%
                    summarize(
                        y_value = case_when(
                            input$y == "real_avg_w" ~ mean(real_avg_w, na.rm = TRUE),
                            input$y == "num_vinculos" ~ sum(num_vinculos, na.rm = TRUE),
                            input$y == "tenure" ~ mean(tenure, na.rm = TRUE)
                        ),
                        .groups = "drop"
                    ) %>%
                    mutate(combinacao = paste(setor, "-", geo_group))
            }
            
            # Verifica se há dados
            if(nrow(df_agg) == 0) {
                return(plotly_empty() %>% 
                           layout(title = list(text = "Nenhum dado encontrado com os filtros selecionados")))
            }
            
            # Calcula evolução relativa se necessário
            if(input$y_option) {
                df_agg <- df_agg %>%
                    group_by(combinacao) %>%
                    mutate(
                        y_value = 100 * y_value / first(na.omit(y_value))
                    ) %>%
                    ungroup()
            }
            
            # Prepara tooltip
            df_agg$tooltip <- paste0(
                "<b>", df_agg$combinacao, "</b><br>",
                "Ano: ", df_agg$year, "<br>",
                switch(input$y,
                       "real_avg_w" = if(input$y_option) "Salário Médio (% do ano base)" else "Salário Médio (R$)",
                       "num_vinculos" = if(input$y_option) "Vínculos (% do ano base)" else "Nº de Vínculos",
                       "tenure" = if(input$y_option) "Tempo (% do ano base)" else "Tempo (meses)"), 
                ": ", round(df_agg$y_value, if(input$y_option) 1 else 2)
            )
            
            # Cria o gráfico
            p <- plot_ly(df_agg,
                         x = ~year,
                         y = ~y_value,
                         color = ~combinacao,
                         colors = pallete_discrete,
                         type = 'scatter',
                         mode = 'lines+markers',
                         text = ~tooltip,
                         hoverinfo = 'text',
                         line = list(width = 2),
                         marker = list(size = 8)) %>%
                layout(
                    xaxis = list(title = "Ano"),
                    yaxis = list(
                        title = switch(input$y,
                                       "real_avg_w" = if(input$y_option) "Salário Médio (% do ano base)" else "Salário Médio (R$)",
                                       "num_vinculos" = if(input$y_option) "Vínculos (% do ano base)" else "Número de Vínculos",
                                       "tenure" = if(input$y_option) "Tempo (% do ano base)" else "Tempo no Emprego (meses)"),
                        type = if(input$ylog) "log" else "linear"
                    ),
                    hovermode = "closest",
                    showlegend = TRUE
                )
            
            p %>% config(
                displayModeBar = TRUE,
                modeBarButtonsToRemove = c("select2d", "lasso2d", "autoScale2d"),
                locale = 'pt-BR'
            )
        })
    }
}