-- ==============================================================================
-- 02_rls_policies.sql: Políticas de Seguridad (Row Level Security) para Supabase
-- ==============================================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adopter_forms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 1. Políticas para Profiles
CREATE POLICY "Los perfiles son visibles públicamente"
    ON public.profiles FOR SELECT
    USING (true);

CREATE POLICY "Los usuarios pueden modificar su propio perfil"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- 2. Políticas para Adopter Forms (Formulario Riguroso)
CREATE POLICY "El usuario puede ver y editar su propio formulario"
    ON public.adopter_forms FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Los refugios pueden ver formularios de adoptantes que hicieron match"
    ON public.adopter_forms FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.matches
            WHERE matches.adopter_id = public.adopter_forms.user_id
              AND matches.shelter_id = auth.uid()
        )
    );

-- 3. Políticas para Mascotas (Pets)
CREATE POLICY "Las mascotas disponibles son visibles para todos"
    ON public.pets FOR SELECT
    USING (status != 'archived');

CREATE POLICY "Los refugios pueden insertar y editar sus propias mascotas"
    ON public.pets FOR ALL
    USING (auth.uid() = shelter_id);

-- 4. Políticas para Swipes
CREATE POLICY "Los adoptantes pueden ver y registrar sus propios swipes"
    ON public.swipes FOR ALL
    USING (auth.uid() = adopter_id);

-- 5. Políticas para Matches
CREATE POLICY "Los usuarios ven los matches en los que participan"
    ON public.matches FOR SELECT
    USING (auth.uid() = adopter_id OR auth.uid() = shelter_id);

CREATE POLICY "Los refugios pueden actualizar el estado de sus matches"
    ON public.matches FOR UPDATE
    USING (auth.uid() = shelter_id);

-- 6. Políticas para Messages (Chat)
CREATE POLICY "Los participantes de un match aprobado pueden ver y enviar mensajes"
    ON public.messages FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.matches
            WHERE matches.id = public.messages.match_id
              AND (matches.adopter_id = auth.uid() OR matches.shelter_id = auth.uid())
              AND matches.status IN ('approved_for_chat', 'interview_scheduled', 'adoption_finalized')
        )
    );
