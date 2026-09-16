-- ==============================================================================
-- 07_seed_extended.sql: Datos de prueba extendidos
-- Cubre cada valor de cada enum del sistema y los 5 casos de uso completos
-- (formulario de adoptante, moderación de mascotas, match end-to-end con chat,
-- contrato firmado, visita agendada e historia de adopción).
-- Requiere: 03_seed_auth_users.sql y 04_seed.sql ya aplicados.
-- ==============================================================================

DO $$
DECLARE
    admin_id UUID := '00000000-0000-0000-0000-000000000003';
    shelter2_id UUID := '00000000-0000-0000-0000-000000000004';
    ana_id UUID := '00000000-0000-0000-0000-000000000005';
    bruno_id UUID := '00000000-0000-0000-0000-000000000006';
    carla_id UUID := '00000000-0000-0000-0000-000000000007';
    diego_id UUID := '00000000-0000-0000-0000-000000000008';

    shelter1_id UUID := '00000000-0000-0000-0000-000000000001'; -- Refugio Patitas Felices
    individual1_id UUID := '00000000-0000-0000-0000-000000000002'; -- Familia Rodríguez

    rocky_id UUID;
    simba_id UUID;
    luna_id UUID;

    copito_id UUID := '10000000-0000-0000-0000-000000000001';
    thor_id UUID := '10000000-0000-0000-0000-000000000002';
    bruna_id UUID := '10000000-0000-0000-0000-000000000003';
    michi_id UUID := '10000000-0000-0000-0000-000000000004';
    toby_id UUID := '10000000-0000-0000-0000-000000000005';
    nina_id UUID := '10000000-0000-0000-0000-000000000006';
    max_id UUID := '10000000-0000-0000-0000-000000000007';
    rex_id UUID := '10000000-0000-0000-0000-000000000008';

    match_a_id UUID := '20000000-0000-0000-0000-000000000001'; -- Ana x Rocky (approved_for_chat)
    match_b_id UUID := '20000000-0000-0000-0000-000000000002'; -- Bruno x Simba (pending_review)
    match_c_id UUID := '20000000-0000-0000-0000-000000000003'; -- Carla x Luna (rejected)
    match_d_id UUID := '20000000-0000-0000-0000-000000000004'; -- Ana x Thor (interview_scheduled)
    match_e_id UUID := '20000000-0000-0000-0000-000000000005'; -- Diego x Toby (adoption_finalized)

    story1_id UUID := '30000000-0000-0000-0000-000000000001';
    story2_id UUID := '30000000-0000-0000-0000-000000000002';
