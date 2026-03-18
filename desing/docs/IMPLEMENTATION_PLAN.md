# IMPLEMENTATION_PLAN (MVP)
Sprint-based execution plan — Mobile-first

---

## 0) Delivery Rules

| Rule | Description |
|---|---|
| **Demoable builds** | Each sprint ends with a testable app build |
| **Vertical slices** | No "big bang" merges — feature-complete slices only |
| **Security first** | RLS + guards active from Sprint 0 |
| **MVP strict** | No stay payments, no KYC automation, no offline maps |

---

## Timeline Overview

| Sprint | Duration | Focus |
|---|---|---|
| Sprint 0 | 2–4 days | Foundation |
| Sprint 1 | 1 week | Discover (Map + Explore) |
| Sprint 2 | 1 week | Monetization + Requests |
| Sprint 3 | 1 week | AI Trip Planner |
| Sprint 4 | 1 week | Social MVP |
| Sprint 5 | 1 week | Host + Admin |
| Hardening | 3–7 days | QA + Release |
| **Total** | **~6–7 weeks** | MVP Launch |

---

## Sprint 0 — Foundation (2–4 days)

### Goal
Project boots, auth works, routing skeleton exists.

### Deliverables
| Task | Details |
|---|---|
| **Flutter scaffold** | Project structure + env config |
| **Supabase setup** | Auth, DB, Storage buckets |
| **Role model** | user/host/admin roles |
| **GoRouter baseline** | Tabs + guards + error routes |
| **Core UI kit** | Buttons, cards, skeletons, input fields |
| **Analytics hooks** | screen_view events |
| **Error handling** | Offline banner, error screens |

### Backend Tasks
```
□ Create Supabase project
□ Set up Auth providers (email, social optional)
□ Create core tables: users, cities
□ Create storage buckets: avatars, post_media, brand_assets
□ Set up RLS policies for users table
□ Create role column or user_roles table
```

### Flutter Tasks
```
□ Initialize Flutter project
□ Set up environment configs (dev/staging/prod)
□ Implement GoRouter with shell routes
□ Create auth provider (Riverpod recommended)
□ Build core UI components
□ Add analytics service
□ Implement offline detection banner
```

### Exit Criteria
- [ ] App launches on device
- [ ] Login/register works
- [ ] Tabs navigate correctly
- [ ] Guards redirect correctly (auth, host, admin)

---

## Sprint 1 — Discover (1 week)

### Goal
Users can browse content quickly.

### Screens
| # | Screen | Priority |
|---|---|---|
| 01 | Main Map View | P0 |
| 02 | Explore List View | P0 |
| 03 | Experience Detail | P0 (read-only + CTA stub) |
| 04 | Stay Detail | P0 (read-only + CTA stub) |

### Backend Tasks
```
□ Create tables: cities, places, experiences, stays, stay_media
□ Seed Barcelona data (min 20 experiences, 10 stays)
□ Set up RLS policies (public read)
□ Create indexes for city_id, status, category
□ Basic pagination support (limit/offset or cursor)
```

### Flutter Tasks
```
□ Implement Map View with Google Maps
□ Implement pin clustering (native)
□ Build bottom sheet with snap points
□ Implement Explore List with filters/sort
□ Build Experience Detail screen
□ Build Stay Detail screen
□ Implement local caching for offline reads
□ Add loading skeletons
```

### Exit Criteria
- [ ] Map shows pins/cards from DB
- [ ] Explore lists items with filters
- [ ] Detail pages load reliably
- [ ] Offline shows cached content (read-only)

---

## Sprint 2 — Monetization + Requests (1 week)

### Goal
First revenue path + core stay request flow.

### Screens
| # | Screen | Priority |
|---|---|---|
| 03 | Experience Detail | Update: Stripe CTA |
| 04 | Stay Detail | Update: Request CTA |
| 05 | Send Booking Request | New |

