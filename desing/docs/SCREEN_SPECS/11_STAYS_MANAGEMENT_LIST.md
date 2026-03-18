# SCREEN SPEC: Stays Management List
Screen ID: 11
Route: `/host/stays`
Design Reference: `02_host_core/stays_management_list`

---

## 1. Purpose

The Stays Management List is the **host's control center for all stay listings**. It provides:
- Overview of all stays (draft, published, paused)
- Quick status toggling and pricing updates
- Performance snapshot for each listing
- Entry point to create or edit stays

This screen answers: **"What's the status of my listings and how are they performing?"**

> **Host-Only**: This screen is only accessible to authenticated hosts.

---

## 2. Entry Points

| Source | Route | Behavior |
|---|---|---|
| Host Dashboard nav | `/host/stays` | Primary entry |
| Host Profile link | `/host/stays` | Manage listings |
| Create stay success | `/host/stays` | Return after creation |
| Booking request notification | `/host/stays` | Review listing |

**Prerequisites:**
- User must be authenticated
- User must have host role (host record exists)

---

## 3. UI Sections

### 3.1 Header
| Element | Description |
|---|---|
| **Title** | "My Stays" |
| **Create button** | "+ Add Stay" (primary CTA) |
| **Filter dropdown** | Filter by status |

### 3.2 Status Filter Tabs
| Tab | Filter | Description |
|---|---|---|
| **All** | All stays | Default view |
| **Published** | status = active | Live listings |
| **Paused** | status = paused | Temporarily hidden |
| **Drafts** | status = draft | Incomplete listings |

### 3.3 Stay Card (List Item)
Each stay displayed as a management card:

#### 3.3.1 Card Header
| Element | Description |
|---|---|
| **Thumbnail** | First listing photo |
| **Title** | Stay name |
| **Status badge** | "Published" / "Paused" / "Draft" |
| **More menu** | "..." → Edit / Pause / Delete |

#### 3.3.2 Pricing Section
| Element | Description |
|---|---|
| **Price range** | "€85 – €120 / night" |
| **Edit button** | Quick edit pricing inline |
| **Last updated** | "Updated 3 days ago" |

#### 3.3.3 Performance Snapshot
| Metric | Display |
|---|---|
| **Views** | "124 views this week" |
| **Requests** | "8 booking requests" |
| **Conversion** | "6.5% request rate" (optional) |

#### 3.3.4 Quick Actions
| Element | Description |
|---|---|
| **Availability toggle** | On/Off switch |
| **Edit button** | Navigate to edit stay form |
| **View listing** | Preview as guest sees it |

### 3.4 Empty State
| Condition | Display |
|---|---|
| No stays at all | Illustration + "List your first stay" + CTA |
| No stays in filter | "No [status] stays" + suggestion |

### 3.5 Summary Stats (Top of List)
| Stat | Display |
|---|---|
| **Total listings** | "4 stays" |
| **Active** | "3 published" |
| **Total views** | "450 views this month" |
| **Pending requests** | "5 pending requests" (badge) |

---

## 4. Stay Status States

### 4.1 Status Definitions
| Status | Description | Visible to Guests |
|---|---|---|
| `draft` | Incomplete listing | ❌ No |
| `active` (Published) | Live and bookable | ✅ Yes |
| `paused` | Temporarily hidden | ❌ No |
| `suspended` | Admin-blocked | ❌ No |

### 4.2 Status Transitions
```
[draft] → Complete form → [active]
[active] → Toggle pause → [paused]
[paused] → Toggle unpause → [active]
[active] → Admin action → [suspended]
[suspended] → Admin review → [active] or delete
[any] → Host delete → removed
```

### 4.3 Status Badge Colors
| Status | Color |
|---|---|
| Published | Green |
| Paused | Yellow |
| Draft | Gray |
| Suspended | Red |

---

## 5. State Handling

### 5.1 Local State (UI)
| State | Type | Default |
|---|---|---|
| `stays` | List<Stay> | [] |
| `activeFilter` | enum | all |
| `isLoading` | bool | true |
| `editingPriceId` | uuid? | null |
| `tempPriceMin` | int? | null |
| `tempPriceMax` | int? | null |

