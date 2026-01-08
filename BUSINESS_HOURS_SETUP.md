# Business Hours Setup Guide

This guide explains how to set up the business hours functionality for the LA Trip Map application.

## Overview

The business hours feature allows you to:
- Filter locations by "Open Now" status
- See which locations are currently open based on their actual business hours
- Automatically fetch hours from Google Places API for new and existing locations

## Prerequisites

1. **Google Places API Key**
   - Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
   - Create a new project or select an existing one
   - Enable the **Places API**
   - Create an API key
   - Restrict the API key to Places API for security

## Setup Steps

### Step 1: Add Hours Column to Supabase

1. Log in to your [Supabase Dashboard](https://app.supabase.com)
2. Navigate to your project: `jgvckilmltimabfdvaly`
3. Go to the **SQL Editor**
4. Run the SQL script from `add-hours-column.sql`:

```sql
ALTER TABLE locations ADD COLUMN IF NOT EXISTS hours JSONB;
```

This adds a `hours` column to store business hours in Google Places API format.

### Step 2: Fetch Hours for Existing Locations

1. **Install dependencies:**
   ```bash
   cd /home/user/la-trip-map
   npm install
   ```

2. **Set your Google Places API key:**
   ```bash
   export GOOGLE_PLACES_API_KEY="your-api-key-here"
   ```

3. **Run the fetch script:**
   ```bash
   npm run fetch-hours
   ```

   This script will:
   - Fetch all 25 locations from Supabase
   - For each location, search Google Places API
   - Retrieve business hours data
   - Update the Supabase database with hours information

   **Expected output:**
   ```
   🚀 Starting business hours fetch for LA Trip Map locations...

   📍 Fetching locations from Supabase...
   ✓ Found 25 locations

   [1/25] Processing: Republic of Pie
     🔍 Searching Google Places...
     ✓ Found place ID: ChIJ...
     📋 Fetching business hours...
     💾 Updating database...
     ✅ Successfully updated with hours data

   ...

   📊 Summary:
     ✅ Success: 23
     ❌ Failed: 2
     ⏭️  Skipped: 0
     📍 Total: 25
   ```

### Step 3: Update index.html with API Key (Optional)

If you want new locations to automatically fetch hours when added through the UI:

1. Open `index.html`
2. Find line 489 and add your API key:
   ```javascript
   const GOOGLE_PLACES_API_KEY = 'your-api-key-here';
   ```

**Note:** Due to CORS restrictions, the Google Places API may not work directly from the browser. If hours aren't fetched when adding new locations, you can:
- Run the `fetch-hours.js` script again to update any locations missing hours
- Set up a backend proxy to handle Places API requests

## How It Works

### Hours Data Structure

Hours are stored in JSONB format matching Google Places API:

```json
{
  "periods": [
    {
      "open": {"day": 1, "time": "0900"},
      "close": {"day": 1, "time": "1700"}
    },
    {
      "open": {"day": 2, "time": "0900"},
      "close": {"day": 2, "time": "1700"}
    }
  ],
  "weekday_text": [
    "Monday: 9:00 AM – 5:00 PM",
    "Tuesday: 9:00 AM – 5:00 PM"
  ]
}
```

- `day`: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
- `time`: 24-hour format as a string (e.g., "0900" = 9:00 AM, "1730" = 5:30 PM)

### isOpenNow() Function

The `isOpenNow()` function:
1. Gets the current time in Los Angeles timezone (America/Los_Angeles)
2. Checks if current day/time falls within any open period
3. Handles multi-day periods (e.g., Friday 10 PM - Saturday 2 AM)
4. Returns `true` if open, `false` if closed or no hours data

### Open Now Filter

- Click the "Open Now" button in the filters panel
- Only locations currently open will be displayed on the map and in the list
- Locations without hours data are considered closed
- Filter updates in real-time based on LA timezone

## Troubleshooting

### "Could not find place on Google Places"
- The location name/address might not match Google's database
- Try manually searching on Google Maps to verify the business exists
- Some locations (like parks or neighborhoods) may not have hours data

### CORS Error in Browser Console
- This is expected when calling Google Places API from the browser
- The `fetch-hours.js` script (server-side) will work without CORS issues
- Consider adding a backend proxy if you need browser-based hours fetching

### Hours Not Updating
- Make sure you ran the SQL migration to add the `hours` column
- Verify your Google Places API key is valid and has Places API enabled
- Check the browser console for any error messages
- Run `npm run fetch-hours` again to retry failed locations

## Files Created

- `add-hours-column.sql` - SQL script to add hours column to Supabase
- `fetch-hours.js` - Node.js script to fetch and populate hours data
- `package.json` - Node.js dependencies and scripts
- `BUSINESS_HOURS_SETUP.md` - This setup guide

## API Usage & Costs

Google Places API charges per request:
- Text Search: $32 per 1000 requests
- Place Details: $17 per 1000 requests (when requesting only basic fields like opening_hours)

For 25 locations:
- Initial fetch: ~$1.23 (25 searches + 25 details)
- Adding one location: ~$0.05

Consider setting usage limits in Google Cloud Console to prevent unexpected charges.
