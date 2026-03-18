# DATA_MODEL (MVP) — Global Travel Social Marketplace (Mobile)

## Principles
- Mobile-first: compact payloads, pagination everywhere
- Trust first: reviews only from verified bookings/completions
- Stay bookings are request-based in MVP (no Stripe payment for stays)
- Experiences can be paid via Stripe Checkout (MVP)
- Sponsored content must be clearly labeled

---

## Entities (MVP)

### 1) user
Represents an authenticated account.
**Fields**
- id (uuid, pk)
- email (string, unique)
- created_at (timestamp)

### 2) profile
Public profile of a user.
**Fields**
- id (uuid, pk)
- user_id (uuid, fk -> user.id, unique)
- display_name (string)
- avatar_url (string, nullable)
- bio (string, nullable)
- languages (string[], nullable)  // user preferred languages
- home_country (string, nullable)
- created_at (timestamp)

### 3) city
City master table.
**Fields**
- id (uuid, pk)
- name (string)
- country_code (string) // ISO
- lat (float)
- lng (float)
- timezone (string)
- popularity_rank (int, nullable)
- created_at (timestamp)

### 4) place
Physical venue: restaurant/bar/museum/cinema etc.
**Fields**
- id (uuid, pk)
- city_id (uuid, fk -> city.id)
- name (string)
- category (enum) // restaurant, bar, museum, etc.
- lat (float)
- lng (float)
- address (string, nullable)
- price_level (enum) // €, €€, €€€
- rating_avg (float, cached)
- rating_count (int, cached)
- local_score (float, cached) // local vs tourist indicator
- sponsored (bool, default false)
- created_at (timestamp)

### 5) experience
Bookable activity: tour/course/surf/ski/workshop etc.
**Fields**
- id (uuid, pk)
- city_id (uuid, fk -> city.id)
- place_id (uuid, fk -> place.id, nullable)
- title (string)
- category (enum) // tour, course, surf, ski, workshop...
- duration_minutes (int, nullable)
- price_range_min (int) // cents or integer
- price_range_max (int)
- currency (string) // EUR
- availability_type (enum) // fixed_slots, open_request
- rating_avg (float, cached)
- rating_count (int, cached)
- local_score (float, cached)
- sponsored (bool, default false)
- created_at (timestamp)

### 6) host
Host account for stays (can be a user profile).
**Fields**
- id (uuid, pk)
- user_id (uuid, fk -> user.id, unique)
- host_status (enum) // pending, active, suspended
- verified_host (bool, default false) // manual admin approval in MVP
- host_rating_avg (float, cached)
- host_rating_count (int, cached)
- created_at (timestamp)

### 7) stay
Accommodation listing (Airbnb-like) — request based in MVP.
**Fields**
- id (uuid, pk)
- host_id (uuid, fk -> host.id)
- city_id (uuid, fk -> city.id)
- title (string)
- room_type (enum) // entire_place, private_room, shared_room
- guests_max (int)
- bedrooms (int, nullable)
- bathrooms (float, nullable)
- price_per_night_min (int)
- price_per_night_max (int)
- currency (string) // EUR
- lat (float)
- lng (float)
- address (string, nullable)
- amenities (string[], nullable)
- stay_status (enum) // pending, active, suspended
- sponsored (bool, default false)
- created_at (timestamp)

### 8) booking_experience
Paid booking for experiences (Stripe in MVP).
**Fields**
- id (uuid, pk)
- user_id (uuid, fk -> user.id)
- experience_id (uuid, fk -> experience.id)
- status (enum) // initiated, paid, completed, refunded, canceled
- stripe_checkout_session_id (string, nullable)
- amount_paid (int, nullable)
- currency (string)
- booked_at (timestamp)
- completed_at (timestamp, nullable)

### 9) booking_request_stay
Request-based stay booking (no payment in MVP).
**Fields**
- id (uuid, pk)
- user_id (uuid, fk -> user.id)
- stay_id (uuid, fk -> stay.id)
- check_in (date)
- check_out (date)
- guests (int)
- message (string, nullable)
- status (enum) // sent, accepted, rejected, canceled
- created_at (timestamp)

### 10) review
Verified review. MUST reference a verified booking/completion.
**Fields**
- id (uuid, pk)
- user_id (uuid, fk -> user.id)
- target_type (enum) // experience, stay
- target_id (uuid)
- rating (int) // 1..5
- text (string, nullable)
- verified (bool, default true)
- booking_experience_id (uuid, nullable) // required if target_type=experience
- booking_request_stay_id (uuid, nullable) // optional MVP (only if you later verify stays)
- created_at (timestamp)

**Rules**
- Experience review allowed only if booking_experience.status in (paid, completed)
- Stay review: MVP optional. If enabled, require accepted request + manual verification or later payment-based verification.

### 11) post
Social post (Instagram-like).
**Fields**
- id (uuid, pk)
- user_id (uuid, fk -> user.id)
- city_id (uuid, fk -> city.id, nullable)
- caption (string, nullable)
- media_urls (string[])
- tagged_type (enum, nullable) // place, experience, stay
- tagged_id (uuid, nullable)
- is_public (bool, default true)
- created_at (timestamp)

### 12) checkin
Event-based location attached to a post (no live tracking).
**Fields**
- id (uuid, pk)
- post_id (uuid, fk -> post.id, unique)
- lat (float)
- lng (float)
- place_name (string, nullable)
- created_at (timestamp)

### 13) follow
User follows user.
**Fields**
- follower_user_id (uuid, fk -> user.id)
- following_user_id (uuid, fk -> user.id)
- created_at (timestamp)

### 14) like
Likes on posts.
**Fields**
- user_id (uuid, fk -> user.id)
- post_id (uuid, fk -> post.id)
- created_at (timestamp)

### 15) comment
Comments on posts.
**Fields**
- id (uuid, pk)
- user_id (uuid, fk -> user.id)
- post_id (uuid, fk -> post.id)
- text (string)
- created_at (timestamp)

### 16) sponsorship
Paid boost for place/experience/stay.
**Fields**
- id (uuid, pk)
- target_type (enum) // place, experience, stay
- target_id (uuid)
- status (enum) // active, paused, ended
- budget (int)
- currency (string)
- created_at (timestamp)

### 17) report
User reports content for moderation.
**Fields**
- id (uuid, pk)
- reporter_user_id (uuid, fk -> user.id)
- target_type (enum) // post, review, stay, experience, host
- target_id (uuid)
- reason (enum) // spam, scam, offensive, fake, other
- details (string, nullable)
- status (enum) // open, reviewing, resolved
- created_at (timestamp)

---

## Index & Performance Notes (MVP)
- geo index on place(lat,lng), stay(lat,lng)
- composite indexes:
  - experience(city_id, category)
  - stay(city_id, room_type)
  - post(created_at desc)
- pagination on all list endpoints

---

## RLS Notes (MVP)
- profile: public read, owner write
- post: public read if is_public, owner write
- booking_experience: owner read/write
- booking_request_stay: requester and host read, requester write, host updates status
- admin tables/actions: restricted by admin role