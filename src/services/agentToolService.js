import { Op } from 'sequelize';
import { User, Workout, WorkoutExercise, Exercise } from '../models/index.js';
import xpService from './xpService.js';
import leaderboardService from './leaderboardService.js';
import achievementService from './achievementService.js';

class AgentToolService {
  /**
   * 1. addXp(userId, amount, reason)
   * Awards XP to athlete and creates audit log.
   */
  async handleAddXp(userId, { amount, reason }) {
    const points = Math.max(1, parseInt(amount, 10) || 50);
    const desc = reason || 'Earned bonus XP from AI Coach';

    await xpService.addXp(userId, 'BONUS', points, desc);

    const user = await User.findByPk(userId, {
      attributes: ['id', 'username', 'level', 'currentXp', 'totalXp'],
    });

    return {
      success: true,
      awardedXp: points,
      reason: desc,
      currentLevel: user?.level || 1,
      totalXp: user?.totalXp || 0,
      message: `Successfully awarded ${points} XP for "${desc}".`,
    };
  }

  /**
   * 2. updateLeaderboard(userId)
   * Recalculates user's total volume, weekly volume, and leaderboard rank.
   */
  async handleUpdateLeaderboard(userId) {
    const lb = await leaderboardService.updateUserLeaderboard(userId);

    return {
      success: true,
      rank: lb?.rank || 1,
      totalVolume: lb?.totalVolume || 0,
      weeklyVolume: lb?.weeklyVolume || 0,
      message: `Leaderboard updated! Current rank: #${lb?.rank || 1} with ${lb?.totalVolume || 0}kg total volume.`,
    };
  }

  /**
   * 3. checkAchievements(userId)
   * Evaluates user stats against achievement definitions and unlocks badges.
   */
  async handleCheckAchievements(userId) {
    const unlocked = await achievementService.checkAndUnlock(userId, 'AGENT_CHECK', {});

    const unlockedNames = unlocked.map((a) => a.name);
    return {
      success: true,
      unlockedCount: unlocked.length,
      unlockedBadges: unlockedNames,
      message:
        unlocked.length > 0
          ? `Congratulations! You unlocked ${unlocked.length} new badge(s): ${unlockedNames.join(', ')}!`
          : 'All eligible achievements have already been unlocked. Keep training for the next milestones!',
    };
  }

  /**
   * 4. suggestNextExercise(userId, muscleGroup)
   * Queries recent workout history and recommends complementary exercises.
   */
  async handleSuggestNextExercise(userId, { muscleGroup }) {
    const targetGroup = (muscleGroup || 'Full Body').trim();

    // 1. Fetch recent exercises performed by user
    const recentWorkouts = await Workout.findAll({
      where: { userId },
      order: [['date', 'DESC']],
      limit: 5,
      include: [
        {
          model: WorkoutExercise,
          as: 'workoutExercises',
          attributes: ['exerciseId'],
        },
      ],
    });

    const recentExerciseIds = new Set();
    for (const w of recentWorkouts) {
      for (const we of w.workoutExercises || []) {
        if (we.exerciseId) recentExerciseIds.add(we.exerciseId);
      }
    }

    // 2. Fetch candidate exercises for the target muscle group
    const candidates = await Exercise.findAll({
      where: {
        muscleGroup: {
          [Op.iLike]: `%${targetGroup}%`,
        },
      },
      limit: 20,
    });

    if (candidates.length === 0) {
      // Fallback: fetch any exercise
      const fallback = await Exercise.findOne();
      return {
        success: true,
        muscleGroup: targetGroup,
        suggestedExercise: fallback
          ? {
              name: fallback.name,
              muscleGroup: fallback.muscleGroup,
              instructions: fallback.instructions,
              formTips: fallback.formTips,
            }
          : null,
        message: fallback ? `Suggested: ${fallback.name}` : 'No exercises found in database.',
      };
    }

    // Prioritize exercises not done recently
    const freshCandidates = candidates.filter((c) => !recentExerciseIds.has(c.id));
    const selected = freshCandidates.length > 0 ? freshCandidates[0] : candidates[0];

    return {
      success: true,
      muscleGroup: targetGroup,
      suggestedExercise: {
        id: selected.id,
        name: selected.name,
        muscleGroup: selected.muscleGroup,
        instructions: selected.instructions,
        formTips: selected.formTips,
        alternatives: selected.alternatives || [],
      },
      isFreshVariation: freshCandidates.length > 0,
      message: `Recommended next exercise: ${selected.name} (${selected.muscleGroup}).`,
    };
  }

