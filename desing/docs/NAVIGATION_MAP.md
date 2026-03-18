# NAVIGATION_MAP (MVP) — Flutter (GoRouter)
Global Travel Social Marketplace – Mobile

## Goals
- Simple bottom navigation
- Deep links for shareable content
- Clear separation of flows (Experience vs Stay)
- Mobile-first, fast back behavior

---

## Router Choice
- GoRouter + StatefulShellRoute (recommended for bottom nav)
- Nested navigation per tab

---

## Bottom Navigation Tabs (MVP)
1. Map
2. Explore
3. Plan (AI)
4. Feed
5. Profile

> Rationale: All core screens are reachable in 1 tap.

---

## Route Table (Canonical)

### Root
- `/` → redirects to `/map`

### Map Tab
- `/map` → MainMapView
- `/map/place/:placeId` → PlaceDetailView (optional MVP, if you show places)
- `/map/experience/:experienceId` → ExperienceDetailView
- `/map/stay/:stayId` → StayDetailView

### Explore Tab
- `/explore` → ExploreListView
- `/explore/experience/:experienceId` → ExperienceDetailView
- `/explore/stay/:stayId` → StayDetailView
- `/explore/search` → SearchOverlayView (optional)

### Plan Tab (AI)
- `/plan` → AITripPlannerView
- `/plan/:planId` → AIPlanDetailView (cached plan)
- `/plan/:planId/day/:date` → AIPlanDayView (optional)

### Feed Tab
- `/feed` → CommunityFeedView
- `/feed/post/:postId` → PostDetailView
- `/feed/create` → CreatePostView (modal or full screen)

### Profile Tab
- `/profile` → MyProfileView
- `/profile/settings` → SettingsView
- `/profile/saved` → SavedItemsView
- `/u/:userId` → PublicUserProfileView (can open from anywhere)
- `/host/:hostId` → HostProfileView (public)
- `/admin` → AdminEntry (admin only, hidden)
- `/admin/dashboard` → AdminDashboard
- `/admin/moderation` → ModerationQueue

---

## Auth Guard
- Unauthenticated users can browse:
  - map, explore, detail pages
- Authentication required for:
  - creating posts
  - booking experiences
  - sending stay requests
  - following/liking/commenting
  - saving items

Guard behavior:
- If user not logged in → redirect to `/auth/login` with `redirect=` param.

Routes:
- `/auth/login`
- `/auth/register`

---

## Screen Transition Rules (MVP)
- Detail pages open as push from Map/Explore
- CreatePost opens as modal from Feed (or full screen on Android back)
- Back behavior:
  - In tab stacks: back pops stack
  - At root of tab: back exits app (Android), no pop loops

---

## Deep Link Requirements
Share links open the app to the correct entity:

- Experience:
  `myapp://explore/experience/<id>`
- Stay:
  `myapp://explore/stay/<id>`
- Post:
  `myapp://feed/post/<id>`
- User profile:
  `myapp://u/<userId>`
- Host profile:
  `myapp://host/<hostId>`

If app not installed:
- fallback to landing page (later)

---

## MVP Navigation Notes
- Avoid too many overlays
- Keep CTA paths short:
  - Explore → Detail → Book/Request
  - Plan → PlanDetail
  - Feed → Post → Profile