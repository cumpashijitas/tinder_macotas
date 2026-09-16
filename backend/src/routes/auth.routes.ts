import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

export const authRouter = Router();

authRouter.post('/otp', AuthController.requestOtp);
authRouter.get('/profile', authMiddleware, AuthController.getProfile);
