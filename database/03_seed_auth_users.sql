-- ==============================================================================
-- 03_seed_auth_users.sql: Usuarios de prueba en auth.users
-- ==============================================================================
-- public.profiles.id referencia auth.users(id) por FK, así que estos usuarios
-- deben existir en auth.users ANTES de correr 04_seed.sql y 07_seed_extended.sql.
-- Password de prueba para todos: "changeme123" (solo para datos de prueba/dev).

INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, is_super_admin,
    confirmation_token, recovery_token, email_change_token_new, email_change
)
VALUES
-- 1. Refugio Patitas Felices (shelter)
(
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated',
    'refugio.patitas.felices@example.com',
    crypt('changeme123', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}', false,
    '', '', '', ''
),
-- 2. Familia Rodríguez (individual_rescuer)
(
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated',
    'familia.rodriguez@example.com',
    crypt('changeme123', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}', false,
    '', '', '', ''
),
-- 3. Administración PetMatch (admin)
(
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000003',
    'authenticated', 'authenticated',
    'admin@petmatch.example.com',
    crypt('changeme123', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}', false,
    '', '', '', ''
),
-- 4. Refugio Huellas del Sur (shelter)
(
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000004',
    'authenticated', 'authenticated',
    'refugio.huellas.delsur@example.com',
    crypt('changeme123', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}', false,
    '', '', '', ''
),
-- 5. Ana Torres (adopter, formulario aprobado)
(
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000005',
    'authenticated', 'authenticated',
    'ana.torres@example.com',
    crypt('changeme123', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}', false,
    '', '', '', ''
),
-- 6. Bruno Silva (adopter, formulario requiere entrevista; también reubica una mascota)
(
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000006',
    'authenticated', 'authenticated',
    'bruno.silva@example.com',
    crypt('changeme123', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}', false,
    '', '', '', ''
),
-- 7. Carla Díaz (adopter, formulario rechazado)
(
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000007',
    'authenticated', 'authenticated',
    'carla.diaz@example.com',
    crypt('changeme123', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}', false,
    '', '', '', ''
),
-- 8. Diego Fernández (adopter, adopción finalizada + historia feliz)
(
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-0000-0000-000000000008',
    'authenticated', 'authenticated',
    'diego.fernandez@example.com',
    crypt('changeme123', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}', false,
    '', '', '', ''
)
ON CONFLICT (id) DO NOTHING;
