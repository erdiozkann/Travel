# QUICKSTART_SUPABASE.md
Complete Beginner Guide — No Prior Knowledge Required

---

## What You Will Do

By the end of this guide, you will have:
- A working Supabase project with database
- API keys for your Flutter app
- Edge Function secrets configured
- Storage buckets for media files
- Authentication enabled

Estimated time: **30-45 minutes**

---

## Part 1: Create Your Supabase Project

### Step 1.1: Sign Up / Log In
1. Open your browser
2. Go to **https://supabase.com**
3. Click **Start your project** (green button, top right)
4. Click **Continue with GitHub** (recommended) or sign up with email
5. Authorize Supabase if prompted

### Step 1.2: Create New Project
1. After login, you'll see the Supabase Dashboard
2. Click **+ New project** (green button)
3. Fill in the form:
   - **Organization**: Select your org or create one
   - **Name**: `travel-mvp`
   - **Database Password**: Click "Generate a password" → **COPY AND SAVE THIS PASSWORD SOMEWHERE SAFE**
   - **Region**: Choose closest to your users (e.g., `eu-central-1` for Europe)
4. Click **Create new project**
5. Wait 2-3 minutes for setup to complete (you'll see a loading spinner)

---

## Part 2: Get Your API Keys

### Step 2.1: Navigate to API Settings
1. In the left sidebar, click the **gear icon** (⚙️) → **Settings**
2. Click **API** in the Settings submenu

### Step 2.2: Copy Your Keys
You will see a page with:
- **Project URL**: Something like `https://abcdefghijkl.supabase.co`
- **Project API keys**: Two keys listed

Copy these and save them:

```
SUPABASE_URL=<YOUR_PROJECT_URL>
SUPABASE_ANON_KEY=<YOUR_ANON_PUBLIC_KEY>
```

**Example (with placeholders):**
```env
SUPABASE_URL=https://xyzabc123456.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

⚠️ **Important:**
- `anon` key is PUBLIC — safe to include in your app
- `service_role` key is SECRET — NEVER put this in your app

---

## Part 3: Set Up Edge Function Secrets

Edge Functions need secrets for Stripe, AI, and deep links.

### Option A: Dashboard Method (Easier)

#### Step 3.1: Navigate to Edge Functions
1. In the left sidebar, click **Edge Functions**
2. If you see "Get started with Edge Functions", that's okay — we'll create functions later
3. Click **Manage Secrets** button (or find it in the top-right area)

#### Step 3.2: Add Each Secret
For each secret below, click **+ Add a new secret**:

| Secret Name | Value to Enter | Where to Get It |
|---|---|---|
| `STRIPE_SECRET_KEY` | `sk_test_...` | Stripe Dashboard → Developers → API keys |
| `STRIPE_WEBHOOK_SECRET` | `whsec_...` | Stripe Dashboard → Developers → Webhooks → Your endpoint → Signing secret |
| `APP_BASE_URL` | `https://yourapp.com` | Your app's domain (use `http://localhost:3000` for testing) |
| `AI_PROVIDER` | `gemini` | Just type `gemini` or `opus` |

### Option B: CLI Method (For Developers)

#### Step 3.3: Install Supabase CLI
Open Terminal and run:
```bash
# Install via npm
npm install -g supabase

# Verify installation
supabase --version
```

#### Step 3.4: Login and Link Project
```bash
# Login to Supabase
supabase login

# This will open a browser — click "Authorize"
```

#### Step 3.5: Link Your Project
1. Go to Supabase Dashboard
2. Click **Settings** (⚙️) → **General**
3. Copy your **Reference ID** (looks like `abcdefghijkl`)

```bash
# Link to your project
supabase link --project-ref <YOUR_REFERENCE_ID>

# Enter your database password when prompted
```

#### Step 3.6: Set Secrets via CLI
```bash
supabase secrets set STRIPE_SECRET_KEY=<YOUR_STRIPE_SECRET_KEY>
supabase secrets set STRIPE_WEBHOOK_SECRET=<YOUR_WEBHOOK_SECRET>
supabase secrets set APP_BASE_URL=<YOUR_APP_URL>
supabase secrets set AI_PROVIDER=gemini

# Verify secrets are set
supabase secrets list
```

---

## Part 4: Create Database Tables

### Step 4.1: Open SQL Editor
1. In the left sidebar, click **SQL Editor**
2. Click **+ New query**

### Step 4.2: Create Users Table
Paste this SQL and click **Run** (or press Cmd+Enter):

```sql
-- Create users table (extends auth.users)
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  bio TEXT,
  home_country TEXT,
  languages TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read user profiles
CREATE POLICY "Users are publicly viewable"
  ON public.users FOR SELECT
  USING (true);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- Allow users to insert their own profile
CREATE POLICY "Users can insert own profile"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);
```

### Step 4.3: Create Cities Table
Click **+ New query** and paste:

```sql
-- Create cities table
CREATE TABLE public.cities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  country_code TEXT NOT NULL,
  lat FLOAT NOT NULL,
  lng FLOAT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;

-- Public read
CREATE POLICY "Cities are publicly viewable"
  ON public.cities FOR SELECT
  USING (true);

-- Seed Barcelona
INSERT INTO public.cities (name, country_code, lat, lng)
VALUES ('Barcelona', 'ES', 41.3851, 2.1734);
```

### Step 4.4: Create Remaining Tables
Refer to `SUPABASE_SCHEMA.md` for full table definitions. Key tables:
- `experiences` — bookable activities
- `stays` — accommodation listings  
- `posts` — social feed content
- `booking_experience` — Stripe bookings
- `booking_request_stay` — stay requests (no payment in MVP)

---

## Part 5: Create Storage Buckets

### Step 5.1: Navigate to Storage
1. In the left sidebar, click **Storage**
2. Click **New bucket**

### Step 5.2: Create Each Bucket

Create these buckets one by one:

| Bucket Name | Public | Purpose |
|---|---|---|
| `avatars` | ✅ ON | User profile pictures |
| `post-media` | ❌ OFF | Post images/videos |
| `brand-assets` | ✅ ON | App logo and branding |

For each:
1. Click **New bucket**
2. Enter the name exactly as shown
3. Toggle **Public bucket** as indicated
4. Click **Create bucket**

### Step 5.3: Add Storage Policies
1. Click on the `avatars` bucket
2. Click **Policies** tab
3. Click **New policy** → **For full customization**
4. Paste:

```sql
-- Policy name: Allow public read
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');
```

5. Click **Review** → **Save policy**

Repeat for upload policy:
```sql
-- Policy name: Authenticated users can upload
CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);
```

---

## Part 6: Enable Authentication

### Step 6.1: Check Email Auth (Default)
1. In the left sidebar, click **Authentication**
2. Click **Providers**
3. **Email** should already be enabled (green toggle)

### Step 6.2: Configure Email Templates (Optional)
1. Click **Email Templates** in Authentication menu
2. Customize confirmation and reset emails if desired

### Step 6.3: Add Google OAuth (Optional)
1. In Providers, find **Google**
2. Toggle it ON
3. You'll need:
   - Client ID from Google Cloud Console
   - Client Secret from Google Cloud Console
4. Follow Supabase docs for Google OAuth setup

---

## Part 7: Create Your First Edge Function

### Step 7.1: Create Function Structure
In Terminal:
```bash
cd /path/to/your/project

# Create supabase directory if it doesn't exist
mkdir -p supabase/functions

# Create the checkout function
supabase functions new create_experience_checkout
```

### Step 7.2: Write Function Code
Open `supabase/functions/create_experience_checkout/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from "https://esm.sh/stripe@12.0.0?target=deno"

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2023-10-16',
})

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
  try {
    const { experience_id, quantity, user_id } = await req.json()
    
    // Get experience details
    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    const { data: experience } = await supabase
      .from('experiences')
      .select('*')
      .eq('id', experience_id)
      .single()
    
    if (!experience) {
      return new Response(JSON.stringify({ error: 'Experience not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      })
    }
    
    // Create Stripe checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: 'eur',
          product_data: {
            name: experience.title,
          },
          unit_amount: Math.round(experience.price_min * 100),
        },
        quantity: quantity,
      }],
      mode: 'payment',
      success_url: `${Deno.env.get('APP_BASE_URL')}/booking/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${Deno.env.get('APP_BASE_URL')}/booking/cancel`,
      metadata: {
        experience_id,
        user_id,
        quantity: quantity.toString(),
      },
    })
    
    return new Response(JSON.stringify({ url: session.url }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

### Step 7.3: Deploy Function
```bash
supabase functions deploy create_experience_checkout
```

---

## Verification Checklist

### ✅ Project Created
- [ ] Supabase project exists and is running
- [ ] Database password saved securely

### ✅ API Keys Obtained
- [ ] `SUPABASE_URL` copied and saved
- [ ] `SUPABASE_ANON_KEY` copied and saved
- [ ] Keys stored in a secure location (NOT in git)

### ✅ Edge Function Secrets Set
- [ ] `STRIPE_SECRET_KEY` added
- [ ] `STRIPE_WEBHOOK_SECRET` added
- [ ] `APP_BASE_URL` added
- [ ] `AI_PROVIDER` added
- [ ] Verified with `supabase secrets list`

### ✅ Database Tables Created
- [ ] `users` table exists with RLS enabled
- [ ] `cities` table exists with Barcelona seeded
- [ ] All core tables from schema created

### ✅ Storage Buckets Created
- [ ] `avatars` bucket exists (public)
- [ ] `post-media` bucket exists (private)
- [ ] `brand-assets` bucket exists (public)
- [ ] Policies added to buckets

### ✅ Auth Configured
- [ ] Email auth enabled
- [ ] (Optional) OAuth providers configured

---

## Common Errors and Fixes

### Error 1: "Invalid API key"
**Cause:** Wrong URL or key copied
**Fix:** 
1. Go to Settings → API
2. Verify you copied the FULL URL (including https://)
3. Verify you copied the `anon` key, not `service_role`

### Error 2: "permission denied for table"
**Cause:** RLS policy missing or wrong
**Fix:**
1. Go to Table Editor → click your table
2. Check that RLS is ENABLED
3. Check that policies exist for the operation you're doing

### Error 3: "function not found" for Edge Function
**Cause:** Function not deployed
**Fix:**
```bash
supabase functions deploy <function_name>
```

### Error 4: "STRIPE_SECRET_KEY is not defined"
**Cause:** Secret not set in Edge Functions
**Fix:**
1. Go to Edge Functions → Manage Secrets
2. Add `STRIPE_SECRET_KEY` with your Stripe key
3. Redeploy the function

### Error 5: "JWT expired"
**Cause:** User session timed out
**Fix:** 
- Implement token refresh in your app
- Check Supabase Auth settings for session duration

### Error 6: "new row violates row-level security policy"
**Cause:** RLS policy blocks the insert
**Fix:**
1. Check your INSERT policy has correct `WITH CHECK` clause
2. Verify `auth.uid()` matches the user_id you're inserting

### Error 7: "Storage object not found"
**Cause:** Wrong bucket name or path
**Fix:**
1. Verify bucket exists in Storage
2. Check the file path is correct
3. Verify storage policies allow the operation

### Error 8: "Could not find the function" when calling Edge Function
**Cause:** Function name mismatch or not deployed
**Fix:**
```bash
# List deployed functions
supabase functions list

# Deploy if missing
supabase functions deploy <function_name>
```

### Error 9: "supabase link failed"
**Cause:** Wrong project reference or not logged in
**Fix:**
```bash
# Re-login
supabase login

# Find correct reference ID in Dashboard → Settings → General
supabase link --project-ref <CORRECT_REF_ID>
```

### Error 10: "Rate limit exceeded"
**Cause:** Too many requests to Supabase
**Fix:**
- Add caching to reduce API calls
- Check for infinite loops in your code
- Upgrade Supabase plan if needed

---

## Next Step

Your Supabase backend is ready! Now proceed to:

**→ QUICKSTART_FLUTTER.md**
