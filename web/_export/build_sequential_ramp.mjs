// Generates the 9-step sequential plum/berry ramp used by
// web/map_dz_munic_cempre/app.js (PALETTE_CONTINUOUS), following the
// dataviz skill's color formula: sequential = one hue, monotone lightness,
// light -> dark. Run: node web/_export/build_sequential_ramp.mjs
//
// Validate the output against the skill's own checker (from the skill's
// base directory):
//   node scripts/validate_palette.js "<COMMA_LIST>" --ordinal --mode light
//
// --ordinal is the applicable check here, not the default categorical one:
// these 9 stops render as discrete legend/bin swatches, not a continuous
// gradient, so the relevant gates are monotone L, adjacent ΔL >= 0.06,
// single hue, and light-end contrast >= 2:1 against a white legend surface.

// Deliberately NOT close to the app's brand greens (#50A486/#48968B, H
// ~168-183): the sidebar and the choropleth were both green, so the data
// layer visually merged into the UI chrome. H340 (plum/berry) sits far
// enough around the wheel to separate cleanly from the sidebar's green —
// the boldest, most saturated of the three hues considered (amber and
// blue were the other two), traded off against being less thematically
// tied to economic-activity data than a warm hue.
const HUE = 340;
const N = 9; // matches N_BINS in app.js

// Lightest step: an ordinal ramp's light end must itself clear >=2:1
// contrast against a white surface (these render as legend swatches, not a
// continuous fade into the background) — L=0.78 is the lightest step at
// this hue that still clears 2:1 (2.02:1); anything lighter drops below it.
// Darkest step: spaced 0.50 below the light end so 9 EVEN steps still clear
// the ordinal minimum adjacent ΔL of 0.06 (0.50/8 = 0.0625).
const L_LIGHT = 0.78;
const L_DARK = 0.28;

// ---- OKLab/OKLCH <-> sRGB (forward math matches the skill's validator) ----

const hex2srgb = (h) => { h = h.trim().replace(/^#/, ""); return [0, 2, 4].map(i => parseInt(h.slice(i, i + 2), 16) / 255); };
const s2lin = (c) => c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
const lin2s = (c) => { c = Math.max(0, Math.min(1, c)); return c <= 0.0031308 ? 12.92 * c : 1.055 * c ** (1 / 2.4) - 0.055; };
const lin = (h) => hex2srgb(h).map(s2lin);

function oklabFromLin([r, g, b]) {
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return [
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  ];
}

function linFromOklab([L, a, b]) {
  const l_ = L + 0.3963377774 * a + 0.2158037573 * b;
  const m_ = L - 0.1055613458 * a - 0.0638541728 * b;
  const s_ = L - 0.0894841775 * a - 1.2914855480 * b;
  const l = l_ ** 3, m = m_ ** 3, s = s_ ** 3;
  return [
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
  ];
}

function hexFromOklch(L, C, H) {
  const hr = H * Math.PI / 180;
  const a = C * Math.cos(hr), b = C * Math.sin(hr);
  const [r, g, bl] = linFromOklab([L, a, b]).map(lin2s);
  const toHex = (c) => Math.round(Math.max(0, Math.min(1, c)) * 255).toString(16).padStart(2, "0");
  return "#" + toHex(r) + toHex(g) + toHex(bl);
}

function inGamut(L, C, H) {
  const hr = H * Math.PI / 180;
  const a = C * Math.cos(hr), b = C * Math.sin(hr);
  const [r, g, bl] = linFromOklab([L, a, b]);
  return [r, g, bl].every((c) => c >= -1e-4 && c <= 1 + 1e-4);
}

function maxChroma(L, H) {
  let lo = 0, hi = 0.4;
  for (let i = 0; i < 40; i++) {
    const mid = (lo + hi) / 2;
    if (inGamut(L, mid, H)) lo = mid; else hi = mid;
  }
  return lo;
}

// ---- build the ramp ----

const steps = [];
for (let i = 0; i < N; i++) {
  const t = i / (N - 1);
  const L = L_LIGHT + (L_DARK - L_LIGHT) * t;
  // Chroma rises smoothly from 15% to 90% of the hue's actual sRGB gamut
  // ceiling at that lightness — near-white/barely tinted at "near zero",
  // fuller color at "high value", no discontinuity, never clips.
  const ceiling = maxChroma(L, HUE);
  const frac = 0.15 + 0.75 * t * (2 - t);
  const C = Math.min(ceiling * frac, ceiling - 0.005);
  steps.push(hexFromOklch(L, C, HUE));
}

console.log(steps.join(","));
