import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';
import { StoryModel } from '../models/story.model.js';
import { ResponseView } from '../views/response.view.js';

export class StoryController {
  /**
   * Listar historias de adopción ("Finales Felices")
   */
  static async list(_req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const stories = await StoryModel.list();
      ResponseView.success(res, stories, 'Historias recuperadas');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Publicar una historia de adopción. Si referencia un match, debe pertenecer
   * al autor y estar en estado "adoption_finalized".
   */
  static async create(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    const { match_id, pet_name, title, content, photo_url } = req.body;

    if (!pet_name || typeof pet_name !== 'string' || !pet_name.trim() || pet_name.trim().length > 80) {
      ResponseView.error(res, 'El nombre de la mascota es requerido (máx. 80 caracteres)', 400);
      return;
    }
    if (!title || typeof title !== 'string' || title.trim().length < 5 || title.trim().length > 150) {
      ResponseView.error(res, 'El título debe tener entre 5 y 150 caracteres', 400);
      return;
    }
    if (!content || typeof content !== 'string' || content.trim().length < 20 || content.trim().length > 5000) {
      ResponseView.error(res, 'El relato debe tener entre 20 y 5000 caracteres', 400);
      return;
    }

    try {
      if (match_id) {
        const owns = await StoryModel.validateMatchOwnership(match_id, userId);
        if (!owns) {
          ResponseView.forbidden(
            res,
            'Sólo podés vincular una historia a un match propio con adopción finalizada'
          );
          return;
        }
      }

      const story = await StoryModel.create(userId, {
        match_id: match_id || null,
        pet_name: pet_name.trim(),
        title: title.trim(),
        content: content.trim(),
        photo_url: photo_url || null,
      });

      ResponseView.success(res, story, 'Historia publicada correctamente', 201);
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  static async like(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

    if (!userId || !id) {
      ResponseView.error(res, 'ID de historia requerido', 400);
      return;
    }

    try {
      await StoryModel.like(id, userId);
      ResponseView.success(res, null, 'Like registrado');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  static async unlike(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

    if (!userId || !id) {
      ResponseView.error(res, 'ID de historia requerido', 400);
      return;
    }

    try {
      await StoryModel.unlike(id, userId);
      ResponseView.success(res, null, 'Like retirado');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }
}
