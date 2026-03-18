# SCREEN SPEC: Admin Dashboard
Screen ID: 12
Route: `/admin` + `/admin/dashboard`
Design Reference: `03_admin_core/admin_panel_-_light`

---

## 1. Purpose

The Admin Dashboard is the **platform control center** for administrators. It provides:
- High-level platform metrics (users, posts, bookings)
- Pending moderation queues (hosts, posts, reports)
- Quick moderation actions (approve, reject, suspend)
- Brand management with global sync
- Audit logging for all admin actions

This screen answers: **"What's the health of the platform and what needs my attention?"**

> **Admin Philosophy**: Admin is a control center, not a consumer UI. Operational clarity > aesthetics.

---

## 2. Entry Points

| Source | Route | Behavior |
|---|---|---|
| Hidden nav link | `/admin` | Redirects to dashboard |
| Direct URL | `/admin/dashboard` | Main dashboard |
| Admin deep link | `myapp://admin` | Open if admin role |

**Prerequisites:**
- User must be authenticated
- User must have admin role
- Role verified server-side on every request

---

## 3. UI Sections

### 3.1 Admin Header
| Element | Description |
|---|---|
| **Title** | "Admin Dashboard" |
| **Admin name** | Current admin user |
| **Last login** | Security context |
| **Logout** | Secure logout action |

### 3.2 Navigation Sidebar / Tabs
| Section | Route |
|---|---|
| **Dashboard** | `/admin/dashboard` |
| **Moderation** | `/admin/moderation` |
| **Users** | `/admin/users` (optional MVP) |
| **Hosts** | `/admin/hosts` (optional MVP) |
| **Brand Settings** | `/admin/brand` |
| **Audit Log** | `/admin/audit` (optional MVP) |

---

## 4. Dashboard Metrics Section

### 4.1 Platform Overview Cards
| Metric | Display | Data Source |
|---|---|---|
| **Total Users** | "12,450" | count(user) |
| **Active Users (7d)** | "3,240" | unique logins last 7 days |
| **Total Posts** | "8,920" | count(post) |
| **Experience Bookings** | "1,245" | count(booking_experience) |
| **Stay Requests** | "890" | count(booking_request_stay) |
| **Verified Hosts** | "156" | count(host where verified=true) |

### 4.2 Trend Indicators
| Element | Description |
|---|---|
| **Change badge** | "+12%" or "-5%" vs previous period |
| **Trend arrow** | ↑ green, ↓ red, → neutral |
| **Period** | Default: 7 days, selectable: 30d, 90d |

### 4.3 Quick Stats Row
| Stat | Value |
|---|---|
| Today's signups | 42 |
| Today's posts | 125 |
| Today's bookings | 18 |
| Today's revenue* | €2,450 (if tracked) |

---

## 5. Pending Queues Section

### 5.1 Queue Cards
| Queue | Count | Description |
|---|---|---|
| **Host Verifications** | 12 pending | Hosts awaiting approval |
| **Reported Posts** | 8 pending | Posts flagged by users |
| **Reported Hosts** | 3 pending | Hosts flagged by users |
| **Reported Reviews** | 2 pending | Reviews flagged |

### 5.2 Queue Card Actions
| Element | Description |
|---|---|
| **Count badge** | Red badge with pending count |
| **Tap action** | Navigate to moderation queue |
| **Priority indicator** | High/Medium/Low based on age |

### 5.3 Queue Priority Rules
| Age | Priority | Badge |
|---|---|---|
| < 24 hours | Normal | Gray |
| 24-72 hours | Elevated | Yellow |
| > 72 hours | Urgent | Red |

---

## 6. Quick Moderation Actions

### 6.1 Recent Items (Inline)
Show 3-5 most recent pending items with quick actions:

| Element | Description |
|---|---|
| **Item preview** | Title/username + type |
| **Created at** | Timestamp |
| **Quick actions** | Approve / Reject / Review |

