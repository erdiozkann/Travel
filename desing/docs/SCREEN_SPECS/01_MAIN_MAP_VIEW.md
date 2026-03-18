# SCREEN SPEC: Main Map View
Screen ID: 01
Route: `/map`
Design Reference: `01_customer_core/main_map_view_-_light`

---

## 1. Purpose

The Main Map View is the **primary entry point** of the app. It provides:
- Geographic discovery of places, experiences, and stays
- Visual clustering of pins by category
- Quick preview cards for tapped pins
- Filter chips for narrowing results
- Access to Explore/Detail screens

This screen answers: **"What's around me / in this city?"**

---

## 2. Entry Points

| Source | Route | Behavior |
|---|---|---|
| App launch (default) | `/map` | Load user's current city or Barcelona (MVP default) |
| Bottom nav: Map tab | `/map` | Restore last viewport if cached |
| Deep link | `myapp://map?city=<cityId>` | Center on specified city |
| Back from Detail | pop stack | Return to map with previous state |

---

## 3. UI Sections

### 3.1 Top Bar
- **City selector** (dropdown or tap to search)
- **Current city name** displayed
- Optional: Profile avatar (tap → `/profile`)

### 3.2 Filter Chips Row
Horizontally scrollable chips:
- `All` (default)
- `Experiences`
- `Stays`
- `Food & Drink`
- `Local favorites`
- `€` / `€€` / `€€€` (price level)

Behavior:
- Single or multi-select (TBD, recommend single for MVP)
- Chips control which pins are visible

### 3.3 Map Canvas
- Full-screen interactive map (Google Maps or Mapbox)
- Pins clustered when zoomed out
- Pin types visually distinct:
  - Experience: accent color
  - Stay: secondary color
  - Place: neutral color
- Tap pin → show bottom sheet preview

### 3.4 Bottom Sheet Preview Card
Appears when user taps a pin:
- Thumbnail image
- Title
- Category badge
- Price range (e.g., `€70–120` or `€€`)
- Rating (stars + count)
- Local badge (if applicable)
- Sponsored badge (if applicable, always labeled)
- CTA: "View details" → navigates to detail screen

### 3.5 Bottom Navigation Bar
- 5 tabs: Map (active), Explore, Plan, Feed, Profile
- Persistent across all tabs

---

## 4. State Handling

### 4.1 Local State (UI)
| State | Type | Default |
|---|---|---|
| `selectedCityId` | uuid | Barcelona (MVP default) |
| `viewport` | LatLngBounds | City center bounds |
| `activeFilters` | List<FilterType> | `[All]` |
| `selectedPinId` | uuid? | null |
| `isBottomSheetVisible` | bool | false |
| `isLoading` | bool | true (initial) |

### 4.2 Cached State (Persisted)
| State | Source | TTL |
|---|---|---|
| `cityPins` | RankingAgent output | 24h (cache_ttl: 86400) |
| `lastViewport` | Local storage | Session |

### 4.3 State Transitions
```
[Initial Load]
  → fetch cached pins for city
  → if stale or missing → trigger RankingAgent
  → display pins
  → isLoading = false

[Filter Change]
  → apply filter to cached pins (client-side)
  → update visible pins

[Pin Tap]
  → selectedPinId = pin.id
  → isBottomSheetVisible = true
  → load preview data (from cache or DB)

[Viewport Change (pan/zoom)]
  → debounce 300ms
  → if new viewport significantly different → fetch new pins
```

---

## 5. User Inputs

| Input | Action | Validation |
|---|---|---|
| Tap city selector | Open city search/picker | - |
| Tap filter chip | Toggle filter, update pins | - |
| Pan/zoom map | Update viewport, lazy load pins | Debounce 300ms |
| Tap pin | Show bottom sheet preview | - |
| Tap "View details" on preview | Navigate to detail screen | - |
| Tap bottom nav item | Switch tab | - |

---

## 6. Data Outputs

### 6.1 Read Operations
| Data | Source | RLS |
|---|---|---|
| Cities list | `city` table | Public read |
| Pins (places/experiences/stays) | Cached agent output or direct query | Public read |
| Preview card data | `place`, `experience`, or `stay` table | Public read |

### 6.2 Write Operations
| Data | Source | RLS |
|---|---|---|
| None | - | - |

> Map View is **read-only**. No writes on this screen.

---

## 7. Agent Usage

### 7.1 RankingAgent
**When called:**
- Initial load (if cache stale or missing)
- City change
- Significant viewport change (>2km pan)

