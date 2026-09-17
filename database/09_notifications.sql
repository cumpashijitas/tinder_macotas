-- ==============================================================================
-- 09_notifications.sql: Notificaciones dentro de la app
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL, -- 'new_match' | 'match_status' | 'new_message' | 'visit' | 'contract'
    title TEXT NOT NULL,
    body TEXT,
    related_id UUID,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "El usuario ve sus propias notificaciones"
    ON public.notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "El usuario marca como leídas sus propias notificaciones"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id);
