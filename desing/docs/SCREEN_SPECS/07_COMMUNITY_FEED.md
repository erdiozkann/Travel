# SCREEN SPEC: Community Feed
Screen ID: 07
Route: `/feed`
Design Reference: `01_customer_core/community_feed_-_light`

---

## 1. Purpose

The Community Feed is the **social discovery hub** where users share and discover real travel experiences. It provides:
- Instagram-style vertical scrolling feed
- Mixed content: organic user posts + sponsored posts
- Place tagging for discovery (city, place, experience, stay)
- Social actions: like, comment, save, follow
- Retention-driving engagement loop

This screen answers: **"What are others experiencing in this city?"**

> **Core Value**: Real experiences from real travelers → trust + discovery.

---

## 2. Entry Points

| Source | Route | Behavior |
|---|---|---|
| Bottom nav: Feed tab | `/feed` | Load personalized feed |
| Deep link | `myapp://feed` | Open feed |
| Post deep link | `myapp://feed/post/<id>` | Open specific post |
| User profile tap | `/feed` (filtered) | Optional: show user's posts |
| Notification tap | `/feed/post/:id` | Open liked/commented post |

---

## 3. UI Sections

### 3.1 Header
| Element | Description |
|---|---|
| **App logo/title** | "Community" or app branding |
| **Create button** | "+ Create" → `/feed/create` |
| **Notifications icon** | Bell icon (optional MVP) |

### 3.2 Feed Tab Bar (Optional MVP)
| Tab | Description |
|---|---|
| **For You** | Personalized feed (default) |
| **Following** | Posts from followed users only |
| **Nearby** | Posts from current city (if location enabled) |

### 3.3 Post Card (Primary Unit)
Full-width card, optimized for vertical scroll.

#### 3.3.1 Post Header
| Element | Description |
|---|---|
| **Avatar** | User profile photo |
| **Username** | Tap → user profile |
| **Timestamp** | "2 hours ago" |
| **Location tag** | City badge (tap → map/explore) |
| **More menu** | "..." → Report / Hide / Copy link |

#### 3.3.2 Post Media
| Type | Description |
|---|---|
| **Photo** | Single image, full-width, tap to zoom |
| **Video** | Auto-play muted, tap to unmute/fullscreen |
| **Carousel** | Swipeable images, pagination dots |

#### 3.3.3 Post Actions Bar
| Element | Description |
|---|---|
| **Like** | ❤️ Heart icon (toggle) + count |
| **Comment** | 💬 Comment icon + count → open comments |
| **Save** | 🔖 Bookmark icon (toggle) |
| **Share** | ↗️ Share icon → share sheet |

#### 3.3.4 Tagged Entity (If Present)
| Element | Description |
|---|---|
| **Tag chip** | "📍 La Boqueria" or "🎯 Gothic Quarter Tour" |
| **Tap action** | Navigate to place/experience/stay detail |
| **Tag types** | place, experience, stay |

#### 3.3.5 Caption
| Element | Description |
|---|---|
| **Text** | User caption (expandable if long) |
| **Hashtags** | Clickable (optional MVP) |
| **"Read more"** | Expand truncated text |

#### 3.3.6 Comments Preview
| Element | Description |
|---|---|
| **Preview** | 1-2 recent comments inline |
| **View all** | "View all 24 comments" → open comment sheet |

### 3.4 Sponsored Post Card
Same structure as user post, with additions:

| Element | Description |
|---|---|
| **Sponsored badge** | "Sponsored" label (always visible, top-right or header) |
| **Sponsor info** | Business/brand name |
| **CTA button** | "Learn More" / "Book Now" → internal navigation only |

> **Rule**: Sponsored content always labeled. Max 20-30% of feed.

### 3.5 Create Post FAB (Alternative)
| Element | Description |
|---|---|
| **FAB** | Floating action button bottom-right |
| **Tap** | Navigate to `/feed/create` |

### 3.6 Empty State (New User)
| Element | Description |
|---|---|
| **Illustration** | Social/travel graphic |
| **Title** | "Your feed is empty" |
| **Subtitle** | "Follow travelers or explore the community" |
| **CTAs** | "Explore" / "Find people to follow" |

