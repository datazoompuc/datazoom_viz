# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis

# Fontes
f1 <- list(family = "Roboto", size = 14, color = "rgb(0, 0, 0)")
f2 <- list(family = "Roboto", size = 13, color = "rgb(0, 0, 0)")

# Funcão para retornar objeto server
get_server <- function(files, param) {
  
  # Carrega dados (tudo)
    df_all <- readRDS(files$db_file) %>%
        dplyr::right_join(tidyr::expand(., time, group))
    
    # --- lê auxiliar (RDS) ---
    aux_sh4 <- readRDS("data/auxiliar_cod_sh4.rds")
    stopifnot(all(c("CO_SH4", "NO_POR_MIN") %in% names(aux_sh4)))
    aux_sh4$CO_SH4 <- sprintf("%04d", as.numeric(aux_sh4$CO_SH4))
    
    # vetor: names = codigo, values = nome
    map_sh4_nome <- stats::setNames(aux_sh4$NO_POR_MIN, aux_sh4$CO_SH4)
    
    # renomeia colunas do df: codigo -> nome
    prod_cols <- setdiff(names(df_all), c("time", "group"))
    new_names <- names(df_all)
    
    # aplica mapeamento só onde existe no auxiliar
    has_map <- prod_cols %in% names(map_sh4_nome)
    new_names[match(prod_cols, new_names)] <- ifelse(
        has_map,
        unname(map_sh4_nome[prod_cols]),
        prod_cols
    )
    
    names(df_all) <- new_names
    
    # garante nomes únicos (evita colunas duplicadas)
    names(df_all) <- make.unique(names(df_all), sep = " __dup__ ")
    
    df_all[is.na(df_all)] <- 0
    
    # --- calcula TOP 20 produtos (por soma total) ---
    prod_cols2 <- setdiff(names(df_all), c("time", "group"))
    
    top_products <- df_all %>%
        dplyr::select(dplyr::all_of(prod_cols2)) %>%
        dplyr::summarise(dplyr::across(dplyr::everything(), ~sum(.x, na.rm = TRUE))) %>%
        tidyr::pivot_longer(dplyr::everything(), names_to = "produto", values_to = "total") %>%
        dplyr::arrange(dplyr::desc(total)) %>%
        dplyr::slice_head(n = 20) %>%
        dplyr::pull(produto)
    
    # --- opcional (recomendado): reduz df só com top 20 (mais leve) ---
    df <- df_all %>%
        dplyr::select(time, group, dplyr::all_of(top_products)) %>%
        dplyr::right_join(tidyr::expand(., time, group))
    
    df[is.na(df)] <- 0
  
  server <- function(input, output, session) {
      
      choices_top20 <- stats::setNames(top_products, top_products)  # label=valor=nome
      
      observeEvent(TRUE, {
          query <- parseQueryString(session$clientData$url_search)
          selected_x <- if (!is.null(query[["x"]]) && query[["x"]] %in% top_products) query[["x"]] else top_products[1]
          
          updateSelectInput(
              session, "x",
              choices = list(Comex = choices_top20),
              selected = selected_x
          )
      }, once = TRUE)
    
    # Cria opções para seleção de grupos
    param$filter_choices <- sort(unique(df$group))
    param$filter_choices <- param$filter_choices[which(param$filter_choices != " - ")]

    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      # se input está vazio preenche com valor aleatório da lista de colunas
      if (input$x == "") {
        updateSelectInput(session, "x",
          choices = param$x_choices,
          selected = sample(param$x_cols$var, 1)
        )
      }

      
    }

    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0("?", "x=", input$x)
      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      # Pega parametros da url e atribui aos selectinputs
      query <- parseQueryString(session$clientData$url_search)

      if (!is.null(query[["x"]])) {
        # se tem x na url atribui valor ao selecinput x
        updateSelectInput(session, "x",
          choices = list(Comex = choices_top20),
          selected = query[["x"]]
        )
      }

    }


    # Output título do gráfico
    output$plot_title <- renderText({
      text <- " "
      # Se algum campo estiver vazio retorna texto vazio
      if (is.null(input$x) || input$x == "") {
        text <- param$label_no_variable
      } else {
        # Monta título a partir de variáveis selecionadas nos inputs
          text <- paste0(param$ranking_intro, input$x)
      }

      text
    })
    output$plot_subtitle <- renderText({
      param$label_amazon
    })

    # Output gráfico
    output$plot <- renderPlotly({

      # random_inputs() #preenche inputs se estiverem vazios
      update_my_queryString() # atualiza url com parametros dos inputs

      fig <- plotly_empty() # inicia figura com gráfico em branco

      tryCatch(
        {

          # Se algum campo estiver vazio retorna gráfico vazio
          if (is.null(input$x) || input$x == "") {
            fig <- plotly_empty()
            stop()
          }
            

          # Cria dataframe do gráfico a partir do arquivo de parâmetros e dos select inputs
          x_col <- param$table[which(param$table$var == input$x), ]
          color_col <- param$table[which(param$table$var == param$color_def), ]
          slider_col <- param$table[which(param$table$var == param$slider_def), ]
          text_col <- param$table[which(param$table$var == param$text_def), ]
          id_col <- param$table[which(param$table$var == param$id_def), ]

          # Cria coluna vazia para o ranking
          y_col <- list()
          y_col$var <- "rank"
          y_col$label <- "Ranking"

          df_p <- data.frame(
            df[x_col$var],
            NA,
            df[color_col$var],
            df[slider_col$var],
            df["group"],
            df["group"],
            df[id_col$var]
          )

          colnames(df_p) <- c("x", "y", "color", "slider", "text", "group", "id")

          # Filtra colunas onde variáveis são NA (não serão exibidas no gráfico de qualquer forma)
          df_p <- df_p[which(!is.na(df_p$x) & !is.na(df_p$color)), ]

          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) {
            fig <- plotly_empty()
            stop()
          }


          # Mantém só top_n por ano (muito mais rápido que ranquear tudo)
          top_n <- 5  # troque para 20 se quiser top 20 municípios
          
          df_p <- df_p %>%
              filter(group != " - ") %>%
              mutate(x = dplyr::coalesce(x, 0)) %>%  # trata NA como 0
              group_by(slider) %>%
              slice_max(order_by = x, n = top_n, with_ties = FALSE) %>%  # filtra cedo
              arrange(slider, dplyr::desc(x), .by_group = TRUE) %>%
              mutate(y = dplyr::row_number()) %>%  # ranking 1..top_n
              ungroup()

          # Se a coluna de cor for toda NA, preenche com strings em branco
          if (all(is.na(df_p$color))) {
            df_p$color <- " "
          }


          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            "(", df_p$slider, ")", "<br><br>",
            input$x, ": ", format(df_p$x, scientific = FALSE,
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
            hoverinfo = "text",
            visible = TRUE
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
            opacity = 0.7,
            visible = TRUE
          )

          # adiciona textos
          fig_p <- fig_p %>% add_text(
            x = 0.01 * max_x, # ~x/2,
            text = ~text,
            ids = ~id,
            hoverinfo = "none",
            textfont = f1,
            textposition = "middle right",
            visible = TRUE
          )



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
                        transition = list(duration = 1000, easing = "linear", 
                                          redraw = TRUE),
                        fromcurrent = TRUE,
                        frame = list(redraw = TRUE, duration = 1500)
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
            title = param$x_label,
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

          fig <- fig %>% animation_opts(
            3000,
            easing = "linear", redraw = FALSE
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
    }) %>%
      bindCache(input$x)

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