**Input (from AGENT_CONTRACTS.md):**
```json
{
  "city_id": "uuid",
  "viewport": {
    "ne": { "lat": 41.42, "lng": 2.20 },
    "sw": { "lat": 41.35, "lng": 2.10 }
  },
  "filters": {
    "type": "place|experience|stay",
    "categories": ["restaurant", "bar"],
    "price_level": ["€", "€€"],
    "min_rating": 0,
    "local_preference": "balanced"
  }
}
```

**Output:**
```json
{
  "items": [
    {
      "type": "experience",
      "id": "uuid",
      "rank_score": 0.87,
      "local_score": 0.72,
      "price_hint": [50, 80],
      "pin": { "lat": 41.38, "lng": 2.17 }
    }
  ],
  "confidence_level": "high",
  "cache_ttl_seconds": 86400
}
```

### 7.2 PricingAgent (Optional enhancement)
- Not required for MVP map view
- Price hints come from RankingAgent output

---

## 8. API Calls

### 8.1 Supabase Direct (RLS)
| Endpoint | Method | Purpose |
|---|---|---|
| `city` | SELECT | Get city list for selector |
| `place`, `experience`, `stay` | SELECT | Fetch preview card details |

### 8.2 Edge Functions
| Function | Purpose |
|---|---|
| `trigger_ranking_agent` | Refresh pins for viewport (async) |

### 8.3 Cache Layer
- Pins cached in local storage (per city + viewport hash)
- TTL: 24 hours
- Invalidation: manual refresh or city change

---

## 9. Edge Cases

### 9.1 No Results
| Condition | Behavior |
|---|---|
| No pins in viewport | Show empty state: "No places found here. Try zooming out or changing filters." |
| No pins in city | Show empty state: "This city is coming soon." |

### 9.2 Loading States
| Condition | Behavior |
|---|---|
| Initial load | Show skeleton pins or loading overlay |
| Agent refresh | Show subtle loading indicator (top bar) |
| Network error | Show error banner + retry button |

### 9.3 Offline
| Condition | Behavior |
|---|---|
| Cached pins available | Show cached pins with "Offline" badge |
| No cache | Show error: "No connection. Please try again." |

### 9.4 Permission Denied (Location)
| Condition | Behavior |
|---|---|
| User denies location | Default to city center (Barcelona MVP) |
| Location optional | Do not block usage |

### 9.5 Sponsored Content
| Condition | Behavior |
|---|---|
| Pin is sponsored | Show "Sponsored" badge on pin and preview card |
| Sponsored ratio | Max 20-30% of visible pins (GUARDRAILS.md) |

---

## 10. Accessibility

- Map pins have accessible labels
- Bottom sheet is keyboard navigable
- Filter chips have focus states
- Screen reader: announce pin count on filter change

---

## 11. Analytics Events (MVP)

| Event | Payload |
|---|---|
| `map_view_loaded` | `city_id`, `pin_count` |
| `filter_applied` | `filter_type`, `city_id` |
| `pin_tapped` | `item_type`, `item_id` |
| `detail_opened` | `item_type`, `item_id`, `source: map` |

---

## 12. Security Checklist

- [x] No writes on this screen
- [x] All reads via RLS-protected tables
- [x] Agent output cached, not direct
- [x] Sponsored content clearly labeled
- [x] No live location tracking (event-based only)

---

## 13. Design Decisions (APPROVED)

1. **Clustering library**: ✅ Google Maps native clustering (MVP)
2. **Filter chips**: ✅ Multi-select with rules:
   - Type (place/experience/stay) = single-select
   - Category = multi-select
   - Price level = multi-select
   - Local preference = single-select (local/balanced/tourist)
3. **City selector**: ✅ Full-screen search modal
4. **Bottom sheet height**: ✅ 3 snap points:
   - Peek: 20%
   - Half: 50–60%
   - Full: 90%

### Additional MVP Rules
- **Location denied**: City selection mandatory, "Use current location" is optional
- **Offline**: Show cached pins + top banner "Offline – showing cached results"

---

## 14. Related Screens

| Screen | Relationship |
|---|---|
| Explore List View | Alternative browse mode |
| Experience Detail | Navigates from pin tap |
| Stay Detail | Navigates from pin tap |
| AI Trip Planner | Can receive items from map |

---

## Approval Checklist

- [ ] Purpose clear
- [ ] Routes correct
- [ ] UI sections complete
- [ ] State handling defined
- [ ] Agent contracts followed
- [ ] Edge cases covered
- [ ] Security verified

---

**Status: AWAITING APPROVAL**
