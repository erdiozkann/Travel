# SCREEN SPEC: Create Post
Screen ID: 08
Route: `/feed/create`
Design Reference: `01_customer_core/create_post_-_light`

---

## 1. Purpose

The Create Post screen is the **content creation flow** for sharing travel experiences. It provides:
- Photo/video/carousel upload
- Place tagging (city, place, experience, stay)
- Caption with hashtag support
- Check-in with event-based location
- Content safety pre-check before publish
- Preview before final submission

This screen answers: **"How do I share my experience?"**

> **Privacy Rule**: Location is event-based. Captured once at post creation, never tracked.

---

## 2. Entry Points

| Source | Route | Behavior |
|---|---|---|
| Feed header "+" button | `/feed/create` | Full-screen create flow |
| Feed FAB | `/feed/create` | Same as above |
| Profile "+" button | `/feed/create` | Same |
| Deep link | Not applicable | Must enter through app |
| Experience/Stay detail | `/feed/create?tag=<type>:<id>` | Pre-fill tagged entity |

**Prerequisites:**
- User must be authenticated
- Camera/gallery permissions for media

---

## 3. UI Sections

### 3.1 Header
| Element | Description |
|---|---|
| **Close button** | "×" → discard confirmation if content exists |
| **Title** | "New Post" |
| **Next/Post button** | "Next" (to preview) or "Post" (final submit) |

### 3.2 Media Section (Step 1)

#### 3.2.1 Media Picker
| Element | Description |
|---|---|
| **Camera button** | Open camera for photo/video |
| **Gallery button** | Open device gallery |
| **Selected media** | Grid preview of selected items |
| **Reorder** | Drag to reorder (carousel) |
| **Remove** | "×" on each item to remove |

#### 3.2.2 Media Rules
| Rule | Limit |
|---|---|
| **Max items** | 10 images/videos per post |
| **Max video duration** | 60 seconds (MVP) |
| **Image format** | JPEG, PNG, HEIC |
| **Video format** | MP4, MOV |
| **Max file size** | 50MB per item |
| **Aspect ratio** | 1:1, 4:5, 16:9 supported |

#### 3.2.3 Media Preview
| Element | Description |
|---|---|
| **Thumbnail grid** | Selected media in order |
| **First = cover** | First item is post cover |
| **Edit (optional MVP)** | Crop/filter (can skip in MVP) |

### 3.3 Caption Section (Step 2)

#### 3.3.1 Caption Input
| Element | Description |
|---|---|
| **Text area** | Multiline input |
| **Placeholder** | "Tell your story..." |
| **Character limit** | 2000 characters |
| **Hashtag support** | Auto-detect #tags (highlight) |
| **@ mentions** | Optional MVP (auto-complete users) |

#### 3.3.2 Character Counter
| Element | Description |
|---|---|
| **Counter** | "142 / 2000" |
| **Warning** | Turn red when near limit |

### 3.4 Location Section

#### 3.4.1 Add Location
| Element | Description |
|---|---|
| **Location chip** | "📍 Add location" (tap to add) |
| **Current location** | Request device location (event-based) |
| **Manual search** | Search for city/place |
| **Selected** | "📍 Barcelona" badge |

#### 3.4.2 Location Rules
| Rule | Implementation |
|---|---|
| Event-based only | Captured once, never updated |
| Optional | User can skip |
| City-level default | Can be more specific |

### 3.5 Tag Section

#### 3.5.1 Tag Entity
| Element | Description |
|---|---|
| **Tag chip** | "🏷️ Tag a place or experience" |
| **Search** | Search for place/experience/stay |
| **Suggestions** | Nearby entities (via PlaceTagAgent) |
| **Selected** | "🏷️ Gothic Quarter Tour" badge |
| **Remove** | "×" to remove tag |

