import { Request, Response, NextFunction } from 'express';
import { supabaseAdmin } from '../config/supabase.js';
import { ResponseView } from '../views/response.view.js';

export interface AuthenticatedRequest extends Request {
  user?: {
    id: string;
    email?: string;
    role?: string;
  };
}

export async function authMiddleware(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    ResponseView.unauthorized(res, 'Token de autenticación requerido (Bearer token)');
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    // Validar token con Supabase
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);

    if (error || !user) {
      ResponseView.unauthorized(res, 'Token inválido o sesión expirada');
      return;
    }

    // Obtener rol del perfil en la tabla profiles
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();

    req.user = {
      id: user.id,
      email: user.email,
      role: profile?.role || 'adopter',
    };

    next();
  } catch (err) {
    ResponseView.internalError(res, err);
  }
}
