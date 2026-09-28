import { sequelize, Workout, WorkoutExercise, Exercise } from '../models/index.js';
import achievementService from '../services/achievementService.js';
import xpService from '../services/xpService.js';
import leaderboardService from '../services/leaderboardService.js';
import ChallengeController from './ChallengeController.js';

class WorkoutController {
  /**
   * POST /workouts
   * Log a new workout session with multiple exercise sets.
   */
  async createWorkout(req, res) {
    const t = await sequelize.transaction();
    try {
      const userId = req.user.id;
      const { name, date, duration, notes, exercises } = req.body;

      // Validate exercises payload if present
      const exerciseList = Array.isArray(exercises) ? exercises : [];
      let totalVolume = 0;

      for (const ex of exerciseList) {
        if (!ex.exerciseId) {
          await t.rollback();
          return res.status(400).json({
            success: false,
            error: 'Each workout exercise must have an exerciseId.',
          });
        }
        const sets = Math.max(1, parseInt(ex.sets, 10) || 1);
        const reps = Math.max(1, parseInt(ex.reps, 10) || 1);
        const weight = Math.max(0, parseFloat(ex.weight) || 0);

        totalVolume += sets * reps * weight;
      }

      // Create Workout record
      const workout = await Workout.create(
        {
          userId,
          name: name ? name.trim() : 'Workout',
          date: date ? new Date(date) : new Date(),
          duration: Math.max(0, parseInt(duration, 10) || 0),
          totalVolume,
          notes: notes || null,
        },
        { transaction: t }
      );

      // Create WorkoutExercise records
      if (exerciseList.length > 0) {
        const weRecords = exerciseList.map((ex, index) => ({
          workoutId: workout.id,
          exerciseId: ex.exerciseId,
          sets: Math.max(1, parseInt(ex.sets, 10) || 1),
          reps: Math.max(1, parseInt(ex.reps, 10) || 1),
          weight: Math.max(0, parseFloat(ex.weight) || 0),
          order: ex.order !== undefined ? parseInt(ex.order, 10) : index + 1,
        }));

        await WorkoutExercise.bulkCreate(weRecords, { transaction: t });
      }

      await t.commit();

      // Retrieve full workout with relations
      const fullWorkout = await Workout.findByPk(workout.id, {
        include: [
          {
            model: WorkoutExercise,
            as: 'workoutExercises',
            include: [
              {
                model: Exercise,
                as: 'exercise',
                attributes: ['id', 'name', 'muscleGroup', 'formTips'],
              },
            ],
          },
        ],
      });

      // Trigger achievement check
      const unlockedAchievements = await achievementService.checkAndUnlock(userId, 'WORKOUT_LOGGED', {
        workout: fullWorkout,
      });

      // Award XP for workout
      const earnedXp = xpService.calculateWorkoutXp(exerciseList);
      const xpResult = await xpService.addXp(
        userId,
        'WORKOUT',
        earnedXp,
        `Completed workout: ${fullWorkout.name}`
      );

      // Recalculate leaderboard standing
      await leaderboardService.updateUserLeaderboard(userId);

      // Update in-progress challenge scores if matching exercises were logged
      await ChallengeController.updateParticipantScores(userId, exerciseList);

      return res.status(201).json({
        success: true,
        message: 'Workout logged successfully.',
        data: {
          workout: fullWorkout,
          unlockedAchievements,
          xp: xpResult,
        },
      });
    } catch (error) {
      await t.rollback();
      console.error('[WorkoutController.createWorkout] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to log workout.',
        details: error.message,
      });
    }
  }

  /**
   * GET /workouts
   * Retrieve list of workouts for the authenticated user (paginated).
   */
  async listUserWorkouts(req, res) {
    try {
      const userId = req.user.id;
      const page = Math.max(1, parseInt(req.query.page, 10) || 1);
      const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
      const offset = (page - 1) * limit;

      const { count, rows } = await Workout.findAndCountAll({
        where: { userId },
        limit,
        offset,
        order: [
          ['date', 'DESC'],
          ['createdAt', 'DESC'],
        ],
        include: [
          {
            model: WorkoutExercise,
            as: 'workoutExercises',
            include: [
              {
                model: Exercise,
                as: 'exercise',
                attributes: ['id', 'name', 'muscleGroup'],
              },
            ],
          },
        ],
      });

      return res.status(200).json({
        success: true,
        data: {
          total: count,
          page,
          limit,
          totalPages: Math.ceil(count / limit),
          workouts: rows,
        },
      });
    } catch (error) {
      console.error('[WorkoutController.listUserWorkouts] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve workouts.',
        details: error.message,
      });
    }
  }

  /**
   * GET /workouts/:id
   * Get single workout session by ID with full details.
   */
  async getWorkoutById(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const workout = await Workout.findOne({
        where: { id, userId },
        include: [
          {
            model: WorkoutExercise,
            as: 'workoutExercises',
            include: [
              {
                model: Exercise,
                as: 'exercise',
                attributes: ['id', 'name', 'muscleGroup', 'instructions', 'formTips', 'alternatives'],
              },
            ],
          },
        ],
      });

      if (!workout) {
        return res.status(404).json({
          success: false,
          error: 'Workout not found.',
        });
      }

      return res.status(200).json({
        success: true,
        data: workout,
      });
    } catch (error) {
      console.error('[WorkoutController.getWorkoutById] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve workout.',
        details: error.message,
      });
    }
  }

  /**
   * PUT /workouts/:id
   * Update an existing workout and optionally update exercises/volume.
   */
  async updateWorkout(req, res) {
    const t = await sequelize.transaction();
    try {
      const { id } = req.params;
      const userId = req.user.id;
      const { name, date, duration, notes, exercises } = req.body;

      const workout = await Workout.findOne({
        where: { id, userId },
        transaction: t,
      });

      if (!workout) {
        await t.rollback();
        return res.status(404).json({
          success: false,
          error: 'Workout not found.',
        });
      }

      if (name !== undefined) workout.name = name.trim();
      if (date !== undefined) workout.date = new Date(date);
      if (duration !== undefined) workout.duration = Math.max(0, parseInt(duration, 10) || 0);
      if (notes !== undefined) workout.notes = notes;

      // If exercises array is provided, replace WorkoutExercises & recalculate totalVolume
      if (Array.isArray(exercises)) {
        await WorkoutExercise.destroy({
          where: { workoutId: workout.id },
          transaction: t,
        });

        let newVolume = 0;
        const weRecords = exercises.map((ex, index) => {
          const sets = Math.max(1, parseInt(ex.sets, 10) || 1);
          const reps = Math.max(1, parseInt(ex.reps, 10) || 1);
          const weight = Math.max(0, parseFloat(ex.weight) || 0);
          newVolume += sets * reps * weight;

          return {
            workoutId: workout.id,
            exerciseId: ex.exerciseId,
            sets,
            reps,
            weight,
            order: ex.order !== undefined ? parseInt(ex.order, 10) : index + 1,
          };
        });

        await WorkoutExercise.bulkCreate(weRecords, { transaction: t });
        workout.totalVolume = newVolume;
      }

      await workout.save({ transaction: t });
      await t.commit();

      // Recalculate leaderboard standing
      await leaderboardService.updateUserLeaderboard(userId);

      const updatedWorkout = await Workout.findByPk(workout.id, {
        include: [
          {
            model: WorkoutExercise,
            as: 'workoutExercises',
            include: [
              {
                model: Exercise,
                as: 'exercise',
                attributes: ['id', 'name', 'muscleGroup'],
              },
            ],
          },
        ],
      });

      return res.status(200).json({
        success: true,
        message: 'Workout updated successfully.',
        data: updatedWorkout,
      });
    } catch (error) {
      await t.rollback();
      console.error('[WorkoutController.updateWorkout] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to update workout.',
        details: error.message,
      });
    }
  }

  /**
   * DELETE /workouts/:id
   * Delete a workout session and cascade to workout exercises.
   */
  async deleteWorkout(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      const workout = await Workout.findOne({
        where: { id, userId },
      });

      if (!workout) {
        return res.status(404).json({
          success: false,
          error: 'Workout not found.',
        });
      }

      await workout.destroy();

      // Recalculate leaderboard standing
      await leaderboardService.updateUserLeaderboard(userId);

      return res.status(200).json({
        success: true,
        message: 'Workout deleted successfully.',
      });
    } catch (error) {
      console.error('[WorkoutController.deleteWorkout] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to delete workout.',
        details: error.message,
      });
    }
  }
}

export default new WorkoutController();
