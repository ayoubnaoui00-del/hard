import { Router } from 'express';
import XpController from '../controllers/XpController.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

// Protected endpoints
router.use(authenticate);

// GET /users/:id/xp
router.get('/:id/xp', XpController.getUserXp);

export default router;
