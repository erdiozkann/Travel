# SCREEN SPEC: AI Trip Planner
Screen ID: 06
Route: `/plan`
Design Reference: `01_customer_core/ai_trip_planner_-_light`

---

## 1. Purpose

The AI Trip Planner is the **smart planning assistant** that generates personalized day-by-day itineraries. It provides:
- Input-driven planning (days, budget, interests, pace)
- AI-generated multi-day plans
- Clear AI labeling with confidence levels
- Editable/regenerable plan sections
- Save plans to profile
- Links to detail pages (no direct booking)

This screen answers: **"What should I do each day in this city?"**

> **AI Rule**: AI assists, never decides. All AI content labeled. Confidence visible.

---

## 2. Entry Points

| Source | Route | Behavior |
|---|---|---|
| Bottom nav: Plan tab | `/plan` | Show input form (or last plan) |
| Deep link | `myapp://plan` | Open planner |
| Map/Explore item | "Add to plan" action | Pre-populate with item |
| Saved plan tap | `/plan/:planId` | View saved plan |
| Profile / My Plans | `/profile/plans` → tap | Open saved plan |

---

## 3. UI Sections

### 3.1 Header
| Element | Description |
|---|---|
| **Title** | "Plan Your Trip" |
| **City selector** | Current city (tap to change) |
| **Saved plans icon** | Navigate to `/profile/plans` |

### 3.2 Input Form (Initial State)
Shown when no plan is generated yet.

#### 3.2.1 Date Range
| Element | Description |
|---|---|
| **Start date** | Date picker |
| **End date** | Date picker |
| **Duration** | Auto-calculated: "3 days" |
| **Max MVP** | 7 days (prevent overload) |

#### 3.2.2 Budget Level
| Element | Description |
|---|---|
| **Selector** | Segmented control: Low / Mid / High |
| **Hints** | "€30–50/day" / "€50–100/day" / "€100+/day" |
| **Default** | Mid |

#### 3.2.3 Interests (Multi-select)
| Element | Description |
|---|---|
| **Chips** | Food, Culture, Nightlife, Nature, Art, Adventure, Shopping, Local hidden gems |
| **Selection** | Multi-select (min 1, max 5 recommended) |
| **Visual** | Checkmark or highlight on selected |

#### 3.2.4 Pace
| Element | Description |
|---|---|
| **Selector** | Segmented: Relaxed / Balanced / Intense |
| **Hint** | "2–3 activities/day" / "4–5/day" / "6+/day" |
| **Default** | Balanced |

#### 3.2.5 Generate Button
| Element | Description |
|---|---|
| **CTA** | **"Generate My Plan"** (primary) |
| **Loading** | Spinner + "AI is thinking..." |

---

### 3.3 Generated Plan View
Shown after AI generates the plan.

#### 3.3.1 Plan Summary Header
| Element | Description |
|---|---|
| **AI badge** | "AI Generated Plan" (always visible) |
| **Confidence** | "High / Medium / Low confidence" badge |
| **Date range** | "Mar 15 – Mar 18, 2026" |
| **Budget level** | "Mid budget" |
| **Interests** | Chips showing selected interests |

#### 3.3.2 Estimated Total Cost
| Element | Description |
|---|---|
| **Display** | "Estimated: €180 – €280" |
| **Note** | "Prices are approximate ranges" |

#### 3.3.3 Day-by-Day Cards
Vertical list of day cards.

**Day Card:**
| Element | Description |
|---|---|
| **Day header** | "Day 1 • Saturday, Mar 15" |
| **Expand/collapse** | Accordion behavior |
| **Items** | List of time slots |

**Time Slot Item:**
| Element | Description |
|---|---|
| **Time label** | "Morning" / "Afternoon" / "Evening" |
| **Item type** | Experience / Place icon |
| **Title** | e.g., "Gothic Quarter Walking Tour" |
| **Duration** | "3 hours" |
| **Price hint** | "€30–45" |
| **Why** | AI explanation: "Great for first-time visitors" |
| **Tap action** | Navigate to detail page |
| **Regenerate** | "↻ Suggest alternative" button |

