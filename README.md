Map view of places we may want to visit in LA. claude pulls from an apple note screenshot, finds addresses, puts them in supabase. this is an ugly but functional view on their physical location, complete with location access so we can take advantage when another thing we thought might be cool is near where we currently are.

## Features

- 🗺️ Interactive map of Los Angeles locations
- 📍 Add, view, and manage points of interest
- ✅ Mark locations as visited
- 🔍 Filter by category (restaurants, cafes, bars, attractions, etc.)
- 📱 Mobile-friendly with geolocation support
- 🔐 Public read access, authenticated modifications

## Security

This app uses **Supabase with Row Level Security (RLS)** policies:
- ✅ Anyone can view locations (public read access)
- 🔐 Authentication required to add, edit, or delete locations
- 🔑 Supabase anon key safely exposed in client code (protected by RLS)

**📖 Read more**: See [SECURITY.md](SECURITY.md) for detailed security architecture

## Setup

This is a static site deployed to GitHub Pages. To set up authentication and security:

1. Apply RLS policies to Supabase (see [SETUP.md](SETUP.md))
2. Enable email authentication in Supabase dashboard
3. Deploy to GitHub Pages (automatic via GitHub Actions)

**📖 Read more**: See [SETUP.md](SETUP.md) for step-by-step instructions

## Architecture

- **Frontend**: Vanilla JavaScript, Leaflet.js for maps
- **Backend**: Supabase (PostgreSQL + Auth)
- **Hosting**: GitHub Pages (static site)
- **Geocoding**: OpenStreetMap Nominatim API
