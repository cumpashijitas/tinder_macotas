import { Router } from 'express';
import { NotificationController } from '../controllers/notification.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

export const notificationRouter = Router();

notificationRouter.use(authMiddleware);

notificationRouter.get('/', NotificationController.list);
notificationRouter.patch('/:id/read', NotificationController.markRead);
notificationRouter.patch('/read-all', NotificationController.markAllRead);
