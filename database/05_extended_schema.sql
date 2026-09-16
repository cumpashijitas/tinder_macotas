-- ==============================================================================
-- 05_extended_schema.sql: Extensión del esquema para casos de uso completos
-- ==============================================================================

-- 1. Moderación y geolocalización de mascotas
ALTER TABLE public.pets
    ADD COLUMN IF NOT EXISTS moderation_status TEXT CHECK (moderation_status IN ('pending', 'approved', 'rejected')) NOT NULL DEFAULT 'approved',
    ADD COLUMN IF NOT EXISTS moderation_notes TEXT,
    ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- 2. Historias de Adopción ("Finales Felices")
CREATE TABLE IF NOT EXISTS public.adoption_stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES public.matches(id) ON DELETE SET NULL,
    author_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    pet_name TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.story_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id UUID REFERENCES public.adoption_stories(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(story_id, user_id)
);

-- 3. Contratos de Adopción (firma digital de ambas partes)
CREATE TABLE IF NOT EXISTS public.adoption_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE UNIQUE NOT NULL,
    adopter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    shelter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    terms_version TEXT NOT NULL DEFAULT 'v1',
    signed_by_adopter BOOLEAN NOT NULL DEFAULT FALSE,
    signed_by_adopter_at TIMESTAMP WITH TIME ZONE,
    signed_by_shelter BOOLEAN NOT NULL DEFAULT FALSE,
    signed_by_shelter_at TIMESTAMP WITH TIME ZONE,
    signature_hash TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Solicitudes de Visita (agendadas desde el chat de un match)
CREATE TABLE IF NOT EXISTS public.visit_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE NOT NULL,
    requested_by UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    proposed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT CHECK (status IN ('pending', 'confirmed', 'declined', 'completed', 'cancelled')) NOT NULL DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_pets_moderation_status ON public.pets(moderation_status);
CREATE INDEX IF NOT EXISTS idx_stories_author ON public.adoption_stories(author_id);
CREATE INDEX IF NOT EXISTS idx_stories_match ON public.adoption_stories(match_id);
CREATE INDEX IF NOT EXISTS idx_story_likes_story ON public.story_likes(story_id);
CREATE INDEX IF NOT EXISTS idx_contracts_match ON public.adoption_contracts(match_id);
CREATE INDEX IF NOT EXISTS idx_visits_match ON public.visit_requests(match_id);
