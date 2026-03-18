# SUPABASE_SCHEMA (MVP)
Tables, Indexes, Relationships, RLS Policies

---

> **Primary DB**: Postgres (Supabase)  
> **Auth**: Supabase Auth  
> **Principle**: Public read where safe, owner-only write, admin-only overrides.

---

## 0) Roles

| Role | Description | Assignment |
|---|---|---|
| `user` | Default role | On signup |
| `host` | Can manage stays | On host registration |
| `admin` | Platform administration | Manual only |

Roles stored via auth claims or a `user_roles` table (admin-controlled).

---

## 1) Core Identity

### users (profile extension)
Extends Supabase Auth user.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK, = auth.uid() |
| `display_name` | text | NOT NULL |
| `avatar_url` | text | - |
| `bio` | text | max 150 chars |
| `home_country` | text | - |
| `languages` | text[] | - |
| `created_at` | timestamptz | DEFAULT now() |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Public |
| INSERT | auth.uid() = id |
| UPDATE | auth.uid() = id |
| DELETE | Admin only |

**Indexes:**
- `idx_users_created_at` on (created_at)

---

### hosts
Host-specific data for users who become hosts.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users.id, UNIQUE |
| `verified_host` | boolean | DEFAULT false |
| `verification_status` | enum | NOT_APPLIED, PENDING, APPROVED, REJECTED |
| `response_rate` | float | - |
| `response_time_hours` | float | - |
| `created_at` | timestamptz | DEFAULT now() |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Public |
| INSERT | auth.uid() = user_id |
| UPDATE | auth.uid() = user_id OR admin |
| DELETE | Admin only |

**Indexes:**
- `idx_hosts_user_id` on (user_id)
- `idx_hosts_verified` on (verified_host)

---

### follows
User follow relationships.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `follower_id` | uuid | FK → users.id |
| `following_id` | uuid | FK → users.id |
| `created_at` | timestamptz | DEFAULT now() |

**Unique:** (follower_id, following_id)

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Public |
| INSERT | auth.uid() = follower_id |
| DELETE | auth.uid() = follower_id |

---

## 2) Geography

### cities
Cities available in the platform.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `name` | text | NOT NULL |
| `country_code` | text | ISO 3166-1 alpha-2 |
| `lat` | float | NOT NULL |
| `lng` | float | NOT NULL |
| `is_active` | boolean | DEFAULT true |
| `created_at` | timestamptz | DEFAULT now() |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Public |
| INSERT/UPDATE/DELETE | Admin only |

**Indexes:**
- `idx_cities_country` on (country_code)
- `idx_cities_location` on (lat, lng)
- `idx_cities_active` on (is_active)

---

## 3) Content & Discovery

### places
Points of interest (restaurants, attractions, etc).

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `city_id` | uuid | FK → cities.id |
| `name` | text | NOT NULL |
| `description` | text | - |
| `category` | text | NOT NULL |
| `lat` | float | NOT NULL |
| `lng` | float | NOT NULL |
| `rating` | float | 0-5 |
| `review_count` | int | DEFAULT 0 |
| `price_level` | int | 1-4 |
| `is_sponsored` | boolean | DEFAULT false |
| `created_at` | timestamptz | DEFAULT now() |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Public |
| INSERT/UPDATE/DELETE | Admin only |

**Indexes:**
- `idx_places_city` on (city_id)
- `idx_places_category` on (category)
- `idx_places_location` on (lat, lng)
- `idx_places_sponsored` on (is_sponsored) WHERE is_sponsored = true

---

### experiences
Bookable experiences/activities.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `city_id` | uuid | FK → cities.id |
| `title` | text | NOT NULL |
| `description` | text | - |
| `price_min` | numeric | NOT NULL |
| `price_max` | numeric | NOT NULL |
| `currency` | text | DEFAULT 'EUR' |
| `duration_minutes` | int | NOT NULL |
| `max_guests` | int | - |
| `category` | text | - |
| `rating` | float | 0-5 |
| `review_count` | int | DEFAULT 0 |
| `is_sponsored` | boolean | DEFAULT false |
| `is_active` | boolean | DEFAULT true |
| `created_at` | timestamptz | DEFAULT now() |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Public (where is_active = true) |
| INSERT/UPDATE/DELETE | Admin only |

**Indexes:**
- `idx_experiences_city` on (city_id)
- `idx_experiences_price` on (price_min, price_max)
- `idx_experiences_rating` on (rating DESC)
- `idx_experiences_category` on (category)
- `idx_experiences_active` on (is_active)

---

