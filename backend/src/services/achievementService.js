import { Achievement, Workout, User } from '../models/index.js';
import { ACHIEVEMENT_DEFINITIONS } from '../constants/achievements.js';

class AchievementService {
  /**
   * Evaluates available achievements against user stats and unlocks newly achieved ones.
   * @param {string} userId - UUID of the user
   * @param {string} trigger - Event trigger ('WORKOUT_LOGGED', 'STREAK_UPDATED', 'LEVEL_UP', etc.)
   * @param {object} context - Additional event metadata (e.g. { workout })
   * @returns {Promise<Array>} List of newly unlocked achievements
   */
  async checkAndUnlock(userId, trigger, context = {}) {
    try {
      if (!userId) return [];

      // 1. Fetch user's existing unlocked achievements
      const existing = await Achievement.findAll({
        where: { userId },
        attributes: ['name'],
      });
      const existingNames = new Set(existing.map((a) => a.name));

      // 2. Gather user stats
      const [totalWorkouts, user] = await Promise.all([
        Workout.count({ where: { userId } }),
        User.findByPk(userId, { attributes: ['id', 'streak', 'level'] }),
      ]);

      const lastWorkoutVolume = Number(context.workout?.totalVolume) || 0;
      const userStreak = user?.streak || 0;
      const userLevel = user?.level || 1;
      const challengeWins = Number(context.challengeWins) || 0;

      const stats = {
        totalWorkouts,
        lastWorkoutVolume,
        maxWorkoutVolume: lastWorkoutVolume,
        userStreak,
        userLevel,
        challengeWins,
      };

      const newlyUnlocked = [];

      // 3. Check each definition
      for (const def of ACHIEVEMENT_DEFINITIONS) {
        if (existingNames.has(def.name)) {
          continue; // Already unlocked
        }

        if (def.check(stats)) {
          const created = await Achievement.create({
            userId,
            type: def.type,
            name: def.name,
            description: def.description,
            badgeIcon: def.badgeIcon,
            unlockedAt: new Date(),
          });

          newlyUnlocked.push(created);
          existingNames.add(def.name);
          console.log(`[AchievementService] Unlocked "${def.name}" for user ${userId}`);
        }
      }

      return newlyUnlocked;
    } catch (error) {
      console.error('[AchievementService.checkAndUnlock] Error evaluating achievements:', error);
      return []; // Non-blocking
    }
  }

  /**
   * Returns unlocked and locked achievements for a user.
   */
  async getUserAchievements(userId) {
    const unlocked = await Achievement.findAll({
      where: { userId },
      order: [['unlockedAt', 'DESC']],
    });

    const unlockedNames = new Set(unlocked.map((a) => a.name));

    const allWithStatus = ACHIEVEMENT_DEFINITIONS.map((def) => {
      const isUnlocked = unlockedNames.has(def.name);
      const unlockedRecord = unlocked.find((u) => u.name === def.name);

      return {
        code: def.code,
        type: def.type,
        name: def.name,
        description: def.description,
        badgeIcon: def.badgeIcon,
        isUnlocked,
        unlockedAt: unlockedRecord ? unlockedRecord.unlockedAt : null,
      };
    });

    return {
      totalAvailable: ACHIEVEMENT_DEFINITIONS.length,
      totalUnlocked: unlocked.length,
      unlocked,
      catalog: allWithStatus,
    };
  }
}

export default new AchievementService();
