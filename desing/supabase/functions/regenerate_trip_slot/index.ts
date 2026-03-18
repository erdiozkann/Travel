// supabase/functions/regenerate_trip_slot/index.ts
// Sprint 3: Regenerate a single slot in an existing plan

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RegenerateRequest {
    plan_id: string
    date: string
    slot: 'morning' | 'afternoon' | 'evening'
    constraints: {
        budget_level: 'low' | 'mid' | 'high'
        interests: string[]
        pace: string
    }
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
        const body: RegenerateRequest = await req.json()
        const { plan_id, date, slot, constraints } = body

        // Validate input
        if (!plan_id || !date || !slot || !constraints) {
            return new Response(
                JSON.stringify({ error: 'Missing required fields' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Get the original plan to find city_id
        const { data: plan } = await supabase
            .from('ai_trip_plan')
            .select('result')
            .eq('id', plan_id)
            .maybeSingle()

        // Find city from the plan or use a default approach
        // For now, we'll fetch experiences randomly
        const { data: experiences } = await supabase
            .from('experiences')
            .select('id, title, price_min, price_max, category')
            .limit(20)

        const { data: places } = await supabase
            .from('places')
            .select('id, name, type, price_level')
            .limit(20)

        // Generate alternative (stub AI)
        const replacement = generateAlternativeStub({
            slot,
            constraints,
            experiences: experiences || [],
            places: places || [],
            existingPlanItems: plan?.result?.days || [],
        })

        return new Response(
            JSON.stringify({
                replacement_item: replacement,
                confidence_level: experiences && experiences.length > 3 ? 'high' : 'medium',
            }),
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

// Stub alternative generator
function generateAlternativeStub(params: {
    slot: string
    constraints: { budget_level: string; interests: string[]; pace: string }
    experiences: any[]
    places: any[]
    existingPlanItems: any[]
}): PlanItem {
    const { slot, constraints, experiences, places } = params
    const { budget_level, interests } = constraints

    const costMultiplier = budget_level === 'low' ? 0.7 : budget_level === 'high' ? 1.5 : 1

    // Randomly pick experience or place (different from common ones)
    const useExperience = Math.random() > 0.5

    if (useExperience && experiences.length > 0) {
        // Pick a random experience
        const randomIndex = Math.floor(Math.random() * experiences.length)
        const exp = experiences[randomIndex]
        const costMin = Math.round((exp.price_min || 25) * costMultiplier)
        const costMax = Math.round((exp.price_max || 60) * costMultiplier)

        return {
            slot: slot as 'morning' | 'afternoon' | 'evening',
            type: 'experience',
            id: exp.id,
            title: exp.title,
            estimated_cost: [costMin, costMax],
            why: `Alternative suggestion: Great match for ${interests[0] || 'your interests'}. Highly rated by similar travelers!`,
            duration_minutes: slot === 'evening' ? 120 : 90,
        }
    } else if (places.length > 0) {
        const randomIndex = Math.floor(Math.random() * places.length)
        const place = places[randomIndex]
        const basePrice = place.price_level === 1 ? 15 : place.price_level === 2 ? 35 : 55
        const costMin = Math.round(basePrice * 0.8 * costMultiplier)
        const costMax = Math.round(basePrice * 1.3 * costMultiplier)

        return {
            slot: slot as 'morning' | 'afternoon' | 'evening',
            type: 'place',
            id: place.id,
            title: place.name,
            estimated_cost: [costMin, costMax],
            why: `Alternative: A hidden gem perfect for ${interests[Math.floor(Math.random() * interests.length)] || 'exploration'}!`,
            duration_minutes: 75,
        }
    }

    // Fallback
    return {
        slot: slot as 'morning' | 'afternoon' | 'evening',
        type: 'experience',
        id: crypto.randomUUID(),
        title: `Alternative ${slot} Activity`,
        estimated_cost: [25, 50],
        why: 'AI-suggested alternative based on your preferences.',
        duration_minutes: 60,
    }
}
