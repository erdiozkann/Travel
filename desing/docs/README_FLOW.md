# Travel App — Clean Stitch Pack

Bu paket, Stitch export’unu **MVP’de kullanılacak şekilde temizlenmiş** ve **tek bir ürün akışı** olacak biçimde düzenlenmiş halidir.

## 1) Klasörler

- `01_customer_core/` → Müşteri uygulamasında **build edilecek** çekirdek ekranlar
- `02_host_core/` → Ev sahibi/işletme tarafı (host) ekranları
- `03_admin_core/` → Platform admin ekranları
- `99_archive_variants/` → Kullanılmayan/tekrarlı/deneme ekranlar (silmek istemezsen arşiv)

## 2) Tek Parça Ürün Akışı (Customer)

Önerilen ana akış:

1. **Main Map View** (`main_map_view_-_light`)
2. **Explore / List** (`explore_hub_-_light`)
3. **Detail**
   - Experience (`experience_details_-_light`)
   - Stay Listing (`stay_listings_discovery`)
   - Stay Detail (`stay_detail_view`)
4. **Action**
   - Stay booking request (`send_booking_request`)
   - Experience booking CTA (detail içinde)
5. **AI Plan** (`ai_trip_planner_-_light`)
6. **Create Post / Check-in** (`create_post_-_light`)
7. **Feed** (`community_feed_-_light`)
8. **Profile** (`user_profile_-_light`)

## 3) Host Akışı

- Host profile & trust (`host_profile_&_trust_center`)
- Stays management (`stays_management_list`)
- Business dashboard (`business_dashboard_-_light`)

## 4) Admin Akışı

- Admin panel (`admin_panel_-_light`)
- Stay & host detail admin view (`stay_&_host_detail_admin_view`)

## 5) Neyi Neden Seçtik?

- `*-_light` ekranları aynı görsel dilde olduğundan **tutarlılık** sağlıyor.
- Aynı ekranların `_1/_2/_3` varyantları arşive alındı.
- Konaklama (stay) + host + admin ekranları artık aynı paket içinde.

## 6) Sonraki Adım

İstersen bir sonraki iterasyonda:
- Sponsorlu (Sponsored) badge standardizasyonu
- “Verified guest / verified host” etiketlerinin tek component’e bağlanması
- Experience vs Stay kart ayrımının daha net hale getirilmesi

yapılabilir.
