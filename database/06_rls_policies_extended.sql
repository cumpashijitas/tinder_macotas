-- ==============================================================================
-- 06_rls_policies_extended.sql: Políticas RLS para las tablas y columnas nuevas
-- ==============================================================================

-- 1. Refinar visibilidad de mascotas: sólo aprobadas y no archivadas son públicas;
--    el propio publicador siempre puede ver las suyas (incluso pendientes/rechazadas).
DROP POLICY IF EXISTS "Las mascotas disponibles son visibles para todos" ON public.pets;
CREATE POLICY "Las mascotas aprobadas son visibles para todos"
    ON public.pets FOR SELECT
    USING (
        (moderation_status = 'approved' AND status != 'archived')
        OR auth.uid() = shelter_id
    );

-- 2. Permitir que un usuario cree su propio perfil (signup)
CREATE POLICY "Un usuario puede crear su propio perfil"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 3. Historias de Adopción ("Finales Felices")
ALTER TABLE public.adoption_stories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Las historias son visibles para todos"
    ON public.adoption_stories FOR SELECT
    USING (true);

CREATE POLICY "El autor puede crear su propia historia"
    ON public.adoption_stories FOR INSERT
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "El autor puede editar su historia"
    ON public.adoption_stories FOR UPDATE
    USING (auth.uid() = author_id);

CREATE POLICY "El autor puede borrar su historia"
    ON public.adoption_stories FOR DELETE
    USING (auth.uid() = author_id);

-- 4. Likes de historias
ALTER TABLE public.story_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los likes son visibles para todos"
    ON public.story_likes FOR SELECT
    USING (true);

CREATE POLICY "Un usuario da like con su propio id"
    ON public.story_likes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Un usuario quita su propio like"
    ON public.story_likes FOR DELETE
    USING (auth.uid() = user_id);

-- 5. Contratos de Adopción: sólo las dos partes del match
ALTER TABLE public.adoption_contracts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Las partes del match ven su contrato"
    ON public.adoption_contracts FOR SELECT
    USING (auth.uid() = adopter_id OR auth.uid() = shelter_id);

CREATE POLICY "El refugio crea el contrato del match"
    ON public.adoption_contracts FOR INSERT
    WITH CHECK (auth.uid() = shelter_id);

CREATE POLICY "Las partes del match firman el contrato"
    ON public.adoption_contracts FOR UPDATE
    USING (auth.uid() = adopter_id OR auth.uid() = shelter_id);

-- 6. Solicitudes de Visita: sólo las dos partes del match asociado
ALTER TABLE public.visit_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Las partes del match ven las visitas"
    ON public.visit_requests FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.matches
            WHERE matches.id = public.visit_requests.match_id
              AND (matches.adopter_id = auth.uid() OR matches.shelter_id = auth.uid())
        )
    );

CREATE POLICY "Las partes del match crean solicitudes de visita"
    ON public.visit_requests FOR INSERT
    WITH CHECK (
        auth.uid() = requested_by AND
        EXISTS (
            SELECT 1 FROM public.matches
            WHERE matches.id = public.visit_requests.match_id
              AND (matches.adopter_id = auth.uid() OR matches.shelter_id = auth.uid())
        )
    );

CREATE POLICY "Las partes del match actualizan la visita"
    ON public.visit_requests FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.matches
            WHERE matches.id = public.visit_requests.match_id
              AND (matches.adopter_id = auth.uid() OR matches.shelter_id = auth.uid())
        )
    );
