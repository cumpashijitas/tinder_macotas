import { Router } from 'express';
import { SwipeController } from '../controllers/swipe.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

export const swipeRouter = Router();

swipeRouter.use(authMiddleware);

swipeRouter.post('/', SwipeController.handleSwipe);
swipeRouter.get('/matches', SwipeController.getMatches);
swipeRouter.patch('/matches/:id/status', SwipeController.updateMatchStatus);
