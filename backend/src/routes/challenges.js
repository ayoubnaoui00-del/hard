import { Router } from 'express';
import ChallengeController from '../controllers/ChallengeController.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

// All challenge routes require authentication
router.use(authenticate);

// Challenge Management
router.post('/', ChallengeController.createChallenge);
router.get('/', ChallengeController.listChallenges);
router.get('/:id', ChallengeController.getChallengeById);
router.put('/:id', ChallengeController.updateChallengeStatus);

export default router;