### Experience Booking (Stripe)
```
□ Create Edge Function: create_experience_checkout
    - Input: experience_id, quantity, user_id
    - Output: checkout_url
□ Create Edge Function: stripe_webhook_handler
    - Verify signature
    - Write booking_experience (status=paid)
□ Create booking_experience table + RLS
□ Implement Stripe Checkout UI flow (in-app webview)
□ Handle success/cancel redirects
```

### Stay Requests
```
□ Create booking_request_stay table + RLS
□ Implement Send Booking Request screen
□ Add date picker + guest selector
□ Form validation
□ Submit request (status=sent)
□ Host can view requests list (minimal UI)
□ Host can update status (accept/reject)
```

### Exit Criteria
- [ ] Experience checkout opens successfully
- [ ] Webhook writes paid booking
- [ ] Stay request can be submitted
- [ ] Host can accept/reject requests

---

## Sprint 3 — AI Trip Planner (1 week)

### Goal
"Wow" feature with async agent pipeline.

### Screens
| # | Screen | Priority |
|---|---|---|
| 06 | AI Trip Planner | P0 |

### Backend Tasks
```
□ Create ai_trip_plan_request table + RLS
□ Create ai_trip_plan table + RLS
□ Create user_plans table + RLS
□ Create Edge Function: request_trip_plan
    - Write request (status=queued)
    - Return request_id
□ Implement agent worker (picks queued, generates plan)
□ Rate limiting on generation (5 per hour per user)
```

### Flutter Tasks
```
□ Build input form (dates, budget, interests, pace)
□ Implement loading state with progress hints
□ Build day-by-day plan display (accordions)
□ Implement slot regeneration
□ Add AI labeling + confidence badges
□ Save plan requires auth
□ Implement plan caching
```

### Exit Criteria
- [ ] Plans generate async without blocking UI
- [ ] Confidence + AI labeling shown
- [ ] Slot regeneration works
- [ ] Save plan works for logged-in users

---

## Sprint 4 — Social MVP (1 week)

### Goal
Build retention engine.

### Screens
| # | Screen | Priority |
|---|---|---|
| 07 | Community Feed | P0 |
| 08 | Create Post | P0 |
| 09 | User Profile | P0 |

### Backend Tasks
```
□ Create posts table + RLS
□ Create comments table + RLS
□ Create likes table + RLS (unique constraint)
□ Create follows table + RLS
□ Create saved_items table + RLS
□ Create checkins table (optional MVP)
□ Storage flow: private upload → approval → public
□ Integrate ContentSafetyAgent (blocking)
□ Create reports table + RLS
```

### Flutter Tasks
```
□ Build Feed with vertical scroll
□ Implement post card (media, actions, caption)
□ Build Create Post flow
□ Media picker + upload with progress
□ Place/experience tagging
□ Build User Profile (own + public)
□ Implement tabs: Posts / Saved / Plans
□ Like / comment / follow actions
□ Pull-to-refresh + infinite scroll
```

### Exit Criteria
- [ ] Feed scrolls smoothly
- [ ] Post creation works with safety checks
- [ ] Profile shows posts + stats
- [ ] Follow/like/comment require auth

---

## Sprint 5 — Host + Admin (1 week)

### Goal
Operational control and quality gates.

### Host Screens
| # | Screen | Priority |
|---|---|---|
| 10 | Host Profile & Trust Center | P0 |
| 11 | Stays Management List | P0 |

### Admin Screen
| # | Screen | Priority |
|---|---|---|
| 12 | Admin Dashboard | P0 |

### Host Backend
```
□ Create hosts table + RLS
□ Verification status field
□ Performance metrics (response rate, time)
□ Stays status toggle (pause/unpause)
□ Inline price editing
```

### Admin Backend
```
□ Create app_config table + RLS (public read, admin write)
□ Create admin_audit_log table + RLS (admin only)
□ Brand config keys (name, logo_url, version)
□ Moderation queues (host verification, reports)
□ Edge Function: update_brand_config
```