### 5.2 Derived State
| State | Calculation |
|---|---|
| `filteredStays` | Filter stays by activeFilter |
| `publishedCount` | Count where status = active |
| `pendingRequestsCount` | Aggregate from booking_request_stay |

### 5.3 State Transitions
```
[Screen Load]
  → verify host role
  → fetch all host's stays
  → fetch summary stats
  → isLoading = false

[Filter Change]
  → update activeFilter
  → filteredStays recalculated (client-side)

[Availability Toggle]
  → optimistic UI update
  → call API to update status
  → on error → revert

[Quick Price Edit]
  → editingPriceId = stay.id
  → show inline price editor
  → on save → call API
  → on success → update local state

[Create Stay Tap]
  → navigate to /host/stays/new

[Edit Stay Tap]
  → navigate to /host/stays/:stayId/edit

[Delete Stay Tap]
  → confirm dialog
  → if confirmed → call API
  → remove from local state
```

---

## 6. User Inputs

| Input | Action | Validation |
|---|---|---|
| Tap filter tab | Filter stays | - |
| Tap "+ Add Stay" | Navigate to create form | - |
| Tap stay card | Navigate to edit | - |
| Tap availability toggle | Change status | - |
| Tap edit price | Open inline editor | Min ≤ Max, > 0 |
| Tap "..." menu | Show options | - |
| Tap "Pause" | Set status = paused | - |
| Tap "Delete" | Confirm then delete | - |
| Tap "View listing" | Open guest preview | - |
| Pull to refresh | Refresh list | - |

---

## 7. Inline Price Editor

### 7.1 UI
| Element | Description |
|---|---|
| **Min price input** | Number field with currency |
| **Max price input** | Number field with currency |
| **Save button** | Confirm changes |
| **Cancel button** | Discard changes |
| **Validation** | Real-time validation |

### 7.2 Validation Rules
| Rule | Error Message |
|---|---|
| Min > 0 | "Minimum price must be greater than 0" |
| Max ≥ Min | "Maximum must be ≥ minimum" |
| Max ≤ 10000 | "Maximum price cannot exceed €10,000" |

### 7.3 Price Edit Flow
```
[Tap edit price]
    ↓
[Show inline editor with current values]
    ↓
[User edits values]
    ↓
[Tap Save]
    → Validate
    → Call API
    → Update local state
    → Close editor
```

---

## 8. Data Outputs

### 8.1 Read Operations
| Data | Source | RLS |
|---|---|---|
| Host's stays | `stay` table (where host_id = current) | Owner read |
| Performance stats | Aggregated views/requests | Owner read |
| Pending requests | `booking_request_stay` (status = sent) | Host read |

### 8.2 Write Operations
| Data | Table | RLS |
|---|---|---|
| Toggle status | `stay` (status field) | Owner write |
| Update pricing | `stay` (price fields) | Owner write |
| Delete stay | `stay` (soft delete or delete) | Owner write |

---

## 9. Agent Usage (Optional MVP)

### 9.1 ListingQualityAgent
**When called:**
- On stay card render (cached)
- Host opens improvement tips

**Input:**
```json
{
  "stay_id": "uuid"
}
```

**Output:**
```json
{
  "quality_score": 0.72,
  "issues": [
    { "type": "photos", "message": "Add more photos for higher visibility" },
    { "type": "description", "message": "Description is too short" }
  ],
  "improvement_tips": [
    "Professional photos can increase bookings by 40%",
    "Respond to requests within 4 hours"
  ],
  "confidence_level": "medium",
  "cache_ttl_seconds": 86400
}
```

> **MVP Note**: Can skip agent and use simple completeness check.

### 9.2 AvailabilityAgent (Not in MVP)
- Calendar sync not included in MVP
- Simple on/off toggle only

---

## 10. API Calls

### 10.1 Supabase Direct (RLS)
| Endpoint | Method | Purpose |
|---|---|---|
| `stay` | SELECT | Fetch host's stays |
| `stay` | UPDATE | Update status/pricing |
| `stay` | DELETE | Delete stay |
| `booking_request_stay` | SELECT | Count pending requests |

### 10.2 Edge Functions
| Function | Purpose |
|---|---|
| `get_stay_performance` | Aggregate views/requests |
| `get_listing_quality` | Trigger ListingQualityAgent (optional) |

