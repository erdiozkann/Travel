# SCREEN SPEC: Send Booking Request
Screen ID: 05
Route: `/stay/:stayId/request`
Design Reference: `01_customer_core/send_booking_request`

---

## 1. Purpose

The Send Booking Request screen is a **focused action form** for submitting stay requests. It provides:
- Simple form: dates, guests, optional message
- Clear expectations: no payment in MVP
- Validation before submit
- Confirmation after submit
- Host notification trigger

This screen answers: **"How do I request this stay?"**

> **Critical Rule**: This is request-only. No payment, no instant confirmation.

---

## 2. Entry Points

| Source | Route | Behavior |
|---|---|---|
| Stay Detail CTA | `/stay/:stayId/request` | Push (or modal) |
| Deep link | Not applicable | Must come from Stay Detail |

**Prerequisites:**
- User must be authenticated
- Stay must exist and be active

---

## 3. UI Sections

### 3.1 Header
| Element | Description |
|---|---|
| **Back button** | Return to Stay Detail |
| **Title** | "Request to Book" |
| **Stay preview** | Mini card: thumbnail, title, price range |

### 3.2 Stay Summary (Compact)
| Element | Description |
|---|---|
| **Thumbnail** | Small stay image |
| **Title** | Stay name |
| **Host** | "Hosted by Maria" + avatar |
| **Price hint** | "~€85–€120 / night" |

### 3.3 Date Selection
| Element | Description |
|---|---|
| **Check-in field** | Date picker (tap to open calendar) |
| **Check-out field** | Date picker |
| **Night count** | Auto-calculated: "4 nights" |
| **Validation** | Check-out must be after check-in |

**Mobile UX:**
- Full-screen calendar modal on tap
- Range selection mode
- Blocked dates shown as disabled

### 3.4 Guest Count
| Element | Description |
|---|---|
| **Guest selector** | Stepper: - [2] + |
| **Max guests** | From stay.guests_max |
| **Validation** | 1 ≤ guests ≤ guests_max |

### 3.5 Estimated Total (Informational)
| Element | Description |
|---|---|
| **Calculation** | `nights × avg_price_per_night` |
| **Display** | "Estimated: €340 – €480" |
| **Disclaimer** | "Final price confirmed by host" |
| **Note** | Price is range, not exact (GUARDRAILS.md) |

### 3.6 Message to Host (Optional)
| Element | Description |
|---|---|
| **Text area** | Multiline input |
| **Placeholder** | "Tell the host about your trip..." |
| **Character limit** | 500 characters |
| **Validation** | Optional, no min length |

### 3.7 Expectations Banner
| Element | Description |
|---|---|
| **Info box** | Light background with icon |
| **Text** | "This is a booking request. The host will review and respond. No payment required now." |
| **Purpose** | Set clear expectations (no instant confirmation) |

### 3.8 Submit Button
| Element | Description |
|---|---|
| **CTA** | **"Send Request"** (primary, full-width) |
| **Disabled state** | If validation fails |
| **Loading state** | Spinner while submitting |

### 3.9 Cancel Link
| Element | Description |
|---|---|
| **Text link** | "Cancel" (returns to Stay Detail) |

---

## 4. State Handling

### 4.1 Local State (UI)
| State | Type | Default |
|---|---|---|
| `stayId` | uuid | from route |
| `stay` | Stay? | from previous screen (or fetch) |
| `checkIn` | Date? | null (or from previous selection) |
| `checkOut` | Date? | null |
| `guests` | int | 1 |
| `message` | string | "" |
| `isSubmitting` | bool | false |
| `isSubmitted` | bool | false |
| `errors` | Map | {} |

### 4.2 Derived State
| State | Calculation |
|---|---|
| `nights` | checkOut - checkIn (in days) |
| `estimatedMin` | nights × stay.price_per_night_min |
| `estimatedMax` | nights × stay.price_per_night_max |
| `isValid` | checkIn && checkOut && guests > 0 && guests ≤ max |

