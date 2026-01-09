#!/usr/bin/env node
import fetch from 'node-fetch';

const SUPABASE_URL = 'https://jgvckilmltimabfdvaly.supabase.co';
const SUPABASE_KEY = 'sb_publishable_TiO_hACvlsn4mfFazsHTlg_i9BnzCfr';

const headers = {
  'apikey': SUPABASE_KEY,
  'Authorization': `Bearer ${SUPABASE_KEY}`,
  'Content-Type': 'application/json'
};

// Fetch all locations from Supabase
async function fetchLocations() {
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/locations?select=id,name,address`, { headers });
    if (!response.ok) throw new Error(`HTTP ${response.status}: ${await response.text()}`);
    return await response.json();
  } catch (err) {
    console.error('Failed to fetch locations:', err);
    throw err;
  }
}

// Main function
async function main() {
  console.log('Fetching locations from Supabase...\n');
  const locations = await fetchLocations();
  console.log(JSON.stringify(locations, null, 2));
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
