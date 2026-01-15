# Setup and Testing Guide

This guide will help you set up authentication and test the security implementation.

## Step 1: Apply RLS Policies to Supabase

Before the authentication will work properly, you need to apply the RLS policies to your Supabase database.

### Using Supabase Dashboard (Easiest):

1. Go to https://supabase.com/dashboard/project/jgvckilmltimabfdvaly
2. Click on **SQL Editor** in the left sidebar
3. Copy the contents of `supabase/migrations/20260115000000_setup_rls_policies.sql`
4. Paste into the SQL editor
5. Click **Run** to execute the migration

### Using Supabase CLI (Alternative):

```bash
# Install Supabase CLI
npm install -g supabase

# Link to your project
supabase link --project-ref jgvckilmltimabfdvaly

# Apply migrations
supabase db push
```

## Step 2: Create User Accounts in Supabase

**Public signups are disabled.** Only pre-created accounts can log in.

You must manually create accounts for the two authorized users:

1. Go to https://supabase.com/dashboard/project/jgvckilmltimabfdvaly
2. Navigate to **Authentication** → **Users**
3. Click **Add user** → **Create new user**
4. Enter email: `adamtrabold@gmail.com` and set a password
5. Click **Create user**
6. Repeat steps 3-5 for `ericatrabold@gmail.com`

**Important**:
- The app has no signup button - users can only log in with existing accounts
- Only these two emails can modify locations (enforced by RLS policies)
- Anyone else cannot create an account or modify data

## Step 3: Test the Implementation

### Test 1: Public Read Access (No Auth Required)

1. Open your site in an **incognito/private browser window**
2. You should see the map and all existing locations
3. Verify you can:
   - ✅ View the map
   - ✅ See all locations in the list
   - ✅ Click on markers to see popups
   - ✅ Filter by categories
   - ✅ Use the "center me" button

### Test 2: Protected Write Access (Auth Required)

Still in the incognito window (or use an account you manually created):

1. Click the **+ button** to add a location
   - **Expected**: Login modal appears (no signup button, only login)
2. Enter one of the authorized emails (adamtrabold@gmail.com or ericatrabold@gmail.com) and password
3. Click **Login**
   - **Expected**: You're logged in immediately
4. After logging in, you should see:
   - ✅ Account icon button appears in top-right
   - ✅ Clicking it shows your email and logout button
5. Try adding a location:
   - ✅ Should succeed without showing login modal
6. Try marking a location as visited:
   - ✅ Should work immediately
7. Try deleting a location:
   - ✅ Should work immediately

### Test 3: Verify Auth Persists on Refresh

1. While logged in, refresh the page
   - **Expected**: You're still logged in (green status indicator shows)
2. Try modifying a location
   - **Expected**: Works without requiring re-login

### Test 4: Logout and Verify Protection

1. Click the account icon button, then click **Logout** in the dropdown
   - **Expected**: Account icon disappears
2. Try to add a location
   - **Expected**: Login modal appears again
3. Try to mark a location as visited
   - **Expected**: Login modal appears

### Test 5: Verify RLS Policies Work

To verify the RLS policies are actually protecting your data:

1. Log out of the app
2. Open browser DevTools (F12)
3. Go to Console tab
4. Try to insert a record manually:

```javascript
// This should FAIL with an RLS policy error
fetch('https://jgvckilmltimabfdvaly.supabase.co/rest/v1/locations', {
  method: 'POST',
  headers: {
    'apikey': 'sb_publishable_TiO_hACvlsn4mfFazsHTlg_i9BnzCfr',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    name: 'Hack attempt',
    category: 'other',
    lat: 34.05,
    lng: -118.24
  })
}).then(r => r.json()).then(console.log)
```

**Expected result**: You should get an error like "new row violates row-level security policy"

## Troubleshooting

### "Failed to add" or "Failed to update" errors

- Make sure you applied the RLS migrations
- Check that you're logged in (green status indicator visible)
- Try logging out and back in

### Signup doesn't work

- Check that Email provider is enabled in Supabase
- If email confirmation is enabled, check your email (including spam)
- Try using a different email address

### Can't see auth status after login

- Check browser console for errors
- Make sure the Supabase JS library loaded correctly
- Try clearing browser cache and refreshing

### RLS policy errors in console

This is expected for unauthenticated write attempts - it means the security is working!

## What's Protected Now

✅ **Public can view**: Anyone can see all locations without logging in
✅ **Auth required to modify**: Must be logged in to add, edit, or delete
✅ **Session persistence**: Stay logged in across page refreshes
✅ **No sensitive data exposure**: Supabase anon key is safe to expose publicly

## Security Model Summary

- **Anon key**: Publicly visible in HTML (this is safe and normal for Supabase)
- **RLS policies**: Enforce read-only access for anonymous users
- **Authentication**: Email/password stored securely by Supabase
- **Session tokens**: Automatically managed by Supabase client library
