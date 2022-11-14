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
  df <- readRDS(files$db_file)
    
  server <- function(input, output, session) {
    
    df_reactived <- reactive({
      
      if (input$tipo != "Todos") df <- df %>% filter(tipo == input$tipo)
      if (input$fonte != "Todos") df <- df %>% filter(fonte == input$fonte)
      if (input$origem != "Todos") df <- df %>% filter(origem == input$origem)
      if (input$combustivel != "Todos") df <- df %>% filter(combustivel_final == input$combustivel)
      
      w <- df %>%
        group_by(ano, municipio, estado) %>%
        summarise(potencia_outorgada_k_w = sum(potencia_outorgada_k_w))
      
      return(w)
    })
    
    # Cria opções para seleção de grupos
    param$fonte_choices <- c("Todos", sort(unique(df$fonte)))
    param$origem_choices <- c("Todos", sort(unique(df$origem)))
    param$tipo_choices <- c("Todos", sort(unique(df$tipo)))
    param$combustivel_choices <- c("Todos", sort(unique(df$combustivel_final)))
    
    # Adicionar opcoes no ui
    updateSelectInput(session, "fonte",
                      choices = param$fonte_choices)
    
    updateSelectInput(session, "origem",
                      choices = param$origem_choices)
    
    updateSelectInput(session, "tipo",
                      choices = param$tipo_choices)
    
    updateSelectInput(session, "combustivel",
                      choices = param$combustivel_choices)
    

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      # se input está vazio preenche com valor aleatório da lista de colunas
      if (input$fonte == "") {
        updateSelectInput(session, "fonte",
          choices = param$fonte_choices,
          selected = sample(param$fonte_choices, 1)
        )
      }
      if (input$origem == "") {
        updateSelectInput(session, "origem",
          choices = param$origem_choices,
          selected = sample(param$origem_choices, 1)
        )
      }
      if (input$tipo == "") {
        updateSelectInput(session, "tipo",
          choices = param$tipo_choices,
          selected = sample(param$tipo_choices, 1)
        )
      }
      if (input$combustivel == "") {
        updateSelectInput(session, "fonte",
          choices = param$combustivel_choices,
          selected = sample(param$combustivel_choices, 1)
        )
      }

    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "fonte=", input$fonte,
        "&", "origem=", input$origem,
        "&", "tipo=", input$tipo,
        "&", "combustivel=", input$combustivel
      )
      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["fonte"]])) {
        updateSelectInput(session, "fonte",
          choices = param$fonte_choices,
          selected = query[["fonte"]]
        )
      }
      if (!is.null(query[["origem"]])) {
        updateSelectInput(session, "origem",
          choices = param$origem_choices,
          selected = query[["origem"]]
        )
      }
      if (!is.null(query[["tipo"]])) {
        updateSelectInput(session, "tipo",
          choices = param$tipo_choices,
          selected = query[["tipo"]]
        )
      }
      if (!is.null(query[["combustivel"]])) {
        updateSelectInput(session, "combustivel",
          choices = param$combustivel_choices,
          selected = query[["combustivel"]]
        )
      }
    }


    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$tipo) || is.null(input$origem) || 
          is.null(input$fonte) || is.null(input$combustivel)) {
        text <- "Variável não selecionada"
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
        x_col <- param$table[which(param$table$var == param$x_def), ]

        text <- paste0("Ranking de ", x_col$label)
      }

      text
    })
    output$plot_subtitle <- renderText({
      text <- paste0("Fonte: ", input$fonte, ", Origem: ", input$origem,
                     ", Tipo: ", input$tipo, ", Combustível Final: ", input$combustivel)

      text
    })

    # Output gráfico
    output$plot <- renderPlotly({

      # random_inputs() #preenche inputs se estiverem vazios
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco

      tryCatch(
        {

          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(input$tipo) || is.null(input$origem) || 
              is.null(input$fonte) || is.null(input$combustivel)) {
            fig <- plotly_empty()
            stop()
          }
          
          
          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          x_col <- param$table[which(param$table$var == param$x_def), ]
          color_col <- param$table[which(param$table$var == param$color_def), ]
          slider_col <- param$table[which(param$table$var == param$slider_def), ]
          group_col <- param$table[which(param$table$var == param$group), ]
          text_col <- param$table[which(param$table$var == param$text_def), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]
  
          # Cria coluna vazia para o ranking
          y_col <- list()
          y_col$var <- "rank"
          y_col$label <- "Ranking"

          df_p <- data.frame(
            df_reactived()[x_col$var],
            NA,
            df_reactived()[color_col$var],
            df_reactived()[slider_col$var],
            df_reactived()[group_col$var],
            df_reactived()[text_col$var],
            df_reactived()[id_col$var]
          )

          colnames(df_p) <- c("x", "y", "color", "slider", "group", "text", "id")

          # Filtra colunas onde variáveis são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$color)), ]
          
          # Adicionar combinações de municipio e ano (slider buga se municipios nao aparecem sempre no df)
          comb <- tidyr::expand(df_p, slider, group) %>%
            left_join(df_p %>% select(color, group)) %>%
            unique() %>%
            mutate(text = group, id = group, y = NA)
         
           df_p <- df_p %>% 
              right_join(comb) %>%  # add all combinations of time and group
              mutate(x = ifelse(is.na(x), 0, x))

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }

          # Ordena base por variável de ranking e preenche y
          df_p <- df_p %>%
            group_by(slider) %>% # para cada ano
            mutate(y = order(order(x, decreasing = TRUE))) %>% # rank pela var de x
            arrange(y, .by_group = TRUE) # ordena por rank e ano

          # Se o rank for NA coloca para o final do ranking e zera x
          df_p$y[is.na(df_p$y)] <- max(df_p$y) + 1
          df_p$x[is.na(df_p$x)] <- 0

          # Se a coluna de cor for toda NA, preenche com strings em branco
          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }

          # Deixa somente grupos que tem rank <n em algum momento
          top_n <- 10
          top_groups <- unique(df_p$group[which(df_p$y <= top_n)])
          df_p <- df_p %>% filter(group %in% top_groups)
          
          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            "(", df_p$slider, ")", "<br><br>",
            x_col$label, ": ", format(df_p$x, scientific = FALSE,
                                      digits = 2,
                                      decimal.mark = ",", 
                                      big.mark = "."), "<br>",
            y_col$label, ": ", df_p$y, "<br>",
            color_col$label, ": ", df_p$color
          )

          # Define paleta de cores
          pallete <- pallete_continuous
          if (!is.numeric(df_p$color)) {
            pallete <- pallete_discrete
          }

          # Calcula menor e maior valor de x
          min_x <- min(0, min(df_p$x))
          max_x <- max(0, max(df_p$x))

          # Monta gráfico

          # base do gráfico
          fig_p <- plot_ly(df_p,
            x = ~x,
            y = ~y,
            color = ~color,
            colors = pallete,
            frame = ~slider,
            text = ~tooltip,
            textposition = "middle right",
            showlegend = FALSE,
            # marker = list(
            #  opacity = 0.5,
            #  line = list(width = 1, color = 'white')
            # ),
            hoverinfo = "text"
          ) %>% animation_opts(redraw = TRUE, transition = 500)

          # adiciona barras
          fig_p <- fig_p %>% add_segments(
            x = 0,
            xend = ~x,
            y = ~y,
            yend = ~y,
            split = ~id,
            color = ~color,
            line = list(width = 30),
            opacity = 0.7
          )

          # adiciona textos
          fig_p <- fig_p %>% add_text(
            x = 0.01 * max_x, # ~x/2,
            text = ~text,
            ids = ~id,
            hoverinfo = "none",
            textfont = f1,
            textposition = "middle right"
          )

          if (!is.numeric(df_p$color)) {
            # adiciona barra sem split para a legenda
            fig_p <- fig_p %>% add_segments(
              hoverinfo = "none",
              showlegend = TRUE,
              x = 0,
              xend = 0,
              y = ~y,
              yend = ~y,
              color = ~color,
              line = list(width = 30),
              opacity = 0.7
            )
          } else {
            fig_p <- fig_p %>% colorbar(title = color_col$label)
          }



          # Parâmetros animação e slider (se tiver mais de um frame)
          if (length(unique(df_p$slider)) > 1) {
            # Edita slider
            fig_p <- fig_p %>% animation_slider(currentvalue = list(prefix = "Ano: ", font = f1))

            # Botões da animação
            #  edita botão padrão (editar move ele para o updatemenus)
            fig_p <- fig_p %>% animation_button(label = "Play")

            #  sobrescreve updatemenus, adicionando play e pause
            fig_p$x$layout$updatemenus <- list(
              list(
                type = "buttons",
                direction = "right",
                showactive = FALSE,
                x = 0,
                y = 0,
                xanchor = "top",
                yanchor = "right",
                pad = list(t = 60, r = 5),
                buttons = list(
                  list(
                    method = "animate",
                    label = "\u25B6",
                    args = list(
                      NA, # primeiro arg vazio para play
                      list(
                        mode = "immediate",
                        transition = list(duration = 1750, easing = "linear", redraw = TRUE),
                        fromcurrent = TRUE,
                        frame = list(redraw = TRUE, duration = 1750)
                      )
                    )
                  ),
                  list(
                    method = "animate",
                    # label = "<U+25FC>",
                    label = "I I",
                    args = list(
                      list(), # primeiro arg lista vazia para pause
                      list(
                        mode = "immediate",
                        transition = list(duration = 0),
                        frame = list(redraw = FALSE, duration = 0)
                      )
                    )
                  )
                )
              )
            )

            # Pula animação para último frame (custom JS)
            first_frame <- min(df_p$slider)
            last_frame <- max(df_p$slider)
            fig_p <- fig_p %>% onRender("
            function(el,x,data){
              Plotly.animate(el, data, {frame: [{duration: 0}]})
            }",
              data = c(first_frame, last_frame)
            )
          }


          # Layout eixos
          x_axis_layout <- list(
            title = x_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = FALSE,
            range = c(min_x, max_x), # fixa range do x
            showgrid = FALSE,
            zeroline = FALSE
          )
          y_axis_layout <- list(
            title = y_col$label,
            titlefont = f1,
            tickfont = f2,
            automargin = FALSE,
            autorange = FALSE,
            showgrid = FALSE,
            zeroline = FALSE,
            dtick = 1,
            tick0 = 1,
            range = c(top_n + 0.5, 0.5), # fixa range do y somente para top 10
            type = "numeric"
          )

          # Tipo de eixo (se log selecionado)
          # if (input$xlog & is.numeric(df_p$x)) {
          #  x_axis_layout$type <- "log"
          # }

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
              legend = list(title = list(text = color_col$label)),
              hoverlabel = tooltip
            )

          fig <- fig

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
