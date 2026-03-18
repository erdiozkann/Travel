# SCREEN SPEC: Host Profile & Trust Center
Screen ID: 10
Route: `/host/:hostId` (public) + `/host/trust` (host-only)
Design Reference: `02_host_core/host_profile_&_trust_center`

---

## 1. Purpose

The Host Profile & Trust Center serves **two audiences**:

**Public View (`/host/:hostId`):**
- Guest-facing profile showing host info and trust signals
- Performance stats (response time, rating)
- Listings overview
- Report host action

**Trust Center (`/host/trust`):**
- Host-only dashboard for verification status
- Pending actions and requirements
- Performance metrics and tips
- Verification application (manual admin approval)

This screen answers:
- Guest: **"Can I trust this host?"**
- Host: **"How do I get verified and improve my standing?"**

> **MVP Rule**: Verified Host = manual admin approval only. No automated KYC.

---

## 2. Entry Points

### Public Host Profile (`/host/:hostId`)
| Source | Route | Behavior |
|---|---|---|
| Stay Detail host tap | `/host/:hostId` | View host profile |
| Feed post (host content) | `/host/:hostId` | View host profile |
| Deep link | `myapp://host/<hostId>` | Direct to host profile |
| Search results | `/host/:hostId` | If hosts are searchable |

### Trust Center (`/host/trust`)
| Source | Route | Behavior |
|---|---|---|
| Host dashboard nav | `/host/trust` | Host-only access |
| Verification prompt | `/host/trust` | After host signup |
| Settings | `/host/trust` | Manage verification |

**Prerequisites:**
- Public profile: No authentication required
- Trust Center: Must be authenticated host

---

## 3. UI Sections — Public Host Profile

### 3.1 Profile Header
| Element | Description |
|---|---|
| **Avatar** | Large host photo |
| **Display name** | "Maria" |
| **Verified badge** | ✅ "Verified Host" (if admin-approved) |
| **Member since** | "Hosting since 2023" |
| **Location** | City/country |
| **Languages** | 🇬🇧 🇪🇸 🇩🇪 |

### 3.2 Trust Signals Section (Public)
| Signal | Display |
|---|---|
| **Rating** | ★ 4.8 (56 reviews) |
| **Response time** | "Usually responds within 2 hours" |
| **Response rate** | "100% response rate" |
| **Acceptance rate** | "85% acceptance rate" |
| **Total stays** | "120+ completed stays" |
| **Superhost** | Optional future badge |

### 3.3 About Section
| Element | Description |
|---|---|
| **Bio** | Host's self-description |
| **Interests** | What they enjoy sharing with guests |
| **Languages spoken** | Full list |

### 3.4 Listings Section
| Element | Description |
|---|---|
| **Title** | "Maria's listings" |
| **Stay cards** | Horizontal scroll of active stays |
| **Card info** | Thumbnail, title, price, rating |
| **Tap action** | Navigate to stay detail |
| **Empty state** | "No active listings" |

### 3.5 Reviews Section
| Element | Description |
|---|---|
| **Title** | "Reviews from guests" |
| **Review cards** | Guest reviews of host (not stay-specific) |
| **Sort** | Most recent first |
| **See all** | Navigate to full reviews list |

### 3.6 Report Section
| Element | Description |
|---|---|
| **Report button** | "Report this host" (bottom of page) |
| **Action** | Opens report modal |
| **Auth required** | Must be logged in to report |

### 3.7 Contact Section (Optional MVP)
| Element | Description |
|---|---|
| **Message button** | "Contact host" → only after accepted booking |
| **Note** | "Book a stay to message this host" |

---

## 4. UI Sections — Trust Center (Host-Only)

### 4.1 Trust Center Header
| Element | Description |
|---|---|
| **Title** | "Trust Center" |
| **Status badge** | "Verified" / "Pending" / "Not Applied" |
| **Progress** | "3 of 4 requirements completed" |

### 4.2 Verification Status Card
| Element | Description |
|---|---|
| **Current status** | Clear status indicator |
| **Requirements checklist** | What's needed for verification |
| **Action button** | "Apply for Verification" or "Under Review" |

**Verification Requirements (MVP):**
| Requirement | Status |
|---|---|
| Complete profile | ✅ / ❌ |
| Active listing | ✅ / ❌ |
| Accepted 1+ booking | ✅ / ❌ |
| Admin approval | ⏳ Pending / ✅ Approved |

### 4.3 Performance Metrics (Host-Only)
| Metric | Display | Benchmark |
|---|---|---|
| **Response rate** | 95% | Target: 90%+ |
| **Response time** | 1.5 hours | Target: < 4 hours |
| **Acceptance rate** | 80% | Target: 75%+ |
| **Cancellation rate** | 2% | Target: < 5% |
| **Rating average** | 4.7 | Target: 4.5+ |
| **Total bookings** | 45 | - |
| **Completed stays** | 42 | - |

