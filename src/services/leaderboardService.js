import { Op } from 'sequelize';
import { Leaderboard, Workout, User, Friend } from '../models/index.js';

class LeaderboardService {
  /**
   * Calculates the start of the current week (Sunday 00:00:00.000 UTC).
   */
  getStartOfWeek() {
    const now = new Date();
    const start = new Date(now);
    start.setDate(now.getDate() - now.getDay());
    start.setHours(0, 0, 0, 0);
    return start;
  }

  /**
   * Recalculates volume and rank for a user and updates the Leaderboards table.
   */
  async updateUserLeaderboard(userId, options = {}) {
    if (!userId) return null;

    const t = options.transaction || null;

    // 1. Calculate lifetime volume
    const totalVolume =
      (await Workout.sum('totalVolume', {
        where: { userId },
        transaction: t,
      })) || 0;

    // 2. Calculate weekly volume
    const startOfWeek = this.getStartOfWeek();
    const weeklyVolume =
      (await Workout.sum('totalVolume', {
        where: {
          userId,
          date: { [Op.gte]: startOfWeek },
        },
        transaction: t,
      })) || 0;

    // 3. Count higher volume users to compute rank
    const higherCount = await Leaderboard.count({
      where: {
        totalVolume: { [Op.gt]: totalVolume },
      },
      transaction: t,
    });
    const rank = higherCount + 1;

    // 4. Upsert Leaderboard record
    let lb = await Leaderboard.findOne({ where: { userId }, transaction: t });
    if (!lb) {
      lb = await Leaderboard.create(
        {
          userId,
          totalVolume,
          weeklyVolume,
          rank,
          lastCalculatedAt: new Date(),
        },
        { transaction: t }
      );
    } else {
      lb.totalVolume = totalVolume;
      lb.weeklyVolume = weeklyVolume;
      lb.rank = rank;
      lb.lastCalculatedAt = new Date();
      await lb.save({ transaction: t });
    }

    return lb;
  }

  /**
   * Global leaderboard: top athletes ranked by total lifetime volume.
   */
  async getGlobalLeaderboard(limit = 50) {
    const entries = await Leaderboard.findAll({
      limit: Math.min(100, Math.max(1, limit)),
      order: [['totalVolume', 'DESC']],
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'username', 'level', 'streak'],
        },
      ],
    });

    return entries.map((entry, index) => ({
      rank: index + 1,
      totalVolume: entry.totalVolume,
      weeklyVolume: entry.weeklyVolume,
      user: entry.user,
      lastCalculatedAt: entry.lastCalculatedAt,
    }));
  }

  /**
   * Weekly leaderboard: top athletes ranked by volume lifted in the current week.
   */
  async getWeeklyLeaderboard(limit = 50) {
    const entries = await Leaderboard.findAll({
      limit: Math.min(100, Math.max(1, limit)),
      order: [['weeklyVolume', 'DESC']],
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'username', 'level', 'streak'],
        },
      ],
    });

    return entries.map((entry, index) => ({
      rank: index + 1,
      totalVolume: entry.totalVolume,
      weeklyVolume: entry.weeklyVolume,
      user: entry.user,
      lastCalculatedAt: entry.lastCalculatedAt,
    }));
  }

  /**
   * Friends leaderboard: rankings among user's accepted friends and themselves.
   */
  async getFriendsLeaderboard(userId) {
    const friendships = await Friend.findAll({
      where: {
        status: 'ACCEPTED',
        [Op.or]: [{ userId }, { friendId: userId }],
      },
    });

    const friendIds = new Set();
    friendIds.add(userId);
    for (const f of friendships) {
      friendIds.add(f.userId === userId ? f.friendId : f.userId);
    }

    const entries = await Leaderboard.findAll({
      where: {
        userId: { [Op.in]: Array.from(friendIds) },
      },
      order: [['totalVolume', 'DESC']],
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'username', 'level', 'streak'],
        },
      ],
    });

    return entries.map((entry, index) => ({
      rank: index + 1,
      totalVolume: entry.totalVolume,
      weeklyVolume: entry.weeklyVolume,
      user: entry.user,
      isCurrentUser: entry.userId === userId,
      lastCalculatedAt: entry.lastCalculatedAt,
    }));
  }
}

export default new LeaderboardService();
