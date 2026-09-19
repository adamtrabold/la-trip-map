-- Neighborhood & street shape overlays (Phase 3).
-- Mirrors the `locations` table's RLS shape exactly: public read, writes
-- restricted to the two authorized emails. Shapes are added through the same
-- add-location form/flow as pins (a "this is a shape" toggle), fetched live
-- from OpenStreetMap (Nominatim polygon boundary / Overpass way) at add time
-- and stored here -- not hand-authored, not baked into index.html as a static
-- config, so that adding one is a single action from the same UI as a pin.

CREATE TABLE neighborhood_shapes (
  id         bigint generated always as identity primary key,
  city       text NOT NULL,
  type       text NOT NULL CHECK (type IN ('district', 'street')),
  label      text NOT NULL,
  color      text,
  note       text,
  min_zoom   integer,
  geometry   jsonb NOT NULL,   -- array of [lat, lng] pairs (this app's convention, not GeoJSON's)
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE neighborhood_shapes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access"
ON neighborhood_shapes
FOR SELECT
TO public
USING (true);

CREATE POLICY "Authorized users can insert"
ON neighborhood_shapes
FOR INSERT
TO authenticated
WITH CHECK (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
);

CREATE POLICY "Authorized users can update"
ON neighborhood_shapes
FOR UPDATE
TO authenticated
USING (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
)
WITH CHECK (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
);

CREATE POLICY "Authorized users can delete"
ON neighborhood_shapes
FOR DELETE
TO authenticated
USING (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
);
