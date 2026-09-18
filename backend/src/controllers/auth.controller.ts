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

  /**
   * Crear o actualizar el perfil del usuario autenticado (bootstrap post-login y edición)
   */
  static async upsertProfile(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    const { full_name, role, phone, organization_name, address, avatar_url, latitude, longitude } = req.body;

    if (!full_name || typeof full_name !== 'string' || full_name.trim().length < 2) {
      ResponseView.error(res, 'El nombre completo es requerido (mínimo 2 caracteres)', 400);
      return;
    }

    const allowedRoles = ['adopter', 'shelter', 'individual_rescuer'];
    if (!role || !allowedRoles.includes(role)) {
      ResponseView.error(res, 'Rol inválido. Debe ser adopter, shelter o individual_rescuer', 400);
      return;
    }

    // La ubicación sólo se toca si vino explícitamente en el body, para no
    // pisar con null una ubicación ya guardada en una edición que no la envía.
    const locationPatch: Record<string, number> = {};
    if (typeof latitude === 'number' && typeof longitude === 'number') {
      if (latitude < -90 || latitude > 90) {
        ResponseView.error(res, 'La latitud debe estar entre -90 y 90', 400);
        return;
      }
      if (longitude < -180 || longitude > 180) {
        ResponseView.error(res, 'La longitud debe estar entre -180 y 180', 400);
        return;
      }
      locationPatch.latitude = latitude;
      locationPatch.longitude = longitude;
    }

    try {
      const { data, error } = await supabaseAdmin
        .from('profiles')
        .upsert(
          {
            id: userId,
            full_name: full_name.trim(),
            role,
            phone: phone || null,
            organization_name: organization_name || null,
            address: address || null,
            avatar_url: avatar_url || null,
            ...locationPatch,
          },
          { onConflict: 'id' }
        )
        .select()
        .single();

      if (error) {
        ResponseView.error(res, error.message, 400);
        return;
      }

      ResponseView.success(res, data, 'Perfil guardado correctamente', 201);
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }
}
