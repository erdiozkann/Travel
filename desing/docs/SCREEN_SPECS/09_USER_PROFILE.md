# SCREEN SPEC: User Profile
Screen ID: 09
Route: `/profile` (own) or `/u/:userId` (public)
Design Reference: `01_customer_core/user_profile_-_light`

---

## 1. Purpose

The User Profile screen is the **personal identity hub** showing travel history and social presence. It provides:
- Public profile view (own and others)
- User stats: posts, followers, following
- Content tabs: Posts, Saved, Plans
- Visited cities and contribution badges
- Edit profile (own profile only)
- Follow/unfollow actions (other profiles)

This screen answers: **"Who is this traveler and what have they experienced?"**

---

## 2. Entry Points

| Source | Route | Behavior |
|---|---|---|
| Bottom nav: Profile tab | `/profile` | Own profile |
| Feed post avatar tap | `/u/:userId` | Other user's profile |
| Comment author tap | `/u/:userId` | Other user's profile |
| Follower/following list tap | `/u/:userId` | Other user's profile |
| Deep link | `myapp://u/<userId>` | Direct to user profile |
| Host profile link | `/u/:userId` | If host is also a user |

---

## 3. UI Sections

### 3.1 Profile Header

#### 3.1.1 Avatar Section
| Element | Description |
|---|---|
| **Avatar** | Large circular profile photo |
| **Edit icon** | Camera icon overlay (own profile only) |
| **Tap action** | View fullscreen (others) or change (own) |

#### 3.1.2 User Info
| Element | Description |
|---|---|
| **Display name** | Bold, large text |
| **Username** | @username (smaller, gray) |
| **Bio** | Short description (max 150 chars) |
| **Location** | Home country / current city (optional) |
| **Languages** | Language badges (e.g., 🇬🇧 🇩🇪 🇹🇷) |
| **Member since** | "Joined March 2025" |

#### 3.1.3 Stats Row
| Stat | Display | Tap Action |
|---|---|---|
| **Posts** | "42 posts" | Scroll to posts tab |
| **Followers** | "1.2K followers" | Open followers list |
| **Following** | "384 following" | Open following list |

#### 3.1.4 Action Buttons
**Own Profile:**
| Button | Action |
|---|---|
| **Edit Profile** | Open edit profile modal |
| **Settings** | Navigate to `/profile/settings` |

**Other Profile:**
| Button | Action |
|---|---|
| **Follow** | Follow user (primary if not following) |
| **Following** | Unfollow option (if following) |
| **Message** | Optional MVP (can hide) |

### 3.2 Visited Cities Section
| Element | Description |
|---|---|
| **Title** | "Cities Visited" |
| **City badges** | Horizontal scroll of city icons/flags |
| **Count** | "12 cities" |
| **Tap city** | Navigate to city on map/explore |

### 3.3 Contribution Badges
| Element | Description |
|---|---|
| **Title** | "Badges" |
| **Badge icons** | Visual achievement badges |
| **Examples** | "First Post", "10 Countries", "Local Guide", "Verified Reviewer" |
| **Tap badge** | Show badge details modal |

### 3.4 Content Tabs
| Tab | Content | Visibility |
|---|---|---|
| **Posts** | User's public posts | Public |
| **Saved** | Saved places/experiences | Own profile only |
| **Plans** | Saved AI trip plans | Own profile only |

#### 3.4.1 Posts Tab (Default)
| Element | Description |
|---|---|
| **Grid view** | 3-column thumbnail grid |
| **List view toggle** | Switch to list (optional) |
| **Tap post** | Open post detail |
| **Empty state** | "No posts yet" |

#### 3.4.2 Saved Tab (Own Profile Only)
| Element | Description |
|---|---|
| **Saved items** | Places, experiences, stays |
| **Type filter** | All / Places / Experiences / Stays |
| **Tap item** | Navigate to detail page |
| **Empty state** | "Save places to see them here" |

#### 3.4.3 Plans Tab (Own Profile Only)
| Element | Description |
|---|---|
| **Saved plans** | AI-generated trip plans |
| **Plan card** | City + dates + item count |
| **Tap plan** | Open plan detail |
| **Empty state** | "Create your first trip plan" |

### 3.5 Requests Tab (Own Profile Only, Optional MVP)
| Element | Description |
|---|---|
| **Booking requests** | Sent stay requests |
| **Status badges** | Pending / Accepted / Rejected |
| **Tap request** | View request detail |

---

## 4. State Handling

### 4.1 Local State (UI)
| State | Type | Default |
|---|---|---|
| `userId` | uuid | from route or current user |
| `isOwnProfile` | bool | derived |
| `profile` | Profile? | null |
| `stats` | Stats? | null |
| `activeTab` | enum | posts |
| `posts` | List<Post> | [] |
| `savedItems` | List<SavedItem> | [] |
| `plans` | List<Plan> | [] |
| `isFollowing` | bool | false |
| `isLoading` | bool | true |

