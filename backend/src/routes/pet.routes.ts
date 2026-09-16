import { Router } from 'express';
import { PetController } from '../controllers/pet.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

export const petRouter = Router();

petRouter.use(authMiddleware);

petRouter.get('/feed', PetController.getFeed);
petRouter.get('/inventory', PetController.getInventory);
petRouter.post('/relocate', PetController.relocatePet);
petRouter.get('/:id', PetController.getDetail);
petRouter.patch('/:id/status', PetController.updateStatus);
petRouter.post('/', PetController.create);
