# SCREEN SPEC: Stay Detail
Screen ID: 04
Route: `/explore/stay/:stayId` or `/map/stay/:stayId`
Design Reference: `01_customer_core/stay_detail_view`

---

## 1. Purpose

The Stay Detail screen is the **accommodation discovery page** with request-based booking. It provides:
- Full stay information (rooms, amenities, location)
- Host-centric presentation (profile, trust signals, response rate)
- Nightly price range visibility
- Trust signals (verified host, ratings, reviews)
- Primary CTA: **"Request booking"** → No payment in MVP

This screen answers: **"Is this the right place to stay?"**

> **Critical Rule**: Stay bookings are request-based in MVP. No Stripe payment.

---

## 2. Entry Points

| Source | Route | Behavior |
|---|---|---|
| Map View pin tap | `/map/stay/:id` | Push on map stack |
| Explore List card tap | `/explore/stay/:id` | Push on explore stack |
| AI Trip Planner item | `/plan/:planId/stay/:id` | Push on plan stack |
| Deep link | `myapp://explore/stay/<id>` | Open directly |
| Saved items | `/profile/saved` → tap | Push on profile stack |
| Host profile | `/host/:hostId` → tap stay | Push on host stack |

---

## 3. UI Sections

### 3.1 Media Carousel (Top)
- Full-width image carousel (rooms, exterior, amenities)
- Swipeable with pagination dots
- Tap to view fullscreen gallery
- First image = hero image

### 3.2 Header Section
| Element | Description |
|---|---|
| **Title** | Stay name (e.g., "Sunny Apartment in Gràcia") |
| **Room type badge** | "Entire place" / "Private room" / "Shared room" |
| **Location** | Neighborhood + City |
| **Capacity** | "Up to 4 guests • 2 bedrooms • 1 bath" |
| **Sponsored badge** | "Sponsored" (if applicable) |

### 3.3 Price Section (Prominent)
| Element | Description |
|---|---|
| **Nightly price range** | `€85 – €120 / night` |
| **Price clarity** | Always range, never exact (GUARDRAILS.md) |
| **Total estimate** | "Estimated total: €340 – €480 for 4 nights" (if dates selected) |
| **Note** | "Final price confirmed by host" |

### 3.4 Host Section (Central — Host-Centric)
| Element | Description |
|---|---|
| **Host avatar** | Circular photo |
| **Host name** | "Hosted by Maria" |
| **Verified Host badge** | ✅ "Verified Host" (if admin-approved) |
| **Host rating** | ★ 4.8 (32 reviews) |
| **Response info** | "Usually responds within 2 hours" |
| **Member since** | "Hosting since 2023" |
| **Tap action** | Navigate to `/host/:hostId` |

> **Design Principle**: Host is the trust anchor for stays. Make them visible.

### 3.5 Trust Section
| Element | Description |
|---|---|
| **Stay rating** | ★ 4.6 (56 reviews) |
| **Verified badge** | "Verified reviews only" |
| **Trust signals** | Cleanliness, accuracy, communication scores (optional MVP) |

### 3.6 Reviews Section
| Element | Description |
|---|---|
| **Review list** | Top 3-5 reviews |
| **Review card** | Avatar, name, date, rating, text, "Verified stay" badge |
| **Empty state** | "No reviews yet." |
| **See all** | Navigate to full reviews page |

> **MVP Rule**: Stay reviews optional or require manual verification (SECURITY.md)

### 3.7 Details Section
| Element | Description |
|---|---|
| **Description** | Full text (expandable) |
| **Amenities** | Icon grid: WiFi, Kitchen, AC, Parking, etc. |
| **House rules** | Check-in/out times, pets, smoking, etc. |
| **Location** | Map preview + neighborhood description |
| **Cancellation policy** | Text summary |

### 3.8 Availability Section (Optional MVP)
| Element | Description |
|---|---|
| **Calendar preview** | Mini calendar showing available/blocked dates |
| **Date picker** | User can select check-in/out (optional for request) |
| **Status** | "Available" / "Limited" / "Check with host" |

### 3.9 Related Stays (Optional)
- Horizontal scroll of similar stays in same area
- "Similar stays nearby"

### 3.10 Sticky Bottom CTA Bar
| Element | Description |
|---|---|
| **Price display** | `From €85 / night` |
| **CTA Button** | **"Request booking"** (primary, full-width) |
| **Favorite button** | Heart icon (toggle) |

---

## 4. State Handling

### 4.1 Local State (UI)
| State | Type | Default |
|---|---|---|
| `stayId` | uuid | from route |
| `stay` | Stay? | null |
| `host` | Host? | null |
| `reviews` | List<Review> | [] |
| `isLoading` | bool | true |
| `isFavorited` | bool | false |
| `selectedCheckIn` | Date? | null |
| `selectedCheckOut` | Date? | null |
| `guestCount` | int | 1 |
| `mediaIndex` | int | 0 |
| `isDescriptionExpanded` | bool | false |