---

## 4. Feed Item Structure (Data Model)

```json
{
  "id": "uuid",
  "type": "post",
  "user": {
    "id": "uuid",
    "username": "maria_travels",
    "avatar_url": "...",
    "is_verified": false
  },
  "media": [
    { "type": "image", "url": "..." },
    { "type": "video", "url": "...", "thumbnail_url": "..." }
  ],
  "caption": "Amazing experience at La Boqueria!",
  "tagged_entity": {
    "type": "place",
    "id": "uuid",
    "name": "La Boqueria",
    "city": "Barcelona"
  },
  "location": {
    "city_id": "uuid",
    "city_name": "Barcelona"
  },
  "stats": {
    "likes": 124,
    "comments": 18,
    "saves": 42
  },
  "user_interaction": {
    "liked": false,
    "saved": false
  },
  "created_at": "2026-02-05T10:30:00Z",
  "is_sponsored": false
}
```

**Sponsored Post Extension:**
```json
{
  "is_sponsored": true,
  "sponsor": {
    "name": "Barcelona Food Tours",
    "logo_url": "...",
    "cta_text": "Book Now",
    "cta_target": "/explore/experience/uuid"
  }
}
```

---

## 5. State Handling

### 5.1 Local State (UI)
| State | Type | Default |
|---|---|---|
| `feedType` | enum | for_you |
| `posts` | List<Post> | [] |
| `cursor` | string? | null |
| `hasMore` | bool | true |
| `isLoading` | bool | true |
| `isRefreshing` | bool | false |
| `likedPosts` | Set<uuid> | {} |
| `savedPosts` | Set<uuid> | {} |
| `mutedUsers` | Set<uuid> | {} |

### 5.2 Cached State
| State | Source | TTL |
|---|---|---|
| `rankingData` | FeedRankingAgent | 5 minutes |
| `sponsoredSlots` | AdsEligibilityAgent | 10 minutes |
| `posts (offline)` | Local storage | Until refresh |

### 5.3 State Transitions
```
[Screen Load]
  → fetch initial feed (page 1)
  → apply FeedRankingAgent results
  → inject sponsored posts at intervals
  → isLoading = false

[Scroll to Bottom]
  → if hasMore → fetch next page (cursor-based)
  → append to posts

[Pull to Refresh]
  → isRefreshing = true
  → fetch fresh feed (page 1)
  → replace posts
  → isRefreshing = false

[Like Toggle]
  → optimistic update UI (immediate)
  → call API (background)
  → on error → revert

[Comment Tap]
  → open comment bottom sheet

[Post Tap]
  → navigate to post detail (fullscreen)

[Tagged Entity Tap]
  → navigate to place/experience/stay detail

[User Avatar Tap]
  → navigate to user profile

[Feed Tab Change]
  → reset posts
  → fetch new feed with different filter
```

---

## 6. User Inputs

| Input | Action | Auth Required |
|---|---|---|
| Scroll | Load more posts | No |
| Pull down | Refresh feed | No |
| Tap like | Toggle like | Yes |
| Tap comment | Open comment sheet | No (view), Yes (post) |
| Tap save | Toggle bookmark | Yes |
| Tap share | Open share sheet | No |
| Tap avatar | Go to user profile | No |
| Tap username | Go to user profile | No |
| Tap location | Go to city on map | No |
| Tap tagged entity | Go to detail page | No |
| Tap "Read more" | Expand caption | No |
| Tap media | Zoom/fullscreen | No |
| Tap "Create" | Go to create post | Yes |
| Tap sponsored CTA | Go to internal page | No |
| Tap "..." menu | Report/Hide options | No (report needs auth) |

---

## 7. Data Outputs

### 7.1 Read Operations
| Data | Source | RLS |
|---|---|---|
| Feed posts | `post` table | Public read (is_public=true) |
| User profiles | `profile` table | Public read |
| Like/save status | `like`, `saved_items` tables | Owner read |
| Comments | `comment` table | Public read |
| Ranked feed | FeedRankingAgent cache | - |