---

## 11. Edge Cases

### 11.1 Not a Host
| Condition | Behavior |
|---|---|
| User has no host record | Redirect to "Become a Host" flow |
| Host suspended | Show suspension message |

### 11.2 Loading States
| Condition | Behavior |
|---|---|
| Initial load | Skeleton cards |
| Toggle processing | Disabled toggle + spinner |
| Price saving | Disabled save button + spinner |

### 11.3 Empty States
| Filter | Empty Message |
|---|---|
| All | "You haven't created any stays yet. List your first stay!" |
| Published | "No published stays. Publish a draft to go live." |
| Paused | "No paused stays." |
| Drafts | "No drafts. All your stays are published!" |

### 11.4 Delete Confirmation
| Element | Description |
|---|---|
| Dialog title | "Delete this stay?" |
| Warning | "This action cannot be undone. Active booking requests will be affected." |
| Confirm button | "Delete" (destructive) |
| Cancel button | "Keep stay" |

### 11.5 Offline
| Condition | Behavior |
|---|---|
| Cached stays | Show cached + "Offline" banner |
| Toggle offline | Block, show "Connection required" |
| Create offline | Block, show "Connection required" |

### 11.6 Pending Requests Warning
| Condition | Behavior |
|---|---|
| Pause with pending requests | Warning: "You have X pending requests" |
| Delete with pending requests | Warning: "Pending requests will be canceled" |

---

## 12. Accessibility

- Status badges have accessible labels
- Toggle switches have state announcements
- Price editor has labeled inputs
- Cards are keyboard navigable
- Delete confirmation is focusable

---

## 13. Analytics Events (MVP)

| Event | Payload |
|---|---|
| `stays_management_viewed` | `host_id`, `stay_count` |
| `stays_filter_changed` | `filter_type` |
| `stay_status_toggled` | `stay_id`, `new_status` |
| `stay_price_edited` | `stay_id`, `old_min`, `old_max`, `new_min`, `new_max` |
| `stay_deleted` | `stay_id`, `had_pending_requests` |
| `stay_create_tapped` | `source` |
| `stay_edit_tapped` | `stay_id` |
| `stay_preview_tapped` | `stay_id` |

---

## 14. Security Checklist

- [x] Host-only access (RLS)
- [x] Can only see/edit own stays (RLS)
- [x] Price validation server-side
- [x] Delete confirmation required
- [x] Suspended hosts blocked
- [x] Status changes logged
- [x] No access to other hosts' data

---

## 15. Design Decisions (APPROVED)

Stays Management specific:
1. **List view only**: Grid not needed for management
2. **Inline price editing**: Quick updates without navigation
3. **Simple on/off availability**: No calendar sync in MVP
4. **Performance snapshot**: Motivate hosts with visible metrics
5. **Status filter tabs**: Quick navigation between states
6. **Pending requests badge**: Urgent action visibility
7. **Confirmation for destructive actions**: Prevent accidents

---

## 16. Related Screens

| Screen | Relationship |
|---|---|
| Create Stay (Form) | "+ Add Stay" destination |
| Edit Stay (Form) | Card tap destination |
| Stay Detail (Guest View) | "View listing" preview |
| Host Dashboard | Parent navigation |
| Booking Requests | Linked via pending count |

---

## 17. MVP vs Future Features

| Feature | MVP | Future |
|---|---|---|
| List/Grid toggle | ❌ List only | ✅ Add grid |
| On/Off availability | ✅ | Calendar sync |
| Price range edit | ✅ Inline | Seasonal pricing |
| Performance stats | ✅ Basic | Detailed analytics |
| Quality agent | ❌ Optional | ✅ Recommendations |
| Bulk actions | ❌ | ✅ Multi-select |
| Duplicate listing | ❌ | ✅ Clone stay |

---

## Approval Checklist

- [ ] Purpose clear
- [ ] Routes correct
- [ ] UI sections complete
- [ ] Status states defined
- [ ] Pricing editor specified
- [ ] Performance metrics included
- [ ] Edge cases covered
- [ ] Security verified

---

**Status: AWAITING APPROVAL**
