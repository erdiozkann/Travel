-- Create experience_ai_cache table
CREATE TABLE IF NOT EXISTS public.experience_ai_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experience_id UUID REFERENCES public.experiences(id) ON DELETE CASCADE,
    ai_summary TEXT,
    local_tips JSONB,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS
ALTER TABLE public.experience_ai_cache ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Users can view ai cache" ON public.experience_ai_cache FOR SELECT USING (true);


-- Verileri Guncelle
UPDATE public.cities SET media_urls = ARRAY['https://images.unsplash.com/photo-1583422409516-2895a77ef244?auto=format&fit=crop&q=80&w=800'] WHERE id = '830cc17f-7a42-4f36-8aed-95fcd7db5092'; 
UPDATE public.cities SET media_urls = ARRAY['https://images.unsplash.com/photo-1543783207-ec64e4d95325?auto=format&fit=crop&q=80&w=800'] WHERE id = '7db8f1d5-7e8c-4a30-8a1f-88da15b2e8fc';
UPDATE public.cities SET media_urls = ARRAY['https://images.unsplash.com/photo-1522083111810-72c2194a28bb?auto=format&fit=crop&q=80&w=800'] WHERE id = '5f4e6d42-ab2a-4bc4-b7e6-76cd961cc2fd';

UPDATE public.stays SET media_urls = ARRAY['https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=800', 'https://images.unsplash.com/photo-1502672260266-1c1de2d92004?auto=format&fit=crop&q=80&w=800'];
UPDATE public.experiences SET media_urls = ARRAY['https://images.unsplash.com/photo-1517400508447-f8dd518b86db?auto=format&fit=crop&q=80&w=800', 'https://images.unsplash.com/photo-1513151233558-d860c5398176?auto=format&fit=crop&q=80&w=800'];
