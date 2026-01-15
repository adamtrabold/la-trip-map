# Security and Secrets Management

## Overview

This document explains how secrets are managed in this GitHub Pages static site that uses Supabase as a backend.

## Question: How are secrets handled on a static GitHub Pages setup?

**Answer**: This project uses **Supabase anon key with tight RLS policies** - no edge functions needed.

## Security Architecture

### 1. Public Anon Key (Safe to Expose)

**Location**: `index.html:526`

```javascript
const SUPABASE_KEY = 'sb_publishable_TiO_hACvlsn4mfFazsHTlg_i9BnzCfr';
```

**Why this is safe**:
- The `sb_publishable_` prefix indicates this is Supabase's public anonymous key
- It's **designed** to be embedded in client-side code and visible to anyone
- Similar to Firebase's public config or Mapbox public tokens
- Security is enforced by Row Level Security (RLS) policies, not by hiding the key

**What the anon key can do**:
- ✅ Read public data (controlled by RLS SELECT policies)
- ✅ Make authenticated requests after user login
- ❌ Cannot bypass RLS policies
- ❌ Cannot access admin functions
- ❌ Cannot read/write data without proper RLS permissions

### 2. Row Level Security (RLS) Policies

**Location**: `supabase/migrations/20260115000000_setup_rls_policies.sql`

RLS is the **actual security layer** that protects your data:

```sql
-- Public read access
CREATE POLICY "Public read access"
ON locations FOR SELECT
TO public
USING (true);

-- Authenticated write access
CREATE POLICY "Authenticated users can insert"
ON locations FOR INSERT
TO authenticated
WITH CHECK (true);

-- Similar policies for UPDATE and DELETE
```

**How this works**:
1. **Anyone** with the anon key can read (`SELECT`) locations - intentional for a public trip map
2. **Only authenticated users** can insert, update, or delete locations
3. PostgreSQL enforces these policies at the database level
4. Even if someone has your anon key (which they do, it's in your HTML), they can't bypass RLS

### 3. Authentication

**System**: Supabase Auth (email/password)

**How it works**:
1. User signs up/logs in through the UI
2. Supabase Auth issues a JWT (JSON Web Token)
3. JWT is automatically included in subsequent requests by Supabase client
4. Database verifies JWT and checks user's role (authenticated vs. public)
5. RLS policies grant/deny access based on authentication status

**Session management**:
- Sessions stored in browser `localStorage` by Supabase client
- Automatic token refresh handled by Supabase
- Logout clears tokens and revokes session

### 4. No Edge Functions Required

This project **does not use** Supabase Edge Functions or any serverless functions because:
- RLS policies provide sufficient security for this use case
- All operations (read/write) can be safely exposed to the client
- No complex business logic or secret API keys to protect
- Keeps deployment simple (static HTML on GitHub Pages)

**When you WOULD need edge functions**:
- Integrating with third-party APIs that require secret keys
- Complex authorization logic beyond row-level permissions
- Server-side computations or data transformations
- Payment processing or other sensitive operations

## Security Model Summary

| Component | Visibility | Security Mechanism |
|-----------|-----------|-------------------|
| Supabase URL | Public | Always safe to expose |
| Anon Key | Public | Safe to expose, RLS enforces permissions |
| User Passwords | Private | Hashed by Supabase Auth, never exposed |
| Session Tokens | Browser only | JWT validated by database |
| Database Data | Controlled | RLS policies enforce access control |

## Comparison to Alternatives

### Option 1: What we use - Anon Key + RLS
✅ Simple deployment (static site)
✅ No server required
✅ Built-in auth
✅ Automatic scaling
✅ Perfect for public data with authenticated modifications

### Option 2: Edge Functions
❌ More complex
❌ Requires serverless deployment
✅ Needed only for secret API keys or complex logic
❌ Overkill for this project

### Option 3: Fully Public Database (No RLS)
❌ **DANGEROUS** - anyone can modify data
❌ No authentication
❌ Not recommended unless data is truly disposable

## Attack Surface Analysis

### What attackers CAN'T do (even with the anon key):

❌ Insert, update, or delete locations without authentication
❌ Access other Supabase projects
❌ View user passwords (hashed by Supabase)
❌ Bypass RLS policies
❌ Access admin functions
❌ Execute arbitrary SQL

### What attackers CAN do:

✅ View all public locations (intentional - it's a public trip map)
✅ Create an account (intentional - controlled by you via Supabase dashboard)
✅ See the database schema through API introspection (not sensitive for this use case)

### Potential risks and mitigations:

**Risk**: Spam signups
- **Mitigation**: Enable email confirmation in Supabase settings
- **Mitigation**: Monitor user list in Supabase dashboard
- **Mitigation**: Add CAPTCHA if needed (future enhancement)

**Risk**: Rate limiting
- **Mitigation**: Supabase has built-in rate limiting per IP
- **Mitigation**: Can add custom rate limiting in edge functions if needed

**Risk**: Data vandalism by authenticated users
- **Mitigation**: Only share login credentials with trusted people
- **Mitigation**: Use Supabase dashboard to manage users
- **Mitigation**: Can add audit logging if needed (future enhancement)

## Best Practices Followed

✅ **RLS enabled** on all tables
✅ **Least privilege** - public can only read, authenticated can modify
✅ **Public key separation** - using anon key, not service role key
✅ **Authentication required** for all mutations
✅ **Client-side security** - Supabase client handles JWT automatically
✅ **Version controlled** - RLS policies stored in migration files
✅ **Documented** - Security model clearly explained

## Best Practices NOT Followed (and why)

❌ **Environment variables for anon key**
- Not needed - anon key is designed to be public
- Would complicate GitHub Pages deployment
- Provides no security benefit for Supabase anon keys

❌ **Service role key**
- Correctly NOT used - this would be dangerous to expose
- Service role key bypasses RLS and should only be used server-side

❌ **Email confirmation**
- Optional - can be enabled in Supabase settings
- Disabled by default for easier testing
- Recommend enabling for production

## Migration from Current "Allow All" Policy

Your database currently has an overly permissive "Allow all operations" policy that Supabase warns about.

### Current State (Insecure):
```sql
CREATE POLICY "Allow all operations"
ON locations FOR ALL
USING (true);
```

This allows **anyone** with your anon key to modify data without authentication.

### New State (Secure):
```sql
-- Separate policies for read (public) and write (authenticated)
CREATE POLICY "Public read access" ON locations FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert" ON locations FOR INSERT TO authenticated WITH CHECK (true);
-- Plus UPDATE and DELETE policies for authenticated users only
```

### How to Apply:

Follow the instructions in `SETUP.md` to apply the migration SQL file.

## Monitoring and Maintenance

### Regular checks:
1. **Review users**: Check Supabase → Authentication → Users for unexpected accounts
2. **Monitor logs**: Check Supabase → Logs for suspicious activity
3. **Audit policies**: Verify RLS policies haven't been accidentally disabled
4. **Update dependencies**: Keep Supabase client library up to date

### Red flags:
- Unexpected user signups
- High API usage from unknown IPs
- RLS policy violation errors (check if someone is probing your database)
- Disabled RLS on tables

## Conclusion

This security model is:
- ✅ **Appropriate** for a personal trip planning app with public read access
- ✅ **Industry standard** for Supabase static site deployments
- ✅ **Simple** to maintain and understand
- ✅ **Scalable** without additional infrastructure

The Supabase anon key is **safe to commit to Git** and **safe to expose in client-side code** because RLS policies enforce all actual security.