### Flutter Tasks
```
□ Build Host Trust Center
□ Build Stays Management List
□ Inline price editor
□ Availability toggle
□ Build Admin Dashboard
□ Metrics cards
□ Queue cards with counts
□ Quick moderation actions
□ Brand settings form
□ Audit logging for all admin actions
```

### Exit Criteria
- [ ] Host can manage stays, pause, edit price range
- [ ] Host can apply for verification
- [ ] Admin can approve/reject/suspend with audit logs
- [ ] Brand updates reflect in-app within minutes

---

## Hardening Sprint — QA + Release (3–7 days)

### Goal
Ship-ready MVP.

### Security Tasks
```
□ RLS verification test (all tables)
□ Auth guard verification (all protected routes)
□ Rate limit verification
□ Input sanitization check
□ Basic pen-test checklist
```

### Performance Tasks
```
□ Feed pagination stress test
□ Map pin rendering performance
□ Image loading optimization
□ Offline mode testing
□ Memory profiling
```

### Infrastructure Tasks
```
□ Crash/error monitoring setup (Sentry/Crashlytics)
□ Analytics verification
□ Store build pipeline setup
□ Environment configs finalized
```

### Polish Tasks
```
□ Copywriting review
□ Error messages UX
□ Loading states consistency
□ Empty states design
□ Disclaimers and AI labels
```

### Release Criteria
- [ ] No P0 security issues
- [ ] No critical crashes
- [ ] Stripe flow stable
- [ ] Moderation/audit works
- [ ] App store requirements met

---

## MVP Success Metrics (First 30 Days)

| Metric | Definition | Target |
|---|---|---|
| **Activation** | % users who view a detail page | 60%+ |
| **Conversion** | Experience booking rate | 5%+ |
| **Retention** | 7-day returning users | 30%+ |
| **Content** | Posts per active user | 0.5+ |
| **Trust** | Report resolution time | < 48h |
| **Host quality** | Verification throughput | < 72h |

---

## Risk Mitigation

| Risk | Mitigation |
|---|---|
| Stripe integration delays | Start in Sprint 2 day 1, have test mode ready |
| AI agent latency | Async queue + clear loading UX |
| Content moderation volume | Auto-safety agent + priority queue |
| Low host adoption | Seed content + manual outreach |
| App store rejection | Review guidelines early |

---

## Explicit MVP Exclusions

| Feature | Status | Notes |
|---|---|---|
| Stay payments/deposits | ❌ Out | Request-based only |
| Automated KYC | ❌ Out | Manual admin approval |
| Offline map downloads | ❌ Out | Too complex for MVP |
| Seasonal pricing | ❌ Out | Simple price range only |
| Calendar sync | ❌ Out | On/off availability only |
| In-app chat | ❌ Out | Future feature |
| Push notifications | ⚠️ Optional | Nice-to-have if time |

---

## Sprint Checklist Template

Use this for each sprint:

```markdown
## Sprint X Checklist

### Planning
- [ ] Sprint goals defined
- [ ] Tasks broken down
- [ ] Dependencies identified
- [ ] Team aligned

### Development
- [ ] Backend tasks complete
- [ ] Frontend tasks complete
- [ ] Integration tested
- [ ] RLS verified

### Quality
- [ ] Code reviewed
- [ ] Tests passing
- [ ] No critical bugs
- [ ] Performance acceptable

### Demo
- [ ] Demo build ready
- [ ] Core flow works end-to-end
- [ ] Feedback collected
- [ ] Next sprint planned
```

---

## Document Dependencies

| Document | Purpose | Used In |
|---|---|---|
| SCREEN_SPECS/*.md | UI/UX specifications | All sprints |
| ARCHITECTURE.md | System design | Sprint 0 |
| ROUTING_FINAL.md | Navigation structure | Sprint 0 |
| SUPABASE_SCHEMA.md | Database design | All sprints |
| AGENT_CONTRACTS.md | AI interfaces | Sprint 3 |
| DESIGN_SYSTEM.md | Visual design | All sprints |
| SECURITY.md | Security model | All sprints |

---

**Status: FINAL — Ready for Implementation**