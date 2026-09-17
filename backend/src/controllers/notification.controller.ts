import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth.middleware.js';
import { NotificationModel } from '../models/notification.model.js';
import { ResponseView } from '../views/response.view.js';

export class NotificationController {
  static async list(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    try {
      const [notifications, unreadCount] = await Promise.all([
        NotificationModel.listForUser(userId),
        NotificationModel.countUnread(userId),
      ]);
      ResponseView.success(res, { notifications, unreadCount }, 'Notificaciones recuperadas');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  static async markRead(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;

    if (!userId || !id) {
      ResponseView.error(res, 'ID requerido', 400);
      return;
    }

    try {
      await NotificationModel.markRead(id, userId);
      ResponseView.success(res, null, 'Notificación marcada como leída');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }

  static async markAllRead(req: AuthenticatedRequest, res: Response): Promise<void> {
    const userId = req.user?.id;
    if (!userId) {
      ResponseView.unauthorized(res);
      return;
    }

    try {
      await NotificationModel.markAllRead(userId);
      ResponseView.success(res, null, 'Notificaciones marcadas como leídas');
    } catch (err) {
      ResponseView.internalError(res, err);
    }
  }
}
