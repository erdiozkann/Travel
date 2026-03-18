// supabase/functions/generate_trip_plan/index.ts
// Sprint 3: AI Trip Plan Generation with caching + rate limiting

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TripPlanRequest {
    city_id: string
    date_range: { start: string; end: string }
    budget_level: 'low' | 'mid' | 'high'
    interests: string[]
    pace: 'relaxed' | 'balanced' | 'intense'
    locale: string
}

interface PlanItem {
    slot: 'morning' | 'afternoon' | 'evening'
    type: 'experience' | 'place' | 'stay'
    id: string
    title?: string
    estimated_cost: [number, number]
    why: string
    duration_minutes: number
}

interface PlanDay {
    date: string
    items: PlanItem[]
}

interface TripPlanResult {
    plan_id: string
    days: PlanDay[]
    total_estimated_cost: [number, number]
    confidence_level: 'low' | 'medium' | 'high'
    cache_ttl_seconds: number
}

serve(async (req: Request) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        const supabase = createClient(supabaseUrl, supabaseServiceKey)

        // Get request body
        const body: TripPlanRequest = await req.json()
        const { city_id, date_range, budget_level, interests, pace, locale } = body

        // Validate input
        if (!city_id || !date_range?.start || !date_range?.end || !interests?.length) {
            return new Response(
                JSON.stringify({ error: 'Missing required fields' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Calculate trip days
        const startDate = new Date(date_range.start)
        const endDate = new Date(date_range.end)
        const tripDays = Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24)) + 1

        if (tripDays > 7 || tripDays < 1) {
            return new Response(
                JSON.stringify({ error: 'Trip must be 1-7 days' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Generate cache key
        const cacheKey = JSON.stringify({
            city_id,
            date_range,
            budget_level,
            interests: interests.sort(),
            pace,
        })
        const cacheHash = await hashString(cacheKey)

        // Check cache
        const { data: cachedPlan } = await supabase
            .from('ai_trip_plan')
            .select('*')
            .eq('cache_hash', cacheHash)
            .gt('expires_at', new Date().toISOString())
            .maybeSingle()

        if (cachedPlan) {
            console.log('Returning cached plan:', cachedPlan.id)
            return new Response(
                JSON.stringify(cachedPlan.result),
                { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Rate limiting
        const clientIP = req.headers.get('x-forwarded-for') || 'unknown'
        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString()
        const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()

        // Extract user_id from auth header if present
        const authHeader = req.headers.get('authorization')
        let userId: string | null = null
        if (authHeader?.startsWith('Bearer ')) {
            try {
                const { data: { user } } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''))
                userId = user?.id || null
            } catch {
                // Ignore auth errors, treat as anonymous
            }
        }

        // Rate limit: anonymous = 5/hour per IP
        const { count: ipRequests } = await supabase
            .from('ai_trip_plan_request')
            .select('*', { count: 'exact', head: true })
            .eq('client_ip', clientIP)
            .gt('created_at', oneHourAgo)

        if (!userId && (ipRequests ?? 0) >= 5) {
            return new Response(
                JSON.stringify({ error: 'Rate limit exceeded. Please try again later.' }),
                { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Rate limit: authenticated = 20/day per user
        if (userId) {
            const { count: userRequests } = await supabase
                .from('ai_trip_plan_request')
                .select('*', { count: 'exact', head: true })
                .eq('user_id', userId)
                .gt('created_at', oneDayAgo)

            if ((userRequests ?? 0) >= 20) {
                return new Response(
                    JSON.stringify({ error: 'Daily limit reached. Please try again tomorrow.' }),
                    { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
                )
            }
        }

        // Log request
        await supabase.from('ai_trip_plan_request').insert({
            city_id,
            request_params: body,
            client_ip: clientIP,
            user_id: userId,
            status: 'processing',
        })

        // Fetch available experiences/places for the city
        const { data: experiences } = await supabase
            .from('experiences')
            .select('id, title, price_min, price_max, category')
            .eq('city_id', city_id)
            .limit(50)

        const { data: places } = await supabase
            .from('places')
            .select('id, name, type, price_level')
            .eq('city_id', city_id)
            .limit(50)

        // Generate plan (stub AI - in production, call real AI provider)
        const plan = await generatePlanStub({
            city_id,
            startDate,
            tripDays,
            budget_level,
            interests,
            pace,
            experiences: experiences || [],
            places: places || [],
        })

        // Cache the result
        const cacheTtl = 604800 // 7 days
        const expiresAt = new Date(Date.now() + cacheTtl * 1000).toISOString()

        await supabase.from('ai_trip_plan').insert({
            id: plan.plan_id,
            cache_hash: cacheHash,
            result: plan,
            expires_at: expiresAt,
        })

        return new Response(
            JSON.stringify(plan),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Error:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})

// Stub AI plan generator (replace with real AI in production)
async function generatePlanStub(params: {
    city_id: string
    startDate: Date
    tripDays: number
    budget_level: string
    interests: string[]
    pace: string
    experiences: any[]
    places: any[]
}): Promise<TripPlanResult> {
    const { startDate, tripDays, budget_level, interests, pace, experiences, places } = params

    const days: PlanDay[] = []
    const slots: ('morning' | 'afternoon' | 'evening')[] = ['morning', 'afternoon', 'evening']

    // Determine items per day based on pace
    const itemsPerDay = pace === 'relaxed' ? 2 : pace === 'balanced' ? 3 : 3

    // Cost multiplier based on budget
    const costMultiplier = budget_level === 'low' ? 0.7 : budget_level === 'high' ? 1.5 : 1

    let totalMin = 0
    let totalMax = 0
    let expIndex = 0
    let placeIndex = 0

    for (let d = 0; d < tripDays; d++) {
        const date = new Date(startDate)
        date.setDate(date.getDate() + d)
        const dateStr = date.toISOString().split('T')[0]

        const items: PlanItem[] = []
        const usedSlots = slots.slice(0, itemsPerDay)

        for (const slot of usedSlots) {
            let item: PlanItem

            // Alternate between experiences and places
            if ((expIndex + placeIndex) % 2 === 0 && experiences.length > 0) {
                const exp = experiences[expIndex % experiences.length]
                const costMin = Math.round((exp.price_min || 20) * costMultiplier)
                const costMax = Math.round((exp.price_max || 50) * costMultiplier)

                item = {
                    slot,
                    type: 'experience',
                    id: exp.id,
                    title: exp.title,
                    estimated_cost: [costMin, costMax],
                    why: `Perfect for ${interests[0] || 'your interests'} enthusiasts. ${slot === 'morning' ? 'Great way to start the day!' : slot === 'evening' ? 'Ideal evening activity.' : 'Popular afternoon choice.'}`,
                    duration_minutes: slot === 'evening' ? 120 : 90,
                }
                expIndex++
            } else if (places.length > 0) {
                const place = places[placeIndex % places.length]
                const basePrice = place.price_level === 1 ? 15 : place.price_level === 2 ? 30 : 50
                const costMin = Math.round(basePrice * 0.8 * costMultiplier)
                const costMax = Math.round(basePrice * 1.2 * costMultiplier)

                item = {
                    slot,
                    type: 'place',
                    id: place.id,
                    title: place.name,
                    estimated_cost: [costMin, costMax],
                    why: `Recommended for ${interests[Math.floor(Math.random() * interests.length)] || 'exploration'}. A local favorite!`,
                    duration_minutes: 60,
                }
                placeIndex++
            } else {
                // Fallback if no data
                item = {
                    slot,
                    type: 'experience',
                    id: crypto.randomUUID(),
                    title: `${slot.charAt(0).toUpperCase() + slot.slice(1)} Activity`,
                    estimated_cost: [20, 40],
                    why: 'AI suggested activity based on your preferences.',
                    duration_minutes: 60,
                }
            }

            items.push(item)
            totalMin += item.estimated_cost[0]
            totalMax += item.estimated_cost[1]
        }

        days.push({ date: dateStr, items })
    }

    return {
        plan_id: crypto.randomUUID(),
        days,
        total_estimated_cost: [totalMin, totalMax],
        confidence_level: experiences.length > 5 ? 'high' : experiences.length > 0 ? 'medium' : 'low',
        cache_ttl_seconds: 604800,
    }
}

async function hashString(str: string): Promise<string> {
    const encoder = new TextEncoder()
    const data = encoder.encode(str)
    const hashBuffer = await crypto.subtle.digest('SHA-256', data)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}