  /**
   * 5. generateWorkoutPlan(userId, duration, focus)
   * Generates a structured JSON workout routine.
   */
  async handleGenerateWorkoutPlan(userId, { duration, focus }) {
    const minutes = Math.max(15, Math.min(120, parseInt(duration, 10) || 45));
    const targetFocus = (focus || 'Full Body').trim();

    // Determine target exercise count based on time: ~8-10 min per exercise including rest
    const exerciseCount = Math.max(2, Math.min(7, Math.round(minutes / 9)));

    // Fetch exercises for the focus
    let exercises = await Exercise.findAll({
      where: {
        muscleGroup: {
          [Op.iLike]: `%${targetFocus}%`,
        },
      },
      limit: exerciseCount * 2,
    });

    if (exercises.length < exerciseCount) {
      // Complement with other exercises if needed
      const extra = await Exercise.findAll({ limit: exerciseCount });
      exercises = [...exercises, ...extra].slice(0, exerciseCount);
    } else {
      exercises = exercises.slice(0, exerciseCount);
    }

    const plannedExercises = exercises.map((ex, index) => ({
      order: index + 1,
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      sets: minutes >= 45 ? 4 : 3,
      reps: '8-12',
      restSeconds: 60,
      formTips: ex.formTips || 'Maintain steady tempo and full range of motion.',
    }));

    const plan = {
      title: `${minutes}-Minute ${targetFocus} Workout Plan`,
      durationMinutes: minutes,
      focus: targetFocus,
      warmup: '5 minutes dynamic stretching & joint rotations',
      exercises: plannedExercises,
      cooldown: '3-5 minutes static stretching & deep breathing',
    };

    return {
      success: true,
      plan,
      message: `Generated a ${minutes}-minute workout plan focused on ${targetFocus} with ${plannedExercises.length} exercises.`,
    };
  }

  /**
   * 6. updateStreak(userId)
   * Updates the user's active workout streak.
   */
  async handleUpdateStreak(userId) {
    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error(`User ${userId} not found`);
    }

    const currentStreak = (user.streak || 0) + 1;
    await user.update({
      streak: currentStreak,
      lastActiveAt: new Date(),
    });

    return {
      success: true,
      currentStreak,
      lastActiveAt: user.lastActiveAt,
      message: `Streak updated! You are currently on a ${currentStreak}-day workout streak! 🔥`,
    };
  }

  /**
   * Master dispatcher for agent function calls.
   * Ensures non-crashing execution with standardized response envelopes.
   */
  async executeTool(userId, toolName, args = {}) {
    try {
      switch (toolName) {
        case 'addXp':
          return await this.handleAddXp(userId, args);
        case 'updateLeaderboard':
          return await this.handleUpdateLeaderboard(userId);
        case 'checkAchievements':
          return await this.handleCheckAchievements(userId);
        case 'suggestNextExercise':
          return await this.handleSuggestNextExercise(userId, args);
        case 'generateWorkoutPlan':
          return await this.handleGenerateWorkoutPlan(userId, args);
        case 'updateStreak':
          return await this.handleUpdateStreak(userId);
        default:
          return {
            success: false,
            error: `Unknown tool function "${toolName}". Available tools: addXp, updateLeaderboard, checkAchievements, suggestNextExercise, generateWorkoutPlan, updateStreak.`,
          };
      }
    } catch (err) {
      console.error(`[AgentToolService] Error executing tool "${toolName}":`, err.message);
      return {
        success: false,
        error: `Failed to execute ${toolName}: ${err.message}`,
        toolName,
      };
    }
  }
}

export default new AgentToolService();
