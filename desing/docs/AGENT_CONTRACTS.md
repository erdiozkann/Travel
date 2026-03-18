

## GLOBAL RULES

- Mobile app NEVER calls AI directly
- Mobile → Backend → Agent → DB Cache → Mobile
- All outputs must be structured JSON
- All outputs MUST include:
  - confidence_level
  - cache_ttl_seconds
- No agent performs destructive actions
- No agent changes product scope

---

## 1) CityResearchAgent

### INPUT
```json
{
  "city_id": "uuid",
  "locale": "en|de|tr",
  "refresh_mode": "scheduled|on_demand"
}

OUTPUT

{
  "city_id": "uuid",
  "summary": "string",
  "top_areas": ["string"],
  "local_areas": ["string"],
  "tourist_traps": ["string"],
  "daily_budget_estimate": {
    "low": [0, 0],
    "mid": [0, 0],
    "high": [0, 0],
    "currency": "EUR"
  },
  "confidence_level": "low|medium|high",
  "cache_ttl_seconds": 604800
}


⸻

2) RankingAgent (Map / Explore)

INPUT

{
  "city_id": "uuid",
  "viewport": {
    "ne": { "lat": 0, "lng": 0 },
    "sw": { "lat": 0, "lng": 0 }
  },
  "filters": {
    "type": "place|experience|stay",
    "categories": ["string"],
    "price_level": ["€","€€","€€€"],
    "min_rating": 0,
    "local_preference": "local|balanced|tourist"
  }
}

OUTPUT

{
  "items": [
    {
      "type": "place|experience|stay",
      "id": "uuid",
      "rank_score": 0,
      "local_score": 0,
      "price_hint": [0, 0],
      "pin": { "lat": 0, "lng": 0 }
    }
  ],
  "confidence_level": "low|medium|high",
  "cache_ttl_seconds": 86400
}


⸻

3) PricingAgent

INPUT

{
  "target_type": "place|experience|stay",
  "target_id": "uuid",
  "currency": "EUR"
}

OUTPUT

{
  "price_level": "€|€€|€€€",
  "price_range": [0, 0],
  "confidence_level": "low|medium|high",
  "cache_ttl_seconds": 259200
}


⸻

4) ExperienceSummaryAgent

INPUT

{
  "experience_id": "uuid",
  "locale": "en|de|tr"
}

OUTPUT

{
  "experience_id": "uuid",
  "ai_summary": "string",
  "highlights": ["string"],
  "who_its_for": ["string"],
  "cancellation_hint": "string",
  "confidence_level": "low|medium|high",
  "cache_ttl_seconds": 604800
}


⸻

5) StayDiscoveryAgent

INPUT

{
  "city_id": "uuid",
  "check_in": "YYYY-MM-DD",
  "check_out": "YYYY-MM-DD",
  "guests": 0,
  "filters": {
    "room_type": "entire_place|private_room|shared_room",
    "price_range": [0, 0],
    "min_rating": 0
  }
}

OUTPUT

{
  "stays": [
    {
      "stay_id": "uuid",
      "rank_score": 0,
      "price_per_night": [0, 0],
      "verified_host": true
    }
  ],
  "confidence_level": "low|medium|high",
  "cache_ttl_seconds": 3600
}


⸻

6) BookingRequestAgent (Stay)

INPUT

{
  "stay_id": "uuid",
  "user_id": "uuid",
  "check_in": "YYYY-MM-DD",
  "check_out": "YYYY-MM-DD",
  "guests": 0,
  "message": "string"
}

OUTPUT

{
  "valid": true,
  "issues": [],
  "estimated_total": [0, 0],
  "next_step": "submit_request",
  "confidence_level": "low|medium|high",
  "cache_ttl_seconds": 0
}


⸻

7) TripPlannerAgent

INPUT

{
  "city_id": "uuid",
  "date_range": {
    "start": "YYYY-MM-DD",
    "end": "YYYY-MM-DD"
  },
  "budget_level": "low|mid|high",
  "interests": ["string"],
  "pace": "relaxed|balanced|intense"
}

OUTPUT

{
  "plan_id": "uuid",
  "days": [
    {
      "date": "YYYY-MM-DD",
      "items": [
        {
          "slot": "morning|afternoon|evening",
          "type": "place|experience",
          "id": "uuid",
          "estimated_cost": [0, 0],
          "why": "string"
        }
      ]
    }
  ],
  "total_estimated_cost": [0, 0],
  "confidence_level": "low|medium|high",
  "cache_ttl_seconds": 604800
}


⸻

8) ContentSafetyAgent

INPUT

{
  "post_id": "uuid",
  "caption": "string",
  "media_urls": ["string"]
}

OUTPUT

{
  "safe": true,
  "flags": ["spam|nudity|hate|scam|other"],
  "recommended_action": "allow|review|remove",
  "confidence_level": "low|medium|high",
  "cache_ttl_seconds": 0
}


⸻

9) FeedRankingAgent

INPUT

{
  "user_id": "uuid",
  "limit": 20,
  "cursor": "string"
}

OUTPUT

{
  "posts": [
    {
      "post_id": "uuid",
      "rank_score": 0,
      "is_sponsored": false
    }
  ],
  "next_cursor": "string",
  "confidence_level": "low|medium|high",
  "cache_ttl_seconds": 300
}


⸻

10) ModerationDecisionAgent (Admin)

INPUT

{
  "report_id": "uuid",
  "target_type": "post|review|stay|experience|host",
  "reason": "string"
}

OUTPUT

{
  "risk_score": 0,
  "recommended_action": "ignore|warn|suspend|ban|review",
  "confidence_level": "low|medium|high",
  "cache_ttl_seconds": 0
}


⸻

FINAL NOTE

If something is unclear:
	•	Ask
	•	Do not assume
	•	Do not invent new fields

---

