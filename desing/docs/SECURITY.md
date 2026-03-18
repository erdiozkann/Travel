# SECURITY & TRUST MODEL (MVP)
Global Travel Social Marketplace – Mobile App

This document defines security, trust, privacy, and abuse-prevention rules.
All backend logic, AI agents, and admin actions MUST comply with this file.

---

## 1. Core Security Principles

- Mobile-first threat model
- Zero trust between client and backend
- No direct client → AI agent calls
- Least privilege everywhere
- Trust is earned, not assumed

---

## 2. Authentication & Identity

### Authentication
- Managed by Supabase Auth
- Supported (MVP):
  - Email + password
  - OAuth (Google / Apple)
- No anonymous posting

### Identity Separation
- `user` = authentication entity
- `profile` = public identity
- `host` = business role (linked to user)

---

## 3. Authorization (RLS – Row Level Security)

### General Rules
- All tables protected with RLS
- No public write access
- Admin actions require admin role

### Examples
- Users can update ONLY their own profile
- Posts:
  - Public read if `is_public = true`
  - Write only by owner
- Booking requests:
  - Read by requester & host
  - Status update only by host
- Reviews:
  - Write only after verified booking

---

## 4. Reviews & Trust Enforcement

### Experience Reviews
Allowed ONLY if:
- booking_experience.status IN (paid, completed)

### Stay Reviews (MVP)
- Disabled by default OR
- Enabled only with:
  - accepted booking request
  - manual admin verification

### Anti-Fraud
- One review per booking
- No anonymous reviews
- Review edits locked after publish

---

## 5. Host Trust & Verification

### MVP Rules
- No automated KYC
- Verified Host = manual admin approval
- Verification revocable at any time

### Trust Signals
- Verified Host badge
- Host rating
- Completed stays count
- Report history

---

## 6. Payments Security (Stripe)

### Experiences
- Stripe Checkout only
- No card data stored
- Webhooks verified server-side

### Stays
- No payments in MVP
- Request-based only
- Payment discussion outside platform

---

## 7. AI & Agent Security

### Agent Isolation
- Agents are stateless
- No direct DB write without validation layer
- Outputs must be structured JSON

### AI Content Rules
- AI content always labeled
- Confidence level mandatory
- No medical, legal, or absolute claims

### Prompt Safety
- User-generated input sanitized
- No prompt injection allowed
- System prompts locked (read-only)

---

## 8. Content Moderation

### User Reports
- Any post, review, stay, host can be reported
- Reports generate moderation tasks

### Admin Moderation
- AI provides recommendation ONLY
- Final decision always human (admin)

### Actions
- Hide content
- Warn user
- Suspend host
- Ban account (last resort)

---

## 9. Rate Limiting & Abuse Prevention

- API rate limits per user
- AI request quotas
- Spam detection on:
  - Posts
  - Booking requests
  - Messages

---

## 10. Data Privacy (GDPR Ready)

- Minimal data collection
- Right to delete account
- Right to data export
- Media stored with access rules

---

## 11. Logging & Audit

- All admin actions logged
- Moderation actions auditable
- Payment events logged via Stripe webhooks

---

## 12. What MVP Explicitly Does NOT Do

- No live location tracking
- No background location access
- No offline map downloads
- No automated KYC
- No escrow / deposit handling

---

## 13. Security Escalation Rule

If a security decision is unclear:
- Block the action
- Require admin review
- Do NOT auto-approve

---

## Final Rule

Security and trust override growth and monetization.
Any feature violating this document must NOT be implemented.