### stays
Host-managed accommodation listings.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `host_id` | uuid | FK → hosts.id |
| `city_id` | uuid | FK → cities.id |
| `title` | text | NOT NULL |
| `description` | text | - |
| `price_min` | numeric | NOT NULL |
| `price_max` | numeric | NOT NULL |
| `currency` | text | DEFAULT 'EUR' |
| `guests_max` | int | NOT NULL |
| `bedrooms` | int | - |
| `beds` | int | - |
| `bathrooms` | float | - |
| `amenities` | text[] | - |
| `house_rules` | text | - |
| `status` | enum | draft, active, paused, suspended |
| `rating` | float | 0-5 |
| `review_count` | int | DEFAULT 0 |
| `views_count` | int | DEFAULT 0 |
| `created_at` | timestamptz | DEFAULT now() |
| `updated_at` | timestamptz | - |

**Status Enum:**
```sql
CREATE TYPE stay_status AS ENUM ('draft', 'active', 'paused', 'suspended');
```

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | status = 'active' OR auth.uid() = host.user_id OR admin |
| INSERT | auth.uid() = host.user_id |
| UPDATE | auth.uid() = host.user_id OR admin |
| DELETE | auth.uid() = host.user_id OR admin |

**Indexes:**
- `idx_stays_host` on (host_id)
- `idx_stays_city` on (city_id)
- `idx_stays_status` on (status)
- `idx_stays_city_status` on (city_id, status)
- `idx_stays_rating` on (rating DESC)

---

### stay_media
Media files for stays.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `stay_id` | uuid | FK → stays.id |
| `url` | text | NOT NULL |
| `type` | enum | image, video |
| `order` | int | DEFAULT 0 |
| `created_at` | timestamptz | DEFAULT now() |

**RLS:** Same as parent stay.

---

## 4) Social

### posts
User-generated content for the feed.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users.id |
| `city_id` | uuid | FK → cities.id |
| `caption` | text | max 2000 chars |
| `media_urls` | text[] | NOT NULL |
| `tagged_type` | enum | place, experience, stay, NULL |
| `tagged_id` | uuid | - |
| `is_public` | boolean | DEFAULT true |
| `is_sponsored` | boolean | DEFAULT false |
| `safety_status` | enum | pending, approved, flagged, removed |
| `created_at` | timestamptz | DEFAULT now() |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | is_public = true AND safety_status = 'approved' |
| INSERT | auth.uid() = user_id |
| UPDATE | auth.uid() = user_id OR admin |
| DELETE | auth.uid() = user_id OR admin |

**Indexes:**
- `idx_posts_user` on (user_id)
- `idx_posts_city` on (city_id)
- `idx_posts_created` on (created_at DESC)
- `idx_posts_tagged` on (tagged_type, tagged_id)

---

### comments
Comments on posts.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `post_id` | uuid | FK → posts.id |
| `user_id` | uuid | FK → users.id |
| `text` | text | NOT NULL, max 500 chars |
| `created_at` | timestamptz | DEFAULT now() |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Public |
| INSERT | auth.uid() = user_id |
| UPDATE | auth.uid() = user_id |
| DELETE | auth.uid() = user_id OR admin |

**Indexes:**
- `idx_comments_post` on (post_id)
- `idx_comments_created` on (created_at DESC)

---

### likes
Post likes.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `post_id` | uuid | FK → posts.id |
| `user_id` | uuid | FK → users.id |
| `created_at` | timestamptz | DEFAULT now() |

**Unique:** (post_id, user_id)

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Public |
| INSERT | auth.uid() = user_id |
| DELETE | auth.uid() = user_id |

**Indexes:**
- `idx_likes_post` on (post_id)
- `idx_likes_user` on (user_id)

---

### saved_items
User's saved/bookmarked items.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users.id |
| `item_type` | enum | place, experience, stay, post |
| `item_id` | uuid | NOT NULL |
| `created_at` | timestamptz | DEFAULT now() |

**Unique:** (user_id, item_type, item_id)

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | auth.uid() = user_id |
| INSERT | auth.uid() = user_id |
| DELETE | auth.uid() = user_id |

**Indexes:**
- `idx_saved_user` on (user_id)
- `idx_saved_item` on (item_type, item_id)

---

## 5) Booking

### booking_experience
Experience bookings via Stripe.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users.id |
| `experience_id` | uuid | FK → experiences.id |
| `quantity` | int | DEFAULT 1 |
| `total_amount` | numeric | NOT NULL |
| `currency` | text | DEFAULT 'EUR' |
| `status` | enum | pending, paid, completed, canceled, refunded |
| `stripe_session_id` | text | - |
| `stripe_payment_intent_id` | text | - |
| `booked_date` | date | - |
| `created_at` | timestamptz | DEFAULT now() |
| `updated_at` | timestamptz | - |

