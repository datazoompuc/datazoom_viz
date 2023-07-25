# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# Funcão para retornar objeto server
get_server <- function(files, param) {
  
  # Carrega dados
  df <- readRDS(files$db_file) %>% 
    ungroup
  
  if(param$lang) {

    df <- df %>%
      mutate(dsc_fonte_geracao = case_when(
        dsc_fonte_geracao == "Bagaço de Cana de Açúcar"         ~ "Sugarcane Bagasse",
        dsc_fonte_geracao == "Biogás-AGR"                       ~ "Biogas-AGR",
        dsc_fonte_geracao == "Biogás - Floresta"                ~ "Biogas - Forest",
        dsc_fonte_geracao == "Biogás - RA"                      ~ "Biogas - RA",
        dsc_fonte_geracao == "Biogás - RU"                      ~ "Biogas - RU",
        dsc_fonte_geracao == "Casca de Arroz"                   ~ "Rice Husk",
        dsc_fonte_geracao == "Cinética do vento"                ~ "Wind Kinetics",
        dsc_fonte_geracao == "Gás de Alto Forno - Biomassa"     ~ "Blast Furnace Gas - Biomass",
        dsc_fonte_geracao == "Gás Natural"                      ~ "Natural Gas",
        dsc_fonte_geracao == "Potencial hidráulico"             ~ "Hydropower",
        dsc_fonte_geracao == "Radiação solar"                   ~ "Solar Radiation",
        dsc_fonte_geracao == "Resíduos Florestais"              ~ "Forest Waste",
        dsc_fonte_geracao == "Resíduos Sólidos Urbanos - RU"    ~ "Urban Solid Waste - RU"),

        sig_modalidade_empreendimento = case_when(
        sig_modalidade_empreendimento == "Indefinido"                                ~ "Undefined",
        sig_modalidade_empreendimento == "Geração compartilhada"                    ~ "Shared Generation",
        sig_modalidade_empreendimento == "Múltiplas unidades consumidoras"           ~ "Multiple Consumer Units",
        sig_modalidade_empreendimento == "Microgeração ou Minigeração distribuída"   ~ "Microgeneration or Distributed Minigeneration",
        sig_modalidade_empreendimento == "Autoconsumo remoto"                        ~ "Remote Self-consumption"),

        dsc_porte = case_when(
        dsc_porte == "Microgeração"    ~ "Microgeneration",
        dsc_porte == "Minigeração"     ~ "Minigeneration"
      ),
      id = case_when(
        id == "Amazônia Legal"            ~ "Legal Amazon",
        id == "Fora da Amazônia Legal"    ~ "Outside Legal Amazon",
        id == "R. Centro-Oeste: DF"       ~ "Central-West Region: DF",
        id == "R. Centro-Oeste: GO"       ~ "Central-West Region: GO",
        id == "R. Centro-Oeste: MS"       ~ "Central-West Region: MS",
        id == "R. Centro-Oeste: MT"       ~ "Central-West Region: MT",
        id == "R. Nordeste: AL"          ~ "Northeast Region: AL",
        id == "R. Nordeste: BA"          ~ "Northeast Region: BA",
        id == "R. Nordeste: CE"          ~ "Northeast Region: CE",
        id == "R. Nordeste: MA"          ~ "Northeast Region: MA",
        id == "R. Nordeste: PB"          ~ "Northeast Region: PB",
        id == "R. Nordeste: PE"          ~ "Northeast Region: PE",
        id == "R. Nordeste: RN"          ~ "Northeast Region: RN",
        id == "R. Nordeste: SE"          ~ "Northeast Region: SE",
        id == "R. Norte: AC"             ~ "North Region: AC",
        id == "R. Norte: AM"             ~ "North Region: AM",
        id == "R. Norte: AP"             ~ "North Region: AP",
        id == "R. Norte: PA"             ~ "North Region: PA",
        id == "R. Norte: RO"             ~ "North Region: RO",
        id == "R. Norte: RR"             ~ "North Region: RR",
        id == "R. Norte: TO"             ~ "North Region: TO",
        id == "R. Sudeste: ES"           ~ "Southeast Region: ES",
        id == "R. Sudeste: MG"           ~ "Southeast Region: MG",
        id == "R. Sudeste: RJ"           ~ "Southeast Region: RJ",
        id == "R. Sudeste: SP"           ~ "Southeast Region: SP",
        id == "R. Sul: PR"               ~ "South Region: PR",
        id == "R. Sul: RS"               ~ "South Region: RS",
        id == "R. Sul: SC"               ~ "South Region: SC",
        TRUE                            ~ id  # Else condition (keep the original value)
      ),
      group = case_when(
        group == "Amazônia Legal"            ~ "Legal Amazon",
        group == "Fora da Amazônia Legal"    ~ "Outside Legal Amazon",
        group == "R. Centro-Oeste: DF"       ~ "Central-West Region: DF",
        group == "R. Centro-Oeste: GO"       ~ "Central-West Region: GO",
        group == "R. Centro-Oeste: MS"       ~ "Central-West Region: MS",
        group == "R. Centro-Oeste: MT"       ~ "Central-West Region: MT",
        group == "R. Nordeste: AL"          ~ "Northeast Region: AL",
        group == "R. Nordeste: BA"          ~ "Northeast Region: BA",
        group == "R. Nordeste: CE"          ~ "Northeast Region: CE",
        group == "R. Nordeste: MA"          ~ "Northeast Region: MA",
        group == "R. Nordeste: PB"          ~ "Northeast Region: PB",
        group == "R. Nordeste: PE"          ~ "Northeast Region: PE",
        group == "R. Nordeste: RN"          ~ "Northeast Region: RN",
        group == "R. Nordeste: SE"          ~ "Northeast Region: SE",
        group == "R. Norte: AC"             ~ "North Region: AC",
        group == "R. Norte: AM"             ~ "North Region: AM",
        group == "R. Norte: AP"             ~ "North Region: AP",
        group == "R. Norte: PA"             ~ "North Region: PA",
        group == "R. Norte: RO"             ~ "North Region: RO",
        group == "R. Norte: RR"             ~ "North Region: RR",
        group == "R. Norte: TO"             ~ "North Region: TO",
        group == "R. Sudeste: ES"           ~ "Southeast Region: ES",
        group == "R. Sudeste: MG"           ~ "Southeast Region: MG",
        group == "R. Sudeste: RJ"           ~ "Southeast Region: RJ",
        group == "R. Sudeste: SP"           ~ "Southeast Region: SP",
        group == "R. Sul: PR"               ~ "South Region: PR",
        group == "R. Sul: RS"               ~ "South Region: RS",
        group == "R. Sul: SC"               ~ "South Region: SC",
        TRUE                            ~ group  # Else condition (keep the original value)
      ))



  }
  
  
  
  server <- function(input, output, session) {
    
    # filtra dados de composicao demografica
    df_reactived <- reactive({
      
      w <- df %>%
        filter(sig_modalidade_empreendimento == input$filter_sig_modalidade_empreendimento & dsc_fonte_geracao == input$filter_dsc_fonte_geracao & dsc_porte == input$filter_dsc_porte)
      
      return(w)
    })

    # Cria opções para seleção de grupos
    param$filter_choices <- sort(unique(df$id))

    param$filter_sig_modalidade_empreendimento_choices <- sort(unique(df$sig_modalidade_empreendimento))
    param$filter_dsc_fonte_geracao_choices <- sort(unique(df$dsc_fonte_geracao))
    param$filter_dsc_porte_choices <- sort(unique(df$dsc_porte))

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      updateSelectizeInput(session,
        "filter1",
        choices = param$filter_choices,
        selected = sample(param$filter_choices, 1) # 2 significa o numero de parametros aleatórios que são escolhidos na geração do gráfico
      )
      
      selected_sig_modalidade_empreendimento <- sample(param$filter_sig_modalidade_empreendimento_choices, 1)
      updateSelectInput(session,
                        "filter_sig_modalidade_empreendimento",
                        choices = param$filter_sig_modalidade_empreendimento_choices,
                        selected = selected_sig_modalidade_empreendimento
      )
      
      selected_dsc_fonte_geracao <- sample(param$filter_dsc_fonte_geracao_choices, 1)
      updateSelectInput(session,
                        "filter_dsc_fonte_geracao",
                        choices = param$filter_dsc_fonte_geracao_choices,
                        selected = selected_dsc_fonte_geracao
      )
      
      selected_dsc_porte <- sample(param$filter_dsc_porte_choices, 1)
      updateSelectInput(session,
                        "filter_dsc_porte",
                        choices = param$filter_dsc_porte_choices,
                        selected = selected_dsc_porte
      )

      selected <- sample(sample(param$y_choices, 1)[[1]], 1)
      updateSelectInput(session,
        "y",
        choices = param$y_choices,
        selected = selected
      )
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "y=", input$y,
        "&", "filter_sig_modalidade_empreendimento=", input$filter_sig_modalidade_empreendimento,
        "&", "filter_dsc_fonte_geracao=", input$filter_dsc_fonte_geracao,
        "&", "filter_dsc_porte=", input$filter_dsc_porte
      )

      for (i in input$filter1) {
        q_string <- paste0(
          q_string,
          "&", "filter=", i
        )
      }


      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Preenche filtro vazio
      updateSelectizeInput(session,
        "filter1",
        choices = param$filter_choices,
        selected = NULL
      )
      updateSelectInput(session,
        "filter_sig_modalidade_empreendimento",
        choices = param$filter_sig_modalidade_empreendimento_choices,
        selected = NULL
      )
      updateSelectInput(session,
                        "filter_dsc_fonte_geracao",
                        choices = param$filter_dsc_fonte_geracao_choices,
                        selected = NULL
      )
      updateSelectInput(session,
                        "filter_dsc_porte",
                        choices = param$filter_dsc_porte_choices,
                        selected = NULL
      )
      

      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["y"]])) {
        updateSelectInput(session, "y",
          choices = param$y_choices,
          selected = query[["y"]]
        )
      }

      if (!is.null(query[["filter_sig_modalidade_empreendimento"]])) {
        updateSelectInput(session, "filter_sig_modalidade_empreendimento",
          choices = param$filter_sig_modalidade_empreendimento_choices,
          selected = query[["filter_sig_modalidade_empreendimento"]]
        )
      }
      if (!is.null(query[["filter_dsc_fonte_geracao"]])) {
        updateSelectInput(session, "filter_dsc_fonte_geracao",
                          choices = param$filter_dsc_fonte_geracao_choices,
                          selected = query[["filter_dsc_fonte_geracao"]]
        )
      }
      if (!is.null(query[["filter_dsc_porte"]])) {
        updateSelectInput(session, "filter_dsc_porte",
                          choices = param$filter_dsc_porte_choices,
                          selected = query[["filter_dsc_porte"]]
        )
      }

      selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
      if (!is.null(query[["filter"]])) {
        updateSelectizeInput(session,
          "filter1",
          choices = param$filter_choices,
          selected = selected
        )
      }

      # Se query está vazia, preenche aleatório
      if (is.null(query[["filter"]]) && is.null(query[["y"]])
          && is.null(query[["filter_dsc_fonte_geracao"]])) {
        random_inputs() # preenche inputs se estiverem vazios
      }
    }

    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$y) || input$y == "") {
        text <- "Variável no eixo Y não selecionada"
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        y_col <- param$table[which(param$table$var == input$y), ]

        text <- paste0(y_col$label)
      }

      text
    })
    output$plot_subtitle <- renderText({
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$y) || input$y == "") {
        text <- " "
      } else {

        text <- paste0(param$subtitle_init, input$filter_sig_modalidade_empreendimento,
          ", ", input$filter_dsc_fonte_geracao, " ", param$subtitle_sep, " ", 
          input$filter_dsc_porte)
      }

      text
    })

    # Output gráfico
    output$plot <- renderPlotly({
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco
      tryCatch(
        {
          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(input$y) || input$y == "" ||
              is.null(input$filter_sig_modalidade_empreendimento) || 
              input$filter_sig_modalidade_empreendimento == "" ||
              is.null(input$filter_dsc_fonte_geracao) || 
              input$filter_dsc_fonte_geracao == "" ||
              is.null(input$filter_dsc_porte) || 
              input$filter_dsc_porte == "" ||
            is.null(input$filter1) || length(input$filter1) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          # Cria dataframe do gráfico
          x_col <- param$table[which(param$table$var == param$x_def), ]
          y_col <- param$table[which(param$table$var == input$y), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]
          color_col <- param$table[which(param$table$var == param$color_def), ]

          # Filtra dataframe com grupos selecionados
          df_filtered <- df_reactived()[which(df_reactived()$group %in% input$filter1), ]

          df_p <- data.frame(
            df_filtered[x_col$var],
            df_filtered[y_col$var],
            df_filtered[color_col$var]
          )
          colnames(df_p) <- c("x", "y", "color")
          df_p$group <- df_filtered$group
          df_p$text <- df_p$group

          # Filtra colunas onde x,y e size são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$y)), ]

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Se a coluna de cor for toda NA, preenche com strings em branco
          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }

          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            "Ano : ", "<b>", paste0(df_p$x), "</b><br>",
            "Modalidade de empreendimento: ", "<b>", paste0(input$filter_sig_modalidade_empreendimento),"</b><br>",
            "Fonte de geracao: ",  "<b>", paste0(input$filter_dsc_fonte_geracao),"</b><br>",
            "Porte: ",  "<b>", paste0(input$filter_dsc_porte),"</b><br>",
            "Unidade de medida: ", "<b>", y_col$unidade,"</b><br>",
            y_col$label, ": ", "<b>", format(df_p$y, scientific = FALSE,
                                      digits = 2,
                                      decimal.mark = ",", 
                                      big.mark = "."), "</b><br>"
          )

          # Define paleta de cores
          pallete <- pallete_discrete

          # Monta gráfico
          fig_p <- plot_ly(df_p,
            x = ~x,
            y = ~y,
            color = ~group,
            type = "scatter",
            mode = "lines+markers",
            text = ~tooltip,
            hoverinfo = "text"
          )

          # Layout eixos
          x_axis_layout <- list(
            title = x_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )
          y_axis_layout <- list(
            title = y_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = TRUE,
            showgrid = FALSE,
            zeroline = FALSE
          )

          # Layout hover/tooltip
          tooltip <- list(
            bordercolor = "rgba(255, 255, 255, 1)",
            bgopacity = "0.5",
            font = f1
          )

          # Aplica layout
          fig_p <- fig_p %>%
            layout(
              font = f1,
              xaxis = x_axis_layout,
              yaxis = y_axis_layout,
              showlegend = TRUE,
              hoverlabel = tooltip
            )

          #  Configura botões do plotly
          fig_p <- fig_p %>%
            config(
              # toImageButtonOptions = list(format = "svg"),
              displaylogo = FALSE,
              modeBarButtonsToRemove = c(
                "lasso2d",
                "select2d",
                "hoverCompareCartesian"
              )
            )

          fig <- fig_p # retorna a figura do gráfico
        },
        error = function(cond) {
          # se encontrar erro retorna fig em branco
          print("plot error")
          fig <- plotly_empty()
        }
      )
      fig
    })

    # Observa eventos
    observe({
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)
      update_my_inputs()
    })
  }

  # Retorna objeto server
  server
}
