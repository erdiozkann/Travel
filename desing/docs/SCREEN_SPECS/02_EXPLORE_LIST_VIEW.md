# SCREEN SPEC: Explore List View
Screen ID: 02
Route: `/explore`
Design Reference: `01_customer_core/explore_hub_-_light`

---

## 1. Purpose

The Explore List View is the **list-based discovery** alternative to the Map View. It provides:
- Scrollable, paginated list of places, experiences, and stays
- Powerful filtering and search
- Quick comparison of options (price, rating, badges)
- Entry point to all detail screens

This screen answers: **"What can I do / where can I stay in this city?"**

---

## 2. Entry Points

| Source | Route | Behavior |
|---|---|---|
| Bottom nav: Explore tab | `/explore` | Load with last filters or default |
| Map View (optional link) | `/explore` | Preserve city context |
| Deep link | `myapp://explore?city=<cityId>&type=experience` | Pre-filter by params |
| Search from anywhere | `/explore/search` | Open with search overlay active |
| Back from Detail | pop stack | Return to list with scroll position preserved |

---

## 3. UI Sections

### 3.1 Top Bar
- **Search bar** (tap to open search overlay)
- **City name** (tap to open full-screen city selector)
- Optional: Filter icon (opens filter sheet)

### 3.2 Segment Control / Tab Bar
Horizontal tabs for primary type filter:
- `All`
- `Experiences`
- `Stays`
- `Places` (optional MVP)

Behavior:
- Single-select
- Changes visible list immediately

### 3.3 Filter Chips Row
Secondary filters (horizontally scrollable):
- **Category chips**: Restaurant, Bar, Tour, Course, Surf, etc.
- **Price level**: `€` / `€€` / `€€€` (multi-select)
- **Rating**: `4+`, `4.5+` (single-select)
- **Local badge**: `Local favorites` (toggle)
- **Sorting**: `Recommended` / `Price low→high` / `Rating`

### 3.4 Results List
Vertical scrollable list with pagination:
- **ExperienceCard** (when type = experience)
  - Thumbnail, title, duration, price range, rating, local badge, sponsored badge
- **StayCard** (when type = stay)
  - Thumbnail, title, nightly price range, room type, host badge, rating, sponsored badge
- **PlaceCard** (when type = place, optional MVP)
  - Thumbnail, title, category, price level, rating, local badge

Behavior:
- Infinite scroll with pagination (20 items per page)
- Pull-to-refresh
- Skeleton loading for new pages

### 3.5 Empty State
- Illustration + message: "No results found. Try adjusting your filters."
- CTA: "Clear filters"

### 3.6 Bottom Navigation Bar
- 5 tabs: Map, Explore (active), Plan, Feed, Profile

---

## 4. State Handling

### 4.1 Local State (UI)
| State | Type | Default |
|---|---|---|
| `selectedCityId` | uuid | Barcelona (MVP default) |
| `activeType` | enum | `all` |
| `categoryFilters` | List<string> | `[]` |
| `priceLevels` | List<string> | `[]` |
| `minRating` | float? | null |
| `localOnly` | bool | false |
| `sortBy` | enum | `recommended` |
| `searchQuery` | string? | null |
| `items` | List<Item> | `[]` |
| `currentPage` | int | 1 |
| `hasMore` | bool | true |
| `isLoading` | bool | true |
| `scrollPosition` | offset | 0 |

### 4.2 Cached State (Persisted)
| State | Source | TTL |
|---|---|---|
| `lastFilters` | Local storage | Session |
| `agentRankings` | DiscoveryAgent output | 24h |

### 4.3 State Transitions
```
[Initial Load]
  → restore lastFilters (if any)
  → fetch page 1 from cache or API
  → isLoading = false

[Filter Change]
  → reset items = []
  → reset currentPage = 1
  → fetch page 1 with new filters
  → save lastFilters

[Type Tab Change]
  → same as filter change
  → scroll to top

[Scroll to Bottom]
  → if hasMore → fetch next page
  → append to items

[Pull to Refresh]
  → reset currentPage = 1
  → fetch fresh data (bypass cache)

[Search Submit]
  → apply searchQuery filter
  → fetch results
```

---

## 5. User Inputs

| Input | Action | Validation |
|---|---|---|
| Tap search bar | Open search overlay | - |
| Type in search | Debounce 300ms, then search | Min 2 chars |
| Tap city selector | Open full-screen city modal | - |
| Tap type tab | Switch type filter | - |
| Tap filter chip | Toggle filter, reload list | - |
| Tap sort option | Change sort, reload list | - |
| Scroll to bottom | Load next page | - |
| Pull down | Refresh list | - |
| Tap card | Navigate to detail screen | - |

---

## 6. Data Outputs

### 6.1 Read Operations
| Data | Source | RLS |
|---|---|---|
| Cities list | `city` table | Public read |
| Experiences | `experience` table | Public read |
| Stays | `stay` table | Public read |
| Places | `place` table | Public read |
| Agent rankings | Cached agent output | - |

### 6.2 Write Operations
| Data | Source | RLS |
|---|---|---|
| None | - | - |

> Explore View is **read-only**. No writes on this screen.

---

## 7. Agent Usage

