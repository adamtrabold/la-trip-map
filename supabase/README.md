# Supabase Configuration

This directory contains database migrations and configuration for the LA Trip Map application.

## Applying Migrations

### Option 1: Via Supabase Dashboard SQL Editor
1. Go to your Supabase project: https://supabase.com/dashboard/project/jgvckilmltimabfdvaly
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `migrations/20260115000000_setup_rls_policies.sql`
4. Click **Run** to apply the policies

### Option 2: Via Supabase CLI (Recommended for future updates)
```bash
# Install Supabase CLI if you haven't already
npm install -g supabase

# Link your project
supabase link --project-ref jgvckilmltimabfdvaly

# Apply migrations
supabase db push
```

## RLS Policies Explained

The migration sets up Row Level Security (RLS) with the following policies:

- **Public read access**: Anyone can view locations (no authentication required)
- **Authenticated insert**: Only authenticated users can add new locations
- **Authenticated update**: Only authenticated users can mark locations as visited/unvisited
- **Authenticated delete**: Only authenticated users can delete locations

This ensures that your database is publicly readable but only modifiable by authorized users.

## Security Model

- **Anon key**: Safe to expose publicly (used for read-only operations)
- **Authentication**: Required for any modifications (INSERT, UPDATE, DELETE)
- **No sensitive data**: This app doesn't store personal information beyond trip locations
