import { Router } from 'express';
import { authenticate } from '../middleware/auth.js';
import achievementService from '../services/achievementService.js';

const router = Router();

/**
 * GET /achievements
 * Returns authenticated user's unlocked achievements and available catalog.
 */
router.get('/', authenticate, async (req, res) => {
  try {
    const data = await achievementService.getUserAchievements(req.user.id);
    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    console.error('[GET /achievements] Error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to retrieve achievements.',
      details: error.message,
    });
  }
});

export default router;
