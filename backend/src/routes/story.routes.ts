import { Router } from 'express';
import { StoryController } from '../controllers/story.controller.js';
import { authMiddleware } from '../middlewares/auth.middleware.js';

export const storyRouter = Router();

storyRouter.use(authMiddleware);

storyRouter.get('/', StoryController.list);
storyRouter.post('/', StoryController.create);
storyRouter.post('/:id/like', StoryController.like);
storyRouter.delete('/:id/like', StoryController.unlike);
