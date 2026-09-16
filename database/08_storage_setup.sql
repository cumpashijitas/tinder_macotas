-- ==============================================================================
-- 08_storage_setup.sql: Bucket de Storage para fotos de mascotas
-- ==============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('pet-photos', 'pet-photos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Las fotos de mascotas son públicas para lectura"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'pet-photos');

CREATE POLICY "Usuarios autenticados pueden subir fotos de mascotas"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'pet-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Usuarios autenticados pueden actualizar sus propias fotos"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'pet-photos' AND owner = auth.uid());

CREATE POLICY "Usuarios autenticados pueden borrar sus propias fotos"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'pet-photos' AND owner = auth.uid());
