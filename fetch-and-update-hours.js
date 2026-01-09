#!/usr/bin/env node
import fetch from 'node-fetch';
import { promises as fs } from 'fs';

const SUPABASE_URL = 'https://jgvckilmltimabfdvaly.supabase.co';
const SUPABASE_KEY = 'sb_publishable_TiO_hACvlsn4mfFazsHTlg_i9BnzCfr';

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
    if (!response.ok) {
      const text = await response.text();
      throw new Error(`HTTP ${response.status}: ${text}`);
    }
    return await response.json();
  } catch (err) {
    console.error('Failed to fetch locations:', err);
    throw err;
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

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`HTTP ${response.status}: ${text}`);
    }
    return true;
  } catch (err) {
    console.error(`Failed to update location ${locationId}:`, err);
    return false;
  }
}

// Save locations to file for manual processing
async function saveLocationsToFile(locations) {
  const data = locations.map(loc => ({
    id: loc.id,
    name: loc.name,
    address: loc.address,
    hasHours: !!loc.hours
  }));
  await fs.writeFile('locations.json', JSON.stringify(data, null, 2));
  console.log(`Saved ${data.length} locations to locations.json`);
}

// Load hours data from file (after manual web search)
async function loadHoursData() {
  try {
    const data = await fs.readFile('hours-data.json', 'utf-8');
    return JSON.parse(data);
  } catch (err) {
    console.error('Failed to load hours-data.json:', err);
    return null;
  }
}

// Main function
async function main() {
  const command = process.argv[2] || 'fetch';

  if (command === 'fetch') {
    console.log('Fetching locations from Supabase...\n');
    const locations = await fetchLocations();
    console.log(`Found ${locations.length} locations\n`);

    await saveLocationsToFile(locations);

    console.log('\nLocations saved to locations.json');
    console.log('\nNext steps:');
    console.log('1. Use web search to find hours for each location');
    console.log('2. Save the hours data in hours-data.json format');
    console.log('3. Run: node fetch-and-update-hours.js update');

  } else if (command === 'update') {
    console.log('Loading hours data from hours-data.json...\n');
    const hoursData = await loadHoursData();

    if (!hoursData) {
      console.error('Error: hours-data.json not found or invalid');
      console.error('Please create hours-data.json with the following format:');
      console.error(`[
  {
    "id": "location-id",
    "hours": {
      "periods": [...],
      "weekday_text": [...]
    }
  }
]`);
      process.exit(1);
    }

    console.log(`Found hours data for ${hoursData.length} locations\n`);

    let successCount = 0;
    let failCount = 0;

    for (const item of hoursData) {
      console.log(`Updating ${item.name || item.id}...`);
      const success = await updateLocationHours(item.id, item.hours);

      if (success) {
        console.log(`  ✓ Success`);
        successCount++;
      } else {
        console.log(`  ✗ Failed`);
        failCount++;
      }
    }

    console.log(`\n📊 Summary:`);
    console.log(`  ✅ Success: ${successCount}`);
    console.log(`  ❌ Failed: ${failCount}`);

  } else if (command === 'check') {
    console.log('Checking current hours data in database...\n');
    const locations = await fetchLocations();

    const withHours = locations.filter(loc => loc.hours);
    const withoutHours = locations.filter(loc => !loc.hours);

    console.log(`Total locations: ${locations.length}`);
    console.log(`With hours: ${withHours.length}`);
    console.log(`Without hours: ${withoutHours.length}\n`);

    if (withoutHours.length > 0) {
      console.log('Locations without hours:');
      withoutHours.forEach(loc => {
        console.log(`  - ${loc.name} (${loc.address || 'no address'})`);
      });
    }
  } else {
    console.log('Usage:');
    console.log('  node fetch-and-update-hours.js fetch   # Fetch locations and save to file');
    console.log('  node fetch-and-update-hours.js update  # Update database with hours from file');
    console.log('  node fetch-and-update-hours.js check   # Check current hours status');
  }
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