#### 3.3.4 Bottom Actions
| Element | Description |
|---|---|
| **Save Plan** | "Save to My Plans" (if not saved) |
| **Regenerate All** | "Start Over" (clears and shows form) |
| **Share** | "Share Plan" (optional MVP) |

---

### 3.4 Saved Plan Indicator
| State | Display |
|---|---|
| Not saved | "Save to My Plans" button visible |
| Saved | ✅ "Saved" badge + "View in Profile" link |

---

### 3.5 Empty State (No Previous Plans)
| Element | Description |
|---|---|
| **Illustration** | Planning-related graphic |
| **Title** | "Plan your Barcelona adventure" |
| **Subtitle** | "Tell us what you like, and AI will create your perfect itinerary" |
| **CTA** | Show input form |

---

## 4. State Handling

### 4.1 Local State (UI)
| State | Type | Default |
|---|---|---|
| `cityId` | uuid | Barcelona (MVP default) |
| `startDate` | Date? | null |
| `endDate` | Date? | null |
| `budgetLevel` | enum | mid |
| `interests` | List<string> | [] |
| `pace` | enum | balanced |
| `generatedPlan` | Plan? | null |
| `isGenerating` | bool | false |
| `isSaved` | bool | false |
| `expandedDays` | Set<int> | {0} (first day expanded) |

### 4.2 Cached State
| State | Source | TTL |
|---|---|---|
| `savedPlans` | DB (user_plans table) | Until modified |
| `generatedPlan` | Agent output | 7 days (cache_ttl: 604800) |

### 4.3 State Transitions
```
[Screen Load]
  → if returning user with recent plan → show generated plan
  → else → show input form

[Input Change]
  → update corresponding state
  → clear generated plan (if inputs changed after generation)

[Generate Tap]
  → validate inputs (dates, at least 1 interest)
  → isGenerating = true
  → call TripPlannerAgent (async via Edge Function)
  → on success → generatedPlan = result, isGenerating = false
  → on error → show error, isGenerating = false

[Day Expand/Collapse]
  → toggle day in expandedDays set

[Item Tap]
  → navigate to /explore/experience/:id or /explore/stay/:id

[Regenerate Slot Tap]
  → call agent for single slot replacement
  → update that slot in plan

[Save Tap]
  → if not authenticated → prompt login
  → save plan to user_plans table
  → isSaved = true

[Start Over Tap]
  → clear generatedPlan
  → show input form
```

---

## 5. User Inputs

| Input | Action | Auth Required |
|---|---|---|
| Select dates | Update start/end date | No |
| Select budget | Update budgetLevel | No |
| Toggle interests | Add/remove from interests | No |
| Select pace | Update pace | No |
| Tap "Generate My Plan" | Trigger AI generation | No |
| Expand/collapse day | Toggle accordion | No |
| Tap plan item | Navigate to detail | No |
| Tap "↻ Suggest alternative" | Regenerate single slot | No |
| Tap "Save to My Plans" | Save plan | Yes |
| Tap "Start Over" | Clear and reset | No |
| Tap city selector | Open city modal | No |

---

## 6. Data Outputs

### 6.1 Read Operations
| Data | Source | RLS |
|---|---|---|
| City info | `city` table | Public read |
| Saved plans | `user_plans` table | Owner read |
| Experience/Place data | Referenced tables | Public read |

### 6.2 Write Operations
| Data | Table | RLS |
|---|---|---|
| Save plan | `user_plans` | Owner write |

