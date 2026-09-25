import { Router } from 'express';
import LeaderboardController from '../controllers/LeaderboardController.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

// Public / Global leaderboards
router.get('/global', LeaderboardController.getGlobal);
router.get('/weekly', LeaderboardController.getWeekly);

// Friends leaderboard (requires authentication)
router.get('/friends', authenticate, LeaderboardController.getFriends);
router.get('/friends/:userId', authenticate, LeaderboardController.getFriends);

// Internal/Manual rank recalculation
router.post('/update/:userId', authenticate, LeaderboardController.updateRank);

export default router;
