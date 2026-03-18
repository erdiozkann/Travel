## Temel Varlıklar (Entities)
- User
- Profile
- City
- Place (restoran/bar/otel/sinema vb.)
- Experience (tur/kurs/aktivite/workshop vb.)
- Post (sosyal paylaşım)
- Check-in (konumlu paylaşım)
- Booking (satın alma/rezervasyon)
- Review (yalnızca booking ile)
- Sponsorship (performans bazlı öne çıkarma)
- Follow / Like / Comment

## Ana İlişkiler
- City 1—N Place
- City 1—N Experience
- Place 1—N Experience (opsiyonel; deneyim bir mekâna bağlı olabilir)
- Post N—1 Profile
- Post 0..1—1 Experience (post bir deneyime tag’lenebilir)
- Post 0..1—1 Place (post bir mekâna tag’lenebilir)
- Check-in N—1 Post (check-in bir postun konum bilgisidir)
- Review N—1 Booking (ZORUNLU) ✅
- Booking N—1 Experience (satın alınan şey)
- Sponsorship N—1 Place/Experience (öğe bazlı sponsorlu)

## Kritik Kural
- `Review` oluşturma şartı:
  - `booking.status == completed`
  - `reviews.booking_id` zorunlu
  - böylece “fake review” biter.