#### 3.5.2 Tag Types
| Type | Icon | Example |
|---|---|---|
| `place` | 📍 | La Boqueria |
| `experience` | 🎯 | Gothic Quarter Tour |
| `stay` | 🏠 | Sunny Apartment |

### 3.6 Check-in Toggle (Optional)

| Element | Description |
|---|---|
| **Toggle** | "Include check-in" switch |
| **Effect** | Creates `checkin` record with lat/lng |
| **Privacy note** | "Your exact location will be shared" |

### 3.7 Visibility Setting

| Element | Description |
|---|---|
| **Toggle/selector** | "Public" / "Followers only" (MVP: public only) |
| **Default** | Public |

### 3.8 Preview Section (Before Publish)

| Element | Description |
|---|---|
| **Full preview** | How post will look in feed |
| **Media carousel** | Swipeable preview |
| **Caption preview** | Full text |
| **Tags preview** | Location + entity tag |

### 3.9 Submit Section

| Element | Description |
|---|---|
| **Post button** | **"Share"** (primary, full-width) |
| **Save draft** | "Save as Draft" (optional MVP) |
| **Loading** | Spinner during upload + safety check |

---

## 4. Multi-Step Flow

### 4.1 Flow Diagram
```
[Open Create] → Step 1: Select Media
    ↓
[Media selected] → Step 2: Add Details
    Caption + Location + Tags
    ↓
[Tap "Next"] → Step 3: Preview
    Review before publish
    ↓
[Tap "Share"] → Processing
    Upload media + Safety check
    ↓
[Success] → Return to Feed (new post shown)
```

### 4.2 Alternative: Single-Page Flow (MVP)
For simpler MVP, all sections on one scrollable page:
```
[Open Create]
    Media picker
    Caption input
    Location/Tag section
    [Share button]
    ↓
[Processing] → [Success] → [Feed]
```

---

## 5. State Handling

### 5.1 Local State (UI)
| State | Type | Default |
|---|---|---|
| `selectedMedia` | List<MediaFile> | [] |
| `caption` | string | "" |
| `location` | Location? | null |
| `taggedEntity` | TaggedEntity? | null (or from deep link) |
| `includeCheckin` | bool | false |
| `isPublic` | bool | true |
| `currentStep` | int | 1 |
| `isUploading` | bool | false |
| `uploadProgress` | float | 0.0 |
| `safetyCheckPassed` | bool? | null |

### 5.2 Derived State
| State | Calculation |
|---|---|
| `canSubmit` | selectedMedia.length > 0 |
| `hasUnsavedChanges` | any field modified |

### 5.3 State Transitions
```
[Screen Load]
  → check for pre-filled tag (from deep link)
  → show media picker

[Media Selected]
  → add to selectedMedia
  → enable "Next" button

[Caption Change]
  → update caption
  → detect hashtags

[Location Tap]
  → request device location (if permitted)
  → show location search modal

[Tag Tap]
  → call PlaceTagAgent for suggestions
  → show tag search modal

[Submit Tap]
  → validate (has media)
  → isUploading = true
  → upload media to storage
  → call ContentSafetyAgent
  → if safe → create post record
  → on success → navigate to Feed
  → on error → show error, keep form

[Close Tap]
  → if hasUnsavedChanges → confirm discard
  → else → close
```

---

## 6. User Inputs

| Input | Action | Validation |
|---|---|---|
| Tap camera | Open camera | Permission required |
| Tap gallery | Open gallery picker | Permission required |
| Select media | Add to list | Max 10 items |
| Drag media | Reorder | - |
| Tap "×" on media | Remove from list | - |
| Type caption | Update text | Max 2000 chars |
| Tap location | Open location picker | - |
| Tap tag | Open tag search | - |
| Toggle check-in | Set includeCheckin | - |
| Tap "Next" | Go to preview | - |
| Tap "Share" | Submit post | Must have media |
| Tap "×" close | Discard/close | Confirm if unsaved |

---

## 7. Data Outputs