### 4.2 Cached State
| State | Source | TTL |
|---|---|---|
| `stay` | DB + cache | 1 hour |
| `host` | DB + cache | 1 hour |
| `reviews` | DB | 15 minutes |

### 4.3 State Transitions
```
[Screen Load]
  → fetch stay from cache or DB
  → fetch host details
  → fetch reviews (first page)
  → isLoading = false

[Request CTA Tap]
  → if not authenticated → redirect to /auth/login?redirect=current
  → navigate to /stay/:stayId/request (Send Booking Request screen)

[Favorite Toggle]
  → if not authenticated → prompt login
  → toggle isFavorited
  → update DB (saved_items table)

[Date Selection]
  → update selectedCheckIn / selectedCheckOut
  → recalculate estimated total

[Host Tap]
  → navigate to /host/:hostId
```

---

## 5. User Inputs

| Input | Action | Auth Required |
|---|---|---|
| Swipe media | Change carousel index | No |
| Tap media | Open fullscreen gallery | No |
| Tap "Read more" | Expand description | No |
| Tap rating/reviews | Scroll to reviews section | No |
| Tap "See all reviews" | Navigate to reviews page | No |
| Tap host section | Navigate to host profile | No |
| Tap amenity | Show amenity details (optional) | No |
| Tap map | Open location in Maps app | No |
| Select dates | Update check-in/out | No |
| Change guest count | Update guestCount | No |
| Tap favorite | Toggle save | Yes |
| Tap "Request booking" | Navigate to request form | Yes |

---

## 6. Data Outputs

### 6.1 Read Operations
| Data | Source | RLS |
|---|---|---|
| Stay details | `stay` table | Public read |
| Host details | `host` + `profile` tables | Public read |
| Reviews | `review` table (where target_type=stay) | Public read |
| Saved status | `saved_items` table | Owner read |

### 6.2 Write Operations
| Data | Action | RLS |
|---|---|---|
| Favorite toggle | INSERT/DELETE `saved_items` | Owner write |

> Note: Booking request created on next screen (05_SEND_BOOKING_REQUEST)

---

## 7. Agent Usage

### 7.1 StayDiscoveryAgent (for related stays)
**When called:**
- Initial load (for "Similar stays" section)

**Input:**
```json
{
  "city_id": "uuid",
  "exclude_stay_id": "uuid",
  "filters": {
    "room_type": "entire_place",
    "price_range": [70, 150],
    "min_rating": 4.0
  },
  "limit": 4
}
```

**Output:**
```json
{
  "stays": [
    {
      "stay_id": "uuid",
      "rank_score": 0.88,
      "price_per_night": [80, 110],
      "verified_host": true
    }
  ],
  "confidence_level": "high",
  "cache_ttl_seconds": 3600
}
```

### 7.2 TrustAgent (Optional MVP+)
- Not required for MVP
- Can provide host risk signals for admin

---

## 8. Request Booking Flow (MVP)

### 8.1 Flow Diagram
```
[User taps "Request booking"]
    ↓
[Auth check]
    ├── Not logged in → /auth/login?redirect=current
    └── Logged in → continue
    ↓
[Navigate to /stay/:stayId/request]
    (Screen 05: Send Booking Request)
    ↓
[User fills: dates, guests, message]
    ↓
[Submit request]
    → Create booking_request_stay (status: sent)
    → Notify host
    ↓
[Host receives request]
    → Accept / Reject (in Host app)
    ↓
[User notified of response]
    → If accepted: "Contact host to arrange payment"
    → If rejected: "Request declined"
```

### 8.2 No Payment in MVP
| Aspect | MVP Behavior |
|---|---|
| **Payment** | Off-platform (contact host) |
| **Deposit** | Not handled |
| **Confirmation** | Host approval only |
| **Cancellation** | Manual communication |

### 8.3 Future Phase (V1.5+)
1. Deposit via Stripe after host accepts
2. Full payment via Stripe
3. Escrow / damage handling

---

## 9. API Calls

### 9.1 Supabase Direct (RLS)
| Endpoint | Method | Purpose |
|---|---|---|
| `stay` | SELECT | Fetch stay details |
| `host` | SELECT | Fetch host details |
| `profile` | SELECT | Fetch host profile (name, avatar) |
| `review` | SELECT | Fetch verified reviews |
| `saved_items` | SELECT/INSERT/DELETE | Check/toggle favorite |