### 6.2 Action Buttons
| Action | Effect | Confirmation |
|---|---|---|
| **Approve** | Mark as verified/approved | No (instant) |
| **Reject** | Mark as rejected + reason | Yes (reason required) |
| **Suspend** | Suspend user/host/content | Yes (reason required) |
| **Review** | Open full detail view | No |

### 6.3 Inline Actions Flow
```
[Approve tap]
    → Instant action
    → Toast: "Host approved"
    → Remove from queue

[Reject tap]
    → Open reason modal
    → Select/type reason
    → Confirm
    → Toast: "Host rejected"
    → Remove from queue
```

---

## 7. Brand Management Section

### 7.1 Brand Settings Card
| Element | Description |
|---|---|
| **Section title** | "Brand Settings" |
| **Current logo** | Display current app logo |
| **Current name** | Display current app name |
| **Edit button** | Open brand editor |

### 7.2 Brand Editor UI
| Field | Type | Validation |
|---|---|---|
| **App Name** | Text input | Required, 2-50 chars |
| **App Logo** | Image upload | PNG/SVG, max 2MB |
| **Preview** | Live preview | Show how it looks |
| **Save button** | Primary CTA | Validate then save |
| **Cancel** | Secondary | Discard changes |

### 7.3 Logo Upload Rules
| Rule | Value |
|---|---|
| Allowed formats | PNG, SVG |
| Max file size | 2MB |
| Recommended size | 512x512px (square) |
| Aspect ratio | 1:1 required |

### 7.4 Brand Data Model
**Table: `app_config`**
| Column | Type | Description |
|---|---|---|
| `key` | string (pk) | Config key |
| `value_json` | jsonb | Config value |
| `updated_at` | timestamp | Last update time |
| `updated_by` | uuid (fk) | Admin who updated |

**Required Keys:**
| Key | Example Value |
|---|---|
| `brand.name` | `"TravelSocial"` |
| `brand.logo_url` | `"https://storage/.../logo.png"` |
| `brand.updated_version` | `"1.0.3"` |

### 7.5 Brand Sync Flow
```
[Admin updates brand]
    ↓
[Upload new logo to storage]
    ↓
[Update app_config table]
    → brand.name = "NewName"
    → brand.logo_url = "new_url"
    → brand.updated_version = increment
    → updated_at = now()
    → updated_by = current_admin
    ↓
[Log audit event]
    ↓
[Mobile apps detect change]
    → On app launch: fetch config
    → On app resume: check version
    → If version changed: refresh config
    ↓
[UI updated across platform]
```

### 7.6 Mobile App Config Sync
| Trigger | Action |
|---|---|
| App launch | Fetch brand config |
| App resume (background → foreground) | Check config version |
| Config version changed | Refresh and apply |
| Network restored | Check for updates |

**Cache Strategy:**
| Element | TTL | Invalidation |
|---|---|---|
| Brand config | 24 hours | Version change |
| Logo image | 7 days | URL change |

### 7.7 Brand Rollback (Optional MVP)
| Element | Description |
|---|---|
| **History** | Show last 5 brand configs |
| **Rollback button** | Restore previous version |
| **Confirmation** | "Restore to [date]?" |

---

## 8. State Handling

### 8.1 Local State (UI)
| State | Type | Default |
|---|---|---|
| `metrics` | Metrics? | null |
| `queues` | QueueCounts? | null |
| `recentItems` | List<PendingItem> | [] |
| `brandConfig` | BrandConfig? | null |
| `isLoading` | bool | true |
| `isEditingBrand` | bool | false |
| `tempBrandName` | string? | null |
| `tempLogoFile` | File? | null |
| `selectedPeriod` | enum | 7d |

