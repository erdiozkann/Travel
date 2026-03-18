/**
 * Foursquare Places API v3 → Supabase Seed Script
 *
 * Usage:
 *   node seed_foursquare.js
 *
 * Requires .env at project root with:
 *   FOURSQUARE_API_KEY=your_key_here
 *   SUPABASE_URL=https://...
 *   SUPABASE_SERVICE_ROLE_KEY=...  (NOT anon key — needs write access)
 *
 * Free tier: 16,500 API calls/day — more than enough for seed.
 */

require('dotenv').config({ path: '../app/.env' });
require('dotenv').config({ path: '.env' }); // local override

const FSQ_KEY = process.env.FOURSQUARE_API_KEY;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!FSQ_KEY || !SUPABASE_URL || !SUPABASE_KEY) {
    console.error('\n❌  Missing env vars. Create desing/scripts/.env with:');
    console.error('   FOURSQUARE_API_KEY=your_key');
    console.error('   SUPABASE_URL=https://jhpvyyhqxilvnqwlqccb.supabase.co');
    console.error('   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key\n');
    process.exit(1);
}

// ── Foursquare Category IDs ────────────────────────────────────────────────
const CATEGORIES = {
    restaurant: '13065', // Restaurants
    cafe: '13032', // Coffee shops & cafes
    bar: '13003', // Bar
    attraction: '16000', // Landmarks & Outdoors
    museum: '10027', // Museum
    hotel: '19014', // Hotel
    nightlife: '13006', // Nightlife Spot
    shopping: '17000', // Shopping
    beach: '16019', // Beach
    park: '16032', // Park
};

// Map Foursquare categories → our DB types
const CATEGORY_TO_TYPE = {
    restaurant: 'experience',
    cafe: 'place',
    bar: 'experience',
    attraction: 'experience',
    museum: 'experience',
    hotel: 'stay',
    nightlife: 'experience',
    shopping: 'place',
    beach: 'experience',
    park: 'place',
};

// ── Cities to seed ─────────────────────────────────────────────────────────
// These will be inserted/updated in the cities table AND seeded with places.
const CITIES = [
    { name: 'Barcelona', country_code: 'ES', lat: 41.3851, lng: 2.1734 },
    { name: 'Lisbon', country_code: 'PT', lat: 38.7169, lng: -9.1395 },
    { name: 'Amsterdam', country_code: 'NL', lat: 52.3676, lng: 4.9041 },
    { name: 'Paris', country_code: 'FR', lat: 48.8566, lng: 2.3522 },
    { name: 'Rome', country_code: 'IT', lat: 41.9028, lng: 12.4964 },
    { name: 'Berlin', country_code: 'DE', lat: 52.5200, lng: 13.4050 },
    { name: 'Tokyo', country_code: 'JP', lat: 35.6762, lng: 139.6503 },
    { name: 'Bali', country_code: 'ID', lat: -8.3405, lng: 115.0920 },
    { name: 'New York', country_code: 'US', lat: 40.7128, lng: -74.0060 },
    { name: 'Istanbul', country_code: 'TR', lat: 41.0082, lng: 28.9784 },
    { name: 'Mexico City', country_code: 'MX', lat: 19.4326, lng: -99.1332 },
    { name: 'Bangkok', country_code: 'TH', lat: 13.7563, lng: 100.5018 },
];

// ── Foursquare API helper ──────────────────────────────────────────────────
async function searchFoursquare(lat, lng, categoryKey, limit = 30) {
    const catId = CATEGORIES[categoryKey];
    const url = new URL('https://api.foursquare.com/v3/places/search');
    url.searchParams.set('ll', `${lat},${lng}`);
    url.searchParams.set('categories', catId);
    url.searchParams.set('radius', '8000');
    url.searchParams.set('limit', String(limit));
    url.searchParams.set('fields', 'fsq_id,name,geocodes,location,categories,rating,price');
    url.searchParams.set('sort', 'RATING');

    const res = await fetch(url.toString(), {
        headers: {
            'Authorization': FSQ_KEY,
            'Accept': 'application/json',
        },
    });

    if (!res.ok) {
        const errText = await res.text();
        throw new Error(`FSQ ${res.status}: ${errText}`);
    }

    const data = await res.json();
    return data.results || [];
}

// ── Supabase REST helper ───────────────────────────────────────────────────
async function supabaseUpsert(table, rows, conflictOn = 'id') {
    if (!rows.length) return;
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?on_conflict=${conflictOn}`, {
        method: 'POST',
        headers: {
            'apikey': SUPABASE_KEY,
            'Authorization': `Bearer ${SUPABASE_KEY}`,
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
        body: JSON.stringify(rows),
    });
    if (!res.ok) {
        const err = await res.text();
        console.error(`  ⚠️  Supabase ${table} upsert failed:`, err.slice(0, 200));
    }
}

async function supabaseSelect(table, filter = '') {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${filter}`, {
        headers: {
            'apikey': SUPABASE_KEY,
            'Authorization': `Bearer ${SUPABASE_KEY}`,
        },
    });
    return res.json();
}

// ── Price level helper ─────────────────────────────────────────────────────
function priceLevel(fsqPrice) {
    if (!fsqPrice) return null;
    const map = { 1: '€', 2: '€€', 3: '€€€', 4: '€€€€' };
    return map[fsqPrice] || null;
}

