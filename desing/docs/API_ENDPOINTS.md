# API_ENDPOINTS (MVP) — Mobile-first Contracts
Global Travel Social Marketplace – Mobile

## Approach
- Supabase Postgres as source of truth
- Use:
  - Supabase client for simple CRUD (with RLS)
  - Edge Functions for:
    - Stripe checkout creation
    - Agent orchestration triggers
    - Complex feed ranking
- Agents are async; results are cached in DB

---

## Auth
- Supabase Auth:
  - login/register/oauth handled by SDK

---

## Core Data (Supabase tables)
Mobile reads via RLS:
- city, place, experience, stay, post, profile

Writes (user-owned via RLS):
- post, comment, like, follow
- booking_request_stay
- booking_experience (created through Stripe flow)

---

## Edge Functions (Recommended)

### 1) Create Stripe Checkout (Experience)
- `POST /functions/v1/create_experience_checkout`
Request:
```json
{ "experience_id":"uuid", "quantity":1 }