**Saved Plan Record:**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "city_id": "uuid",
  "plan_data": { /* full AI output */ },
  "date_range": {"start": "2026-03-15", "end": "2026-03-18"},
  "budget_level": "mid",
  "interests": ["food", "culture"],
  "created_at": "timestamp"
}
```

---

## 7. Agent Usage

### 7.1 TripPlannerAgent (Primary)
**When called:**
- Generate button tap
- Regenerate single slot (with context)

**Input (from AGENT_CONTRACTS.md):**
```json
{
  "city_id": "uuid",
  "date_range": {
    "start": "2026-03-15",
    "end": "2026-03-18"
  },
  "budget_level": "mid",
  "interests": ["food", "culture", "local"],
  "pace": "balanced"
}
```

**Output:**
```json
{
  "plan_id": "uuid",
  "days": [
    {
      "date": "2026-03-15",
      "items": [
        {
          "slot": "morning",
          "type": "experience",
          "id": "uuid-gothic-tour",
          "estimated_cost": [30, 45],
          "why": "Perfect introduction to Barcelona's history"
        },
        {
          "slot": "afternoon",
          "type": "place",
          "id": "uuid-la-boqueria",
          "estimated_cost": [15, 25],
          "why": "Local market experience, great for food lovers"
        },
        {
          "slot": "evening",
          "type": "place",
          "id": "uuid-el-xampanyet",
          "estimated_cost": [20, 35],
          "why": "Authentic tapas bar, local favorite"
        }
      ]
    }
  ],
  "total_estimated_cost": [180, 280],
  "confidence_level": "high",
  "cache_ttl_seconds": 604800
}
```

### 7.2 Slot Regeneration
**Input (single slot):**
```json
{
  "city_id": "uuid",
  "date": "2026-03-15",
  "slot": "morning",
  "exclude_id": "uuid-gothic-tour",
  "context": {
    "budget_level": "mid",
    "interests": ["food", "culture"]
  }
}
```

**Output:**
```json
{
  "slot": "morning",
  "type": "experience",
  "id": "uuid-alternative-tour",
  "estimated_cost": [25, 40],
  "why": "Art-focused alternative for culture enthusiasts",
  "confidence_level": "medium"
}
```

---

## 8. API Calls

### 8.1 Supabase Direct (RLS)
| Endpoint | Method | Purpose |
|---|---|---|
| `city` | SELECT | City info |
| `user_plans` | SELECT/INSERT | Saved plans |
| `experience`, `place` | SELECT | Item details for display |

### 8.2 Edge Functions
| Function | Purpose |
|---|---|
| `generate_trip_plan` | Trigger TripPlannerAgent, return plan |
| `regenerate_plan_slot` | Replace single slot |

### 8.3 Async Flow
```
[Client] → POST /functions/v1/generate_trip_plan
    ↓
[Edge Function] → Call TripPlannerAgent
    ↓
[Agent] → Generate plan (may take 2-5 seconds)
    ↓
[Edge Function] → Cache result, return to client
    ↓