### 4.4 Tips & Recommendations
| Element | Description |
|---|---|
| **Title** | "Improve your hosting" |
| **Tips cards** | Personalized suggestions |
| **Examples** | "Respond faster to get more bookings" |

### 4.5 Verification History
| Element | Description |
|---|---|
| **Timeline** | Past verification events |
| **Entries** | "Verified on Jan 2024", "Profile updated" |

### 4.6 Account Actions
| Element | Description |
|---|---|
| **Pause hosting** | Temporarily deactivate all listings |
| **Request re-verification** | If status changed |
| **Delete host account** | Permanent action |

---

## 5. State Handling

### 5.1 Local State (UI)
| State | Type | Default |
|---|---|---|
| `hostId` | uuid | from route |
| `isOwnProfile` | bool | derived (current user = host?) |
| `host` | Host? | null |
| `profile` | Profile? | null |
| `listings` | List<Stay> | [] |
| `reviews` | List<Review> | [] |
| `trustStatus` | TrustStatus? | null |
| `metrics` | HostMetrics? | null |
| `isLoading` | bool | true |

### 5.2 Cached State
| State | Source | TTL |
|---|---|---|
| `host` | DB | 15 minutes |
| `listings` | DB | 5 minutes |
| `reviews` | DB | 15 minutes |
| `metrics` | HostTrustAgent (optional) | 1 hour |

### 5.3 State Transitions
```
[Public Profile Load]
  → fetch host data from DB
  → fetch associated profile
  → fetch active listings
  → fetch reviews
  → isLoading = false

[Trust Center Load]
  → verify current user is host
  → fetch own host record
  → fetch verification status
  → fetch performance metrics
  → isLoading = false

[Report Tap]
  → if not authenticated → prompt login
  → open report modal

[Apply for Verification Tap]
  → check requirements met
  → submit verification request
  → status = "Pending"
```

---

## 6. User Inputs

### Public Profile
| Input | Action | Auth Required |
|---|---|---|
| Tap stay card | Navigate to stay detail | No |
| Tap "See all reviews" | Navigate to reviews list | No |
| Tap "Report host" | Open report modal | Yes |
| Pull to refresh | Refresh profile | No |

### Trust Center (Host-Only)
| Input | Action | Auth Required |
|---|---|---|
| Tap "Apply for Verification" | Submit application | Yes (host) |
| Tap metric card | View detailed breakdown | Yes (host) |
| Tap tip card | View improvement details | Yes (host) |
| Toggle "Pause hosting" | Deactivate listings | Yes (host) |
| Tap "Request re-verification" | Submit request | Yes (host) |

---

## 7. Data Outputs

### 7.1 Read Operations
| Data | Source | RLS |
|---|---|---|
| Host profile | `host` + `profile` tables | Public read |
| Active listings | `stay` table (status=active) | Public read |
| Reviews | `review` table (host reviews) | Public read |
| Trust status | `host` table | Owner read only |
| Metrics | Aggregated | Owner read only |

### 7.2 Write Operations
| Data | Table | RLS |
|---|---|---|
| Report | `report` table | Owner write |
| Verification application | `host` table (status update) | Owner write |
| Pause hosting | `stay` table (bulk status) | Owner write |

---

## 8. Agent Usage (Optional MVP)

### 8.1 HostTrustAgent
**When called:**
- Trust Center load (for host-only metrics)
- Admin review (for risk signals)

**Input:**
```json
{
  "host_id": "uuid"
}
```

**Output:**
```json
{
  "trust_score": 0.85,
  "risk_signals": [],
  "performance": {
    "response_rate": 0.95,
    "response_time_hours": 1.5,
    "acceptance_rate": 0.80,
    "cancellation_rate": 0.02,
    "rating_avg": 4.7,
    "review_count": 56
  },
  "recommendations": [
    "Improve response time to qualify for featured placement",
    "Add more photos to your listings"
  ],
  "confidence_level": "high",
  "cache_ttl_seconds": 3600
}
```

> **MVP Note**: Can skip agent and use direct DB aggregations for metrics.

---

## 9. Verification Flow (MVP — Manual Admin)

### 9.1 Flow Diagram
```
[Host completes profile + listing]
    ↓
[Host taps "Apply for Verification"]
    ↓
[Check requirements]
    ├── Requirements not met → Show what's missing
    └── Requirements met → Submit application
    ↓
[Status = "Pending"]
    ↓
[Admin receives notification]
    ↓
[Admin reviews in Admin Panel]
    ├── Approve → host.verified_host = true
    └── Reject → host.verified_host = false, reason logged
    ↓
[Host notified of decision]
```

### 9.2 Requirements Checklist
| Requirement | Check |
|---|---|
| Profile complete | display_name, avatar, bio |
| At least 1 active listing | stay.status = active |
| At least 1 accepted booking | booking_request_stay.status = accepted |
| No active reports | report.status != open |

