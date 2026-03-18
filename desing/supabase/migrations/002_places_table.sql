-- ===========================================
-- PLACES TABLE - Google Places Import Storage
-- ===========================================

-- Create places table
CREATE TABLE IF NOT EXISTS public.places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Google Places Data
  google_place_id TEXT UNIQUE,
  name TEXT NOT NULL,
  formatted_address TEXT,
  
  -- Location
  lat FLOAT NOT NULL,
  lng FLOAT NOT NULL,
  city_id UUID REFERENCES public.cities(id),
  
  -- Category
  types TEXT[], -- restaurant, cafe, bar, tourist_attraction, etc.
  primary_type TEXT, -- Main category
  
  -- Details
  rating FLOAT,
  user_ratings_total INTEGER,
  price_level INTEGER, -- 0-4 (Google's pricing)
  
  -- Contact
  phone TEXT,
  website TEXT,
  
  -- Hours (simplified)
  opening_hours JSONB, -- Store raw opening hours
  
  -- Media
  photo_references TEXT[], -- Google photo references
  cover_photo_url TEXT,
  
  -- Status
  business_status TEXT, -- OPERATIONAL, CLOSED_TEMPORARILY, CLOSED_PERMANENTLY
  is_verified BOOLEAN DEFAULT FALSE,
  is_featured BOOLEAN DEFAULT FALSE,
  is_sponsored BOOLEAN DEFAULT FALSE,
  
  -- Metadata
  imported_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Source
  source TEXT DEFAULT 'google_places' -- google_places, manual, partner
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_places_city ON public.places(city_id);
CREATE INDEX IF NOT EXISTS idx_places_location ON public.places(lat, lng);
CREATE INDEX IF NOT EXISTS idx_places_types ON public.places USING GIN(types);
CREATE INDEX IF NOT EXISTS idx_places_rating ON public.places(rating DESC);
CREATE INDEX IF NOT EXISTS idx_places_google_id ON public.places(google_place_id);

-- Enable RLS
ALTER TABLE public.places ENABLE ROW LEVEL SECURITY;

-- Public read policy
CREATE POLICY "Places are publicly readable"
  ON public.places
  FOR SELECT
  TO anon, authenticated
  USING (business_status = 'OPERATIONAL' OR business_status IS NULL);

-- Admin write policy (adjust role as needed)
CREATE POLICY "Admins can manage places"
  ON public.places
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ===========================================
-- IMPORT LOG TABLE - Track imports
-- ===========================================

CREATE TABLE IF NOT EXISTS public.place_imports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city_id UUID REFERENCES public.cities(id),
  city_name TEXT,
  
  -- Import details
  search_type TEXT, -- restaurant, cafe, tourist_attraction
  radius_meters INTEGER,
  
  -- Results
  places_found INTEGER,
  places_inserted INTEGER,
  places_updated INTEGER,
  
  -- Status
  status TEXT DEFAULT 'pending', -- pending, running, completed, failed
  error_message TEXT,
  
  -- Timing
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  
  -- Who triggered
  triggered_by UUID REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE public.place_imports ENABLE ROW LEVEL SECURITY;

-- Admin only
CREATE POLICY "Admins can view import logs"
  ON public.place_imports
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ===========================================
-- UPDATE users table to have role column
-- ===========================================

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';

-- Grant yourself admin (replace with your email)
-- UPDATE public.users SET role = 'admin' WHERE email = 'your@email.com';
