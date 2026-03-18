# ARCHITECTURE (MVP) — Mobile Travel Marketplace
Flutter + Supabase + Edge Functions + Async AI Agents

---

## 0) Scope & Principles

This architecture supports:
- **Discover** (Map + Explore)
- **Monetization** (Experience Stripe Checkout)
- **Stays** (Request-based, no payment in MVP)
- **Social** (Feed + Create Post + Profile)
- **Host tools** (Stays management + Trust Center)
- **Admin tools** (Moderation + Verification + Brand sync)

### Core Principles
| Principle | Description |
|---|---|
| **Mobile-first** | Offline-tolerant (cached reads) |
| **Security-first** | RLS + role-based access |
| **Async AI** | No blocking UI |
| **Single source of truth** | Postgres (Supabase) |
| **Observability** | Logs, errors, audit from day 1 |

---

## 1) System Overview

### 1.1 Clients
- Flutter Mobile App (iOS/Android)

### 1.2 Backend
| Component | Purpose |
|---|---|
| **Supabase Postgres** | Primary DB |
| **Supabase Auth** | Users, sessions |
| **Supabase Storage** | Media, logos |
| **Supabase Realtime** | Status updates, optional feed |
| **Supabase Edge Functions** | Stripe + orchestration + privileged writes |
| **AI Agent Orchestration** | Antigravity + Gemini 3 Pro High / Opus (async) |

### 1.3 Key Rule
```
❌ Mobile NEVER calls AI directly.
✅ Mobile calls Edge Functions or reads cached results from DB.
```

---

## 2) High-Level Data Flows

### 2.1 Explore / Map
```
1) Mobile reads `city`, `place`, `experience`, `stay` via RLS
2) Ranking comes from:
   - cached tables (preferred)
   - optional edge function trigger to refresh ranking
```

### 2.2 Experience Booking (Stripe Checkout)
```
1) Mobile → Edge: create_experience_checkout(experience_id, quantity)
2) Edge creates Stripe Checkout Session → returns checkout_url
3) Mobile opens checkout_url (in-app webview / browser)
4) Stripe webhook → Edge verifies signature → writes booking_experience(status=paid)
5) Mobile observes booking status (poll/realtime) → enables verified review
```

### 2.3 Stay Booking Request (No Payment)
```
1) Mobile writes booking_request_stay(status=sent)
2) Host reads requests (RLS: owner only)
3) Host updates request status: accepted/rejected
4) Payment handled outside platform (MVP)
```

### 2.4 AI Trip Planner (Async)
```
1) Mobile → Edge: request_trip_plan(input...)
2) Edge writes ai_trip_plan_request(status=queued)
3) Agent worker picks request → generates plan
4) Result saved to ai_trip_plan
5) Mobile fetches plan via DB + cache
```

### 2.5 Social Posting
```
1) Mobile uploads media to Storage (private first)
2) Edge / server validates + runs ContentSafetyAgent
3) If allowed: post becomes public
4) Feed ranking via cached ordering or edge function (optional)
```

### 2.6 Brand Sync (Admin)
```
1) Admin uploads new logo to Storage
2) Admin updates app_config keys:
   - brand.name, brand.logo_url, brand.updated_version++
3) Mobile checks version on launch/resume, refreshes and applies in-app branding
```

---

## 3) App Modules (Flutter)

### 3.1 Feature-First Structure
```
lib/
├── features/
│   ├── map/
│   ├── explore/
│   ├── experience/
│   ├── stays/
│   ├── planner/
│   ├── feed/
│   ├── post_create/
│   ├── profile/
│   ├── host/
│   └── admin/
├── core/
│   ├── auth/
│   ├── routing/
│   ├── networking/
│   ├── cache/
│   ├── analytics/
│   └── ui/          # Design system widgets
└── main.dart
```

### 3.2 State Management
- Any consistent approach is acceptable
- **Recommended**: Riverpod
- **Rule**: Keep domain logic outside widgets

---

## 4) Backend Components (Supabase)

### 4.1 Database
| Aspect | Implementation |
|---|---|
| Tables | Postgres tables for all entities |
| AI outputs | JSONB for plans, city insights |
| Indexing | Strict on commonly queried fields (city_id, status, created_at) |

### 4.2 Auth
**Roles:**
| Role | Description |
|---|---|
| `user` | Default role |
| `host` | Can manage stays |
| `admin` | Platform administration |

**Row Level Security (RLS):**
| Policy | Description |
|---|---|
| Public read | Where allowed (listings, profiles) |
| Owner-only | Writes/reads where required |
| Admin-only | Sensitive reads and actions |

### 4.3 Storage
**Buckets:**
| Bucket | Access |
|---|---|
| `post_media` | Private upload → public after approval |
| `avatars` | Public read |
| `brand_assets` | Admin-only write, public read |

**Policies:**
- Size limits + type allowlist
- Path prefix by user_id / post_id

### 4.4 Edge Functions
**Use Edge Functions for:**
| Function Type | Examples |
|---|---|
| Stripe | Checkout creation, webhook handling |
| AI triggers | Plan request, city refresh |
| Moderation | Privileged writes for admin actions |
| Brand | Admin brand updates |

---

## 5) AI Layer (Agents)

### 5.1 Agent Contracts
All agent contracts live in:
- `AGENT_CONTRACTS.md`

