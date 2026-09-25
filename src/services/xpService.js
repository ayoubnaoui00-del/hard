import { XpLog, User, sequelize } from '../models/index.js';
import achievementService from './achievementService.js';

class XpService {
  /**
   * Calculates XP required to reach the next level.
   * e.g., Level 1 -> 500 XP, Level 2 -> 1000 XP, Level 3 -> 1500 XP
   */
  getNextLevelThreshold(level) {
    const lvl = Math.max(1, parseInt(level, 10) || 1);
    return lvl * 500;
  }

  /**
   * Calculates XP earned from a completed workout.
   * Formula: 100 Base XP + (10 * total reps across all sets)
   */
  calculateWorkoutXp(workoutExercises = []) {
    let totalReps = 0;
    for (const ex of workoutExercises) {
      const sets = Math.max(1, parseInt(ex.sets, 10) || 1);
      const reps = Math.max(1, parseInt(ex.reps, 10) || 1);
      totalReps += sets * reps;
    }
    return 100 + totalReps * 10;
  }

  /**
   * Adds XP to a user, logs immutable audit entry, and handles leveling up.
   * @param {string} userId - User UUID
   * @param {string} type - 'WORKOUT' | 'PR' | 'STREAK' | 'CHALLENGE' | 'ACHIEVEMENT' | 'BONUS'
   * @param {number} amount - Points to add
   * @param {string} description - Human-readable reason
   * @param {object} options - Optional transaction { transaction }
   */
  async addXp(userId, type, amount, description = '', options = {}) {
    const points = Math.max(0, parseInt(amount, 10) || 0);
    if (!userId || points === 0) return null;

    const t = options.transaction || null;

    // 1. Create immutable audit record
    const xpLog = await XpLog.create(
      {
        userId,
        amount: points,
        type,
        description: description || `Earned ${points} XP from ${type}`,
      },
      { transaction: t }
    );

    // 2. Fetch and update user
    const user = await User.findByPk(userId, { transaction: t });
    if (!user) {
      throw new Error(`User ${userId} not found when applying XP.`);
    }

    user.totalXp = (user.totalXp || 0) + points;
    user.currentXp = (user.currentXp || 0) + points;

    let leveledUp = false;
    let threshold = this.getNextLevelThreshold(user.level);

    // Level up loop
    while (user.currentXp >= threshold) {
      user.currentXp -= threshold;
      user.level += 1;
      leveledUp = true;
      threshold = this.getNextLevelThreshold(user.level);
    }

    await user.save({ transaction: t });

    // 3. Trigger level up achievement check if leveled up
    if (leveledUp) {
      achievementService.checkAndUnlock(userId, 'LEVEL_UP', { user }).catch((err) => {
        console.error('[XpService] Failed to check LEVEL_UP achievement:', err);
      });
    }

    return {
      xpLog,
      user: {
        id: user.id,
        level: user.level,
        currentXp: user.currentXp,
        totalXp: user.totalXp,
        nextLevelAt: threshold,
        streak: user.streak,
      },
      leveledUp,
    };
  }

  /**
   * Retrieves user's XP summary and recent audit logs.
   */
  async getXpSummary(userId) {
    const user = await User.findByPk(userId, {
      attributes: ['id', 'username', 'level', 'currentXp', 'totalXp', 'streak'],
    });

    if (!user) {
      return null;
    }

    const nextLevelAt = this.getNextLevelThreshold(user.level);
    const progressPercent = Math.min(100, Math.round((user.currentXp / nextLevelAt) * 100));

    const recentLogs = await XpLog.findAll({
      where: { userId },
      limit: 20,
      order: [['createdAt', 'DESC']],
    });

    return {
      user: {
        id: user.id,
        username: user.username,
        level: user.level,
        currentXp: user.currentXp,
        totalXp: user.totalXp,
        nextLevelAt,
        progressPercent,
        streak: user.streak,
      },
      recentLogs,
    };
  }
}

export default new XpService();
