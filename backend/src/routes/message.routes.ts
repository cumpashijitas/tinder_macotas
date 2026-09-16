import { Router } from 'express';
import { MessageController } from '../controllers/message.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

export const messageRouter = Router();

messageRouter.use(authMiddleware);

messageRouter.get('/:matchId/messages', MessageController.list);
messageRouter.post('/:matchId/messages', MessageController.send);
