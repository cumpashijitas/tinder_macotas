-- ==============================================================================
-- 11_pagination_indexes.sql: índices para las consultas paginadas
-- adoption_contracts.listForUser filtra por adopter_id/shelter_id con OR;
-- sin estos índices esa consulta cae en un full scan a medida que crece.
-- ==============================================================================

CREATE INDEX IF NOT EXISTS idx_contracts_adopter ON public.adoption_contracts(adopter_id);
CREATE INDEX IF NOT EXISTS idx_contracts_shelter ON public.adoption_contracts(shelter_id);
