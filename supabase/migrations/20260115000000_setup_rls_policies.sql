-- Enable RLS on locations table
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow all operations" ON locations;
DROP POLICY IF EXISTS "Public read access" ON locations;
DROP POLICY IF EXISTS "Authenticated users can insert" ON locations;
DROP POLICY IF EXISTS "Authenticated users can update" ON locations;
DROP POLICY IF EXISTS "Authenticated users can delete" ON locations;

-- Policy 1: Allow public read access (SELECT)
-- Anyone can view locations, even without authentication
CREATE POLICY "Public read access"
ON locations
FOR SELECT
TO public
USING (true);

-- Policy 2: Allow only specific users to insert locations
-- Only adamtrabold@gmail.com and ericatrabold@gmail.com can add locations
CREATE POLICY "Authorized users can insert"
ON locations
FOR INSERT
TO authenticated
WITH CHECK (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
);

-- Policy 3: Allow only specific users to update locations
-- Only adamtrabold@gmail.com and ericatrabold@gmail.com can update locations
CREATE POLICY "Authorized users can update"
ON locations
FOR UPDATE
TO authenticated
USING (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
)
WITH CHECK (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
);

-- Policy 4: Allow only specific users to delete locations
-- Only adamtrabold@gmail.com and ericatrabold@gmail.com can delete locations
CREATE POLICY "Authorized users can delete"
ON locations
FOR DELETE
TO authenticated
USING (
  auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
);
