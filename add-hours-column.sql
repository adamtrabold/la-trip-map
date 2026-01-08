-- Add hours column to locations table
-- This column will store business hours in Google Places API format
-- Run this in your Supabase SQL Editor

ALTER TABLE locations ADD COLUMN IF NOT EXISTS hours JSONB;

-- Add a comment to document the column structure
COMMENT ON COLUMN locations.hours IS 'Business hours in Google Places API format: {"periods": [{"open": {"day": 0, "time": "0900"}, "close": {"day": 0, "time": "1700"}}], "weekday_text": ["Monday: 9:00 AM – 5:00 PM"]}';
