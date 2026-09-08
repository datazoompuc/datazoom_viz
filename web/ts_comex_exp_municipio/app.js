// Data Zoom Amazônia — app_ts_comex_exp_municipio, JS rebuild PoC
//
// Static rebuild of the Shiny app: data is pre-exported by
// data-raw/export_ts_comex_exp_municipio_web.R into web/ts_comex_exp_municipio/data/.
// Everything below runs client-side against those static files — no R
// server, no shinyapps.io.
//
// v1 scope: the ranked bar chart view only (top-N municipalities by export
// value for a selected year, with a year slider/play). The composition
// (stacked-area) and per-entity trend views are follow-up work — see the
// brainstorm in the PR/conversation history for the full plan.

(function () {
  "use strict";

  const I18N = {
    pt: {
      plot_name: "Data Zoom Amazônia",
      plot_desc: "Comércio exterior na Amazônia (COMEX): valor da exportação por município",
      label_topn_name: "Municípios exibidos",
      label_year: "Ano",
      label_title: "Ranking de municípios exportadores",
      label_subtitle: "Valor exportado (US$), por município",
      ranking_axis_label: "Valor exportado (US$)",
      region_total_prefix: "Total Amazônia Legal: ",
      label_no_data: "Sem dado",
      btn_lang: "English"
    },
    en: {
      plot_name: "Data Zoom Amazônia",
      plot_desc: "External trade in the Amazon (COMEX): export value by municipality",
      label_topn_name: "Municipalities shown",
      label_year: "Year",
      label_title: "Ranking of exporting municipalities",
      label_subtitle: "Export value (US$), by municipality",
      ranking_axis_label: "Export value (US$)",
      region_total_prefix: "Legal Amazon total: ",
      label_no_data: "No data",
      btn_lang: "Português"
    }
  };

  const DATA_DIR = "data";
  const PLAY_INTERVAL_MS = 900;
  const SPARK_W = 260;
  const SPARK_H = 40;
  const SPARK_PAD = 4;

  const state = {
    lang: "pt",
    year: null,
    topN: 15,
    playing: false,
    playTimer: null
  };

  let dictionary, municipalityTotals, regionTotals;
  let totalsByYear; // year -> [{municipio, valor}], sorted descending
  let regionTotalByYear; // year -> valor
  let sparkSeries = [];
  let sparkXFor = null;
  let sparkYFor = null;

  Promise.all([
    fetchJson(`${DATA_DIR}/dictionary.json`),
    fetchJson(`${DATA_DIR}/municipality_totals.json`),
    fetchJson(`${DATA_DIR}/region_totals.json`)
  ]).then(([dict, munTotals, regTotals]) => {
    dictionary = dict;
    municipalityTotals = munTotals;
    regionTotals = regTotals;

    totalsByYear = groupByYear(municipalityTotals);
    regionTotalByYear = new Map(regionTotals.map((r) => [r.ano, r.valor]));

    initState();
    initControls();
    initSparklineHover();
    render();
    document.getElementById("spinner").classList.add("hidden");
  }).catch((err) => {
    console.error("Failed to load data", err);
    document.getElementById("spinner").classList.add("hidden");
    alert("Failed to load app data — see console. Did you run the export script and serve this folder over HTTP?");
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
      if (!byYear.has(row.ano)) byYear.set(row.ano, []);
      byYear.get(row.ano).push(row);
    }
    for (const list of byYear.values()) list.sort((a, b) => b.valor - a.valor);
    return byYear;
  }

  // ---- State init from query string ----

  function initState() {
    const params = new URLSearchParams(location.search);
    const qLang = params.get("lang");
    const qYear = parseInt(params.get("year"), 10);
    const qTopN = parseInt(params.get("topn"), 10);

    state.lang = qLang === "en" ? "en" : "pt";
    state.year = Number.isFinite(qYear) && qYear >= dictionary.year_inicio && qYear <= dictionary.year_final
      ? qYear
      : dictionary.year_final;
    state.topN = [10, 15, 20, 30].includes(qTopN) ? qTopN : 15;
  }

  function updateUrl() {
    const params = new URLSearchParams();
    params.set("lang", state.lang);
    params.set("year", state.year);
    params.set("topn", state.topN);
    history.replaceState(null, "", `?${params.toString()}`);
  }

  // ---- Controls ----

  function initControls() {
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

    document.getElementById("topn-select").value = String(state.topN);
    document.getElementById("topn-select").addEventListener("change", (e) => {
      state.topN = parseInt(e.target.value, 10);
      updateUrl();
      renderRanking();
    });
  }

  function yearFromPointerEvent(e) {
    const rect = document.querySelector(".sparkline-wrap").getBoundingClientRect();
    const frac = (e.clientX - rect.left) / rect.width;
    const year = Math.round(dictionary.year_inicio + frac * (dictionary.year_final - dictionary.year_inicio));
    return Math.min(dictionary.year_final, Math.max(dictionary.year_inicio, year));
  }

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

      const t = I18N[state.lang];

      if (d && d.value !== null) {
        hoverMarker.setAttribute("cx", svgX);
        hoverMarker.setAttribute("cy", sparkYFor(d.value));
        hoverMarker.style.opacity = "1";
        tooltip.innerHTML = "<strong>" + fmtAbbrev(d.value) + "</strong><br>" + year;
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

  function applyYear(newYear) {
    state.year = newYear;
    document.getElementById("year-slider").value = newYear;
    document.getElementById("year-value").textContent = newYear;
    updateUrl();
    renderRanking();
    updateSparklineMarker();
  }

  function jumpToYear(newYear) {
    stopPlaying();
    applyYear(newYear);
  }

  function togglePlay() {
    state.playing = !state.playing;
    const btn = document.getElementById("play-btn");
    btn.classList.toggle("playing", state.playing);
    btn.innerHTML = state.playing ? PAUSE_ICON_SVG : PLAY_ICON_SVG;

    if (state.playing) {
      if (state.year >= dictionary.year_final) {
        applyYear(dictionary.year_inicio);
      }
      state.playTimer = setInterval(() => {
        if (state.year >= dictionary.year_final) {
          stopPlaying();
          return;
        }
        applyYear(state.year + 1);
      }, PLAY_INTERVAL_MS);
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
    btn.innerHTML = PLAY_ICON_SVG;
  }

  const PLAY_ICON_SVG = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>';
  const PAUSE_ICON_SVG = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="6" y="4" width="4" height="16"></rect><rect x="14" y="4" width="4" height="16"></rect></svg>';

  // ---- Rendering ----

  function render() {
    const t = I18N[state.lang];

    document.getElementById("plot_name").textContent = t.plot_name;
    document.getElementById("plot_desc").textContent = t.plot_desc;
    document.getElementById("label_year").textContent = t.label_year;
    document.getElementById("label_topn_name").textContent = t.label_topn_name;
    document.getElementById("plot-title").textContent = t.label_title;
    document.getElementById("plot-subtitle").textContent = t.label_subtitle;
    document.getElementById("ranking-axis-label").textContent = t.ranking_axis_label;
    document.getElementById("lang-toggle-label").textContent = t.btn_lang;

    const slider = document.getElementById("year-slider");
    slider.value = state.year;
    document.getElementById("year-value").textContent = state.year;

    renderSparkline();
    renderRanking();
  }

  function renderRanking() {
    const t = I18N[state.lang];
    const rows = totalsByYear.get(state.year) || [];
    const top = rows.slice(0, state.topN);
    const maxVal = top.length ? top[0].valor : 1;

    const regionTotal = regionTotalByYear.get(state.year);
    document.getElementById("region-total-label").innerHTML =
      regionTotal != null ? t.region_total_prefix + "<b>" + fmtAbbrev(regionTotal) + "</b>" : "";

    const container = document.getElementById("ranking-rows");
    container.innerHTML = "";
    const frag = document.createDocumentFragment();
    top.forEach((row, i) => frag.appendChild(buildRankRow(row, i, maxVal)));
    container.appendChild(frag);
  }

  function buildRankRow(row, index, maxVal) {
    const el = document.createElement("div");
    el.className = "rank-row";

    const pos = document.createElement("div");
    pos.className = "rank-position";
    pos.textContent = (index + 1) + ".";
    el.appendChild(pos);

    const label = document.createElement("div");
    label.className = "rank-label";
    label.textContent = row.municipio;
    label.title = row.municipio;
    el.appendChild(label);

    const track = document.createElement("div");
    track.className = "rank-track";
    const bar = document.createElement("div");
    bar.className = "rank-bar";
    bar.style.width = (maxVal > 0 ? (row.valor / maxVal) * 100 : 0) + "%";
    track.appendChild(bar);
    el.appendChild(track);

    const value = document.createElement("div");
    value.className = "rank-value";
    value.textContent = fmtAbbrev(row.valor);
    el.appendChild(value);

    el.addEventListener("pointerenter", (e) => showRankTooltip(e, row, index));
    el.addEventListener("pointermove", moveRankTooltip);
    el.addEventListener("pointerleave", hideRankTooltip);

    return el;
  }

  function showRankTooltip(e, row, index) {
    const tooltip = document.getElementById("ranking-tooltip");
    tooltip.innerHTML =
      "<strong>" + row.municipio + "</strong><br>" +
      "#" + (index + 1) + " · US$ " + fmtNumber(row.valor);
    tooltip.style.opacity = "1";
    moveRankTooltip(e);
  }

  function moveRankTooltip(e) {
    const tooltip = document.getElementById("ranking-tooltip");
    const panelRect = document.getElementById("ranking-panel").getBoundingClientRect();
    tooltip.style.left = (e.clientX - panelRect.left + 12) + "px";
    tooltip.style.top = (e.clientY - panelRect.top + 12) + "px";
  }

  function hideRankTooltip() {
    document.getElementById("ranking-tooltip").style.opacity = "0";
  }

  // ---- Sparkline: region-wide total export value per year ----

  function renderSparkline() {
    sparkSeries = regionTotals.map((r) => ({ year: r.ano, value: r.valor }));
    const values = sparkSeries.map((d) => d.value);
    const minV = Math.min(...values);
    const maxV = Math.max(...values);

    sparkXFor = (year) => ((year - dictionary.year_inicio) / (dictionary.year_final - dictionary.year_inicio)) * SPARK_W;
    sparkYFor = (value) => (maxV === minV
      ? SPARK_H / 2
      : SPARK_PAD + (1 - (value - minV) / (maxV - minV)) * (SPARK_H - 2 * SPARK_PAD));

    const pts = sparkSeries.map((d) => `${sparkXFor(d.year).toFixed(1)},${sparkYFor(d.value).toFixed(1)}`);

    document.getElementById("spark-line").setAttribute("d", pts.length ? `M${pts.join(" L")}` : "");
    document.getElementById("spark-area").setAttribute("d", pts.length
      ? `M${sparkXFor(sparkSeries[0].year).toFixed(1)},${SPARK_H} L${pts.join(" L")} L${sparkXFor(sparkSeries[sparkSeries.length - 1].year).toFixed(1)},${SPARK_H} Z`
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

  // ---- Formatting ----

  function fmtNumber(x) {
    if (x === null || x === undefined || Number.isNaN(x)) return "";
    return Number(x).toLocaleString("pt-BR", { maximumFractionDigits: 0 });
  }

  // Abbreviated US$ value for dense displays (ranking rows, sparkline
  // tooltip, region total) — full precision is one hover away in the row
  // tooltip. bi/mi/mil follow PT-BR convention; en labels reuse the same
  // magnitude words since this is a bilingual number, not translated text.
  function fmtAbbrev(x) {
    if (x === null || x === undefined || Number.isNaN(x)) return "";
    const abs = Math.abs(x);
    const fmt1 = (v) => v.toLocaleString("pt-BR", { minimumFractionDigits: 1, maximumFractionDigits: 1 });
    if (abs >= 1e9) return "US$ " + fmt1(x / 1e9) + " bi";
    if (abs >= 1e6) return "US$ " + fmt1(x / 1e6) + " mi";
    if (abs >= 1e3) return "US$ " + fmt1(x / 1e3) + " mil";
    return "US$ " + fmtNumber(x);
  }
})();
