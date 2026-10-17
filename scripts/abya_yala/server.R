# -------------------------------- Define lógica do server --------------------------------

get_server <- function(files, param) {
    
    # Carrega dados
    regions <- readr::read_rds(files$db_file)
    
    # Registra a pasta de assets (Rmds já renderizados em HTML, fotos, banner, ícones)
    # para que o Shiny sirva esses arquivos estáticos sob o prefixo "abya_yala_assets"
    shiny::addResourcePath("abya_yala_assets", normalizePath(files$assets_dir))
    
    server <- function(input, output, session) {
        
        values <- reactiveValues(mapLoaded = FALSE)
        
        output$plot_title <- renderText({
            param$plot_name
        })
        output$plot_subtitle <- renderText({
            param$plot_desc
        })
        
        pallete_discrete <- c("#fcff84", "#ffcf48", "#c3ff83", "#007e47", "#00596d", "#4fdf94", "#99b0c8", "#261c4e", "#000098", "#c368b1", "#60458c", "#757575")
        
        pal <- colorFactor(
            palette = c("#FF6B35", "#007e47"),
            domain = regions$temporada
        )
        
        region_centroids <- st_point_on_surface(regions)
        
        output$map <- renderLeaflet({
            leaflet(regions) %>%
                addProviderTiles("Esri.WorldGrayCanvas",
                                 options = providerTileOptions(className = "tiles-escuros")) %>%
                htmlwidgets::onRender("function(el, x) { this.attributionControl.addAttribution('<a href=\"https://native-land.ca/\">Native Land Digital</a>'); }") %>%
                addControl(
                    html = '<button onclick="Shiny.setInputValue(\'showHelp\', Math.random())"
                      style="background:#007BFF;color:white;border:none;border-radius:50%;width:32px;height:32px;font-size:18px;">
                    ?
                </button>',
                    position = "topright"
                ) %>%
                addControl(
                    html = '<div onclick="window.open(\'https://datazoomamazonia.com.br/\', \'_blank\')" style="cursor: pointer;">
    <img src="https://raw.githubusercontent.com/datazoompuc/datazoom.amazonia/master/logo.png" style="height:20px; vertical-align:middle; margin-right:5px;">
    Data Zoom Amazônia
  </div>',
                    position = "topright",
                    className = "datazoom"
                ) %>%
                addControl(
                    html = '<img id="logo-click" src="abya_yala_assets/logo.jpg" style="width:10vh; cursor:pointer;">',
                    position = "topleft",
                    className = "logo"
                ) %>%
                addPolygons(
                    data = regions,
                    layerId = ~label,
                    fillColor = ~pal(temporada), weight = 1, color = "white", fillOpacity = 0.6,
                    highlightOptions = highlightOptions(color = "red", weight = 2),
                    label = ~lapply(paste0(
                        "<strong>", etnia, "</strong><br/>",
                        nome, "<br/>",
                        temporada, "ª temporada"
                    ), htmltools::HTML)
                ) %>%
                addAwesomeMarkers(
                    data = region_centroids,
                    layerId = ~label,
                    label = ~lapply(paste0(
                        "<strong>", etnia, "</strong><br/>",
                        nome, "<br/>",
                        temporada, "ª temporada"
                    ), htmltools::HTML),
                    icon = awesomeIcons(
                        icon = 'circle',
                        iconColor = 'white',
                        markerColor = 'white',
                        library = 'fa'
                    ),
                    clusterOptions = markerClusterOptions(
                        iconCreateFunction = JS("
            function(cluster) {
                return new L.DivIcon({
                    html: '<div style=\"background-color: white; color: black; border: 2px solid #ccc; border-radius: 50%; width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; font-weight: bold;\">' + cluster.getChildCount() + '</div>',
                    className: 'marker-cluster-custom',
                    iconSize: new L.Point(40, 40)
                });
            }
        ")
                    ))
        })
        
        current_page <- reactiveVal("default")
        
        get_page_name <- function(id) {
            if (is.null(id)) return("default")
            else {
                id
            }
        }
        
        observeEvent(input$map_shape_click, {
            current_page(get_page_name(input$map_shape_click$id))
        })
        
        observeEvent(input$map_marker_click, {
            current_page(get_page_name(input$map_marker_click$id))
        })
        
        observeEvent(input$logo_clicked, {
            current_page("default")
        })
        
        output$regionInfo <- renderUI({
            tags$iframe(
                id = "regionFrame",
                src = paste0("abya_yala_assets/", current_page(), ".html"),
                width = "100%",
                frameborder = 0,
                style = "border: none; display: block;"
            )
        })
        
        output$helpbox <- renderUI({
            tags$div(
                id = "helpbox",
                tags$p("Explore o mapa clicando em um território ou marcador."),
                tags$p("Então clique na seta abaixo para expandir o painel de texto."),
                tags$p("Para voltar à descrição do projeto, clique no logotipo à esquerda."),
                tags$button("×", onclick = "document.getElementById('helpbox').style.display='none';",
                            style = "position:absolute; top:5px; right:10px; border:none; background:none; font-size:20px;")
            )
        })
        
        observeEvent(input$showHelp, {
            session$sendCustomMessage("showInstructions", TRUE)
        })
        
        tags$script(HTML("
    Shiny.addCustomMessageHandler('showInstructions', function(message) {
      document.getElementById('helpbox').style.display = 'block';
    });
  ")) %>% insertUI(selector = "body", where = "beforeEnd")
    }
    
    server
}
