/**
 * Overpass API (OpenStreetMap) → Supabase Seed Script
 *
 * Usage:
 *   node seed_overpass.js
 *
 * COMPLETELY FREE - No API keys needed.
 * Data source: OpenStreetMap via Overpass API.
 */

require('dotenv').config({ path: '../app/.env' });
require('dotenv').config({ path: '.env' }); // local override

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_KEY) {
    console.error('\n❌  Missing Supabase env vars. Ensure desing/scripts/.env has:');
    console.error('   SUPABASE_URL=https://jhpvyyhqxilvnqwlqccb.supabase.co');
    console.error('   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key\n');
    process.exit(1);
}

// ── Overpass Tags Mapping ──────────────────────────────────────────────────
// Map our categories to OSM tags
const CATEGORIES = {
    restaurant: 'amenity=restaurant',
    cafe: 'amenity=cafe',
    bar: 'amenity=bar',
    museum: 'tourism=museum',
    attraction: 'tourism=attraction',
    hotel: 'tourism=hotel',
    viewpoint: 'tourism=viewpoint',
    beach: 'natural=beach',
    park: 'leisure=park',
    shopping: 'shop=mall',
};

// Map OSM category -> our DB table type
const CATEGORY_TO_TYPE = {
    restaurant: 'experience',
    cafe: 'place',
    bar: 'experience',
    museum: 'experience',
    attraction: 'experience',
    hotel: 'stay',
    viewpoint: 'place',
    beach: 'experience',
    park: 'place',
    shopping: 'place',
};

// ── Cities to seed ─────────────────────────────────────────────────────────
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
    { name: 'London', country_code: 'GB', lat: 51.5074, lng: -0.1278 },
    { name: 'Milan', country_code: 'IT', lat: 45.4642, lng: 9.1900 },
];

// ── Overpass API Helper ────────────────────────────────────────────────────
async function fetchOverpass(lat, lng, catTag, radius = 5000, limit = 15) {
    const query = `
    [out:json][timeout:25];
    (
      node[${catTag}](around:${radius},${lat},${lng});
      way[${catTag}](around:${radius},${lat},${lng});
    );
    out center ${limit};
  `;

    const endpoints = [
        'https://overpass-api.de/api/interpreter',
        'https://overpass.kumi.systems/api/interpreter',
        'https://lz4.overpass-api.de/api/interpreter'
    ];

    let lastError = null;

    for (const endpoint of endpoints) {
        const url = `${endpoint}?data=${encodeURIComponent(query)}`;
        try {
            const res = await fetch(url, {
                headers: {
                    'User-Agent': 'TravelAppSeedScript/1.0 (contact@example.com)'
                }
            });

            if (!res.ok) {
                if (res.status === 429) {
                    lastError = new Error('Rate limited');
                    continue; // try next endpoint
                }
                lastError = new Error(`Overpass ${res.status}: ${await res.text()}`);
                continue; // try next endpoint
            }

            const data = await res.json();
            return data.elements || [];
        } catch (err) {
            lastError = err;
        }
    }

    throw lastError;
}

// ── Supabase REST Help ─────────────────────────────────────────────────────
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

// ── Logic Helpers ──────────────────────────────────────────────────────────
function generatePrice(type, catKey) {
    if (type === 'stay') return { min: 60, max: 250 };
    if (catKey === 'restaurant' || catKey === 'bar') return { min: 15, max: 80 };
    return { min: 0, max: 40 };
}

// OSM data doesn't have ratings/photos by default.
// We'll generate semi-random realistic values for a better map look.
function generateSeedData(name, type) {
    const seed = name.length % 5;
    return {
        rating: (4 + (seed / 5)).toFixed(1),
        reviews: 10 + (seed * 15),
    };
}

// ── Main Seed Logic ────────────────────────────────────────────────────────
async function seedCity(city, cityId) {
    console.log(`\n  📍 Seeding ${city.name} [Overpass]...`);

    const experienceRows = [];
    const stayRows = [];
    const placeRows = [];

    for (const catKey of Object.keys(CATEGORIES)) {
        try {
            const tag = CATEGORIES[catKey];
            const results = await fetchOverpass(city.lat, city.lng, tag, 5000, 15);
            const type = CATEGORY_TO_TYPE[catKey];
            console.log(`    ↳ ${catKey}: ${results.length} found`);

            for (const el of results) {
                const lat = el.lat || el.center?.lat;
                const lng = el.lon || el.center?.lon;
                const name = el.tags?.name;
                if (!lat || !lng || !name) continue;

                const { rating, reviews } = generateSeedData(name, type);
                const { min, max } = generatePrice(type, catKey);

                if (type === 'stay') {
                    stayRows.push({
                        title: name,
                        city_id: cityId,
                        lat, lng,
                        rating,
                        review_count: reviews,
                        price_min: min,
                        price_max: max,
                        currency: 'EUR',
                        status: 'active',
                        is_sponsored: false,
                        media_urls: [],
                        neighborhood: el.tags?.['addr:suburb'] || null,
                        room_type: 'entire_place',
                    });
                } else if (type === 'experience') {
                    experienceRows.push({
                        title: name,
                        city_id: cityId,
                        lat, lng,
                        category: catKey,
                        rating,
                        review_count: reviews,
                        price_min: min,
                        price_max: max,
                        currency: 'EUR',
                        status: 'active',
                        is_active: true,
                        is_sponsored: false,
                        local_score: 0.5,
                        media_urls: [],
                        description: el.tags?.description || el.tags?.['addr:full'] || '',
                    });
                } else {
                    placeRows.push({
                        name: name,
                        city_id: cityId,
                        lat, lng,
                        category: catKey,
                        rating,
                        review_count: reviews,
                        price_level: min > 20 ? '€€' : '€',
                        is_sponsored: false,
                        local_score: 0.5,
                        media_urls: [],
                    });
                }
            }

            // Respect Overpass rate limits (wait 1s between categories)
            await new Promise(r => setTimeout(r, 1000));
        } catch (err) {
            console.error(`    ⚠️  ${catKey} fetch failed:`, err.message);
            await new Promise(r => setTimeout(r, 5000)); // wait longer on error
        }
    }

    // Batch Upsert
    if (experienceRows.length) await supabaseUpsert('experiences', experienceRows, 'title,city_id');
    if (placeRows.length) await supabaseUpsert('places', placeRows, 'name,city_id');
    if (stayRows.length) {
        // Note: Stays need host_id. Handled at DB level or skip if missing.
        console.log(`    ℹ️  Collected ${stayRows.length} stays (hosting logic pending real users)`);
    }

    console.log(`    ✅ ${city.name} population complete`);
}

async function main() {
    console.log('🚀 Overpass API → Supabase Seed Script');
    console.log('=====================================\n');

    // 1. Sync cities
    console.log('📦 Syncing cities...');
    const cityRows = CITIES.map(c => ({
        name: c.name,
        country_code: c.country_code,
        lat: c.lat,
        lng: c.lng,
        is_active: true,
        country: c.country_code,
    }));
    await supabaseUpsert('cities', cityRows, 'name');
    console.log(`✅ ${cityRows.length} cities active\n`);

    // 2. Load active cities
    const cities = await supabaseSelect('cities', 'select=id,name,lat,lng&is_active=eq.true');
    console.log(`🌆 Found ${cities.length} cities to populate\n`);

    // 3. Populate
    for (const city of cities) {
        await seedCity(city, city.id);
    }

    console.log('\n\n✨ All cities populated with real OSM data!');
}

main().catch(err => {
    console.error('Fatal error:', err);
    process.exit(1);
});
