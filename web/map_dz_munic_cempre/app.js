// Data Zoom Amazônia — app_map_dz_munic_cempre, JS/Leaflet PoC
//
// Static rebuild of the Shiny app: data is pre-exported by
// data-raw/export_map_dz_munic_cempre_web.R (which reuses the same join
// logic as scripts/map_dz_munic_cempre/server.R) into web/map_dz_munic_cempre/data/.
// Everything below runs client-side against those static files — no R
// server, no shinyapps.io.

(function () {
  "use strict";

  // ---- i18n strings (mirrors param$i18n in apps/app_map_dz_munic_cempre.R) ----

  const I18N = {
    pt: {
      plot_name: "Data Zoom Amazônia",
      plot_desc: "Compilação de dados ao nível municipal (CEMPRE)",
      label_var_name: "VARIÁVEIS:",
      label_x_name: "Seleciona variável (x)",
      label_year: "Ano referente",
      label_title: "Mapa dos municípios da Amazônia Legal",
      label_munic_name: "Nome do Município <b>",
      label_state_name: "Estado: <b>",
      label_measurement_unit: "Unidade de medida: <b>",
      label_no_data: "Sem dado",
      btn_compare: "Comparar anos",
      btn_compare_exit: "Sair da comparação",
      btn_snapshot: "Salvar imagem",
      btn_snapshot_busy: "Gerando imagem…",
      snapshot_error: "Não foi possível gerar a imagem. Veja o console para detalhes.",
      compare_vs: "vs.",
      btn_lang: "English"
    },
    en: {
      plot_name: "Data Zoom Amazônia",
      plot_desc: "Data compilation at municipality level (CEMPRE)",
      label_var_name: "VARIABLES:",
      label_x_name: "Select variable (x)",
      label_year: "Reference year",
      label_title: "Legal Amazon municipality map",
      label_munic_name: "Municipality name: <b>",
      label_state_name: "State: <b>",
      label_measurement_unit: "Measurement unit: <b>",
      label_no_data: "No data",
      btn_compare: "Compare years",
      btn_compare_exit: "Exit comparison",
      btn_snapshot: "Save image",
      btn_snapshot_busy: "Generating image…",
      snapshot_error: "Couldn't generate the image — see console for details.",
      compare_vs: "vs.",
      btn_lang: "Português"
    }
  };

  // Single-hue sequential ramp (green, ~170deg OKLCH hue — close to the
  // app's own #50A486/#48968B brand greens), light -> dark = low -> high.
  // Replaces the original reversed-viridis palette (yellow->purple), which
  // is a multi-hue rainbow ramp encoding magnitude — exactly what the
  // dataviz skill's color formula rules out ("Sequential = one hue,
  // light->dark. Never a rainbow.") Validated with the skill's own checker
  // as an ordinal ramp (these 9 stops render as discrete legend swatches,
  // not a continuous gradient, so --ordinal is the applicable check):
  // monotone lightness, adjacent ΔL >= 0.06, single hue (spread 2deg), and
  // light-end contrast 2.07:1 against a white legend surface (>= the 2:1
  // floor) — see data-raw/build_sequential_ramp.mjs for the generator.
  const PALETTE_CONTINUOUS = [
    "#a4b6af", "#82a799", "#659685", "#4b8571", "#35735f",
    "#23604e", "#154e3d", "#0b3b2e", "#052a1f"
  ];

  // "No data" gets a hatch texture, not a flat gray: at dE 8.8 (OKLab, the
  // dataviz skill's CVD-separation metric) the previous flat #cccccc sat
  // below even the CVD floor (6) against the lightest green bin — on a
  // choropleth, an under-vs-missing mixup is a real misread, not just an
  // aesthetic gap. NODATA_FILL colors the pattern itself (see
  // ensureNoDataPattern); its base clears the normal-vision floor (dE 15.4)
  // against the lightest bin, and the diagonal hatch is the accessibility
  // skill's texture channel — a second, hue-independent signal.
  const NODATA_PATTERN_ID = "nodata-hatch";
  const NODATA_BASE = "#e4e2dd";
  const NODATA_LINE = "#b8b5ae";

  const DATA_DIR = "data";
  const N_BINS = 9;
  const SPARK_W = 260;
  const SPARK_H = 40;
  const SPARK_PAD = 4;

  const state = {
    lang: "pt",
    x: null,
    year: null,
    playing: false,
    playTimer: null,
    compareMode: false,
    yearA: null,
    yearB: null,
    dividerFrac: 0.5
  };

  let map, legendControl;
  let municGeo, statesGeo, legalAmazonGeo, attributesByYear, dictionary, fullDomainByVar;

  // Built once in buildMapLayer(); year/variable/lang changes update these
  // layers in place (setStyle / setTooltipContent) instead of tearing down
  // and recreating the whole GeoJSON layer. That's what lets the CSS
  // transition on .muni-path actually animate — a fresh element every
  // frame has no "previous" fill to transition from.
  const layersByCodIbge = new Map();
  // Each municipality's centroid (bounds center), precomputed once — compare
  // mode needs "which side of the divider is this polygon on" on every
  // drag/pan/zoom, and re-deriving that from the full polygon geometry each
  // time would be needless work when the geometry never changes.
  const centroidByCodIbge = new Map();
  const breaksCache = {}; // var -> { breaks, colors }, since the domain (and so the bins) only depends on the variable, not the year
  let openTooltipLayer = null;
  let sparkSeries = [];
  let sparkXFor = null;
  let sparkYFor = null;

  // ---- Boot ----

  Promise.all([
    fetchJson(`${DATA_DIR}/municipalities.geojson`),
    fetchJson(`${DATA_DIR}/states_boundary.geojson`),
    fetchJson(`${DATA_DIR}/legal_amazon_boundary.geojson`),
    fetchJson(`${DATA_DIR}/attributes.json`),
    fetchJson(`${DATA_DIR}/dictionary.json`)
  ]).then(([munic, states, legalAmazon, attrs, dict]) => {
    municGeo = munic;
    statesGeo = states;
    legalAmazonGeo = legalAmazon;
    dictionary = dict;

    attributesByYear = groupByYear(attrs);
    fullDomainByVar = computeFullDomains(attrs, dict.pt.map((d) => d.var));

    initState();
    initMap();
    buildMapLayer();
    initControls();
    initSparklineHover();
    render();
    document.getElementById("spinner").classList.add("hidden");
  }).catch((err) => {
    console.error("Failed to load data", err);
    document.getElementById("spinner").classList.add("hidden");
    alert("Failed to load map data — see console. Did you run the export script and serve this folder over HTTP?");
  });

  function fetchJson(url) {
    return fetch(url).then((r) => {
      if (!r.ok) throw new Error(`${url}: ${r.status}`);
      return r.json();
    });
  }

  function groupByYear(rows) {
    const byYear = new Map();
    for (const row of rows) {
      if (!byYear.has(row.ano)) byYear.set(row.ano, new Map());
      byYear.get(row.ano).set(row.cod_ibge, row);
    }
    return byYear;
  }

  function computeFullDomains(rows, vars) {
    // Mirrors `domain = df[[input$x]]` in server.R: the color scale is
    // fit against values across ALL years, so bins stay stable while
    // scrubbing the year slider.
    const domains = {};
    for (const v of vars) domains[v] = [];
    for (const row of rows) {
      for (const v of vars) {
        const val = row[v];
        if (val !== null && val !== undefined && !Number.isNaN(val)) domains[v].push(val);
      }
    }
    return domains;
  }

  // ---- State init from query string (mirrors update_my_inputs() in server.R) ----

  function initState() {
    const params = new URLSearchParams(location.search);
    const qLang = params.get("lang");
    const qX = params.get("x");
    const qFilter = params.get("filter");

    state.lang = qLang === "en" ? "en" : "pt";
    state.x = dictionary.pt.some((d) => d.var === qX) ? qX : dictionary.pt[0].var;
    const qYear = qFilter ? parseInt(qFilter, 10) : NaN;
    state.year = Number.isFinite(qYear) && qYear >= dictionary.year_inicio && qYear <= dictionary.year_final
      ? qYear
      : dictionary.year_final;
  }

  function updateUrl() {
    const params = new URLSearchParams();
    params.set("lang", state.lang);
    params.set("x", state.x);
    params.set("filter", state.year);
    history.replaceState(null, "", `?${params.toString()}`);
  }

  // ---- Map setup ----

  function initMap() {
    map = L.map("map", { zoomControl: true }).setView([-7, -58], 5);

    // NOTE: the original app uses CartoDB.PositronNoLabels (no-label light
    // basemap), but Carto retired free anonymous raster tile access — that
    // style now needs an API key. Esri's World_Light_Gray_Base is the
    // closest free, no-key equivalent: light, minimal roads, no labels
    // fighting the choropleth for attention (stock OSM tiles are far busier).
    L.tileLayer("https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}", {
      attribution: "Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ",
      maxZoom: 16,
      // Esri's tile server sends Access-Control-Allow-Origin: * — this asks
      // the browser to actually fetch tiles in CORS mode instead of the
      // default opaque cross-origin request, which is what lets
      // captureSnapshot() draw them onto a canvas at all: an image loaded
      // without crossOrigin taints any canvas it's drawn to (toBlob/toDataURL
      // throw) regardless of what headers the server sends, and this can't
      // be fixed retroactively — it has to be set before the tile's first
      // fetch, i.e. here.
      crossOrigin: true
    }).addTo(map);

    // Explicit panes/z-index for every layer (rather than relying on add
    // order within the shared default pane) so stacking is guaranteed, not
    // incidental — this matters more once compare mode adds two more fill
    // layers that must both sit under the boundaries.
    map.createPane("paneMain");
    map.getPane("paneMain").style.zIndex = 400;
    map.createPane("paneBoundaries");
    map.getPane("paneBoundaries").style.zIndex = 450;

    L.geoJSON(statesGeo, { pane: "paneBoundaries", style: { color: "grey", weight: 1, fill: false }, interactive: false }).addTo(map);
    L.geoJSON(legalAmazonGeo, { pane: "paneBoundaries", style: { color: "black", weight: 2, fill: false }, interactive: false }).addTo(map);

    legendControl = L.control({ position: "bottomright" });
    legendControl.onAdd = function () {
      this._div = L.DomUtil.create("div", "legend");
      return this._div;
    };
    legendControl.addTo(map);
  }

  // ---- Controls ----

  function initControls() {
    const xSelect = document.getElementById("x-select");
    xSelect.addEventListener("change", () => {
      state.x = xSelect.value;
      updateUrl();
      render();
    });

    const slider = document.getElementById("year-slider");
    slider.min = dictionary.year_inicio;
    slider.max = dictionary.year_final;
    slider.addEventListener("input", () => {
      jumpToYear(parseInt(slider.value, 10));
    });

    document.getElementById("year-sparkline").addEventListener("click", (e) => {
      jumpToYear(yearFromPointerEvent(e));
    });

    document.getElementById("play-btn").addEventListener("click", togglePlay);
    document.getElementById("lang-toggle").addEventListener("click", () => {
      state.lang = state.lang === "pt" ? "en" : "pt";
      updateUrl();
      render();
    });

    document.getElementById("compare-toggle").addEventListener("click", () => {
      setCompareMode(!state.compareMode);
    });

    initCompareMarkers();
    initSwipeDivider();

    document.getElementById("snapshot-btn").addEventListener("click", captureSnapshot);
  }

  // Shared by the sparkline's click-to-jump and hover-preview: which year
  // does this pointer position (over the sparkline wrapper) correspond to.
  function yearFromPointerEvent(e) {
    const rect = document.querySelector(".sparkline-wrap").getBoundingClientRect();
    const frac = (e.clientX - rect.left) / rect.width;
    const year = Math.round(dictionary.year_inicio + frac * (dictionary.year_final - dictionary.year_inicio));
    return Math.min(dictionary.year_final, Math.max(dictionary.year_inicio, year));
  }

  // Hover crosshair + tooltip on the sparkline (dataviz skill's interaction
  // spec: "the crosshair finds the X" — a vertical hairline snaps to the
  // nearest data position, with a tooltip, independent of the persistent
  // .spark-guide/.spark-marker that mark the currently *selected* year).
  function initSparklineHover() {
    const wrap = document.querySelector(".sparkline-wrap");
    const hoverLine = document.getElementById("spark-hover-line");
    const hoverMarker = document.getElementById("spark-hover-marker");
    const tooltip = document.getElementById("spark-tooltip");

    wrap.addEventListener("pointermove", (e) => {
      if (!sparkXFor || state.compareMode) return; // compare mode has its own markers/guides for A and B
      const year = yearFromPointerEvent(e);
      const d = sparkSeries.find((s) => s.year === year);
      const svgX = sparkXFor(year);

      hoverLine.setAttribute("x1", svgX);
      hoverLine.setAttribute("x2", svgX);
      hoverLine.style.opacity = "1";

      const dict = dictionary[state.lang];
      const varMeta = dict.find((v) => v.var === state.x);
      const t = I18N[state.lang];

      if (d && d.value !== null) {
        hoverMarker.setAttribute("cx", svgX);
        hoverMarker.setAttribute("cy", sparkYFor(d.value));
        hoverMarker.style.opacity = "1";
        tooltip.innerHTML = "<strong>" + fmtNumber(d.value) + "</strong> " + varMeta.unidade + "<br>" + year;
      } else {
        hoverMarker.style.opacity = "0";
        tooltip.innerHTML = "<strong>" + year + "</strong><br>" + t.label_no_data;
      }

      const rect = wrap.getBoundingClientRect();
      const frac = Math.min(1, Math.max(0, (e.clientX - rect.left) / rect.width));
      tooltip.style.left = Math.min(rect.width - 4, Math.max(4, frac * rect.width)) + "px";
      tooltip.style.opacity = "1";
    });

    wrap.addEventListener("pointerleave", () => {
      hoverLine.style.opacity = "0";
      hoverMarker.style.opacity = "0";
      tooltip.style.opacity = "0";
    });
  }

  // ---- Compare mode: two draggable year markers on the sparkline (year A,
  // year B — an identity pair, categorical slots 1/2 blue/orange) driving a
  // swipe divider on the map. ----

  function initCompareMarkers() {
    const markerA = document.getElementById("spark-marker-a");
    const markerB = document.getElementById("spark-marker-b");
    let dragging = null; // "a" | "b" | null

    function onMove(e) {
      if (!dragging || !sparkXFor) return;
      const year = yearFromPointerEvent(e);
      if (dragging === "a") state.yearA = year; else state.yearB = year;
      updateCompareYearPositions();
      updateCompareColors();
      updateCompareLabels();
    }

    markerA.addEventListener("pointerdown", (e) => { dragging = "a"; markerA.setPointerCapture(e.pointerId); });
    markerB.addEventListener("pointerdown", (e) => { dragging = "b"; markerB.setPointerCapture(e.pointerId); });
    markerA.addEventListener("pointermove", onMove);
    markerB.addEventListener("pointermove", onMove);
    markerA.addEventListener("pointerup", () => { dragging = null; });
    markerB.addEventListener("pointerup", () => { dragging = null; });
  }

  function updateCompareYearPositions() {
    if (!sparkXFor) return;
    placeCompareMarker("a", state.yearA);
    placeCompareMarker("b", state.yearB);
  }

  function placeCompareMarker(which, year) {
    const marker = document.getElementById("spark-marker-" + which);
    const guide = document.getElementById("spark-guide-" + which);
    const x = sparkXFor(year);
    guide.setAttribute("x1", x);
    guide.setAttribute("x2", x);
    const d = sparkSeries.find((s) => s.year === year);
    if (d && d.value !== null) {
      marker.setAttribute("cx", x);
      marker.setAttribute("cy", sparkYFor(d.value));
      marker.setAttribute("opacity", "1");
    } else {
      marker.setAttribute("opacity", "0");
    }
  }

  function updateCompareLabels() {
    document.getElementById("compare-label-a").textContent = state.yearA;
    document.getElementById("compare-label-b").textContent = state.yearB;
  }

  function initSwipeDivider() {
    const handle = document.querySelector(".divider-handle");
    let dragging = false;

    handle.addEventListener("pointerdown", (e) => { dragging = true; handle.setPointerCapture(e.pointerId); });
    handle.addEventListener("pointerup", () => { dragging = false; });
    handle.addEventListener("pointermove", (e) => {
      if (!dragging) return;
      const rect = document.querySelector(".map-wrap").getBoundingClientRect();
      setDividerFrac((e.clientX - rect.left) / rect.width);
    });
  }

  function setDividerFrac(frac) {
    state.dividerFrac = Math.min(0.95, Math.max(0.05, frac));
    document.getElementById("swipe-divider").style.left = (state.dividerFrac * 100) + "%";
    if (state.compareMode) updateCompareColors();
  }

  // Recolors when the map pans/zooms: a municipality's *screen* position
  // relative to the divider is what decides which year it shows, so panning
  // moves the effective split even though state.dividerFrac hasn't changed.
  function onCompareMapMove() {
    if (state.compareMode) updateCompareColors();
  }

  function setCompareMode(on) {
    state.compareMode = on;
    document.querySelector(".apppanel").classList.toggle("compare-mode", on);
    document.getElementById("compare-toggle").classList.toggle("active", on);
    document.getElementById("compare-toggle-label").textContent =
      I18N[state.lang][on ? "btn_compare_exit" : "btn_compare"];

    if (on) {
      stopPlaying();
      // In case the single-year hover crosshair was mid-display when the
      // toggle was clicked — it stops updating in compare mode (see
      // initSparklineHover) but was already visible.
      document.getElementById("spark-hover-line").style.opacity = "0";
      document.getElementById("spark-hover-marker").style.opacity = "0";
      document.getElementById("spark-tooltip").style.opacity = "0";
      if (state.yearA == null) state.yearA = dictionary.year_inicio;
      if (state.yearB == null) state.yearB = dictionary.year_final;
      updateCompareYearPositions();
      updateCompareLabels();
      setDividerFrac(state.dividerFrac); // positions the handle + repaints via updateCompareColors()
      map.on("move zoom", onCompareMapMove);
    } else {
      map.off("move zoom", onCompareMapMove);
      updateMapColors();
    }
  }

  // Recolors and re-tooltips the SAME polygons the single-year map uses —
  // compare mode isn't a second map layer, just a different rule for which
  // year's data each polygon currently shows. A polygon whose *screen*
  // centroid sits left of the divider shows year A, right shows year B, so
  // dragging the divider (or panning/zooming the map, see
  // onCompareMapMove) changes the split live. Same breaks/colors as the
  // single-year map (the domain is fit across all years, not per-year —
  // see computeFullDomains), so year A and year B share one legend.
  //
  // (An earlier version tried two separate Leaflet layers in their own
  // panes, clipped with CSS clip-path to build the swipe visually. That
  // doesn't work: Leaflet's pane <div>s are deliberately unsized —
  // position:absolute with no explicit width/height, since the SVG/tile
  // children position themselves via their own transforms rather than
  // filling a box — so clip-path's percentage insets had no box to resolve
  // against and clipped everything to nothing. Recoloring one set of
  // polygons sidesteps that entirely.)
  function updateCompareColors() {
    const dict = dictionary[state.lang];
    const varMeta = dict.find((d) => d.var === state.x);
    const t = I18N[state.lang];
    const { breaks, colors } = getBreaksAndColors(state.x);
    const yearDataA = attributesByYear.get(state.yearA) || new Map();
    const yearDataB = attributesByYear.get(state.yearB) || new Map();
    const dividerX = state.dividerFrac * map.getSize().x;

    for (const [codIbge, layer] of layersByCodIbge) {
      const screenX = map.latLngToContainerPoint(centroidByCodIbge.get(codIbge)).x;
      const useA = screenX < dividerX;
      const year = useA ? state.yearA : state.yearB;
      const row = (useA ? yearDataA : yearDataB).get(codIbge);
      const value = row ? row[state.x] : null;
      const color = value === null || value === undefined || Number.isNaN(value)
        ? "url(#" + NODATA_PATTERN_ID + ")"
        : colors[binIndex(value, breaks)];

      layer.setStyle({ fillColor: color });
      layer.setTooltipContent([
        "<strong>", year, "</strong><br>",
        t.label_munic_name, row ? row.nm_municip : "—", "</b><br>",
        t.label_state_name, row ? row.estado : "—", "</b><br>",
        varMeta.label, ": <b>", fmtNumber(value), "</b><br>",
        t.label_measurement_unit, varMeta.unidade, "</b>"
      ].join(""));
    }

    renderLegend(breaks, colors, `${varMeta.label} (${varMeta.unidade})`, t.label_no_data);
  }

  // ---- Snapshot: composite the live map (basemap tiles + choropleth/
  // boundary SVG) onto a canvas, draw a title/legend on top from the same
  // app state the on-screen legend uses, and download it as a PNG. ----

  async function captureSnapshot() {
    const btn = document.getElementById("snapshot-btn");
    const label = document.getElementById("snapshot-btn-label");
    const t = I18N[state.lang];
    btn.disabled = true;
    label.textContent = t.btn_snapshot_busy;

    try {
      const dpr = window.devicePixelRatio || 1;
      const mapEl = document.getElementById("map");
      const mapRect = mapEl.getBoundingClientRect();

      const canvas = document.createElement("canvas");
      canvas.width = Math.round(mapRect.width * dpr);
      canvas.height = Math.round(mapRect.height * dpr);
      const ctx = canvas.getContext("2d");
      ctx.scale(dpr, dpr);

      // Basemap tiles. Each tile's getBoundingClientRect() already reflects
      // Leaflet's internal pane/tile transforms post-resolution, so drawing
      // at that rect (relative to the map container) lines up correctly
      // without re-deriving any of Leaflet's own transform math.
      const tiles = mapEl.querySelectorAll(".leaflet-tile-pane img.leaflet-tile-loaded");
      for (const tile of tiles) {
        const r = tile.getBoundingClientRect();
        try {
          ctx.drawImage(tile, r.left - mapRect.left, r.top - mapRect.top, r.width, r.height);
        } catch (err) {
          // A tainted or not-yet-decoded tile — skip it rather than losing
          // the whole capture over one missing tile.
          console.warn("Snapshot: skipped a tile", err);
        }
      }

      // Choropleth fill + state/country boundaries: each of our two map-data
      // panes (paneMain, paneBoundaries) gets its own <svg> root. Serializing
      // and redrawing each as an image is simpler and more robust than
      // walking Leaflet's internal layer objects, and needs no CORS handling
      // since it's an inline data: URI.
      //
      // Scoped to those two panes specifically, not a blanket "#map svg":
      // that also matches Leaflet's own UI-chrome SVGs (e.g. the tiny 12x8
      // flag icon in the attribution control), which would otherwise get
      // rasterized and stamped onto the map content at whatever screen
      // position that control happens to occupy.
      const svgs = mapEl.querySelectorAll(".leaflet-paneMain-pane svg, .leaflet-paneBoundaries-pane svg");
      for (const svg of svgs) {
        const r = svg.getBoundingClientRect();
        const svgText = new XMLSerializer().serializeToString(svg);
        const img = await loadImage("data:image/svg+xml;charset=utf-8," + encodeURIComponent(svgText));
        ctx.drawImage(img, r.left - mapRect.left, r.top - mapRect.top, r.width, r.height);
      }

      drawSnapshotOverlay(ctx, mapRect.width, mapRect.height);

      const blob = await new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = snapshotFilename();
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    } catch (err) {
      console.error("Snapshot failed", err);
      alert(t.snapshot_error);
    } finally {
      btn.disabled = false;
      label.textContent = t.btn_snapshot;
    }
  }

  function loadImage(src) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = reject;
      img.src = src;
    });
  }

  function snapshotFilename() {
    const stamp = new Date().toISOString().replace(/[:T]/g, "-").slice(0, 19);
    const yearPart = state.compareMode ? `${state.yearA}-vs-${state.yearB}` : String(state.year);
    return `datazoom_cempre_${state.x}_${yearPart}_${stamp}.png`;
  }

  // Everything baked into the exported image beyond the raw map pixels:
  // title, the year (or year A vs year B + divider), the legend, and
  // attribution — all read from the same state/dictionary the on-screen UI
  // uses, not scraped from the DOM.
  function drawSnapshotOverlay(ctx, width, height) {
    const t = I18N[state.lang];
    const dict = dictionary[state.lang];
    const varMeta = dict.find((d) => d.var === state.x);
    const { breaks, colors } = getBreaksAndColors(state.x);
    const fontUi = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif";

    ctx.textBaseline = "top";
    ctx.fillStyle = "rgba(255,255,255,0.92)";
    ctx.fillRect(0, 0, width, 52);
    ctx.fillStyle = "#17211c";
    ctx.font = `700 15px ${fontUi}`;
    ctx.fillText(t.label_title, 12, 8);

    ctx.font = `400 12px ${fontUi}`;
    ctx.fillStyle = "#555";
    const subtitle = state.compareMode
      ? `${varMeta.label} — ${state.yearA} ${t.compare_vs} ${state.yearB}`
      : `${t.label_var_name} ${varMeta.label} (${state.year})`;
    ctx.fillText(subtitle, 12, 29);

    if (state.compareMode) {
      const dividerX = state.dividerFrac * width;
      ctx.strokeStyle = "#ffffff";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(dividerX, 52);
      ctx.lineTo(dividerX, height);
      ctx.stroke();

      ctx.font = `700 12px ${fontUi}`;
      drawBadge(ctx, fontUi, 10, 90, String(state.yearA), "#2a78d6");
      const bWidth = ctx.measureText(String(state.yearB)).width + 20;
      drawBadge(ctx, fontUi, width - 10 - bWidth, 90, String(state.yearB), "#eb6834");
    }

    drawLegendOnCanvas(ctx, fontUi, width, height, breaks, colors, `${varMeta.label} (${varMeta.unidade})`, t.label_no_data);

    ctx.font = `400 10px ${fontUi}`;
    ctx.fillStyle = "rgba(0,0,0,0.55)";
    ctx.textAlign = "right";
    ctx.fillText("Tiles © Esri — Esri, DeLorme, NAVTEQ | Leaflet | datazoom.com.br/amazonia", width - 6, height - 14);
    ctx.textAlign = "left";
  }

  function drawBadge(ctx, fontUi, x, y, text, color) {
    ctx.font = `700 12px ${fontUi}`;
    const padding = 10;
    const w = ctx.measureText(text).width + padding * 2;
    const h = 22;
    roundRectPath(ctx, x, y, w, h, 11);
    ctx.fillStyle = color;
    ctx.fill();
    ctx.fillStyle = "#fff";
    ctx.textBaseline = "middle";
    ctx.fillText(text, x + padding, y + h / 2 + 1);
    ctx.textBaseline = "top";
  }

  function roundRectPath(ctx, x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }

  function wrapCanvasText(ctx, text, maxWidth) {
    const words = text.split(" ");
    const lines = [];
    let line = "";
    for (const word of words) {
      const test = line ? line + " " + word : word;
      if (line && ctx.measureText(test).width > maxWidth) {
        lines.push(line);
        line = word;
      } else {
        line = test;
      }
    }
    if (line) lines.push(line);
    return lines;
  }

  function drawLegendOnCanvas(ctx, fontUi, width, height, breaks, colors, title, noDataLabel) {
    const pad = 10;
    const rowH = 18;
    const swatch = 14;
    const boxW = 232;
    const innerW = boxW - pad * 2 - swatch - 6;

    ctx.font = `700 12px ${fontUi}`;
    const titleLines = wrapCanvasText(ctx, title, boxW - pad * 2);

    const rows = colors.length + 1; // + no-data row
    const boxH = pad * 2 + titleLines.length * 16 + 4 + rows * rowH;
    const boxX = width - boxW - 10;
    const boxY = height - boxH - 10;

    ctx.fillStyle = "rgba(255,255,255,0.95)";
    roundRectPath(ctx, boxX, boxY, boxW, boxH, 6);
    ctx.fill();
    ctx.strokeStyle = "rgba(0,0,0,0.12)";
    ctx.lineWidth = 1;
    ctx.stroke();

    let cy = boxY + pad;
    ctx.fillStyle = "#17211c";
    ctx.font = `700 12px ${fontUi}`;
    for (const line of titleLines) {
      ctx.fillText(line, boxX + pad, cy);
      cy += 16;
    }
    cy += 4;

    ctx.font = `400 11px ${fontUi}`;
    for (let i = colors.length - 1; i >= 0; i--) {
      ctx.fillStyle = colors[i];
      ctx.fillRect(boxX + pad, cy + 2, swatch, swatch);
      ctx.fillStyle = "#17211c";
      const label = `${fmtNumber(breaks[i])} – ${fmtNumber(breaks[i + 1])}`;
      ctx.fillText(wrapCanvasText(ctx, label, innerW)[0], boxX + pad + swatch + 6, cy + 3);
      cy += rowH;
    }

    // "No data" row, matching the hatch swatch used on the map/legend.
    ctx.fillStyle = "#e4e2dd";
    ctx.fillRect(boxX + pad, cy + 2, swatch, swatch);
    ctx.strokeStyle = "#b8b5ae";
    ctx.beginPath();
    ctx.moveTo(boxX + pad, cy + 2 + swatch);
    ctx.lineTo(boxX + pad + swatch, cy + 2);
    ctx.stroke();
    ctx.fillStyle = "#17211c";
    ctx.fillText(noDataLabel, boxX + pad + swatch + 6, cy + 3);
  }

  // Applies state.year to every year-dependent bit of UI (slider position,
  // map colors, sparkline marker) without touching the play/pause state —
  // this is the tick handler for autoplay.
  function applyYear(newYear) {
    state.year = newYear;
    document.getElementById("year-slider").value = newYear;
    document.getElementById("year-value").textContent = newYear;
    updateUrl();
    updateMapColors();
    updateSparklineMarker();
  }

  // User-initiated seek (slider drag, sparkline click) — also stops autoplay.
  function jumpToYear(newYear) {
    stopPlaying();
    applyYear(newYear);
  }

  function togglePlay() {
    state.playing = !state.playing;
    const btn = document.getElementById("play-btn");
    btn.classList.toggle("playing", state.playing);
    btn.innerHTML = state.playing ? "&#10074;&#10074;" : "&#9654;";

    if (state.playing) {
      state.playTimer = setInterval(() => {
        if (state.year >= dictionary.year_final) {
          stopPlaying();
          return;
        }
        applyYear(state.year + 1);
      }, 5000);
    } else {
      clearInterval(state.playTimer);
    }
  }

  function stopPlaying() {
    if (!state.playing) return;
    state.playing = false;
    clearInterval(state.playTimer);
    const btn = document.getElementById("play-btn");
    btn.classList.remove("playing");
    btn.innerHTML = "&#9654;";
  }

  // ---- Rendering ----

  function render() {
    const t = I18N[state.lang];
    const dict = dictionary[state.lang];

    document.getElementById("plot_name").textContent = t.plot_name;
    document.getElementById("plot_desc").textContent = t.plot_desc;
    document.getElementById("label_var_name").textContent = t.label_var_name;
    document.getElementById("label_x_name").textContent = t.label_x_name;
    document.getElementById("label_year").textContent = t.label_year;
    document.getElementById("plot-title").textContent = t.label_title;
    document.getElementById("lang-toggle-label").textContent = t.btn_lang;
    if (!document.getElementById("snapshot-btn").disabled) {
      document.getElementById("snapshot-btn-label").textContent = t.btn_snapshot;
    }

    const xSelect = document.getElementById("x-select");
    const prevValue = state.x;
    xSelect.innerHTML = "";
    for (const entry of dict) {
      const opt = document.createElement("option");
      opt.value = entry.var;
      opt.textContent = entry.label;
      xSelect.appendChild(opt);
    }
    xSelect.value = prevValue;

    const slider = document.getElementById("year-slider");
    slider.value = state.year;
    document.getElementById("year-value").textContent = state.year;

    const varMeta = dict.find((d) => d.var === state.x);
    document.getElementById("plot-subtitle").textContent = `${t.label_var_name} ${varMeta.label}`;

    document.getElementById("compare-toggle-label").textContent =
      t[state.compareMode ? "btn_compare_exit" : "btn_compare"];

    renderSparkline();
    if (state.compareMode) {
      updateCompareYearPositions();
      updateCompareColors();
      updateCompareLabels();
    } else {
      updateMapColors();
    }
  }

  // Builds the 772 municipality polygons ONCE, wiring up hover/tooltip
  // behavior that doesn't change across renders. Every subsequent
  // variable/year/lang change goes through updateMapColors() instead of
  // rebuilding this layer — see the layersByCodIbge comment above.
  // Injects an SVG <pattern> for the "no data" fill into Leaflet's own SVG
  // renderer, so polygons can set fillColor to `url(#nodata-hatch)` — a
  // valid SVG paint reference, same as any other setStyle value. Must run
  // after the first polygon layer exists (that's what makes Leaflet create
  // its SVG root).
  function ensureNoDataPattern() {
    var svg = document.querySelector("#map svg");
    if (!svg || svg.querySelector("#" + NODATA_PATTERN_ID)) return;
    var defs = document.createElementNS("http://www.w3.org/2000/svg", "defs");
    defs.innerHTML =
      '<pattern id="' + NODATA_PATTERN_ID + '" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">' +
      '<rect width="6" height="6" fill="' + NODATA_BASE + '"></rect>' +
      '<line x1="0" y1="0" x2="0" y2="6" stroke="' + NODATA_LINE + '" stroke-width="2"></line>' +
      "</pattern>";
    svg.insertBefore(defs, svg.firstChild);
  }

  // Builds the 772 municipality polygons ONCE, wiring up hover/tooltip
  // behavior that doesn't change across renders. Every subsequent
  // variable/year/lang/compare change goes through updateMapColors() or
  // updateCompareColors() instead of rebuilding this layer — see the
  // layersByCodIbge comment above.
  function buildMapLayer() {
    L.geoJSON(municGeo, {
      pane: "paneMain",
      style: () => ({
        className: "muni-path",
        stroke: false,
        fillOpacity: 0.9,
        fillColor: "#cccccc" // placeholder; the first color update repaints before this ever renders a frame
      }),
      onEachFeature: (feature, layer) => {
        layersByCodIbge.set(feature.properties.cod_ibge, layer);
        centroidByCodIbge.set(feature.properties.cod_ibge, layer.getBounds().getCenter());
        layer.bindTooltip("", { sticky: true });

        layer.on("mouseover", () => {
          if (openTooltipLayer && openTooltipLayer !== layer) openTooltipLayer.closeTooltip();
          openTooltipLayer = layer;
          layer.setStyle({ stroke: true, weight: 5, color: "black", opacity: 1, fillOpacity: 1 });
          layer.bringToFront();
        });
        layer.on("mouseout", () => {
          if (openTooltipLayer === layer) openTooltipLayer = null;
          // Explicit rest style rather than layer.resetStyle(): resetStyle
          // reverts to the style captured when the layer was created, which
          // would snap fillColor back to the very first year ever shown
          // instead of the current one. Omitting fillColor here keeps
          // whatever the last color update set (setStyle merges options).
          layer.setStyle({ stroke: false, fillOpacity: 0.9 });
        });
      }
    }).addTo(map);

    ensureNoDataPattern();
  }

  function getBreaksAndColors(varName) {
    if (!breaksCache[varName]) {
      const breaks = prettyBreaks(fullDomainByVar[varName], N_BINS);
      const colors = samplePalette(PALETTE_CONTINUOUS, breaks.length - 1);
      breaksCache[varName] = { breaks, colors };
    }
    return breaksCache[varName];
  }

  // Re-colors and re-tooltips the existing polygons for the current
  // variable/year/lang. Changing only `fillColor` on an already-mounted
  // <path> (rather than replacing the element) is what makes the
  // .muni-path CSS transition animate the year-to-year change.
  function updateMapColors() {
    const dict = dictionary[state.lang];
    const varMeta = dict.find((d) => d.var === state.x);
    const t = I18N[state.lang];
    const { breaks, colors } = getBreaksAndColors(state.x);
    const yearData = attributesByYear.get(state.year) || new Map();

    for (const [codIbge, layer] of layersByCodIbge) {
      const row = yearData.get(codIbge);
      const value = row ? row[state.x] : null;
      const color = value === null || value === undefined || Number.isNaN(value)
        ? "url(#" + NODATA_PATTERN_ID + ")"
        : colors[binIndex(value, breaks)];

      layer.setStyle({ fillColor: color });
      layer.setTooltipContent([
        t.label_munic_name, row ? row.nm_municip : "—", "</b><br>",
        t.label_state_name, row ? row.estado : "—", "</b><br>",
        varMeta.label, ": <b>", fmtNumber(value), "</b><br>",
        t.label_measurement_unit, varMeta.unidade, "</b>"
      ].join(""));
    }

    renderLegend(breaks, colors, `${varMeta.label} (${varMeta.unidade})`, t.label_no_data);
  }

  // ---- Sparkline: total value per year for the selected variable, above
  // the slider. Lets you see the shape of the series before scrubbing, and
  // click any point on it to jump straight there. ----

  function computeYearSeries(varName) {
    const series = [];
    for (let y = dictionary.year_inicio; y <= dictionary.year_final; y++) {
      const yearData = attributesByYear.get(y);
      let sum = 0;
      let has = false;
      if (yearData) {
        for (const row of yearData.values()) {
          const v = row[varName];
          if (v !== null && v !== undefined && !Number.isNaN(v)) {
            sum += v;
            has = true;
          }
        }
      }
      series.push({ year: y, value: has ? sum : null });
    }
    return series;
  }

  function renderSparkline() {
    sparkSeries = computeYearSeries(state.x);
    const values = sparkSeries.map((d) => d.value).filter((v) => v !== null);
    const minV = Math.min(...values);
    const maxV = Math.max(...values);

    sparkXFor = (year) => ((year - dictionary.year_inicio) / (dictionary.year_final - dictionary.year_inicio)) * SPARK_W;
    sparkYFor = (value) => (maxV === minV
      ? SPARK_H / 2
      : SPARK_PAD + (1 - (value - minV) / (maxV - minV)) * (SPARK_H - 2 * SPARK_PAD));

    const known = sparkSeries.filter((d) => d.value !== null);
    const pts = known.map((d) => `${sparkXFor(d.year).toFixed(1)},${sparkYFor(d.value).toFixed(1)}`);

    document.getElementById("spark-line").setAttribute("d", pts.length ? `M${pts.join(" L")}` : "");
    document.getElementById("spark-area").setAttribute("d", pts.length
      ? `M${sparkXFor(known[0].year).toFixed(1)},${SPARK_H} L${pts.join(" L")} L${sparkXFor(known[known.length - 1].year).toFixed(1)},${SPARK_H} Z`
      : "");

    updateSparklineMarker();
  }

  function updateSparklineMarker() {
    if (!sparkXFor) return;
    const x = sparkXFor(state.year);
    const guide = document.getElementById("spark-guide");
    guide.setAttribute("x1", x);
    guide.setAttribute("x2", x);

    const d = sparkSeries.find((d) => d.year === state.year);
    const marker = document.getElementById("spark-marker");
    if (d && d.value !== null) {
      marker.setAttribute("cx", x);
      marker.setAttribute("cy", sparkYFor(d.value));
      marker.setAttribute("opacity", "1");
    } else {
      marker.setAttribute("opacity", "0");
    }
  }

  function renderLegend(breaks, colors, title, noDataLabel) {
    const div = legendControl._div;
    let html = `<div class="legend-title">${title}</div>`;
    for (let i = colors.length - 1; i >= 0; i--) {
      html += `<div class="legend-row"><span class="swatch" style="background:${colors[i]}"></span>${fmtNumber(breaks[i])} &ndash; ${fmtNumber(breaks[i + 1])}</div>`;
    }
    html += `<div class="legend-row"><span class="swatch swatch-nodata"></span>${noDataLabel}</div>`;
    div.innerHTML = html;
  }

  // ---- Color scale helpers (approximates leaflet::colorBin(bins = 9)) ----

  function prettyBreaks(values, n) {
    if (!values.length) return [0, 1];
    const min = Math.min(...values);
    const max = Math.max(...values);
    if (min === max) return [min, min + 1];

    const rawStep = (max - min) / n;
    const mag = Math.pow(10, Math.floor(Math.log10(rawStep)));
    const norm = rawStep / mag;
    let niceNorm;
    if (norm < 1.5) niceNorm = 1;
    else if (norm < 3) niceNorm = 2;
    else if (norm < 7) niceNorm = 5;
    else niceNorm = 10;
    const step = niceNorm * mag;

    const niceMin = Math.floor(min / step) * step;
    const niceMax = Math.ceil(max / step) * step;

    const breaks = [];
    for (let v = niceMin; v <= niceMax + step / 2; v += step) {
      breaks.push(Math.round(v * 1e6) / 1e6);
    }
    return breaks;
  }

  function binIndex(value, breaks) {
    for (let i = 0; i < breaks.length - 1; i++) {
      if (value <= breaks[i + 1]) return i;
    }
    return breaks.length - 2;
  }

  function samplePalette(colors, n) {
    if (n <= 1) return [colors[colors.length - 1]];
    const result = [];
    for (let i = 0; i < n; i++) {
      const t = i / (n - 1);
      const pos = t * (colors.length - 1);
      const lo = Math.floor(pos);
      const hi = Math.ceil(pos);
      result.push(lo === hi ? colors[lo] : lerpHex(colors[lo], colors[hi], pos - lo));
    }
    return result;
  }

  function lerpHex(a, b, t) {
    const ca = hexToRgb(a), cb = hexToRgb(b);
    const r = Math.round(ca.r + (cb.r - ca.r) * t);
    const g = Math.round(ca.g + (cb.g - ca.g) * t);
    const bch = Math.round(ca.b + (cb.b - ca.b) * t);
    return `rgb(${r},${g},${bch})`;
  }

  function hexToRgb(hex) {
    const v = parseInt(hex.slice(1), 16);
    return { r: (v >> 16) & 255, g: (v >> 8) & 255, b: v & 255 };
  }

  function fmtNumber(x) {
    if (x === null || x === undefined || Number.isNaN(x)) return "";
    return Number(x).toLocaleString("pt-BR", { maximumFractionDigits: 2 });
  }
})();
