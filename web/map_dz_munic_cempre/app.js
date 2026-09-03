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
    playTimer: null
  };

  let map, legendControl;
  let municGeo, statesGeo, legalAmazonGeo, attributesByYear, dictionary, fullDomainByVar;

  // Built once in buildMapLayer(); year/variable/lang changes update these
  // layers in place (setStyle / setTooltipContent) instead of tearing down
  // and recreating the whole GeoJSON layer. That's what lets the CSS
  // transition on .muni-path actually animate — a fresh element every
  // frame has no "previous" fill to transition from.
  const layersByCodIbge = new Map();
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
      maxZoom: 16
    }).addTo(map);

    L.geoJSON(statesGeo, { style: { color: "grey", weight: 1, fill: false }, interactive: false }).addTo(map);
    L.geoJSON(legalAmazonGeo, { style: { color: "black", weight: 2, fill: false }, interactive: false }).addTo(map);

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
      if (!sparkXFor) return;
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

    renderSparkline();
    updateMapColors();
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

  function buildMapLayer() {
    L.geoJSON(municGeo, {
      style: () => ({
        className: "muni-path",
        stroke: false,
        fillOpacity: 0.9,
        fillColor: "#cccccc" // placeholder; updateMapColors() repaints before this ever renders a frame
      }),
      onEachFeature: (feature, layer) => {
        layersByCodIbge.set(feature.properties.cod_ibge, layer);
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
          // whatever updateMapColors() last set (setStyle merges options).
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
