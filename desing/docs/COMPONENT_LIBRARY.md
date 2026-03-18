# COMPONENT_LIBRARY (MVP) — Flutter Widgets
Global Travel Social Marketplace – Mobile

## Design Principles
- Calm, premium, honest
- Price visible
- Trust signals always visible
- Experience vs Stay visually distinct
- Fast lists (pagination + skeletons)

---

## Foundations
### Typography
- AppTitle, SectionTitle, Body, Caption, BadgeText

### Spacing
- 8 / 16 / 24 px rhythm

### Colors (conceptual)
- Neutral backgrounds
- Accent for CTAs
- Warning / Danger for admin actions

---

## Core UI Building Blocks

### Navigation
- `AppBottomNav`
- `AppTopBar`
- `AppSearchBar`
- `FilterChipsRow`

### Cards
- `ExperienceCard`
  - title, duration, price_range, rating, local_badge, sponsored_badge
- `StayCard`
  - title, nightly_price, host_badge, rating, room_type, sponsored_badge
- `PlaceCard` (optional)
- `PostCard`

### Media
- `MediaCarousel`
- `Avatar`
- `VerifiedBadge`
- `SponsoredBadge`

### Trust
- `TrustRow` (verified host/guest, safety hints)
- `RatingSummary`
- `ReportButton`

### Lists & Loading
- `PagedListView`
- `SkeletonCard`
- `EmptyState`
- `ErrorState` (retry button)

### Map
- `MapView` (Google Maps / Mapbox wrapper)
- `MapPinCluster`
- `MapBottomSheetPreviewCard`

### Forms
- `DateRangePickerField`
- `GuestCountSelector`
- `PrimaryButton`
- `SecondaryButton`
- `TextAreaField`

### AI
- `AIInfoBanner` (labels + confidence)
- `PlanDayCard`
- `PlanItemRow`

### Social
- `LikeButton`
- `CommentComposer`
- `FollowButton`
- `TagChip`

---

## Screen Composition (at a glance)
- MainMapView:
  MapView + FilterChipsRow + BottomSheetPreviewCard
- ExploreListView:
  SearchBar + Filters + (ExperienceCard / StayCard list)
- ExperienceDetail:
  MediaCarousel + PriceHeader + TrustRow + CTA
- StayDetail:
  MediaCarousel + NightlyPriceHeader + HostPreview + CTA
- AITripPlanner:
  Inputs form + Generate button + Plan preview list
- Feed:
  PagedListView(PostCard) + CreatePost FAB
- Profile:
  ProfileHeader + Tabs (Posts/Saved/Trips)

---

## Admin Components (separate style)
- `AdminTable`
- `StatusPill` (pending/active/suspended)
- `AdminActionButton` (approve/suspend/ban)
- `ModerationQueueItem`