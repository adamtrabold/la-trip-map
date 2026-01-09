#!/usr/bin/env python3
"""
Fetch and update business hours for LA Trip Map locations using web search.
This script demonstrates the process of finding hours via web search instead of Google Places API.
"""

import json
import requests
import re
from datetime import datetime

SUPABASE_URL = 'https://jgvckilmltimabfdvaly.supabase.co'
SUPABASE_KEY = 'sb_publishable_TiO_hACvlsn4mfFazsHTlg_i9BnzCfr'

headers = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

def fetch_locations():
    """Fetch all locations from Supabase"""
    try:
        response = requests.get(
            f'{SUPABASE_URL}/rest/v1/locations',
            headers=headers,
            params={'select': 'id,name,address,hours'}
        )
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f'Error fetching locations: {e}')
        return None

def update_location_hours(location_id, hours_data):
    """Update a location's hours in Supabase"""
    try:
        response = requests.patch(
            f'{SUPABASE_URL}/rest/v1/locations',
            headers=headers,
            params={'id': f'eq.{location_id}'},
            json={'hours': hours_data}
        )
        response.raise_for_status()
        return True
    except Exception as e:
        print(f'Error updating location {location_id}: {e}')
        return False

def parse_hours_from_text(text):
    """
    Parse business hours from free-form text.
    Returns hours in Google Places API format.
    """
    hours_data = {
        'periods': [],
        'weekday_text': []
    }

    # Common patterns for hours
    # e.g., "Monday: 9:00 AM – 5:00 PM"
    # e.g., "Mon-Fri: 9am-5pm"
    # e.g., "Open 24 hours"

    day_map = {
        'monday': 1, 'mon': 1,
        'tuesday': 2, 'tue': 2, 'tues': 2,
        'wednesday': 3, 'wed': 3,
        'thursday': 4, 'thu': 4, 'thur': 4, 'thurs': 4,
        'friday': 5, 'fri': 5,
        'saturday': 6, 'sat': 6,
        'sunday': 0, 'sun': 0
    }

    # Check for 24 hours
    if '24 hour' in text.lower() or 'open 24' in text.lower():
        hours_data['weekday_text'] = ['Open 24 hours']
        # Single period with no close time indicates 24/7
        hours_data['periods'] = [{'open': {'day': 0, 'time': '0000'}}]
        return hours_data

    lines = text.split('\n')
    for line in lines:
        # Try to find day and time patterns
        # Pattern: "Monday: 9:00 AM – 5:00 PM" or "Monday 9:00 AM – 5:00 PM"
        match = re.search(r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)[:\s]+(\d{1,2}):?(\d{2})?\s*(am|pm)?.*?(\d{1,2}):?(\d{2})?\s*(am|pm)?', line, re.IGNORECASE)

        if match:
            day_str = match.group(1).lower()
            day_num = day_map.get(day_str, None)

            if day_num is not None:
                # Parse open time
                open_hour = int(match.group(2))
                open_min = int(match.group(3)) if match.group(3) else 0
                open_period = match.group(4).lower() if match.group(4) else 'am'

                # Convert to 24-hour format
                if open_period == 'pm' and open_hour != 12:
                    open_hour += 12
                elif open_period == 'am' and open_hour == 12:
                    open_hour = 0

                open_time = f'{open_hour:02d}{open_min:02d}'

                # Parse close time if present
                if match.group(5):
                    close_hour = int(match.group(5))
                    close_min = int(match.group(6)) if match.group(6) else 0
                    close_period = match.group(7).lower() if match.group(7) else 'pm'

                    if close_period == 'pm' and close_hour != 12:
                        close_hour += 12
                    elif close_period == 'am' and close_hour == 12:
                        close_hour = 0

                    close_time = f'{close_hour:02d}{close_min:02d}'

                    period = {
                        'open': {'day': day_num, 'time': open_time},
                        'close': {'day': day_num, 'time': close_time}
                    }
                    hours_data['periods'].append(period)
                    hours_data['weekday_text'].append(line.strip())

    return hours_data if hours_data['periods'] else None

def save_to_json(data, filename):
    """Save data to JSON file"""
    with open(filename, 'w') as f:
        json.dump(data, f, indent=2)
    print(f'Saved to {filename}')

def main():
    import sys

    command = sys.argv[1] if len(sys.argv) > 1 else 'fetch'

    if command == 'fetch':
        print('Fetching locations from Supabase...')
        locations = fetch_locations()

        if locations:
            print(f'Found {len(locations)} locations\n')

            # Save locations to file
            save_to_json(locations, 'locations.json')

            # Show locations without hours
            without_hours = [loc for loc in locations if not loc.get('hours')]
            print(f'\nLocations without hours: {len(without_hours)}')

            for loc in without_hours:
                print(f"  - {loc['name']} ({loc.get('address', 'no address')})")

            print('\nNext: Use web search to find hours for each location')
            print('Then run: python3 fetch_hours.py update hours-data.json')

    elif command == 'update':
        if len(sys.argv) < 3:
            print('Usage: python3 fetch_hours.py update hours-data.json')
            return

        hours_file = sys.argv[2]

        print(f'Loading hours data from {hours_file}...')
        with open(hours_file, 'r') as f:
            hours_data = json.load(f)

        print(f'Found hours data for {len(hours_data)} locations\n')

        success_count = 0
        fail_count = 0

        for item in hours_data:
            location_id = item['id']
            hours = item.get('hours')
            name = item.get('name', location_id)

            if not hours:
                print(f'Skipping {name} (no hours data)')
                continue

            print(f'Updating {name}...')
            if update_location_hours(location_id, hours):
                print(f'  ✓ Success')
                success_count += 1
            else:
                print(f'  ✗ Failed')
                fail_count += 1

        print(f'\n📊 Summary:')
        print(f'  ✅ Success: {success_count}')
        print(f'  ❌ Failed: {fail_count}')

    elif command == 'check':
        print('Checking current hours data in database...')
        locations = fetch_locations()

        if locations:
            with_hours = [loc for loc in locations if loc.get('hours')]
            without_hours = [loc for loc in locations if not loc.get('hours')]

            print(f'\nTotal locations: {len(locations)}')
            print(f'With hours: {len(with_hours)}')
            print(f'Without hours: {len(without_hours)}')

            if without_hours:
                print('\nLocations without hours:')
                for loc in without_hours:
                    print(f"  - {loc['name']} ({loc.get('address', 'no address')})")

    else:
        print('Usage:')
        print('  python3 fetch_hours.py fetch          # Fetch locations')
        print('  python3 fetch_hours.py update FILE    # Update with hours data')
        print('  python3 fetch_hours.py check          # Check status')

if __name__ == '__main__':
    main()