### 4.2 Cached State
| State | Source | TTL |
|---|---|---|
| `profile` | DB | 15 minutes |
| `stats` | DB (aggregated) | 5 minutes |
| `visitedCities` | ProfileInsightsAgent | 1 hour |
| `badges` | ProfileInsightsAgent | 1 hour |

### 4.3 State Transitions
```
[Screen Load]
  → determine isOwnProfile
  → fetch profile data
  → fetch stats (posts, followers, following)
  → fetch ProfileInsightsAgent data (cities, badges)
  → fetch initial tab content (posts)
  → isLoading = false

[Tab Change]
  → update activeTab
  → fetch tab content if not cached
  → if Saved/Plans on other profile → show "Private"

[Follow Tap]
  → optimistic update isFollowing
  → call API (background)
  → update stats count

[Edit Profile Tap]
  → open edit modal

[Post Tap]
  → navigate to post detail

[Saved Item Tap]
  → navigate to detail page

[Plan Tap]
  → navigate to plan detail
```

---

## 5. User Inputs

| Input | Action | Auth Required |
|---|---|---|
| Tap avatar (own) | Change photo | Yes |
| Tap avatar (other) | View fullscreen | No |
| Tap "Edit Profile" | Open edit modal | Yes (own) |
| Tap "Settings" | Go to settings | Yes (own) |
| Tap "Follow" | Follow user | Yes |
| Tap "Following" | Unfollow option | Yes |
| Tap followers count | Open followers list | No |
| Tap following count | Open following list | No |
| Tap visited city | Go to city explore | No |
| Tap badge | Show badge detail | No |
| Switch tab | Change content view | No |
| Tap post | Go to post detail | No |
| Tap saved item | Go to detail page | Yes (own) |
| Tap plan | Go to plan detail | Yes (own) |
| Pull to refresh | Refresh profile | No |

---

## 6. Data Outputs

### 6.1 Read Operations
| Data | Source | RLS |
|---|---|---|
| Profile | `profile` table | Public read |
| Posts | `post` table (is_public=true) | Public read |
| Stats | Aggregated counts | Public read |
| Followers/Following | `follow` table | Public read |
| Saved items | `saved_items` table | Owner read only |
| Plans | `user_plans` table | Owner read only |
| Visited cities | ProfileInsightsAgent | - |
| Badges | ProfileInsightsAgent | - |

### 6.2 Write Operations
| Data | Table | RLS |
|---|---|---|
| Follow/Unfollow | `follow` | Owner write |
| Update profile | `profile` | Owner write |
| Update avatar | Supabase Storage | Owner write |

---

## 7. Agent Usage

### 7.1 ProfileInsightsAgent
**When called:**
- Profile load (own or other)

**Input:**
```json
{
  "user_id": "uuid"
}
```

**Output:**
```json
{
  "visited_cities": [
    { "city_id": "uuid", "city_name": "Barcelona", "visit_count": 3 },
    { "city_id": "uuid", "city_name": "Paris", "visit_count": 1 }
  ],
  "badges": [
    { "id": "first_post", "name": "First Post", "earned_at": "2025-03-15" },
    { "id": "10_countries", "name": "10 Countries", "earned_at": "2025-06-20" },
    { "id": "verified_reviewer", "name": "Verified Reviewer", "earned_at": "2025-08-10" }
  ],
  "stats": {
    "total_posts": 42,
    "total_cities": 12,
    "total_countries": 8,
    "total_bookings": 15
  },
  "confidence_level": "high",
  "cache_ttl_seconds": 3600
}
```

---

## 8. Edit Profile Modal

### 8.1 UI Elements
| Field | Type | Validation |
|---|---|---|
| **Avatar** | Image picker | Max 5MB, JPEG/PNG |
| **Display name** | Text input | Required, 2-50 chars |
| **Bio** | Text area | Optional, max 150 chars |
| **Home country** | Country picker | Optional |
| **Languages** | Multi-select | Optional |
| **Save button** | Primary CTA | Validate before save |
| **Cancel** | Secondary | Discard changes |

### 8.2 Edit Flow
```
[Tap Edit Profile]
    ↓
[Open modal with current values]
    ↓
[User makes changes]
    ↓
[Tap Save]
    → Validate fields
    → Upload new avatar (if changed)
    → Update profile record
    → Close modal, refresh profile
```

---

## 9. API Calls

### 9.1 Supabase Direct (RLS)
| Endpoint | Method | Purpose |
|---|---|---|
| `profile` | SELECT | Fetch profile data |
| `profile` | UPDATE | Update profile (own) |
| `post` | SELECT | Fetch user's posts |
| `follow` | SELECT | Check follow status |
| `follow` | INSERT/DELETE | Follow/unfollow |
| `saved_items` | SELECT | Fetch saved items (own) |
| `user_plans` | SELECT | Fetch saved plans (own) |

### 9.2 Edge Functions
| Function | Purpose |
|---|---|
| `get_profile_insights` | Trigger ProfileInsightsAgent |
| `get_user_stats` | Aggregated counts |

### 9.3 Storage
| Operation | Purpose |
|---|---|
| Upload avatar | Update profile photo |