**Status Enum:**
```sql
CREATE TYPE booking_status AS ENUM ('pending', 'paid', 'completed', 'canceled', 'refunded');
```

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | auth.uid() = user_id OR admin |
| INSERT | auth.uid() = user_id |
| UPDATE | Admin only (webhook) |

**Indexes:**
- `idx_booking_exp_user` on (user_id)
- `idx_booking_exp_experience` on (experience_id)
- `idx_booking_exp_status` on (status)
- `idx_booking_exp_stripe` on (stripe_session_id)

---

### booking_request_stay
Stay booking requests (no payment in MVP).

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `stay_id` | uuid | FK → stays.id |
| `user_id` | uuid | FK → users.id |
| `host_id` | uuid | FK → hosts.id |
| `check_in` | date | NOT NULL |
| `check_out` | date | NOT NULL |
| `guests` | int | NOT NULL |
| `message` | text | max 500 chars |
| `status` | enum | sent, accepted, rejected, canceled |
| `created_at` | timestamptz | DEFAULT now() |
| `updated_at` | timestamptz | - |

**Status Enum:**
```sql
CREATE TYPE request_status AS ENUM ('sent', 'accepted', 'rejected', 'canceled');
```

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | auth.uid() IN (user_id, host.user_id) OR admin |
| INSERT | auth.uid() = user_id |
| UPDATE | auth.uid() IN (user_id, host.user_id) OR admin |

**Indexes:**
- `idx_request_stay` on (stay_id)
- `idx_request_host` on (host_id)
- `idx_request_user` on (user_id)
- `idx_request_status` on (status)

---

## 6) Reviews

### reviews
Reviews for experiences, stays, and hosts.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users.id |
| `target_type` | enum | experience, stay, host |
| `target_id` | uuid | NOT NULL |
| `booking_id` | uuid | FK → booking_experience or booking_request_stay |
| `rating` | int | 1-5, NOT NULL |
| `text` | text | max 1000 chars |
| `verified` | boolean | DEFAULT false |
| `created_at` | timestamptz | DEFAULT now() |

**Verification Rules:**
- Experience: booking_experience.status IN ('paid', 'completed') → verified = true
- Stay: booking_request_stay.status = 'accepted' → verified = true (optional MVP)

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Public |
| INSERT | auth.uid() = user_id |
| UPDATE | auth.uid() = user_id OR admin |
| DELETE | auth.uid() = user_id OR admin |

**Indexes:**
- `idx_reviews_target` on (target_type, target_id)
- `idx_reviews_user` on (user_id)
- `idx_reviews_verified` on (verified)

---

## 7) AI

### ai_trip_plan_request
Queued AI plan generation requests.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users.id (nullable for anonymous) |
| `city_id` | uuid | FK → cities.id |
| `input_json` | jsonb | NOT NULL |
| `status` | enum | queued, processing, done, failed |
| `error_message` | text | - |
| `created_at` | timestamptz | DEFAULT now() |
| `processed_at` | timestamptz | - |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | auth.uid() = user_id OR user_id IS NULL |
| INSERT | Public |
| UPDATE | Admin/Agent only |

**Indexes:**
- `idx_plan_req_status` on (status)
- `idx_plan_req_user` on (user_id)

---

### ai_trip_plan
Generated AI trip plans.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `request_id` | uuid | FK → ai_trip_plan_request.id |
| `output_json` | jsonb | NOT NULL |
| `confidence_level` | enum | low, medium, high |
| `cache_ttl_seconds` | int | DEFAULT 604800 |
| `created_at` | timestamptz | DEFAULT now() |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Same as request |
| INSERT/UPDATE | Admin/Agent only |

**Indexes:**
- `idx_plan_request` on (request_id)

---

### user_plans
User-saved trip plans.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → users.id |
| `city_id` | uuid | FK → cities.id |
| `plan_id` | uuid | FK → ai_trip_plan.id |
| `custom_name` | text | - |
| `created_at` | timestamptz | DEFAULT now() |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | auth.uid() = user_id |
| INSERT | auth.uid() = user_id |
| DELETE | auth.uid() = user_id |

---

## 8) Moderation

### reports
User-submitted reports.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `reporter_id` | uuid | FK → users.id |
| `target_type` | enum | post, comment, user, host, stay, review |
| `target_id` | uuid | NOT NULL |
| `reason` | enum | spam, harassment, inappropriate, scam, other |
| `description` | text | - |
| `status` | enum | open, reviewing, resolved, dismissed |
| `created_at` | timestamptz | DEFAULT now() |
| `resolved_at` | timestamptz | - |
| `resolved_by` | uuid | FK → users.id (admin) |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | auth.uid() = reporter_id OR admin |
| INSERT | auth.uid() = reporter_id |
| UPDATE | Admin only |

**Indexes:**
- `idx_reports_status` on (status)
- `idx_reports_target` on (target_type, target_id)