### 4.3 State Transitions
```
[Screen Load]
  → fetch stay summary (or use cached from previous screen)
  → pre-fill dates if passed from Stay Detail
  → isSubmitting = false

[Date Selection]
  → open calendar modal
  → on confirm → update checkIn / checkOut
  → recalculate nights and estimate

[Guest Change]
  → update guests
  → validate against max

[Message Input]
  → update message
  → validate character limit

[Submit Tap]
  → if not valid → show errors, stop
  → isSubmitting = true
  → call API: create booking_request_stay
  → on success → isSubmitted = true, show confirmation
  → on error → show error message, isSubmitting = false

[Cancel Tap]
  → pop back to Stay Detail
```

---

## 5. User Inputs

| Input | Action | Validation |
|---|---|---|
| Tap check-in | Open calendar modal | Required |
| Tap check-out | Open calendar modal | Required, must be > check-in |
| Tap +/- guests | Increment/decrement | 1 ≤ guests ≤ max |
| Type message | Update text | Optional, max 500 chars |
| Tap "Send Request" | Submit form | All validations pass |
| Tap "Cancel" | Return to Stay Detail | - |

---

## 6. Data Outputs

### 6.1 Read Operations
| Data | Source | RLS |
|---|---|---|
| Stay summary | `stay` table (or cached) | Public read |
| Host summary | `host` + `profile` tables | Public read |

### 6.2 Write Operations
| Data | Table | RLS |
|---|---|---|
| Booking request | `booking_request_stay` | Owner write |

**Created Record:**
```json
{
  "id": "uuid",
  "user_id": "current_user_id",
  "stay_id": "uuid",
  "check_in": "2026-03-15",
  "check_out": "2026-03-19",
  "guests": 2,
  "message": "Looking forward to staying...",
  "status": "sent",
  "created_at": "timestamp"
}
```

---

## 7. Agent Usage

### 7.1 BookingRequestAgent
**When called:**
- On form submit (validation + price estimate)

**Input (from AGENT_CONTRACTS.md):**
```json
{
  "stay_id": "uuid",
  "user_id": "uuid",
  "check_in": "2026-03-15",
  "check_out": "2026-03-19",
  "guests": 2,
  "message": "Looking forward to..."
}
```

**Output:**
```json
{
  "valid": true,
  "issues": [],
  "estimated_total": [340, 480],
  "next_step": "submit_request",
  "confidence_level": "high",
  "cache_ttl_seconds": 0
}
```

**Usage:**
- Pre-submit validation (optional MVP)
- Can show issues before submit (e.g., "Host rarely accepts 1-night stays")
- MVP can skip agent and do basic validation client-side

---

## 8. API Calls

### 8.1 Supabase Direct (RLS)
| Endpoint | Method | Purpose |
|---|---|---|
| `stay` | SELECT | Fetch stay summary (if not cached) |
| `booking_request_stay` | INSERT | Create booking request |

### 8.2 Edge Functions (Optional)
| Function | Purpose |
|---|---|
| `validate_booking_request` | Pre-submit validation via BookingRequestAgent |
| `notify_host` | Trigger push notification to host |

### 8.3 Notification Trigger
**On successful request creation:**
1. Realtime subscription notifies host app
2. Push notification: "New booking request from [Guest Name]"
3. Email (optional MVP)

---

## 9. Confirmation View (Post-Submit)

After successful submission, replace form with confirmation:

### 9.1 Confirmation UI
| Element | Description |
|---|---|
| **Success icon** | Checkmark animation |
| **Title** | "Request Sent!" |
| **Message** | "Maria will review your request and respond soon." |
| **Request summary** | Dates, guests, estimated total |
| **Status badge** | "Pending" |
| **Expected response** | "Hosts usually respond within 24 hours" |

### 9.2 Confirmation Actions
| Element | Description |
|---|---|
| **Primary CTA** | "View My Requests" → navigate to profile/requests |
| **Secondary** | "Continue Exploring" → navigate to /explore |
| **Back blocked** | Prevent accidental re-submit (replace route) |

---

