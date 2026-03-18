# Environment Configuration (MVP)
Environment variables for Flutter client and Supabase Edge Functions

---

## Overview

| Environment | Purpose |
|---|---|
| **Development** | Local development |
| **Staging** | Testing before production |
| **Production** | Live app |

---

## Flutter Client

### Required Variables

| Variable | Description | Example |
|---|---|---|
| `SUPABASE_URL` | Supabase project URL | `https://xxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase anonymous/public key | `eyJhbGciOiJIUzI1...` |

### Optional Variables

| Variable | Description | Default |
|---|---|---|
| `GOOGLE_MAPS_API_KEY` | Google Maps SDK key | - |
| `SENTRY_DSN` | Error tracking DSN | - |
| `ANALYTICS_ID` | Analytics identifier | - |

### Flutter Configuration

**Option 1: Dart Define (Recommended)**
```bash
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJ...
```

**Option 2: .env file with flutter_dotenv**
```
# .env.development
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

**⚠️ Security Note:**
- Never commit `.env` files with real keys
- Use `.env.example` as template
- Add `.env*` to `.gitignore`

---

## Supabase Edge Functions

### Required Secrets

| Variable | Description | Where Used |
|---|---|---|
| `STRIPE_SECRET_KEY` | Stripe API secret key | create_experience_checkout |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret | stripe_webhook_handler |
| `APP_BASE_URL` | App base URL for deep links | Checkout redirects |
| `AI_PROVIDER` | AI provider selection | Agent orchestration |

### Setting Secrets

```bash
# Set secrets via Supabase CLI
supabase secrets set STRIPE_SECRET_KEY=sk_live_xxx
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxx
supabase secrets set APP_BASE_URL=https://yourapp.com
supabase secrets set AI_PROVIDER=gemini
```

### List Secrets
```bash
supabase secrets list
```

---

## Environment-Specific Values

### Development
```env
# Flutter (.env.development)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...dev...

# Edge Functions (set via CLI)
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_test_xxx
APP_BASE_URL=http://localhost:3000
AI_PROVIDER=gemini
```

### Staging
```env
# Flutter (.env.staging)
SUPABASE_URL=https://xxx-staging.supabase.co
SUPABASE_ANON_KEY=eyJ...staging...

# Edge Functions
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_test_xxx
APP_BASE_URL=https://staging.yourapp.com
AI_PROVIDER=gemini
```

### Production
```env
# Flutter (.env.production)
SUPABASE_URL=https://xxx-prod.supabase.co
SUPABASE_ANON_KEY=eyJ...prod...

# Edge Functions
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_live_xxx
APP_BASE_URL=https://yourapp.com
AI_PROVIDER=opus
```

---

## Stripe Configuration

### Test Mode Keys
| Key Type | Prefix | Use |
|---|---|---|
| Publishable | `pk_test_` | Client-side (public) |
| Secret | `sk_test_` | Server-side (secret) |
| Webhook | `whsec_` | Webhook verification |

### Live Mode Keys
| Key Type | Prefix | Use |
|---|---|---|
| Publishable | `pk_live_` | Client-side (public) |
| Secret | `sk_live_` | Server-side (secret) |
| Webhook | `whsec_` | Webhook verification |

### Webhook Endpoints
```
Development: https://xxx.supabase.co/functions/v1/stripe_webhook
Staging:     https://xxx-staging.supabase.co/functions/v1/stripe_webhook
Production:  https://xxx-prod.supabase.co/functions/v1/stripe_webhook
```

---

## AI Provider Configuration

### Available Providers

| Provider | Value | Description |
|---|---|---|
| Gemini | `gemini` | Gemini 3 Pro High |
| Opus | `opus` | Claude Opus (Antigravity) |

### Provider-Specific Config (Future)
```env
# If needed, add provider-specific keys
GEMINI_API_KEY=xxx
ANTHROPIC_API_KEY=xxx
```

---

## Google Maps Configuration

### Flutter Setup
```dart
// android/app/src/main/AndroidManifest.xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}"/>

// ios/Runner/AppDelegate.swift
GMSServices.provideAPIKey(Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as! String)
```

### API Restrictions (Recommended)
- Restrict to package name (Android)
- Restrict to bundle ID (iOS)
- Enable only Maps SDK APIs

---

## File Templates

### .env.example
```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Google Maps
GOOGLE_MAPS_API_KEY=your-maps-key

# Error Tracking (optional)
SENTRY_DSN=your-sentry-dsn
```

### .gitignore additions
```gitignore
# Environment files
.env
.env.*
!.env.example

# Supabase secrets
supabase/.env
```

---

## Validation Checklist

Before deployment, verify:

### Flutter Client
- [ ] `SUPABASE_URL` is set
- [ ] `SUPABASE_ANON_KEY` is set
- [ ] `GOOGLE_MAPS_API_KEY` is set (if using maps)
- [ ] Keys match environment (dev/staging/prod)

### Edge Functions
- [ ] `STRIPE_SECRET_KEY` is set
- [ ] `STRIPE_WEBHOOK_SECRET` is set
- [ ] `APP_BASE_URL` is correct
- [ ] `AI_PROVIDER` is set
- [ ] Webhook endpoints configured in Stripe dashboard

### Supabase Project
- [ ] Auth providers configured
- [ ] Storage buckets created
- [ ] RLS policies active
- [ ] Edge functions deployed

---

## Troubleshooting

| Issue | Check |
|---|---|
| Auth not working | Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` |
| Stripe checkout fails | Check `STRIPE_SECRET_KEY` environment |
| Webhook not processing | Verify `STRIPE_WEBHOOK_SECRET` matches dashboard |
| Deep links broken | Check `APP_BASE_URL` configuration |
| AI not responding | Verify `AI_PROVIDER` and provider credentials |

---

**Status: FINAL**
