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
            df <- readRDS(files$db_file) %>%
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
        
        dados <- reactive({df})

        
        # Atualiza seletores
        
        default_geo <- unname(unlist(param$geo_choices[[1]]))[1]
        default_group <- unname(unlist(param$group_categories[1]))[1]
        
        observe({
            df <- dados()
            
            # Atualiza filtro geográfico
        
            
            updateSelectizeInput(
                session, 
                "filter_geo",
                choices = param$geo_choices,
                selected = default_geo
            )
            
            # Atualiza filtro de agrupamento
            updateSelectizeInput(
                session, 
                "filter_group",
                choices = param$group_categories,
                selected = default_group,
                options = list(placeholder = param$label_group)
            )
        })
        
        
        # Gera título dinâmico
        output$plot_title <- renderText({
            req(input$y)  
            
            y_label <- param$table$label[param$table$var == input$y]
            paste(param$title_init, y_label)
        })
        
        # Gera subtítulo
        output$plot_subtitle <- renderText({
            
            req(input$filter_group)
            
            first_choice <- names(param$group_categories)[1]
            if (input$filter_group != first_choice) {
                paste(param$subtitle_init, "-", input$filter_group)
            }
        })
        
        
        # Gera o gráfico principal
        output$plot <- renderPlotly({
            req(input$y, input$filter_geo, input$filter_group)
            df <- dados()
            
            # Aplica filtros geográficos
            if(!(param$geo_choices[[1]][[1]] %in% input$filter_geo)) {
                df <- df %>%
                    filter(uf %in% input$filter_geo |
                               regiao %in% input$filter_geo |
                               amazonia_legal %in% input$filter_geo) %>%
                    mutate(geo_group = case_when(
                        uf %in% input$filter_geo ~ uf,
                        regiao %in% input$filter_geo ~ regiao,
                        amazonia_legal %in% input$filter_geo ~ amazonia_legal
                    ))
            } else {
                df <- df %>% mutate(geo_group = "Brasil")
            }
            
            # Aplica filtros de grupo
            if(input$filter_group != default_group) {
                df <- df %>% filter(group == input$filter_group)
            }
            
            # Determina variáveis de agrupamento
            group_vars <- c("year")
            
            if(!(default_geo %in% input$filter_geo)) {
                group_vars <- c(group_vars, "geo_group")
            }
            
            if(input$filter_group != default_group) {
                group_vars <- c(group_vars, "group")
            }
            
            # Agregação dinâmica
            df_agg <- df %>%
                group_by(across(all_of(group_vars))) %>%
                summarize(
                    y_value = case_when(
                        input$y == "real_avg_w" ~ sum(real_avg_w * num_vinculos, na.rm = TRUE)/sum(num_vinculos, na.rm = TRUE),
                        input$y == "num_vinculos" ~ sum(num_vinculos, na.rm = TRUE),
                        input$y == "tenure" ~ sum(tenure * num_vinculos, na.rm = TRUE)/sum(num_vinculos, na.rm = TRUE)
                    ),
                    .groups = "drop"
                ) %>%
                filter(if (input$y == "real_avg_w") between(year, 1995, 2021) else TRUE)
            
            # Filtra linhas com valores zero ou NA
            df_agg <- df_agg %>%
                filter(
                    !is.na(y_value),          # Remove valores NA
                    y_value != 0,             # Remove valores zero
                    !is.infinite(y_value)     # Remove infinitos se houver
                )
            
            # Verifica se ainda há dados após o filtro
            
            if(!(default_geo %in% input$filter_geo)) {
                df_agg$combinacao <- df_agg$geo_group
            } else {
                df_agg$combinacao <- default_geo
            }
            
            # Mantém o grupo completo para o tooltip
            df_agg$combinacao_completa <- if(input$filter_group != default_group && "group" %in% names(df_agg)) {
                paste(df_agg$combinacao, "-", df_agg$group)
            } else {
                df_agg$combinacao
            }
            
            
            # Verifica se há dados
            if(nrow(df_agg) == 0) {
                return(plotly_empty() %>% 
                           layout(title = list(text = param$no_data_msg)))
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
                "<b>", df_agg$combinacao_completa, "</b><br>",
                param$axis_x_title, ": ", df_agg$year, "<br>",
                param$table$label[param$table$var == input$y], ": ",
                format(round(df_agg$y_value, 2),
                       scientific = FALSE,
                       decimal.mark = ifelse(grepl("en", files$param_file), ".", ","),
                       big.mark = ifelse(grepl("en", files$param_file), ",", "."))
            )
            
            # Layout hover/tooltip
            tooltip <- list(
                bordercolor = "rgba(255, 255, 255, 1)",
                bgopacity = "0.5",
                font = f1
            )
            
            
            # Título eixo y
            y_label <- param$table$label[param$table$var == input$y]
            if (input$y_option) {
                y_title <- paste0(y_label, " (% of base year)")
                if (!grepl("en", files$param_file)) y_title <- paste0(y_label, " (% do ano base)")
            } else {
                y_title <- y_label
            }
            
            
            # Layout eixos
                x_axis_layout <- list(
                    title = param$axis_x_title,
                    titlefont = f1, 
                    tickfont = f2, 
                    showgrid = FALSE,
                    zeroline = FALSE
                )
                
                y_axis_layout <- list(
                    title = y_title,
                    titlefont = f1, 
                    tickfont = f2,   
                    type = if(input$ylog) "log" else "linear",
                    showgrid = FALSE,
                    zeroline = FALSE
                )
            
            # Cria o gráfico
            p <- plot_ly(df_agg,
                         x = ~year,
                         y = ~y_value,
                         color = ~combinacao,
                         type = 'scatter',
                         mode = 'lines',
                         text = ~tooltip,
                         hoverinfo = 'text',
                         hoverlabel = tooltip
                ) %>%
                layout(
                    font = f1,
                    xaxis = x_axis_layout,
                    yaxis = y_axis_layout,
                    margin = list(l = 50, r = 50, b = 100, t = 50, pad = 4),
                    hovermode = "closest",
                    showlegend = TRUE
                )
            
            p %>% config(
                displayModeBar = TRUE,
                modeBarButtonsToRemove = c("select2d", "lasso2d", "autoScale2d"),
                locale = ifelse(grepl("en", files$param_file), "en-US", "pt-BR")
            )
        })
    }
}