## 10. Edge Cases

### 10.1 Validation Errors
| Condition | Behavior |
|---|---|
| No check-in date | Highlight field, show "Select check-in date" |
| No check-out date | Highlight field, show "Select check-out date" |
| Check-out ≤ check-in | Show "Check-out must be after check-in" |
| Guests = 0 | Disable decrement, show min 1 |
| Guests > max | Disable increment, show "Max X guests" |
| Message too long | Show character count, block input at 500 |

### 10.2 Loading States
| Condition | Behavior |
|---|---|
| Submitting | Disable button, show spinner |
| Slow network | Keep spinner, no timeout (or 30s max) |

### 10.3 Submission Errors
| Condition | Behavior |
|---|---|
| Network error | Show "Connection error. Please try again." + retry button |
| Stay unavailable | Show "This stay is no longer available." + back |
| User session expired | Redirect to login with return URL |
| Duplicate request | Show "You already have a pending request for this stay." |

### 10.4 Offline
| Condition | Behavior |
|---|---|
| User offline | Block submit, show "Connection required" |
| Reconnect | Enable submit button |

### 10.5 Date Edge Cases
| Condition | Behavior |
|---|---|
| Past date selected | Block selection in calendar |
| Same-day check-in | Allow (if host permits) or block |
| Very long stay (30+ days) | Allow, but maybe warn |

### 10.6 Navigation Edge Cases
| Condition | Behavior |
|---|---|
| Back after submit | Show confirmation, not form |
| Deep link to this screen | Redirect to Stay Detail first |
| Stay deleted while on form | Show error on submit |

---

## 11. Accessibility

- Form fields have labels and error messages
- Calendar is keyboard navigable
- Stepper has accessible increment/decrement buttons
- Submit button has loading announcement
- Confirmation is screen reader friendly

---

## 12. Analytics Events (MVP)

| Event | Payload |
|---|---|
| `booking_request_form_opened` | `stay_id`, `host_id` |
| `booking_request_dates_selected` | `stay_id`, `check_in`, `check_out`, `nights` |
| `booking_request_guests_changed` | `stay_id`, `guests` |
| `booking_request_message_entered` | `stay_id`, `has_message: bool` |
| `booking_request_submitted` | `stay_id`, `host_id`, `nights`, `guests` |
| `booking_request_success` | `stay_id`, `request_id` |
| `booking_request_error` | `stay_id`, `error_type` |

---

## 13. Security Checklist

- [x] User must be authenticated
- [x] Stay ID validated server-side
- [x] User can only create requests for themselves
- [x] Message input sanitized
- [x] No payment data collected
- [x] Rate limiting on submits (prevent spam)
- [x] Duplicate request prevention

---

## 14. Design Decisions (APPROVED)

Form-specific:
1. **Full-screen calendar modal**: Better mobile UX than inline picker
2. **Stepper for guests**: More intuitive than dropdown on mobile
3. **Expectations banner**: Clear "no payment" messaging
4. **Replace form with confirmation**: Prevent re-submit on back
5. **Optional message**: Don't force users to write

---

## 15. Related Screens

| Screen | Relationship |
|---|---|
| Stay Detail | Entry point (CTA tap) |
| Profile / My Requests | Post-submit destination |
| Explore | "Continue Exploring" destination |
| Login | Redirect if not authenticated |
| Host Dashboard | Receives notification |

---

## 16. Request Status Flow

```
[sent] → User submitted, waiting for host
    ↓
[accepted] → Host approved
    → User sees: "Request accepted! Contact host to arrange payment."
    ↓
[rejected] → Host declined
    → User sees: "Request declined by host."
    ↓
[canceled] → User canceled before response
    → User sees: "You canceled this request."
```

---

## Approval Checklist

- [ ] Purpose clear
- [ ] Form fields complete
- [ ] Validation rules defined
- [ ] No payment logic (MVP)
- [ ] Confirmation view defined
- [ ] Edge cases covered
- [ ] Security verified

---

**Status: AWAITING APPROVAL**
