// Import Google Places for a City
// 
// Calls Google Places API (Nearby Search) and stores results in Supabase
// Trigger: Admin panel "Import Places" button

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ImportRequest {
  city_id: string
  city_name: string
  lat: number
  lng: number
  radius: number // meters, max 50000
  types: string[] // restaurant, cafe, bar, tourist_attraction, etc.
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const GOOGLE_PLACES_API_KEY = Deno.env.get('GOOGLE_PLACES_API_KEY')
    if (!GOOGLE_PLACES_API_KEY) {
      throw new Error('GOOGLE_PLACES_API_KEY not configured')
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get request body
    const { city_id, city_name, lat, lng, radius = 5000, types = ['restaurant', 'cafe', 'bar'] }: ImportRequest = await req.json()

    // Validate
    if (!city_id || !lat || !lng) {
      throw new Error('Missing required fields: city_id, lat, lng')
    }

    // Create import log
    const { data: importLog, error: logError } = await supabase
      .from('place_imports')
      .insert({
        city_id,
        city_name,
        search_type: types.join(','),
        radius_meters: radius,
        status: 'running',
      })
      .select()
      .single()

    if (logError) {
      console.error('Failed to create import log:', logError)
    }

    let totalFound = 0
    let totalInserted = 0
    let totalUpdated = 0

    // Fetch places for each type
    for (const type of types) {
      let nextPageToken: string | null = null
      
      do {
        // Build URL
        let url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=${radius}&type=${type}&key=${GOOGLE_PLACES_API_KEY}`
        
        if (nextPageToken) {
          url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken=${nextPageToken}&key=${GOOGLE_PLACES_API_KEY}`
          // Google requires a short delay before using pagetoken
          await new Promise(r => setTimeout(r, 2000))
        }

        // Fetch from Google
        const response = await fetch(url)
        const data = await response.json()

        if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') {
          console.error(`Google API error for ${type}:`, data.status, data.error_message)
          break
        }

        const results = data.results || []
        totalFound += results.length

        // Process each place
        for (const place of results) {
          const placeData = {
            google_place_id: place.place_id,
            name: place.name,
            formatted_address: place.vicinity || place.formatted_address,
            lat: place.geometry.location.lat,
            lng: place.geometry.location.lng,
            city_id,
            types: place.types,
            primary_type: type,
            rating: place.rating,
            user_ratings_total: place.user_ratings_total,
            price_level: place.price_level,
            photo_references: place.photos?.map((p: any) => p.photo_reference) || [],
            business_status: place.business_status || 'OPERATIONAL',
            updated_at: new Date().toISOString(),
          }

          // Upsert (insert or update)
          const { error: upsertError, data: upsertData } = await supabase
            .from('places')
            .upsert(placeData, { 
              onConflict: 'google_place_id',
              ignoreDuplicates: false 
            })
            .select()

          if (upsertError) {
            console.error('Upsert error:', upsertError)
          } else {
            totalInserted++
          }
        }

        // Get next page token
        nextPageToken = data.next_page_token || null

      } while (nextPageToken)
    }

    // Update import log
    if (importLog?.id) {
      await supabase
        .from('place_imports')
        .update({
          places_found: totalFound,
          places_inserted: totalInserted,
          places_updated: totalUpdated,
          status: 'completed',
          completed_at: new Date().toISOString(),
        })
        .eq('id', importLog.id)
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Imported ${totalInserted} places from ${types.length} categories`,
        stats: {
          found: totalFound,
          inserted: totalInserted,
          updated: totalUpdated,
        }
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('Import error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})
