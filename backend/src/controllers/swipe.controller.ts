import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';
import { SwipeModel } from '../models/swipe.model.js';
import { MatchModel } from '../models/match.model.js';
import { ResponseView } from '../views/response.view.js';

export class SwipeController {
  /**
   * Registrar un swipe en una mascota (left, right, superlike)
   */
  static async handleSwipe(req: AuthenticatedRequest, res: Response): Promise<void> {
    const adopterId = req.user?.id;
    const { pet_id, direction } = req.body;

    if (!adopterId) {
      ResponseView.unauthorized(res);
      return;
    }

    if (!pet_id || !['left', 'right', 'superlike'].includes(direction)) {
      ResponseView.error(res, 'pet_id y dirección válida (left, right, superlike) son requeridos', 400);
      return;
    }

    try {
      const result = await SwipeModel.recordSwipe(adopterId, pet_id, direction);

      ResponseView.success(
        res,
        result,
        result.matchCreated
          ? '¡Solicitud de adopción enviada al refugio!'
          : 'Swipe registrado'
      );
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Listar matches según el rol del usuario (adoptante o refugio)
   */
  static async getMatches(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const role = (req.user?.role || 'adopter') as 'adopter' | 'shelter';

    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    try {
      const matches = await MatchModel.getMatchesByUserId(userId, role);
      ResponseView.success(res, matches, 'Matches recuperados');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Actualizar estado del match (Aprobar para chat, rechazar, etc.) por parte del refugio
   */
  static async updateMatchStatus(req: AuthenticatedRequest, res: Response): Promise<void> {
    const shelterId = req.user?.id;
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const { status, comments } = req.body;

    if (!id) {
      ResponseView.error(res, 'ID de match requerido', 400);
      return;
    }

    if (!shelterId || req.user?.role !== 'shelter') {
      ResponseView.forbidden(res, 'Solo los refugios pueden actualizar el estado de una solicitud');
      return;
    }

    const validStatuses = [
      'pending_review',
      'approved_for_chat',
      'interview_scheduled',
      'rejected',
      'adoption_finalized',
    ];

    if (!validStatuses.includes(status)) {
      ResponseView.error(res, 'Estado de match inválido', 400);
      return;
    }

    try {
      const updatedMatch = await MatchModel.updateStatus(id, shelterId, status, comments);
      ResponseView.success(res, updatedMatch, 'Estado de solicitud actualizado correctamente');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }
}
