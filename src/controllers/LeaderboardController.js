import leaderboardService from '../services/leaderboardService.js';

class LeaderboardController {
  /**
   * GET /leaderboard/global
   */
  async getGlobal(req, res) {
    try {
      const limit = parseInt(req.query.limit, 10) || 50;
      const leaderboard = await leaderboardService.getGlobalLeaderboard(limit);
      return res.status(200).json({
        success: true,
        data: {
          type: 'GLOBAL',
          total: leaderboard.length,
          leaderboard,
        },
      });
    } catch (error) {
      console.error('[LeaderboardController.getGlobal] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve global leaderboard.',
        details: error.message,
      });
    }
  }

  /**
   * GET /leaderboard/weekly
   */
  async getWeekly(req, res) {
    try {
      const limit = parseInt(req.query.limit, 10) || 50;
      const leaderboard = await leaderboardService.getWeeklyLeaderboard(limit);
      return res.status(200).json({
        success: true,
        data: {
          type: 'WEEKLY',
          total: leaderboard.length,
          leaderboard,
        },
      });
    } catch (error) {
      console.error('[LeaderboardController.getWeekly] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve weekly leaderboard.',
        details: error.message,
      });
    }
  }

  /**
   * GET /leaderboard/friends
   */
  async getFriends(req, res) {
    try {
      const userId = req.user.id;
      const leaderboard = await leaderboardService.getFriendsLeaderboard(userId);
      return res.status(200).json({
        success: true,
        data: {
          type: 'FRIENDS',
          total: leaderboard.length,
          leaderboard,
        },
      });
    } catch (error) {
      console.error('[LeaderboardController.getFriends] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve friends leaderboard.',
        details: error.message,
      });
    }
  }

  /**
   * POST /leaderboard/update/:userId
   */
  async updateRank(req, res) {
    try {
      const targetUserId = req.params.userId || req.user.id;
      const updated = await leaderboardService.updateUserLeaderboard(targetUserId);
      return res.status(200).json({
        success: true,
        message: 'Leaderboard rank recalculated successfully.',
        data: updated,
      });
    } catch (error) {
      console.error('[LeaderboardController.updateRank] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to update leaderboard rank.',
        details: error.message,
      });
    }
  }
}

export default new LeaderboardController();
