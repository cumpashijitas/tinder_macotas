import { Request, Response } from 'express';
import { supabaseAdmin, supabaseAnon } from '../config/supabase.js';
import { ResponseView } from '../views/response.view.js';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';

export class AuthController {
  /**
   * Enviar código OTP al correo electrónico
   */
  static async requestOtp(req: Request, res: Response): Promise<void> {
    const { email } = req.body;

    if (!email || typeof email !== 'string') {
      ResponseView.error(res, 'El correo electrónico es requerido', 400);
      return;
    }

    try {
      const { error } = await supabaseAnon.auth.signInWithOtp({
        email,
        options: {
          shouldCreateUser: true,
        },
      });

      if (error) {
        ResponseView.error(res, error.message, 400);
        return;
      }

      ResponseView.success(res, { email }, 'Código de verificación enviado exitosamente a tu correo');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Obtener perfil del usuario autenticado
   */
  static async getProfile(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;

    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    try {
      const { data: profile, error } = await supabaseAdmin
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

      if (error) {
        ResponseView.error(res, error.message, 400);
        return;
      }

      ResponseView.success(res, profile, 'Perfil obtenido correctamente');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }
}
