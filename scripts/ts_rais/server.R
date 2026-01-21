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
        
        default_geo   <- unname(unlist(param$geo_choices[[1]]))[1]          # "Brasil"
        default_group <- unname(unlist(param$group_categories[[1]]))[1]     # "Todos"
        
        # Reativo de língua
        lang <- reactiveVal("pt")
        
        observeEvent(input$toggle_lang, {
            lang(ifelse(lang() == "pt", "en", "pt"))
        })
        
        # Helper para pegar textos e a tabela correta
        txt <- reactive({
            param$i18n[[lang()]]
        })
        
        param_tbl <- reactive({
            param$tables[[lang()]]
        })
        
        # Renderizar os textos do topo do menu
        output$plot_name_ui <- renderUI({
            h2(class = "plot_name", txt()$plot_name)
        })
        
        output$plot_desc_ui <- renderUI({
            p(class = "plot_desc", txt()$plot_desc)
        })
        
        output$label_var_ui <- renderUI({
            p(class = "vars", txt()$label_var_name)
        })
        
        # Atualizar labels dos inputs + choices do Y quando mudar idioma
        observeEvent(lang(), {
            # Atualiza labels
            updateSelectInput(session, "y", label = txt()$label_y_name)
            updateCheckboxInput(session, "ylog", label = txt()$label_scale_name)
            updateCheckboxInput(session, "y_option", label = txt()$label_prop_name)
            
            # Mantém seleção atual (valores continuam PT)
            sel_geo <- isolate(input$filter_geo)
            sel_group <- isolate(input$filter_group)
            
            if (is.null(sel_geo) || length(sel_geo) == 0) sel_geo <- default_geo
            if (is.null(sel_group) || !nzchar(sel_group)) sel_group <- default_group
            
            updateSelectizeInput(session, "filter_geo", label = txt()$label_geo,
                                 choices = geo_choices_i18n(),
                                 selected = sel_geo,
                                 options = list(placeholder = txt()$label_geo, maxItems = 20))

            updateSelectizeInput(session, "filter_group", label = txt()$label_group,
                                 choices = group_choices_i18n(),
                                 selected = sel_group,
                                 options = list(placeholder = txt()$label_group))

            # Botões
            updateActionButton(session, "toggle_lang", label = txt()$btn_lang)
            updateActionButton(session, "ab1", label = txt()$btn_fullscreen)
            
            # Atualiza choices do Y com a tabela traduzida
            tbl <- param_tbl()
            updateSelectInput(
                session,
                "y",
                choices = setNames(tbl$var[tbl$y], tbl$label[tbl$y]),
                selected = if (!is.null(isolate(input$y))) isolate(input$y) else param$y_def
            )
        }, ignoreInit = FALSE)
        
        # Função para geo choices traduzidas
        geo_choices_i18n <- function() {
            base <- param$geo_choices
            if (lang() == "pt") return(base)
            
            list(
                "Brazil" = c("Brazil" = "Brasil"),
                "Legal Amazon" = c(
                    "Legal Amazon" = "Amazônia Legal",
                    "Outside Legal Amazon" = "Fora da Amazônia Legal"
                ),
                "Regions" = c(
                    "North" = "Norte",
                    "Northeast" = "Nordeste",
                    "Southeast" = "Sudeste",
                    "South" = "Sul",
                    "Central-West" = "Centro-Oeste"
                ),
                "States" = base[["Estados"]]  # pode ficar como está
            )
        }
        
        # Função para grupos traduzidos
        group_choices_i18n <- function() {
            base <- param$group_categories
            if (lang() == "pt") return(base)
            
            list(
                "All" = "Todos",
                "Education" = setNames(
                    c("Sem fundamental completo", "Médio completo", "Superior completo"),
                    c("Less than primary", "High school", "College degree")
                ),
                "Gender" = setNames(
                    c("Feminino", "Masculino"),
                    c("Female", "Male")
                ),
                "Age Group" = c(
                    "Under 18 years old" = "Menor de 18 anos",
                    "Between 18 and 24 years old" = "Entre 18 e 24 anos",
                    "Between 25 and 29 years old" = "Entre 25 e 29 anos",
                    "Between 30 and 39 years old" = "Entre 30 e 39 anos",
                    "Between 40 and 49 years old" = "Entre 40 e 49 anos",
                    "Between 50 and 59 years old" = "Entre 50 e 59 anos",
                    "Between 60 years and over" = "60 anos ou mais"
                ),
                "Race/color" = setNames(
                    c("Branca", "Preta", "Parda", "Amarela", "Indígena"),
                    c("White", "Black", "Brown", "Yellow", "Indigenous")
                ),
                "Occupation" = c(
                    "Administrative support workers" =
                        "Trabalhadores de serviços administrativos",
                    "Agricultural, forestry, and fishery workers" =
                        "Trabalhadores agropecuários, florestais e da pesca",
                    "Members of the armed forces, police, and military firefighters" =
                        "Membros das forças armadas, Policiais e bombeiros militares",
                    "Production workers in industry and related services" =
                        "Trabalhadores da produção de bens e serviços industriais",
                    "Professionals in science and the arts" =
                        "Profissionais das ciências e das artes",
                    "Repair and maintenance workers" =
                        "Trabalhadores em serviços de reparação e manutenção",
                    "Senior public officials, executives, and managers" =
                        "Membros superiores do poder público, Dirigentes de organizações de interesse público e de empresas, Gerentes",
                    "Service and sales workers in shops and markets" =
                        "Trabalhadores dos serviços, vendedores do comércio em lojas e mercados",
                    "Technicians and associate professionals" =
                        "Técnicos de nível médio"
                ),
                
                "Economic Sector" = c(
                    "Accommodation and food services" = "Alojamento e Alimentação",
                    "Administrative and support service activities" =
                        "Atividades administrativas e serviços complementares",
                    "Agriculture, livestock, forestry, fishing, and aquaculture" =
                        "Agricultura, Pecuária, Produção Florestal, Pesca e Aquicultura",
                    "Arts, culture, sports, and recreation" =
                        "Artes, Cultura, Esporte e Recreação",
                    "Construction" = "Construção",
                    "Domestic services" = "Serviços domésticos",
                    "Education" = "Educação",
                    "Electricity and gas supply" = "Eletricidade e Gás",
                    "Financial and insurance activities" =
                        "Atividades financeiras, de seguros e serviços relacionados",
                    "Human health and social work activities" =
                        "Saúde humana e Serviços sociais",
                    "Information and communication" = "Informação e Comunicação",
                    "International organizations and other extraterritorial institutions" =
                        "Organismos internacionais e outras instituições extraterritoriais",
                    "Manufacturing" = "Indústrias de transformação",
                    "Mining and quarrying" = "Indústrias extrativas",
                    "Other service activities" = "Outras atividades de serviços",
                    "Professional, scientific, and technical activities" =
                        "Atividades Profissionais, Científicas e Técnicas",
                    "Public administration, defense, and social security" =
                        "Administração pública, Defesa e Seguridade social",
                    "Real estate activities" = "Atividades imobiliárias",
                    "Transportation, storage, and postal services" =
                        "Transporte, Armazenagem e Correio",
                    "Water supply, sewage, waste management, and remediation" =
                        "Água, Esgoto, Atividades de Gestão de resíduos e Descontaminação",
                    "Wholesale and retail trade; repair of motor vehicles and motorcycles" =
                        "Comércio; Reparação de veículos automotores e motocicletas"
                )
            )
        }
        
        # “mapa achatado” PT → EN
        group_map_pt_to_en <- reactive({
            if (lang() != "en") return(NULL)
            
            ch <- group_choices_i18n()  # lista hierárquica
            
            # pega apenas os itens "folha" (cada um é named vector ou lista nomeada)
            leaves <- c(
                ch[["Education"]],
                ch[["Gender"]],
                unlist(ch[["Age Group"]]),
                ch[["Race/color"]],
                unlist(ch[["Occupation"]]),
                unlist(ch[["Economic Sector"]])
            )
            
            # leaves: names = EN, values = PT
            # inverte: names = PT, values = EN
            setNames(names(leaves), unname(leaves))
        })
        
        geo_map_pt_to_en <- reactive({
            if (lang() != "en") return(NULL)
            
            ch <- geo_choices_i18n()
            
            leaves <- c(
                ch[["Brazil"]],       
                ch[["Legal Amazon"]],  
                ch[["Regions"]]         
                # States fica sem tradução
            )
            
            # inverte: names = PT, values = EN
            setNames(names(leaves), unname(leaves))
        })

        
        
        
        # Gera título dinâmico
        output$plot_title <- renderText({
            req(input$y)  
            
            tbl <- param_tbl()
            y_label <- tbl$label[tbl$var == input$y]
            paste(txt()$title_init, y_label)
        })
        
        # Gera subtítulo
        output$plot_subtitle <- renderText({
            
            req(input$filter_group)
            
            if (input$filter_group != default_group) {
                if (lang() == "en") {
                    m <- group_map_pt_to_en()
                    grp_en <- unname(m[input$filter_group])
                    if (is.na(grp_en)) grp_en <- input$filter_group
                    paste(txt()$subtitle_init, "-", grp_en)
                } else {
                    paste(txt()$subtitle_init, "-", input$filter_group)
                }
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
                if (lang() == "en") {
                    m <- geo_map_pt_to_en()
                    geo_en <- unname(m[df_agg$combinacao])
                    df_agg$combinacao <- ifelse(is.na(geo_en), df_agg$combinacao, geo_en)
                }
                
            } else {
                df_agg$combinacao <- if (lang() == "en") "Brazil" else "Brasil"
            }
            
            # Mantém o grupo completo para o tooltip
            df_agg$combinacao_completa <- if(input$filter_group != default_group && "group" %in% names(df_agg)) {
                grp_disp <- df_agg$group
                
                if (lang() == "en") {
                    m <- group_map_pt_to_en()
                    grp_en <- unname(m[grp_disp])
                    grp_disp <- ifelse(is.na(grp_en), grp_disp, grp_en)
                }
                
                paste(df_agg$combinacao, "-", grp_disp)
                
            } else {
                df_agg$combinacao
            }
            
            
            # Verifica se há dados
            if(nrow(df_agg) == 0) {
                return(plotly_empty() %>% 
                           layout(title = list(text = txt()$no_data_msg)))
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
            tbl <- param_tbl()
            
            df_agg$tooltip <- paste0(
                "<b>", df_agg$combinacao_completa, "</b><br>",
                txt()$axis_x_title, ": ", df_agg$year, "<br>",
                tbl$label[tbl$var == input$y], ": ",
                format(
                    round(df_agg$y_value, 2),
                    scientific = FALSE,
                    decimal.mark = txt()$dec_mark,
                    big.mark = txt()$big_mark
                )
            )
            
            # Layout hover/tooltip
            tooltip <- list(
                bordercolor = "rgba(255, 255, 255, 1)",
                bgopacity = "0.5",
                font = f1
            )
            
            
            # Título eixo y
            tbl <- param_tbl()
            y_label <- tbl$label[tbl$var == input$y]
            
            y_title <- if (input$y_option) {
                paste0(y_label, " ", txt()$y_rel_suffix)
            } else {
                y_label
            }
            
            
            # Layout eixos
                x_axis_layout <- list(
                    title = txt()$axis_x_title,
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
                locale = txt()$locale
            )
        })
    }
}