BEGIN
    SELECT id INTO rocky_id FROM public.pets WHERE name = 'Rocky' LIMIT 1;
    SELECT id INTO simba_id FROM public.pets WHERE name = 'Simba (Cachorro de Camada)' LIMIT 1;
    SELECT id INTO luna_id FROM public.pets WHERE name = 'Luna' LIMIT 1;

    -- ==========================================================================
    -- 1. Perfiles adicionales
    -- ==========================================================================
    INSERT INTO public.profiles (id, full_name, phone, role, organization_name, address, is_verified)
    VALUES
        (admin_id, 'Administración PetMatch', '+54 11 5000-0000', 'admin', 'PetMatch', 'Oficina Central', true),
        (shelter2_id, 'Refugio Huellas del Sur', '+54 11 4321-0000', 'shelter', 'ONG Huellas del Sur', 'Av. Rivadavia 8800', true),
        (ana_id, 'Ana Torres', '+54 11 6000-0001', 'adopter', NULL, 'Palermo, CABA', true),
        (bruno_id, 'Bruno Silva', '+54 11 6000-0002', 'adopter', NULL, 'Belgrano, CABA', false),
        (carla_id, 'Carla Díaz', '+54 11 6000-0003', 'adopter', NULL, 'Villa Urquiza, CABA', false),
        (diego_id, 'Diego Fernández', '+54 11 6000-0004', 'adopter', NULL, 'Caballito, CABA', true)
    ON CONFLICT (id) DO NOTHING;

    -- ==========================================================================
    -- 2. Formularios de adoptante (cubre approved / requires_interview / rejected)
    -- ==========================================================================
    INSERT INTO public.adopter_forms (
        user_id, housing_type, housing_status, has_yard, has_protective_netting,
        household_members, all_members_agree, has_allergies, hours_pet_alone_per_day,
        has_other_pets, other_pets_details, previous_pet_experience,
        monthly_budget_confirmed, emergency_fund_available, agrees_to_follow_up, agrees_to_mandatory_neutering,
        evaluation_status, evaluation_score, reviewer_notes
    )
    VALUES
    (
        ana_id, 'house', 'owned', true, false,
        'couple', true, false, 4,
        false, NULL, 'Tuvo perros toda su vida, incluye experiencia con cachorros.',
        true, true, true, true,
        'approved', 90, 'Vivienda propia con patio, disponibilidad alta. Apta sin observaciones.'
    ),
    (
        bruno_id, 'apartment', 'rented_allowed', false, true,
        'alone', true, true, 9,
        true, 'Un gato adulto esterilizado', 'Primera vez con perros.',
        true, false, true, true,
        'requires_interview', 55, 'Fondo de emergencia no confirmado; se solicita entrevista para evaluar convivencia con el gato existente.'
    ),
    (
        carla_id, 'apartment', 'rented_pending_permission', false, false,
        'roommates', true, false, 11,
        false, NULL, 'Sin experiencia previa.',
        false, false, true, true,
        'rejected', 20, 'Permiso de alquiler pendiente y más de 10 horas de soledad diaria: riesgo alto de desalojo y abandono.'
    ),
    (
        diego_id, 'house', 'owned', true, false,
        'family_with_teens', true, false, 3,
        false, NULL, 'Creció con mascotas, familia numerosa y activa.',
        true, true, true, true,
        'approved', 95, 'Perfil ideal: vivienda propia, poco tiempo de soledad, compromiso total.'
    )
    ON CONFLICT (user_id) DO NOTHING;

    -- ==========================================================================
    -- 3. Mascotas adicionales (cubre cada valor de cada enum restante)
    -- ==========================================================================
    INSERT INTO public.pets (
        id, shelter_id, publisher_type, name, species, breed, age_years, gender, size,
        energy_level, origin, is_litter, weaning_completed, is_vaccinated,
        vaccines_applied, dewormed_internal, dewormed_external, has_microchip,
        is_neutered, reproductive_status, house_trained, good_with_dogs, good_with_cats,
        good_with_kids, requires_yard, storm_anxiety, story, relocation_reason,
        requires_adoption_contract, requires_home_check, requires_followup_photos, delivery_type,
        photos, status, moderation_status, moderation_notes
    )
    VALUES
    (
        copito_id, shelter2_id, 'shelter', 'Copito', 'other', 'Conejo Cabeza de León', 0.8, 'male', 'small',
        2, 'shelter_born', false, true, true,
        ARRAY['Mixomatosis'], true, true, false,
        false, 'intact', true, true, true,
        true, false, 1, 'Copito nació en el refugio. Muy sociable, se lleva bien con otras mascotas pequeñas.', NULL,
        true, false, true, 'pickup_at_shelter',
        ARRAY['https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?auto=format&fit=crop&w=800&q=80'], 'available', 'approved', NULL
    ),
    (
        thor_id, shelter1_id, 'individual_rescuer', 'Thor', 'dog', 'Mestizo Ovejero', 5.0, 'male', 'large',
        3, 'relinquished', false, true, true,
        ARRAY['Antirrábica', 'Séxtuple Canina'], true, true, true,
        true, 'neutered', true, true, false,
        true, true, 2, 'Thor fue entregado por su familia anterior tras una mudanza al exterior. Muy obediente y protector.', 'Mudanza internacional de la familia anterior, no pueden llevarlo por regulaciones de la aerolínea.',
        true, true, true, 'to_be_agreed',
        ARRAY['https://images.unsplash.com/photo-1553882809-a4f57e59501d?auto=format&fit=crop&w=800&q=80'], 'available', 'approved', NULL
    ),
    (
        bruna_id, shelter1_id, 'shelter', 'Bruna', 'dog', 'Gran Danés', 3.0, 'female', 'giant',
        2, 'shelter_born', false, true, true,
        ARRAY['Antirrábica', 'Séxtuple Canina'], true, true, true,
        true, 'spayed', true, true, true,
        true, true, 3, 'Bruna es gigante pero muy tranquila. Actualmente en pausa por tratamiento veterinario preventivo.', NULL,
        true, true, true, 'to_be_agreed',
        ARRAY['https://images.unsplash.com/photo-1517849845537-4d257902861a?auto=format&fit=crop&w=800&q=80'], 'paused', 'approved', NULL
    ),
    (
        michi_id, shelter2_id, 'shelter', 'Michi', 'cat', 'Mestizo', 2.5, 'male', 'medium',
        3, 'street_rescue', false, true, true,
        ARRAY['Triple Felina'], true, true, true,
        true, 'neutered', true, false, true,
        true, false, 2, 'Michi está actualmente en proceso de adopción con una familia, en evaluación final.', NULL,
        true, false, true, 'pickup_at_shelter',
        ARRAY['https://images.unsplash.com/photo-1533738363-b7f9aef128ce?auto=format&fit=crop&w=800&q=80'], 'in_process', 'approved', NULL
    ),
    (
        toby_id, shelter1_id, 'individual_rescuer', 'Toby', 'dog', 'Beagle Mestizo', 4.0, 'male', 'medium',
        4, 'relinquished', false, true, true,
        ARRAY['Antirrábica', 'Séxtuple Canina'], true, true, true,
        true, 'neutered', true, true, true,
        true, false, 1, 'Toby ya encontró su hogar definitivo con Diego y su familia. ¡Adopción finalizada con éxito!', 'Entregado por rescatista independiente tras estabilizarlo de la calle.',
        true, false, true, 'home_delivery',
        ARRAY['https://images.unsplash.com/photo-1477884143824-5d7a9a0f4d1f?auto=format&fit=crop&w=800&q=80'], 'adopted', 'approved', NULL
    ),
    (
        nina_id, individual1_id, 'individual_rescuer', 'Nina', 'cat', 'Mestiza', 0.3, 'female', 'small',
        4, 'home_litter', true, true, true,
        ARRAY['Pupivac (1ra dosis Triple Felina)'], true, true, false,
        false, 'requires_spay_agreement', false, true, true,
        true, false, 3, 'Nina es una de las gatitas de la camada de la Familia Rodríguez. Juguetona y curiosa.', NULL,
        true, false, true, 'to_be_agreed',
        ARRAY['https://images.unsplash.com/photo-1495360010541-f48722b34f7d?auto=format&fit=crop&w=800&q=80'], 'available', 'approved', NULL
    ),
    (
        max_id, bruno_id, 'individual_rescuer', 'Max', 'dog', 'Mestizo Caniche', 6.0, 'male', 'medium',
        2, 'relinquished', false, true, true,
        ARRAY['Antirrábica'], true, false, false,
        true, 'neutered', true, true, true,
        true, false, 4, 'Reubicación Responsable: Max necesita un nuevo hogar porque su dueño se muda a un departamento que no admite mascotas.', 'El propietario se muda a un edificio que no permite mascotas y no consiguió alternativa a tiempo.',
        true, true, true, 'to_be_agreed',
        ARRAY['https://images.unsplash.com/photo-1561037404-61cd46aa615b?auto=format&fit=crop&w=800&q=80'], 'available', 'pending', NULL
    ),
    (
        rex_id, individual1_id, 'individual_rescuer', 'Rex', 'dog', 'Pitbull Mestizo', 3.0, 'male', 'large',
        5, 'street_rescue', false, true, false,
        ARRAY[]::TEXT[], false, false, false,
        false, 'intact', false, false, false,
        false, false, 5, 'Publicación rechazada: faltan datos sanitarios obligatorios y fotos claras del animal.', NULL,
        true, true, true, 'to_be_agreed',
        ARRAY['https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=800&q=80'], 'available', 'rejected', 'Falta cartilla de vacunación y fotos nítidas. Se solicita al publicador completar la información antes de re-publicar.'
    )
    ON CONFLICT (id) DO NOTHING;

    -- ==========================================================================
    -- 4. Swipes (cubre left / right / superlike)
    -- ==========================================================================
    INSERT INTO public.swipes (adopter_id, pet_id, direction)
    VALUES
        (ana_id, rocky_id, 'right'),
        (ana_id, thor_id, 'superlike'),
        (ana_id, luna_id, 'left'),
        (ana_id, copito_id, 'left'),
        (bruno_id, simba_id, 'right'),
        (bruno_id, michi_id, 'left'),
        (carla_id, luna_id, 'right'),
        (carla_id, nina_id, 'left'),
        (diego_id, toby_id, 'superlike'),
        (diego_id, bruna_id, 'left')
    ON CONFLICT (adopter_id, pet_id) DO NOTHING;

    -- ==========================================================================
    -- 5. Matches (cubre los 5 valores de status)
    -- ==========================================================================
    INSERT INTO public.matches (id, pet_id, adopter_id, shelter_id, status, shelter_comments)
    VALUES
        (match_a_id, rocky_id, ana_id, shelter1_id, 'approved_for_chat', 'Perfil aprobado, coordinar visita.'),
        (match_b_id, simba_id, bruno_id, individual1_id, 'pending_review', NULL),
        (match_c_id, luna_id, carla_id, shelter1_id, 'rejected', 'El formulario de la adoptante fue rechazado: permiso de alquiler pendiente.'),
        (match_d_id, thor_id, ana_id, shelter1_id, 'interview_scheduled', 'Excelente candidata, se agenda entrevista y visita domiciliaria.'),
        (match_e_id, toby_id, diego_id, shelter1_id, 'adoption_finalized', 'Adopción completada exitosamente. ¡Felicidades a la nueva familia!')
    ON CONFLICT (id) DO NOTHING;

    -- ==========================================================================
    -- 6. Mensajes de chat (matches con status approved_for_chat / interview_scheduled / adoption_finalized)
    -- ==========================================================================
    INSERT INTO public.messages (match_id, sender_id, content, is_read)
    VALUES
        (match_a_id, ana_id, 'Hola! Me encantó Rocky, ¿podemos coordinar para conocerlo?', true),
        (match_a_id, shelter1_id, '¡Hola Ana! Claro, contanos qué día te queda mejor.', true),
        (match_a_id, ana_id, 'El sábado por la mañana tendría disponibilidad.', false),
        (match_d_id, ana_id, 'Vi que Thor necesita mucho espacio, tenemos un patio grande así que debería estar bien.', true),
        (match_d_id, shelter1_id, 'Perfecto, vamos a agendar la entrevista y la visita domiciliaria.', true),
        (match_e_id, diego_id, '¡Toby se adaptó increíble a la familia, gracias por todo!', true),
        (match_e_id, shelter1_id, 'Qué alegría leer esto, ¡gracias por adoptar responsablemente!', true);

    -- ==========================================================================
    -- 7. Contratos de adopción (firma digital)
    -- ==========================================================================
    INSERT INTO public.adoption_contracts (
        match_id, adopter_id, shelter_id, terms_version,
        signed_by_adopter, signed_by_adopter_at, signed_by_shelter, signed_by_shelter_at, signature_hash
    )
    VALUES
        (match_d_id, ana_id, shelter1_id, 'v1', true, now() - interval '1 day', false, NULL, NULL),
        (match_e_id, diego_id, shelter1_id, 'v1', true, now() - interval '10 days', true, now() - interval '9 days', encode(sha256((match_e_id::text || diego_id::text || now()::text)::bytea), 'hex'))
    ON CONFLICT (match_id) DO NOTHING;

    -- ==========================================================================
    -- 8. Solicitudes de visita
    -- ==========================================================================
    INSERT INTO public.visit_requests (match_id, requested_by, proposed_at, status, notes)
    VALUES
        (match_a_id, shelter1_id, now() + interval '5 days', 'pending', 'Propuesta: sábado 11hs en el refugio.'),
        (match_d_id, ana_id, now() + interval '3 days', 'confirmed', 'Visita domiciliaria confirmada para evaluar el patio.');

    -- ==========================================================================
    -- 9. Historias de Adopción ("Finales Felices") + Likes
    -- ==========================================================================
    INSERT INTO public.adoption_stories (id, match_id, author_id, pet_name, title, content, photo_url)
    VALUES
        (story1_id, match_e_id, diego_id, 'Toby', 'Toby encontró su hogar para siempre', 'Después de meses en la calle, Toby hoy duerme en su propia cama y sale a pasear todos los días con nuestra familia. ¡Gracias PetMatch!', 'https://images.unsplash.com/photo-1477884143824-5d7a9a0f4d1f?auto=format&fit=crop&w=800&q=80'),
        (story2_id, NULL, ana_id, 'Firulais', 'Un año juntos y contando', 'Adoptamos a Firulais hace un año fuera de la plataforma, pero queríamos compartir cómo transformó nuestra rutina familiar.', 'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=800&q=80')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.story_likes (story_id, user_id)
    VALUES
        (story1_id, bruno_id),
        (story1_id, carla_id),
        (story1_id, ana_id),
        (story2_id, diego_id)
    ON CONFLICT (story_id, user_id) DO NOTHING;
END $$;
