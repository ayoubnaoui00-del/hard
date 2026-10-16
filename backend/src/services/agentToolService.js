import { Op } from 'sequelize';
import { User, Workout, WorkoutExercise, Exercise, Achievement } from '../models/index.js';
import xpService from './xpService.js';
import achievementService from './achievementService.js';

function getMuscleGroupWhere(muscle) {
  if (!muscle) return null;
  const trimmed = muscle.trim().toLowerCase();
  if (trimmed === 'arms' || trimmed === 'arm') {
    return { [Op.in]: ['Biceps', 'Triceps', 'Forearms', 'Arms'] };
  }
  if (trimmed === 'legs' || trimmed === 'leg') {
    return { [Op.in]: ['Quadriceps', 'Hamstrings', 'Calves', 'Legs'] };
  }
  return { [Op.iLike]: `%${muscle.trim()}%` };
}

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
   * 2. checkAchievements(userId)
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
        muscleGroup: getMuscleGroupWhere(targetGroup),
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
        muscleGroup: getMuscleGroupWhere(targetFocus),
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
   * 7. logWorkout(userId, { name, duration, exercises, notes })
   * Logs a complete workout session with exercises, calculates volume, and awards XP.
   */
  async handleLogWorkout(userId, { name, duration, exercises, notes } = {}) {
    const exerciseList = Array.isArray(exercises) ? exercises : [];
    if (exerciseList.length === 0) {
      return {
        success: false,
        error: 'No exercises provided to log workout.',
      };
    }

    let totalVolume = 0;
    const resolvedExercises = [];

    for (let i = 0; i < exerciseList.length; i++) {
      const ex = exerciseList[i];
      const exName = (ex.exerciseName || ex.name || 'Exercise').trim();
      const sets = Math.max(1, parseInt(ex.sets, 10) || 1);
      const reps = Math.max(1, parseInt(ex.reps, 10) || 1);
      const weight = Math.max(0, parseFloat(ex.weight) || 0);

      totalVolume += sets * reps * weight;

      // Find exercise in DB by name or fallback
      let dbExercise = await Exercise.findOne({
        where: { name: { [Op.iLike]: `%${exName}%` } },
      });
      if (!dbExercise) {
        dbExercise = await Exercise.findOne();
      }

      resolvedExercises.push({
        exerciseId: dbExercise ? dbExercise.id : null,
        name: dbExercise ? dbExercise.name : exName,
        sets,
        reps,
        weight,
        order: i + 1,
      });
    }

    // Create Workout record
    const workout = await Workout.create({
      userId,
      name: (name || 'Workout').trim(),
      date: new Date(),
      duration: Math.max(0, parseInt(duration, 10) || 0),
      totalVolume,
      notes: notes || null,
    });

    // Create WorkoutExercise records
    if (resolvedExercises.some((e) => e.exerciseId)) {
      await WorkoutExercise.bulkCreate(
        resolvedExercises
          .filter((e) => Boolean(e.exerciseId))
          .map((e) => ({
            workoutId: workout.id,
            exerciseId: e.exerciseId,
            sets: e.sets,
            reps: e.reps,
            weight: e.weight,
            order: e.order,
          }))
      );
    }

    // Award XP
    const earnedXp = xpService.calculateWorkoutXp(resolvedExercises);
    const xpResult = await xpService.addXp(
      userId,
      'WORKOUT',
      earnedXp,
      `Logged workout via AI Coach: ${workout.name}`
    );

    // Increment streak
    const user = await User.findByPk(userId);
    if (user) {
      await user.update({
        streak: (user.streak || 0) + 1,
        lastActiveAt: new Date(),
      });
    }

    // Trigger achievement check
    let unlockedBadges = [];
    try {
      const unlocked = await achievementService.checkAndUnlock(userId, 'WORKOUT_LOGGED', { workout });
      unlockedBadges = unlocked.map((a) => a.name);
    } catch (_) {}

    return {
      success: true,
      workoutId: workout.id,
      name: workout.name,
      totalVolume,
      exerciseCount: resolvedExercises.length,
      awardedXp: earnedXp,
      newLevel: xpResult?.user?.level || user?.level || 1,
      newStreak: user?.streak || 1,
      unlockedBadges,
      message: `Workout "${workout.name}" logged successfully! Volume: ${totalVolume}kg. Earned ${earnedXp} XP!`,
    };
  }

  /**
   * 8. getUserStats(userId)
   * Queries athlete profile stats: level, XP, streak, workouts, and volume lifted.
   */
  async handleGetUserStats(userId) {
    const user = await User.findByPk(userId, {
      attributes: ['id', 'username', 'level', 'currentXp', 'totalXp', 'streak', 'lastActiveAt'],
    });

    if (!user) {
      throw new Error(`User ${userId} not found`);
    }

    const nextLevelAt = xpService.getNextLevelThreshold(user.level);
    const workoutCount = await Workout.count({ where: { userId } });
    const totalVolume = (await Workout.sum('totalVolume', { where: { userId } })) || 0;
    const unlockedAchievements = await Achievement.count({ where: { userId } });

    return {
      success: true,
      username: user.username,
      level: user.level,
      currentXp: user.currentXp,
      totalXp: user.totalXp,
      nextLevelAt,
      streak: user.streak,
      totalWorkouts: workoutCount,
      totalVolumeKg: Math.round(totalVolume),
      unlockedAchievements,
      message: `Athlete Stats for ${user.username}: Level ${user.level}, ${user.totalXp} Total XP, ${user.streak}-day streak, ${workoutCount} workouts completed, ${Math.round(totalVolume)}kg lifted.`,
    };
  }

  /**
   * 9. getRecentWorkouts(userId, { limit, exerciseFilter })
   * Fetches the user's recent workout history for progressive overload guidance.
   */
  async handleGetRecentWorkouts(userId, { limit = 3, exerciseFilter } = {}) {
    const count = Math.max(1, Math.min(10, parseInt(limit, 10) || 3));

    const workouts = await Workout.findAll({
      where: { userId },
      order: [['date', 'DESC']],
      limit: count,
      include: [
        {
          model: WorkoutExercise,
          as: 'workoutExercises',
          include: [
            {
              model: Exercise,
              as: 'exercise',
              attributes: ['name', 'muscleGroup'],
            },
          ],
        },
      ],
    });

    const formatted = workouts.map((w) => {
      let exercises = (w.workoutExercises || []).map((we) => ({
        name: we.exercise?.name || 'Exercise',
        muscleGroup: we.exercise?.muscleGroup || 'General',
        sets: we.sets,
        reps: we.reps,
        weight: we.weight,
      }));

      if (exerciseFilter) {
        const filterLower = exerciseFilter.toLowerCase();
        exercises = exercises.filter((e) => e.name.toLowerCase().includes(filterLower));
      }

      return {
        id: w.id,
        name: w.name,
        date: w.date ? new Date(w.date).toISOString().split('T')[0] : 'Recent',
        durationMinutes: w.duration,
        totalVolumeKg: w.totalVolume,
        exercises,
      };
    });

    return {
      success: true,
      count: formatted.length,
      workouts: formatted,
      message: `Retrieved ${formatted.length} recent workout(s).`,
    };
  }

  /**
   * Master dispatcher for agent function calls.
   * Ensures non-crashing execution with standardized response envelopes.
   */
  async executeTool(userId, toolName, args = {}) {
    try {
      switch (toolName) {
        case 'logWorkout':
          return await this.handleLogWorkout(userId, args);
        case 'getUserStats':
          return await this.handleGetUserStats(userId);
        case 'getRecentWorkouts':
          return await this.handleGetRecentWorkouts(userId, args);
        case 'addXp':
          return await this.handleAddXp(userId, args);
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
            error: `Unknown tool function "${toolName}". Available tools: logWorkout, getUserStats, getRecentWorkouts, addXp, checkAchievements, suggestNextExercise, generateWorkoutPlan, updateStreak.`,
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
