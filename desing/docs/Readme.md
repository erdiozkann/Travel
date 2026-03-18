# Global Travel Social Marketplace – Product Flow

## Purpose
This document is the **single source of truth** for product scope,
screen flow, and non-negotiable rules.

All contributors (human or AI) must follow this document.
If a feature is not defined here, it does NOT exist in MVP.

---

## Product Summary
A **mobile-first travel marketplace + social platform** that helps users:
- Discover cities
- Explore experiences and stays
- Plan trips with AI
- Share real experiences socially

This is **NOT** a booking clone.
Trust, discovery, and real experiences come first.

---

## Screen Scope (LOCKED)

### Customer
1. Main Map View
2. Explore / List View
3. Experience Detail
4. Stay Detail
5. AI Trip Planner
6. Create Post / Check-in
7. Community Feed
8. User Profile

### Host
9. Host Profile & Trust Center
10. Stay Management

### Admin
11. Admin Dashboard
12. Moderation & Trust

🚫 No other screens are allowed in MVP.

---

## Mandatory User Flow
Map → Explore → Detail → Action → AI Plan → Share → Feed → Profile

Rules:
- No dead ends
- No isolated screens
- Every screen must link forward or back meaningfully

---

## Experience vs Stay Rules (NON-NEGOTIABLE)

### Experience
- Activity-based
- Duration & time focused
- Instant conversion
- CTA: **"Book experience"**
- Payment via Stripe Checkout

### Stay
- Accommodation-based
- Nightly price focused
- Host-centric trust model
- CTA: **"Request booking"**
- NO payment in MVP

They must **never** be mixed in UI, logic, or copy.

---

## AI Rules
- AI content must always be labeled
- Confidence level (Low / Medium / High) is mandatory
- No absolute claims ("best", "guaranteed")
- AI assists discovery, AI never decides or auto-books

---

## Monetization Rules
- Sponsored content must always be labeled
- Sponsored ratio capped (20–30%)
- No dark patterns
- Trust > revenue

---

## Security & Privacy Rules
- Mobile app never calls AI directly
- Row Level Security (RLS) everywhere
- Location is **event-based only** (no live tracking)
- Verified reviews only after real interaction
- Admin actions are always logged (audit)

---

## Explicit MVP Exclusions (LOCKED)
These features are intentionally NOT part of MVP:
- Stay payments, deposits, or holds
- Automated KYC / ID verification
- Offline map downloads
- In-app chat or messaging
- Seasonal pricing & calendar sync
- App Store / Play Store icon change via admin

---

## Admin Rules
- Admin UI is operational, not visual
- Focus on moderation, quality, and safety
- Manual approval is preferred over automation

---

## Change Control (VERY IMPORTANT)
Any change to:
- Screen scope
- User flow
- Monetization model
- AI behavior
- Security rules

❗ MUST be approved explicitly before implementation.

No silent changes.
No “just adding one thing”.

---

## Final Rule
If a feature, screen, or behavior is not defined here,
**it must NOT be implemented.**
# Travel Social Marketplace (MVP)

Mobile-first travel app:
- Map discovery (pins)
- Explore list
- Experience booking (Stripe Checkout via Edge Function)
- Stay request flow (no payment in MVP)
- AI Trip Planner (async)
- Social feed + posts
- Host tools + Admin dashboard (brand sync)

## Stack
- Flutter (iOS/Android)
- Supabase (Postgres, Auth, Storage, Realtime)
- Supabase Edge Functions
- AI: Antigravity + Gemini 3 Pro High / Opus (async jobs)
- Payments: Stripe Checkout (experiences only)

## Locked Rules
- 12 screens only (see SCREEN_SPECS/)
- Experiences: instant book + Stripe
- Stays: request-only (no payments in MVP)
- AI labeled + confidence required
- Sponsored content labeled

## Repo Structure
- /docs: all MVP docs
- /supabase: SQL + Edge functions
- /app: Flutter app