// Data Zoom Amazônia — app_ts_comex_exp_municipio, JS rebuild PoC
//
// Static rebuild of the Shiny app: data is pre-exported by
// data-raw/export_ts_comex_exp_municipio_web.R into web/ts_comex_exp_municipio/data/.
// Everything below runs client-side against those static files — no R
// server, no shinyapps.io.
//
// Two views so far: a ranked bar chart (top-N municipalities by export
// value for a selected year) and a region-wide composition view (stacked
// area of export value by product category over the whole time range).
// Per-entity trend small multiples and a year-over-year dumbbell view are
// still follow-up work — see the brainstorm in the PR/conversation history
// for the full plan.

(function () {
  "use strict";

  const I18N = {
    pt: {
      plot_name: "Data Zoom Amazônia",
      plot_desc: "Comércio exterior na Amazônia (COMEX): valor da exportação por município",
      label_topn_name: "Municípios exibidos",
      label_year: "Ano",
      label_view_name: "Visualização",
      view_ranking: "Ranking",
      view_composition: "Composição",
      title_ranking: "Ranking de municípios exportadores",
      subtitle_ranking: "Valor exportado (US$), por município",
      title_composition: "Composição das exportações da Amazônia Legal",
      subtitle_composition: "Valor exportado (US$) por categoria de produto, 1997–2025",
      ranking_axis_label: "Valor exportado (US$)",
      region_total_prefix: "Total Amazônia Legal: ",
      label_no_data: "Sem dado",
      label_others: "Outros",
      view_change: "Variação",
      title_change: "Variação entre dois anos",
      subtitle_change: "Municípios ordenados pela variação no valor exportado",
      label_state: "Estado",
      label_year_a: "Ano A",
      label_year_b: "Ano B",
      change_axis_label: "Valor exportado (US$)",
      btn_lang: "English"
    },
    en: {
      plot_name: "Data Zoom Amazônia",
      plot_desc: "External trade in the Amazon (COMEX): export value by municipality",
      label_topn_name: "Municipalities shown",
      label_year: "Year",
      label_view_name: "View",
      view_ranking: "Ranking",
      view_composition: "Composition",
      title_ranking: "Ranking of exporting municipalities",
      subtitle_ranking: "Export value (US$), by municipality",
      title_composition: "Legal Amazon export composition",
      subtitle_composition: "Export value (US$) by product category, 1997–2025",
      ranking_axis_label: "Export value (US$)",
      region_total_prefix: "Legal Amazon total: ",
      label_no_data: "No data",
      label_others: "Other",
      view_change: "Change",
      title_change: "Change between two years",
      subtitle_change: "Municipalities ranked by change in export value",
      label_state: "State",
      label_year_a: "Year A",
      label_year_b: "Year B",
      change_axis_label: "Export value (US$)",
      btn_lang: "Português"
    }
  };

  // Okabe-Ito — a published, colorblind-safe 8-hue categorical palette.
  // Assigned once, in a fixed order, to the top-8 products by all-time
  // total value; every other category folds into "Outros"/"Other" (a
  // neutral gray, not a 9th hue). Order is fixed regardless of how a
  // product's per-year rank moves — color follows the entity, never its
  // rank in a given year.
  const CATEGORY_COLORS = ["#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#666666"];
  const OTHERS_COLOR = "#c9c4ba";

  const DATA_DIR = "data";
  const PLAY_INTERVAL_MS = 900;
  const SPARK_W = 260;
  const SPARK_H = 40;
  const SPARK_PAD = 4;

  const state = {
    lang: "pt",
    year: null,
    topN: 15,
    view: "ranking", // "ranking" | "composition" | "change"
    playing: false,
    playTimer: null,
    changeState: null, // UF filter for the change (dumbbell) view
    yearA: null,
    yearB: null
  };

  let dictionary, municipalityTotals, regionTotals, composition, products;
  let totalsByYear; // year -> [{municipio, valor}], sorted descending
  let regionTotalByYear; // year -> valor
  let compositionSeries; // [{ produto, color, isOthers, values: Map(year -> valor) }], top-8 + Outros, fixed order
  let totalsByMunicipio; // municipio -> Map(year -> valor)
  let municipioMeta; // municipio -> { uf }
  let ufList; // sorted distinct UF codes
  let sparkSeries = [];
  let sparkXFor = null;
  let sparkYFor = null;

  Promise.all([
    fetchJson(`${DATA_DIR}/dictionary.json`),
    fetchJson(`${DATA_DIR}/municipality_totals.json`),
    fetchJson(`${DATA_DIR}/region_totals.json`),
    fetchJson(`${DATA_DIR}/composition.json`),
    fetchJson(`${DATA_DIR}/products.json`)
  ]).then(([dict, munTotals, regTotals, comp, prod]) => {
    dictionary = dict;
    municipalityTotals = munTotals;
    regionTotals = regTotals;
    composition = comp;
    products = prod;

    totalsByYear = groupByYear(municipalityTotals);
    regionTotalByYear = new Map(regionTotals.map((r) => [r.ano, r.valor]));
    compositionSeries = buildCompositionSeries(composition, dictionary);
    ({ totalsByMunicipio, municipioMeta, ufList } = buildMunicipioIndex(municipalityTotals));

    initState();
    initControls();
    initSparklineHover();
    initCompositionHover();
    setView(state.view);
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

  // The source data keys municipalities by a "Nome - UF" string (the .rds
  // pipeline discards the IBGE code in favor of this name early on — see
  // the export script) — UF is parsed from that suffix rather than
  // re-fetched from anywhere else, same pattern the CEMPRE map used for
  // its own compare-mode state filter.
  function buildMunicipioIndex(rows) {
    const byMuni = new Map();
    const meta = new Map();
    for (const row of rows) {
      if (!byMuni.has(row.municipio)) {
        byMuni.set(row.municipio, new Map());
        const uf = row.municipio.slice(row.municipio.lastIndexOf(" - ") + 3);
        meta.set(row.municipio, { uf });
      }
      byMuni.get(row.municipio).set(row.ano, row.valor);
    }
    const ufs = Array.from(new Set(Array.from(meta.values()).map((m) => m.uf))).sort();
    return { totalsByMunicipio: byMuni, municipioMeta: meta, ufList: ufs };
  }

  // ---- State init from query string ----

  function initState() {
    const params = new URLSearchParams(location.search);
    const qLang = params.get("lang");
    const qYear = parseInt(params.get("year"), 10);
    const qTopN = parseInt(params.get("topn"), 10);
    const qView = params.get("view");
    const qState = params.get("state");
    const qYearA = parseInt(params.get("yeara"), 10);
    const qYearB = parseInt(params.get("yearb"), 10);

    state.lang = qLang === "en" ? "en" : "pt";
    state.year = Number.isFinite(qYear) && qYear >= dictionary.year_inicio && qYear <= dictionary.year_final
      ? qYear
      : dictionary.year_final;
    state.topN = [10, 15, 20, 30].includes(qTopN) ? qTopN : 15;
    state.view = ["ranking", "composition", "change"].includes(qView) ? qView : "ranking";
    state.changeState = ufList.includes(qState) ? qState : ufList[0];
    state.yearA = Number.isFinite(qYearA) && qYearA >= dictionary.year_inicio && qYearA <= dictionary.year_final
      ? qYearA
      : dictionary.year_inicio;
    state.yearB = Number.isFinite(qYearB) && qYearB >= dictionary.year_inicio && qYearB <= dictionary.year_final
      ? qYearB
      : dictionary.year_final;
  }

  function updateUrl() {
    const params = new URLSearchParams();
    params.set("lang", state.lang);
    params.set("year", state.year);
    params.set("topn", state.topN);
    params.set("view", state.view);
    params.set("state", state.changeState);
    params.set("yeara", state.yearA);
    params.set("yearb", state.yearB);
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

    document.getElementById("view-ranking").addEventListener("click", () => setView("ranking"));
    document.getElementById("view-composition").addEventListener("click", () => setView("composition"));
    document.getElementById("view-change").addEventListener("click", () => setView("change"));

    const stateSelect = document.getElementById("change-state-select");
    for (const uf of ufList) {
      const opt = document.createElement("option");
      opt.value = uf;
      opt.textContent = uf;
      stateSelect.appendChild(opt);
    }
    stateSelect.value = state.changeState;
    stateSelect.addEventListener("change", (e) => {
      state.changeState = e.target.value;
      updateUrl();
      renderChange();
    });

    const yearASelect = document.getElementById("change-year-a");
    const yearBSelect = document.getElementById("change-year-b");
    for (let y = dictionary.year_inicio; y <= dictionary.year_final; y++) {
      const optA = document.createElement("option");
      optA.value = y; optA.textContent = y;
      yearASelect.appendChild(optA);
      const optB = document.createElement("option");
      optB.value = y; optB.textContent = y;
      yearBSelect.appendChild(optB);
    }
    yearASelect.value = state.yearA;
    yearBSelect.value = state.yearB;
    yearASelect.addEventListener("change", (e) => {
      state.yearA = parseInt(e.target.value, 10);
      updateUrl();
      renderChange();
    });
    yearBSelect.addEventListener("change", (e) => {
      state.yearB = parseInt(e.target.value, 10);
      updateUrl();
      renderChange();
    });
  }

  function setView(view) {
    stopPlaying();
    state.view = view;
    document.getElementById("view-ranking").classList.toggle("active", view === "ranking");
    document.getElementById("view-composition").classList.toggle("active", view === "composition");
    document.getElementById("view-change").classList.toggle("active", view === "change");
    document.getElementById("ranking-panel").classList.toggle("hidden", view !== "ranking");
    document.getElementById("composition-panel").classList.toggle("hidden", view !== "composition");
    document.getElementById("change-panel").classList.toggle("hidden", view !== "change");
    document.getElementById("topn-group").classList.toggle("hidden", view !== "ranking");
    document.getElementById("change-group").classList.toggle("hidden", view !== "change");
    document.querySelector(".slider-inline").classList.toggle("hidden", view === "change");
    updateUrl();
    render();
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
    if (state.view === "composition") {
      updateCompositionGuide();
    } else {
      renderRanking();
    }
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
    document.getElementById("label_view_name").textContent = t.label_view_name;
    document.getElementById("view-ranking").textContent = t.view_ranking;
    document.getElementById("view-composition").textContent = t.view_composition;
    document.getElementById("view-change").textContent = t.view_change;
    document.getElementById("ranking-axis-label").textContent = t.ranking_axis_label;
    document.getElementById("change-axis-label").textContent = t.change_axis_label;
    document.getElementById("label_state").textContent = t.label_state;
    document.getElementById("label_year_a").textContent = t.label_year_a;
    document.getElementById("label_year_b").textContent = t.label_year_b;
    document.getElementById("lang-toggle-label").textContent = t.btn_lang;

    const titles = { ranking: t.title_ranking, composition: t.title_composition, change: t.title_change };
    const subtitles = { ranking: t.subtitle_ranking, composition: t.subtitle_composition, change: t.subtitle_change };
    document.getElementById("plot-title").textContent = titles[state.view];
    document.getElementById("plot-subtitle").textContent = subtitles[state.view];

    const slider = document.getElementById("year-slider");
    slider.value = state.year;
    document.getElementById("year-value").textContent = state.year;

    renderSparkline();
    if (state.view === "composition") {
      renderComposition();
    } else if (state.view === "change") {
      renderChange();
    } else {
      renderRanking();
    }
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

  // ---- Composition: stacked area of region-wide export value by product
  // category (SEC level, 22 categories) over the full time range. Reduced
  // to the top 8 by all-time total + an "Outros"/"Other" bucket, since 22
  // stacked bands would be unreadable and the dataviz convention here is a
  // 9th-plus series folds into Other rather than generating another hue. ----

  const COMP_PAD_L = 60, COMP_PAD_R = 16, COMP_PAD_T = 12, COMP_PAD_B = 28;
  const COMP_VB_W = 1000, COMP_VB_H = 520;

  function buildCompositionSeries(rows, dict) {
    const totalByProduct = new Map();
    for (const r of rows) {
      totalByProduct.set(r.produto, (totalByProduct.get(r.produto) || 0) + r.valor);
    }
    const ranked = Array.from(totalByProduct.entries()).sort((a, b) => b[1] - a[1]);
    const topProducts = ranked.slice(0, 8).map(([produto]) => produto);
    const topSet = new Set(topProducts);

    const years = [];
    for (let y = dict.year_inicio; y <= dict.year_final; y++) years.push(y);

    const byProdYear = new Map(); // produto -> Map(year -> valor)
    for (const p of topProducts) byProdYear.set(p, new Map());
    const othersByYear = new Map(years.map((y) => [y, 0]));

    for (const r of rows) {
      if (topSet.has(r.produto)) {
        byProdYear.get(r.produto).set(r.ano, r.valor);
      } else {
        othersByYear.set(r.ano, (othersByYear.get(r.ano) || 0) + r.valor);
      }
    }

    const series = topProducts.map((produto, i) => ({
      produto,
      color: CATEGORY_COLORS[i],
      isOthers: false,
      values: byProdYear.get(produto)
    }));
    series.push({ produto: null, color: OTHERS_COLOR, isOthers: true, values: othersByYear });

    return series;
  }

  function productLabel(produto) {
    if (produto === null) return I18N[state.lang].label_others;
    const list = products[state.lang] || products.pt;
    const hit = list.find((p) => p.var === produto);
    return hit ? hit.label : produto;
  }

  function renderComposition() {
    const svg = document.getElementById("composition-svg");
    svg.innerHTML = "";

    const years = [];
    for (let y = dictionary.year_inicio; y <= dictionary.year_final; y++) years.push(y);

    // Stacked cumulative bounds per year, in the fixed series order.
    const cumByYear = new Map(years.map((y) => [y, 0]));
    const bandBounds = compositionSeries.map((s) => {
      const bottoms = [], tops = [];
      for (const y of years) {
        const bottom = cumByYear.get(y);
        const top = bottom + (s.values.get(y) || 0);
        bottoms.push(bottom);
        tops.push(top);
        cumByYear.set(y, top);
      }
      return { bottoms, tops };
    });

    const maxTotal = Math.max(...years.map((y) => cumByYear.get(y)));
    const xFor = (year) => COMP_PAD_L + ((year - dictionary.year_inicio) / (dictionary.year_final - dictionary.year_inicio)) * (COMP_VB_W - COMP_PAD_L - COMP_PAD_R);
    const yFor = (value) => COMP_PAD_T + (1 - value / maxTotal) * (COMP_VB_H - COMP_PAD_T - COMP_PAD_B);

    const svgNS = "http://www.w3.org/2000/svg";
    const addEl = (tag, attrs) => {
      const el = document.createElementNS(svgNS, tag);
      for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, v);
      svg.appendChild(el);
      return el;
    };

    // Gridlines + Y labels (4 bands, recessive per the dataviz mark spec).
    for (let i = 0; i <= 4; i++) {
      const v = (maxTotal / 4) * i;
      const y = yFor(v);
      addEl("line", { class: "comp-gridline", x1: COMP_PAD_L, x2: COMP_VB_W - COMP_PAD_R, y1: y, y2: y });
      addEl("text", { class: "comp-axis-label", x: COMP_PAD_L - 8, y: y + 3, "text-anchor": "end" }).textContent = fmtAbbrev(v);
    }

    // X labels every 4 years.
    for (const y of years) {
      if ((y - dictionary.year_inicio) % 4 !== 0 && y !== dictionary.year_final) continue;
      addEl("text", { class: "comp-axis-label", x: xFor(y), y: COMP_VB_H - COMP_PAD_B + 16, "text-anchor": "middle" }).textContent = y;
    }

    // Stacked bands, in series order (largest all-time total at the
    // bottom, Outros last/top).
    compositionSeries.forEach((s, i) => {
      const { bottoms, tops } = bandBounds[i];
      const topPts = years.map((y, j) => `${xFor(y).toFixed(1)},${yFor(tops[j]).toFixed(1)}`);
      const botPts = years.map((y, j) => `${xFor(y).toFixed(1)},${yFor(bottoms[j]).toFixed(1)}`).reverse();
      addEl("path", {
        class: "comp-band",
        fill: s.color,
        d: `M${topPts.join(" L")} L${botPts.join(" L")} Z`,
        "data-index": i
      });
    });

    // Selected-year guide line.
    const guideX = xFor(state.year);
    addEl("line", { id: "comp-guide", class: "comp-guide", x1: guideX, x2: guideX, y1: COMP_PAD_T, y2: COMP_VB_H - COMP_PAD_B });

    renderCompositionLegend();
  }

  function updateCompositionGuide() {
    const guide = document.getElementById("comp-guide");
    if (!guide) return;
    const x = COMP_PAD_L + ((state.year - dictionary.year_inicio) / (dictionary.year_final - dictionary.year_inicio)) * (COMP_VB_W - COMP_PAD_L - COMP_PAD_R);
    guide.setAttribute("x1", x);
    guide.setAttribute("x2", x);
  }

  function renderCompositionLegend() {
    const legend = document.getElementById("composition-legend");
    legend.innerHTML = "";
    for (const s of compositionSeries) {
      const item = document.createElement("div");
      item.className = "legend-item";
      const swatch = document.createElement("span");
      swatch.className = "swatch";
      swatch.style.background = s.color;
      const label = document.createElement("span");
      label.className = "label";
      label.textContent = productLabel(s.produto);
      label.title = productLabel(s.produto);
      item.appendChild(swatch);
      item.appendChild(label);
      legend.appendChild(item);
    }
  }

  function initCompositionHover() {
    const area = document.querySelector(".composition-chart-area");
    const tooltip = document.getElementById("composition-tooltip");

    area.addEventListener("pointermove", (e) => {
      if (state.view !== "composition") return;
      const svg = document.getElementById("composition-svg");
      const rect = svg.getBoundingClientRect();
      const fracX = (e.clientX - rect.left) / rect.width;
      const vbX = fracX * COMP_VB_W;
      const frac = (vbX - COMP_PAD_L) / (COMP_VB_W - COMP_PAD_L - COMP_PAD_R);
      const year = Math.round(dictionary.year_inicio + frac * (dictionary.year_final - dictionary.year_inicio));
      if (year < dictionary.year_inicio || year > dictionary.year_final) {
        tooltip.style.opacity = "0";
        return;
      }

      const truncate = (s, n) => (s.length > n ? s.slice(0, n - 1) + "…" : s);
      const rowsHtml = compositionSeries
        .map((s) => ({ label: productLabel(s.produto), color: s.color, valor: s.values.get(year) || 0 }))
        .sort((a, b) => b.valor - a.valor)
        .map((r) => `<div style="display:flex;align-items:center;gap:6px;"><span style="width:8px;height:8px;border-radius:2px;background:${r.color};display:inline-block;flex:0 0 auto;"></span><span style="flex:1 1 auto;min-width:0;overflow:hidden;text-overflow:ellipsis;">${truncate(r.label, 42)}</span><span style="flex:0 0 auto;padding-left:8px;">${fmtAbbrev(r.valor)}</span></div>`)
        .join("");

      tooltip.innerHTML = `<strong>${year}</strong>` + rowsHtml;
      const areaRect = area.getBoundingClientRect();
      const left = e.clientX - areaRect.left;
      tooltip.style.left = Math.min(areaRect.width - 300, left + 14) + "px";
      tooltip.style.top = (e.clientY - areaRect.top - 10) + "px";
      tooltip.style.opacity = "1";
    });

    area.addEventListener("pointerleave", () => {
      tooltip.style.opacity = "0";
    });

    area.addEventListener("click", (e) => {
      const svg = document.getElementById("composition-svg");
      const rect = svg.getBoundingClientRect();
      const fracX = (e.clientX - rect.left) / rect.width;
      const vbX = fracX * COMP_VB_W;
      const frac = (vbX - COMP_PAD_L) / (COMP_VB_W - COMP_PAD_L - COMP_PAD_R);
      const year = Math.round(dictionary.year_inicio + frac * (dictionary.year_final - dictionary.year_inicio));
      jumpToYear(Math.min(dictionary.year_final, Math.max(dictionary.year_inicio, year)));
    });
  }

  // ---- Change: ranked dumbbell chart, year A vs year B, filtered to one
  // state — same pattern as the CEMPRE map rebuild's compare mode (446
  // municipalities isn't readable as one ranked list; 13-115 per state is).
  // Dot color is a fixed identity pair (year A = blue, year B = orange),
  // not an encoding of which value is larger. ----

  function computeChangeRows(uf, yearA, yearB) {
    const rows = [];
    for (const [municipio, meta] of municipioMeta) {
      if (meta.uf !== uf) continue;
      const years = totalsByMunicipio.get(municipio);
      const valueA = years.get(yearA) || 0;
      const valueB = years.get(yearB) || 0;
      rows.push({ municipio, valueA, valueB, delta: valueB - valueA });
    }
    rows.sort((a, b) => b.delta - a.delta);
    return rows;
  }

  function changeDomain(rows) {
    if (!rows.length) return { min: 0, max: 1 };
    let min = Infinity, max = -Infinity;
    for (const r of rows) {
      min = Math.min(min, r.valueA, r.valueB);
      max = Math.max(max, r.valueA, r.valueB);
    }
    if (min === max) { min -= 1; max += 1; }
    const pad = (max - min) * 0.05;
    return { min: min - pad, max: max + pad };
  }

  function pctForChange(value, domain) {
    return ((value - domain.min) / (domain.max - domain.min)) * 100;
  }

  function renderChange() {
    document.getElementById("change-legend-a-label").textContent = state.yearA;
    document.getElementById("change-legend-b-label").textContent = state.yearB;

    const rows = computeChangeRows(state.changeState, state.yearA, state.yearB);
    const domain = changeDomain(rows);
    document.getElementById("change-axis-min").textContent = fmtAbbrev(domain.min);
    document.getElementById("change-axis-max").textContent = fmtAbbrev(domain.max);

    const container = document.getElementById("change-rows");
    container.innerHTML = "";
    const frag = document.createDocumentFragment();
    for (const r of rows) frag.appendChild(buildChangeRowEl(r, domain));
    container.appendChild(frag);
  }

  function buildChangeRowEl(r, domain) {
    const pctA = pctForChange(r.valueA, domain);
    const pctB = pctForChange(r.valueB, domain);
    const lo = Math.min(pctA, pctB);
    const hi = Math.max(pctA, pctB);

    const row = document.createElement("div");
    row.className = "change-row";

    const label = document.createElement("div");
    label.className = "change-col-label";
    label.textContent = r.municipio;
    label.title = r.municipio;
    row.appendChild(label);

    const track = document.createElement("div");
    track.className = "change-col-track";
    const line = document.createElement("div");
    line.className = "change-line";
    line.style.left = lo + "%";
    line.style.width = (hi - lo) + "%";
    track.appendChild(line);
    const dotA = document.createElement("div");
    dotA.className = "change-dot change-dot-a";
    dotA.style.left = pctA + "%";
    track.appendChild(dotA);
    const dotB = document.createElement("div");
    dotB.className = "change-dot change-dot-b";
    dotB.style.left = pctB + "%";
    track.appendChild(dotB);
    row.appendChild(track);

    const delta = document.createElement("div");
    delta.className = "change-col-delta";
    delta.textContent = (r.delta > 0 ? "+" : "") + fmtAbbrev(r.delta);
    row.appendChild(delta);

    row.addEventListener("pointerenter", (e) => showChangeTooltip(e, r));
    row.addEventListener("pointermove", moveChangeTooltip);
    row.addEventListener("pointerleave", hideChangeTooltip);

    return row;
  }

  function showChangeTooltip(e, r) {
    const tooltip = document.getElementById("change-tooltip");
    const pct = r.valueA !== 0 ? (r.delta / Math.abs(r.valueA)) * 100 : null;
    tooltip.innerHTML =
      "<strong>" + r.municipio + "</strong><br>" +
      state.yearA + ": US$ " + fmtNumber(r.valueA) + "<br>" +
      state.yearB + ": US$ " + fmtNumber(r.valueB) + "<br>" +
      (r.delta >= 0 ? "+" : "") + fmtNumber(r.delta) +
      (pct !== null ? " (" + (pct >= 0 ? "+" : "") + pct.toFixed(1) + "%)" : "");
    tooltip.style.opacity = "1";
    moveChangeTooltip(e);
  }

  function moveChangeTooltip(e) {
    const tooltip = document.getElementById("change-tooltip");
    const panelRect = document.getElementById("change-panel").getBoundingClientRect();
    tooltip.style.left = (e.clientX - panelRect.left + 12) + "px";
    tooltip.style.top = (e.clientY - panelRect.top + 12) + "px";
  }

  function hideChangeTooltip() {
    document.getElementById("change-tooltip").style.opacity = "0";
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
