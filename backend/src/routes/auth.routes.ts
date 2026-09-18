import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';
import { otpRateLimiter } from '../middlewares/rate_limit.middleware.js';

export const authRouter = Router();

authRouter.post('/otp', otpRateLimiter, AuthController.requestOtp);
authRouter.get('/profile', authMiddleware, AuthController.getProfile);
authRouter.post('/profile', authMiddleware, AuthController.upsertProfile);