### 9.2 Edge Functions
| Function | Purpose |
|---|---|
| None on this screen | Request created on 05_SEND_BOOKING_REQUEST |

### 9.3 Cached Agent Data
| Data | Source |
|---|---|
| Related stays | `StayDiscoveryAgent` output |

---

## 10. Edge Cases

### 10.1 Stay Not Found
| Condition | Behavior |
|---|---|
| Invalid ID | Show error: "Stay not found" + back button |
| Deleted/suspended | Show error: "This stay is no longer available" |

### 10.2 Loading States
| Condition | Behavior |
|---|---|
| Initial load | Skeleton UI (image placeholder, text lines) |
| Host loading | Avatar placeholder |
| Reviews loading | Skeleton review cards |

### 10.3 Offline
| Condition | Behavior |
|---|---|
| Cached stay | Show cached data + "Offline" banner |
| No cache | Show error: "No connection" |
| Request attempt offline | Block + show "Connection required" |

### 10.4 Authentication
| Condition | Behavior |
|---|---|
| Not logged in + tap Request | Redirect to login with return URL |
| Not logged in + tap Favorite | Show login prompt (modal) |

### 10.5 Host Not Verified
| Condition | Behavior |
|---|---|
| Host pending verification | Show: "Host verification pending" (no badge) |
| Host suspended | Stay should not be visible (admin action) |

### 10.6 Availability
| Condition | Behavior |
|---|---|
| No availability data | Show: "Check with host for availability" |
| Dates blocked | Show: "Not available for selected dates" |
| Calendar empty | Hide calendar, show "Contact host" |

### 10.7 Sponsored Content
| Condition | Behavior |
|---|---|
| Stay is sponsored | Show "Sponsored" badge in header |

### 10.8 Reviews (MVP)
| Condition | Behavior |
|---|---|
| Stay reviews disabled | Show: "Reviews coming soon" or hide section |
| No reviews | Show: "Be the first to stay here!" |

---

## 11. Accessibility

- All images have alt text
- Price and rating announced by screen reader
- CTA button is focusable and has clear label
- Host section is tappable with clear focus state
- Amenity icons have labels

---

## 12. Analytics Events (MVP)

| Event | Payload |
|---|---|
| `stay_detail_viewed` | `stay_id`, `source`, `host_id`, `price_range` |
| `stay_gallery_opened` | `stay_id`, `image_index` |
| `stay_host_tapped` | `stay_id`, `host_id` |
| `stay_reviews_expanded` | `stay_id`, `review_count` |
| `stay_dates_selected` | `stay_id`, `check_in`, `check_out` |
| `stay_favorite_toggled` | `stay_id`, `is_favorited` |
| `stay_request_tapped` | `stay_id`, `host_id` |

---

## 13. Security Checklist

- [x] Stay data is public read (RLS)
- [x] Host data is public read (RLS)
- [x] Reviews filtered to verified stays only (if enabled)
- [x] Favorite toggle requires authentication
- [x] Request booking requires authentication
- [x] No payment data on this screen
- [x] Sponsored content clearly labeled
- [x] Host verification status accurate

---

## 14. Design Decisions (APPROVED)

Inherited from previous specs:
1. **Full-screen city selector**: Consistent navigation
2. **Price always as range**: Never exact (GUARDRAILS.md)
3. **Sticky CTA bar**: Always visible at bottom

Stay-specific:
1. **Host section is central**: Large, tappable, with trust signals
2. **No payment in MVP**: Request-based only
3. **Verified Host badge**: Only if admin-approved
4. **Calendar optional**: Dates can be discussed with host
5. **Reviews optional MVP**: May require manual verification

---

## 15. Related Screens

| Screen | Relationship |
|---|---|
| Map View | Entry point (pin tap) |
| Explore List | Entry point (card tap) |
| Send Booking Request | Next step after CTA tap |
| Host Profile | Navigate from host section |
| Reviews List | "See all reviews" destination |
| Login | Required for request/favorite |
| User Profile | Shows saved stays |

---

## 16. Stay vs Experience Comparison

| Aspect | Stay Detail | Experience Detail |
|---|---|---|
| **Primary CTA** | "Request booking" | "Book experience" |
| **Payment** | None (MVP) | Stripe Checkout |
| **Pricing** | Per night | Per person, duration |
| **Host focus** | Central (trust anchor) | Minimal (provider) |
| **Confirmation** | Host approval required | Instant (after payment) |
| **Reviews** | Optional / manual verify | Required verified booking |

---

## Approval Checklist

- [ ] Purpose clear
- [ ] Routes correct
- [ ] UI sections complete
- [ ] Host-centric design clear
- [ ] Request flow documented (no payment)
- [ ] Edge cases covered
- [ ] Security verified

---

**Status: AWAITING APPROVAL**
