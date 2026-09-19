# Triplet

Personal single-file trip-planning app (Iceland/Scandinavia, Sept 2026).
Vanilla JS/HTML/CSS in `index.html`, Leaflet + Supabase, deployed via GitHub
Pages on push to `main`. **No build step — this is permanent, not a
temporary simplification.**

## UX principles (learned the hard way — don't repeat these)

- **A list shows everything that matches the active filters, full stop.**
  Never gate list membership on map viewport/zoom/pan. Zoom is a rendering
  concern for the *map layer only* — see `visibleNeighborhoodShapes()`
  (filters only) vs `mapVisibleNeighborhoodShapes()` (adds the zoom gate,
  feeds only `syncNeighborhoodLayers()`). If you add a new listable thing,
  give it the same split.
- **Clicking any list item navigates the map to it** — pan and zoom in
  enough to actually see the thing, regardless of current zoom. Pins do
  this via `focusMap()`/`highlightMarker()`; shapes via `focusShape()`
  (`map.flyToBounds()` on the shape's geometry). A new list item type needs
  the same click-to-navigate behavior, not just a static row.
- Category filter chips (`CATEGORY_COLORS`) are independent of the
  add-form's category dropdown — adding a category to one doesn't require
  touching the other, and the reverse is also true.

## Architecture

- `locations` table: pins (point features) — `city`, `category`, `lat/lng`.
- `neighborhood_shapes` table: districts/streets (area/line features) —
  `city`, `type` (`district`|`street`), `geometry` (array of `[lat,lng]`
  pairs, this app's convention, not GeoJSON). Fetched live from OSM
  (Nominatim polygon / Overpass way) at add time, not hand-authored.
- `cities` table: runtime-extensible city registry, merged into the static
  `CITIES` bootstrap object in `index.html` (never replacing it — that
  object is the offline-safe seed before any fetch resolves).
- The add-location form routes on category alone: `isShapeCategory(category)`
  (true for `district`/`street`) decides both which fields show and which
  table the submit goes to. No separate "this is a shape" toggle.
- RLS pattern, identical across all three tables: public `SELECT`;
  `INSERT`/`UPDATE`/`DELETE` restricted to
  `auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')`.

## Environment constraints

- An agent's sandbox typically **cannot reach Supabase, Nominatim, or
  Overpass directly** (network egress blocked). DB migrations must be
  handed to the user to run manually in the Supabase SQL editor; anything
  depending on live Nominatim/Overpass calls (e.g. `tools/*.html`) must run
  in the user's own browser, not be fetched by the agent.
- The user often works from a phone — don't hand them a file they can't
  open. Prefer pasting copy-pasteable text directly in chat, or an Artifact
  with a copy button, over `SendUserFile` for anything they need to paste
  elsewhere (like SQL for the Supabase editor).

## Open items (as of 2026-09-19)

Update this list as items get resolved or new ones surface — don't let it
go stale, and don't leave it silently out of date either.

**Needs the user's action:**
- Confirm the `20260920000000_add_cities_table.sql` migration has actually
  been run. Until it is, `fetchCities()` throws on every load (the `cities`
  table doesn't exist yet), Phase 4 auto-detection silently no-ops back to
  the static `CITIES` bootstrap, and the error banner flashes on load
  (masked a moment later by an unrelated successful fetch calling
  `hideError()` — see the bug noted below).

**Data cleanup (neighborhood shapes):**
- `reykjavik-klapparstigur` was excluded from the seeded shapes — 14 of 43
  fetched geometry points jumped ~50km south to Keflavík (Overpass merged
  in an unrelated way sharing the street name). Needs a re-fetch or manual
  fix before it's added.
- `copenhagen-nyboder` (Nyboder) and `stockholm-gamla-stan` (Gamla Stan)
  have no auto-fetched geometry — need manual tracing via geojson.io.

**Known minor bugs (not fixed, flagged not silently dropped):**
- `showError()`/`hideError()` share one global banner with no source
  tracking, so an unrelated successful fetch's `hideError()` can mask a
  real error before the user reads it.
- `slugifyCityId()` doesn't decompose Nordic `ø`/`Ø` (e.g. "Nørrebro" →
  "n-rrebro") — cosmetic only, still produces a valid unique slug.

**Deferred roadmap (not started):**
- Phase 2 — trip context (dates/closures) and shared traits (kid-friendly,
  vegetarian, etc.) across both pins and shapes.
- SRI hashing on the CDN script tags.
- Nominatim autocomplete-while-typing (currently only fires on submit).
