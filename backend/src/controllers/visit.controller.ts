import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';
import { VisitModel } from '../models/visit.model.js';
import { ResponseView } from '../views/response.view.js';

const VALID_STATUSES = ['pending', 'confirmed', 'declined', 'completed', 'cancelled'];

async function assertParticipant(matchId: string, userId: string): Promise<boolean> {
  const participants = await VisitModel.getMatchParticipants(matchId);
  if (!participants) return false;
  return participants.adopter_id === userId || participants.shelter_id === userId;
}

export class VisitController {
  /**
   * Historial consolidado: todas las visitas donde el usuario participa
   */
  static async listAll(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    try {
      const visits = await VisitModel.listForUser(userId);
      ResponseView.success(res, visits, 'Visitas recuperadas');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Listar solicitudes de visita de un match
   */
  static async list(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const matchId = Array.isArray(req.params.matchId) ? req.params.matchId[0] : req.params.matchId;

    if (!userId || !matchId) {
      ResponseView.error(res, 'ID de match requerido', 400);
      return;
    }

    try {
      if (!(await assertParticipant(matchId, userId))) {
        ResponseView.forbidden(res, 'No participás de este match');
        return;
      }

      const visits = await VisitModel.findByMatchId(matchId);
      ResponseView.success(res, visits, 'Visitas recuperadas');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Proponer una visita (agendar desde el chat)
   */
  static async create(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const matchId = Array.isArray(req.params.matchId) ? req.params.matchId[0] : req.params.matchId;
    const { proposed_at, notes } = req.body;

    if (!userId || !matchId) {
      ResponseView.error(res, 'ID de match requerido', 400);
      return;
    }

    if (!proposed_at || isNaN(Date.parse(proposed_at))) {
      ResponseView.error(res, 'proposed_at debe ser una fecha/hora válida (ISO 8601)', 400);
      return;
    }

    const FIVE_MINUTES_MS = 5 * 60 * 1000;
    if (Date.parse(proposed_at) < Date.now() - FIVE_MINUTES_MS) {
      ResponseView.error(res, 'La visita propuesta debe ser en una fecha/hora futura', 422);
      return;
    }

    if (notes !== undefined && notes !== null && (typeof notes !== 'string' || notes.trim().length > 500)) {
      ResponseView.error(res, 'Las notas no pueden superar los 500 caracteres', 422);
      return;
    }

    try {
      if (!(await assertParticipant(matchId, userId))) {
        ResponseView.forbidden(res, 'No participás de este match');
        return;
      }

      const visit = await VisitModel.create(matchId, userId, new Date(proposed_at).toISOString(), notes);
      ResponseView.success(res, visit, 'Visita propuesta correctamente', 201);
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Confirmar, rechazar, completar o cancelar una visita
   */
  static async updateStatus(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
    const { status } = req.body;

    if (!userId || !id) {
      ResponseView.error(res, 'ID de visita requerido', 400);
      return;
    }

    if (!VALID_STATUSES.includes(status)) {
      ResponseView.error(res, 'Estado de visita inválido', 400);
      return;
    }

    try {
      const visit = await VisitModel.findById(id);
      if (!visit) {
        ResponseView.notFound(res, 'Visita no encontrada');
        return;
      }

      if (!(await assertParticipant(visit.match_id, userId))) {
        ResponseView.forbidden(res, 'No participás de este match');
        return;
      }

      const updated = await VisitModel.updateStatus(id, status, userId);
      ResponseView.success(res, updated, 'Estado de la visita actualizado');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }
}