function estimatePrice(fsqPrice, type) {
    if (!fsqPrice) return null;
    const baseByType = type === 'stay' ? 80 : type === 'experience' ? 20 : 10;
    return baseByType * fsqPrice;
}

// ── Photo helper ───────────────────────────────────────────────────────────
function getPhotoUrls(photos) {
    if (!photos || !photos.length) return [];
    return photos.slice(0, 3).map(p => `${p.prefix}800x600${p.suffix}`);
}

// ── Main seed logic ────────────────────────────────────────────────────────
async function seedCity(city, cityId) {
    console.log(`\n  📍 Seeding ${city.name}...`);

    const experienceRows = [];
    const stayRows = [];
    const placeRows = [];

    const categoriesToFetch = Object.keys(CATEGORIES);

    for (const catKey of categoriesToFetch) {
        try {
            const results = await searchFoursquare(city.lat, city.lng, catKey, 20);
            const type = CATEGORY_TO_TYPE[catKey];
            console.log(`    ↳ ${catKey}: ${results.length} results`);

            for (const place of results) {
                const geocode = place.geocodes?.main || {};
                const lat = geocode.latitude;
                const lng = geocode.longitude;
                if (!lat || !lng) continue;

                const mediaUrls = []; // Search response doesn't return photos easily — keeping empty for now
                const rating = place.rating ? place.rating / 2 : null; // FSQ is /10, we use /5
                const priceMin = estimatePrice(place.price, type);
                const priceMax = priceMin ? Math.round(priceMin * 1.5) : null;
                const reviewCount = 0; // fsq stats removed from fields for stability

                if (type === 'stay') {
                    stayRows.push({
                        // We use fsq_id as a stable external_id (store in title if needed)
                        title: place.name,
                        city_id: cityId,
                        lat,
                        lng,
                        rating,
                        review_count: reviewCount,
                        price_min: priceMin,
                        price_max: priceMax,
                        currency: 'EUR',
                        media_urls: mediaUrls,
                        status: 'active',
                        is_sponsored: false,
                        neighborhood: place.location?.neighborhood?.[0] || null,
                        room_type: 'entire_place',
                        // We store host_id as a system account — skip for now
                    });
                } else if (type === 'experience') {
                    experienceRows.push({
                        title: place.name,
                        city_id: cityId,
                        lat,
                        lng,
                        category: catKey,
                        rating,
                        review_count: reviewCount,
                        price_min: priceMin,
                        price_max: priceMax,
                        currency: 'EUR',
                        media_urls: mediaUrls,
                        status: 'active',
                        is_active: true,
                        is_sponsored: false,
                        local_score: 0.5,
                        description: place.location?.formatted_address || '',
                    });
                } else {
                    placeRows.push({
                        name: place.name,
                        city_id: cityId,
                        lat,
                        lng,
                        category: catKey,
                        rating,
                        review_count: reviewCount,
                        price_level: priceLevel(place.price),
                        media_urls: mediaUrls,
                        is_sponsored: false,
                        local_score: 0.5,
                    });
                }
            }

            // Rate limit: 4 requests/second on free tier — add small delay
            await new Promise(r => setTimeout(r, 300));
        } catch (err) {
            console.error(`    ⚠️  ${catKey} fetch failed:`, err.message);
        }
    }

    // Batch upsert to Supabase
    // experiences: no unique external key yet, so we insert (may get duplicates on re-run — OK for seed)
    if (experienceRows.length) {
        // Remove id to let Supabase generate (avoid conflicts)
        await supabaseUpsert('experiences', experienceRows.map(r => ({ ...r })), 'title,city_id');
        console.log(`    ✅ Upserted ${experienceRows.length} experiences`);
    }
    if (placeRows.length) {
        await supabaseUpsert('places', placeRows.map(r => ({ ...r })), 'name,city_id');
        console.log(`    ✅ Upserted ${placeRows.length} places`);
    }
    if (stayRows.length) {
        // Stays need a host_id — skip for now (to be set by actual hosts)
        console.log(`    ℹ️  Skipped ${stayRows.length} stays (need real host accounts)`);
    }
}

async function main() {
    console.log('🚀 Foursquare → Supabase Seed Script');
    console.log('=====================================\n');

    // 1. Upsert cities first
    console.log('📦 Upserting cities...');
    const cityRows = CITIES.map(c => ({
        name: c.name,
        country_code: c.country_code,
        lat: c.lat,
        lng: c.lng,
        is_active: true,
        country: c.country_code, // also fill country column
    }));
    await supabaseUpsert('cities', cityRows, 'name');
    console.log(`✅ ${cityRows.length} cities seeded\n`);

    // 2. Fetch current city IDs
    const cities = await supabaseSelect('cities', 'select=id,name,lat,lng&is_active=eq.true');
    console.log(`🌆 Found ${cities.length} cities in DB\n`);

    // 3. Seed each city
    for (const city of cities) {
        const ref = CITIES.find(c => c.name === city.name);
        const lat = ref?.lat || Number(city.lat);
        const lng = ref?.lng || Number(city.lng);
        if (!lat || !lng) {
            console.warn(`  ⚠️  No coordinates for ${city.name}, skipping`);
            continue;
        }
        await seedCity({ ...city, lat, lng }, city.id);
    }

    console.log('\n\n✨ Seed complete!');
}

main().catch(err => {
    console.error('Fatal error:', err);
    process.exit(1);
});
