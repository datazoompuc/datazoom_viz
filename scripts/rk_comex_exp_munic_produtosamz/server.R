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
  
  df[is.na(df)] <- 0
  
  # --- auxiliar: CO_SH4 -> label --
  aux_sh4 <- readRDS(files$aux_file)
  stopifnot(all(c("CO_SH4", "NO_SH4_PT") %in% names(aux_sh4)))

  aux_sh4$CO_SH4 <- sprintf("%04d", as.numeric(aux_sh4$CO_SH4))
  map_nome <- stats::setNames(aux_sh4$NO_SH4_PT, aux_sh4$CO_SH4)
  
  # colunas de produto
  prod_codes <- setdiff(names(df), c("time", "group"))
  
  # mantém só os códigos que existem no auxiliar
  prod_codes <- prod_codes[prod_codes %in% names(map_nome)]
  
  starter_choices <- list(
      "Agro e alimentos" = c(
          "Soja, mesmo triturada" = "1201",
          "Milho" = "1005",
          "Legumes de vagem, secos, em grão" = "0713",
          "Produtos hortícolas congelados" = "0710",
          "Tomates, frescos ou refrigerados" = "0702",
          "Pepinos e pepininhos, frescos ou refrigerados" = "0707",
          "Grãos de cereais trabalhados (flocos/partidos etc.)" = "1104",
          "Produtos à base de cereais (expandidos/torrados)" = "1904",
          "Produtos hortícolas preparados/conservados (exceto vinagre)" = "2005",
          "Frutas e partes comestíveis, preparadas ou conservadas" = "2008",
          "Águas (minerais/gaseificadas) sem açúcar" = "2201",
          "Extratos e preparações de café/chá/mate" = "2101"
      ),
      
      "Carnes e produtos de origem animal" = c(
          "Carnes bovinas, congeladas" = "0202",
          "Carnes bovinas, frescas ou refrigeradas" = "0201",
          "Miudezas comestíveis (bov./suín./ovín. etc.)" = "0206",
          "Tripas, bexigas e estômagos de animais (exceto peixes)" = "0504",
          "Gorduras de bovinos/ovinos/caprinos (exceto 1503)" = "1502",
          "Farinhas/pó/pellets de carnes/miudezas/peixes (impróprios p/ alimentação humana)" = "2301"
      ),
      
      "Óleos e derivados" = c(
          "Óleo de soja e frações (mesmo refinado)" = "1507"
      ),
      
      "Florestais e madeira" = c(
          "Madeira serrada/endireitada longitudinalmente (> 6mm)" = "4407",
          "Madeira perfilada (tacos/frisos para soalhos etc.)" = "4409",
          "Cocos/castanha do Brasil/castanha de caju (frescos ou secos)" = "0801"  # se preferir, pode mover pra Agro
      ),
      
      "Metais e minerais" = c(
          "Ouro (bruto/semimanufaturado ou em pó)" = "7108",
          "Algodão, não cardado nem penteado" = "5201"
      ),
      
      "Indústria e manufaturados" = c(
          "Parafusos, porcas, anilhas, rebites e afins" = "7318",
          "Rolamentos (esferas/roletes/agulhas)" = "8482",
          "Papel/pasta para higiene e toucador" = "4818",
          "Vestuário feminino (conjuntos/vestidos/saias/calças etc.)" = "6204",
          "Malas, maletas, estojos e bolsas" = "4202",
          "Preparações e artigos farmacêuticos" = "3006"
      )
  )
  
  # ordena alfabeticamente dentro de cada categoria
  starter_choices <- lapply(starter_choices, function(x) x[order(tolower(names(x)))])
  
  # pega os códigos usados nas escolhas (valores do vetor)
  starter_codes <- unique(unname(unlist(starter_choices)))
  
  # garante formato "0000"
  starter_codes <- sprintf("%04d", as.integer(starter_codes))
                           
  # filtra para só códigos que existem no df e no auxiliar
  starter_codes <- intersect(starter_codes, prod_codes)
  
  # remove dos choices qualquer item cujo código não exista
  starter_choices <- lapply(starter_choices, function(x) x[x %in% starter_codes])
  starter_choices <- starter_choices[lengths(starter_choices) > 0]
  
  
  df <- df %>% select(time, group, all_of(starter_codes))
  df[is.na(df)] <- 0
  
  # if(param$lang){
  #     #translating the column names from the dataframe
  #     df <- df %>%
  #         rename("Coconuts, Brazil nuts, and cashew nuts, fresh or dried, whether or not shelled or peeled" = "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados",
  #                "Whole or broken cocoa, raw or roasted" = "Cacau inteiro ou partido, em bruto ou torrado",
  #                "Raw wood, whether or not stripped of bark or sapwood, or roughly squared" = "Madeira em bruto, mesmo descascada, desalburnada ou esquadriada")
  #     
  #     #translating the names from the param$table
  #     param$table <- param$table %>% 
  #         mutate(var = case_when(
  #             var == "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados" ~ "Coconuts, Brazil nuts, and cashew nuts, fresh or dried, whether or not shelled or peeled",
  #             var == "Cacau inteiro ou partido, em bruto ou torrado" ~ "Whole or broken cocoa, raw or roasted",
  #             var == "Madeira em bruto, mesmo descascada, desalburnada ou esquadriada" ~ "Raw wood, whether or not stripped of bark or sapwood, or roughly squared",
  #             TRUE ~ var
  #             ),
  #             label = case_when(
  #                 label == "Cocos, castanha do Brasil e castanha de caju, frescos ou secos, mesmo sem casca ou pelados" ~ "Coconuts, Brazil nuts, and cashew nuts, fresh or dried, whether or not shelled or peeled" ,
  #                 label == "Cacau inteiro ou partido, em bruto ou torrado" ~ "Whole or broken cocoa, raw or roasted",
  #                 label == "Madeira em bruto, mesmo descascada, desalburnada ou esquadriada" ~ "Raw wood, whether or not stripped of bark or sapwood, or roughly squared",
  #                 TRUE ~ label
  #             )
  #          )
  # }
   

  
  server <- function(input, output, session) {
    
      observeEvent(TRUE, {
          query <- parseQueryString(session$clientData$url_search)
          
          selected_x <- if (!is.null(query[["x"]]) && query[["x"]] %in% starter_codes) query[["x"]] else starter_codes[1]
          
          updateSelectInput(
              session, "x",
              choices = starter_choices,
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
      q_string <- paste0("?", "x=", URLencode(input$x, reserved = TRUE))
      updateQueryString(q_string, mode = "replace")
    }

    # Função para atualizar inputs a partir da URL
    # update_my_inputs <- function() {
    #   # Pega parametros da url e atribui aos selectinputs
    #   query <- parseQueryString(session$clientData$url_search)
    # 
    #   if (!is.null(query[["x"]])) {
    #     # se tem x na url atribui valor ao selecinput x
    #     updateSelectInput(session, "x",
    #       choices = param$x_choices$Comex,
    #       selected = query[["x"]]
    #     )
    #   }
    # 
    # }


    # Output título do gráfico
    output$plot_title <- renderText({
        param$plot_title
    })
    
    
    output$plot_subtitle <- renderText({
        if (is.null(input$x) || input$x == "") return("")
        
        cod <- sprintf("%04d", as.integer(input$x))
        nome <- unname(map_nome[cod])
        
        if (is.na(nome) || nome == "") {
            paste0("SH4 ", cod)
        } else {
            paste0(nome, " (SH4 ", cod, ")")
        }
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
            
          
          x_label <- unname(map_nome[input$x])
          if (is.na(x_label) || x_label == "") x_label <- input$x
          
          top_n <- 5

          # Cria coluna vazia para o ranking
          y_col <- list()
          y_col$var <- "rank"
          y_col$label <- "Ranking"

          df_p <- data.frame(
              x      = df[[input$x]],
              slider = df[[param$slider_def]],
              text   = df[["group"]],
              group  = df[["group"]],
              id     = df[[param$id_def]],
              stringsAsFactors = FALSE
          )



          # Se dataset estiver vazio, não monta o gráfico, retorna em branco
          if (nrow(df_p) < 1) return(plotly_empty())

          df_p$color <- df_p$group
          df_p$text  <- df_p$group
          
          
          df_p <- df_p %>%
              filter(group != " - ") %>%
              mutate(x = dplyr::coalesce(x, 0)) %>%
              group_by(slider) %>%
              mutate(
                  total_ano = sum(x, na.rm = TRUE),
                  pct_ano   = if_else(total_ano > 0, 100 * x / total_ano, 0)
              ) %>%
              slice_max(order_by = x, n = top_n, with_ties = FALSE) %>%
              arrange(desc(x), .by_group = TRUE) %>%
              mutate(y = row_number()) %>%
              ungroup()
          




          # Monta html do tooltip
          df_p$tooltip <- paste0(
            "<b>", df_p$text, "</b><br>",
            "(", df_p$slider, ")", "<br><br>",
            param$x_label, " : ", "<b>",format(df_p$x, scientific = FALSE,
                                      digits = 2,
                                      decimal.mark = ",", 
                                      big.mark = "."), "</b><br>",
            param$pct_anual, "<b>", format(round(df_p$pct_ano, 2), nsmall = 2, decimal.mark = ","), "%</b><br>",
            y_col$label, ": ", df_p$y, "<br>"
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
            font = f1,
            align = "left"
          )

          # Aplica layout
          fig_p <- fig_p %>%
            layout(
              font = f1,
              xaxis = x_axis_layout,
              yaxis = y_axis_layout,
              showlegend = TRUE,
              legend = list(title = list(text = param$table$label[param$table$var == param$color_def])),
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
    # observe({
    #   # Pega parametros da url e atribui aos selectinputs
    #   query <- parseQueryString(session$clientData$url_search)
    #   update_my_inputs()
    # })
  }

  # Retorna objeto server
  server
}
