# Foursquare Places Seed Script

Fetches real business data from **Foursquare Places API v3** (free tier: 16,500 calls/day)
and populates the Supabase database with experiences and places for all supported cities.

## Cities Covered (12 cities)
Barcelona, Lisbon, Amsterdam, Paris, Rome, Berlin, Tokyo, Bali, New York, Istanbul, Mexico City, Bangkok

## Categories Fetched per City
- 🍽️ Restaurants → `experiences`
- ☕ Cafes → `places`
- 🍸 Bars → `experiences`
- 🏛️ Attractions/Museums → `experiences`
- 🌿 Parks/Beaches → `places`/`experiences`
- 🛍️ Shopping → `places`

---

## Setup

### 1. Get Foursquare API Key (FREE)

1. Go to [developer.foursquare.com](https://developer.foursquare.com)
2. Click **"Sign Up"** → Create account
3. Click **"+ Create a new project"**
4. Go to **API Keys** tab
5. Copy the **API Key** (it's a long string — use it as `Bearer YOUR_KEY`)

### 2. Get Supabase Service Role Key

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project → **Settings** → **API**
3. Copy **Service Role** key (⚠️ NOT the anon key)

### 3. Create `.env` file in this directory

```bash
cp .env.example .env
```

Edit `.env`:
```env
FOURSQUARE_API_KEY=Bearer fsq3abc123...your_key_here
SUPABASE_URL=https://jhpvyyhqxilvnqwlqccb.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...your_service_role_key
```

### 4. Run the Seed Script

```bash
npm run seed
```

Expected output:
```
🚀 Foursquare → Supabase Seed Script
=====================================

📦 Upserting cities...
✅ 12 cities seeded

🌆 Found 12 cities in DB

  📍 Seeding Barcelona...
    ↳ restaurant: 20 results
    ↳ cafe: 20 results
    ↳ bar: 20 results
    ...
    ✅ Upserted 140 experiences
    ✅ Upserted 60 places

  📍 Seeding Lisbon...
  ...

✨ Seed complete!
```

---

## Re-running
The script uses **upsert** with `(title, city_id)` as conflict key — safe to re-run.

## Rate Limits
- Free tier: **16,500 calls/day**
- Script uses: ~120 calls per run (12 cities × 10 categories)
- Far below the limit ✅