### 7.1 DiscoveryAgent
**When called:**
- Initial load (if cache stale)
- Filter change
- City change

**Input:**
```json
{
  "city_id": "uuid",
  "type": "all|experience|stay|place",
  "filters": {
    "categories": ["tour", "course"],
    "price_levels": ["€", "€€"],
    "min_rating": 4.0,
    "local_only": false
  },
  "sort_by": "recommended|price_asc|rating_desc",
  "page": 1,
  "page_size": 20
}
```

**Output:**
```json
{
  "items": [
    {
      "type": "experience",
      "id": "uuid",
      "rank_score": 0.92,
      "local_score": 0.85,
      "price_range": [40, 70],
      "rating_avg": 4.6,
      "sponsored": false
    }
  ],
  "total_count": 156,
  "has_more": true,
  "confidence_level": "high",
  "cache_ttl_seconds": 86400
}
```

### 7.2 PersonalizationAgent (Optional MVP+)
- Not required for MVP
- Can be added later to personalize ranking based on user history

---

## 8. API Calls

### 8.1 Supabase Direct (RLS)
| Endpoint | Method | Purpose |
|---|---|---|
| `city` | SELECT | City list for selector |
| `experience` | SELECT | Paginated experience list |
| `stay` | SELECT | Paginated stay list |
| `place` | SELECT | Paginated place list (optional) |

**Query pattern:**
```sql
SELECT * FROM experience
WHERE city_id = $1
  AND category = ANY($2)
  AND price_range_min >= $3
  AND rating_avg >= $4
ORDER BY rank_score DESC
LIMIT 20 OFFSET $5
```

### 8.2 Edge Functions
| Function | Purpose |
|---|---|
| `trigger_discovery_agent` | Refresh rankings for city (async) |

### 8.3 Cache Layer
- Results cached per: `city_id + type + filters_hash + page`
- TTL: 24 hours for general, 1 hour for personalized
- Invalidation: manual refresh or filter change

---

## 9. Edge Cases

### 9.1 No Results
| Condition | Behavior |
|---|---|
| No items match filters | Show empty state with "Clear filters" CTA |
| No items in city | Show empty state: "This city is coming soon." |
| Search returns nothing | Show: "No results for '[query]'. Try different keywords." |

### 9.2 Loading States
| Condition | Behavior |
|---|---|
| Initial load | Show skeleton cards (4-6) |
| Loading next page | Show loading indicator at bottom |
| Pull to refresh | Show refresh indicator at top |
| Network error | Show error banner + retry button |

### 9.3 Offline
| Condition | Behavior |
|---|---|
| Cached items available | Show cached list + "Offline" banner |
| No cache | Show error: "No connection. Please try again." |
| Pagination offline | Disable "load more", show message |

### 9.4 Sponsored Content
| Condition | Behavior |
|---|---|
| Item is sponsored | Show "Sponsored" badge on card |
| Sponsored ratio | Max 20-30% of results (1 in 4-5 cards) |
| Sponsored placement | Can appear in top positions, but never 100% top |

### 9.5 Large Result Sets
| Condition | Behavior |
|---|---|
| > 1000 results | Use cursor-based pagination |
| Scroll position lost | Restore on back navigation |

---

## 10. Accessibility

- All cards have accessible labels (title, price, rating read aloud)
- Filter chips have focus states and are keyboard navigable
- Screen reader: announce "X results found" on filter change
- List items are swipeable for quick actions (optional MVP+)

---

## 11. Analytics Events (MVP)

| Event | Payload |
|---|---|
| `explore_view_loaded` | `city_id`, `type`, `result_count` |
| `filter_applied` | `filter_type`, `filter_value`, `city_id` |
| `search_performed` | `query`, `result_count` |
| `card_tapped` | `item_type`, `item_id`, `position` |
| `page_loaded` | `page_number`, `item_count` |

---

## 12. Security Checklist

- [x] No writes on this screen
- [x] All reads via RLS-protected tables
- [x] Search input sanitized
- [x] Pagination prevents data dump
- [x] Sponsored content clearly labeled
- [x] No user data exposed in list

---

## 13. Design Decisions (APPROVED)

Inherited from Map View:
1. **City selector**: ✅ Full-screen search modal
2. **Price level chips**: ✅ Multi-select

Explore-specific:
1. **Type tabs**: ✅ Single-select (All / Experiences / Stays)
2. **Category chips**: ✅ Multi-select
3. **Pagination**: ✅ Infinite scroll (20 items per page)
4. **Sort options**: ✅ Recommended (default), Price, Rating

---

## 14. Related Screens

| Screen | Relationship |
|---|---|
| Main Map View | Alternative browse mode (geographic) |
| Experience Detail | Navigates from experience card tap |
| Stay Detail | Navigates from stay card tap |
| AI Trip Planner | Can receive items from Explore |
| Search Overlay | Opens from search bar tap |

---

## 15. Differences from Map View

| Aspect | Map View | Explore List View |
|---|---|---|
| Primary UI | Map canvas + pins | Scrollable list |
| Discovery style | Geographic | List-based |
| Comparison | Harder (one at a time) | Easier (side by side) |
| Filters | Basic chips | Full filter set |
| Search | No | Yes |
| Sorting | By location | By ranking/price/rating |

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