### 7.2 Write Operations
| Data | Table | RLS |
|---|---|---|
| Like | `like` | Owner write |
| Save | `saved_items` | Owner write |
| Comment | `comment` | Owner write |
| Report | `report` | Owner write |

---

## 8. Agent Usage

### 8.1 FeedRankingAgent
**When called:**
- Feed load (initial + refresh)
- Tab change (For You / Following / Nearby)

**Input (from AGENT_CONTRACTS.md):**
```json
{
  "user_id": "uuid",
  "limit": 20,
  "cursor": "string"
}
```

**Output:**
```json
{
  "posts": [
    {
      "post_id": "uuid",
      "rank_score": 0.92,
      "is_sponsored": false
    },
    {
      "post_id": "uuid",
      "rank_score": 0.85,
      "is_sponsored": true
    }
  ],
  "next_cursor": "abc123",
  "confidence_level": "high",
  "cache_ttl_seconds": 300
}
```

**Ranking Factors:**
- Followings (posts from followed users boosted)
- Interests (matching user's travel interests)
- Recency (newer posts prioritized)
- Engagement (high-engagement posts boosted)
- Location (nearby city posts if location enabled)

### 8.2 AdsEligibilityAgent
**When called:**
- Feed load (to determine sponsored slots)

**Input:**
```json
{
  "user_id": "uuid",
  "city_id": "uuid",
  "feed_size": 20
}
```

**Output:**
```json
{
  "sponsored_slots": [2, 7, 15],
  "max_sponsored_ratio": 0.25,
  "eligible_ads": [
    {
      "ad_id": "uuid",
      "target_type": "experience",
      "target_id": "uuid",
      "rating_threshold_met": true,
      "review_threshold_met": true
    }
  ],
  "confidence_level": "high",
  "cache_ttl_seconds": 600
}
```

> **Rule**: Sponsored = only if 4.0+ rating AND 10+ verified reviews (GUARDRAILS.md)

---

## 9. API Calls

### 9.1 Supabase Direct (RLS)
| Endpoint | Method | Purpose |
|---|---|---|
| `post` | SELECT | Fetch posts (paginated) |
| `profile` | SELECT | User info for posts |
| `like` | SELECT/INSERT/DELETE | Like status and toggle |
| `saved_items` | SELECT/INSERT/DELETE | Save status and toggle |
| `comment` | SELECT | Fetch comments |
| `report` | INSERT | Report content |

### 9.2 Edge Functions
| Function | Purpose |
|---|---|
| `get_ranked_feed` | Trigger FeedRankingAgent, return sorted posts |
| `get_sponsored_posts` | Trigger AdsEligibilityAgent, return eligible ads |

### 9.3 Realtime Subscriptions (Optional MVP)
| Channel | Purpose |
|---|---|
| `likes:post_id` | Live like count updates |
| `comments:post_id` | Live comment count updates |

---

## 10. Sponsored Content Rules (Mandatory)

### 10.1 Visibility
| Rule | Implementation |
|---|---|
| Always labeled | "Sponsored" badge on every sponsored post |
| Clear distinction | Visual separator or badge color |
| No deceptive styling | Cannot mimic organic posts completely |

### 10.2 Eligibility
| Requirement | Threshold |
|---|---|
| Minimum rating | 4.0+ stars |
| Minimum reviews | 10+ verified reviews |
| Content quality | Approved by admin |

### 10.3 Frequency
| Rule | Implementation |
|---|---|
| Max ratio | 20-30% of feed |
| Spacing | At least 3 organic posts between sponsored |
| First post | Never sponsored (position 0) |

### 10.4 CTA Behavior
| Rule | Implementation |
|---|---|
| Internal only | All CTAs navigate within app |
| No external links | Never open browser |
| Trackable | CTA taps logged for analytics |

---

## 11. Edge Cases

### 11.1 Empty Feed
| Condition | Behavior |
|---|---|
| New user, no follows | Show "Explore" CTA + suggested users |
| Following tab, no follows | "Follow travelers to see their posts" |
| Nearby tab, no location | Prompt location permission |

### 11.2 Loading States
| Condition | Behavior |
|---|---|
| Initial load | Skeleton post cards (3-4) |
| Loading more | Spinner at bottom |
| Refreshing | Pull-to-refresh indicator |

### 11.3 Errors
| Condition | Behavior |
|---|---|
| Network error | Show error banner + retry button |
| Post deleted | "This post is no longer available" |
| User blocked | Filter out from feed |

### 11.4 Offline
| Condition | Behavior |
|---|---|
| Cached feed | Show cached posts + "Offline" banner |
| No cache | Show error: "No connection" |
| Like/save offline | Queue action, sync when online |

### 11.5 Content Moderation
| Condition | Behavior |
|---|---|
| Reported post | Hide after threshold (admin review) |
| NSFW content | ContentSafetyAgent flags → admin review |
| Spam detected | Auto-hide + admin review |

### 11.6 Rate Limiting
| Condition | Behavior |
|---|---|
| Too many likes | "Slow down" message + cooldown |
| Too many comments | Same as above |

---

## 12. Accessibility

- All images have alt text (AI-generated or from caption)
- Videos have mute/unmute and closed captions (if available)
- Like/save buttons have toggle announcements
- Scroll position saved and restored
- Screen reader announces post author and content

---

## 13. Analytics Events (MVP)

| Event | Payload |
|---|---|
| `feed_loaded` | `feed_type`, `post_count`, `sponsored_count` |
| `feed_scrolled` | `posts_viewed`, `scroll_depth` |
| `post_viewed` | `post_id`, `is_sponsored`, `position` |
| `post_liked` | `post_id`, `is_sponsored` |
| `post_saved` | `post_id` |
| `post_shared` | `post_id`, `share_method` |
| `post_reported` | `post_id`, `reason` |
| `comment_opened` | `post_id`, `comment_count` |
| `tagged_entity_tapped` | `post_id`, `entity_type`, `entity_id` |
| `user_profile_tapped` | `post_id`, `user_id` |
| `sponsored_cta_tapped` | `ad_id`, `target_type`, `target_id` |
| `create_post_tapped` | `source` |

---

## 14. Security & Moderation Checklist

- [x] Posts filtered to public only (RLS)
- [x] Like/save/comment require authentication
- [x] Report system for bad content
- [x] ContentSafetyAgent pre-screens posts (on creation)
- [x] Sponsored content clearly labeled
- [x] No external links (internal navigation only)
- [x] Rate limiting on social actions
- [x] Blocked/muted users hidden
- [x] Admin moderation queue for flagged content

---

## 15. Design Decisions (APPROVED)

Feed-specific:
1. **Full-width post cards**: Instagram-style immersive experience
2. **Video auto-play muted**: Modern social UX, user controls unmute
3. **Inline comment preview**: Reduce taps, increase engagement
4. **FAB for create**: Always accessible, doesn't clutter header
5. **Tab bar optional MVP**: "For You" as single feed initially
6. **Sponsored max 20-30%**: Trust over revenue
7. **No external links**: Keep users in app

---

## 16. Related Screens

| Screen | Relationship |
|---|---|
| Create Post | "+ Create" action destination |
| User Profile | Tap avatar/username |
| Post Detail | Tap post (optional fullscreen) |
| Comment Sheet | Tap comment icon |
| Place/Experience/Stay Detail | Tap tagged entity |
| Map View | Tap location badge |
| Report Modal | Tap "..." → Report |

---

## 17. Feed Types Comparison

| Feed Type | Filter | Use Case |
|---|---|---|
| **For You** | Personalized ranking | Default discovery |
| **Following** | Only followed users | Close connections |
| **Nearby** | Current city only | Local discovery |

---

## Approval Checklist

- [ ] Purpose clear
- [ ] Post card structure complete
- [ ] Sponsored rules defined
- [ ] Ranking factors documented
- [ ] Agent contracts matched
- [ ] Moderation rules included
- [ ] Edge cases covered
- [ ] Internal navigation only (confirmed)

---

**Status: AWAITING APPROVAL**
