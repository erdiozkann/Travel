-- Barcelona Real Businesses Seed Data
-- Experiences table columns: id (UUID), city_id, title, description, price_min, price_max, 
--                           duration_minutes, rating, is_sponsored, is_active, local_score, status

-- =====================================================
-- STEP 1: Insert Barcelona City
-- =====================================================
INSERT INTO cities (id, name, country_code, lat, lng)
VALUES (
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Barcelona',
  'ES',
  41.3851,
  2.1734
)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 20 REAL BARCELONA EXPERIENCES (Using proper UUIDs)
-- =====================================================

-- 1. Disfrutar - World's #1 Restaurant 2024
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000001',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Disfrutar - Tasting Menu Experience',
  'World''s #1 Restaurant 2024. Three Michelin stars. Creative Mediterranean cuisine by award-winning chefs.',
  220, 350, 180, 4.9, false, true, 0.4, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 2. Cinc Sentits - 2 Michelin Star
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000002',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Cinc Sentits - Modern Catalan Cuisine',
  'Two Michelin star restaurant offering refined interpretation of Catalan cuisine.',
  130, 180, 150, 4.8, false, true, 0.7, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 3. La Boqueria Market Tour
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000003',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'La Boqueria Food Market Tour',
  'Explore Barcelona''s most famous food market with a local guide. Sample fresh seafood, Iberian ham, and local cheeses.',
  45, 65, 120, 4.7, false, true, 0.9, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 4. El Xampanyet Tapas
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000004',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'El Xampanyet - Authentic Tapas Experience',
  'A beloved local institution since 1929. Famous for house cava and traditional tapas like anchovies and manchego.',
  20, 35, 90, 4.6, false, true, 0.95, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 5. Restaurant Pla
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000005',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Restaurant Pla - Gothic Quarter Dining',
  'Hidden gem in Gothic Quarter offering creative Mediterranean fusion. Intimate atmosphere with exposed stone walls.',
  40, 65, 120, 4.7, false, true, 0.85, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 6. Can Culleretes (Oldest restaurant 1786)
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000006',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Can Culleretes - Historic Catalan Restaurant',
  'Barcelona''s oldest restaurant serving traditional Catalan dishes since 1786. Try the escudella.',
  25, 45, 90, 4.5, false, true, 0.88, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 7. Nomad Coffee Lab
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000007',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Nomad Coffee Lab - Specialty Coffee',
  'Award-winning specialty coffee roastery and cafe in El Born. Expert baristas and single-origin beans.',
  4, 12, 45, 4.8, false, true, 0.92, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 8. Federal Cafe
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000008',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Federal Cafe - Best Brunch in Barcelona',
  'Australian-style cafe famous for legendary brunch. Fresh pastries, avocado toast, and rooftop terrace.',
  15, 28, 75, 4.6, false, true, 0.78, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 9. Satan's Coffee Corner
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000009',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Satan''s Coffee Corner - Industrial Coffee',
  'Edgy specialty coffee shop with industrial decor in Gothic Quarter. Favorite among design community.',
  3, 8, 30, 4.7, false, true, 0.94, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 10. Maison Coffee
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000010',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Maison Coffee - French Patisserie',
  'Charming French-style patisserie. Famous for beautiful latte art, fresh croissants, and exquisite pastries.',
  6, 15, 45, 4.6, false, true, 0.75, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 11. Sagrada Familia Tour (Sponsored)
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000011',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Sagrada Família Skip-the-Line Tour',
  'Skip the long lines and explore Gaudí''s masterpiece with an expert guide. Includes tower access. UNESCO World Heritage.',
  55, 75, 120, 4.9, true, true, 0.5, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 12. Park Güell Tour
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000012',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Park Güell Guided Tour with Panoramic Views',
  'Explore Gaudí''s whimsical park with guaranteed entrance. See the famous dragon fountain and mosaic benches.',
  35, 50, 90, 4.8, false, true, 0.55, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 13. Gothic Quarter Walking Tour
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000013',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Gothic Quarter Walking Tour - Hidden Secrets',
  'Discover 2000 years of history in Barcelona''s medieval heart. Roman ruins, medieval streets, and local stories.',
  25, 35, 150, 4.7, false, true, 0.88, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 14. Flamenco Show
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000014',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Authentic Flamenco Show with Tapas Dinner',
  'Experience passionate flamenco at Barcelona''s premier tablao. World-class dancers, guitarists, and singers.',
  45, 85, 90, 4.6, false, true, 0.6, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 15. Moco Museum
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000015',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Moco Museum - Banksy, Warhol & Digital Art',
  'Contemporary art museum featuring Banksy, Warhol, Dalí, and immersive digital art in a 16th-century palace.',
  16, 22, 120, 4.5, false, true, 0.65, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 16. Montjuïc Cable Car
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000016',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Montjuïc Cable Car - Panoramic City Views',
  'Soar above Barcelona on the historic cable car. Incredible 360° views of the city, port, and Mediterranean.',
  14, 20, 60, 4.7, false, true, 0.7, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 17. Sunset Sailing
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000017',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Sunset Sailing Experience with Cava',
  'Private or small group sailing along Barcelona''s coast. Watch the sunset with cava and local snacks.',
  65, 120, 120, 4.8, false, true, 0.72, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 18. Paddleboard Adventure
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000018',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Paddle Board Adventure at Barceloneta',
  'Learn to paddleboard with certified instructors on Barcelona''s famous beach. All equipment included.',
  35, 55, 90, 4.6, false, true, 0.82, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 19. Shôko Barcelona Beach Club
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000019',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Shôko Barcelona - Beach Club Experience',
  'Iconic beachfront club voted 7th Best Club in the World 2025. Restaurant by day, legendary nightclub by night.',
  25, 60, 240, 4.4, false, true, 0.58, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- 20. Jamboree Jazz Club
INSERT INTO experiences (id, city_id, title, description, price_min, price_max, duration_minutes, rating, is_sponsored, is_active, local_score, status)
VALUES (
  'a1b2c3d4-e5f6-4a1b-8c2d-100000000020',
  'b8e9d4a1-5c3f-4e2d-8a7b-1c9f0d6e3b5a',
  'Jamboree Jazz Club - Live Jazz Night',
  'Barcelona''s legendary jazz club since 1960. Live performances every night. Where Chet Baker once played.',
  12, 25, 150, 4.7, false, true, 0.9, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- DONE: 20 Real Barcelona experiences added!
-- =====================================================