### 9.3 No Automated KYC (MVP)
| What we DON'T do | Why |
|---|---|
| ID verification | Complex, third-party dependency |
| Address verification | Not needed for MVP trust |
| Background checks | Legal complexity |
| Automated approval | Quality control via admin |

---

## 10. API Calls

### 10.1 Supabase Direct (RLS)
| Endpoint | Method | Purpose |
|---|---|---|
| `host` | SELECT | Fetch host data |
| `profile` | SELECT | Fetch profile data |
| `stay` | SELECT | Fetch listings |
| `review` | SELECT | Fetch reviews |
| `report` | INSERT | Submit report |
| `host` | UPDATE | Apply for verification |

### 10.2 Edge Functions
| Function | Purpose |
|---|---|
| `get_host_metrics` | Calculate performance metrics |
| `submit_verification` | Handle verification application |

---

## 11. Edge Cases

### 11.1 Host Not Found
| Condition | Behavior |
|---|---|
| Invalid host ID | Show error: "Host not found" |
| Host suspended | Show: "This host is not available" |
| Host never verified | Show profile without badge |

### 11.2 Loading States
| Condition | Behavior |
|---|---|
| Profile loading | Skeleton header + cards |
| Metrics loading | Placeholder values |
| Listings loading | Skeleton cards |

### 11.3 Empty States
| Section | Empty Message |
|---|---|
| Listings | "No active listings" |
| Reviews | "No reviews yet" |
| Metrics | Calculate from available data |

### 11.4 Verification Edge Cases
| Condition | Behavior |
|---|---|
| Requirements not met | Show missing items, disable apply |
| Already pending | Show "Application under review" |
| Rejected | Show reason, allow re-apply after changes |
| Revoked | Show reason, path to re-verification |

### 11.5 Offline
| Condition | Behavior |
|---|---|
| Public profile | Show cached if available |
| Trust Center | Show cached metrics + banner |
| Report/Apply offline | Block, show "Connection required" |

---

## 12. Accessibility

- Verified badge has screen reader label
- Stats are announced as numbers
- Trust requirements have checkbox labels
- Report button clearly labeled
- Metrics have accessible descriptions

---

## 13. Analytics Events (MVP)

| Event | Payload |
|---|---|
| `host_profile_viewed` | `host_id`, `viewer_user_id`, `source` |
| `host_listing_tapped` | `host_id`, `stay_id` |
| `host_reviews_expanded` | `host_id`, `review_count` |
| `host_reported` | `host_id`, `reason` |
| `trust_center_viewed` | `host_id` |
| `verification_applied` | `host_id` |
| `verification_status_changed` | `host_id`, `new_status` |
| `host_metric_viewed` | `host_id`, `metric_type` |

---

## 14. Security Checklist

- [x] Public profile is read-only (RLS)
- [x] Trust Center requires authenticated host (RLS)
- [x] Metrics visible to owner only
- [x] Report requires authentication
- [x] Verification is manual admin only
- [x] No automated KYC data collection
- [x] Host status changes logged
- [x] Sensitive data not exposed publicly

---

## 15. Design Decisions (APPROVED)

Host Profile specific:
1. **Two views in one spec**: Public profile + Trust Center
2. **Verified badge = admin only**: No automated KYC in MVP
3. **Requirements checklist**: Clear path to verification
4. **Metrics host-only**: Public sees summary, host sees details
5. **No messaging before booking**: Prevent spam
6. **Report visible always**: Trust and safety

---

## 16. Related Screens

| Screen | Relationship |
|---|---|
| Stay Detail | Host section links here |
| Admin Panel | Reviews verification applications |
| Stays Management | Host's listing management |
| Host Dashboard | Business stats and analytics |
| Report Modal | Tap "Report host" |

---

## 17. Public vs Host-Only Comparison

| Element | Public (Guest) | Host-Only |
|---|---|---|
| Profile header | ✅ | ✅ |
| Verified badge | ✅ | ✅ |
| Rating + reviews | ✅ | ✅ |
| Response time | ✅ | ✅ |
| Response rate | ✅ | ✅ |
| Acceptance rate | ✅ Summary | ✅ Detailed |
| Cancellation rate | ❌ | ✅ |
| Performance benchmarks | ❌ | ✅ |
| Verification status | ❌ | ✅ |
| Apply for verification | ❌ | ✅ |
| Tips & recommendations | ❌ | ✅ |
| Report button | ✅ | ❌ |

---

## Approval Checklist

- [ ] Purpose clear (public + host-only)
- [ ] Routes correct
- [ ] UI sections complete for both views
- [ ] Verification flow defined (manual admin)
- [ ] No automated KYC confirmed
- [ ] Edge cases covered
- [ ] Security verified

---

**Status: AWAITING APPROVAL**