[Client] → Display plan
```

**Loading UX:**
- Show "AI is thinking..." with progress hints
- Optional: Stream partial results (MVP can skip)

---

## 9. AI Display Rules (Mandatory)

### 9.1 AI Labeling
| Requirement | Implementation |
|---|---|
| AI badge | "AI Generated Plan" always visible in header |
| Per-item source | "AI suggestion" label on each item |
| Confidence | Badge: "High / Medium / Low confidence" |

### 9.2 Disclaimer
| Location | Text |
|---|---|
| Plan header | "Prices are estimates. Check details before booking." |
| Footer | "AI suggestions based on available data. Results may vary." |

### 9.3 No Absolute Claims
| ❌ Don't say | ✅ Say instead |
|---|---|
| "Best restaurant in Barcelona" | "Popular choice for food lovers" |
| "You will love this" | "Highly rated by visitors" |
| "Guaranteed experience" | "Often recommended" |

---

## 10. Edge Cases

### 10.1 Input Validation
| Condition | Behavior |
|---|---|
| No dates selected | Disable generate, show "Select dates" |
| End < Start | Show error: "End date must be after start" |
| > 7 days | Show warning, cap at 7 for MVP |
| No interests selected | Show warning: "Select at least 1 interest" |

### 10.2 Generation Errors
| Condition | Behavior |
|---|---|
| Network error | Show error + retry button |
| Agent timeout | Show "Taking longer than expected..." + retry |
| No results for city | Show "Limited data for this city. Try Barcelona." |
| Partial failure | Show partial plan + "Some slots couldn't be filled" |

### 10.3 Loading States
| Condition | Behavior |
|---|---|
| Generating | Full-screen overlay with progress animation |
| Regenerating slot | Inline spinner on that slot |
| Saving | Button loading state |

### 10.4 Offline
| Condition | Behavior |
|---|---|
| Viewing saved plan | Works offline |
| Generating new plan | Block, show "Connection required" |
| Cached recent plan | Show cached + "Offline" badge |

### 10.5 Empty/Sparse Data
| Condition | Behavior |
|---|---|
| City has few items | Show shorter plan + "Limited options available" |
| Interests have no matches | Broaden suggestions + explain |

### 10.6 Authentication
| Condition | Behavior |
|---|---|
| Generate without login | Works (AI planning is free) |
| Save without login | Prompt login modal |
| Return after login | Preserve generated plan, then save |

---

## 11. Accessibility

- Date pickers are accessible
- Interest chips have toggle announcements
- Day accordions announce expand/collapse
- Plan items are tappable with clear labels
- AI confidence announced by screen reader

---

## 12. Analytics Events (MVP)

| Event | Payload |
|---|---|
| `trip_planner_opened` | `city_id` |
| `trip_plan_inputs_set` | `city_id`, `days`, `budget`, `interests`, `pace` |
| `trip_plan_generated` | `city_id`, `days`, `item_count`, `confidence` |
| `trip_plan_slot_tapped` | `city_id`, `slot`, `item_type`, `item_id` |
| `trip_plan_slot_regenerated` | `city_id`, `date`, `slot` |
| `trip_plan_saved` | `plan_id`, `city_id` |
| `trip_plan_start_over` | `city_id` |

---

## 13. Security Checklist

- [x] AI generation is async (no blocking UI)
- [x] AI content always labeled
- [x] Confidence level always visible
- [x] No absolute claims in AI output
- [x] Save requires authentication
- [x] Plan data cached per user
- [x] No direct booking from planner (links only)
- [x] Rate limiting on generation requests

---

## 14. Design Decisions (APPROVED)

AI Planner-specific:
1. **Generate without login**: Lower friction for discovery
2. **Save requires login**: Monetization-friendly (capture users)
3. **Max 7 days MVP**: Prevent agent overload
4. **No direct booking**: Links to detail pages only
5. **Slot regeneration**: Allow partial edits without full regenerate
6. **AI badge always visible**: Trust and transparency
7. **Day accordion**: Mobile-friendly for long plans

---

## 15. Related Screens

| Screen | Relationship |
|---|---|
| Map View | Can add items to plan |
| Explore List | Can add items to plan |
| Experience Detail | Linked from plan items |
| Place Detail | Linked from plan items (optional) |
| Profile / My Plans | Saved plans destination |
| Login | Required for save |

---

## 16. Plan Item Actions (No Direct Booking)

| Action | Where it happens |
|---|---|
| View item | Tap → navigate to detail page |
| Book experience | On Experience Detail (Stripe) |
| Request stay | On Stay Detail (request form) |
| Save item | On detail page (favorite) |
| Remove from plan | "↻ Suggest alternative" replaces it |

> **Rule**: Planner is for discovery and planning. Booking happens on detail pages.

---

## Approval Checklist

- [ ] Purpose clear
- [ ] Input form complete
- [ ] Plan display defined
- [ ] AI labeling rules followed
- [ ] Agent contracts matched
- [ ] Regeneration flow defined
- [ ] Edge cases covered
- [ ] No direct booking (confirmed)

---

**Status: AWAITING APPROVAL**