---

## 9) Admin & Config

### app_config
Platform configuration (including brand settings).

| Column | Type | Constraints |
|---|---|---|
| `key` | text | PK |
| `value_json` | jsonb | NOT NULL |
| `updated_at` | timestamptz | DEFAULT now() |
| `updated_by` | uuid | FK → users.id (admin) |

**Required Keys:**
| Key | Example |
|---|---|
| `brand.name` | `"TravelSocial"` |
| `brand.logo_url` | `"https://..."` |
| `brand.updated_version` | `"1.0.3"` |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Public |
| INSERT/UPDATE/DELETE | Admin only |

---

### admin_audit_log
Audit trail for all admin actions.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `admin_id` | uuid | FK → users.id |
| `action_type` | text | NOT NULL |
| `target_type` | text | - |
| `target_id` | uuid | - |
| `old_value` | jsonb | - |
| `new_value` | jsonb | - |
| `reason` | text | - |
| `ip_address` | inet | - |
| `created_at` | timestamptz | DEFAULT now() |

**RLS Policies:**
| Action | Policy |
|---|---|
| SELECT | Admin only |
| INSERT | Admin only |
| UPDATE/DELETE | Never |

**Indexes:**
- `idx_audit_admin` on (admin_id)
- `idx_audit_created` on (created_at DESC)
- `idx_audit_action` on (action_type)

---

## 10) Check-ins (Optional MVP)

### checkins
Location check-ins attached to posts.

| Column | Type | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `post_id` | uuid | FK → posts.id |
| `lat` | float | NOT NULL |
| `lng` | float | NOT NULL |
| `place_name` | text | - |
| `created_at` | timestamptz | DEFAULT now() |

**RLS:** Same as post.

---

## 11) Indexing Strategy

### General Rules
| Rule | Implementation |
|---|---|
| Foreign keys | Always indexed |
| Status fields | Index if used in filters |
| Timestamps | Index created_at for sorting |
| Composite | (city_id, status) for common queries |

### High-Traffic Queries
| Query | Indexes Used |
|---|---|
| Explore list by city | idx_experiences_city, idx_stays_city_status |
| Feed by recency | idx_posts_created |
| User's bookings | idx_booking_exp_user |
| Host's requests | idx_request_host |

---

## 12) Enums Summary

```sql
-- Status enums
CREATE TYPE stay_status AS ENUM ('draft', 'active', 'paused', 'suspended');
CREATE TYPE booking_status AS ENUM ('pending', 'paid', 'completed', 'canceled', 'refunded');
CREATE TYPE request_status AS ENUM ('sent', 'accepted', 'rejected', 'canceled');
CREATE TYPE safety_status AS ENUM ('pending', 'approved', 'flagged', 'removed');
CREATE TYPE report_status AS ENUM ('open', 'reviewing', 'resolved', 'dismissed');
CREATE TYPE plan_status AS ENUM ('queued', 'processing', 'done', 'failed');
CREATE TYPE confidence_level AS ENUM ('low', 'medium', 'high');

-- Type enums
CREATE TYPE media_type AS ENUM ('image', 'video');
CREATE TYPE item_type AS ENUM ('place', 'experience', 'stay', 'post');
CREATE TYPE target_type AS ENUM ('experience', 'stay', 'host');
CREATE TYPE report_target AS ENUM ('post', 'comment', 'user', 'host', 'stay', 'review');
CREATE TYPE report_reason AS ENUM ('spam', 'harassment', 'inappropriate', 'scam', 'other');
CREATE TYPE verification_status AS ENUM ('NOT_APPLIED', 'PENDING', 'APPROVED', 'REJECTED');
```

---

## 13) Out of Scope (MVP)

| Feature | Table | Status |
|---|---|---|
| Calendar sync | stay_availability | ❌ |
| Stay payments | stay_payment | ❌ |
| Seasonal pricing | stay_pricing_rules | ❌ |
| Automated KYC | kyc_verification | ❌ |
| Notifications | notifications | Future |
| Chat/Messages | messages | Future |

---

## 14) Table Count Summary

| Category | Tables |
|---|---|
| Identity | 3 (users, hosts, follows) |
| Geography | 1 (cities) |
| Content | 4 (places, experiences, stays, stay_media) |
| Social | 5 (posts, comments, likes, saved_items, checkins) |
| Booking | 2 (booking_experience, booking_request_stay) |
| Reviews | 1 (reviews) |
| AI | 3 (ai_trip_plan_request, ai_trip_plan, user_plans) |
| Moderation | 1 (reports) |
| Admin | 2 (app_config, admin_audit_log) |
| **Total** | **22 tables** |

---

**Status: AWAITING APPROVAL**