### 8.2 State Transitions
```
[Screen Load]
  → verify admin role (server-side)
  → fetch metrics
  → fetch queue counts
  → fetch recent pending items
  → fetch brand config
  → isLoading = false

[Period Change]
  → update selectedPeriod
  → refetch metrics with new period

[Queue Card Tap]
  → navigate to moderation queue

[Quick Action Tap]
  → execute action (with confirmation if needed)
  → update local state
  → log audit event

[Brand Edit Tap]
  → isEditingBrand = true
  → tempBrandName = brandConfig.name
  → tempLogoFile = null

[Brand Save]
  → validate inputs
  → upload logo if changed
  → update app_config
  → log audit event
  → refresh brandConfig
  → isEditingBrand = false
```

---

## 9. Agent Usage (Optional MVP)

### 9.1 AdminInsightsAgent
**When called:**
- Dashboard load (cached)

**Input:**
```json
{
  "period_days": 7
}
```

**Output:**
```json
{
  "metrics": {
    "total_users": 12450,
    "active_users_7d": 3240,
    "total_posts": 8920,
    "experience_bookings": 1245,
    "stay_requests": 890,
    "verified_hosts": 156
  },
  "trends": {
    "users_change": 0.12,
    "posts_change": 0.08,
    "bookings_change": 0.15
  },
  "confidence_level": "high",
  "cache_ttl_seconds": 3600
}
```

### 9.2 ModerationDecisionAgent
**When called:**
- Item reviewed (optional AI recommendation)

**Input:**
```json
{
  "report_id": "uuid",
  "target_type": "post|host|review",
  "reason": "spam"
}
```

**Output:**
```json
{
  "risk_score": 0.85,
  "recommended_action": "suspend",
  "confidence_level": "medium",
  "cache_ttl_seconds": 0
}
```

> **MVP Note**: Can use direct DB queries instead of agents.

---

## 10. API Calls

### 10.1 Supabase Direct (RLS)
| Endpoint | Method | Purpose |
|---|---|---|
| `user` | SELECT (count) | User metrics |
| `post` | SELECT (count) | Post metrics |
| `booking_experience` | SELECT (count) | Booking metrics |
| `host` | SELECT/UPDATE | Host verification |
| `report` | SELECT | Pending reports |
| `app_config` | SELECT/UPDATE | Brand config |

### 10.2 Edge Functions
| Function | Purpose |
|---|---|
| `get_admin_metrics` | Aggregated platform metrics |
| `get_queue_counts` | Pending queue counts |
| `moderate_item` | Execute moderation action |
| `update_brand_config` | Update brand settings |

### 10.3 Storage
| Operation | Purpose |
|---|---|
| Upload logo | New brand logo |

---

## 11. Audit Logging

### 11.1 Audit Log Table
**Table: `admin_audit_log`**
| Column | Type | Description |
|---|---|---|
| `id` | uuid | Primary key |
| `admin_id` | uuid | Admin who acted |
| `action_type` | enum | Action taken |
| `target_type` | enum | What was affected |
| `target_id` | uuid | ID of affected item |
| `old_value` | jsonb | Previous state |
| `new_value` | jsonb | New state |
| `reason` | string | Action reason |
| `created_at` | timestamp | When action occurred |

### 11.2 Action Types
| Action | Description |
|---|---|
| `approve_host` | Host verification approved |
| `reject_host` | Host verification rejected |
| `suspend_host` | Host suspended |
| `approve_content` | Post/review approved |
| `remove_content` | Post/review removed |
| `suspend_user` | User suspended |
| `ban_user` | User banned |
| `update_brand` | Brand config changed |
| `restore_brand` | Brand config rolled back |

### 11.3 Audit Entry Example
```json
{
  "id": "uuid",
  "admin_id": "admin-uuid",
  "action_type": "update_brand",
  "target_type": "app_config",
  "target_id": "brand.name",
  "old_value": { "name": "OldName" },
  "new_value": { "name": "NewName" },
  "reason": "Rebranding Q1 2026",
  "created_at": "2026-02-06T00:15:00Z"
}
```

---

## 12. Edge Cases

### 12.1 Access Control
| Condition | Behavior |
|---|---|
| Not logged in | Redirect to login |
| Logged in, not admin | Show "Access denied" |
| Admin role revoked | Kick out on next request |