### 7.1 Read Operations
| Data | Source | RLS |
|---|---|---|
| Nearby places | PlaceTagAgent | - |
| City list | `city` table | Public read |
| Search results | `place`, `experience`, `stay` tables | Public read |

### 7.2 Write Operations
| Data | Table | RLS |
|---|---|---|
| Post | `post` | Owner write |
| Check-in | `checkin` | Owner write |
| Media files | Supabase Storage | Owner write |

**Created Post Record:**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "city_id": "uuid",
  "caption": "Amazing experience at La Boqueria! #barcelona #food",
  "media_urls": ["https://storage/.../1.jpg", "https://storage/.../2.jpg"],
  "tagged_type": "place",
  "tagged_id": "uuid",
  "is_public": true,
  "created_at": "timestamp"
}
```

**Created Check-in Record (if enabled):**
```json
{
  "id": "uuid",
  "post_id": "uuid",
  "lat": 41.3818,
  "lng": 2.1719,
  "place_name": "La Boqueria",
  "created_at": "timestamp"
}
```

---

## 8. Agent Usage

### 8.1 ContentSafetyAgent
**When called:**
- Before post is published (blocking)

**Input (from AGENT_CONTRACTS.md):**
```json
{
  "post_id": "uuid",
  "caption": "Amazing experience...",
  "media_urls": ["https://storage/.../1.jpg"]
}
```

**Output:**
```json
{
  "safe": true,
  "flags": [],
  "recommended_action": "allow",
  "confidence_level": "high",
  "cache_ttl_seconds": 0
}
```

**Flags (if not safe):**
- `spam`
- `nudity`
- `hate`
- `scam`
- `other`

**Actions:**
| Result | Behavior |
|---|---|
| `allow` | Publish immediately |
| `review` | Publish but flag for admin review |
| `remove` | Block publish, show error to user |

### 8.2 PlaceTagAgent
**When called:**
- When user taps "Tag" section
- On location permission granted

**Input:**
```json
{
  "lat": 41.3818,
  "lng": 2.1719,
  "radius_km": 1
}
```

**Output:**
```json
{
  "suggestions": [
    {
      "type": "place",
      "id": "uuid",
      "name": "La Boqueria",
      "distance_m": 120
    },
    {
      "type": "experience",
      "id": "uuid",
      "name": "Food Market Tour",
      "distance_m": 150
    }
  ],
  "confidence_level": "high"
}
```

---

## 9. API Calls

### 9.1 Supabase Storage
| Operation | Purpose |
|---|---|
| Upload | Upload media files to bucket |
| Get URL | Generate public URL for media |

### 9.2 Supabase Direct (RLS)
| Endpoint | Method | Purpose |
|---|---|---|
| `post` | INSERT | Create post record |
| `checkin` | INSERT | Create check-in record |
| `city`, `place`, `experience`, `stay` | SELECT | Search for tags |

### 9.3 Edge Functions
| Function | Purpose |
|---|---|
| `check_content_safety` | Trigger ContentSafetyAgent |
| `get_nearby_places` | Trigger PlaceTagAgent |

---

## 10. Media Handling Rules

### 10.1 Upload Flow
```
[User selects media]
    ↓
[Client compresses (if needed)]
    ↓
[Upload to Supabase Storage]
    → Show progress bar
    ↓
[Get public URLs]
    ↓
