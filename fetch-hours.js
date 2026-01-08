#!/usr/bin/env node
import fetch from 'node-fetch';

const SUPABASE_URL = 'https://jgvckilmltimabfdvaly.supabase.co';
const SUPABASE_KEY = 'sb_publishable_TiO_hACvlsn4mfFazsHTlg_i9BnzCfr';
const GOOGLE_API_KEY = process.env.GOOGLE_PLACES_API_KEY;

if (!GOOGLE_API_KEY) {
  console.error('❌ Error: GOOGLE_PLACES_API_KEY environment variable not set');
  console.error('Please set it with: export GOOGLE_PLACES_API_KEY="your-api-key"');
  process.exit(1);
}

const headers = {
  'apikey': SUPABASE_KEY,
  'Authorization': `Bearer ${SUPABASE_KEY}`,
  'Content-Type': 'application/json',
  'Prefer': 'return=representation'
};

// Fetch all locations from Supabase
async function fetchLocations() {
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/locations?select=*`, { headers });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (err) {
    console.error('Failed to fetch locations:', err);
    throw err;
  }
}

// Search for place using Google Places API (Text Search)
async function searchPlace(name, address) {
  try {
    const query = encodeURIComponent(`${name} ${address} Los Angeles`);
    const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${query}&key=${GOOGLE_API_KEY}`;

    const response = await fetch(url);
    const data = await response.json();

    if (data.status === 'OK' && data.results.length > 0) {
      return data.results[0].place_id;
    }
    return null;
  } catch (err) {
    console.error(`Error searching for place ${name}:`, err);
    return null;
  }
}

// Get place details including opening hours
async function getPlaceDetails(placeId) {
  try {
    const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=opening_hours&key=${GOOGLE_API_KEY}`;

    const response = await fetch(url);
    const data = await response.json();

    if (data.status === 'OK' && data.result.opening_hours) {
      return data.result.opening_hours;
    }
    return null;
  } catch (err) {
    console.error(`Error fetching details for place ${placeId}:`, err);
    return null;
  }
}

// Update location in Supabase with hours data
async function updateLocationHours(locationId, hours) {
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/locations?id=eq.${locationId}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ hours })
    });

    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return true;
  } catch (err) {
    console.error(`Failed to update location ${locationId}:`, err);
    return false;
  }
}

// Main function
async function main() {
  console.log('🚀 Starting business hours fetch for LA Trip Map locations...\n');

  // Fetch all locations
  console.log('📍 Fetching locations from Supabase...');
  const locations = await fetchLocations();
  console.log(`✓ Found ${locations.length} locations\n`);

  let successCount = 0;
  let failCount = 0;
  let skipCount = 0;

  // Process each location
  for (let i = 0; i < locations.length; i++) {
    const location = locations[i];
    console.log(`[${i + 1}/${locations.length}] Processing: ${location.name}`);

    // Check if hours already exist
    if (location.hours) {
      console.log(`  ⏭️  Already has hours data, skipping`);
      skipCount++;
      continue;
    }

    // Search for place
    console.log(`  🔍 Searching Google Places...`);
    const placeId = await searchPlace(location.name, location.address || '');

    if (!placeId) {
      console.log(`  ❌ Could not find place on Google Places`);
      failCount++;
      continue;
    }

    console.log(`  ✓ Found place ID: ${placeId}`);

    // Get place details
    console.log(`  📋 Fetching business hours...`);
    const hours = await getPlaceDetails(placeId);

    if (!hours) {
      console.log(`  ⚠️  No hours data available for this place`);
      failCount++;
      continue;
    }

    // Update Supabase
    console.log(`  💾 Updating database...`);
    const updated = await updateLocationHours(location.id, hours);

    if (updated) {
      console.log(`  ✅ Successfully updated with hours data`);
      successCount++;
    } else {
      console.log(`  ❌ Failed to update database`);
      failCount++;
    }

    // Rate limiting - wait 100ms between requests to avoid hitting API limits
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  // Summary
  console.log('\n📊 Summary:');
  console.log(`  ✅ Success: ${successCount}`);
  console.log(`  ❌ Failed: ${failCount}`);
  console.log(`  ⏭️  Skipped: ${skipCount}`);
  console.log(`  📍 Total: ${locations.length}`);

  if (successCount > 0) {
    console.log('\n🎉 Business hours have been successfully fetched and stored!');
  }
}

// Run the script
main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
