import { Op } from 'sequelize';
import { Challenge, Exercise, User, sequelize } from '../models/index.js';
import xpService from '../services/xpService.js';
import achievementService from '../services/achievementService.js';

class ChallengeController {
  /**
   * POST /challenges
   * Creates a 1v1 challenge against another user for a specific exercise.
   */
  async createChallenge(req, res) {
    try {
      const challengerId = req.user.id;
      const { challengedId, exerciseId, rewardXp } = req.body;

      if (!challengedId || !exerciseId) {
        return res.status(400).json({
          success: false,
          error: 'challengedId and exerciseId are required.',
        });
      }

      if (challengerId === challengedId) {
        return res.status(400).json({
          success: false,
          error: 'You cannot challenge yourself.',
        });
      }

      const [challengedUser, targetExercise] = await Promise.all([
        User.findByPk(challengedId, { attributes: ['id', 'username'] }),
        Exercise.findByPk(exerciseId, { attributes: ['id', 'name'] }),
      ]);

      if (!challengedUser) {
        return res.status(404).json({
          success: false,
          error: 'Challenged user not found.',
        });
      }

      if (!targetExercise) {
        return res.status(404).json({
          success: false,
          error: 'Target exercise not found.',
        });
      }

      const challenge = await Challenge.create({
        challengerId,
        challengedId,
        exerciseId,
        rewardXp: Math.max(50, parseInt(rewardXp, 10) || 150),
        status: 'PENDING',
      });

      const fullChallenge = await Challenge.findByPk(challenge.id, {
        include: [
          { model: User, as: 'challenger', attributes: ['id', 'username', 'level'] },
          { model: User, as: 'challenged', attributes: ['id', 'username', 'level'] },
          { model: Exercise, as: 'exercise', attributes: ['id', 'name', 'muscleGroup'] },
        ],
      });

      return res.status(201).json({
        success: true,
        message: `Challenge sent to ${challengedUser.username} for ${targetExercise.name}!`,
        data: fullChallenge,
      });
    } catch (error) {
      console.error('[ChallengeController.createChallenge] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to create challenge.',
        details: error.message,
      });
    }
  }

  /**
   * GET /challenges
   * List challenges involving the authenticated user.
   */
  async listChallenges(req, res) {
    try {
      const userId = req.user.id;
      const { status } = req.query;
      const page = Math.max(1, parseInt(req.query.page, 10) || 1);
      const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
      const offset = (page - 1) * limit;

      const where = {
        [Op.or]: [{ challengerId: userId }, { challengedId: userId }],
      };

      if (status) {
        where.status = status.toUpperCase();
      }

      const { count, rows } = await Challenge.findAndCountAll({
        where,
        limit,
        offset,
        order: [['createdAt', 'DESC']],
        include: [
          { model: User, as: 'challenger', attributes: ['id', 'username', 'level'] },
          { model: User, as: 'challenged', attributes: ['id', 'username', 'level'] },
          { model: User, as: 'winner', attributes: ['id', 'username'] },
          { model: Exercise, as: 'exercise', attributes: ['id', 'name', 'muscleGroup'] },
        ],
      });

      return res.status(200).json({
        success: true,
        data: {
          total: count,
          page,
          limit,
          totalPages: Math.ceil(count / limit),
          challenges: rows,
        },
      });
    } catch (error) {
      console.error('[ChallengeController.listChallenges] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to list challenges.',
        details: error.message,
      });
    }
  }

  /**
   * GET /challenges/:id
   * Get single challenge details.
   */
  async getChallengeById(req, res) {
    try {
      const { id } = req.params;
      const challenge = await Challenge.findByPk(id, {
        include: [
          { model: User, as: 'challenger', attributes: ['id', 'username', 'level', 'streak'] },
          { model: User, as: 'challenged', attributes: ['id', 'username', 'level', 'streak'] },
          { model: User, as: 'winner', attributes: ['id', 'username'] },
          { model: Exercise, as: 'exercise', attributes: ['id', 'name', 'muscleGroup'] },
        ],
      });

      if (!challenge) {
        return res.status(404).json({
          success: false,
          error: 'Challenge not found.',
        });
      }

      return res.status(200).json({
        success: true,
        data: challenge,
      });
    } catch (error) {
      console.error('[ChallengeController.getChallengeById] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to retrieve challenge.',
        details: error.message,
      });
    }
  }

  /**
   * PUT /challenges/:id
   * Accepts, declines, or completes a challenge.
   */
  async updateChallengeStatus(req, res) {
    const t = await sequelize.transaction();
    try {
      const { id } = req.params;
      const userId = req.user.id;
      const { action } = req.body;

      if (!action || !['accept', 'reject', 'complete'].includes(action.toLowerCase())) {
        await t.rollback();
        return res.status(400).json({
          success: false,
          error: "Action must be one of 'accept', 'reject', or 'complete'.",
        });
      }

      const challenge = await Challenge.findByPk(id, { transaction: t });
      if (!challenge) {
        await t.rollback();
        return res.status(404).json({
          success: false,
          error: 'Challenge not found.',
        });
      }

      // Verify user is a participant
      if (challenge.challengerId !== userId && challenge.challengedId !== userId) {
        await t.rollback();
        return res.status(403).json({
          success: false,
          error: 'You are not a participant in this challenge.',
        });
      }

      const act = action.toLowerCase();

      if (act === 'accept') {
        if (challenge.challengedId !== userId) {
          await t.rollback();
          return res.status(403).json({
            success: false,
            error: 'Only the challenged user can accept this invitation.',
          });
        }
        challenge.status = 'IN_PROGRESS';
        await challenge.save({ transaction: t });
        await t.commit();

        return res.status(200).json({
          success: true,
          message: 'Challenge accepted! Time to lift!',
          data: challenge,
        });
      }

      if (act === 'reject') {
        challenge.status = 'DECLINED';
        await challenge.save({ transaction: t });
        await t.commit();

        return res.status(200).json({
          success: true,
          message: 'Challenge declined.',
          data: challenge,
        });
      }

      if (act === 'complete') {
        if (challenge.status === 'COMPLETED') {
          await t.rollback();
          return res.status(400).json({
            success: false,
            error: 'Challenge is already completed.',
          });
        }

        // Determine winner
        let winnerId = null;
        let loserId = null;

        if (challenge.challengerScore > challenge.challengedScore) {
          winnerId = challenge.challengerId;
          loserId = challenge.challengedId;
        } else if (challenge.challengedScore > challenge.challengerScore) {
          winnerId = challenge.challengedId;
          loserId = challenge.challengerId;
        }

        challenge.winnerId = winnerId;
        challenge.status = 'COMPLETED';
        await challenge.save({ transaction: t });

        // Award XP
        const rewardXp = challenge.rewardXp || 150;
        const consolationXp = 50;

        if (winnerId) {
          await xpService.addXp(
            winnerId,
            'CHALLENGE',
            rewardXp,
            `Won 1v1 challenge on volume!`,
            { transaction: t }
          );

          // Trigger Challenge achievement check
          achievementService.checkAndUnlock(winnerId, 'CHALLENGE_WIN', { challengeWins: 1 }).catch(() => {});
        }

        if (loserId) {
          await xpService.addXp(
            loserId,
            'CHALLENGE',
            consolationXp,
            `Completed 1v1 challenge`,
            { transaction: t }
          );
        }

        await t.commit();

        const updated = await Challenge.findByPk(challenge.id, {
          include: [
            { model: User, as: 'challenger', attributes: ['id', 'username'] },
            { model: User, as: 'challenged', attributes: ['id', 'username'] },
            { model: User, as: 'winner', attributes: ['id', 'username'] },
            { model: Exercise, as: 'exercise', attributes: ['id', 'name'] },
          ],
        });

        return res.status(200).json({
          success: true,
          message: 'Challenge completed and XP rewards distributed!',
          data: updated,
        });
      }
    } catch (error) {
      await t.rollback();
      console.error('[ChallengeController.updateChallengeStatus] Error:', error);
      return res.status(500).json({
        success: false,
        error: 'Failed to update challenge.',
        details: error.message,
      });
    }
  }

  /**
   * Helper called after workouts to update scores for in-progress challenges.
   */
  async updateParticipantScores(userId, workoutExercises = []) {
    try {
      if (!workoutExercises.length) return;

      const activeChallenges = await Challenge.findAll({
        where: {
          status: 'IN_PROGRESS',
          [Op.or]: [{ challengerId: userId }, { challengedId: userId }],
        },
      });

      for (const challenge of activeChallenges) {
        const matching = workoutExercises.filter(
          (we) => we.exerciseId === challenge.exerciseId
        );
        if (!matching.length) continue;

        const volumeAdded = matching.reduce((sum, we) => {
          const sets = Math.max(1, parseInt(we.sets, 10) || 1);
          const reps = Math.max(1, parseInt(we.reps, 10) || 1);
          const weight = Math.max(0, parseFloat(we.weight) || 0);
          return sum + sets * reps * weight;
        }, 0);

        if (challenge.challengerId === userId) {
          challenge.challengerScore += volumeAdded;
        } else if (challenge.challengedId === userId) {
          challenge.challengedScore += volumeAdded;
        }

        await challenge.save();
      }
    } catch (err) {
      console.error('[ChallengeController.updateParticipantScores] Error:', err);
    }
  }
}

export default new ChallengeController();