### 12.2 Loading States
| Condition | Behavior |
|---|---|
| Metrics loading | Skeleton cards |
| Queues loading | Skeleton counts |
| Brand loading | Skeleton config |

### 12.3 Empty States
| Section | Empty Message |
|---|---|
| Queues | "No pending items 🎉" |
| Recent items | "All caught up!" |

### 12.4 Brand Upload Errors
| Condition | Behavior |
|---|---|
| Wrong format | "Only PNG and SVG allowed" |
| File too large | "Max file size is 2MB" |
| Wrong aspect ratio | "Logo must be square (1:1)" |
| Upload failed | Retry button + error message |

### 12.5 Concurrent Admin Actions
| Condition | Behavior |
|---|---|
| Item already moderated | Show "Already handled by [admin]" |
| Stale data | Refresh queue on action |

### 12.6 Offline
| Condition | Behavior |
|---|---|
| Viewing dashboard | Show cached (if available) + warning |
| Taking actions | Block all actions, show "Connection required" |

---

## 13. Accessibility

- All metrics have screen reader labels
- Action buttons have clear labels
- Form fields have proper labels
- Color is not sole indicator (icons + text)
- Keyboard navigation supported

---

## 14. Analytics Events (MVP)

| Event | Payload |
|---|---|
| `admin_dashboard_viewed` | `admin_id` |
| `admin_period_changed` | `admin_id`, `period` |
| `admin_queue_clicked` | `admin_id`, `queue_type` |
| `admin_action_taken` | `admin_id`, `action_type`, `target_type`, `target_id` |
| `brand_edit_started` | `admin_id` |
| `brand_updated` | `admin_id`, `changes` |
| `brand_rollback` | `admin_id`, `restored_version` |

---

## 15. Security Checklist

- [x] Admin role required (verified server-side)
- [x] All actions require authentication
- [x] All actions logged to audit table
- [x] Brand changes logged with before/after
- [x] Logo upload restricted (type, size)
- [x] No direct DB access from client
- [x] Concurrent action handling
- [x] Session validation on every request

---

## 16. Design Decisions (APPROVED)

Admin Dashboard specific:
1. **Operational UI**: Function over aesthetics
2. **Inline quick actions**: Reduce clicks for common tasks
3. **Audit everything**: Compliance and accountability
4. **Brand sync via version**: Cache-friendly invalidation
5. **No App Store icon change**: Out of scope
6. **Mobile config fetch**: On launch + resume
7. **Confirmation for destructive actions**: Prevent mistakes

---

## 17. Related Screens

| Screen | Relationship |
|---|---|
| Moderation Queue | Queue card destination |
| Host Detail Admin | Review host applications |
| Stay Detail Admin | Review reported stays |
| Audit Log | View all admin actions |
| User Management | Optional MVP |

---

## 18. Brand Config in Mobile Apps

### 18.1 Config Fetch Logic
```dart
// Pseudocode for mobile app
onAppLaunch() {
  fetchBrandConfig()
}

onAppResume() {
  checkConfigVersion()
  if (version != cachedVersion) {
    fetchBrandConfig()
  }
}

fetchBrandConfig() {
  config = await api.getAppConfig()
  cache.set('brand', config)
  applyBrandToUI(config)
}
```

### 18.2 UI Application
| Element | Source |
|---|---|
| App name in header | brand.name |
| Logo in header | brand.logo_url |
| Splash screen logo | brand.logo_url |
| Notification title | brand.name |

### 18.3 What Doesn't Change
| Element | Reason |
|---|---|
| App Store icon | Requires new app submission |
| Play Store icon | Requires new app submission |
| Package name | Hardcoded |

---

## Approval Checklist

- [ ] Purpose clear
- [ ] Routes correct
- [ ] Metrics section complete
- [ ] Queues section complete
- [ ] Brand management complete
- [ ] Sync mechanism defined
- [ ] Audit logging defined
- [ ] Edge cases covered
- [ ] Security verified

---

**Status: AWAITING APPROVAL**
