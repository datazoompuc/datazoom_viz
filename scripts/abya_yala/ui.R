#  -------------------------------- Define UI --------------------------------

get_ui <- function(files, param) {
    fluidPage(
        
        includeCSS(files$CSS_script), # Incluí script CSS
        tags$style(type = "text/css",
                   "
      .irs-grid-text.js-grid-text-10 {display: none;}
      .irs-grid-pol.small {display: none;}
      .slider-animate-container {width: 5%; margin-top: 1px;}
      .slider-animate-button {font-size: 20px;}
    "),
        
        tags$head(
            tags$style(HTML("
      #infoPanel {
        transition: height 0.3s ease;
        z-index: 500;
        overflow: hidden;
      }
      #regionFrame {
        width: 100%;
        display: block;
        border: none;
        max-height: none;
        scrollbar-width: thin !important;
        scrollbar-color: white !important;
      }
    regionFrame::-webkit-scrollbar {
      width: 8px !important;
    }

#regionFrame::-webkit-scrollbar-track {
    background: transparent !important;
}

#regionFrame::-webkit-scrollbar-thumb {
    background-color: white !important;
    border-radius: 4px !important;
    border: 2px solid transparent !important;
    background-clip: content-box !important;
}
      }
      #toggleButton {
        cursor: pointer;
        background-color: #ddd;
        border-radius: 5px 5px 0 0;
        padding: 4px 8px;
        font-weight: bold;
        font-size: 14px;
        text-align: center;
        z-index: 100
      }
      #map {
        border: 1px solid white;
        border-radius: 1px;
        margin: 0px;
      }
      #helpbox {
        position: fixed;
        top: 20px;
        right: 20px;
        background-color: white;
        border: 1px solid #ccc;
        padding: 15px;
        z-index: 9999;
        box-shadow: 2px 2px 10px rgba(0,0,0,0.3);
        border-radius: 8px;
        max-width: 300px;
      }

      .logo {
          transition: opacity 1s ease;
      }
      .datazoom {
          transition: opacity 1s ease;
          background: white;
          background: rgba(255,255,255,0.8);
          border-radius: 5px;
          padding: 6px 8px;
          font-family: JetBrains Mono;
          font-style: normal;
          font-weight: 100;
          box-shadow: 0 1px 5px rgba(0,0,0,0.4);
          border: 2px solid rgba(0,0,0,0.2);
      }
    #helpbox {
        font-family: JetBrains Mono;
        font-style: normal;
        font-weight: 100;
        font-size: 12px;
        position: fixed;
        top: 80px;
        right: 100px;
        background-color: white;
        border: 1px solid #ccc;
        padding: 15px;
        z-index: 9999;
        box-shadow: 2px 2px 10px rgba(0,0,0,0.3);
        border-radius: 8px;
        max-width: 300px;
      }
  
  .datazoom a {
    text-decoration: none;
    color: black;
  }
  
  .datazoom a:hover {
    color: #0078A8;
  }
    
    @media (max-width: 768px) {
        .logo {
        display: none !important;
        }
    }"
            ))
        ),
        
        div(
            class = "plotcol h-100",
            style = "background: #0e0e0e;",
            textOutput("plot_title"),
            textOutput("plot_subtitle")
        ),
        
        uiOutput("helpbox"),
        
        withSpinner(
            leafletOutput("map", height = "90vh"),
            type = 4, color = "white"
        ),
        
        absolutePanel(
            id = "infoPanel", class = "panel panel-default", fixed = TRUE,
            bottom = 0, left = 0, right = 0,
            height = "15vh",
            style = "background: black; padding: 0; display: flex; flex-direction: column;",
            
            div(id = "toggleButton", "▲", onclick = "togglePanel()",
                style = "background: black; color: white; text-align: center; padding: 10px; cursor: pointer; flex-shrink: 0;"),
            
            
            htmlOutput("regionInfo")
        ),
        
        tags$script(HTML("
var panelVisible = false;
function togglePanel() {
  const panel = document.getElementById('infoPanel');
  const toggle = document.getElementById('toggleButton');
  const logo = document.querySelector('.logo');
  const datazoom = document.querySelector('.datazoom');
  const iframe = document.getElementById('regionFrame');
  
  if (panelVisible) {
    panel.style.height = '15vh';
    toggle.innerHTML = '▲';
    logo.style.opacity = '1';
    logo.style.pointerEvents = 'auto';
    datazoom.style.opacity = '1';
    datazoom.style.pointerEvents = 'auto';
    
    if (iframe) {
      iframe.style.height = 'calc(15vh - 40px)';
    }
  } else {
    panel.style.height = '70vh';
    toggle.innerHTML = '▼';
    logo.style.opacity = '0';
    logo.style.pointerEvents = 'none';
    datazoom.style.opacity = '0';
    datazoom.style.pointerEvents = 'none';
    
    if (iframe) {
      iframe.style.height = 'calc(70vh - 40px)';
    }
  }
  panelVisible = !panelVisible;
}

    function waitForLogoAndBind() {
    var logo = document.getElementById('logo-click');
    if (logo) {
      logo.addEventListener('click', function() {
        Shiny.setInputValue('logo_clicked', new Date().getTime());
      });
    } else {
      setTimeout(waitForLogoAndBind, 300);
    }
  }
  waitForLogoAndBind();

const observer = new MutationObserver(function(mutations, observer) {
    const helpBtn = document.getElementById('helpToggle');
    const helpBox = document.getElementById('helpBox');
    if (helpBtn && helpBox) {
        helpBtn.addEventListener('click', function() {
            helpBox.style.display = 'block';
        });
        observer.disconnect();
    }
});
observer.observe(document.body, { childList: true, subtree: true });
"
        ))
    )
}