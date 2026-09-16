import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';
import { AdopterFormModel, AdopterFormSchema } from '../models/adopter_form.model.js';
import { ResponseView } from '../views/response.view.js';
import { ZodError } from 'zod';

export class AdopterController {
  /**
   * Obtener el formulario del adoptante actual
   */
  static async getMyForm(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    try {
      const form = await AdopterFormModel.findByUserId(userId);
      ResponseView.success(res, form, 'Formulario recuperado correctamente');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Enviar o actualizar el formulario riguroso de adopción
   */
  static async submitForm(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    try {
      // 1. Validar cuerpo con Zod
      const validatedInput = AdopterFormSchema.parse(req.body);

      // 2. Procesar evaluación y guardar
      const savedRecord = await AdopterFormModel.upsertForm(userId, validatedInput);

      ResponseView.success(
        res,
        savedRecord,
        'Formulario de adopción evaluado y guardado exitosamente',
        201
      );
    } catch (err) {
      if (err instanceof ZodError) {
        ResponseView.error(
          res,
          'Faltan campos obligatorios o el formato es incorrecto',
          422,
          err.errors
        );
        return;
      }
      ResponseView.internalError(res, err);
    }
  }
}
