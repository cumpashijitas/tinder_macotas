-- ==============================================================================
-- 01_schema.sql: Esquema Principal de Base de Datos para PetMatch
-- ==============================================================================

-- 1. Tabla de Perfiles (Extiende los usuarios de auth.users de Supabase)
-- Soporta 3 tipos de usuario: Adoptante, Refugio Institucional y Particular con Camada/Rescatista
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT NOT NULL,
    phone TEXT,
    role TEXT CHECK (role IN ('adopter', 'shelter', 'individual_rescuer', 'admin')) DEFAULT 'adopter',
    organization_name TEXT, -- Opcional: Nombre del refugio u ONG si aplica
    avatar_url TEXT,
    address TEXT,
    is_verified BOOLEAN DEFAULT FALSE, -- Verificación de identidad / refugio
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Formulario Riguroso de Aptitud de Adopción (Cuestionario del adoptante)
CREATE TABLE IF NOT EXISTS public.adopter_forms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
    -- Datos de Vivienda
    housing_type TEXT CHECK (housing_type IN ('house', 'apartment', 'farm', 'other')) NOT NULL,
    housing_status TEXT CHECK (housing_status IN ('owned', 'rented_allowed', 'rented_pending_permission')) NOT NULL,
    has_yard BOOLEAN NOT NULL DEFAULT FALSE,
    has_protective_netting BOOLEAN NOT NULL DEFAULT FALSE,
    -- Composición del Hogar y Rutina
    household_members TEXT CHECK (household_members IN ('alone', 'couple', 'family_with_young_kids', 'family_with_teens', 'roommates')) NOT NULL,
    all_members_agree BOOLEAN NOT NULL DEFAULT TRUE,
    has_allergies BOOLEAN NOT NULL DEFAULT FALSE,
    hours_pet_alone_per_day INT NOT NULL CHECK (hours_pet_alone_per_day BETWEEN 0 AND 24),
    -- Experiencia e Historial con Mascotas
    has_other_pets BOOLEAN NOT NULL DEFAULT FALSE,
    other_pets_details TEXT,
    previous_pet_experience TEXT,
    -- Compromiso Financiero y Legal
    monthly_budget_confirmed BOOLEAN NOT NULL DEFAULT TRUE,
    emergency_fund_available BOOLEAN NOT NULL DEFAULT TRUE,
    agrees_to_follow_up BOOLEAN NOT NULL DEFAULT TRUE,
    agrees_to_mandatory_neutering BOOLEAN NOT NULL DEFAULT TRUE,
    -- Estado de Evaluación
    evaluation_status TEXT CHECK (evaluation_status IN ('pending', 'approved', 'requires_interview', 'rejected')) DEFAULT 'pending',
    evaluation_score NUMERIC(5, 2) DEFAULT 0.0,
    reviewer_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Tabla de Mascotas en Adopción (Formulario Integral y Salud)
