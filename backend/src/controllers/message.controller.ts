import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';
import { MessageModel } from '../models/message.model.js';
import { ResponseView } from '../views/response.view.js';
import { containsProhibitedContent } from '../utils/content_filter.js';

const CHAT_ENABLED_STATUSES = ['approved_for_chat', 'interview_scheduled', 'adoption_finalized'];

export class MessageController {
  /**
   * Listar mensajes de un match y marcar como leídos los del interlocutor
   */
  static async list(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const matchId = Array.isArray(req.params.matchId) ? req.params.matchId[0] : req.params.matchId;

    if (!userId || !matchId) {
      ResponseView.error(res, 'ID de match requerido', 400);
      return;
    }

    try {
      const { ok } = await MessageModel.isParticipant(matchId, userId);
      if (!ok) {
        ResponseView.forbidden(res, 'No participás de este match');
        return;
      }

      const messages = await MessageModel.findByMatchId(matchId);
      await MessageModel.markReadForRecipient(matchId, userId);

      ResponseView.success(res, messages, 'Mensajes recuperados');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  /**
   * Enviar un mensaje en el chat de un match (solo si el match fue aprobado)
   */
  static async send(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const matchId = Array.isArray(req.params.matchId) ? req.params.matchId[0] : req.params.matchId;
    const { content } = req.body;

    if (!userId || !matchId) {
      ResponseView.error(res, 'ID de match requerido', 400);
      return;
    }

    if (!content || typeof content !== 'string' || !content.trim()) {
      ResponseView.error(res, 'El contenido del mensaje es requerido', 400);
      return;
    }

    if (content.trim().length > 3000) {
      ResponseView.error(res, 'El mensaje no puede superar los 3000 caracteres', 422);
      return;
    }

    if (containsProhibitedContent(content)) {
      ResponseView.error(res, 'El mensaje contiene lenguaje no permitido', 422);
      return;
    }

    try {
      const { ok, status, adopterId, shelterId } = await MessageModel.isParticipant(matchId, userId);
      if (!ok) {
        ResponseView.forbidden(res, 'No participás de este match');
        return;
      }

      if (!status || !CHAT_ENABLED_STATUSES.includes(status)) {
        ResponseView.forbidden(res, 'El chat sólo está disponible una vez que la solicitud fue aprobada');
        return;
      }

      const recipientId = userId === adopterId ? shelterId : adopterId;
      const message = await MessageModel.create(matchId, userId, content.trim(), recipientId);
      ResponseView.success(res, message, 'Mensaje enviado', 201);
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }
}