### 5.2 Agent Execution Pattern
```
[Request Created]
    → Input written to *_request table with status=queued
    ↓
[Agent Worker]
    → Picks up request
    → Runs agent logic
    → Writes output to cache table
    ↓
[Completion]
    → Status updated to done/failed + error reason
    ↓
[Mobile]
    → Fetches result from DB
```

### 5.3 Safety & Labeling
| Rule | Description |
|---|---|
| AI labeling | All AI content must be labeled in UI |
| Confidence level | Required in output |
| No absolutes | "Popular" not "Best" |

---

## 6) Caching & Offline Strategy

### 6.1 Cached Content
| Screen | Cached Data |
|---|---|
| Map | Pins, clusters |
| Explore | Lists, rankings |
| Planner | Generated plans |
| City | City insights |

### 6.2 Offline Behavior
| Action | Behavior |
|---|---|
| Read | Show cached content with banner |
| Write | Block unless explicitly queued |

### 6.3 Cache Invalidation
| Type | Strategy |
|---|---|
| Agent outputs | TTL per output |
| Brand config | Version bump |

---

## 7) Security Model (MVP)

### 7.1 Core Security Controls
| Control | Implementation |
|---|---|
| **RLS** | Everywhere |
| **Admin routes** | Server-side verification |
| **Rate limiting** | Create post, booking requests, AI plan generation |

### 7.2 Verified Reviews
| Type | Rule |
|---|---|
| Experiences | Only if booking_experience is paid/completed |
| Stays | Optional MVP (can be off initially) |

### 7.3 Audit Logging
| Scope | What's Logged |
|---|---|
| Admin actions | Moderation, verification, brand changes |

### 7.4 Sanitization
| Field | Sanitized |
|---|---|
| Captions | ✅ |
| Bios | ✅ |
| Messages | ✅ |

### 7.5 Location Privacy
```
❌ No live tracking
✅ Location is event-based only (captured once at action time)
```

---

## 8) Observability & Monitoring (2026-ready)

### 8.1 Minimum (MVP)
| Component | Implementation |
|---|---|
| Edge function logs | Centralized logging |
| Mobile crashes | Error tracking service |
| Admin audit | Logs in DB |

### 8.2 Recommended (Future)
| Component | Implementation |
|---|---|
| Traces | OpenTelemetry-style for edge calls |
| Performance | Query latency metrics (feed, map) |

---

## 9) Non-Goals (MVP)

Explicitly **out of scope** for MVP:
| Feature | Reason |
|---|---|
| Store-level icon changes | Requires app store submission |
| Automated KYC / ID verification | Complexity, third-party dependency |
| In-platform stay payments | Request-based only in MVP |
| Offline map downloads | Too large for MVP scope |
| Calendar sync / seasonal pricing | Future enhancement |

---

## 10) Architecture Diagram (Conceptual)

```
┌─────────────────────────────────────────────────────────────────┐
│                      FLUTTER MOBILE APP                         │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐       │
│  │   Map    │ Explore  │   Feed   │  Profile │   Host   │       │
│  └────┬─────┴────┬─────┴────┬─────┴────┬─────┴────┬─────┘       │
│       │          │          │          │          │             │
│       └──────────┴──────────┴──────────┴──────────┘             │
│                            │                                     │
│                    ┌───────▼───────┐                            │
│                    │  Core Layer   │                            │
│                    │ (Auth, Cache, │                            │
│                    │  Networking)  │                            │
│                    └───────┬───────┘                            │
└────────────────────────────┼────────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ Supabase │   │  Edge    │   │  Storage │
        │ Postgres │   │ Functions│   │  Buckets │
        │ + Auth   │   │          │   │          │
        └────┬─────┘   └────┬─────┘   └──────────┘
             │              │
             │   ┌──────────┼──────────┐
             │   │          │          │
             │   ▼          ▼          ▼
             │ ┌──────┐ ┌──────┐ ┌──────────┐
             │ │Stripe│ │  AI  │ │  Admin   │
             │ │Webhk │ │Agents│ │ Actions  │
             │ └──────┘ └──────┘ └──────────┘
             │              │
             └──────────────┤
                            │
                    ┌───────▼───────┐
                    │  AI Agent     │
                    │ Orchestration │
                    │ (Async Jobs)  │
                    └───────────────┘
```

---

## 11) Document Dependencies

| Document | Status | Purpose |
|---|---|---|
| PRODUCT.md | ✅ Locked | Product vision |
| MVP_SCOPE.md | ✅ Locked | Feature scope |
| GUARDRAILS.md | ✅ Locked | Rules and constraints |
| DATA_MODEL.md | ✅ Locked | Entity relationships |
| AGENT_CONTRACTS.md | ✅ Locked | AI agent I/O specs |
| DESIGN_SYSTEM.md | ✅ Locked | Visual design rules |
| COMPONENT_LIBRARY.md | ✅ Locked | UI component specs |
| NAVIGATION_MAP.md | ✅ Locked | GoRouter routes |
| SECURITY.md | ✅ Locked | Security model |
| SCREEN_SPECS/*.md | ✅ Complete | 12 screen specifications |
| **ARCHITECTURE.md** | ✅ This doc | System architecture |

---

## 12) Next Documents (in order)

| # | Document | Purpose |
|---|---|---|
| 1 | `ROUTING_FINAL.md` | Final route table with guards |
| 2 | `SUPABASE_SCHEMA.md` | Tables + indexes + RLS policies |
| 3 | `IMPLEMENTATION_PLAN.md` | Final sprint breakdown |

---

**Status: AWAITING APPROVAL**
