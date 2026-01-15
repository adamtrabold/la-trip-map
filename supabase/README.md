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
- **Authorized insert**: Only adamtrabold@gmail.com and ericatrabold@gmail.com can add new locations
- **Authorized update**: Only adamtrabold@gmail.com and ericatrabold@gmail.com can mark locations as visited/unvisited
- **Authorized delete**: Only adamtrabold@gmail.com and ericatrabold@gmail.com can delete locations

This ensures that your database is publicly readable but only modifiable by the two authorized users.

### How It Works

The RLS policies check the authenticated user's email address using:
```sql
auth.jwt() ->> 'email' IN ('adamtrabold@gmail.com', 'ericatrabold@gmail.com')
```

If someone else creates an account and tries to add/edit/delete locations, the database will reject the request with an RLS policy violation error.

## Security Model

- **Anon key**: Safe to expose publicly (used for read-only operations)
- **Authentication**: Required for any modifications (INSERT, UPDATE, DELETE)
- **No sensitive data**: This app doesn't store personal information beyond trip locations
