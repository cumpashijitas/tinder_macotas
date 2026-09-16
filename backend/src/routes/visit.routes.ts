import { Router } from 'express';
import { VisitController } from '../controllers/visit.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

export const visitRouter = Router();

visitRouter.use(authMiddleware);

visitRouter.get('/:matchId/visits', VisitController.list);
visitRouter.post('/:matchId/visits', VisitController.create);

export const visitStatusRouter = Router();
visitStatusRouter.use(authMiddleware);
visitStatusRouter.patch('/:id', VisitController.updateStatus);
