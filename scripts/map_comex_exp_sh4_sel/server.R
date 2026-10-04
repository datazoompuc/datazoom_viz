# -------------------------------- Define lógica do server --------------------------------

# Paleta de cores
pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
pallete_continuous <- c("#440154", "#481567", "#453781", "#404788", "#39568c", "#33638d", "#287d8e", "#238a8d", "#1f968b", "#20a387", "#29af7f", "#3cbb75", "#55c667", "#73d055", "#95d840", "#b8de29", "#dce319", "#fde725") # Viridis
pallete_discrete <- rev(pallete_discrete)
pallete_continuous <- rev(pallete_continuous)


# Funcão para retornar objeto server
get_server <- function(files, param) {
  
  # Carrega dados
  df <- readRDS(files$db_file) %>%
    st_transform(crs = "+init=epsg:4326")
  
  # Lookups de tradução PT -> EN
  aux <- readRDS(files$aux_file)
  
  trunc_str <- function(x, n) {
    ifelse(!is.na(x) & nchar(x) > n, paste0(substr(x, 1, n - 1), "…"), x)
  }
  
  # SH4: cod_sh4 (char, 4 díg.) -> nome EN, truncado a 60 (igual ao PT)
  sh4_map <- aux %>% distinct(CO_SH4, NO_SH4_EN)
  map_sh4_en <- setNames(trunc_str(sh4_map$NO_SH4_EN, 60), sh4_map$CO_SH4)
  
  # SH2: código de 2 díg. -> nome EN, truncado a 50 (igual ao PT)
  sh2_map <- aux %>%
    mutate(CO_SH2 = substr(CO_SH4, 1, 2)) %>%
    distinct(CO_SH2, NO_SH2_EN)
  map_sh2_en <- setNames(trunc_str(sh2_map$NO_SH2_EN, 50), sh2_map$CO_SH2)
  
  # Domínio de cores dos capítulos (SH2) em cada idioma — mantém legenda estável
  chapters <- df %>%
    st_drop_geometry() %>%
    distinct(cod_sh2, nome_sh2) %>%
    filter(!is.na(nome_sh2)) %>%
    mutate(cs2 = sprintf("%02d", as.integer(cod_sh2)),
           nome_sh2_en = ifelse(is.na(map_sh2_en[cs2]), nome_sh2, unname(map_sh2_en[cs2])))
  domain_sh2 <- list(
    pt = sort(unique(chapters$nome_sh2)),
    en = sort(unique(chapters$nome_sh2_en))
  )
  
  # Traduz produto_principal e nome_sh2 de um sf filtrado, se idioma = EN
  translate_names <- function(w, lg) {
    if (lg == "en") {
      en_prod <- map_sh4_en[as.character(w$cod_sh4)]
      w$produto_principal <- ifelse(is.na(en_prod), w$produto_principal, unname(en_prod))
      en_ch <- map_sh2_en[sprintf("%02d", as.integer(w$cod_sh2))]
      w$nome_sh2 <- ifelse(is.na(en_ch), w$nome_sh2, unname(en_ch))
    }
    w
  }
  
  # --- Base para a visão "Razão: Floresta / Outros produtos" ---
  df_resto <- df %>%
    filter(!floresta) %>%
    select(
      cod_ibge, time, nm_municip, uf, geometry, cod_sh4, cod_sh2,
      produto_principal_resto = produto_principal,
      maximo_resto = maximo_produto
    )
  
  df_forest <- df %>%
    filter(floresta) %>%
    st_drop_geometry() %>%
    select(
      cod_ibge, time,
      produto_principal_forest = produto_principal,
      maximo_forest = maximo_produto
    )
  
  df_ratio <- df_resto %>%
    left_join(df_forest, by = c("cod_ibge", "time")) %>%
    mutate(
      same_prod = !is.na(produto_principal_forest) &
        (produto_principal_forest == produto_principal_resto),
      
      ratio_compat = dplyr::if_else(
        is.na(maximo_resto) | maximo_resto <= 0 | is.na(maximo_forest),
        NA_real_,
        maximo_forest / maximo_resto
      ),
      
      ratio_compat = if_else(same_prod, 1, ratio_compat),
      
      # classe como chave idioma-independente (traduzida no server)
      # "Mesmo produto principal" conta como compatível com a floresta:
      # same_prod já força ratio_compat = 1, que cai em "sim" (>= 1)
      classe_ratio = case_when(
        is.na(ratio_compat) ~ NA_character_,
        ratio_compat < 1 ~ "nao",
        ratio_compat >= 1 ~ "sim"
      ),
      
      produto_principal = produto_principal_resto,
      maximo_produto    = ratio_compat
    ) %>%
    st_as_sf()
  
  
  
  server <- function(input, output, session) {
    
    # Lang toggle
    lang <- reactiveVal("pt")
    
    observeEvent(input$toggle_lang, {
      lang(ifelse(lang() == "pt", "en", "pt"))
    })
    
    i18n <- reactive({ param$i18n[[lang()]] })
    
    # rótulo traduzido da opção x selecionada (p/ subtítulo)
    x_label <- reactive({
      switch(input$x,
             forest = i18n()$x_forest,
             all    = i18n()$x_all,
             razao  = i18n()$x_razao,
             "")
    })
    
    # Textos dinâmicos da sidebar
    output$plot_desc <- renderText({ i18n()$plot_desc })
    output$topo      <- renderText({ i18n()$topo })
    
    # Atualiza inputs e botões quando o idioma muda
    observeEvent(lang(), {
      updateSelectInput(
        session, "x",
        label    = i18n()$varxlabel,
        choices  = setNames(c("forest", "all", "razao"),
                            c(i18n()$x_forest, i18n()$x_all, i18n()$x_razao)),
        selected = isolate(input$x)
      )
      updateSliderInput(session, "filter1", label = i18n()$vardatelabel)
      updateActionButton(session, "toggle_lang", label = i18n()$btn_lang)
      updateActionButton(session, "ab1",         label = i18n()$btn_fullscreen)
    }, ignoreInit = FALSE)
    
    
    # Dados reativos
    df_reactived <- reactive({
      lg <- lang()
      
      if (input$x == "razao") {
        w <- df_ratio %>% filter(time == input$filter1)
        # traduz o produto principal (do grupo "outros") pelo código
        if (lg == "en") {
          en_prod <- map_sh4_en[as.character(w$cod_sh4)]
          w$produto_principal <- ifelse(is.na(en_prod), w$produto_principal, unname(en_prod))
        }
        # nome_sh2 = classe da razão, traduzida
        lv <- c(i18n()$ratio_nao, i18n()$ratio_sim)
        key2lab <- setNames(lv, c("nao", "sim"))
        w$nome_sh2 <- factor(unname(key2lab[w$classe_ratio]), levels = lv)
        return(w)
      }
      
      w <- df %>% filter(time == input$filter1)
      
      if (input$x == "forest") {
        w <- w %>% filter(floresta)
      } else {
        w <- w %>% filter(!floresta)
      }
      
      translate_names(w, lg)
    })
    
    # Cria opções para seleção de datas
    param$filter_choices <- sort(unique(df$time))
    
    # Funcão para preencher inputs com coluna/variável aleatória
    random_inputs <- function() {
      updateSliderInput(session, "filter1", value = param$year_final)
    }
    
    # Função para atualizar url do app com parâmetros dos inputs
    update_my_queryString <- function() {
      q_string <- paste0(
        "?", "x=", input$x,
        "&", "filter=", input$filter1
      )
      
      updateQueryString(q_string, mode = "replace")
    }
    
    # Função para atualizar inputs a partir da URL
    update_my_inputs <- function() {
      query <- parseQueryString(session$clientData$url_search)
      
      # idioma via ?lang=en
      if (!is.null(query[["lang"]]) && query[["lang"]] == "en") lang("en")
      
      selected <- unlist(query[names(query) == "filter"], use.names = FALSE)
      if (length(selected)) {
        updateSliderInput(session, "filter1", value = as.numeric(selected))
      } else {
        random_inputs()
      }
    }
    
    output$plot_title <- renderText({
      if (is.null(input$filter1) || input$filter1 == "") " " else i18n()$titulo1
    })
    output$plot_subtitle <- renderText({
      if (is.null(input$filter1) || input$filter1 == "") {
        i18n()$titulo2
      } else {
        paste0(i18n()$titulo3, x_label())
      }
    })
    
    output$map <- renderLeaflet({
      
      update_my_queryString()
      
      fig <- leaflet() %>%
        addProviderTiles(provider = "CartoDB.VoyagerNoLabels") %>%
        setView(-58, -7, zoom = 5)
      
      vals <- df_reactived()[["nome_sh2"]]
      
      if (input$x == "razao") {
        lv <- c(i18n()$ratio_nao, i18n()$ratio_sim)
        pal <- colorFactor(
          palette  = pallete_discrete[2:3],   # mantém as cores que "nao" e "sim" já tinham
          domain   = lv,
          na.color = "#cccccc"
        )
      } else {
        pal1 <- pallete_continuous
        if (!is.numeric(vals)) {
          pal1 <- pallete_discrete
        }
        pal <- colorFactor(palette = pal1, domain = domain_sh2[[lang()]])
      }
      
      tryCatch(
        {
          labels <- paste0(
            i18n()$tooltip1, " <b>", df_reactived()$nm_municip, "</b> <br>",
            i18n()$tooltip2, " <b>", df_reactived()$uf, "</b> <br>",
            i18n()$tooltip3, " <b>", df_reactived()[["produto_principal"]], "</b> <br>",
            i18n()$tooltip4, " <b>", df_reactived()[["nome_sh2"]], "</b> <br>",
            i18n()$tooltip5, " <b>", format(df_reactived()$maximo_produto, scientific = FALSE,
                                            digits = 2,
                                            decimal.mark = ",",
                                            big.mark = "."
            ), "<br>", "</b>",
            "<b>", i18n()$tooltip6, i18n()$tooltip7, "</b>"
          ) %>%
            lapply(htmltools::HTML)
          
          fig_p <- df_reactived() %>%
            leaflet() %>%
            addProviderTiles(provider = "CartoDB.VoyagerNoLabels") %>%
            setView(-58, -7, zoom = 5) %>%
            addPolygons(
              data = df_reactived(),
              label = labels,
              stroke = FALSE,
              smoothFactor = .5,
              fillOpacity = 0.7,
              fillColor = ~ pal(df_reactived()[["nome_sh2"]]),
              highlightOptions = highlightOptions(
                weight = 5,
                fillOpacity = 1,
                color = "black",
                opacity = 1,
                bringToFront = TRUE
              )
            ) %>%
            addLegend("bottomright",
                      pal = pal,
                      values = ~ df_reactived()[["nome_sh2"]],
                      title = i18n()$legend,
                      opacity = 0.7
            )
          
          fig <- fig_p
        },
        error = function(cond) {
          print("Plot error in tryCatch environment")
        }
      )
      fig
    })
    
    observe({
      update_my_inputs()
    })
  }
  
  server
}