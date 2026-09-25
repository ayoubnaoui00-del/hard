import xpService from '../services/xpService.js';

class XpController {
  /**
   * GET /users/:id/xp
   * Returns current user level, XP progress, and audit logs.
   */
  async getUserXp(req, res) {
    try {
      let targetUserId = req.params.id;
      if (targetUserId === 'me') {
        targetUserId = req.user.id;
      }

      const summary = await xpService.getXpSummary(targetUserId);
      if (!summary) {
        return res.status(404).json({
          success: false,
          error: 'User not found.',
        });
      }

      return res.status(200).json({
        success: true,
        data: summary,
      });
    } catch (error) {
      console.error('[XpController.getUserXp] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve XP summary.',
        details: error.message,
      });
    }
  }
}

export default new XpController();
