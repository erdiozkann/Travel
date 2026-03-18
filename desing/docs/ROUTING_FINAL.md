# ROUTING_FINAL — Flutter (GoRouter)
Auth Guards, Bottom Nav, Deep Links

---

## 0) Routing Strategy

| Aspect | Implementation |
|---|---|
| **Router** | GoRouter |
| **Guards** | Auth, role-based (host/admin) |
| **Bottom Nav** | Core user flows |
| **Nested routes** | Details, forms |
| **Isolated stacks** | Host & Admin separate from user tabs |

---

## 1) Bottom Navigation (User)

### Tab Order (left → right)
| # | Tab | Route | Icon |
|---|---|---|---|
| 1 | Map | `/map` | 🗺️ |
| 2 | Explore | `/explore` | 🔍 |
| 3 | Planner | `/plan` | 📅 |
| 4 | Feed | `/feed` | 📱 |
| 5 | Profile | `/profile` | 👤 |

### Rules
- Preserve state per tab
- Back button returns within tab stack
- Tab tap: scroll to top if already on tab

---

## 2) Complete Route Table

### 2.1 Public Routes (No Auth)
| Route | Screen | Notes |
|---|---|---|
| `/map` | Main Map View | Bottom nav tab |
| `/explore` | Explore List View | Bottom nav tab |
| `/explore/experience/:id` | Experience Detail | Public detail |
| `/explore/stay/:id` | Stay Detail | Public detail |
| `/feed` | Community Feed | Bottom nav tab |
| `/u/:userId` | User Profile (public) | Other users |
| `/host/:hostId` | Host Profile (public) | Host info |

### 2.2 Auth Required Routes
| Route | Screen | Guard |
|---|---|---|
| `/profile` | User Profile (own) | Auth |
| `/profile/settings` | Settings | Auth |
| `/profile/plans` | My Plans | Auth |
| `/profile/saved` | Saved Items | Auth |
| `/profile/requests` | My Booking Requests | Auth |
| `/feed/create` | Create Post | Auth |
| `/plan` | AI Trip Planner | No auth (generate), auth (save) |
| `/stay/:stayId/request` | Send Booking Request | Auth |

### 2.3 Host Routes (Role: host)
| Route | Screen | Guard |
|---|---|---|
| `/host` | Host Dashboard | Auth + Host |
| `/host/trust` | Trust Center | Auth + Host |
| `/host/stays` | Stays Management | Auth + Host |
| `/host/stays/new` | Create Stay | Auth + Host |
| `/host/stays/:stayId/edit` | Edit Stay | Auth + Host |
| `/host/requests` | Booking Requests | Auth + Host |
| `/host/requests/:requestId` | Request Detail | Auth + Host |
| `/become-host` | Host Onboarding | Auth |

### 2.4 Admin Routes (Role: admin)
| Route | Screen | Guard |
|---|---|---|
| `/admin` | Redirect → /admin/dashboard | Auth + Admin |
| `/admin/dashboard` | Admin Dashboard | Auth + Admin |
| `/admin/hosts` | Host Management | Auth + Admin |
| `/admin/hosts/:hostId` | Host Detail (Admin) | Auth + Admin |
| `/admin/posts` | Post Moderation | Auth + Admin |
| `/admin/reviews` | Review Moderation | Auth + Admin |
| `/admin/brand` | Brand Settings | Auth + Admin |
| `/admin/audit` | Audit Log | Auth + Admin |

### 2.5 Auth Routes
| Route | Screen | Guard |
|---|---|---|
| `/auth/login` | Login | Guest only |
| `/auth/register` | Register | Guest only |
| `/auth/forgot` | Forgot Password | Guest only |
| `/auth/callback` | OAuth Callback | - |

### 2.6 Error Routes
| Route | Screen | Purpose |
|---|---|---|
| `/not-found` | Not Found | Unknown routes |
| `/offline` | Offline | No connection |
| `/access-denied` | Access Denied | Role mismatch |

---

## 3) Auth Guards

### 3.1 Guard Types
| Guard | Check | Redirect |
|---|---|---|
| `authGuard` | isAuthenticated | `/auth/login` |
| `hostGuard` | role == host | `/become-host` |
| `adminGuard` | role == admin | `/access-denied` |
| `guestGuard` | !isAuthenticated | `/profile` |

### 3.2 Guard Flow
```
[Route Request]
    ↓
[Check Guard]
    ├── Pass → Allow navigation
    └── Fail → Store intended route → Redirect
                    ↓
              [After Auth]
                    ↓
              [Restore intended route]
```

### 3.3 Server-Side Verification (Admin)
```
❗ Admin routes MUST verify role on EVERY request server-side.
   Client-side guard is UX only, not security.
```

---

## 4) Nested Route Stacks

### 4.1 Experience Stack
```
/explore/experience/:id
    └── (detail page)
    
/booking/success?booking_id=X
    └── (success after Stripe)
    
/booking/cancel
    └── (cancelled checkout)
```

### 4.2 Stay Stack
```
/explore/stay/:id
    └── (detail page)
    
/stay/:stayId/request
    └── (booking request form)
    
/profile/requests/:requestId
    └── (request detail)
```

### 4.3 Host Stack
```
/host
├── /host/trust
├── /host/stays
│   ├── /host/stays/new
│   └── /host/stays/:stayId/edit
└── /host/requests
    └── /host/requests/:requestId
```

