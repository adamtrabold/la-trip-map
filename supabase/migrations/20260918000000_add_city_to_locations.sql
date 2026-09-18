-- Add multi-city support to locations.
--
-- Context: the app is expanding from Los Angeles only to LA + Reykjavik +
-- Copenhagen + Malmo + Stockholm. Every existing row is an LA row.
--
-- This migration is intentionally additive and backwards compatible: it can be
-- applied BEFORE the new index.html is deployed without breaking the currently
-- deployed client (see the DEFAULT note below).

-- ---------------------------------------------------------------------------
-- 1. Add the column
-- ---------------------------------------------------------------------------
-- DEFAULT 'la' is deliberate and TEMPORARY. The currently deployed index.html
-- inserts rows without a `city` field. Keeping the default in place means the
-- live client keeps working during the window between this migration and the
-- index.html deploy. Once the new client ships (it always sends `city`), run
-- the follow-up migration at the bottom of this file to drop the default so a
-- client that forgets `city` fails loudly instead of silently writing LA rows.
ALTER TABLE locations
  ADD COLUMN IF NOT EXISTS city text DEFAULT 'la';

-- ---------------------------------------------------------------------------
-- 2. Backfill existing rows
-- ---------------------------------------------------------------------------
-- Covers rows that predate the column as well as any row inserted with an
-- explicit NULL. Idempotent.
UPDATE locations
  SET city = 'la'
  WHERE city IS NULL;

-- ---------------------------------------------------------------------------
-- 3. Enforce NOT NULL
-- ---------------------------------------------------------------------------
-- A NULL city is invisible in every view (visibleLocations() filters on it),
-- so a row with a NULL city is a silently lost row. Must run AFTER the
-- backfill above.
ALTER TABLE locations
  ALTER COLUMN city SET NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. Constrain to the known city set
-- ---------------------------------------------------------------------------
-- The city ids here must stay in sync with the keys of the CITIES config
-- object in index.html. A typo'd city id ('kobenhavn', 'Malmo') would produce
-- a row that is never shown by any filter and never noticed -- worse than an
-- insert error. The set is small and deliberate, so the cost of a one-line
-- migration per new city is acceptable.
--
-- DROP + ADD rather than ADD IF NOT EXISTS so that re-running this file after
-- editing the city list actually updates the constraint.
ALTER TABLE locations
  DROP CONSTRAINT IF EXISTS locations_city_check;

ALTER TABLE locations
  ADD CONSTRAINT locations_city_check
  CHECK (city IN ('la', 'reykjavik', 'copenhagen', 'malmo', 'stockholm'));

COMMENT ON COLUMN locations.city IS
  'City/trip bucket id. Matches a key of the CITIES config object in index.html.';

-- ---------------------------------------------------------------------------
-- 5. Index: deliberately NOT created
-- ---------------------------------------------------------------------------
-- The chosen fetch strategy is "fetch all cities once, filter client-side via
-- visibleLocations()". The Supabase query stays unfiltered (SELECT with an
-- explicit column list, no .eq('city', ...)), so there is no WHERE city = ...
-- predicate for an index to serve.
--
-- Even if the fetch were scoped per city: at roughly 100 rows the whole table
-- is a single heap page and the planner will sequential-scan it regardless --
-- an index here would be dead weight that still has to be maintained on every
-- INSERT/UPDATE.
--
-- Enable the index below if EITHER of these becomes true:
--   * fetchLocations() switches to .eq('city', activeCity), AND
--   * the table exceeds a few thousand rows.
--
-- CREATE INDEX IF NOT EXISTS locations_city_idx ON locations (city);

-- ---------------------------------------------------------------------------
-- 6. RLS: no changes required (verified, not assumed)
-- ---------------------------------------------------------------------------
-- Verified against 20260115000000_setup_rls_policies.sql. All four policies
-- are column-agnostic:
--
--   "Public read access"            SELECT / public        USING (true)
--   "Authorized users can insert"   INSERT / authenticated WITH CHECK (auth.jwt() ->> 'email' IN (...))
--   "Authorized users can update"   UPDATE / authenticated USING + WITH CHECK (auth.jwt() ->> 'email' IN (...))
--   "Authorized users can delete"   DELETE / authenticated USING (auth.jwt() ->> 'email' IN (...))
--
-- None of the USING or WITH CHECK expressions reference a column of
-- `locations` -- they reference only the JWT claim and the literal `true`.
-- Postgres RLS policies apply to the row as a whole, not to an enumerated set
-- of columns, so a newly added column is automatically covered by the existing
-- policies with no policy change, no re-grant, and no re-enable.
--
-- The one thing that WOULD have required action is column-level privileges
-- (GRANT SELECT (col_a, col_b) ...), because those do not extend to new
-- columns. Supabase's defaults grant at the table level to anon/authenticated,
-- and no column-level GRANT appears in this repo's migration history, so this
-- does not apply. Confirm on the live database with the two queries below --
-- both should return zero rows:
--
--   -- (a) any policy expression that mentions a column name:
--   SELECT policyname, qual, with_check
--     FROM pg_policies
--    WHERE schemaname = 'public' AND tablename = 'locations';
--   -- expect: qual/with_check contain only `true` and the auth.jwt() email test.
--
--   -- (b) any column-level grant on locations:
--   SELECT grantee, privilege_type, column_name
--     FROM information_schema.column_privileges
--    WHERE table_schema = 'public' AND table_name = 'locations'
--      AND grantee IN ('anon', 'authenticated');
--   -- expect: zero rows (privileges are held at table level, not column level).

-- ---------------------------------------------------------------------------
-- FOLLOW-UP (separate migration, only after the new index.html is deployed)
-- ---------------------------------------------------------------------------
-- ALTER TABLE locations ALTER COLUMN city DROP DEFAULT;