CREATE TABLE IF NOT EXISTS public.pets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shelter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL, -- ID del publicador (refugio o particular)
    publisher_type TEXT CHECK (publisher_type IN ('shelter', 'individual_rescuer')) NOT NULL DEFAULT 'shelter',
    name TEXT NOT NULL,
    species TEXT CHECK (species IN ('dog', 'cat', 'other')) NOT NULL,
    breed TEXT DEFAULT 'Mestizo',
    age_years NUMERIC(3, 1) NOT NULL,
    gender TEXT CHECK (gender IN ('male', 'female')) NOT NULL,
    size TEXT CHECK (size IN ('small', 'medium', 'large', 'giant')) NOT NULL,
    energy_level INT CHECK (energy_level BETWEEN 1 AND 5) NOT NULL,
    
    -- Origen y Camadas
    origin TEXT CHECK (origin IN ('home_litter', 'street_rescue', 'shelter_born', 'relinquished')) DEFAULT 'street_rescue',
    is_litter BOOLEAN DEFAULT FALSE,
    birth_date DATE,
    weaning_completed BOOLEAN DEFAULT TRUE, -- Mínimo 60 días para cachorros
    
    -- Plan Sanitario y Específico por Sexo
    is_vaccinated BOOLEAN NOT NULL DEFAULT TRUE,
    vaccines_applied TEXT[] NOT NULL DEFAULT '{}', -- Ej: ARRAY['Antirrábica', 'Séxtuple / Óctuple', 'Triple Felina']
    dewormed_internal BOOLEAN NOT NULL DEFAULT TRUE,
    dewormed_external BOOLEAN NOT NULL DEFAULT TRUE, -- Pipeta antipulgas/garrapatas
    has_microchip BOOLEAN NOT NULL DEFAULT FALSE,
    is_neutered BOOLEAN NOT NULL DEFAULT TRUE,
    reproductive_status TEXT CHECK (reproductive_status IN ('neutered', 'spayed', 'requires_spay_agreement', 'intact')) NOT NULL DEFAULT 'neutered',
    
    -- Hábitos y Comportamiento
    house_trained BOOLEAN NOT NULL DEFAULT TRUE, -- Acostumbrado a hacer afuera o en arenero
    good_with_dogs BOOLEAN DEFAULT TRUE,
    good_with_cats BOOLEAN DEFAULT TRUE,
    good_with_kids BOOLEAN DEFAULT TRUE,
    requires_yard BOOLEAN DEFAULT FALSE,
    storm_anxiety INT CHECK (storm_anxiety BETWEEN 1 AND 5) DEFAULT 1, -- Nivel de miedo a tormentas / pirotecnia
    special_needs TEXT,
    story TEXT NOT NULL,
    
    -- Requisitos exigidos por el publicador para entregar la mascota
    requires_adoption_contract BOOLEAN DEFAULT TRUE,
    requires_home_check BOOLEAN DEFAULT FALSE,
    requires_followup_photos BOOLEAN DEFAULT TRUE,
    delivery_type TEXT CHECK (delivery_type IN ('pickup_at_shelter', 'home_delivery', 'to_be_agreed')) DEFAULT 'to_be_agreed',
    
    photos TEXT[] NOT NULL DEFAULT '{}',
    status TEXT CHECK (status IN ('available', 'paused', 'in_process', 'adopted')) DEFAULT 'available',
    relocation_reason TEXT, -- Motivo justificado en caso excepcional de mudanza o fuerza mayor
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Registro de Swipes (Interacciones tipo Tinder)
CREATE TABLE IF NOT EXISTS public.swipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    adopter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE NOT NULL,
    direction TEXT CHECK (direction IN ('left', 'right', 'superlike')) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(adopter_id, pet_id)
);

-- 5. Tabla de Matches y Solicitudes de Adopción
CREATE TABLE IF NOT EXISTS public.matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID REFERENCES public.pets(id) ON DELETE CASCADE NOT NULL,
    adopter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    shelter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    status TEXT CHECK (status IN ('pending_review', 'approved_for_chat', 'interview_scheduled', 'rejected', 'adoption_finalized')) DEFAULT 'pending_review',
    shelter_comments TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(pet_id, adopter_id)
);

-- 6. Mensajes de Chat en Tiempo Real
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Índices para optimizar consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_pets_species_status ON public.pets(species, status);
CREATE INDEX IF NOT EXISTS idx_pets_publisher_type ON public.pets(publisher_type);
CREATE INDEX IF NOT EXISTS idx_swipes_adopter_pet ON public.swipes(adopter_id, pet_id);
CREATE INDEX IF NOT EXISTS idx_matches_adopter ON public.matches(adopter_id);
CREATE INDEX IF NOT EXISTS idx_matches_shelter ON public.matches(shelter_id);
CREATE INDEX IF NOT EXISTS idx_messages_match ON public.messages(match_id, created_at);
