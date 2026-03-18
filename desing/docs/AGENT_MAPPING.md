# Agent Mapping (AI + Otomasyon)

Bu dosya, ileride Antigravity/Gemini ajanlarını bağlarken hangi ekranın hangi ajan çıktısını (output) gösterdiğini ve hangi girdileri (input) topladığını özetler.

## Customer Core

### 1) `main_map_view_-_light`
- **Input:** konum (şehir/ülke), filtreler (kategori, fiyat, rating, local/tourist)
- **Output:** harita pinleri, yakın öneriler
- **Ajanlar:**
  - `CityResearchAgent` (pin/yer verisi)
  - `RankingAgent` (sıralama/öncelik)
  - `PricingAgent` (fiyat bandı)

### 2) `explore_hub_-_light`
- **Input:** filtreler, arama terimi
- **Output:** liste kartları + etiketler
- **Ajanlar:**
  - `DiscoveryAgent`
  - `PersonalizationAgent` (profil bazlı öneri)

### 3) `experience_details_-_light`
- **Input:** seçilen deneyim
- **Output:** özet, fiyat, uygunluk, CTA
- **Ajanlar:**
  - `ExperienceSummaryAgent` (AI summary + confidence)
  - `PolicyAgent` (iptal/iade kuralları)

### 4) `stay_listings_discovery` + `stay_detail_view`
- **Input:** tarih aralığı, kişi sayısı, filtreler
- **Output:** konaklama listesi/detayı
- **Ajanlar:**
  - `StayDiscoveryAgent`
  - `TrustAgent` (verified host / risk sinyali)

### 5) `send_booking_request`
- **Input:** check-in/out, guest count, mesaj
- **Output:** talep özeti + gönderim
- **Ajanlar:**
  - `BookingRequestAgent` (validasyon + fiyat tahmini)

### 6) `ai_trip_planner_-_light`
- **Input:** gün sayısı, bütçe, ilgi alanı
- **Output:** günlük plan + kartlar
- **Ajanlar:**
  - `TripPlannerAgent`
  - `RouteAgent` (mesafe / rota önerisi)

### 7) `create_post_-_light`
- **Input:** foto/video, konum, place tag, caption
- **Output:** paylaşım
- **Ajanlar:**
  - `ContentSafetyAgent` (moderasyon)
  - `PlaceTagAgent` (yakındaki yer eşleştirme)

### 8) `community_feed_-_light`
- **Input:** takipler, ilgi alanları
- **Output:** feed + sponsored ayrımı
- **Ajanlar:**
  - `FeedRankingAgent`
  - `AdsEligibilityAgent` (sponsorlu etiketi)

### 9) `user_profile_-_light`
- **Input:** kullanıcı tercihleri, takipler
- **Output:** ziyaret edilen şehirler, kayıtlar, postlar
- **Ajanlar:**
  - `ProfileInsightsAgent`

## Host Core

### `host_profile_&_trust_center`
- **Input:** host kimlik/doğrulama verileri
- **Output:** güven rozetleri, performans özeti
- **Ajanlar:** `HostTrustAgent`, `KYCFlowAgent`

### `stays_management_list`
- **Input:** ilan düzenleme, fiyat bandı, müsaitlik
- **Output:** ilan listesi + durum
- **Ajanlar:** `ListingQualityAgent`, `AvailabilityAgent`

### `business_dashboard_-_light`
- **Input:** tarih aralığı
- **Output:** gelir, talep, dönüşüm, performans
- **Ajanlar:** `HostAnalyticsAgent`

## Admin Core

### `admin_panel_-_light`
- **Output:** sistem metrikleri, raporlar, onay bekleyenler
- **Ajanlar:** `AdminInsightsAgent`

### `stay_&_host_detail_admin_view`
- **Output:** detay inceleme + aksiyonlar
- **Ajanlar:** `ModerationDecisionAgent`, `FraudRiskAgent`