---

## 10. Badge System (MVP)

### 10.1 Available Badges
| Badge ID | Name | Criteria |
|---|---|---|
| `first_post` | First Post | Create first post |
| `first_booking` | First Booking | Complete first experience booking |
| `verified_reviewer` | Verified Reviewer | 5+ verified reviews |
| `explorer` | Explorer | Visit 5+ cities |
| `globetrotter` | Globetrotter | Visit 10+ countries |
| `local_guide` | Local Guide | 10+ posts in one city |
| `influencer` | Influencer | 1000+ followers |

### 10.2 Badge Calculation
- Calculated by ProfileInsightsAgent
- Updated on relevant actions (post, booking, review)
- Cached for 1 hour

---

## 11. Edge Cases

### 11.1 Profile Not Found
| Condition | Behavior |
|---|---|
| Invalid user ID | Show error: "User not found" + back |
| Deleted account | Show: "This account no longer exists" |

### 11.2 Private Content
| Condition | Behavior |
|---|---|
| Saved tab (other) | Hide tab or show "Private" |
| Plans tab (other) | Hide tab or show "Private" |
| Requests tab (other) | Hide completely |

### 11.3 Loading States
| Condition | Behavior |
|---|---|
| Profile loading | Skeleton header + tabs |
| Posts loading | Grid skeleton |
| Stats loading | Placeholder numbers |

### 11.4 Empty States
| Tab | Empty Message |
|---|---|
| Posts | "No posts yet. Share your first adventure!" (own) |
| Posts (other) | "No posts yet" |
| Saved | "Save places to see them here" |
| Plans | "Create your first trip plan" |

### 11.5 Offline
| Condition | Behavior |
|---|---|
| Cached profile | Show cached + "Offline" banner |
| No cache | Show error: "No connection" |
| Follow action offline | Queue + sync when online |

### 11.6 Blocked Users
| Condition | Behavior |
|---|---|
| Blocked by user | "You cannot view this profile" |
| User blocked by me | Option to unblock |

---

## 12. Accessibility

- Avatar has alt text with username
- Stats are screen reader friendly ("42 posts")
- Tab navigation is keyboard accessible
- Follow button announces state change
- Grid items have accessible labels

---

## 13. Analytics Events (MVP)

| Event | Payload |
|---|---|
| `profile_viewed` | `user_id`, `is_own`, `source` |
| `profile_tab_switched` | `user_id`, `tab` |
| `profile_follow_tapped` | `target_user_id`, `action` (follow/unfollow) |
| `profile_post_tapped` | `post_id`, `user_id` |
| `profile_city_tapped` | `city_id`, `user_id` |
| `profile_badge_tapped` | `badge_id`, `user_id` |
| `profile_edit_opened` | - |
| `profile_edit_saved` | `fields_changed` |
| `followers_list_opened` | `user_id` |
| `following_list_opened` | `user_id` |

---

## 14. Security Checklist

- [x] Profile data is public read (RLS)
- [x] Saved items are owner-only (RLS)
- [x] Plans are owner-only (RLS)
- [x] Profile edit requires authentication + ownership
- [x] Follow requires authentication
- [x] Avatar upload size limited
- [x] Bio sanitized (no scripts)
- [x] Block/mute system respected

---

## 15. Design Decisions (APPROVED)

Profile-specific:
1. **Single view for own + other**: Same layout, different actions
2. **Tabs for content**: Clean organization
3. **Private tabs hidden**: Saved/Plans not visible to others
4. **Grid view for posts**: Instagram-style, space efficient
5. **Horizontal city badges**: Scannable at a glance
6. **Modal for edit**: Keep user on same screen
7. **Stats always visible**: Social proof

---

## 16. Related Screens

| Screen | Relationship |
|---|---|
| Community Feed | Tap avatar → profile |
| Post Detail | Tap author → profile |
| Followers/Following List | Tap stats → lists |
| Settings | Tap settings icon |
| Edit Profile Modal | Tap edit button |
| Experience/Stay Detail | Tap saved item |
| AI Trip Planner | Tap saved plan |

---

## 17. Own vs Other Profile Comparison

| Element | Own Profile | Other Profile |
|---|---|---|
| Avatar | Editable | View only |
| Edit button | ✅ Visible | ❌ Hidden |
| Settings button | ✅ Visible | ❌ Hidden |
| Follow button | ❌ Hidden | ✅ Visible |
| Posts tab | ✅ Visible | ✅ Visible |
| Saved tab | ✅ Visible | ❌ Hidden |
| Plans tab | ✅ Visible | ❌ Hidden |
| Requests tab | ✅ Visible (optional) | ❌ Hidden |

---

## Approval Checklist

- [ ] Purpose clear
- [ ] Routes correct (own + public)
- [ ] UI sections complete
- [ ] Tab system defined
- [ ] Own vs other logic clear
- [ ] Agent usage defined
- [ ] Edge cases covered
- [ ] Security verified

---

**Status: AWAITING APPROVAL**
