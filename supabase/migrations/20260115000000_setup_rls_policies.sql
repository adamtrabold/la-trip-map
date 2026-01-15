-- Enable RLS on locations table
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

-- Drop existing "Allow all operations" policy if it exists
DROP POLICY IF EXISTS "Allow all operations" ON locations;

-- Policy 1: Allow public read access (SELECT)
-- Anyone can view locations, even without authentication
CREATE POLICY "Public read access"
ON locations
FOR SELECT
TO public
USING (true);

-- Policy 2: Allow authenticated users to insert locations
CREATE POLICY "Authenticated users can insert"
ON locations
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy 3: Allow authenticated users to update locations
CREATE POLICY "Authenticated users can update"
ON locations
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy 4: Allow authenticated users to delete locations
CREATE POLICY "Authenticated users can delete"
ON locations
FOR DELETE
TO authenticated
USING (true);
