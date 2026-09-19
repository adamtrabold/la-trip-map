-- Automatic City Detection (Phase 4).
-- Moves CITIES from a static index.html object to a Supabase-backed table,
-- following the same reasoning already applied to neighborhood_shapes: a
-- running browser session cannot rewrite its own deployed index.html, so a
-- city that gets auto-added at runtime (see detectCityContext()/addCity() in
-- index.html) needs somewhere durable, cross-device to live. The static
-- CITIES object in index.html is NOT removed -- it stays as an offline-safe
-- bootstrap seed the map can draw from before any fetch resolves, and this
-- table is merged into it (never replacing it) once fetchCities() completes.
--
-- id is deliberately `text`, not a surrogate numeric key: this value IS what
-- gets stored in locations.city / neighborhood_shapes.city and looked up as
-- CITIES[id] throughout index.html.

CREATE TABLE cities (
  id              text PRIMARY KEY,
  label           text NOT NULL,
  center_lat      double precision NOT NULL,
  center_lng      double precision NOT NULL,
  zoom            integer NOT NULL DEFAULT 12,
  geocode_suffix  text NOT NULL,
  countrycodes    text NOT NULL,
  viewbox         text NOT NULL,   -- serialized "lonMin,latMin,lonMax,latMax", same convention index.html already parses via cfg.viewbox.split(',').map(Number)
  auto_added      boolean NOT NULL DEFAULT false,
  created_by      text,            -- auth email, for provenance/cleanup of a bad auto-add
  created_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE cities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access"
ON cities
FOR SELECT
TO public
USING (true);

CREATE POLICY "Authorized users can insert"
ON cities
FOR INSERT
TO authenticated
WITH CHECK (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
);

CREATE POLICY "Authorized users can update"
ON cities
FOR UPDATE
TO authenticated
USING (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
)
WITH CHECK (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
);

CREATE POLICY "Authorized users can delete"
ON cities
FOR DELETE
TO authenticated
USING (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
);

-- Seed verbatim from index.html's current static CITIES object.
INSERT INTO cities (id, label, center_lat, center_lng, zoom, geocode_suffix, countrycodes, viewbox) VALUES
  ('la',         'LA',         34.0522,  -118.2437, 11, 'Los Angeles, CA', 'us',    '-118.668,33.704,-118.155,34.337'),
  ('reykjavik',  'Reykjavík',  64.1466,   -21.9426, 11, 'Iceland',         'is',    '-22.700,63.900,-21.200,64.300'),
  ('copenhagen', 'Copenhagen', 55.6761,    12.5683, 12, 'København',       'dk,se', '12.450,55.610,12.700,55.750'),
  ('malmo',      'Malmö',      55.6050,    13.0038, 12, 'Malmö',           'se,dk', '12.900,55.530,13.120,55.650'),
  ('stockholm',  'Stockholm',  59.3293,    18.0686, 11, 'Stockholm',       'se',    '17.850,59.250,18.220,59.420');

-- Replace the hard-coded CHECK with proper foreign keys, now that `cities`
-- exists and is seeded with exactly the ids the CHECK used to allow -- so
-- this is at least as permissive as before for any currently-deployed
-- client, and safe to run before the new index.html deploys (same pattern
-- as 20260918000000_add_city_to_locations.sql).
ALTER TABLE locations DROP CONSTRAINT IF EXISTS locations_city_check;
ALTER TABLE locations ADD CONSTRAINT locations_city_fkey FOREIGN KEY (city) REFERENCES cities(id);
ALTER TABLE neighborhood_shapes ADD CONSTRAINT neighborhood_shapes_city_fkey FOREIGN KEY (city) REFERENCES cities(id);
