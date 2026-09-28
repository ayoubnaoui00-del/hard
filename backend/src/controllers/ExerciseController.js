import { Op } from 'sequelize';
import { Exercise } from '../models/index.js';

class ExerciseController {
  /**
   * GET /exercises
   * Lists exercises with pagination, muscle filtering, and keyword search.
   */
  async listExercises(req, res) {
    try {
      const page = Math.max(1, parseInt(req.query.page, 10) || 1);
      const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
      const offset = (page - 1) * limit;

      const { muscle, muscleGroup, search } = req.query;
      const where = {};

      const targetMuscle = muscle || muscleGroup;
      if (targetMuscle) {
        where.muscleGroup = {
          [Op.iLike]: `%${targetMuscle.trim()}%`,
        };
      }

      if (search) {
        where.name = {
          [Op.iLike]: `%${search.trim()}%`,
        };
      }

      const { count, rows } = await Exercise.findAndCountAll({
        where,
        limit,
        offset,
        order: [['name', 'ASC']],
      });

      return res.status(200).json({
        success: true,
        data: {
          total: count,
          page,
          limit,
          totalPages: Math.ceil(count / limit),
          exercises: rows,
        },
      });
    } catch (error) {
      console.error('[ExerciseController.listExercises] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve exercises.',
        details: error.message,
      });
    }
  }

  /**
   * GET /exercises/:id
   * Fetches a single exercise by UUID.
   */
  async getExerciseById(req, res) {
    try {
      const { id } = req.params;

      // Standard UUID check
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidRegex.test(id)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid exercise ID format. Expected a valid UUID.',
        });
      }

      const exercise = await Exercise.findByPk(id);
      if (!exercise) {
        return res.status(404).json({
          success: false,
          error: 'Exercise not found.',
        });
      }

      return res.status(200).json({
        success: true,
        data: exercise,
      });
    } catch (error) {
      console.error('[ExerciseController.getExerciseById] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve exercise details.',
        details: error.message,
      });
    }
  }
}

export default new ExerciseController();
