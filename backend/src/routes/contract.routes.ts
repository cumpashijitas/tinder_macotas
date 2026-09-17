import { Router } from 'express';
import { ContractController } from '../controllers/contract.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

export const contractRouter = Router();

contractRouter.use(authMiddleware);

contractRouter.get('/', ContractController.listAll);
contractRouter.get('/:matchId', ContractController.get);
contractRouter.post('/:matchId', ContractController.create);
contractRouter.post('/:matchId/sign', ContractController.sign);