[Submit post with URLs]
```

### 10.2 Compression Rules
| Media | Rule |
|---|---|
| Images | Resize to max 2048px, quality 85% |
| Videos | Compress to 720p if larger |
| Thumbnails | Generate 300px thumbnail |

### 10.3 Error Handling
| Error | Behavior |
|---|---|
| Upload failed | Retry button + error message |
| File too large | Show size limit, block upload |
| Unsupported format | Show format requirements |
| Network lost | Pause upload, resume when connected |

---

## 11. Edge Cases

### 11.1 Permissions
| Condition | Behavior |
|---|---|
| Camera denied | Show settings prompt |
| Gallery denied | Show settings prompt |
| Location denied | Allow post without location |

### 11.2 Media Issues
| Condition | Behavior |
|---|---|
| No media selected | Disable "Share" button |
| > 10 items | Show "Max 10 items" message |
| Corrupt file | Skip + notify user |
| Upload timeout | Retry with exponential backoff |

### 11.3 Content Safety Failure
| Condition | Behavior |
|---|---|
| Flagged as unsafe | Block publish: "Content doesn't meet guidelines" |
| Flagged for review | Publish with warning: "Post is under review" |
| Agent timeout | Allow publish (fail-open) + queue review |

### 11.4 Navigation
| Condition | Behavior |
|---|---|
| Back with unsaved | Show confirmation modal |
| App backgrounded | Preserve state |
| App killed | Lose unsaved (MVP), draft in v2 |

### 11.5 Duplicate Post
| Condition | Behavior |
|---|---|
| Same media uploaded | Allow (user choice) |
| Exact duplicate post | Block + show "Already posted" |

### 11.6 Offline
| Condition | Behavior |
|---|---|
| Network lost during creation | Allow local editing |
| Submit offline | Queue + show "Will post when connected" |

---

## 12. Accessibility

- Media picker has screen reader labels
- Upload progress announced
- Caption has accessible label and character count
- Location/tag buttons have clear focus states
- Error messages announced

---

## 13. Analytics Events (MVP)

| Event | Payload |
|---|---|
| `create_post_opened` | `source` (feed/profile) |
| `media_selected` | `count`, `types` (photo/video) |
| `caption_entered` | `char_count`, `hashtag_count` |
| `location_added` | `city_id`, `method` (auto/search) |
| `tag_added` | `entity_type`, `entity_id` |
| `checkin_toggled` | `enabled` |
| `post_submitted` | `media_count`, `has_tag`, `has_location` |
| `post_published` | `post_id`, `safety_result` |
| `post_failed` | `error_type` |
| `post_discarded` | `had_content` |

---

## 14. Security & Moderation Checklist

- [x] User must be authenticated
- [x] Media uploaded to private bucket, then made public
- [x] ContentSafetyAgent checks all posts
- [x] Caption sanitized (no script injection)
- [x] Location is event-based (no tracking)
- [x] File size limits enforced
- [x] Rate limiting on post creation
- [x] Duplicate detection
- [x] NSFW content blocked

---

## 15. Design Decisions (APPROVED)

Create-specific:
1. **Multi-step vs single page**: MVP uses single scrollable page
2. **Video limit 60s**: Balance between quality and storage
3. **Max 10 media items**: Prevent abuse, ensure performance
4. **Check-in optional**: Privacy-first approach
5. **Safety check blocking**: Don't publish until checked
6. **Caption 2000 chars**: Generous but not unlimited
7. **Hashtag auto-detect**: Highlight in real-time

---

## 16. Related Screens

| Screen | Relationship |
|---|---|
| Community Feed | Entry point, return destination |
| Location Search | Modal for location picker |
| Tag Search | Modal for entity tagging |
| Camera | Native camera integration |
| Gallery | Native gallery picker |
| User Profile | Shows user's posts |

---

## 17. Post-Submit Flow

```
[Share tapped]
    ↓
[Upload media] → Progress bar
    ↓
[ContentSafetyAgent check]
    ├── Safe → Create post record
    ├── Review → Create post + flag
    └── Unsafe → Block + error message
    ↓
[Success toast] "Post shared!"
    ↓
[Navigate to Feed] with new post at top
```

---

## Approval Checklist

- [ ] Purpose clear
- [ ] Media handling rules defined
- [ ] Tagging flow complete
- [ ] Safety check integrated
- [ ] Privacy rules followed (event-based location)
- [ ] Edge cases covered
- [ ] Security verified

---

**Status: AWAITING APPROVAL**
