import { createClient } from '@supabase/supabase-js';
import { ENV } from './env.js';

// Cliente administrativo con permisos de servicio para el backend MVC
export const supabaseAdmin = createClient(
  ENV.SUPABASE_URL,
  ENV.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

// Cliente anónimo estándar para validar sesiones de usuario
export const supabaseAnon = createClient(
  ENV.SUPABASE_URL,
  ENV.SUPABASE_ANON_KEY
);
