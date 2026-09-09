# web/

Static, serverless rebuilds of Data Zoom Amazônia's Shiny visualizations — plain HTML/CSS/JS reading pre-exported JSON, no server or build step required.

This folder is mirrored automatically to [datazoompuc/datazoom_viz_web](https://github.com/datazoompuc/datazoom_viz_web) (public) whenever a change under `web/` lands on `main` — see `.github/workflows/web-publish.yml`. That repo publishes via GitHub Pages; this repo (private) stays the source of truth, alongside the R export scripts in `data-raw/` that generate each app's JSON.

## Apps

- [`ts_comex_exp_municipio/`](ts_comex_exp_municipio/) — COMEX exports by municipality: ranking, composition, year-over-year change, trends, municipality comparison, per-municipality composition, and product ranking views.
