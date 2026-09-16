-- ==============================================================================
-- 03_seed.sql: Datos de Prueba Iniciales (Refugios, Particulares con Camadas y Mascotas)
-- ==============================================================================

DO $$
DECLARE
    dummy_shelter_id UUID := '00000000-0000-0000-0000-000000000001';
    dummy_individual_id UUID := '00000000-0000-0000-0000-000000000002';
BEGIN
    -- 1. Refugio Institucional
    INSERT INTO public.profiles (id, full_name, phone, role, organization_name, address, is_verified)
    VALUES (
        dummy_shelter_id,
        'Refugio Patitas Felices',
        '+54 11 4455-6677',
        'shelter',
        'ONG Patitas Felices',
        'Av. San Martín 1240',
        true
    )
    ON CONFLICT (id) DO NOTHING;

    -- 2. Particular con Camada / Rescatista Independiente
    INSERT INTO public.profiles (id, full_name, phone, role, organization_name, address, is_verified)
    VALUES (
        dummy_individual_id,
        'Familia Rodríguez (Camada en casa)',
        '+54 11 9988-1122',
        'individual_rescuer',
        NULL,
        'Barrio Norte, CABA',
        false
    )
    ON CONFLICT (id) DO NOTHING;

    -- 3. Mascotas en adopción
    INSERT INTO public.pets (
        shelter_id, publisher_type, name, species, breed, age_years, gender, size,
        energy_level, origin, is_litter, weaning_completed, is_vaccinated,
        vaccines_applied, dewormed_internal, dewormed_external, has_microchip,
        is_neutered, reproductive_status, house_trained, good_with_dogs, good_with_cats,
        good_with_kids, requires_yard, storm_anxiety, story,
        requires_adoption_contract, requires_home_check, requires_followup_photos, delivery_type,
        photos, status
    )
    VALUES
    (
        dummy_shelter_id,
        'shelter',
        'Rocky',
        'dog',
        'Mestizo Labrador',
        2.0,
        'male',
        'medium',
        3,
        'street_rescue',
        false,
        true,
        true,
        ARRAY['Antirrábica', 'Séxtuple Canina'],
        true,
        true,
        true,
        true,
        'neutered',
        true,
        true,
        false,
        true,
        false,
        1,
        'Rocky fue rescatado cerca de un parque. Muy alegre, esterilizado y con libreta sanitaria completa. Ideal para familias activas.',
        true,
        true,
        true,
        'to_be_agreed',
        ARRAY['https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80'],
        'available'
    ),
    (
        dummy_individual_id,
        'individual_rescuer',
        'Simba (Cachorro de Camada)',
        'dog',
        'Cachorro Mestizo Golden',
        0.2, -- ~2.5 meses (75 días)
        'male',
        'medium',
        4,
        'home_litter',
        true,
        true, -- Cumplió los 60 días éticos de destete
        true,
        ARRAY['Pupivac (1ra dosis Séxtuple)'],
        true,
        true,
        false,
        false,
        'requires_spay_agreement', -- Cachorro: compromiso de castración a los 6 meses
        false,
        true,
        true,
        true,
        true,
        2,
        'Nació en casa tras el rescate de la mamá. Cumplió más de 60 días con su madre, ya come alimento sólido y está listo para encontrar una familia con patio.',
        true,
        false,
        true,
        'home_delivery',
        ARRAY['https://images.unsplash.com/photo-1591160690555-5debfba289f0?auto=format&fit=crop&w=800&q=80'],
        'available'
    ),
    (
        dummy_shelter_id,
        'shelter',
        'Luna',
        'cat',
        'Común Europeo',
        1.2,
        'female',
        'small',
        2,
        'street_rescue',
        false,
        true,
        true,
        ARRAY['Antirrábica', 'Triple Felina'],
        true,
        true,
        true,
        true,
        'spayed',
        true,
        false,
        true,
        true,
        false,
        1,
        'Luna es sumamente tranquila, esterilizada y acostumbrada a arenero. Ideal para departamento con red de seguridad.',
        true,
        false,
        true,
        'pickup_at_shelter',
        ARRAY['https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800&q=80'],
        'available'
    );
END $$;