### 4.4 Admin Stack
```
/admin
├── /admin/dashboard
├── /admin/hosts
│   └── /admin/hosts/:hostId
├── /admin/posts
├── /admin/reviews
├── /admin/brand
└── /admin/audit
```

---

## 5) Deep Links

### 5.1 Supported Deep Links
| Deep Link | Route | Auth Required |
|---|---|---|
| `myapp://explore/experience/:id` | Experience Detail | No |
| `myapp://explore/stay/:id` | Stay Detail | No |
| `myapp://u/:userId` | User Profile | No |
| `myapp://host/:hostId` | Host Profile | No |
| `myapp://feed/post/:postId` | Post Detail | No |
| `myapp://plan` | Trip Planner | No |
| `myapp://admin` | Admin Dashboard | Auth + Admin |

### 5.2 Deep Link Behavior
```
[Deep Link Received]
    ↓
[Parse Route]
    ↓
[Check Auth Guard]
    ├── No auth needed → Navigate
    ├── Auth needed, logged in → Navigate
    └── Auth needed, not logged in
            ↓
        [Store intent]
            ↓
        [Show login]
            ↓
        [After login → Navigate to stored intent]
```

### 5.3 Content Not Found
```
[Deep Link to /explore/experience/:id]
    ↓
[Fetch experience]
    ├── Found → Show detail
    └── Not found → Show /not-found with back option
```

---

## 6) Navigation Patterns

### 6.1 Push vs Replace
| Action | Pattern |
|---|---|
| Detail from list | Push |
| Login success | Replace |
| Post success | Pop to feed |
| Booking success | Replace (prevent back to form) |
| Tab switch | Change shell index |

### 6.2 Modal Routes
| Route | Type | Behavior |
|---|---|---|
| Report modal | Dialog | Overlay on current |
| City selector | Full-screen modal | Push with transition |
| Filter sheet | Bottom sheet | Native sheet |

### 6.3 Transitions
| Route Type | Transition |
|---|---|
| Tab switch | None (instant) |
| Push detail | Slide from right |
| Modal | Slide from bottom |
| Replace | Fade |

---

## 7) State Preservation

### 7.1 Tab State
```
Each bottom nav tab maintains its own navigation stack.
Switching tabs does NOT reset the stack.
```

### 7.2 Form State
```
Form data preserved when:
- App backgrounded
- Tab switched
- Back navigation (until submit)

Form data cleared when:
- Submit success
- Explicit discard
- App killed
```

### 7.3 Scroll Position
```
Scroll position preserved per route in stack.
Restored on back navigation.
```

---

## 8) Analytics Hooks

### 8.1 Route Events
| Event | Trigger |
|---|---|
| `screen_view` | Route enter |
| `deep_link_opened` | Deep link navigation |
| `auth_redirect` | Guard redirect to login |
| `access_denied` | Role guard rejection |

### 8.2 Event Payload
```json
{
  "route": "/explore/experience/uuid",
  "previous_route": "/explore",
  "source": "tap|deep_link|redirect",
  "timestamp": "2026-02-06T00:27:00Z"
}
```

---

## 9) Error Handling

### 9.1 Unknown Route
```
Any unknown route → /not-found
```

### 9.2 Offline Navigation
```
Offline attempt to protected write route:
    → Show offline banner
    → Block navigation to form
```

### 9.3 Session Expired
```
Protected route access with expired session:
    → Clear auth state
    → Redirect to /auth/login
    → Store intended route
```

---

## 10) Route Configuration (Pseudo-Code)

```dart
// GoRouter configuration structure
final router = GoRouter(
  initialLocation: '/map',
  redirect: globalRedirect,
  routes: [
    // Bottom Nav Shell
    StatefulShellRoute.indexedStack(
      branches: [
        StatefulShellBranch(routes: [/* /map */]),
        StatefulShellBranch(routes: [/* /explore */]),
        StatefulShellBranch(routes: [/* /plan */]),
        StatefulShellBranch(routes: [/* /feed */]),
        StatefulShellBranch(routes: [/* /profile */]),
      ],
    ),
    
    // Auth routes
    GoRoute(path: '/auth/login', ...),
    GoRoute(path: '/auth/register', ...),
    
    // Host routes (guarded)
    ShellRoute(
      redirect: hostGuard,
      routes: [/* /host/* */],
    ),
    
    // Admin routes (guarded)
    ShellRoute(
      redirect: adminGuard,
      routes: [/* /admin/* */],
    ),
    
    // Error routes
    GoRoute(path: '/not-found', ...),
    GoRoute(path: '/access-denied', ...),
  ],
);
```

---

## 11) MVP Notes

| Aspect | Status |
|---|---|
| Web routing parity | ❌ Not required |
| SSR | ❌ Not supported |
| Host/Admin isolation | ✅ Separate from user tabs |
| Deep link support | ✅ Implemented |
| State preservation | ✅ Per tab |

---

## 12) Route Summary Table

| Category | Route Count | Auth | Role |
|---|---|---|---|
| Public | 7 | ❌ | - |
| User Auth | 6 | ✅ | - |
| Host | 7 | ✅ | host |
| Admin | 8 | ✅ | admin |
| Auth | 4 | ❌ | - |
| Error | 3 | ❌ | - |
| **Total** | **35** | - | - |

---

**Status: AWAITING APPROVAL**
