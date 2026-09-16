import { Router } from 'express';
import { AdopterController } from '../controllers/adopter.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

export const adopterRouter = Router();

// Todas las rutas del adoptante requieren autenticación
adopterRouter.use(authMiddleware);

adopterRouter.get('/form', AdopterController.getMyForm);
adopterRouter.post('/form', AdopterController.submitForm);
